---
title: OCBC Data Acquisition — Cloud Sync Detailed Microservice Design (Source Document)
category: reference
tags: [aws, data-platform, ocbc, data-acquisition, microservices, source-document]
relationships:
  - target: "[[reference/data-acquisition-platform-v1.3]]"
    type: derived_from
  - target: "[[reference/data-acquisition-platform-v1.5]]"
    type: related_to
  - target: "[[reference/cloud-sync-user-stories]]"
    type: derived_from
  - target: "[[entities/cloud-data-acquisition-service]]"
    type: extends
  - target: "[[concepts/data-onboarding-orchestration-pipeline]]"
    type: related_to
  - target: "[[concepts/source-registry-and-audit-data-model]]"
    type: related_to
  - target: "[[concepts/sync-push-service-architecture]]"
    type: related_to
  - target: "[[synthesis/data-acquisition-open-decisions]]"
    type: informs
sources: ["External: Re__IaC_Deployment_Process/OCBC Data Acquisition - Cloud Sync Detailed Design.md", "External: OCBC Data Acquisition - Cloud Sync Detailed Design.md"]
summary: AWS-authored DRAFT v0.1 internal microservice decomposition for the Cloud Sync services, closing design decision D03; updated 2026-08-05 with a gap-analysis reconciliation adding the DECOMPRESSING audited state, a two-phase transfer-complete callback, and a minimal per-task result contract. Replaces the earlier indicative Integration/Control/Security/Orchestration four-service split with five components (Orchestrator, Worker, Sync Push Service, Operations Service, Scheduler Job Adapter) built around a "database as task queue" model with no persistent lease and no inter-service network calls.
provenance:
  extracted: 0.85
  inferred: 0.15
  ambiguous: 0.0
base_confidence: 0.72
lifecycle: draft
lifecycle_changed: 2026-08-05
tier: core
created: 2026-08-03
updated: 2026-08-05
---

# OCBC Data Acquisition — Cloud Sync Detailed Microservice Design (Source Document)

Reference index for **"OCBC Data Acquisition — Cloud Sync Detailed Microservice Design"**, DRAFT v0.1, Amazon Confidential. This document closes design decision **D03** (physical microservice decomposition, previously deferred in v1.1/v1.2/v1.3) by recording the internal service breakdown that implements [[reference/data-acquisition-platform-v1.3]] and [[reference/cloud-sync-user-stories]] (v0.5). It is explicitly a *living* document — schema/package-level detail is filled in progressively as user stories are implemented, not fixed upfront.

## 2026-08-05 Update — Gap-Analysis Reconciliation (Version Not Bumped, Still v0.1)

A re-sent copy reconciles this design against the platform document's own gap-analysis pass ([[reference/data-acquisition-platform-v1.5]]). No scope change — clarifies contracts the two documents had left implicit or inconsistent:

