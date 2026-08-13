---
title: OCBC Data Acquisition — Delivery Tranche Roadmap (Source Document)
category: reference
tags: [aws, data-platform, ocbc, data-acquisition, delivery-plan, roadmap, source-document]
relationships:
  - target: "[[reference/cloud-sync-user-stories]]"
    type: derived_from
  - target: "[[reference/data-acquisition-cloud-sync-detailed-design]]"
    type: related_to
  - target: "[[synthesis/data-acquisition-architecture-overview]]"
    type: informs
  - target: "[[synthesis/data-acquisition-open-decisions]]"
    type: related_to
  - target: "[[concepts/data-onboarding-orchestration-pipeline]]"
    type: related_to
sources: ["External: Delivery-Tranches.xlsx"]
summary: >
  Authoritative delivery-sequencing roadmap that slices the Cloud Sync build into six
  incremental tranches, each defined by a demonstrable end-to-end scenario, the
  component(s) it introduces, and the CS-xxx user-story IDs it delivers. Tranche 1
  (Orchestrator-only, fully simulated) is complete; Tranche 2 (Worker "walking skeleton":
  one real connector writing to mock/local S3) is complete; Tranche 3 (retry/backoff,
  classify-and-promote, real readiness check, manifest validation, and decompression
  pipeline) is complete. Tranches 4–6 progressively add the remaining connectors and
  real decompression (remaining steps), add the synchronous Sync Push path, and finally
  swap the API-key/manual stand-ins for real Control-M + gateway auth and an Operations
  Service; business-date resolution (Epic G, CS-060–062) is split out as the final
  tranche (Tranche 7).
  Updated 2026-08-14: previously unassigned stories (CS-002, CS-003, CS-009, CS-014,
  CS-019, CS-023, CS-025, CS-051, CS-052, CS-054, CS-055, CS-056, CS-059) assigned to
  their correct tranches following a gap analysis against the full CS-xxx catalogue.
  Updated 2026-08-15: second gap-analysis pass assigned the 5 remaining unassigned stories
  (CS-004, CS-005, CS-010, CS-018, CS-070) — CS-018 to T1 (implicit in the Orchestrator
  skeleton from day one), CS-004/CS-005/CS-010/CS-070 to T4 (were hidden inside the
  "Remaining Epic A connectors" catch-all).
  Updated 2026-08-15 (CS-019 reassignment): CS-019 (bounded-memory streaming) moved T4→T2.
  LocalFileSourceConnector already enforces the size pre-check and S3Uploader streams via
  InputStream — constraint is satisfied and closed in T2. T4 connectors must meet the same
  acceptance criterion but do not re-open the story.
provenance:
  extracted: 0.9
  inferred: 0.1
  ambiguous: 0.0
base_confidence: 0.8
lifecycle: draft
created: 2026-08-06
updated: 2026-08-15 (CS-019 moved T4→T2)
---

# OCBC Data Acquisition — Delivery Tranche Roadmap

> **Source:** External: `Delivery-Tranches.xlsx` (distilled, not reproduced verbatim).
> This page captures the delivery-sequencing plan for the Cloud Sync build. It is the
> authoritative source for **which tranche each scenario and CS-xxx story belongs to**.
> The per-tranche scenarios map onto the components in
> [[reference/data-acquisition-cloud-sync-detailed-design]] and the story catalogue in
> [[reference/cloud-sync-user-stories]].

## Sequencing principle

Each tranche is defined by a **demonstrable, end-to-end scenario** rather than by a
component or an epic. A tranche adds the smallest coherent increment that produces a
runnable, testable slice — starting from a fully-simulated Orchestrator (Tranche 1) and
walking outward one real capability at a time (a real connector, then S3, then hardening,
then more connectors, then the push path, then real scheduler/gateway/ops).

## The tranches

