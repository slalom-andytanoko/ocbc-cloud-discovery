---
title: Data Onboarding Orchestration Pipeline
category: concepts
tags: [aws, orchestration, airflow, ocbc, data-acquisition]
relationships:
  - target: "[[entities/cloud-data-acquisition-service]]"
    type: derived_from
  - target: "[[concepts/data-tokenization-and-encryption]]"
    type: related_to
  - target: "[[concepts/temporal-io-workflow-orchestration]]"
    type: related_to
  - target: "[[concepts/source-registry-and-audit-data-model]]"
    type: related_to
  - target: "[[concepts/orchestrator-state-machine-integrity]]"
    type: related_to
sources: ["External: Mar 11 _Data-Acquisition-Service-LLD-NarrativeV1.0[63].pdf", "External: image001.png", "External: image002.png", "External: OCBC Data Acquisition Platform on AWS - v1.1.pdf", "External: uc1_scheduled_db_poll_narrative.docx", "External: OCBC Data Acquisition Platform on AWS - v1.3.md", "External: Re__IaC_Deployment_Process/OCBC Data Acquisition Platform on AWS - v1.3.md", "External: Re__IaC_Deployment_Process/OCBC Data Acquisition - Cloud Sync Detailed Design.md", "External: OCBC Data Acquisition - Orchestration Service Code Assessment.md"]
summary: The on-prem run lifecycle for scheduled-pull ingestion — Control-M (external fire) + an in-service orchestration run driver (durable execution), with a dedicated Scheduler Job Adapter (v1.3) bridging Control-M's synchronous job model to the DAL's async run lifecycle, file/object readiness driven by the Control-M job dependency rather than polling, and (2026-08-03) a post-landing decompression step. The Detailed Design v0.1 supersedes the "Four Services" boundary model below with an Orchestrator/Worker/Sync Push/Operations Service decomposition.
provenance:
  extracted: 0.85
  inferred: 0.15
  ambiguous: 0.0
base_confidence: 0.75
lifecycle: draft
lifecycle_changed: 2026-08-03
tier: core
created: 2026-07-27
updated: 2026-08-04
---

# Data Onboarding Orchestration Pipeline

> **Update (v1.1, 24 Jul 2026):** the "Airflow Trigger Modes" section below describes the *earlier* (11 Mar 2026) LLD's design. The current, authoritative design explicitly excludes Apache Airflow (decision **D16**) in favour of **Control-M** (external scheduling) + an in-service orchestration run driver (durable run execution) — see [[concepts/temporal-io-workflow-orchestration]]. The section is kept below for historical/evolution context and because it still accurately describes the *trigger taxonomy* (poll/watch/push/event), just not the underlying execution engine. The **Run State Machine** and **UC-1 Sequence Walkthrough** sections have been updated to the current model.

> **Update (v1.3, 31 Jul 2026):** two further corrections. First, a **Scheduler Job Adapter** now runs inside the Control-M job itself: it calls the initiate endpoint, then polls the DAL PostgreSQL directly (read-only, via PgBouncer) for run status until a terminal state, exiting `0` on `SECURED` and non-zero on failure — so a failed DAL run surfaces natively as a failed Control-M job, resolving what was previously open as OQ-08. Second, **readiness for file/object sources no longer polls a `BATCH_CONTROL`-style table or a file marker** — those sources have no such signal, so Control-M's own upstream job-dependency declaration is the readiness signal, and the DAL reads the configured file/object immediately once triggered. Only **relational (DB-poll)** sources still poll a registry-held, parameterised readiness query against the source. Each file/object pipeline entry also now names exactly **one** file or object — pattern-based multi-file matching is removed.