- **`DECOMPRESSING` promoted to an audited run state (§6.1).** The run state machine gains `TRANSFERRING → DECOMPRESSING → COMPLETED` for decompression-enabled pipelines (in addition to the existing `TRANSFERRING → COMPLETED`/`SLA_BREACH` path for pipelines without decompression). This gives operators in-flight visibility between transfer-verified and fully-closed (CS-064), and lets the SLA scan cover the decompression window rather than treating decompression time as free.
- **Two-phase transfer-complete callback (§8.2).** `POST /runs/{run_id}/transfer-complete` now carries a `phase` field (`TRANSFER` | `DECOMPRESSION`), applied **idempotently on `(run_id, phase)`**. A `TRANSFER` callback with `verification_outcome = FAIL` fails the run; with `PASS` it either completes the run directly (no decompression configured) or moves it to `DECOMPRESSING` (decompression configured), which then closes on the later `DECOMPRESSION` callback. A callback for an unknown or already-terminal run is accepted, logged, and ignored (`200`) so the AWS-side caller never enters a retry loop.
- **Minimal per-task result contract pinned (§5.1).** Because the orchestrator cannot advance the state machine without it, the minimal JSON shape per task type is fixed in sprint 0, ahead of full column-level schema: `CHECK_READINESS → {ready}`, `EXTRACT → {manifest_uri, file_count, total_bytes}`, `VALIDATE → {aggregate_outcome, validators[]: {name, outcome, message}}`, `COMPRESS → {method, per_file: {pre_bytes, post_bytes, pre_checksum}}`, `CLASSIFY_AND_PROMOTE → {promoted_prefix}`, `PUBLISH_TRANSFER_EVENT → {event_id, published_at}` — plus a common error envelope (`error_code`, `error_class: TRANSIENT|PERMANENT`, `message`) shared by all task types for §5.4 failure handling.
- **Manifest-write step added to the push sequence (§5.3).** The Sync Push Service's in-process pipeline now explicitly ends with assembling and writing `_manifest.json` to S3 **last**, alongside the object(s) under the same prefix — matching the pull path's write-last convention rather than leaving manifest handling implicit.
- **`source_ref` vs `source_path` disambiguated on the push contract (§8.2).** Exactly one data-reference field applies per on-demand request, selected by `pipeline_mode`: `source_ref`/`payload_ref` for `REGISTERED_ITEM` pipelines, `source_path` for `CALLER_SUPPLIED_PATH` pipelines. Supplying the wrong one, or both, is a `400`.
- **Operations Service unified pull/push view specified (§7.1).** Since `Run` and `Push run` are deliberately separate tables (DD-11), `GET /runs` is now specified as querying a **read-only SQL view that unions both tables** onto common fields (run_id, pipeline_id, source_id, status, batch_date, timestamps, trigger_type), rather than two endpoints or a per-query UNION — keeping the query surface single and letting future archive tables fold into the same view.
- **Scheduler Job Adapter's schema coupling accepted as a trade-off (§7.1).** The adapter reads the `Run.status` column directly rather than going through the Operations Service — accepted because the adapter's only dependency is run status, direct reads remove any dependency on Operations Service availability, and `Run.status` is treated as a stable contract (a compatibility view/alias would be provided if the column were ever renamed).
- **Audit ≥ zone retention rule made explicit (§7.2).** Housekeeping/archival retention for `Run`/`Push run` must satisfy **audit retention ≥ zone retention + the maximum re-run/replay latency** — not just the CS-015 dedup window in isolation — so a batch's audit row (the dedup/idempotency guard) still exists for as long as its on-premises zone data remains re-runnable. Archiving an audit row earlier reopens the dedup window and could let a re-run duplicate data.

## ⚠️ Supersedes the Previously Modelled Four-Service Split

