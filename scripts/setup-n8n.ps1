# Import credentials and workflows into the running n8n container and activate workflow 1.
# Zugangsdaten und Workflows in den laufenden n8n-Container importieren, Workflow 1 aktivieren.
#
#   docker compose up -d
#   .\scripts\setup-n8n.ps1
#
# Reads POSTGRES_* and GROQ_API_KEY from .env. Safe to run again: existing items are skipped.
# Liest POSTGRES_* und GROQ_API_KEY aus .env. Mehrfach ausfuehrbar: Vorhandenes wird uebersprungen.
$ErrorActionPreference = "Stop"

Set-Location (Join-Path $PSScriptRoot "..")

# Load .env into the environment of this process (passed on by name, not on the command line).
# .env in die Umgebung dieses Prozesses laden (wird per Name weitergegeben, nicht in der Kommandozeile).
foreach ($line in Get-Content .env) {
    if ($line -match '^\s*([A-Za-z_][A-Za-z0-9_]*)=(.*)$') {
        [Environment]::SetEnvironmentVariable($Matches[1], $Matches[2].Trim('"', "'"), "Process")
    }
}
if (-not $env:GROQ_API_KEY) { throw "set GROQ_API_KEY in .env" }

function Invoke-Checked {
    & $args[0] $args[1..($args.Count - 1)]
    if ($LASTEXITCODE -ne 0) { throw "failed: $($args -join ' ')" }
}

# Copied files belong to root, so the temporary folder is removed as root.
# Kopierte Dateien gehoeren root, deshalb wird der temporaere Ordner als root entfernt.
Invoke-Checked docker compose exec -T -u root n8n rm -rf /tmp/advisory-setup
Invoke-Checked docker compose exec -T n8n mkdir -p /tmp/advisory-setup
Invoke-Checked docker compose cp workflows n8n:/tmp/advisory-setup/workflows
Invoke-Checked docker compose cp scripts/n8n-import.sh n8n:/tmp/advisory-setup/n8n-import.sh

Invoke-Checked docker compose exec -T -e POSTGRES_DB -e POSTGRES_USER -e POSTGRES_PASSWORD -e GROQ_API_KEY `
    n8n sh /tmp/advisory-setup/n8n-import.sh

Invoke-Checked docker compose exec -T -u root n8n rm -rf /tmp/advisory-setup

# Restart so that n8n registers the activated webhook.
# Neustart, damit n8n den aktivierten Webhook registriert.
Invoke-Checked docker compose restart n8n

# Wait until the webhook is registered. A GET on a registered POST webhook answers
# "Did you mean to make a POST request?"; GET does not start the workflow.
# Warten, bis der Webhook registriert ist. GET startet den Workflow nicht.
$url = "http://localhost:5678/webhook/advisory-input"
for ($i = 0; $i -lt 60; $i++) {
    try {
        Invoke-WebRequest -Uri $url -UseBasicParsing | Out-Null
    } catch {
        if ("$($_.ErrorDetails.Message)" -match "POST request") { "Webhook ready: $url"; exit 0 }
    }
    Start-Sleep -Seconds 2
}
throw "Webhook not registered after 120 s, see: docker compose logs n8n"