| Tranche | Scenario | Adds (entry → exit) | Component(s) | CS-xxx / DD IDs | Status (per source) |
|---|---|---|---|---|---|
| **1** | Request to simulated completion | Request → admission (dedupe / concurrency ceiling) → simulated task execution → cancel / resume / replay → two-phase transfer-complete callback (`TRANSFER` / `DECOMPRESSION`) → terminal state | Orchestrator only | CS-001, CS-015, CS-017, **CS-018** (audit trail — every state transition written to `run_event`), CS-020, CS-021, CS-022, CS-026, CS-027, CS-029, CS-037, CS-038, CS-040, CS-041, CS-053, CS-058 | ✅ Done — verified against the Orchestrator source |
| **2** | Request to S3 (walking skeleton) | Same admission/dispatch, then a **Worker claims the task, executes one real connector, writes the file to mock/local S3 (LocalStack / MinIO) via the S3 API, reports completion**, and the run reaches a terminal state | Orchestrator **+ new Worker service** | CS-006, CS-007, **CS-009** (pass-through byte integrity), **CS-019** (bounded-memory streaming — `LocalFileSourceConnector` enforces size pre-check; `S3Uploader` streams via `InputStream`; closed here, not re-opened in T4), **CS-023** (staging zone isolation — `raw/` prefix write) | ✅ Done (ahead of snapshot) — `worker-service` delivers the walking skeleton, proven by `WorkerExtractFlowIT` (see drift note below) |
| **3** | Request to S3, but things go wrong | Same flow, **hardened**: transient Worker failure → retry with backoff; classify-and-promote runs as its own task; real readiness check, manifest validation, decompression pipeline, and JDBC/Oracle connector | Orchestrator + Worker | CS-016 (retry), CS-024 (classify+promote), **CS-021** (real CHECK_READINESS — JdbcTemplate query), **CS-011** (required manifest fields), **CS-012** (batch integrity), **CS-053** (real VALIDATE task — reads `_manifest.json`, checks CS-011/CS-012), **CS-063** (list `.gz` objects under prefix), **CS-064** (stream → GZIPInputStream → re-upload → delete original), **CS-004** (JDBC/Oracle relational connector), **CS-008** (Parquet landing — depends on CS-004; not implemented in T2, moved here) | ✅ Done — CS-016 (retry/backoff) and CS-024 (real Worker S3 raw→transfer-ready promotion) both delivered; CS-021/CS-053/CS-063/CS-064/CS-004 implemented ahead of full T4 sweep. Full `mvn verify` green. **Business-date (CS-060–062) split out to Tranche 7 (2026-08-12)**; CS-042 & CS-028 deferred (2026-08-07) |
| **4** | Every source, and a clean landing | Same flow, extended to the **remaining two connectors** (REST/FileNet, S3-compatible/ECS) plus **real decompression** (remaining steps) and **real validation** (remaining chain members) | Worker service | **Readiness & Scheduling:** CS-027 (no-deadline config-gap alert) · **Connectors:** **CS-005** (REST/FileNet content-repository connector) · **Validation & Manifest Integrity:** **CS-054** (format/size validator — chain member), **CS-055** (active-source/registration-completeness check — chain member) · **Classification:** **CS-014** (classify batch and record destination — governance labelling before `CLASSIFY_AND_PROMOTE`) · **Compression / Decompression Pipeline:** **CS-010** (compress batch before transfer — `S3Compressor` gzip on `raw/`), CS-065/CS-066/CS-067 (caller-supplied-path), CS-068 (canonical S3 key layout), CS-069 (allowlisted system IDs) · **Landing:** **CS-070** (medallion tier routing — Bronze/Gold bucket resolved from registry at S3 write time) · **Remaining Epic A connectors** including **CS-003** (uniform acquisition contract — config-driven connector factory complete when all four connectors exist) · **CS-025** (`PUBLISH_TRANSFER_EVENT` real implementation carrying `source_id`) · **CS-028** (outage-hold, deferred from T3 — trigger TBD) | 🔲 Planned |
| **5** | Caller pushes, not pull | Caller **pushes data synchronously** → admission control → direct S3 write → timeout handling | **New Sync Push Service** | CS-030, CS-031, CS-032, CS-033, CS-034, CS-035, CS-036, **CS-056** (governance metadata consistency check — placeholder completed when Q-03 retention values resolved; T5 is the first tranche exercising the validation chain on a second mode) | 🔲 Planned |
| **6a** | Real scheduler, real gateway | The Tranche 2–4 flow, triggered by a **real Control-M contract** and authenticated via **real mTLS / Entra ID** instead of the API-key stand-in | **New Scheduler Job Adapter + new API Gateway** | CS-020, CS-037, CS-038 (hardening — no new IDs), **CS-002** (credential vaulting via CyberArk/Conjur — same class of "replace the stand-in" work as the API-key → Entra ID swap) | 🔲 Planned |
| **6b** | Operator sees and reacts | Operator queries run state → resumes / replays a failed run → is alerted on SLA breach → quarantines poison batches | **New Operations Service** | CS-039, **CS-042 (quarantine, from T3)**, CS-043, CS-044, CS-045, CS-046, CS-047, CS-048, CS-049, CS-050, **CS-051** (read-only pipeline config view), **CS-052** (read-only run status/history view), **CS-059** (zone retention enforcement — blocked on Q-03 retention values; Operations Service owns housekeeping) | 🔲 Planned |
| **7** | Business dates resolve themselves | `batch_date` special values (`CURRENT_DATE`, `PREVIOUS_MONTH_END_DATE`, …) → resolved to a concrete business date **at run initiation** using the system-wide **anchor date** + per-country **calendars**; anchor rolled forward by a scheduled Control-M job | Orchestrator (**`dal-calendar` library**) + Sync Push Service | CS-060, CS-061, CS-062 (Epic G) | 🔲 Planned — **final tranche** (split from T3, 2026-08-12) |