Every earlier ingested source ([[reference/data-acquisition-platform-v1.1]] through [[reference/data-acquisition-platform-v1.3]], and this wiki's own [[concepts/data-onboarding-orchestration-pipeline]]) described the on-prem pipeline as **four** named services — Integration, Control, Security, Orchestration — each owning a distinct pipeline stage. This detailed design **replaces that indicative split** with a different decomposition, explicitly presented as the resolution of D03:

| Component | Type | Responsibility | Roughly absorbs |
|---|---|---|---|
| **Orchestrator** | Spring Boot microservice | Run lifecycle state machine, scan loop, task dispatch, completion callback handling | Prior "Orchestration Service" |
| **Worker** | Spring Boot microservice | Executes dispatched tasks: readiness queries, extraction, validation, compression, classify+promote, EventBridge publish | Prior "Integration Service" + "Control Service" + "Security Service" (their logic becomes shared libraries a Worker consumes — see below) |
| **Sync Push Service** | Spring Boot microservice | Synchronous on-demand transfers, end to end in-process | Unchanged from v1.1's D24 — see [[concepts/sync-push-service-architecture]] |
| **Operations Service** | Spring Boot microservice | Read-only run/pipeline views today; proxies write actions (resume, replay, cancel) to the Orchestrator next phase | New — makes the previously-implicit "operations surface" (v1.2) an explicit, separately deployed component |
| **Scheduler Job Adapter** | Script/CLI, on the Control-M agent host | Bridges async DAL runs with Control-M's synchronous job model | Unchanged from v1.3 §10.1.1 |

The four prior services' *logic* is not discarded — it becomes shared Java libraries (`dal-connectors`, `dal-validation`, `dal-processing`, `dal-calendar`, `dal-config`) consumed in-process by the Worker and the Sync Push Service, rather than four separately-deployed, separately-scaled microservices calling each other over the network. This is a materially different physical topology, not just a rename.

**This wiki's concept pages have been updated to reflect this** — see the update note in [[concepts/data-onboarding-orchestration-pipeline]]. **A finding has been raised** ([[deliverables/findings]] #8) about reconciling this decomposition with any implementation already underway against the older four-service model.

## Design Principles (Mandatory, §2)

1. **Database is the state machine.** Every status change is a committed row update.
2. **No direct service-to-service calls.** All communication is through the shared PostgreSQL database — no REST callbacks, no message broker between internal services.
3. **Single writer per table.** Exactly one service writes each table.
4. **Workers are stateless.** All context comes from the database and the staging zone.
5. **Shared logic as libraries, not services.** Connectors, validation, compression, classification, calendar resolution are Java libraries, not network hops.
6. **DDD tactical patterns** for each microservice's internal structure (elaborated during implementation).
7. **Schema emerges from stories** — table schemas are defined progressively, not upfront.

## Communication Model: Database as Task Queue

The Orchestrator dispatches work by inserting rows into a task table; Workers claim tasks using `SELECT ... FOR UPDATE SKIP LOCKED`. The Orchestrator runs a periodic scan (every 5–10 seconds) that: (a) dispatches the next task for runs whose `next_wake_at` has elapsed, (b) reads completed/failed tasks and advances the run state machine, and (c) resets stale `CLAIMED` tasks back to `PENDING` (crash recovery).

**No persistent lease is needed** — this explicitly **supersedes the v1.3 §9.7.2 lease-with-TTL/renewal/fencing model**. That model existed because the Orchestration Service *also* executed long-running steps, so a slow step could outlast a lease and let a second replica reclaim and re-execute it. Here, the Orchestrator only ever performs short (millisecond) DB transactions; all long-running work lives in Workers, whose isolation is the task table's `CLAIMED` status plus stale-task detection. There is no "slow owner" to protect against.

**Two independent concurrency ceilings (CS-029)** are enforced as part of the Orchestrator's dispatch transaction: a per-pipeline **run admission** limit (`max_concurrent_runs`), and a per-environment **transfer slot** limit (24 in production, 5 in UAT) gating `PUBLISH_TRANSFER_EVENT` dispatch. A run whose transfer slot isn't available holds at `SECURED` and retries — its on-prem processing is already complete.

## Task Model (Scheduled Pull Path)

Up to six sequential tasks per run: `CHECK_READINESS` → `EXTRACT` → `VALIDATE` → `COMPRESS` (optional, per pipeline) → `CLASSIFY_AND_PROMOTE` → `PUBLISH_TRANSFER_EVENT`. `CHECK_READINESS` is skipped for file/object sources (readiness is the Control-M job dependency, per v1.3 CS-022). Classify and promote are one task because they're physically inseparable at the S3 API level (tags are applied during the copy). The AWS transfer-completion callback is handled directly by the Orchestrator, not dispatched as a task.

**Validation failure is not retried** and **blocks resume** — a run whose last failed task was `VALIDATE` cannot be resumed from checkpoint; the operator must replay (creates a new linked run, re-running the whole validation chain from its first validator). This is enforced in the Orchestrator's state-machine logic even though resume/replay endpoints are next-phase.

The Sync Push Service bypasses the task queue entirely, handling a request in-process end to end (no compression on this path — files land uncompressed).

## Run State Machine

Scheduled pull: `INITIATED → READY → EXTRACTED → VALIDATED → COMPRESSED → SECURED → EVENT_PUBLISHED → TRANSFERRING → COMPLETED` (or `SLA_BREACH`), with `FAILED` reachable from any state. On-demand transfer: `INITIATED → RECEIVED → VALIDATED → CLASSIFIED → WRITING → COMPLETED`, written entirely by the Sync Push Service on its own `push_run` table (kept separate from the pull-mode `run` table — different lifecycles, different writers, no dead columns from mode mismatch, per DD-11).

## Database Structure (Directional — Table Ownership, Not DDL)

| Table | Sole writer | Purpose |
|---|---|---|
| Source registry tables | Onboarding process (out of scope) | Pipeline configuration |
| **Run** | Orchestrator | One row per scheduled pull run — status, checkpoint, `next_wake_at`, retry count, SLA deadline |
| **Run task** | Orchestrator (inserts), Worker (claims/writes results) | Task dispatch queue |
| **Push run** | Sync Push Service | One row per on-demand transfer; idempotent on `(caller_identity, idempotency_key)` |
| **Run event** | Orchestrator | Append-only audit — state transitions, per-validator outcomes, retry history |
| **Anchor date** | Orchestrator (via the Control-M roll-over job, CS-061) | System-wide business-date reference point |
| **Country calendar** | Maintenance process | Non-business days per country |

Housekeeping (archival) applies to `Run task` (7–14 days), `Run`/`Push run` (retention ≥ the CS-015 dedup window), and `Run event` (long-term audit, never deleted within compliance retention).

## API Design Highlights

Everything is fronted by Spring Cloud Gateway (Entra ID validation, rate limiting, path routing). Run lifecycle (`POST /runs`, the transfer-completion callback, `POST /anchor-date/roll-over`) routes to the Orchestrator; `POST /on-demand-transfers` routes to the Sync Push Service; all `GET` read views route to the Operations Service. Next-phase write actions (`resume`, `replay`, `cancel`) route through the Operations Service, which proxies to the Orchestrator (DD-12) once the write-operator authentication model is confirmed.

## Compression

Relational extracts (Parquet) are never externally compressed. Scheduled-pull file/object content is optionally compressed per pipeline for DX efficiency, then **decompressed on the AWS side after DataSync landing, before the run closes** — this is the same post-landing decompression capability added to [[reference/data-acquisition-platform-v1.3]] and [[reference/cloud-sync-user-stories]] (Epic H, CS-063/CS-064), here recorded as DD-15. On-demand transfer never compresses.

## Key Decisions Register (DD-01 to DD-15)

| # | Decision | Rationale (condensed) |
|---|---|---|
| DD-01 | Five components (Orchestrator, Worker, Sync Push, Operations, Scheduler Job Adapter) | Different scaling profiles/failure modes; Orchestrator stays responsive regardless of data-plane load |
| DD-02 | Database as task queue, no broker, no direct service calls | One communication mechanism, one failure model; PostgreSQL is already the shared dependency (v1.1 D05) |
| DD-03 | Orchestrator drives readiness via repeated short dispatched tasks | Workers never block waiting; wait state lives in `next_wake_at` |
| DD-04 | One task per logical step (six task types) | Checkpoint-based resume without re-executing completed work |
| DD-05 | Classify and promote are one task | Physically inseparable at the S3 API level |
| DD-06 | Transactional row locking on runs, no persistent lease | Orchestrator's interaction with a run is one short transaction; `FOR UPDATE SKIP LOCKED` prevents dual processing |
| DD-07 | Stale-task detection for worker crash recovery | Covers worker death between `CLAIMED` commit and `COMPLETED` write |
| DD-08 | Shared logic as Java libraries | Avoids network hops for internal processing |
| DD-09 | One OpenShift namespace for all services | Isolation via Deployment-level resource limits, not namespaces |
| DD-10 | Single Spring Cloud Gateway fronting all services | One entry point for auth and routing |
| DD-11 | Separate tables for pull runs and push runs | Different lifecycles/writers/columns |
| DD-12 | Operations Service proxies write actions to the Orchestrator (next phase) | Single operator entry point; auth/audit before forwarding |
| DD-13 | Per-source connection ceiling enforced by the `dal-connectors` library | Bounded pool per source (`max_connections`), covering extraction + readiness + on-demand together |
| DD-14 | DDD tactical patterns for internal service structure | Elaborated during implementation |
| DD-15 | No compression on the on-demand path | Avoids a pointless compress-then-decompress cycle when writing straight to S3 |

## Assumptions (DA-01 to DA-04)

Per-source connection limits are enforced by a bounded pool in `dal-connectors` (environment default when unconfigured); the 5–10 second Orchestrator scan interval is acceptable latency for batch pipelines; task-table growth (6 tasks/run × tens-to-low-hundreds of runs/day) is manageable with periodic archival; `FOR UPDATE SKIP LOCKED` distributes work across Orchestrator replicas without a dedicated coordinator.

## Open Items (Resolved During Implementation)

Exact table schemas/DDL, package/class structure, lease-safety fencing for `CLASSIFY_AND_PROMOTE` (relevant when CS-024 is built), AWS-side decompression component design, per-service observability metrics, the stale-task detection threshold, and housekeeping retention values — all deferred to progressive implementation, several tied to the still-open retention question (Q-03 in [[reference/cloud-sync-user-stories]]).

## Related

- [[reference/data-acquisition-platform-v1.3]]
- [[reference/cloud-sync-user-stories]]
- [[concepts/data-onboarding-orchestration-pipeline]]
- [[concepts/source-registry-and-audit-data-model]]
- [[concepts/sync-push-service-architecture]]
- [[synthesis/data-acquisition-open-decisions]]
- [[deliverables/findings]]
- [[reference/orchestration-service-mini-code-assessment]] — a code assessment of an early Orchestrator extract against this design's mandatory principles
- [[concepts/orchestrator-state-machine-integrity]]

## Sources

- External: Re__IaC_Deployment_Process/OCBC Data Acquisition - Cloud Sync Detailed Design.md
- External: OCBC Data Acquisition - Cloud Sync Detailed Design.md (2026-08-05 gap-analysis reconciliation copy)
