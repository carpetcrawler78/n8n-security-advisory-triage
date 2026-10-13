#!/bin/sh
# Runs inside the n8n container. Called by setup-n8n.sh / setup-n8n.ps1, not directly.
# Laeuft im n8n-Container. Wird von setup-n8n.sh / setup-n8n.ps1 aufgerufen, nicht direkt.
#
# - creates the credentials "Postgres account" and "Groq account" if missing
# - imports both workflows if missing
# - publishes (activates) workflow 1
#
# Expects in the environment / erwartet in der Umgebung:
#   POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD, GROQ_API_KEY
# Expects the workflow exports in /tmp/advisory-setup/workflows.
set -eu

dir=/tmp/advisory-setup
wf1="01 - Advisory Input"

: "${POSTGRES_PASSWORD:?missing}" "${GROQ_API_KEY:?missing}"

# Names of existing credentials (empty if none).
# Namen vorhandener Zugangsdaten (leer, wenn keine).
existing=""
if n8n export:credentials --all --output="$dir/existing.json" >/dev/null 2>&1; then
  existing=$(node -e 'for (const c of require(process.argv[1])) console.log(c.name)' "$dir/existing.json")
fi
rm -f "$dir/existing.json"

# Build the credentials file from the environment; n8n encrypts it on import.
# Zugangsdaten-Datei aus der Umgebung bauen; n8n verschluesselt sie beim Import.
EXISTING="$existing" node -e '
const e = process.env;
const have = new Set(e.EXISTING.split("\n"));
// n8n needs an id; generated here, it only ends up in the n8n database.
// n8n braucht eine id; hier erzeugt, sie landet nur in der n8n-Datenbank.
const newId = () => require("crypto").randomBytes(12).toString("base64url").slice(0, 16);
const creds = [
  { name: "Postgres account", type: "postgres",
    data: { host: "postgres", port: 5432, database: e.POSTGRES_DB || "advisory",
            user: e.POSTGRES_USER || "advisory", password: e.POSTGRES_PASSWORD, ssl: "disable" } },
  { name: "Groq account", type: "groqApi", data: { apiKey: e.GROQ_API_KEY } },
].filter(c => !have.has(c.name)).map(c => ({ id: newId(), ...c }));
require("fs").writeFileSync(process.argv[1], JSON.stringify(creds));
console.log("credentials to import: " + (creds.map(c => c.name).join(", ") || "none"));
' "$dir/credentials.json"

if [ "$(cat "$dir/credentials.json")" != "[]" ]; then
  n8n import:credentials --input="$dir/credentials.json"
fi
rm -f "$dir/credentials.json"

# Import workflows that do not exist yet (matched by name). The list is read completely
# first: n8n list:workflow hangs if the reading end of a pipe closes early (grep -q, head).
# Workflows importieren, die es noch nicht gibt (Abgleich ueber den Namen). Die Liste wird
# zuerst vollstaendig gelesen: n8n list:workflow haengt, wenn eine Pipe frueh schliesst.
workflows=$(n8n list:workflow 2>/dev/null)
for file in "$dir"/workflows/*.json; do
  name=$(node -e 'console.log(require(process.argv[1]).name)' "$file")
  if printf '%s\n' "$workflows" | awk -F'|' -v n="$name" '$2 == n { f = 1 } END { exit !f }'; then
    echo "workflow exists: $name"
  else
    # Add a random id to a temporary copy; the export in the repo has none.
    # Zufaellige id in eine temporaere Kopie schreiben; der Export im Repo hat keine.
    node -e '
      const w = require(process.argv[1]);
      w.id = require("crypto").randomBytes(12).toString("base64url").slice(0, 16);
      require("fs").writeFileSync(process.argv[2], JSON.stringify(w));
    ' "$file" "$dir/import.json"
    n8n import:workflow --input="$dir/import.json"
    rm -f "$dir/import.json"
  fi
done

# Publish workflow 1 so that the production webhook is registered.
# Workflow 1 veroeffentlichen, damit der Produktions-Webhook registriert ist.
workflows=$(n8n list:workflow 2>/dev/null)
id=$(printf '%s\n' "$workflows" | awk -F'|' -v n="$wf1" '$2 == n { print $1; exit }')
[ -n "$id" ] || { echo "workflow 1 not found" >&2; exit 1; }
n8n publish:workflow --id="$id"