## What the tranche boundaries clarify

- **The "five use cases + one guardrail" that the current Orchestrator extract implements
  are Tranche 1**, not Tranche 2. Tranche 1's CS-xxx set is exactly UC-1 (CS-001/015/020),
  UC-2 (CS-021/022), UC-3 (CS-040/041/053), UC-4 (CS-058), UC-5 (CS-029), the auth guardrail
  (CS-026/037/038), and the supporting SLA (CS-027) and traceId (CS-017) mechanisms.
  **Note:** CS-021 and CS-053 appear in T1 as *simulated stubs only*; their real Worker
  implementations (JdbcTemplate readiness query and manifest validation) are T4 deliverables.
- **Tranche 2 is specifically the Worker "walking skeleton"** — one real connector writing to
  real (mock/local) S3 — and is keyed to the *connector* stories CS-006/007/008, not the
  progression stories CS-021/022 that drive it.
- **Tranche 3 now includes the implemented T4 stories**: CS-021 (real CHECK_READINESS),
  CS-011/CS-012/CS-053 (manifest validation chain), CS-063/CS-064 (decompression
  pipeline core), and CS-004 (JDBC/Oracle relational connector) — all confirmed implemented
  ahead of the full T4 connector sweep and moved here to reflect actual build state.
- **Tranche 4 CS-xxx are organised into five proximity groups**: (1) Readiness & Scheduling
  (CS-027 — no-deadline config-gap alert; CS-021 moved to T3 as implemented); (2) Connectors
  (CS-005 — REST/FileNet; CS-004/JDBC/Oracle moved to T3 as implemented); (3) Validation & Manifest Integrity (CS-054/055 — format/size bounds
  and registration completeness; CS-011/012/053 moved to T3 as implemented); (4) Classification
  (CS-014 — governance labelling before `CLASSIFY_AND_PROMOTE`); (5) Compression/Decompression
  Pipeline (CS-010/065/066/067/068/069 — compress before transfer and the remaining S3 key
  conventions; CS-063/064 moved to T3 as implemented).
  Also: CS-003 (uniform acquisition contract — closed when all four connectors exist), CS-025 (real
  `PUBLISH_TRANSFER_EVENT` carrying `source_id`), CS-070 (medallion tier routing at S3 write time).
  Note: CS-019 (bounded-memory streaming) is **closed in T2** — T4 connectors must satisfy the
  same acceptance criterion but the story is not re-opened.
