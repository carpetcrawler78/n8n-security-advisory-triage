#!/usr/bin/env bash
# Send one test case to workflow 1.
# Einen Testfall an Workflow 1 schicken.
#
#   ./scripts/send-case.sh PA-01
#   WEBHOOK_URL=http://localhost:5678/webhook-test/advisory-input ./scripts/send-case.sh PA-01
#
# Default: production URL (workflow 1 is active after scripts/setup-n8n).
# Standard: Produktions-URL (Workflow 1 ist nach scripts/setup-n8n aktiv).
# Test URL: click "Execute workflow" in workflow 1 first. / Test-URL: vorher in Workflow 1 auf "Execute workflow" klicken.
set -euo pipefail

case_id="${1:?usage: send-case.sh <CASE-ID>, e.g. PA-01}"
url="${WEBHOOK_URL:-http://localhost:5678/webhook/advisory-input}"
file="$(dirname "$0")/../examples/requests/${case_id}.json"

curl --fail --silent --show-error \
  -H "Content-Type: application/json; charset=utf-8" \
  --data-binary "@${file}" \
  "$url"
echo