> **Update (Detailed Design v0.1, 2026-08-03):** [[reference/data-acquisition-cloud-sync-detailed-design]] closes decision **D03** and **replaces the "Four Services" model below with a five-component decomposition**: **Orchestrator** (run state machine + dispatch, absorbing this page's "Control Service"/"Orchestration Service" roles), **Worker** (executes dispatched tasks — readiness, extraction, validation, compression, classify+promote, event publish — absorbing "Integration Service"/"Control Service"/"Security Service"'s processing logic as in-process shared libraries), **Sync Push Service** (unchanged, see [[concepts/sync-push-service-architecture]]), a new **Operations Service** (read-only run views today, write-proxy next phase), and the existing **Scheduler Job Adapter**. Communication is **database-as-task-queue** (`FOR UPDATE SKIP LOCKED` claiming, no direct service-to-service calls), and **no persistent lease is used** — the Orchestrator only performs short DB transactions while all long-running work lives in stateless Workers, so there is no "slow owner" to protect against. The **"Four Services" section immediately below is kept for historical/evolution context** (it still correctly describes pipeline-*stage* responsibilities) but its service-*boundary* framing is superseded — see [[deliverables/findings]] #8 for the reconciliation risk this raises against any implementation already built against the older four-service model. Also new: a **post-landing decompression** step (resolving Q-15) runs after DataSync transfer and before a run closes — folded into step 9 of the sequence walkthrough below.

> **Update (code assessment, 2026-08-04):** an independent review of an `orchestration-service-mini` extract — a standalone build of the Orchestrator's run state machine and task dispatch — found that the Detailed Design's "database is the state machine" and "single writer per table" principles have concrete, reproducible failure modes when the mechanisms behind them (atomic checkpoint transitions, committed acknowledgement of completions, row locking, idempotent admission) are not fully implemented, even when the schema and state enum match the design exactly. See [[concepts/orchestrator-state-machine-integrity]] for the pattern and [[reference/orchestration-service-mini-code-assessment]] / [[synthesis/orchestration-service-mini-assessment]] for the assessment and its resolution status.

For structured and unstructured data, the on-prem [[entities/cloud-data-acquisition-service]] pipeline runs in a fixed sequence regardless of trigger mode:

```
Integration Service (pull/push) → Control Service (validation, state) →
Security Service (tokenize/encrypt) → AWS DataSync task execution →
Post-transfer validation (Lambda) → S3 Gold Zone landing
```

## The Four Services

- **Integration Service** — ingestion gateway; abstracts source protocols (JDBC/ODBC, REST/SFTP), performs schema extraction/drift detection per cycle, exposes a REST API for source registration and health checks, retries with exponential backoff, and maintains a **source system registry** (source_id, connection type, schedule, trigger_type, SLA deadline, priority tier, etc.).
- **Control Service** — the workflow "brain": maintains a job state machine (`INITIATED → EXTRACTING → COMPRESSING → STAGED → SYNCING → COMPLETED|FAILED|RETRYING`), persists state to PostgreSQL with full audit trail, publishes lifecycle events to Kafka, and enforces a multi-layered **Eligibility and Validation Gate** before any file may progress (see below).
- **Security Service** — see [[concepts/data-tokenization-and-encryption]].
- **Orchestration Service** — schedules and coordinates all three trigger modes below, and drives the AWS DataSync task execution.

## Control Service Validation Gate

Before `EXTRACTING → COMPRESSING`, a sequential validator chain runs; any FAIL halts the job:

1. **Registration Eligibility** — source is active, approved, has a data owner and security sign-off.
2. **Schema Validation** — SHA-256 fingerprint match against the Schema Registry; additive drift (new nullable columns) can WARN-and-proceed if `schema_drift_override_flag` is set, but breaking drift always FAILs. **v1.3 update:** this validator is specified but **deferred to the backlog (BL-005)** — not built in the current release; see [[reference/data-acquisition-platform-v1.3]].
3. **Metadata Tag Validation** — mandatory tags (`source_system`, `data_classification`, `pii_flag`, `retention_years`, etc.) plus cross-field rules, e.g. `pii_flag=true` requires classification CONFIDENTIAL/RESTRICTED, RESTRICTED data requires a non-empty `regulatory_scope` tag.
4. **Data Classification & Ownership** — data owner must be an active directory account; classification cannot be silently downgraded.
5. **File Integrity Pre-Check** — size bounds, SHA-256 checksum recomputation, minimum row count, file format/MIME match.
6. **Duplicate / Idempotency Check** — prevents double-processing the same batch.