- The later tranches are cumulative hardening: **3** adds core durability (retry and real
  classify-and-promote); **4** adds the remaining connectors, real decompression, and real
  validation; **5** adds the synchronous push path; **6a/6b** replace the API-key and manual
  stand-ins with real scheduler/gateway auth and an operator-facing Operations Service; and
  **7** (final) adds Epic G business-date resolution. Three Tranche-3 items were reassigned:
  **CS-060–062 (business-date)** to the new final **Tranche 7** (2026-08-12), **CS-042
  (quarantine)** to Tranche 6b, and **CS-028 (outage-hold)** to Tranche 4 (see the decision
  notes below).
- **2026-08-14 gap-analysis assignment:** previously unassigned stories have been placed into
  tranches: **CS-009/CS-023 → T2** (pass-through integrity and staging zone isolation are
  implicit in the T2 walking skeleton); **CS-003/CS-014/CS-025/CS-054/CS-055 → T4**
  (uniform connector contract, classification, real event publish, and the
  remaining validation chain members all belong to the "every source, clean landing" tranche);
  **CS-019 → T2** (reassigned from T4 — see 2026-08-15 CS-019 reassignment note below);
  **CS-056 → T5** (governance metadata consistency placeholder — completed when Q-03 is
  resolved, natural fit when the second mode exercising the validation chain is built);
  **CS-002 → T6a** (credential vaulting is the same class of stand-in replacement as the
  API-key → Entra ID swap); **CS-051/CS-052/CS-059 → T6b** (read-only operations views and
  zone retention enforcement belong to the Operations Service).
- **2026-08-15 gap-analysis assignment (second pass):** five stories remaining after the
  2026-08-14 pass assigned: **CS-018 → T1** (audit trail — `run_event` table and
  `RunEventRecorder` are already in the T1 Orchestrator skeleton, was implicit alongside
  CS-017); **CS-004/CS-005 → T4** (JDBC/Oracle and REST/FileNet connectors — were hidden
  inside the "Remaining Epic A connectors" catch-all, now named explicitly); **CS-010 → T4**
  (`S3Compressor` gzip-before-transfer is a T4 Worker deliverable, CR-02 confirms compression
  applies to both modes); **CS-070 → T4** (medallion tier routing added in user stories v0.9
  after the roadmap snapshot — Bronze/Gold bucket resolved at S3 write time by the Worker).

## 2026-08-07 scope decision — Tranche 3 reduced

Tranche 3 was narrowed to the workstreams with a firm design basis. The two deferred items
lacked one and were reassigned to later tranches (mirrored in the source
`Delivery-Tranches.xlsx`, "Change Log" sheet):

- **CS-016 (retry/backoff), CS-024 (classify-and-promote), CS-060–CS-062 (business-date)** —
  **kept in Tranche 3**. CS-060–062 is now grounded by the archived `ocbc-data-acquisition-service`
  reference implementation (`AnchorDate` / `CountryCalendar` entities + `/anchor-date/roll-over`,
  CS-061); only the special-value resolver is new build. *(Superseded 2026-08-12: CS-060–062 moved
  out to the new final Tranche 7 — see the decision note below.)*
- **CS-042 (quarantine)** → **Tranche 6b (Operations Service)**. No quarantine store/status is
  defined anywhere, and the Detailed Design already scopes quarantine to Operations.
