-- Schema for the n8n security advisory triage prototype.
-- Reconstructed from the workflow exports (column names and types as used by the
-- n8n nodes). The prototype itself ran on a managed PostgreSQL instance (Supabase).
--
-- Schema für den Prototyp. Aus den Workflow-Exporten rekonstruiert (Spaltennamen
-- und Typen so, wie die n8n-Knoten sie verwenden). Der Prototyp lief auf einer
-- verwalteten PostgreSQL-Instanz (Supabase).

-- One row per incoming advisory (groups A, B, C and D of the data model).
-- Eine Zeile pro eingehendem Hinweis (Gruppen A, B, C und D des Datenmodells).
CREATE TABLE IF NOT EXISTS public.advisory_requests (
    -- A: intake / Eingang
    request_id                TEXT PRIMARY KEY,
    received_at               TIMESTAMPTZ NOT NULL,
    source_channel            TEXT        NOT NULL,
    payload_type              TEXT        NOT NULL
        CHECK (payload_type IN ('structured', 'unstructured')),
    raw_text                  TEXT        NOT NULL,

    -- B: advisory facts / Fakten aus dem Hinweis
    is_security_advisory      BOOLEAN,
    advisory_reference        TEXT,
    cve_ids                   JSONB,
    affected_products         JSONB,
    severity_stated_by_source TEXT,
    recommended_action        TEXT,
    missing_information       JSONB,
    evidence_quotes           JSONB,

    -- C: decision / Entscheidung
    status                    TEXT,
    matched_assets            JSONB,
    reason_codes              JSONB,
    decided_at                TIMESTAMPTZ,

    -- D: processing and audit / Verarbeitung und Nachweis
    extraction_method         TEXT,
    model_provider            TEXT,
    model_name                TEXT,
    processing_status         TEXT        NOT NULL DEFAULT 'NEW'
        CHECK (processing_status IN ('NEW', 'PROCESSING', 'DONE', 'ERROR')),
    attempt_count             INTEGER     NOT NULL DEFAULT 0
        CHECK (attempt_count >= 0),
    error_detail              TEXT,
    processed_at              TIMESTAMPTZ,
    schema_version            INTEGER     NOT NULL DEFAULT 1
);

-- Supports claiming the oldest NEW request.
-- Unterstützt die Übernahme des ältesten NEW-Vorgangs.
CREATE INDEX IF NOT EXISTS advisory_requests_queue_idx
    ON public.advisory_requests (processing_status, received_at, request_id);

-- One row per product installation.
-- Eine Zeile pro Produktinstallation.
CREATE TABLE IF NOT EXISTS public.asset_inventory (
    id                BIGSERIAL PRIMARY KEY,
    asset_id          TEXT NOT NULL UNIQUE,
    customer_name     TEXT NOT NULL,
    device_name       TEXT NOT NULL,
    vendor            TEXT NOT NULL,
    product           TEXT NOT NULL,
    installed_version TEXT NOT NULL
);
