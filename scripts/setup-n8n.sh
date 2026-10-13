#!/usr/bin/env bash
# Import credentials and workflows into the running n8n container and activate workflow 1.
# Zugangsdaten und Workflows in den laufenden n8n-Container importieren, Workflow 1 aktivieren.
#
#   docker compose up -d
#   ./scripts/setup-n8n.sh
#
# Reads POSTGRES_* and GROQ_API_KEY from .env. Safe to run again: existing items are skipped.
# Liest POSTGRES_* und GROQ_API_KEY aus .env. Mehrfach ausfuehrbar: Vorhandenes wird uebersprungen.
set -euo pipefail

# Git Bash on Windows: keep container paths like /tmp/... unchanged (no effect elsewhere).
# Git Bash unter Windows: Containerpfade wie /tmp/... nicht umschreiben (sonst ohne Wirkung).
export MSYS_NO_PATHCONV=1

cd "$(dirname "$0")/.."

set -a
# shellcheck disable=SC1091
source .env
set +a
: "${GROQ_API_KEY:?set GROQ_API_KEY in .env}"

# Copied files belong to root, so the temporary folder is removed as root.
# Kopierte Dateien gehoeren root, deshalb wird der temporaere Ordner als root entfernt.
docker compose exec -T -u root n8n rm -rf /tmp/advisory-setup
docker compose exec -T n8n mkdir -p /tmp/advisory-setup
docker compose cp workflows n8n:/tmp/advisory-setup/workflows
docker compose cp scripts/n8n-import.sh n8n:/tmp/advisory-setup/n8n-import.sh

docker compose exec -T -e POSTGRES_DB -e POSTGRES_USER -e POSTGRES_PASSWORD -e GROQ_API_KEY \
  n8n sh /tmp/advisory-setup/n8n-import.sh

docker compose exec -T -u root n8n rm -rf /tmp/advisory-setup

# Restart so that n8n registers the activated webhook.
# Neustart, damit n8n den aktivierten Webhook registriert.
docker compose restart n8n

# Wait until the webhook is registered. A GET on a registered POST webhook answers
# "Did you mean to make a POST request?"; GET does not start the workflow.
# Warten, bis der Webhook registriert ist. GET startet den Workflow nicht.
url=http://localhost:5678/webhook/advisory-input
for _ in $(seq 1 60); do
  if curl --silent "$url" | grep -q "POST request"; then
    echo "Webhook ready: $url"
    exit 0
  fi
  sleep 2
done
echo "Webhook not registered after 120 s, see: docker compose logs n8n" >&2
exit 1