- **CS-028 (outage-hold)** → **Tranche 4 (provisional)**. The hold-at-checkpoint + backoff
  behaviour is described (D21), but the **outage-trigger mechanism is unspecified**; parked in
  the next durability tranche pending that decision.

## 2026-08-12 scope decision — Epic G split into its own final tranche

Business-date resolution (Epic G: **CS-060, CS-061, CS-062**) was **removed from Tranche 3** and
made its **own, final tranche (Tranche 7)**. Rationale: it is an **orthogonal capability**
(calendar-aware date resolution at run initiation), not part of Tranche 3's "things go wrong"
durability theme, and it depends on loading each country's holiday **calendar data** — an
operating-model / ownership follow-on that should not gate the retry / classify-and-promote
hardening. **Tranche 3 is now just CS-016 (retry/backoff, delivered) and CS-024
(classify-and-promote, delivered 2026-08-12).** Epic G's mechanism is fully specified (CS-060 token set, CS-061
anchor date + Control-M roll-over, CS-062 per-country calendars) and grounded by the archived
`ocbc-data-acquisition-service` reference implementation, so it carries no design risk — only
the calendar-data ownership follow-on and the build itself remain.

## Drift note (source snapshot vs. current code)

The source records Tranche 2 as *"Next — confirmed 100% greenfield (no worker/connector/S3
package or dependency exists anywhere in the reactor)"*. That reflects a point-in-time
snapshot taken **before** the Tranche 2 walking skeleton was built. The `ocbc-cloud-sync`
code repository has since **added a `worker-service` module that already delivers the
Tranche 2 scenario**: it claims the `EXTRACT` task (`SKIP LOCKED`), reads a real file via a
`SourceConnector`, uploads it to S3 (LocalStack in dev/test), and is proven end-to-end by
`WorkerExtractFlowIT`. The code is therefore **ahead of this roadmap snapshot** for
Tranche 2; treat the roadmap's status column as a plan-time view, not current build state.

## 2026-08-15 gap-analysis assignment note (second pass)

A second gap analysis (diff of user stories v0.9 CS-xxx set against the roadmap) found 5
stories still absent after the 2026-08-14 pass:

- **CS-018 → T1.** "Record every state transition" — the `run_event` table and
  `RunEventRecorder` are already delivered in the T1 Orchestrator skeleton alongside CS-017
  (trace ID). It was implicit; now explicit.
- **CS-004 → T3.** JDBC/Oracle relational connector — implemented and moved to T3.
- **CS-005 → T4.** REST/FileNet content-repository connector — same reason as CS-004.
- **CS-010 → T4.** Compress a batch before transfer — the `S3Compressor` (gzip on `raw/`)
  is a T4 Worker deliverable. CR-02 confirms compression applies to both scheduled and
  on-demand modes. Was missing from all tranche lists despite the `COMPRESS` task type
  existing in the task sequence.
- **CS-070 → T4.** Medallion tier routing (Bronze/Gold bucket) — added in user stories v0.9
  after the roadmap snapshot was taken, so it was never in any tranche. Tier is resolved from
  the pipeline registry at S3 write time by the Worker, making T4 the correct home.

## 2026-08-14 gap-analysis assignment note (first pass)

A full gap analysis against the CS-xxx catalogue identified stories present in the user
stories (v0.9) but absent from all tranche CS-xxx lists. Assignments above reflect the
following reasoning:

- **CS-009, CS-023 → T2.** Pass-through byte integrity (CS-009) and staging zone isolation
  (CS-023) are already exercised by the T2 walking skeleton (`WorkerExtractFlowIT` proves
  the file lands byte-for-byte under `raw/`). They were implicit; they are now explicit.
