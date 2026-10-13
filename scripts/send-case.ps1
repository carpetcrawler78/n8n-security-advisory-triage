# Send one test case to workflow 1.
# Einen Testfall an Workflow 1 schicken.
#
#   .\scripts\send-case.ps1 PA-01
#   .\scripts\send-case.ps1 PA-01 -WebhookUrl http://localhost:5678/webhook-test/advisory-input
#
# Default: production URL (workflow 1 is active after scripts/setup-n8n).
# Standard: Produktions-URL (Workflow 1 ist nach scripts/setup-n8n aktiv).
# Test URL: click "Execute workflow" in workflow 1 first. / Test-URL: vorher in Workflow 1 auf "Execute workflow" klicken.
#
# The body is sent as UTF-8 bytes so that umlauts arrive unchanged.
# Der Body wird als UTF-8-Bytes geschickt, damit Umlaute unveraendert ankommen.
param(
    [Parameter(Mandatory = $true)][string]$CaseId,
    [string]$WebhookUrl = "http://localhost:5678/webhook/advisory-input"
)

$file = Join-Path $PSScriptRoot "..\examples\requests\$CaseId.json"
$bytes = [System.IO.File]::ReadAllBytes((Resolve-Path $file))

Invoke-RestMethod -Method Post -Uri $WebhookUrl `
    -ContentType "application/json; charset=utf-8" `
    -Body $bytes
