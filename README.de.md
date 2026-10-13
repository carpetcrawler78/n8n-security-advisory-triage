# n8n Security Advisory Triage

[English](README.md) · **Deutsch**

Ein n8n-Prototyp, der Sicherheitshinweise von Softwareherstellern (Security Advisories) mit einem Asset-Inventar abgleicht und für jeden Hinweis festhält, ob Kunden betroffen sein könnten. Ein Sprachmodell liest den Freitext; jede Entscheidung treffen feste Regeln.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/screenshots/workflow2-dark.png">
  <img alt="Workflow 2 – Advisory Processing (19 n8n-Knoten)" src="assets/screenshots/workflow2-light.png">
</picture>

## Das Szenario

Ein IT-Dienstleister (MSP, Managed Service Provider) betreut die IT vieler kleiner Betriebe. Softwarehersteller verschicken Sicherheitshinweise per E-Mail, als PDF, über Portale oder als Feed. Bei jedem Hinweis muss jemand herausfinden, welche Kunden das betroffene Produkt in einer betroffenen Version einsetzen. Der Prototyp automatisiert diesen Schritt – vom eingehenden Hinweis bis zur gespeicherten, nachvollziehbaren Entscheidung. Er spielt keine Updates ein und schreibt keine Kunden an.

Alle Firmen, Produkte, Kunden und Hinweise sind erfunden; alle Daten sind synthetisch.

## So funktioniert es

**Workflow 1 – Advisory Input:**

<img src="assets/n8n-icons/n8n_webhook.png" width="20" height="20" alt="Webhook"> Webhook → <img src="assets/n8n-icons/n8n_set_pen.png" width="20" height="20" alt="Edit Fields"> Edit Fields → <img src="assets/n8n-icons/n8n_postgres.png" width="20" height="20" alt="PostgreSQL"> Vorgang mit Status `NEW` speichern → Antwort `HTTP 202`

**Workflow 2 – Advisory Processing (19 Knoten):** <img src="assets/n8n-icons/n8n_bolt.png" width="20" height="20" alt="Trigger"> Start von Hand

1. <img src="assets/n8n-icons/n8n_postgres.png" width="20" height="20" alt="PostgreSQL"> ältesten `NEW`-Vorgang übernehmen (`FOR UPDATE SKIP LOCKED`)
2. <img src="assets/n8n-icons/n8n_set_pen.png" width="20" height="20" alt="Edit Fields"> strukturierte Quellen: Felder direkt zuordnen, **ohne** Sprachmodell – Freitext: Sprachmodell liest Hersteller, Produkt, Versionen und Belegstellen heraus
3. Prüfung in Python: Pflichtfelder, Versionsregeln, jede Belegstelle muss **wörtlich** im Originaltext stehen
4. exakter Abgleich von Produkt und Version mit dem Asset-Inventar
5. feste Regeln setzen einen von vier Status, <img src="assets/n8n-icons/n8n_postgres.png" width="20" height="20" alt="PostgreSQL"> das Ergebnis wird gespeichert

| Status | Bedeutung |
| --- | --- |
| `POTENTIALLY_AFFECTED` | Produkt und betroffene Version passen zu mindestens einem Asset |
| `REVIEW_REQUIRED` | Angaben fehlen, sind unklar oder widersprüchlich |
| `NO_MATCH_FOUND` | kein Treffer im vorhandenen Inventar – keine Entwarnung |
| `INVALID_ADVISORY` | kein Sicherheitshinweis (z. B. Release Notes, Werbung) |

**Entwurfsentscheidungen**

- Das Sprachmodell extrahiert nur. Es sieht das Inventar nie und entscheidet weder Status noch Treffer noch Weiterleitung.
- Belegstellen werden gegen den Originaltext geprüft; so lässt sich die Extraktion zurückverfolgen.
- Strukturierte Quellen laufen am Sprachmodell vorbei.
- Jeder Vorgang wird vor der Verarbeitung gespeichert; ein fehlgeschlagener Aufruf des Sprachmodells endet als `ERROR` und lässt sich wiederholen.
- Sind Angaben unklar, lautet das Ergebnis `REVIEW_REQUIRED` – geraten wird nicht.

Details: [docs/architecture.de.md](docs/architecture.de.md)

## Beispiele: vom Eingang zur Entscheidung

Drei Testmeldungen von entgegengesetzten Enden: eine automatisch erzeugte Hersteller-E-Mail und zwei frei formulierte Telefonnotizen aus dem Service-Desk.

### 1. Automatische Hersteller-E-Mail (PA-01)

> Von: security-notifications@musterwerk.example<br>
> Betreff: Sicherheitsinformation MS-2026-014 – MusterLink Remote Gateway<br>
> Meldungstyp: Security Advisory · Herstellerbewertung: Hoch
>
> Bei einer internen Sicherheitsprüfung wurde ein Fehler in der Anmeldekomponente von MusterLink Remote Gateway festgestellt. […] Betroffen sind die Versionen 2.3.0 bis einschließlich 2.3.2. Installationen ab Version 2.4.0 sind nach unserem derzeitigen Kenntnisstand nicht betroffen. […] Eine CVE-Nummer wurde bislang nicht vergeben.