- **CS-003 → T4.** The uniform acquisition contract ("add a source by configuration, no
  code change") is only closeable once all four connectors exist — which is the T4 milestone.
- **CS-014 → T4.** Classification and destination labelling runs after validation and before
  `CLASSIFY_AND_PROMOTE`. T4 already owns the promotion step; the governance labelling
  belongs in the same tranche.
- **CS-019 → T2 (reassigned from T4, 2026-08-15).** `LocalFileSourceConnector` already
  enforces the bounded-memory size pre-check and `S3Uploader` streams via `InputStream` —
  the constraint is satisfied and the story is closed in T2. The original T4 rationale
  ("local-file connector is trivially bounded") is precisely the reason to close it in T2,
  not defer it. T4 connectors (JDBC/REST/S3) must meet the same acceptance criterion but
  do not re-open CS-019.
- **CS-025 → T4.** `PUBLISH_TRANSFER_EVENT` is currently a `DemoTaskExecutor` stub. T4 is
  the tranche that makes all other worker tasks real; the event publish should follow.
- **CS-054, CS-055 → T4.** Both are validation chain members (CS-053 framework is T4);
  they belong in the same tranche as the chain they extend.
- **CS-056 → T5.** Placeholder blocked on Q-03 (retention domain minimums). T5 introduces
  the Sync Push Service, which is the second mode exercising the validation chain — the
  natural point to complete this placeholder once Q-03 is resolved.
- **CS-002 → T6a.** CyberArk/Conjur credential vaulting is the credential-plane equivalent
  of the API-key → Entra ID swap that T6a delivers. Both replace a stand-in with the real
  production mechanism.
- **CS-051, CS-052 → T6b.** Read-only pipeline config and run views are the Operations
  Service's primary read surface. The roadmap already listed CS-039 in T6b; CS-051/052 are
  the same component.
- **CS-059 → T6b.** Zone retention enforcement is an Operations Service housekeeping
  responsibility. Blocked on Q-03 but the owning component is T6b.

## 2026-08-12 gap note — T4 partial implementation

Three of the four T4 proximity groups were partially or fully implemented ahead of the
full T4 connector sweep and have been **moved to Tranche 3** to reflect actual build state:

- **Readiness & Scheduling (CS-021):** ✅ Moved to T3. CS-021 real `CHECK_READINESS` Worker
  task (JdbcTemplate query against `readiness_query`/`readiness_expected_value` columns)
  implemented. CS-027 no-deadline config-gap alert remains open in T4 (readiness polling
  timeout bound also still open — see finding #16).
- **Validation & Manifest Integrity (CS-011/012/053):** ✅ Moved to T3. CS-053 real
  `VALIDATE` task implemented — reads `_manifest.json` from S3, checks CS-011 required
  fields and CS-012 batch integrity. CS-013 (schema-drift) and CS-057 (data-owner
  verification) remain deferred (BL-005/BL-006). CS-054/055 remain open in T4.
- **Compression/Decompression Pipeline (CS-063/064):** ✅ Moved to T3. `DECOMPRESSION`
  Worker task implemented — `S3Decompressor` lists `.gz` objects, streams through
  `GZIPInputStream`, re-uploads without `.gz` suffix, deletes original; full state machine
  wiring (`DECOMPRESSING → DECOMPRESSED → COMPLETED`). CS-065/066/067 (caller-supplied-path),
  CS-068 (canonical key layout), CS-069 (allowlisted system IDs) remain open in T4.
- **Connectors (CS-004):** ✅ Moved to T3. JDBC/Oracle relational connector implemented.
  CS-005 (REST/FileNet) and remaining Epic A connectors not yet started (remain in T4).
- **CS-028:** not yet started (remains in T4).

## Related pages

- [[reference/cloud-sync-user-stories]] — the CS-xxx story catalogue the tranches draw from
- [[reference/data-acquisition-cloud-sync-detailed-design]] — the five-component decomposition (Orchestrator, Worker, Sync Push Service, Operations Service, Scheduler Job Adapter) the tranches build out
- [[synthesis/data-acquisition-architecture-overview]] — cross-cutting architecture synthesis
- [[concepts/data-onboarding-orchestration-pipeline]] — the run state machine the tranches exercise
