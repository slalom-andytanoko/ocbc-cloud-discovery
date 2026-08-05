---
title: Source Registry and Audit Data Model (DAL)
category: concepts
tags: [ocbc, data-acquisition, data-model, postgresql, governance]
relationships:
  - target: "[[entities/cloud-data-acquisition-service]]"
    type: extends
  - target: "[[concepts/data-onboarding-orchestration-pipeline]]"
    type: related_to
sources: ["External: OCBC Data Acquisition Platform on AWS - v1.1.pdf", "External: uc1_scheduled_db_poll_narrative.docx", "External: OCBC Data Acquisition Platform on AWS - v1.3.md"]
summary: The three logical stores behind the DAL — the Source Registry (config), the Orchestration Audit table (run state, now also carrying the run driver's scheduling columns), and the source-owned read-only control data (polled for relational-source readiness only, as of v1.3) — plus the per-batch manifest contract.
provenance:
  extracted: 0.9
  inferred: 0.1
  ambiguous: 0.0
base_confidence: 0.74
lifecycle: draft
lifecycle_changed: 2026-07-31
tier: core
created: 2026-07-28
updated: 2026-07-31
---

# Source Registry and Audit Data Model (DAL)

> **Design maturity note:** this schema is explicitly marked *indicative* in v1.1/v1.3 (D03) — subject to change once a dedicated microservice-decomposition requirements session is held and signed off.

> **Update (v1.3, 31 Jul 2026):** file/object sources no longer have a DAL-side readiness poll — `source_file_watch_config` is removed, since those sources have no file-marker/completion signal and readiness is now the Control-M job dependency itself (see [[concepts/data-onboarding-orchestration-pipeline]]). `source_readiness_check` (relational sources only) is rewritten to be source-agnostic: a parameterised readiness query plus an expected ready value, with no fixed control-table shape assumed. The Orchestration Audit table now also carries the run driver's own scheduling-state columns. Each file/object pipeline entry names exactly **one** file or object — pattern-based multi-file matching is removed.

The DAL persists three logical stores, plus the source's own control data (relational sources only):

| Store | Location | Read/write pattern |
|---|---|---|
| **Source Registry** | On-prem PostgreSQL, prod; AWS (interim) in UAT | Read-only during execution; populated by a future-phase onboarding process |
| **Orchestration Audit** | Same PostgreSQL database as the Source Registry (D05) | Two disjoint writers — Orchestration Service writes `SCHEDULED_PULL` rows, Sync Push Service writes `SYNC_PUSH` rows |
| **BATCH_CONTROL** | Inside the source system's own database (e.g. Oracle) | Read-only, polled by the Orchestration Service; owned and written exclusively by the source system's own ETL |

## Source Registry — Class-Table Model (§11.1)

The registry uses a core `source`/`source_pipeline` model with trigger-specific extension tables, so one source system can run several extraction patterns across different trigger types:

| Table | Purpose |
|---|---|
| `source` | Master record for the source system (name, environment, data domain), plus (v1.3) the **maximum concurrent connections** the DAL may hold against it — sits here since several pipelines can share one source's connection capacity |
| `source_pipeline` | One extraction pattern per row: `trigger_type`, `connection_type` (JDBC / REST / SFTP·NFS·SMB / S3), `connection_ref`, priority, alert channel |
| `source_governance` | Classification, PII flag, retention, KMS key, sign-off (source level) |
| `source_schedule` | Cron, SLA deadline, concurrency, retry limits, and (v1.3) the scheduled-path `max_item_bytes` |
| `source_readiness_check` | **Relational sources only (v1.3).** Holds the registered, parameterised readiness query (any SQL returning a single comparable value), the expected ready value, JDBC connection reference, poll interval, and poll window. The DAL is agnostic to the source's own control-table structure — no fixed schema assumed. File/object sources need no readiness configuration; the Control-M job dependency is their readiness signal |
| `source_event_config` | Event-trigger metadata only: flag that the pipeline is coordinator-driven, expected coordinator identity, default routing (pull vs push). **Kafka topic/consumer-group/schema are deliberately not stored here** — that belongs to the out-of-scope coordinator service |
| `source_push_config` | Sync push: endpoint path, auth mechanism, payload schema, response timeout, and (v1.3) the **on-demand limits as configuration** — `max_payload_bytes`, `max_item_bytes`, `max_extract_duration_seconds`, `compression_skip_bytes`, each with a platform default per environment |
| `source_transfer_config` | DataSync task ARN, source/destination location ARNs, target tier/bucket/prefix, and (v1.3) the **landed prefix template** for the batch's objects (pull only) — configuration rather than a constant, since the landed layout is a contract with consuming applications |
| `source_extraction_table` | RDBMS extraction: table name, parameterised SQL template, output format, expected row-count threshold |
| `source_rest_config` | WFI/FileNet REST: base URL, object/query params, pagination, auth ref |

> **v1.3 removal:** `source_file_watch_config` (path/pattern, marker pattern, poll interval/window) no longer exists — file/object readiness is now signalled by the Control-M job dependency, not DAL-side polling.

`source_extraction_table.extraction_query_template` holds the parameterised SQL (e.g. a `WHERE trade_date = :batch_date` predicate). Supported parameters are bind parameters plus a small, registry-defined set of dynamic parameters (date offsets, run window) — the Integration Service binds these at runtime and never builds queries programmatically (D13).

### Illustrative attribute list (from the UC-1 narrative's earlier, flatter registry model)

The UC-1 narrative document describes a flatter, pre-D03-decomposition version of the same registry with a single illustrative attribute set: `source_id`, `source_name`, `active_flag`, `environment`, `connection_type`, `connection_string` (vault-resolved), `auth_type`, `trigger_type`, `schedule`, `sla_deadline`, `priority_tier`, `alert_channel`, `readiness_check_query`, `readiness_check_jdbc_ref`, `poll_interval_seconds`, `poll_window_start_utc`/`poll_window_end_utc`, `schema_version`, `last_run_timestamp`, `max_concurrent_runs`, `max_retry`, `data_sync_task_arn`, `data_owner`, `onboarding_status`, `security_signoff_flag`, `retention_years`, `kms_key_arn`, `data_domain`, `classification`, `pii_flag`. This maps onto the class-table model above; the two are the same concept described at two points in the design's evolution. `^[inferred]`

## Orchestration Audit Table (§11.3)

One record per run. Key fields: `run_id` (PK), `trace_id`, `caller_identity` (verified principal from the validated token), `idempotency_key` (push path; **v1.3: `UNIQUE` together with `caller_identity`**, not globally unique), `source_id`, `pipeline_id`, `batch_date`, `trigger_type` (`SCHEDULED_PULL` | `SYNC_PUSH`), `trigger_source` (`CONTROL_M` | `COORDINATOR` | `API`), `trigger_ref`, `status`, `checkpoint`, `retry_count`, `datasync_execution_arn` (pull only), `s3_uri` (push), `initiated_at`, `last_updated_at`, `completed_at`, `error_code`, `error_message`, `alert_sent`.

**Run driver columns (v1.3, pull path only).** The same row carries the run driver's scheduling state, so run state and scheduling state cannot diverge: `next_wake_at` (when the run is next due), `sla_deadline_at` (scanned to raise `SLA_BREACH`), `hold_reason`, `lease_owner` and `lease_expires_at` (which Orchestration replica owns the run, and when an abandoned run becomes reclaimable). These columns are null for `SYNC_PUSH` rows, which have no driver.

**Two-writer model with no contention.** The Orchestration Service writes only `SCHEDULED_PULL` rows (whether Control-M or event-trigger-coordinator initiated); the Sync Push Service writes only `SYNC_PUSH` rows. No row has two writers.

**Idempotency at scale.** The push path enforces idempotency with a **composite `UNIQUE` constraint on `(caller_identity, idempotency_key)`** (v1.3, corrected from a global-`UNIQUE` on `idempotency_key` alone) using an insert-first pattern — see [[concepts/sync-push-service-architecture]]. Scoping the key to the verified caller prevents two different callers who happen to choose the same idempotency value from colliding and one silently receiving the other's result/`s3_uri`. The pull path remains idempotent on `pipeline_id + batch_date`.

## Source Control Data (source-owned, read-only, relational sources only)

Resides inside the source system's own database (e.g. Oracle) — **not** part of the DAL and not on shared infrastructure. Its structure varies per source; the DAL is agnostic to it and only ever reads it via the registered `source_readiness_check` query (v1.3). An illustrative example, consistent with the bank's existing `BATCH_CONTROL`-style control-framework tables: `SELECT Status FROM BATCH_CONTROL WHERE Tablename = :table_name AND Business_Date = :batch_date`, expected value `Done`. File/object sources have no equivalent — readiness for them is the Control-M job dependency (see [[concepts/data-onboarding-orchestration-pipeline]]).

## Batch Manifest (`_manifest.json`) — §11.4

Every batch carries a manifest: a small JSON sidecar written **last**, after every data file, so its presence is the atomic "batch fully staged" signal. It travels with the batch across the on-prem→AWS boundary and lands in S3 alongside the data, giving a self-describing batch record where the on-prem audit database isn't reachable.

Standard contents: `run_id`, `trace_id`, `pipeline_id`, `batch_date`, `files[] {path, size_bytes, checksum}`, `file_count`, `total_bytes`, `content_fingerprint`, `schema_version`, `drift_detected`, `format` (`parquet` | `passthrough`); RDBMS extracts additionally carry per-table row counts.

| Stage (pull path) | Manifest action | Location |
|---|---|---|
| Integration (extract/pickup) | Writes `_manifest.json` last | `control-zone` |
| Control (validate/compress) | Reads it, verifies declared vs. actual, records compression result | `control-zone` |
| Security (classify/promote) | Tags `target_tier`, promotes with the batch | `control-zone` → `zone` (transfer-ready) |
| DataSync | Copies it as an ordinary object alongside the batch (no special handling) | `zone` → S3 |

On the push path, there are no staging zones, so the Sync Push Service assembles the manifest in-process and writes it to S3 alongside the landed object(s) under the same prefix — keeping the landed-batch record uniform across both modes.

## Related

- [[entities/cloud-data-acquisition-service]]
- [[concepts/data-onboarding-orchestration-pipeline]]
- [[concepts/temporal-io-workflow-orchestration]]
- [[concepts/sync-push-service-architecture]]
- [[reference/uc1-scheduled-db-poll-narrative]]
- [[reference/data-acquisition-platform-v1.1]]
- [[reference/data-acquisition-platform-v1.3]]

## Sources

- External: OCBC Data Acquisition Platform on AWS - v1.1.pdf
- External: uc1_scheduled_db_poll_narrative.docx
- External: OCBC Data Acquisition Platform on AWS - v1.3.md