| Schritt | Ergebnis |
| --- | --- |
| Workflow 1 | gespeichert als `NEW`, `payload_type = unstructured` |
| Extraktion (Sprachmodell) | Hersteller *Musterwerk Systems GmbH*, Produkt *MusterLink Remote Gateway*, Regel `range` 2.3.0–2.3.2 (beide Grenzen einschließlich), behoben in 2.4.0, Kennung MS-2026-014, keine CVE |
| Prüfung | Schema gültig; alle drei Belegstellen stehen wörtlich im Text |
| Abgleich | A-REM-01 (2.3.1) ✓ · A-REM-02 (2.3.2) ✓ · C-REM-01 (2.3.0) ✓ · B-REM-01 (2.4.0) ✗ bereits behoben |
| **Entscheidung** | **`POTENTIALLY_AFFECTED`** – `PRODUCT_AND_VERSION_MATCH`, drei Assets bei Kunde A und C |

<details>
<summary>Extrahierte Fakten (JSON, wie im Notebook)</summary>

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

### 2. Telefonnotiz mit klarer Version (PA-04)

> Interne Service-Desk-Notiz – erfasst nach Telefonat
>
> Jemand von Warenstrom Software GmbH hat angerufen, ziemlich kurzfristig, wollte eigentlich nur schnell Bescheid geben. Es geht wohl um WarenFlow ERP, ein Sicherheitsthema beim Im- oder Export von Dokumenten, genau wusste er es selbst nicht mehr, aber er war sich sicher: alle Versionen bis einschließlich 3.8 sind betroffen, ab 3.9 sei es behoben. […] Ein schriftliches Bulletin soll noch folgen.

| Schritt | Ergebnis |
| --- | --- |
| Workflow 1 | gespeichert als `NEW`, `source_channel = phone` |
| Extraktion (Sprachmodell) | Produkt *WarenFlow ERP*, Regel `through` – bis einschließlich 3.8, behoben ab 3.9 |
| Prüfung | Schema und Belegstellen gültig – keine Tabelle, keine CVE, trotzdem eine klare Versionsgrenze |
| Abgleich | C-ERP-01 (3.8) ✓ – die Obergrenze zählt mit |
| **Entscheidung** | **`POTENTIALLY_AFFECTED`** – ein Asset bei Kunde C |

### 3. Telefonnotiz ohne Version (RR-04)

> Interne Service-Desk-Notiz – erfasst nach Telefonat
>
> Techniker von Anlagenblick GmbH hat angerufen und vor einem möglichen Problem bei PlantView HMI gewarnt: Bei bestimmten Netzwerkkonfigurationen könne die Anmeldemaske umgangen werden. Er war sich nicht sicher, ob das nur die aktuelle Version oder auch ältere Stände betrifft […]

| Schritt | Ergebnis |
| --- | --- |
| Workflow 1 | gespeichert als `NEW`, `source_channel = phone` |
| Extraktion (Sprachmodell) | Produkt *PlantView HMI* erkannt; die betroffene Version ist ausdrücklich unklar |
| Abgleich | Produkt steht im Inventar (B-HMI-01, 7.4), die Version lässt sich aber nicht prüfen |
| **Entscheidung** | **`REVIEW_REQUIRED`** – `VERSION_INFORMATION_UNCLEAR`; B-HMI-01 wird **nicht** markiert, nur weil es die einzige PlantView-Installation ist |

Dieselbe Art von Eingang – eine frei formulierte Telefonnotiz – führt zu zwei verschiedenen Entscheidungen, und den Unterschied machen die festen Regeln, nicht das Modell. Alle 15 Fälle mit Eingangstexten und erwarteten Ergebnissen: [`data/synthetic_security_advisories.md`](data/synthetic_security_advisories.md).

## Ergebnisse

Im ursprünglichen Testaufbau erreichen alle 15 synthetischen Testfälle (4 × betroffen, 4 × kein Treffer, 4 × Prüfung, 3 × kein Sicherheitshinweis; über E-Mail, PDF, Portal und Telefon) den erwarteten Status. Laufzeit pro Vorgang: etwa 3,4–5,4 s mit einem Cloud-Modell (`openai/gpt-oss-20b` über Groq, Testaufbau).

