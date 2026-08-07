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
  one real connector writing to mock/local S3) is next. Tranches 3–6 progressively harden
  the flow (retries/quarantine/business-date/outage-hold), add the remaining connectors and
  real decompression, add the synchronous Sync Push path, and finally swap the API-key/manual
  stand-ins for real Control-M + gateway auth and an Operations Service.
provenance:
  extracted: 0.9
  inferred: 0.1
  ambiguous: 0.0
base_confidence: 0.8
lifecycle: draft
created: 2026-08-06
updated: 2026-08-07
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

## The six tranches

| Tranche | Scenario | Adds (entry → exit) | Component(s) | CS-xxx / DD IDs | Status (per source) |
|---|---|---|---|---|---|
| **1** | Request to simulated completion | Request → admission (dedupe / concurrency ceiling) → simulated task execution → cancel / resume / replay → two-phase transfer-complete callback (`TRANSFER` / `DECOMPRESSION`) → terminal state | Orchestrator only | CS-001, CS-015, CS-017, CS-020, CS-021, CS-022, CS-026, CS-027, CS-029, CS-037, CS-038, CS-040, CS-041, CS-053, CS-058 | ✅ Done — verified against the Orchestrator source |
| **2** | Request to S3 (walking skeleton) | Same admission/dispatch, then a **Worker claims the task, executes one real connector, writes the file to mock/local S3 (LocalStack / MinIO) via the S3 API, reports completion**, and the run reaches a terminal state | Orchestrator **+ new Worker service** | CS-008 / CS-006–007 (first real connector) | ✅ Done (ahead of snapshot) — `worker-service` delivers the walking skeleton, proven by `WorkerExtractFlowIT` (see drift note below) |
| **3** | Request to S3, but things go wrong | Same flow, **hardened**: transient Worker failure → retry with backoff; `batch_date` special values → resolved via anchor date; classify-and-promote runs as its own task | Orchestrator + Worker | CS-016 (retry), CS-060–CS-062 (business-date), CS-024 (classify+promote) | 🔲 Planned — **reduced scope** (CS-042 & CS-028 deferred, see 2026-08-07 decision note) |
| **4** | Every source, and a clean landing | Same flow, extended to the **remaining three connectors** (JDBC/Oracle, REST/FileNet, S3-compatible/ECS) plus **real decompression** execution | Worker service | Remaining Epic A connector stories (~17), CS-063–CS-064 (reduced scope), **CS-028 (outage-hold, deferred from T3 — trigger TBD)** | 🔲 Planned |
| **5** | Caller pushes, not pull | Caller **pushes data synchronously** → admission control → direct S3 write → timeout handling | **New Sync Push Service** | CS-030–CS-036 | 🔲 Planned |
| **6a** | Real scheduler, real gateway | The Tranche 2–4 flow, triggered by a **real Control-M contract** and authenticated via **real mTLS / Entra ID** instead of the API-key stand-in | **New Scheduler Job Adapter + new API Gateway** | CS-020, CS-037, CS-038 (hardening — no new IDs) | 🔲 Planned |
| **6b** | Operator sees and reacts | Operator queries run state → resumes / replays a failed run → is alerted on SLA breach → quarantines poison batches | **New Operations Service** | CS-039, **CS-042 (quarantine, from T3)**, CS-043, CS-044–CS-050 | 🔲 Planned |

## What the tranche boundaries clarify

- **The "five use cases + one guardrail" that the current Orchestrator extract implements
  are Tranche 1**, not Tranche 2. Tranche 1's CS-xxx set is exactly UC-1 (CS-001/015/020),
  UC-2 (CS-021/022), UC-3 (CS-040/041/053), UC-4 (CS-058), UC-5 (CS-029), the auth guardrail
  (CS-026/037/038), and the supporting SLA (CS-027) and traceId (CS-017) mechanisms.
- **Tranche 2 is specifically the Worker "walking skeleton"** — one real connector writing to
  real (mock/local) S3 — and is keyed to the *connector* stories CS-006/007/008, not the
  progression stories CS-021/022 that drive it.
- The later tranches are cumulative hardening: **3** adds core durability (retry,
  business-date resolution, real classify-and-promote); **4** adds the remaining connectors
  and real decompression; **5** adds the synchronous push path; and **6a/6b** replace the
  API-key and manual stand-ins with real scheduler/gateway auth and an operator-facing
  Operations Service. Two Tranche-3 durability items were **deferred on 2026-08-07** for lack
  of a firm design decision: **CS-042 (quarantine)** to Tranche 6b (Operations), and
  **CS-028 (outage-hold)** to Tranche 4 (trigger mechanism still to be decided) — see the
  decision note below.

## 2026-08-07 scope decision — Tranche 3 reduced

Tranche 3 was narrowed to the workstreams with a firm design basis. The two deferred items
lacked one and were reassigned to later tranches (mirrored in the source
`Delivery-Tranches.xlsx`, "Change Log" sheet):

- **CS-016 (retry/backoff), CS-024 (classify-and-promote), CS-060–CS-062 (business-date)** —
  **kept in Tranche 3**. CS-060–062 is now grounded by the archived `ocbc-data-acquisition-service`
  reference implementation (`AnchorDate` / `CountryCalendar` entities + `/anchor-date/roll-over`,
  CS-061); only the special-value resolver is new build.
- **CS-042 (quarantine)** → **Tranche 6b (Operations Service)**. No quarantine store/status is
  defined anywhere, and the Detailed Design already scopes quarantine to Operations.
- **CS-028 (outage-hold)** → **Tranche 4 (provisional)**. The hold-at-checkpoint + backoff
  behaviour is described (D21), but the **outage-trigger mechanism is unspecified**; parked in
  the next durability tranche pending that decision.

## Drift note (source snapshot vs. current code)

The source records Tranche 2 as *"Next — confirmed 100% greenfield (no worker/connector/S3
package or dependency exists anywhere in the reactor)"*. That reflects a point-in-time
snapshot taken **before** the Tranche 2 walking skeleton was built. The `ocbc-cloud-sync`
code repository has since **added a `worker-service` module that already delivers the
Tranche 2 scenario**: it claims the `EXTRACT` task (`SKIP LOCKED`), reads a real file via a
`SourceConnector`, uploads it to S3 (LocalStack in dev/test), and is proven end-to-end by
`WorkerExtractFlowIT`. The code is therefore **ahead of this roadmap snapshot** for
Tranche 2; treat the roadmap's status column as a plan-time view, not current build state.

## Related pages

- [[reference/cloud-sync-user-stories]] — the CS-xxx story catalogue the tranches draw from
- [[reference/data-acquisition-cloud-sync-detailed-design]] — the five-component decomposition (Orchestrator, Worker, Sync Push Service, Operations Service, Scheduler Job Adapter) the tranches build out
- [[synthesis/data-acquisition-architecture-overview]] — cross-cutting architecture synthesis
- [[concepts/data-onboarding-orchestration-pipeline]] — the run state machine the tranches exercise