Validation failures do not auto-retry — a human must correct the source registry or manifest first, then call the manual retry API.

## Airflow Trigger Modes ⚠️ Superseded (see update note above)

Every registered source gets one dedicated Airflow DAG (generated from a standard template at onboarding), enforcing `max_active_runs=1` as the primary per-source serialisation mechanism. *(This described the 11 Mar 2026 LLD's design; v1.1's D16 explicitly excludes Airflow — the taxonomy of trigger types below still holds, now implemented as Control-M schedules + Temporal workflows + the Sync Push Service, not Airflow DAGs.)*

| Mode | Applicability | Mechanism |
|---|---|---|
| `SCHEDULED_DB_POLL` | Structured DB sources | PythonSensor polls a `BATCH_CONTROL` readiness table via JDBC within a schedule window |
| `SCHEDULED_FILE_WATCH` | SFTP-dropped files | FileSensor/custom sensor watches a Shared Storage path for a filename pattern |
| `PUSH` | Source pushes via REST API | Integration Service receives the push; readiness/trigger tasks are skipped (`ShortCircuitOperator`) |
| `EVENT_DRIVEN` | Intraday/near-real-time file arrivals | `StorageEventListener` buffers arrivals; an `EventBatchScheduler` fires every 10 minutes per source; concurrent runs for the same source are serialised (HTTP 409 on conflict, retried next window) |

Onboarding a new source requires **only a Terraform PR** — DataSync source/destination locations, IAM roles, KMS CMK import, S3 prefixes, CloudWatch log groups, and the Airflow DAG are all templated; no manual console changes or agent re-provisioning. ^[inferred] (stated as a design goal — actual CI/CD implementation not shown in the source.)

## Run State Machine (v1.1, current)

The Orchestration Service's Temporal-backed workflow (Mode 1 only — see [[concepts/temporal-io-workflow-orchestration]]) drives every run through:

```
INITIATED → READY (readiness check passed) → EXTRACTING → EXTRACTED →
STAGED (Control Service validated/compressed) → SECURED (Security Service classified/promoted) →
EVENT_PUBLISHED (PutEvents to EventBridge) → TRANSFERRING (DataSync in flight) →
COMPLETED | FAILED | SLA_BREACH
```

Key properties: **`SECURED` is the durable checkpoint** — if AWS/Direct Connect is unavailable, the workflow holds here and retries with backoff, resuming automatically once connectivity returns (no re-extraction, no duplicate landing). `SLA_BREACH` is a parallel terminal-ish state driven by a Temporal timer against the source's registered SLA deadline (raises an alert; the run may still complete afterward). Validation failures inside `STAGED` do not auto-retry — see the Control Service Validation Gate above; a human must correct the source registry or manifest, then call the manual retry API, and Temporal resumes the held workflow from its last checkpoint rather than restarting.

## Sequence Walkthrough (UC-1: SCHEDULED_DB_POLL) — updated 10-step model

The detailed narrative walkthrough (`uc1_scheduled_db_poll_narrative.docx`, distilled at [[reference/uc1-scheduled-db-poll-narrative]]) supersedes the two-diagram summary previously here, adding the Control-M "fire-and-forget" contract and the manifest-driven staging detail:

