-- =====================================================================================
-- Cloud Sync — Configuration Table Design (Part A design rulings)
-- =====================================================================================
-- Exported: 2026-08-11
-- Scope: the per-pipeline / per-source configuration tables that back the design
--        decisions recorded in questions.md Section A and docs/team-input.md.
--
--   A3 — readiness  (CS-021): a parameterised COUNT(*) readiness poll
--   A4 — retry      (CS-016): deterministic exponential backoff, NO jitter
--   A6 — retention  (CS-059): per-source / per-zone retention (values pending
--                             compliance sign-off, Q-03)
--
-- Dialect: PostgreSQL (the DAL's own store). Proposed defaults are the seed values
-- recorded in questions.md; per-pipeline / per-source rows override them.
--
-- Parent tables (assumed to already exist in the Source Registry):
--   pipeline_config(pipeline_id ...)   -- one row per registered pipeline
--   source_registry(source_id ...)     -- one row per registered source system
-- The FKs below reference those; adjust names to match the live schema.
--
-- SECRETS / CONJUR (D22, CS-002): NONE of these tables store credentials. Source/DB
-- secrets are resolved at point-of-use from CyberArk Vault via Conjur, by reference key
-- (the reference lives on the source connection config, not here). A4 (retry) and A6
-- (retention) never touch secrets; A3 (readiness) reuses the source's Conjur-resolved
-- connection. See concepts/dal-security-authentication-and-secrets.md.
-- =====================================================================================


-- -------------------------------------------------------------------------------------
-- A3 — Readiness poll configuration (CS-021)  [relational sources]
-- -------------------------------------------------------------------------------------
-- Readiness is a configured, parameterised SELECT COUNT(*) against the source's control
-- table, bound by :batch_date and filtered by a ready-status set. The source is READY
-- when COUNT(*) >= readiness_expected_count. Window/interval live here (not in code).
-- Outcomes (CS-021): poll-window expiry -> run.fail(READINESS_TIMEOUT) + alert (CS-043),
-- no auto-retry (operator replays, CS-041); a readiness *query* error retries per CS-016.
--
-- SECRETS / CONJUR (D22, CS-002): this table holds NO credentials. The readiness poll's
-- DB connection reuses the source's registered connection; its credential is resolved at
-- point-of-use from CyberArk Vault via Conjur, by reference key (auth methods 3->4/5).
-- Nothing here stores a raw credential (no raw credentials are ever stored in the
-- Source Registry / config). See concepts/dal-security-authentication-and-secrets.md.
CREATE TABLE pipeline_readiness_config (
    pipeline_id                UUID        PRIMARY KEY
                                           REFERENCES pipeline_config (pipeline_id) ON DELETE CASCADE,

    -- Parameterised readiness query. MUST be a single-value SELECT COUNT(*) that binds
    -- :batch_date and filters on the source's ready/terminal status set, e.g.:
    --   SELECT COUNT(*) FROM BATCH_CONTROL
    --   WHERE Business_Date = :batch_date AND Status IN ('COMPLETE','DONE')
    readiness_query            TEXT        NOT NULL,

    -- Count that means "ready" (default >= 1 row in a ready state).
    readiness_expected_count   INTEGER     NOT NULL DEFAULT 1
                                           CHECK (readiness_expected_count >= 0),

    -- Polling cadence: a "not ready" result is expected waiting, NOT a retry.
    -- 30s prod (bounds shared source-DB load, CS-047); 5s demo.
    poll_interval_seconds      INTEGER     NOT NULL DEFAULT 30
                                           CHECK (poll_interval_seconds > 0),

    -- Give-up window. MUST be < the pipeline's SLA deadline so READINESS_TIMEOUT fires
    -- before the SLA_BREACH backstop. Cross-table (SLA) check is enforced at onboarding
    -- validation (CS-055), not as a DB constraint.
    poll_window_minutes        INTEGER     NOT NULL DEFAULT 60
                                           CHECK (poll_window_minutes > 0),

    created_at                 TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                 TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE  pipeline_readiness_config              IS 'A3/CS-021 readiness poll config (COUNT(*) poll; window/interval per pipeline).';
COMMENT ON COLUMN pipeline_readiness_config.readiness_query          IS 'Parameterised SELECT COUNT(*); binds :batch_date + status filter.';
COMMENT ON COLUMN pipeline_readiness_config.readiness_expected_count IS 'Ready when COUNT(*) >= this value (default 1).';
COMMENT ON COLUMN pipeline_readiness_config.poll_window_minutes      IS 'Give-up window; MUST be < pipeline SLA (validated at onboarding, CS-055).';


-- -------------------------------------------------------------------------------------
-- A4 — Retry & backoff configuration (CS-016)
-- -------------------------------------------------------------------------------------
-- Deterministic exponential backoff, NO jitter: delay = min(cap, base * multiplier^attempt).
-- transient -> retry to the configured limit + checkpoint resume; permanent -> fail;
-- exhaustion -> run.fail() + alert (CS-043) + quarantine (CS-042).
CREATE TABLE pipeline_retry_config (
    pipeline_id          UUID          PRIMARY KEY
                                       REFERENCES pipeline_config (pipeline_id) ON DELETE CASCADE,

    base_delay_seconds   INTEGER       NOT NULL DEFAULT 5
                                       CHECK (base_delay_seconds > 0),
    multiplier           NUMERIC(4,2)  NOT NULL DEFAULT 2.0
                                       CHECK (multiplier >= 1),
    max_delay_seconds    INTEGER       NOT NULL DEFAULT 300
                                       CHECK (max_delay_seconds >= base_delay_seconds),
    max_attempts         INTEGER       NOT NULL DEFAULT 5
                                       CHECK (max_attempts >= 1),
    -- No jitter column by design (deterministic backoff).

    created_at           TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ   NOT NULL DEFAULT now()
);

COMMENT ON TABLE pipeline_retry_config IS 'A4/CS-016 retry schedule (deterministic exponential, no jitter): delay = min(cap, base * multiplier^attempt).';


-- Global seed map: which error codes are TRANSIENT vs PERMANENT vs NEVER_RETRIED.
-- Not per-pipeline; seeds the retry engine's classification. Per-pipeline overrides,
-- if ever needed, would add a pipeline_id column — omitted here (single default map).
CREATE TABLE retry_error_classification (
    error_code    VARCHAR(64)  PRIMARY KEY,
    error_class   VARCHAR(16)  NOT NULL
                               CHECK (error_class IN ('TRANSIENT', 'PERMANENT', 'NEVER_RETRIED')),
    cs_ref        VARCHAR(64),
    notes         TEXT
);

COMMENT ON TABLE retry_error_classification IS 'A4/CS-016 seed error-class map consumed by the retry engine.';

-- Seed defaults (from questions.md A4 note) --------------------------------------------
INSERT INTO retry_error_classification (error_code, error_class, cs_ref, notes) VALUES
    -- TRANSIENT (retry with backoff)
    ('NETWORK_ERROR',              'TRANSIENT',     NULL,           'connection reset / refused'),
    ('SOCKET_TIMEOUT',             'TRANSIENT',     NULL,           'socket / query / read timeout'),
    ('THROTTLED',                  'TRANSIENT',     NULL,           'rate-limit; honour Retry-After'),
    ('CREDENTIAL_RESOLUTION',      'TRANSIENT',     'CS-002',       'vault temporarily unreachable'),
    ('CLOUD_5XX',                  'TRANSIENT',     NULL,           'S3/cloud 5xx / 503 SlowDown / RequestTimeout'),
    ('READINESS_QUERY_ERROR',      'TRANSIENT',     'CS-021',       'readiness query itself errored (<> "not ready")'),
    ('DB_DEADLOCK',                'TRANSIENT',     NULL,           'deadlock / lock-timeout'),
    ('CONNECTION_DROPPED_MIDREAD', 'TRANSIENT',     'CS-004/006',   'discard partial, re-read'),
    -- PERMANENT (fail now)
    ('CONFIG_ERROR',               'PERMANENT',     NULL,           'config error / unknown pipeline'),
    ('SOURCE_FILE_ACCESS_DENIED',  'PERMANENT',     NULL,           '403 / AccessDenied'),
    ('SOURCE_FILE_NOT_FOUND',      'PERMANENT',     NULL,           'source not delivered -> replay, not retry'),
    ('SOURCE_FILE_TOO_LARGE',      'PERMANENT',     'CS-019',       'exceeds max size'),
    ('SOURCE_OBJECT_CHANGED',      'PERMANENT',     'CS-007',       'ETag 412'),
    ('UNSUPPORTED_TYPE',           'PERMANENT',     'CS-003/008',   'no approved mapping'),
    ('FORMAT_SIZE_MISMATCH',       'PERMANENT',     'CS-054',       'format / size mismatch'),
    ('READINESS_TIMEOUT',          'PERMANENT',     'CS-021',       'poll window expired'),
    -- NEVER_RETRIED (terminal by design; re-acquire via replay CS-041)
    ('VALIDATE_FAIL',              'NEVER_RETRIED', 'CS-012/053',   're-acquire via replay (CS-041)');


-- -------------------------------------------------------------------------------------
-- A6 — Retention configuration (CS-059)  [per source]
-- -------------------------------------------------------------------------------------
-- Values live here per source (per-zone within the row). VALUES ARE A COMPLIANCE
-- DECISION (Q-03) — defaults below are the recommended seeds pending compliance sign-off.
-- Governing rule enforced as a CHECK: audit retention >= zone retention + max replay
-- latency, so the CS-015 dedup guard is never archived while a batch could still be
-- replayed. Cleanup is fail-safe to retain (NULL => delete nothing).
CREATE TABLE source_retention_config (
    source_id                          UUID        PRIMARY KEY
                                                   REFERENCES source_registry (source_id) ON DELETE CASCADE,

    audit_retention_days               INTEGER     NOT NULL DEFAULT 90
                                                   CHECK (audit_retention_days > 0),
    dedup_window_days                  INTEGER     NOT NULL DEFAULT 30
                                                   CHECK (dedup_window_days > 0),
    staging_zone_retention_days        INTEGER     NOT NULL DEFAULT 7
                                                   CHECK (staging_zone_retention_days > 0),
    transfer_ready_zone_retention_days INTEGER     NOT NULL DEFAULT 7
                                                   CHECK (transfer_ready_zone_retention_days > 0),
    max_replay_latency_days            INTEGER     NOT NULL DEFAULT 30
                                                   CHECK (max_replay_latency_days > 0),

    -- Long-term regulatory archive (cold storage), SEPARATE from the hot-store defaults
    -- above and compliance-owned. NULL => no regulatory archive configured for this source.
    regulatory_archive_years           INTEGER     NULL
                                                   CHECK (regulatory_archive_years IS NULL OR regulatory_archive_years > 0),

    created_at                         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                         TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Governing rule (A6): audit retention must cover every zone plus the replay window.
    CONSTRAINT chk_audit_covers_staging
        CHECK (audit_retention_days >= staging_zone_retention_days + max_replay_latency_days),
    CONSTRAINT chk_audit_covers_transfer_ready
        CHECK (audit_retention_days >= transfer_ready_zone_retention_days + max_replay_latency_days),
    -- Dedup guard must outlive the replay window (CS-015).
    CONSTRAINT chk_dedup_covers_replay
        CHECK (dedup_window_days >= max_replay_latency_days)
);

COMMENT ON TABLE  source_retention_config                        IS 'A6/CS-059 per-source retention. VALUES pending compliance sign-off (Q-03).';
COMMENT ON COLUMN source_retention_config.regulatory_archive_years IS 'Compliance-owned cold-storage archive (e.g. ~7yr, confirm vs bank records schedule); separate from hot-store retention.';
