# n8n Security Advisory Triage

**English** · [Deutsch](README.de.md)

An n8n prototype that checks vendor security advisories against an asset inventory and records, for each advisory, whether customers may be affected. A language model reads the free text; fixed rules make every decision.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/screenshots/workflow2-dark.png">
  <img alt="Workflow 2 – Advisory Processing (19 n8n nodes)" src="assets/screenshots/workflow2-light.png">
</picture>

## The scenario

A managed service provider (MSP) looks after the IT of many small businesses. Software vendors send security advisories by e-mail, as PDF, through portals or as feeds. For each advisory someone has to find out which customers run the affected product in an affected version. The prototype automates this step – from the incoming advisory to a stored, traceable decision. It does not patch and does not contact customers.

All companies, products, customers and advisories are fictional; all data is synthetic.

## How it works

**Workflow 1 – Advisory Input:**

<img src="assets/n8n-icons/n8n_webhook.png" width="20" height="20" alt="Webhook"> Webhook → <img src="assets/n8n-icons/n8n_set_pen.png" width="20" height="20" alt="Edit Fields"> Edit Fields → <img src="assets/n8n-icons/n8n_postgres.png" width="20" height="20" alt="PostgreSQL"> store the request with status `NEW` → reply `HTTP 202`

**Workflow 2 – Advisory Processing (19 nodes):** <img src="assets/n8n-icons/n8n_bolt.png" width="20" height="20" alt="Trigger"> started manually

1. <img src="assets/n8n-icons/n8n_postgres.png" width="20" height="20" alt="PostgreSQL"> claim the oldest `NEW` request (`FOR UPDATE SKIP LOCKED`)
2. <img src="assets/n8n-icons/n8n_set_pen.png" width="20" height="20" alt="Edit Fields"> structured sources: map fields directly, **without** LLM – free text: LLM extracts vendor, product, versions and evidence
3. Python validation: required fields, version rules, every evidence quote must occur **verbatim** in the original text
4. exact match of product and version against the asset inventory
5. fixed rules set one of four statuses, <img src="assets/n8n-icons/n8n_postgres.png" width="20" height="20" alt="PostgreSQL"> the result is stored

| Status | Meaning |
| --- | --- |
| `POTENTIALLY_AFFECTED` | product and affected version match at least one asset |
| `REVIEW_REQUIRED` | information missing, unclear or contradictory |
| `NO_MATCH_FOUND` | no match in the existing inventory – not an all-clear |
| `INVALID_ADVISORY` | not a security advisory (e.g. release notes, marketing) |

**Design decisions**

- The LLM only extracts. It never sees the inventory and never decides status, matches or routing.
- Evidence is checked against the original text, so the extraction can be traced back.
- Structured sources skip the LLM.
- Every request is stored before processing; technical errors end as `ERROR` and can be repeated.
- When information is unclear, the result is `REVIEW_REQUIRED` – nothing is guessed.

Details: [docs/architecture.md](docs/architecture.md)

## Examples: from input to decision

Three test advisories at opposite ends: a machine-generated vendor e-mail and two informal phone notes from the service desk. The input texts are German, as in the scenario.

### 1. Automated vendor e-mail (PA-01)

> Von: security-notifications@musterwerk.example<br>
> Betreff: Sicherheitsinformation MS-2026-014 – MusterLink Remote Gateway<br>
> Meldungstyp: Security Advisory · Herstellerbewertung: Hoch
>
> Bei einer internen Sicherheitsprüfung wurde ein Fehler in der Anmeldekomponente von MusterLink Remote Gateway festgestellt. […] Betroffen sind die Versionen 2.3.0 bis einschließlich 2.3.2. Installationen ab Version 2.4.0 sind nach unserem derzeitigen Kenntnisstand nicht betroffen. […] Eine CVE-Nummer wurde bislang nicht vergeben.