0. **Onboarding pre-condition** — source registered in the Source Registry (see [[concepts/source-registry-and-audit-data-model]]), readiness table agreed with the source team, governance sign-off recorded.
1. **Control-M** fires on schedule, calls `POST /orchestration/runs/initiate` via the **Scheduler Job Adapter** running inside the Control-M job (v1.3); Orchestration Service creates `run_id` + audit row (`INITIATED`) and returns `202` immediately. The adapter then polls the DAL PostgreSQL directly for run status and keeps the Control-M job open until a terminal state is reached — exiting `0` on `SECURED`, non-zero on failure — so Control-M's native monitoring sees DAL success/failure without the DAL calling back into Control-M's API.
2. Orchestration Service polls the source's read-only, **registry-held parameterised readiness query** via the Integration Service's JDBC connector inside the configured poll window (`READY`, or SLA alert on window expiry). *(This DB-poll applies to relational sources, as in UC-1. File/object sources use a different signal — Control-M's own job-dependency declaration, with no DAL-side polling — see the v1.3 update note above.)*
3. Integration Service binds the registry's parameterised SQL template with the batch date, extracts, converts to Parquet, writes to the on-prem `control-zone` (`EXTRACTING` → `EXTRACTED`), then writes `_manifest.json` last as the atomic "batch fully staged" signal.
4. Control Service validates (schema/size/checksum/threshold/duplicate) and compresses (`STAGED`).
5. Security Service classifies, tags `target_tier`, and promotes the batch + manifest from `control-zone` to the transfer-ready `zone` (`SECURED`).
6. Orchestration Service calls EventBridge `PutEvents` (`EVENT_PUBLISHED`) — holds at the `SECURED` checkpoint and retries if AWS/Direct Connect is unreachable.
7. EventBridge Rule → Lambda resolves `target_tier`, calls DataSync `StartTaskExecution` (`TRANSFERRING`).
8. A DataSync agent from the per-VPC **agent pool** (24 in production, 5 in UAT — not a single shared FIFO agent, correcting an earlier narrative-document description) pulls the batch + manifest over Direct Connect into the resolved S3 bucket/prefix under the source's CMK, with its own built-in checksum verification.
9. DataSync's `TaskExecution` state-change event flows back via EventBridge Rule 2 → API Destination → Orchestration Service, which verifies the transfer, then — **if the pipeline had compression enabled** — runs the new **post-landing decompression** step (2026-08-03 refinement, resolves Q-15): decompresses the landed object back to its original form under the same KMS key, confirms it against the pre-compression manifest checksum, and removes the compressed original. Only then does the run mark `COMPLETED`, check the SLA deadline, and record transfer metrics. A decompression failure fails the run; relational (Parquet) extracts and the on-demand path never compress, so they skip this step entirely.

This remains fully event-driven on the cloud side — zero polling once the on-prem run has published to EventBridge.

## Related

- [[entities/cloud-data-acquisition-service]]
- [[concepts/data-tokenization-and-encryption]]
- [[concepts/s3-data-lake-zone-design]]
- [[concepts/temporal-io-workflow-orchestration]]
- [[concepts/sync-push-service-architecture]]
- [[concepts/source-registry-and-audit-data-model]]
- [[concepts/orchestrator-state-machine-integrity]]
- [[synthesis/data-acquisition-architecture-overview]]
- [[reference/uc1-scheduled-db-poll-narrative]]
- [[reference/data-acquisition-platform-v1.3]]
- [[reference/data-acquisition-cloud-sync-detailed-design]]
- [[reference/orchestration-service-mini-code-assessment]]
- [[synthesis/orchestration-service-mini-assessment]]

## Sources

- External: Mar 11 _Data-Acquisition-Service-LLD-NarrativeV1.0[63].pdf
- External: image001.png (UC-1 on-prem sequence diagram)
- External: image002.png (UC-1 cloud sequence diagram)
- External: OCBC Data Acquisition Platform on AWS - v1.1.pdf
- External: uc1_scheduled_db_poll_narrative.docx
- External: OCBC Data Acquisition Platform on AWS - v1.3.md
- External: Re__IaC_Deployment_Process/OCBC Data Acquisition Platform on AWS - v1.3.md
- External: Re__IaC_Deployment_Process/OCBC Data Acquisition - Cloud Sync Detailed Design.md
- External: OCBC Data Acquisition - Orchestration Service Code Assessment.md