Im Docker-Lauf mit n8n 2.42.7 erreichen 14 von 15 Fällen den erwarteten Status. PA-03 endet reproduzierbar als `REVIEW_REQUIRED` statt `POTENTIALLY_AFFECTED`: Der Abgleich findet B-HMI-01, aber das Modell trägt „Andere Versionen wurden … nicht bewertet“ als fehlende Information ein, und `Decide Status` leitet jede fehlende Angabe zur Prüfung. Die Abweichung geht in die vorsichtige Richtung (kein übersehener Treffer). Prompt und Regeln wurden nicht nachgeschärft, weil jede Änderung einen vollständigen Regressionslauf erfordert. Details: [docs/architecture.de.md](docs/architecture.de.md#wiederholung-im-docker-aufbau).

## Aufbau des Repositorys

```text
workflows/          n8n-Exporte von Workflow 1 und 2
sql/                Schema und synthetisches Asset-Inventar
examples/requests/  die 15 Testfälle als Webhook-Anfragen
scripts/            n8n einrichten, Testfall verschicken (bash, PowerShell)
data/               Testmeldungen mit erwarteten Ergebnissen
docs/               Architektur (Englisch, Deutsch)
notebooks/          beide Workflows als reines Python, läuft ohne n8n
assets/             Diagramm von Workflow 2 (PNG hell/dunkel, eigenständiges HTML), Knoten-Symbole
```

## Lokal ausführen

Voraussetzungen: Docker und ein API-Key für Groq. Andere Chat-Modelle können den Groq-Knoten in n8n ersetzen; getestet ist nur Groq.

1. `cp .env.example .env` und `POSTGRES_PASSWORD`, `N8N_RUNNERS_AUTH_TOKEN` (beliebige Zufallszeichenkette) und `GROQ_API_KEY` setzen.
2. `docker compose up -d` – startet PostgreSQL (Schema und Inventar werden beim ersten Start angelegt), n8n und die Task-Runner für die Code-Knoten (Workflow 2 enthält einen Python-Knoten, der den separaten Container `n8nio/runners` braucht).
3. Zugangsdaten und Workflows importieren, Workflow 1 aktivieren:
   ```bash
   ./scripts/setup-n8n.sh                # PowerShell: .\scripts\setup-n8n.ps1
   ```
   Das Skript legt die Zugangsdaten **Postgres account** und **Groq account** aus `.env` an, importiert beide Workflows und startet n8n neu. Ein erneuter Aufruf überspringt, was schon vorhanden ist.
   Falls PowerShell keine Skripte ausführt: `powershell -ExecutionPolicy Bypass -File .\scripts\setup-n8n.ps1` (ebenso für `send-case.ps1`).
4. Einen Testfall an den Produktions-Webhook von Workflow 1 schicken:
   ```bash
   ./scripts/send-case.sh PA-01          # PowerShell: .\scripts\send-case.ps1 PA-01
   ```
   Die Antwort ist `202` mit der `request_id`.
5. http://localhost:5678 öffnen, das lokale n8n-Konto anlegen, Workflow 2 öffnen und auf **Execute workflow** klicken. Jeder Lauf verarbeitet den ältesten Vorgang mit Status `NEW`. Das Ergebnis steht in der Datenbank:
   ```bash
   docker compose exec postgres psql -U advisory -d advisory \
     -c "SELECT request_id, status, matched_assets FROM advisory_requests;"
   ```

Mit dem kostenlosen Groq-Zugang (8.000 Tokens pro Minute) Workflow 2 höchstens etwa einmal pro Minute starten. Schnellere Läufe überschreiten das Ratenlimit, enden als `ERROR` und lassen sich wiederholen:

```bash
docker compose exec postgres psql -U advisory -d advisory \
  -c "UPDATE advisory_requests SET processing_status = 'NEW' WHERE processing_status = 'ERROR';"
```

Neu anfangen mit leerer Datenbank und frischem n8n: `docker compose down -v`, dann weiter mit Schritt 2. Die SQL-Dateien in `sql/` laufen nur, wenn das Datenbank-Volume neu angelegt wird.

Der Prototyp wurde gegen ein gehostetes PostgreSQL (Supabase) entwickelt. Schema und Docker-Aufbau sind für dieses Repository aus den Workflow-Exporten nachgebaut. Der vollständige Docker-Lauf wurde mit n8n 2.42.7, PostgreSQL 16 und `openai/gpt-oss-20b` über Groq von Anfang bis Ende wiederholt: Einrichtung, Import und alle 15 Webhook-Anfragen funktionieren wie beschrieben. Ergebnis: siehe [Ergebnisse](#ergebnisse).

Ohne n8n: [`notebooks/workflow_in_python.ipynb`](notebooks/workflow_in_python.ipynb) führt dieselbe Logik mit der Python-Standardbibliothek aus.

## Grenzen

Workflow 2 wird von Hand gestartet, der Webhook hat keine Authentifizierung, und der strukturierte Weg erwartet Eingaben, die schon dem Zielschema entsprechen. Die vollständige Liste und der Weg in den Betrieb stehen in [docs/architecture.de.md](docs/architecture.de.md#8-grenzen-des-prototyps).

## Lizenz

[MIT](LICENSE). Knoten-Symbole: [n8n](https://n8n.io); PostgreSQL-Logo: PostgreSQL Global Development Group.

## Sprache

Das Szenario spielt bei einem deutschen IT-Dienstleister. Testmeldungen, Extraktions-Prompt und Code-Kommentare sind deshalb deutsch; die Dokumentation gibt es auf Englisch und Deutsch.