| Step | Result |
| --- | --- |
| Workflow 1 | stored as `NEW`, `payload_type = unstructured` |
| LLM extraction | vendor *Musterwerk Systems GmbH*, product *MusterLink Remote Gateway*, rule `range` 2.3.0–2.3.2 (both inclusive), fixed in 2.4.0, reference MS-2026-014, no CVE |
| Validation | schema valid; all three evidence quotes occur verbatim in the text |
| Matching | A-REM-01 (2.3.1) ✓ · A-REM-02 (2.3.2) ✓ · C-REM-01 (2.3.0) ✓ · B-REM-01 (2.4.0) ✗ already fixed |
| **Decision** | **`POTENTIALLY_AFFECTED`** – `PRODUCT_AND_VERSION_MATCH`, three assets at customers A and C |

<details>
<summary>Extracted facts (JSON, as in the notebook)</summary>

```json
{
  "is_security_advisory": true,
  "advisory_reference": "MS-2026-014",
  "cve_ids": [],
  "affected_products": [{
    "vendor": "Musterwerk Systems GmbH",
    "product": "MusterLink Remote Gateway",
    "affected_version_raw": "Versionen 2.3.0 bis einschließlich 2.3.2",
    "version_rule_type": "range",
    "lower_bound": "2.3.0", "lower_inclusive": true,
    "upper_bound": "2.3.2", "upper_inclusive": true,
    "fixed_version": "2.4.0"
  }],
  "severity_stated_by_source": "Hoch",
  "missing_information": [],
  "evidence_quotes": [
    "Bei einer internen Sicherheitsprüfung wurde ein Fehler in der Anmeldekomponente von MusterLink Remote Gateway festgestellt.",
    "Betroffen sind die Versionen 2.3.0 bis einschließlich 2.3.2.",
    "Installationen ab Version 2.4.0 sind nach unserem derzeitigen Kenntnisstand nicht betroffen."
  ]
}
```
</details>

### 2. Phone note with a clear version (PA-04)

> Interne Service-Desk-Notiz – erfasst nach Telefonat
>
> Jemand von Warenstrom Software GmbH hat angerufen, ziemlich kurzfristig, wollte eigentlich nur schnell Bescheid geben. Es geht wohl um WarenFlow ERP, ein Sicherheitsthema beim Im- oder Export von Dokumenten, genau wusste er es selbst nicht mehr, aber er war sich sicher: alle Versionen bis einschließlich 3.8 sind betroffen, ab 3.9 sei es behoben. […] Ein schriftliches Bulletin soll noch folgen.

| Step | Result |
| --- | --- |
| Workflow 1 | stored as `NEW`, `source_channel = phone` |
| LLM extraction | product *WarenFlow ERP*, rule `through` – up to and including 3.8, fixed in 3.9 |
| Validation | schema and evidence valid – no table, no CVE, still a clear version limit |
| Matching | C-ERP-01 (3.8) ✓ – the inclusive upper bound counts |
| **Decision** | **`POTENTIALLY_AFFECTED`** – one asset at customer C |

### 3. Phone note without a version (RR-04)

> Interne Service-Desk-Notiz – erfasst nach Telefonat
>
> Techniker von Anlagenblick GmbH hat angerufen und vor einem möglichen Problem bei PlantView HMI gewarnt: Bei bestimmten Netzwerkkonfigurationen könne die Anmeldemaske umgangen werden. Er war sich nicht sicher, ob das nur die aktuelle Version oder auch ältere Stände betrifft […]

| Step | Result |
| --- | --- |
| Workflow 1 | stored as `NEW`, `source_channel = phone` |
| LLM extraction | product *PlantView HMI* recognised; the affected version is explicitly unclear |
| Matching | product is in the inventory (B-HMI-01, 7.4), but the version cannot be checked |
| **Decision** | **`REVIEW_REQUIRED`** – `VERSION_INFORMATION_UNCLEAR`; B-HMI-01 is **not** flagged just because it is the only PlantView installation |

The same kind of input – an informal phone note – ends in two different decisions, and the difference comes from the fixed rules, not from the model. All 15 cases with input texts and expected results: [`data/synthetic_security_advisories.md`](data/synthetic_security_advisories.md).

## Results

In the original test setup, all 15 synthetic test cases (4 × affected, 4 × no match, 4 × review, 3 × no advisory; via e-mail, PDF, portal and phone) reach the expected status. Runtime per request: about 3.4–5.4 s with a cloud model (`openai/gpt-oss-20b` via Groq, test setup).

