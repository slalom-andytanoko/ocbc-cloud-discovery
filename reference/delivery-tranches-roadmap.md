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
  Updated 2026-08-15 (CS-071/CS-072 mapping): CS-071 (pre-computed special_value_date table)
  and CS-072 (special values population batch job) added in user stories v1.0 (2026-08-13).
  Both mapped to T7 — they are the table-lookup replacement for runtime Jollyday computation
  and are inseparable from Epic G (CS-060–062).
  Updated 2026-08-15 (build-review corrections): CS-045 split — the IAM zone-isolation policies
  (DD-B10's compensating control) move to T4 because they must precede the transfer path they
  protect, with the remainder staying in T6b; CS-028 removed from the T3 ID list and named
  explicitly in T4, resolving a duplication between the table and the decision notes;
  CS-063/CS-064 descriptions corrected, as both previously described CS-063 and CS-064's real
  subject (decompression monitoring) was absent; and the non-existent `DECOMPRESSED` status
  corrected to `TRANSFERRING → DECOMPRESSING → COMPLETED`. CS-025 deliberately stays in T4.
  Updated 2026-08-15 (CS-027 reassignment): CS-027 (SLA-breach detection) moved T4→T3, resolving a
  contradiction where the tranche table assigned it to T4 while the prose listed it under T1.
  It is implemented in the delivered build (`SlaDeadlineResolver`, `RunSlaBreachEvaluator`, five
  CS-027 unit tests), so T3 follows the same "placed where delivered" rule applied to CS-021,
  CS-011, CS-012, CS-053, CS-063, CS-064, CS-004 and CS-008. Alert *routing* remains CS-043 in T6b.
  Updated 2026-08-15 (CS-040 split; CS-007 correction): CS-040 → part T1 (resume incl. the
  validation-failure refusal) / remainder T6b (staged-batch-removed refusal, which needs CS-059
  retention to exist before the guard is meaningful). CS-007 was briefly split T2/T4 the same day on
  the strength of the 2026-08-07 findings and is **not** split — the S3 source connector, ETag check
  and multipart abort were all delivered 2026-08-11 (DD-B2) and are verified in the source. Knock-on:
  T4's scenario promised two remaining connectors but only REST/FileNet (CS-005) is outstanding.
  Updated 2026-08-15 (T1–T3 criterion-level sweep): all 33 T1–T3 stories checked criterion by
  criterion against main source. **Only 5 of 33 meet every criterion** (CS-007, CS-010, CS-011,
  CS-041, CS-058); CS-003 is divergent; 27 are partial. Most partials are the tranche model working
  as designed (a story's push-path or operations-UI criteria belong to T5/T6b), but ten genuine gaps
  belong to no later tranche — chief among them that a run can wait in `TRANSFERRING` or
  `DECOMPRESSING` **indefinitely** when no SLA deadline is configured, and ten registry columns
  (security sign-off, classification, the push limits) that no code reads. CS-005 and CS-070 split
  part/remainder as a result. Full findings in the sweep section.
  Updated 2026-08-15 (T4 verification sweep): every T4 story checked against source. T4 is now
  **🟡 Partially delivered**, not Planned — CS-003/CS-005/CS-010/CS-045(part)/CS-070 done,
  CS-014/CS-028/CS-065/CS-069 partial, CS-025/CS-054/CS-055/CS-066/CS-067 not started, and CS-068
  raised as a **divergence**: the built key layout (`<zone>/<pipelineId>/<batchDate>/`) contradicts
  the specified canonical layout (`batch_date=YYYY-MM-DD/<source_system>/<filename>`), which must be
  settled before CS-025 publishes it across the boundary.
  Updated 2026-08-15 (T4→T3 move): the four **fully** delivered T4 stories — CS-003, CS-005, CS-010
  and CS-070 — moved to **T3**, extending the "recorded where delivered" precedent that had already
  moved eight stories the same way. T3 now holds 15 stories and is where the connector set was
  completed; T4's scenario narrows to "a clean landing" and its Readiness and Connectors proximity
  groups are now empty. T4 stays 🟡 because CS-025 still cannot publish a transfer event.
  **CS-045(part) stays in T4**, corrected after being briefly moved with the four: its policy JSON is
  authored in `docs/S3-ZONE-ISOLATION.md` but not provisioned to any IAM identity and not applied by
  IaC, so the boundary it exists to enforce does not exist yet, and DD-B10 makes it unverifiable until
  CS-025 replaces the demo executor.
provenance:
  extracted: 0.9
  inferred: 0.1
  ambiguous: 0.0
base_confidence: 0.8
lifecycle: draft
created: 2026-08-06
updated: 2026-08-15 (CS-027 moved T4→T3; earlier same-day build-review corrections — CS-045 split T4/T6b, CS-028 duplication resolved, CS-063/CS-064 descriptions corrected)
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
| **1** | Request to simulated completion *(status ✅ describes the scenario; see the criterion-level sweep — only 5 of 33 T1–T3 stories meet every criterion)* | Request → admission (dedupe / concurrency ceiling) → simulated task execution → cancel / resume / replay → two-phase transfer-complete callback (`TRANSFER` / `DECOMPRESSION`) → terminal state | Orchestrator only | CS-001, CS-015, CS-017, **CS-018** (audit trail — every state transition written to `run_event`), CS-020 *(simulated stub — hardened in T6a)*, CS-021 *(simulated stub — real Worker impl in T3)*, CS-022, CS-026, CS-029, CS-037 *(simulated stub — hardened in T6a)*, CS-038 *(simulated stub — hardened in T6a)*, **CS-040** *(resume from checkpoint — fully delivered: refusal after a validation failure, refusal when the staged batch has been removed (`StagedBatchAvailability` / `S3StagedBatchAvailability` → `StagedBatchUnavailableException` → 422, checked only for checkpoints whose next step reads staged data), and an audited operator override past the retry budget. Briefly split to T6b on 2026-08-15 before the staged-batch check was verified present)*, CS-041, CS-053 *(simulated stub — real VALIDATE task in T3)*, CS-058 | ✅ Done — verified against the Orchestrator source |
| **2** | Request to S3 (walking skeleton) | Same admission/dispatch, then a **Worker claims the task, executes one real connector, writes the file to mock/local S3 (LocalStack / MinIO) via the S3 API, reports completion**, and the run reaches a terminal state | Orchestrator **+ new Worker service** | CS-006, **CS-007** *(fully closed — write side in T2; the S3-compatible/ECS **source** connector, the ETag/version-change check and multipart upload with `AbortMultipartUpload` all landed 2026-08-11 per DD-B2)*, **CS-009** (pass-through byte integrity), **CS-019** (bounded-memory streaming — `LocalFileSourceConnector` enforces size pre-check; `S3Uploader` streams via `InputStream`; closed here, not re-opened in T4), **CS-023** (staging zone isolation — `raw/` prefix write) | ✅ Done (ahead of snapshot) — `worker-service` delivers the walking skeleton, proven by `WorkerExtractFlowIT` (see drift note below) |
| **3** | Request to S3, but things go wrong | Same flow, **hardened**: transient Worker failure → retry with backoff; classify-and-promote runs as its own task; real readiness check, manifest validation, decompression pipeline, SLA-breach detection, all four source connectors, compression, and tier routing | Orchestrator + Worker | CS-016 (retry), CS-024 (classify+promote), **CS-021** *(real CHECK_READINESS — JdbcTemplate query; stub was T1)*, **CS-011** (required manifest fields), **CS-012** (batch integrity), **CS-053** *(real VALIDATE task — reads `_manifest.json`, checks CS-011/CS-012; stub was T1)*, **CS-027** *(SLA-breach detection and the no-deadline config-gap alert; moved T4→T3 2026-08-15 — alert **routing** is CS-043 in T6b)*, **CS-063** (decompress landed content — stream each `.gz` through `GZIPInputStream`, re-upload without the suffix, delete the original), **CS-064** (monitor the decompression component — Micrometer metrics, health indicator, idle and repeated-failure alerts), **CS-004** (JDBC/Oracle relational connector), **CS-008** (Parquet landing — depends on CS-004; not implemented in T2, moved here), **CS-005** *(REST/FileNet content-repository connector — `RestSourceConnector` fetches a single configured item path, surfaces 429/401 as transient for CS-016 and streams to scratch for CS-019. **Fully delivered** on assumption AS-01: CS-005 has one-item-per-entry, the same rule as CS-006/CS-007, so its enumeration and pagination criteria are **dropped rather than deferred** — briefly split part-T3/remainder-T4 on 2026-08-15 before AS-01 closed it)*, **CS-003** *(uniform acquisition contract — `SourceConnectorFactory` dispatches `LOCAL`/`JDBC`/`REST`/`S3` on the registry `source_type`, including the CS-003 E1 unsupported-type path. Briefly marked divergent on 2026-08-15 because the story specifies **three** operations where `SourceConnector` declares one; **resolved by narrowing the story** on assumption AS-01 — with one-item-per-entry no connector needs `enumerate`, and CS-003's "**optionally** verify readiness" is satisfied by a JDBC-only `SourceReadinessProbe` outside the interface, since `ReadinessMode` is only `NONE`/`DB_POLL` and CS-022 gives file/object sources their readiness from Control-M)*, **CS-010** *(compress before transfer — `S3Compressor` + `WorkerTaskExecutor.executeCompress`; moved T4→T3)*, **CS-070 (part)** *(medallion tier **resolution** — `executePromote` reads `target_tier` from the registry, defaults to `BRONZE`, and records it on the run and manifest so a misassignment is auditable per RSK-08. The **routing** half — writing to the tier's per-application bucket `dacq-<env>-<app>-<tier>` — is not implemented: `S3Promoter` copies within one bucket to the `transfer-ready/` prefix and the tier selects nothing. Remainder in T4, gated on CS-025; the push-path `allowed_tiers`/403 validation arrives with T5)* | ✅ Done — CS-016 (retry/backoff) and CS-024 (real Worker S3 raw→transfer-ready promotion) both delivered; CS-021/CS-027/CS-053/CS-063/CS-064/CS-004 implemented ahead of the T4 sweep, and CS-003/CS-005/CS-010/CS-070 moved here on 2026-08-15 after source verification. Full `mvn verify` green. |
| **4** | A clean landing | **All four connectors are now delivered** (moved to T3), so what remains here is the *landing* half of the original scenario: the remaining validation-chain members, classification labelling, the caller-supplied-path stories, the canonical key layout, and the real transfer-event publish that lets a batch actually leave the premises | Worker service | **Readiness & Scheduling:** *(CS-021 and CS-027 both moved to T3 as implemented; the readiness-poll timeout bound remains open here — see finding #16)* · *(Connectors: all four delivered and in T3. CS-005's enumeration/pagination remainder was **closed on assumption AS-01** — CS-005 has one-item-per-entry like CS-006/CS-007, so those criteria are dropped rather than built. CS-003 likewise closed by narrowing its three-operation contract to the single `extract` the code declares.)* · **Validation & Manifest Integrity:** 🔲 **CS-054** (format/size validator), 🔲 **CS-055** (registration-completeness check) — *neither exists; the eight-validator chain covers CS-011/CS-012/CS-019/CS-004 only* · **Classification:** 🟡 **CS-014** (registry `classification` field present, but `executePromote` applies only `target_tier` — no classification label is attached to the objects) · **Caller-supplied path / Key layout:** 🟡 **CS-065** (`Run.sourcePath` column and accessors only), 🔲 **CS-066** (dedup not extended to `source_path`), 🔲 **CS-067** (no `allowed_path_prefix`, no normalisation, no traversal rejection), ⚠️ **CS-068** (**divergence, not a gap** — the built layout is `<zone>/<pipelineId>/<batchDate>/` per `S3Zone`, *not* CS-068's canonical `batch_date=YYYY-MM-DD/<source_system>/<filename>`; needs a decision before it is built, see the note below), 🟡 **CS-069** (structural gate only — `source_system.application_id` FK to `application`, which carries `approved_at`, replaces the former `source_system_allowlist` table; no onboarding-time allowlist validation in code) · **Zone & Transfer Boundary:** 🔲 **CS-025** (`PUBLISH_TRANSFER_EVENT` — the **single remaining** `DemoTaskExecutor` stub; the event's batch location must be the run's **own** prefix, `…/<batchDate>/replay=<n>/` for a replay, not the batch root, or a replay's transfer points at the batch it superseded), 🔲 **CS-070 (remainder)** (tier → **bucket routing**: writing each file to `dacq-<env>-<app>-<tier>`. Today `S3Promoter` copies within one bucket and the resolved tier selects nothing, so the tier is recorded but never routed on. Gated on CS-025, which carries the tier across the boundary; the push-path `allowed_tiers` validation and its fail-closed `403` arrive with T5), 🟡 **CS-045 (part)** (**authored, not provisioned** — the zone-isolation policy JSON exists in `docs/S3-ZONE-ISOLATION.md` and the `S3Zone` two-prefix model is in code, but no IAM identity has the policy applied and there is no IaC to apply it. The document is explicit: *"Without them the zone boundary does not exist — the code separates the zones, but only IAM can enforce the separation."* It is also unverifiable until CS-025 exists, since DD-B10 defers the check to "when the real transfer path replaces `DemoTaskExecutor`". Stays in this tranche so provisioning lands with, or before, the CS-025 publish it protects; remainder of CS-045 stays in T6b), 🟡 **CS-028** (hold-at-`SECURED` with bounded backoff and an alert after N attempts is implemented in `RunProgressionService`/`ScanProperties`; the outage-**trigger** mechanism is still undecided) *(CS-010 compression and CS-070 tier routing moved to T3)* | 🟡 **Partially delivered** — verified against source 2026-08-15. Partial: CS-014, CS-028, CS-045(part), CS-065, CS-069. Not started: CS-025, CS-054, CS-055, CS-066, CS-067, CS-070(remainder). Decision needed: CS-068. *(Four delivered stories moved to T3. CS-070 splits part-T3/remainder-T4. **CS-005's and CS-003's remainders were closed on assumption AS-01** — CS-005 has one-item-per-entry, so enumeration and pagination are dropped rather than built, and both stories sit whole in T3.)* |
| **5** | Caller pushes, not pull | Caller **pushes data synchronously** → admission control → direct S3 write → timeout handling | **New Sync Push Service** | CS-030, CS-031, CS-032, CS-033, CS-034, CS-035, CS-036, **CS-056** (governance metadata consistency check — placeholder completed when Q-03 retention values resolved; T5 is the first tranche exercising the validation chain on a second mode) | 🔲 Planned |
| **6a** | Real scheduler, real gateway | The Tranche 2–4 flow, triggered by a **real Control-M contract** and authenticated via **real mTLS / Entra ID** instead of the API-key stand-in | **New Scheduler Job Adapter + new API Gateway** | CS-020, CS-037, CS-038 (hardening — no new IDs), **CS-002** (credential vaulting via CyberArk/Conjur — same class of "replace the stand-in" work as the API-key → Entra ID swap) | 🔲 Planned |
| **6b** | Operator sees and reacts | Operator queries run state → resumes / replays a failed run → is alerted on SLA breach → quarantines poison batches | **New Operations Service** | CS-039, **CS-042** (quarantine — deferred from T3 scope decision 2026-08-07), CS-043 *(includes CS-027's alert routing — configurable severity and delivery via the observability platform, replacing the `[ALERT]` log stand-in)*, CS-044, **CS-045 (remainder)** (at-rest posture per D18, per-source landing segregation, and retention-driven cleanup — the zone-isolation policies stay in T4, where their provisioning is outstanding), CS-046, CS-047, CS-048, CS-049, CS-050, **CS-051** (read-only pipeline config view), **CS-052** (read-only run status/history view), **CS-059** (zone retention enforcement — blocked on Q-03 retention values; Operations Service owns housekeeping) | 🔲 Planned |
| **7** | Business dates resolve themselves | `batch_date` special values (`CURRENT_DATE`, `PREVIOUS_MONTH_END_DATE`, …) → resolved to a concrete business date **at run initiation** using the system-wide **anchor date** + per-country **calendars**; anchor rolled forward by a scheduled Control-M job; special values pre-computed into `special_value_date` table by a batch job (Jollyday confined to batch only) | Orchestrator (**`dal-calendar` library**) + Sync Push Service | CS-060, CS-061, CS-062 (Epic G), **CS-071** (pre-computed `special_value_date` table — `dal-calendar` reads table not runtime computation), **CS-072** (special values population batch job — Jollyday confined here) | 🔲 Planned — **final tranche** (split from T3, 2026-08-12) |
| **— deferred** | Schema change detection + data owner verification | Not in build scope for this phase; tracked in backlog | — | **CS-013** (schema change detection — BL-005; deferred 2026-07-29), **CS-057** (data owner verification — BL-006; deferred 2026-07-31, WARN-only when adopted) | ⏸ Deferred to backlog |

## What the tranche boundaries clarify

- **The "five use cases + one guardrail" that the current Orchestrator extract implements
  are Tranche 1**, not Tranche 2. Tranche 1's CS-xxx set is exactly UC-1 (CS-001/015/020),
  UC-2 (CS-021/022), UC-3 (CS-040/041/053), UC-4 (CS-058), UC-5 (CS-029), the auth guardrail
  (CS-026/037/038), and the supporting traceId (CS-017) and audit-trail (CS-018) mechanisms.
  **Note:** this sentence previously also named CS-027 (SLA) as a T1 supporting mechanism, which
  contradicted the T4 row that owned its deliverable. CS-027 is now assigned to T3 — see the
  2026-08-15 decision note below.
  **Note:** CS-021 and CS-053 appear in T1 as *simulated stubs only*; their real Worker
  implementations (JdbcTemplate readiness query and manifest validation) are T4 deliverables.
- **Tranche 2 is specifically the Worker "walking skeleton"** — one real connector writing to
  real (mock/local) S3 — and is keyed to the *connector* stories CS-006/007/008, not the
  progression stories CS-021/022 that drive it.
- **Tranche 3 now includes the implemented T4 stories**: CS-021 (real CHECK_READINESS),
  CS-011/CS-012/CS-053 (manifest validation chain), CS-063/CS-064 (decompression
  pipeline core), and CS-004 (JDBC/Oracle relational connector) — all confirmed implemented
  ahead of the full T4 connector sweep and moved here to reflect actual build state.
- **Tranche 4 is partially delivered, not planned**, and its four fully delivered stories (CS-003,
  CS-005, CS-010, CS-070) moved to T3 on 2026-08-15 — see the verification sweep for the per-story
  verdict. What remains is the landing half: CS-025 is the last `DemoTaskExecutor` stub, CS-045(part)
  is authored but unprovisioned, and CS-068 is a divergence needing a decision rather than a build.
- **Tranche 4's proximity groups have collapsed from six to four.** Readiness & Scheduling is empty
  (CS-021 and CS-027 moved to T3; only the readiness-poll timeout bound from finding #16 remains),
  and Connectors is empty (all four delivered, CS-003/CS-005 moved to T3). The groups still carrying
  work are Validation & Manifest Integrity (CS-054, CS-055), Classification (CS-014),
  Caller-supplied path / Key layout (CS-065, CS-066, CS-067, CS-068, CS-069) and Zone & Transfer
  Boundary (CS-025, CS-028). For the original six-group rationale: (1) Readiness & Scheduling;
  (2) Connectors
  (CS-005 — REST/FileNet; CS-004/JDBC/Oracle moved to T3 as implemented); (3) Validation & Manifest Integrity (CS-054/055 — format/size bounds
  and registration completeness; CS-011/012/053 moved to T3 as implemented); (4) Classification
  (CS-014 — governance labelling before `CLASSIFY_AND_PROMOTE`); (5) Compression/Decompression
  Pipeline (CS-010/065/066/067/068/069 — compress before transfer and the remaining S3 key
  conventions; CS-063/064 moved to T3 as implemented); (6) Zone & Transfer Boundary (CS-025 real
  `PUBLISH_TRANSFER_EVENT`, CS-045-part IAM zone isolation, CS-028 outage-hold — the three things
  that must be true before a batch can actually leave the premises).
  Also: CS-003 (uniform acquisition contract — closed when all four connectors exist), CS-070
  (medallion tier routing at S3 write time).
  Note: CS-019 (bounded-memory streaming) is **closed in T2** — T4 connectors must satisfy the
  same acceptance criterion but the story is not re-opened.
- The later tranches are cumulative hardening: **3** adds core durability (retry and real
  classify-and-promote); **4** adds the remaining connectors, real decompression, and real
  validation; **5** adds the synchronous push path; **6a/6b** replace the API-key and manual
  stand-ins with real scheduler/gateway auth and an operator-facing Operations Service; and
  **7** (final) adds Epic G business-date resolution (CS-060–062) and the pre-computed
  special values table (CS-071/CS-072 — added in user stories v1.0, 2026-08-13). Three Tranche-3 items were reassigned:
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
(classify-and-promote, delivered 2026-08-12).** *(Superseded by the 2026-08-12 gap note below:
T3 subsequently absorbed CS-021, CS-011, CS-012, CS-053, CS-063, CS-064, CS-004 and CS-008 as
implemented ahead of the full T4 sweep. The tranche table above is T3's current contents.)*
Epic G's mechanism is fully specified (CS-060 token set, CS-061
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

## 2026-08-15 correction note (build review of `ocbc-cloud-sync`)

A code review of the delivered T1–T3 build against the story catalogue found five errors in this
roadmap. All five are corrected above. Every CS-xxx in the catalogue (CS-001–CS-072) remains
assigned to exactly one tranche, or split across two where noted.

- **CS-045 split — zone-isolation policies to T4, remainder in T6b.** CS-045 sat wholly in T6b,
  two tranches after the capability it protects. DD-B10's own text is the argument: *"The boundary
  must be real before the AWS transfer path is built."* That path is CS-025, which is T4, so the
  IAM policies in `docs/S3-ZONE-ISOLATION.md` are a **T4 prerequisite**, not a T6b deliverable —
  *(the 2026-08-15 sweep confirmed the policies are authored but not provisioned, so this item
  remains open in T4 exactly where the argument places it)* —
  and T2/T3 code (CS-023 staging isolation, CS-024 promotion) already relies on a boundary that
  nothing yet enforces. The remainder of CS-045 (at-rest posture per D18, per-source landing
  segregation, retention-driven cleanup, which pairs with CS-059) legitimately stays in T6b with
  the Operations Service. Splitting a story across tranches follows the precedent already set by
  CS-021, CS-053, CS-020, CS-037 and CS-038.
- **CS-028 duplication resolved.** The T3 ID list carried CS-028 with the parenthetical
  "deferred from T3 scope decision 2026-08-07", while both the 2026-08-07 decision note and the
  2026-08-12 gap note place it in T4 — where it was not actually listed. It is now removed from T3
  and named explicitly in T4. Note the drift: the delivered build *does* implement the outage hold
  (`RunProgressionService` holds `PUBLISH_TRANSFER_EVENT` transient failures at `SECURED` with
  bounded backoff and alerts after a configured attempt count), so the code is ahead of both
  entries. What genuinely remains open in T4 is the **outage-trigger mechanism**, which is why the
  story is not closed.
- **CS-063 / CS-064 descriptions corrected.** T3 described CS-063 as "list `.gz` objects under
  prefix" and CS-064 as "stream → GZIPInputStream → re-upload → delete original". Both describe
  CS-063. CS-064 is *Monitor the decompression component* — metrics, health, and the idle and
  repeated-failure alerts — and its actual subject appeared nowhere in this roadmap. The build
  implements it correctly (`DecompressionMetrics`, `DecompressionMonitor`,
  `DecompressionHealthIndicator`), so the defect was in the plan, not the code; anyone scoping
  remaining work from the old text would have thought monitoring was still to do.
- **`DECOMPRESSED` is not a run status.** The 2026-08-12 gap note described wiring
  `DECOMPRESSING → DECOMPRESSED → COMPLETED`. `RunStatus` has no such value and Detailed Design
  §6.1 specifies `TRANSFERRING → DECOMPRESSING → COMPLETED`.
- **The 2026-08-12 Epic G decision's closing claim was stale.** It asserted "Tranche 3 is now just
  CS-016 … and CS-024", which the 2026-08-12 gap note in the same file then contradicted by moving
  eight further stories into T3. Marked superseded rather than rewritten, since the Epic G decision
  itself still stands.

## 2026-08-15 criterion-level sweep — T1–T3 are not complete at criterion level

All 33 T1–T3 stories were checked criterion by criterion against main source (not tests, not
review documents, not the guardrails register's own claims). **Only 5 of 33 meet every acceptance
criterion.** The tranche status columns say ✅ Done for T1, T2 and T3; that is true of the
*scenario* each tranche demonstrates, and not true of the stories' full criteria.

| Verdict | Count | Stories |
|---|---|---|
| COMPLETE | 5 | CS-007, CS-010, CS-011, CS-041, CS-058 |
| DIVERGENT | 1 | CS-003 |
| PARTIAL | 27 | the rest |

**Most PARTIAL verdicts are the tranche model working as designed, not defects.** A story sliced
across modes cannot be complete before the later mode is built, so an unmet "Given the on-demand
mode…" criterion in T3 is expected: it belongs to T5. This accounts for one criterion each in
CS-003, CS-008, CS-015, CS-016, CS-017, CS-018, CS-019 and CS-053, and the operations-UI criteria in
CS-064 (T6b). **Read the 27 as "sliced", not "broken", unless it appears below.**

### The genuine gaps — unmet and owned by no later tranche

These are not explained by a future tranche and are not recorded as deviations anywhere.

| # | Gap | Stories | Why it matters |
|---|---|---|---|
| 1 | **A run can wait in `TRANSFERRING` or `DECOMPRESSING` forever.** No stage-level timeout exists; `RunTaskDispatcher` maps both to `Optional.empty()` and the only escape is `RunSlaBreachEvaluator`, which no-ops when `sla_deadline_at` is null — which `RunAdmissionService` deliberately permits | CS-026, CS-063 | Directly contradicts CS-026's "Given the callback never arrives… the run is marked failed or SLA-breached, rather than the run remaining in transfer indefinitely". Operationally the worst kind of failure: silent and unbounded |
| 2 | **Two registry columns are unread by a tranche that is already closed** — narrowed 2026-08-15. Ten columns on `PipelineRegistryEntry` have no reader, but **eight are correctly awaiting a later tranche** and are not gaps: `onboarding_status`, `expected_format`, `environment`, `data_owner`, `landed_prefix_template` → T4 (CS-055, CS-054, CS-068); `max_payload_bytes`, `max_item_bytes`, `compression_skip_bytes` → T5 (CS-030–036). The two genuine ones each have a **second** reader that was due in a closed tranche: `security_signoff` (CS-001's *"lacks security sign-off → rejected, no run is created"*, **T1**) and `classification` (CS-024's *"validation, compression, **and classification** have all succeeded"* before clearing, **T3**) | CS-001 (T1), CS-024 (T3) | An unapproved pipeline runs and lands data today, and a batch is cleared with no sensitivity label attached. Both criteria belong to tranches marked ✅. **The original framing of this row treated all ten as gaps, which mis-applied this sweep's own "sliced, not broken" rule** — the same rule correctly applied to the push-mode criteria one paragraph above |
| 3 | **Per-validator outcomes are not audit records.** They are serialised into the VALIDATE task's `result_payload` and surface as one `TASK_COMPLETED` event | CS-053 | Detailed Design §7.1 explicitly requires the Orchestrator to copy them into `run_event` rows. As built they are not individually queryable, so CS-053's "outcomes are audit, not a separate report" is unmet |
| 4 | ~~`DD-B11` cited in code but missing from the register~~ — **CLOSED 2026-08-15 19:27.** DD-B11 now exists and records the decision: promotion relies on deterministic destination keys plus byte-identical attempts rather than a fencing token, and it explicitly closes Detailed Design §12's fencing item. The gap was register hygiene and the register has caught up | CS-024 | Resolved |
| 5 | ~~Two stale register claims~~ — **CLOSED 2026-08-15 19:27.** DD-B3 now names `parquet-floor` explicitly and warns against "restoring" the Avro/DOUBLE mapping. DD-A15's `retry_error_classification` wording is loose rather than wrong: `db/schema.sql` documents the table as *"reference data; CS-016 classification is carried in the task result envelope's `error_class` instead"*, which is what the code does | CS-008, CS-016 | Resolved |
| 6 | **Zero-byte source file is not caught at acquisition.** `LocalFileSourceConnector` checks existence and the maximum size only | CS-022 | CS-022's exception path wants a *timing mismatch* error when the scheduler fires before the source finished writing. Instead the batch stages, uploads, and fails two steps later as `MANIFEST_EMPTY` — the wrong diagnosis for the actual fault |
| 7 | **Excess initiations are rejected, not queued.** `requireWithinConcurrencyCeiling` throws → 429 | CS-029 | CS-029 says "Excess initiations **wait** rather than execute". Waiting is delegated to the caller. Defensible, but it is a behavioural difference from the story and is undocumented |
| 8 | **On-demand idempotency has no enforcement.** `Run.idempotencyKey` has a setter nothing calls, and there is no `(caller_identity, idempotency_key)` uniqueness in code. No deduplication *window* exists either — the lookup is unbounded in time | CS-015 | The window is partly a T6b/retention dependency, but the composite-uniqueness constraint is the mechanism CS-015 and platform §11.3 name explicitly and it is absent |
| 9 | **`source.max_connections` is read nowhere.** `SourceReadinessProbe` opens a raw `DriverManager` connection per poll with no pool | CS-021, CS-047 | Contradicts DD-13's claim that `dal-connectors` maintains a bounded per-source pool. CS-021's "aggregate poll load bounded by configuration" is unmet, and CS-047 (T6b) rests on the same absent mechanism |
| 10 | **CS-003 is divergent, not partial** — see the T3 row. The connector contract has one operation where the story specifies three | CS-003 | Needs a decision: narrow the story or widen the interface |

Gap 1 is the one to action first: it is a correctness and operations problem in delivered code, not a
planning artefact. Gaps 4 and 5 closed within hours of being raised.

### The codebase is a moving target — date every verdict

`design-decisions-and-guardrails.md` was rewritten at **19:27 on 2026-08-15**, after the sweep above
had read the source. Three findings changed as a result, in both directions:

- **CS-040 is fully delivered, not partial.** The staged-batch-removed refusal now exists
  (`StagedBatchAvailability` / `S3StagedBatchAvailability` → `StagedBatchUnavailableException` → 422,
  scoped to the checkpoints whose next step actually reads staged data), and so does an audited
  operator override past the retry budget. Its T6b split, made earlier the same day, has been
  **reverted** — the story sits wholly in T1.
- **Gaps 4 and 5 closed**, as above.
- Gaps 1 and 3 were **re-tested after the rewrite and still hold**: no stage-level timeout exists for
  `TRANSFERRING`/`DECOMPRESSING` (`ScanProperties` has readiness, idle, active, stale-claim and
  outage-hold knobs, and no transfer-stage knob), and per-validator outcomes still reach `run_event`
  only as one `TASK_COMPLETED` blob.
- **Gap 2 was narrowed from ten columns to two.** The ten unread columns are real, but eight are
  waiting on the tranche that owns their reader (T4 or T5) and are therefore *sliced, not broken* —
  the same rule this sweep applies to push-mode criteria. Only `security_signoff` and `classification`
  are genuine, because each has a second reader that was due in an already-closed tranche (CS-001 in
  T1, CS-024 in T3). **The original row applied the rule inconsistently**, which is worth recording:
  the failure mode of a criterion-level sweep is treating every unmet criterion as a defect, and the
  tranche model means most are not.

**Consequence for how this page is used.** Any status here is a claim about a specific commit, not a
standing fact. Three of my own errors on 2026-08-15 came from trusting a dated artefact — a review
finding, a policy document, a register entry — over the source at the moment of asking. Re-verify
before acting, and prefer the source and the register together over either alone.

## 2026-08-15 verification sweep — T4 reconciled against source

The CS-007 error below showed this roadmap's T4 status was a plan-time view, so every T4 story was
checked against the `ocbc-cloud-sync` source and the build's decision register rather than against
review documents. **T4 is roughly half delivered, not "Planned".** Five stories are done, four are
partial, four are not started, and one is a divergence needing a decision.

| Verdict | Stories | Evidence |
|---|---|---|
| ✅ Delivered → **moved to T3** | CS-003, CS-005, CS-010, CS-070 | `SourceConnectorFactory`, `RestSourceConnector`, `S3Compressor`, `executePromote` tier resolution |
| 🟡 Partial — **stays in T4** | CS-014, CS-028, CS-045(part), CS-065, CS-069 | Registry field, authored-but-unprovisioned policy, or structural gate present; enforcing behaviour absent (see the row above for each) |
| 🔲 Not started | CS-025, CS-054, CS-055, CS-066, CS-067 | `CS-025` is the last live `DemoTaskExecutor` branch; no CS-054/CS-055 validator; no caller-path prefix or dedup extension |
| ⚠️ Divergence | CS-068 | Built layout contradicts the specified one — below |

**The four fully delivered stories were moved to T3** (decided 2026-08-15), extending the precedent
that already moved eight implemented-ahead stories T4→T3. The rule is applied consistently: a story
is recorded in the tranche where it was actually delivered, so CS-003, CS-005, CS-010 and CS-070 sit
in T3 alongside CS-004 and CS-008 rather than inflating a "planned" tranche with finished work.

**CS-045(part) was initially moved with them and moved back** — it is authored, not delivered. The
sweep first read "the policy document exists" as the deliverable being met. It is not: the roadmap's
own wording for this item is that the policies "must be provisioned *before* the transfer path can
read the zone", and provisioning is what has not happened. No IAM identity carries the policy and no
IaC applies it, so the enforcement the item exists to create does not exist. The document states the
consequence plainly — *"Without them the zone boundary does not exist"* — and DD-B10 defers
verification to "when the real transfer path replaces `DemoTaskExecutor`", making the item dependent
on CS-025, which is in this tranche. It therefore stays in T4 as 🟡. This is the same class of error
as the CS-007 one below: treating a written artefact as evidence of a delivered capability.

Two consequences worth noting. **T3 now holds 15 stories** and is the tranche where the connector
set was completed — its scenario line has been widened accordingly, since "things go wrong" no
longer describes everything in it. **T4's scenario narrowed to "a clean landing"**: with every
connector delivered, what remains is the landing half — the outstanding validation-chain members,
classification labelling, caller-supplied paths, the canonical key layout, the zone-isolation
provisioning, and CS-025. The tranche is still not demonstrable end-to-end, because CS-025 cannot yet
publish a transfer event, so its status stays 🟡 rather than being reduced further.

### CS-068 — the built key layout diverges from the specified one

`S3Zone.batchRootFor()` builds `<zone>/<pipelineId>/<batchDate>/`. CS-068 specifies
`<app-bucket>/batch_date=YYYY-MM-DD/<source_system>/<filename>`. Three differences, each with a
consequence:

1. **No Hive-style `batch_date=` partition key.** CS-068's stated benefit is that "partition pruning
   works without a crawler or a Glue catalog partition registration step" for Athena/Spark/Glue
   consumers. A bare date segment does not prune.
2. **`pipelineId`, not `source_system`.** CS-068 keys on the registered source system. One source
   system can carry several pipelines, so the built layout partitions more finely than the contract
   consumers were given — and a consumer reading "everything from source X for date D" must know
   every pipeline ID rather than one source ID.
3. **Consequence for CS-025.** The transfer event carries the batch location, so publishing before
   this is settled would ship the divergent layout across the boundary to DataSync and into the
   landing buckets, where it becomes a consumer-visible contract rather than an internal detail.

This is **not** simply unbuilt work, so it should not be scoped as such. Either the layout is
migrated to the canonical form before CS-025 publishes, or CS-068 is amended and the consuming teams
re-agree it, since §9.6 calls the landed layout "a contract with the consuming applications, not an
internal detail". Note the built layout is deliberate and load-bearing elsewhere: replay isolation
(`batchPrefixFor`, `belongsToBatchPrefix`) depends on the batch-root/`replay=<n>` nesting, so any
migration must preserve that property. Raised here rather than silently reclassified.

## 2026-08-15 scope decision — CS-040 split to T6b; CS-007 confirmed fully closed

A pass over the T1–T3 stories marked ✅ against their full acceptance criteria looked for work
closed in-tranche with a residue recorded only in the code-review findings. Two candidates were
already handled correctly and needed no change: CS-020/CS-037/CS-038 carry *(simulated stub —
hardened in T6a)* and appear in the T6a row, and CS-027's alert routing went to CS-043 in T6b when
it moved to T3. Of the remaining two, one was a real gap and one was a false alarm.

**CS-040 → part in T1, remainder in T6b.** T1 delivers resume-from-checkpoint including the
refusal after a validation failure — `RunResumeService.resume()` inspects the most recent FAILED
task and throws `NonResumableRunException` when it was `VALIDATE`. The unmet criterion is refusing
a resume once *"the staged batch has already been removed by the retention policy"*: the service
performs no staged-data presence check, and there is no `CS-040` or staged-batch entry in the
build's own decision register. No retention policy exists to remove the batch either — that is
**CS-059**, in T6b and blocked on Q-03. Assigning the guard earlier would mean writing a check
against a state the system cannot yet produce, so it travels with the retention work. Follows the
part/remainder precedent set by CS-045, CS-021 and CS-053.

**CS-007 → no split. Fully closed, verification error corrected.** This story was briefly split
T2/T4 earlier the same day on the strength of the **2026-08-07** code-review findings, which record
*"no S3 source connector"*, *"ETag check deferred"* and *"multipart abort deferred"*. Those findings
were **four days stale**. Checking the source instead shows all three delivered on 2026-08-11 and
recorded as decision **DD-B2** in the build's own register:

| CS-007 criterion | Implementation |
|---|---|
| Read a single configured object from object storage | `S3SourceConnector`, config-selected by `source_type = S3`; bucket and key prefix resolved from `source_system` |
| Fail when the object's ETag/version changes between the readiness signal and the read | `GetObjectRequest…ifMatch(head.eTag())`; a 412 becomes `SourceObjectChangedException` |
| Abandon an incomplete chunked upload so no partial object remains | `S3Uploader.uploadMultipart()` above `multipart_threshold_bytes`, with `abortQuietly()` issuing `AbortMultipartUpload` on both `IOException` and `RuntimeException` |

Coverage is `S3SourceConnectorTest` (ETag change, missing, oversize, download), `S3UploaderTest`
(single vs multipart, abort-on-failure) and `WorkerS3ObjectStorageIT` — a real LocalStack round-trip
covering both the multipart upload and an actual ETag change between `HeadObject` and `GetObject`.
That integration test also closes the gap raised as finding #2 in the 2026-08-12 review, which noted
the ETag check was implemented but only unit-tested.

**Consequence for T4, which was hiding the same staleness.** T4's scenario promised *"the remaining
two connectors (REST/FileNet, S3-compatible/ECS)"*. The S3-compatible/ECS connector already exists,
so **only REST/FileNet (CS-005) is outstanding** — corrected in the row above. Anyone sizing T4 from
the old text would have double-counted a connector that is already built and tested.

**Method note.** The dated code-review findings under `output/code-review/` are point-in-time
snapshots, and this roadmap's own drift note already warns that its status column is a plan-time
view. Both cut the same way: **verify a story's state against the source and the build's decision
register (`design-decisions-and-guardrails.md`), not against a review document alone.** The CS-027
move earlier the same day was checked that way; this one initially was not.

## 2026-08-15 scope decision — CS-027 moved T4 → T3

CS-027 (*Detect and alert on SLA breach*) was **contradictorily assigned**: the tranche table put
its deliverable ("no-deadline config-gap alert") in T4, while the "What the tranche boundaries
clarify" prose listed it among T1's supporting mechanisms. Neither was correct, and the
contradiction meant anyone scoping remaining T4 work would have counted CS-027 as outstanding.

**It is now T3**, on the same rule this roadmap already applies eight times over: a story is placed
in the tranche where it was actually delivered. CS-027 is implemented in the T1–T3 build, across
all four of its acceptance criteria:

| CS-027 criterion | Implementation |
|---|---|
| Completion within the deadline stays `COMPLETED` | `RunSlaBreachEvaluator.checkAndRecord()` returns early on a terminal status |
| Deadline passing in flight → `SLA_BREACH`, alert flag set, alert raised | `run.breachSla()` + `run.markAlertSent()` + `SLA_BREACHED` audit event + `[ALERT] SLA_BREACH` log |
| A breach that later completes keeps both visible, breach not overwritten | `SLA_BREACH` is terminal; the `SLA_BREACHED` event persists in `run_event` independently of the run's final status |
| No deadline configured → no breach, gap reported | `SlaDeadlineResolver` returns `null` and logs `[ALERT] SLA_NOT_CONFIGURED` naming the pipeline; a separate WARN covers the pipeline-override-absent/env-default-present case |

Unit coverage is five `@DisplayName("CS-027: …")` tests in `RunAdmissionServiceTest` (override wins,
env-default fallback, neither configured, gap recorded in the audit trail, non-positive default
refused at binding time).

**Thematic fit also favours T3.** T3's theme is "things go wrong" — durability and detection.
Missing an SLA is a thing going wrong. T4's theme is "every source, and a clean landing", which is
about connector breadth and landing correctness; SLA detection was never a member of that set, and
it sits in the Orchestrator rather than the Worker that T4 builds out.

**Split, not wholly closed.** The *detection* is complete in T3. The *routing* — configurable
severity and delivery through the central observability platform — is **CS-043 in T6b**; the build
currently uses a `[ALERT]` log line as the stand-in, exactly as CS-020/CS-037/CS-038 use the
API-key stand-in until T6a. This follows the split precedent already set by CS-045, CS-021 and
CS-053.

**Not changed, deliberately.** CS-025 stays in T4 rather than moving to T3, on two hard
dependencies rather than a sequencing preference: Q-13/DI-06 leaves the short-lived-credential
vending mechanism undecided, and the receiving side (EventBridge, Trigger Lambda, DataSync) is out
of build scope per user stories §2 — so a real publish is neither authenticable nor demonstrable
yet, failing this roadmap's own "runnable, testable slice" principle. What was recorded instead is
the payload constraint a T4 build must honour (the run's own prefix, not the batch root) and the
module consequence: `S3Zone` currently lives in `worker-service` while the event is published by
`orchestration-service`, so T4 should move it to `cloud-sync-common` rather than duplicate the
layout rule.

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

- **Readiness & Scheduling (CS-021, CS-027):** ✅ Both moved to T3. CS-021 real `CHECK_READINESS`
  Worker task (JdbcTemplate query against `readiness_query`/`readiness_expected_value` columns)
  implemented. CS-027 likewise implemented (`SlaDeadlineResolver`, `RunSlaBreachEvaluator`) and
  moved on 2026-08-15 — see the decision note below. The readiness-polling timeout bound remains
  open in T4 (see finding #16).
- **Validation & Manifest Integrity (CS-011/012/053):** ✅ Moved to T3. CS-053 real
  `VALIDATE` task implemented — reads `_manifest.json` from S3, checks CS-011 required
  fields and CS-012 batch integrity. CS-013 (schema-drift) and CS-057 (data-owner
  verification) remain deferred (BL-005/BL-006). CS-054/055 remain open in T4.
- **Compression/Decompression Pipeline (CS-063/064):** ✅ Moved to T3. `DECOMPRESSION`
  Worker task implemented — `S3Decompressor` lists `.gz` objects, streams through
  `GZIPInputStream`, re-uploads without `.gz` suffix, deletes original; full state machine
  wiring (`TRANSFERRING → DECOMPRESSING → COMPLETED`, per Detailed Design §6.1 — there is no
  `DECOMPRESSED` status in `RunStatus`). CS-065/066/067 (caller-supplied-path),
  CS-068 (canonical key layout), CS-069 (allowlisted system IDs) remain open in T4.
- **Connectors (CS-004):** ✅ Moved to T3. JDBC/Oracle relational connector implemented.
  CS-005 (REST/FileNet) and remaining Epic A connectors not yet started (remain in T4).
- **CS-028:** not yet started (remains in T4).

## Related pages

- [[reference/cloud-sync-user-stories]] — the CS-xxx story catalogue the tranches draw from
- [[reference/data-acquisition-cloud-sync-detailed-design]] — the five-component decomposition (Orchestrator, Worker, Sync Push Service, Operations Service, Scheduler Job Adapter) the tranches build out
- [[synthesis/data-acquisition-architecture-overview]] — cross-cutting architecture synthesis
- [[concepts/data-onboarding-orchestration-pipeline]] — the run state machine the tranches exercise