In the Docker run with n8n 2.42.7, 14 of 15 cases reach the expected status. PA-03 reproducibly ends as `REVIEW_REQUIRED` instead of `POTENTIALLY_AFFECTED`: the match finds B-HMI-01, but the model enters "Andere Versionen wurden … nicht bewertet" (other versions were not assessed) as missing information, and `Decide Status` routes every missing item to review. The deviation goes in the cautious direction (no missed match). Prompt and rules were not tightened, because every change requires a full regression run. Details: [docs/architecture.md](docs/architecture.md#repeat-with-the-docker-setup).

## Repository

```text
workflows/          n8n exports of workflow 1 and 2
sql/                schema and synthetic asset inventory
examples/requests/  the 15 test cases as webhook requests
scripts/            set up n8n, send a test case (bash, PowerShell)
data/               test advisories with expected results (German)
docs/               architecture (English, German)
notebooks/          both workflows as plain Python, runs without n8n
assets/             workflow 2 diagram (PNG light/dark, standalone HTML), node icons
```

## Run it locally

Requirements: Docker and an API key for Groq. Other chat models can replace the Groq node in n8n; only Groq has been tested.

1. `cp .env.example .env` and set `POSTGRES_PASSWORD`, `N8N_RUNNERS_AUTH_TOKEN` (any random string) and `GROQ_API_KEY`.
2. `docker compose up -d` – starts PostgreSQL (schema and inventory are created on first start), n8n and the task runners for the Code nodes (workflow 2 contains a Python node, which needs the separate `n8nio/runners` container).
3. Import credentials and workflows and activate workflow 1:
   ```bash
   ./scripts/setup-n8n.sh                # PowerShell: .\scripts\setup-n8n.ps1
   ```
   The script creates the credentials **Postgres account** and **Groq account** from `.env`, imports both workflows and restarts n8n. Running it again skips what already exists.
   If PowerShell refuses to run scripts: `powershell -ExecutionPolicy Bypass -File .\scripts\setup-n8n.ps1` (same for `send-case.ps1`).
4. Send a test case to the production webhook of workflow 1:
   ```bash
   ./scripts/send-case.sh PA-01          # PowerShell: .\scripts\send-case.ps1 PA-01
   ```
   The reply is `202` with the `request_id`.
5. Open http://localhost:5678, create the local n8n account, open workflow 2 and click **Execute workflow**. Each run processes the oldest request with status `NEW`. The result is in the database:
   ```bash
   docker compose exec postgres psql -U advisory -d advisory \
     -c "SELECT request_id, status, matched_assets FROM advisory_requests;"
   ```

With Groq's free tier (8,000 tokens per minute), start workflow 2 at most about once per minute. Faster runs exceed the rate limit, end as `ERROR` and can be repeated:

```bash
docker compose exec postgres psql -U advisory -d advisory \
  -c "UPDATE advisory_requests SET processing_status = 'NEW' WHERE processing_status = 'ERROR';"
```

To start over with an empty database and a fresh n8n: `docker compose down -v`, then continue with step 2. The SQL files in `sql/` only run when the database volume is created.

The prototype was developed against a hosted PostgreSQL (Supabase). Schema and Docker setup were reconstructed from the workflow exports for this repository. The complete Docker run was repeated end to end with n8n 2.42.7, PostgreSQL 16 and `openai/gpt-oss-20b` via Groq: setup, import and all 15 webhook requests work as described. Result: see [Results](#results).

Without n8n: [`notebooks/workflow_in_python.ipynb`](notebooks/workflow_in_python.ipynb) runs the same logic with the Python standard library.

## Limitations

Workflow 2 is started manually, the webhook has no authentication, and the structured path expects input that already matches the target schema. The full list and the path to production are in [docs/architecture.md](docs/architecture.md#8-limitations-of-the-prototype).

## License

[MIT](LICENSE). Node icons: [n8n](https://n8n.io); PostgreSQL logo: PostgreSQL Global Development Group.

## Language

The scenario is set at a German MSP. Test advisories, the extraction prompt and code comments are therefore in German; the documentation is available in English and German.
