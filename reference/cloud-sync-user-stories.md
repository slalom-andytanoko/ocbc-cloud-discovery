---
title: OCBC Data Acquisition — Cloud Sync User Stories (Source Document)
category: reference
tags: [aws, ocbc, data-acquisition, user-stories, requirements, source-document]
relationships:
  - target: "[[reference/data-acquisition-platform-v1.1]]"
    type: derived_from
  - target: "[[reference/data-acquisition-platform-v1.5]]"
    type: related_to
  - target: "[[entities/cloud-data-acquisition-service]]"
    type: extends
sources:
  - "External: OCBC Data Acquisition - Cloud Sync User Stories.md"
  - "External: FW__Data_Acquisition_Design_Document/OCBC Data Acquisition - Cloud Sync User Stories.md"
  - "External: Revised_Data_Acquisition_User_Stories_and_Design_Docs/OCBC Data Acquisition - Cloud Sync User Stories.md"
  - "External: Re__IaC_Deployment_Process/OCBC Data Acquisition - Cloud Sync User Stories.md"
  - "External: OCBC Data Acquisition - Cloud Sync User Stories.md (2026-08-05, v0.8)"
  - "External: dod.md"
summary: >-
  DRAFT v0.8 requirements baseline deferring the schema-drift and ownership validators to the backlog, replacing pattern-based file/object enumeration with one-file-per-pipeline-entry, moving file/object readiness onto the Control-M job-dependency signal, resolving the Scheduler Job Adapter contract (Q-25/OQ-08), adding Epic G (business-date resolution) and Epic H (post-landing decompression, resolves Q-15), then adding a caller-supplied-path source type (CS-065–067), a canonical object key layout (CS-068), an allowlisted-system-IDs onboarding gate (CS-069), and (v0.8, gap-analysis reconciliation) the CS-025 event payload carrying source_id so the cloud transfer path can resolve its DataSync task from the event alone.
provenance:
  extracted: 0.9
  inferred: 0.1
  ambiguous: 0.0
base_confidence: 0.68
lifecycle: draft
lifecycle_changed: 2026-08-05
tier: supporting
created: 2026-07-28
updated: 2026-08-15
---

# OCBC Data Acquisition — Cloud Sync User Stories (Source Document)

Reference index for **"OCBC Data Acquisition — Cloud Sync Services User Stories"**, currently ingested at **DRAFT v0.8** (superseding v0.5), Amazon Confidential. It converts the architecture in [[reference/data-acquisition-platform-v1.1]], [[reference/data-acquisition-platform-v1.2]], and [[reference/data-acquisition-platform-v1.3]] (now [[reference/data-acquisition-platform-v1.5]]) into implementable user stories with Given/When/Then acceptance criteria, and is the explicit input meant to close design decision **D03** (physical microservice decomposition, previously deferred).

## Version Notes

- **v0.8 (2026-08-05) — gap-analysis reconciliation, no scope change:** the **CS-025** event payload now carries `source_id`, so the cloud transfer path can resolve the pre-created DataSync task directly from the event, without reading any on-premises store (platform A11; [[reference/data-acquisition-platform-v1.5]] §9.5, Appendix B).
- **v0.7 (2026-08-04):**
  - **CS-068 — Object key layout (new).** Defines the canonical `batch_date=YYYY-MM-DD/<source_system>/` key hierarchy for both on-premises Dell ECS zones and AWS S3 landing buckets. Re-runs for the same batch date create S3 object versions rather than overwriting. CS-023 and CS-032 updated to cross-reference it.
  - **CS-069 — Allowlisted system IDs (new).** Onboarding must validate `source_system_id` against a platform-maintained allowlist — only pre-approved system IDs can be registered (fail-closed).
- **v0.6 (2026-08-04):**
  - **Caller-supplied-path source type (new, CS-065/066/067).** A new source type where the pipeline registers a source system without a specific file name, and the caller supplies the file path at invocation time. CS-065 defines acquisition behaviour, CS-066 deduplication, CS-067 path authorization. Applicable to file-transfer and object-storage protocols only — relational sources excluded (D13). Added to Epic A (shared capabilities) and Required priority; see [[concepts/source-registry-and-audit-data-model]] for the resulting `pipeline_mode`/`source_caller_path_config` schema.
  - **New Epic H — post-landing decompression (CS-063, CS-064), resolves Q-15.** For pipelines with decompression enabled, an AWS-side component decompresses landed file/object content after transfer verification and before the run closes, confirming against the pre-compression manifest checksum and writing back under the same KMS key. Scheduled path only — the on-demand path never compresses file content. A run does not reach `COMPLETED` until this step succeeds (or is skipped, if decompression isn't enabled for that pipeline).
  - Terminology cleanup: "scheduler job" is used consistently for the Control-M unit of work (CS-020, CS-006, CS-007, CS-051), avoiding confusion with a DAL *run*.
  - This baseline is now formally implemented by the companion **[[reference/data-acquisition-cloud-sync-detailed-design]]** (DRAFT v0.1), which closes decision **D03** — see that page for the resulting 5-component decomposition (Orchestrator, Worker, Sync Push Service, Operations Service, Scheduler Job Adapter).
- **v0.5 ingest (2026-07-31):** aligned to v1.3 —
  - **CS-013 deferred (BL-005):** schema change detection moved to the backlog; removed from the CS-053 validator list and from the traceability table.
  - **CS-057 deferred (BL-006):** data owner verification moved to the backlog; when adopted, WARN-only and outside the validation critical path.
  - **One file/object per pipeline entry (CS-006, CS-007):** pattern matching and multi-file enumeration removed.
  - **File/object readiness via Control-M job dependency (CS-022):** file markers and set-stability polling removed.
  - **Readiness query configurable per source (CS-021):** rewritten to hold a parameterised query + expected ready value; the DAL no longer assumes a fixed control-table shape.
  - **Scheduler Job Adapter contract resolved (CS-020, Q-25/OQ-08):** Control-M job stays open and polls the DAL PostgreSQL for run status via the adapter until terminal.
  - **New Epic G — business-date resolution (CS-060–CS-062):** special date values (e.g. `CURRENT_DATE`, `PREVIOUS_MONTH_END_DATE`) resolved against an anchor date and per-country business calendars.
- **v0.4 ingest (2026-07-29):** expanded and clarified the requirements set, including explicit validation-chain extensibility (`CS-053`) and additional governance/ownership checks (`CS-054`–`CS-057` placeholders) while retaining the original epic structure and priority model.
- **v0.1 ingest (2026-07-28):** initial requirements baseline captured from the first markdown export.

## Scope

**In scope:** Spring Cloud Gateway, Orchestration Service, Integration Service + 4 connectors, Control Service, Security Service, Sync Push Service. **Boundary:** AWS-side components (EventBridge, Trigger Lambda, DataSync, S3, KMS) appear only where they define a contract a Cloud Sync service must honour. **Out of scope:** listed in the document's §6, consistent with v1.1 §3.4 (streaming/Kafka consumption, file-content format conversion, tokenisation/masking, DLP, Source Registry onboarding UI, full dynamic query construction, FinOps cost attribution).

## Actors (§4)

| ID | Actor | Role |
|---|---|---|
| DPT | Data platform team | Owns/operates the DAL |
| DEG | Data engineering/governance | Maintains Source Registry metadata |
| SEC | Security and compliance | Approves onboarding; owns classification/key policy |
| SRC | Source system team | Owns the readiness signal |
| CON | Consuming AI/ML application team | Reads landed data; calls the push endpoint |
| — | Control-M | Scheduler (system actor) |
| — | Coordinator service | Consumes Kafka, calls a DAL endpoint (out of DAL scope) |

## Epics and Story Ranges

| Epic | Range | Covers |
|---|---|---|
| A — Shared capabilities | CS-001–CS-019 | Config/secret resolution, connector interface, the 4 connectors (one-file/object-per-entry, CS-006/CS-007), Parquet/pass-through, compression, manifest, validation (schema-drift CS-013 **deferred to backlog BL-005**), classification, idempotency, retry, tracing, audit, bounded-memory streaming |
| B — Mode 1: Scheduled pull | CS-020–CS-029 | Initiate via the **Scheduler Job Adapter** (CS-020, resolves OQ-08), readiness (DB-poll for relational sources; **Control-M job dependency** for file/object sources, CS-021/CS-022 — no more file-watch polling), stage, promote, publish, complete, SLA, outage hold/resume, concurrency ceilings |
| C — Mode 2: Synchronous push | CS-030–CS-036 | Authenticated intake, fetch (incl. relational extracts, CR-01), direct S3 write, timeout, admission control, drain on scale-down |
| D — API edge and identity | CS-037–CS-038 | Gateway token validation, per-caller authorization/rate-limiting |
| E — Operations | CS-039–CS-043 | Query run state, resume, replay, quarantine poison batches, alerting |
| F — Non-functional requirements | CS-044–CS-050 | Environment parity via config, least-privilege zone access, telemetry content governance, connection pooling, OpenShift workload readiness, throughput/latency targets, store resilience/DR |
| G — Business date resolution *(new in v0.5)* | CS-060–CS-062 | Special date values (e.g. `CURRENT_DATE`, `PREVIOUS_MONTH_END_DATE`) resolved against a system-wide anchor date and per-country business calendars |

Additional post-050 user stories (CS-053–CS-057) appear in v0.4/v0.5 and are currently treated as extensions to the same baseline pending formal renumbering/sign-off in delivery planning. Per v0.5, **CS-013 and CS-057 are deferred to the backlog** (BL-005, BL-006) rather than built in this release — see [[reference/data-acquisition-platform-v1.3]].

## Definition of Done (applies to every story)

Audit every state transition (`run_id`, `trace_id`, checkpoint); all secrets resolve from CyberArk Conjur at runtime (none ever logged or stored); idempotency on `pipeline_id + batch_date` (pull) or `idempotency_key` (push); OTLP telemetry with no source-data content or PII; identical behaviour across UAT/Prod/DR via configuration; Source Registry is read-only at execution; unit + containerised integration tests runnable in CI before any UAT deployment.

> **Cross-check against the standalone `dod.md` checklist (External: dod.md):** the project's own literal Definition-of-Done checklist (business functionality/acceptance criteria met, no unattended dependencies, no build failures, >85% unit-test branch coverage, all unit/integration tests passed, penetration test if required, Spotless formatting, no Critical/High Checkstyle or PMD findings, no known defects, documentation updated, peer review passed, CI/CD pipeline available, deployed to UAT — no SIT environment for Cloud Sync Service) is the same list distilled above, at a more granular per-criterion level. **Discrepancy noted:** the `ocbc-data-acquisition` code repo's own copy of this checklist (assessed in [[reference/orchestration-service-mini-code-assessment]]) includes one additional item not present in this canonical `dod.md` — "no Critical/High vulnerabilities in a CI security scan." Logged to [[deliverables/findings]] for follow-up (is the security-scan gate a locally-added extra, or a canonical item missing from this source?).

## Change Requests Against Design v1.1 (§8)

| ID | Change | Stories |
|---|---|---|
| **CR-01** | Synchronous push can serve a relational extract (Parquet), not only a file/object fetch | CS-008, CS-031 |
| **CR-02** | Compression is a shared capability on both paths, not pull-only | CS-010 |

Both are confirmed during requirements review and need v1.1 updated to v1.2 so the two artefacts agree (see open question Q-12).

## Deferred to Backlog (v0.5)

Two validators specified in v0.4's CS-053 chain are pushed out of this release's build scope, tracked in *OCBC Data Acquisition - Backlog Requirements*:

| ID | Story | Backlog Ref | Note |
|---|---|---|---|
| **BL-005** | CS-013 — Schema change detection | Backlog | Specified (§9.1.1 fingerprint-vs-baseline design) but not built. Q-20 (schema-baseline default action) is parked pending this. |
| **BL-006** | CS-057 — Data owner verification | Backlog | When adopted: WARN-only, outside the validation chain's critical path, so a corporate-directory outage cannot block acquisition. Q-17 (directory interface) updated accordingly. |

## Open Questions (§9) — Q-01 to Q-12

The document's own open-question register (`Q-01`–`Q-12`) covers payload/volume profiles, default drift action per classification tier, zone retention windows, replay semantics, push idempotency edge cases, synchronous push size/duration limits, push admission health-gating, alert-rule thresholds, PostgreSQL HA/DR standard, confirmed DataSync throughput, per-source file-watch readiness contracts, and CR-01/CR-02 sign-off. Several of these map onto the same two items v1.1 itself still tracks as outstanding (**OQ-01** performance/scale, **OQ-03** catalog/lineage) — see [[synthesis/data-acquisition-open-decisions]] for the consolidated, deduplicated register.

## Traceability

The document includes a full traceability table mapping each story range back to the v1.1 decisions/sections it implements (§7) — useful when validating that a future implementation covers every confirmed decision.

## Story Index (v0.9 — all 70 CS-xxx stories)

Stories present in the knowledge-base index above are marked ✓. Stories added here from the v0.9 source to complete coverage are marked with their assigned tranche.

### Epic A — Shared capabilities (CS-001–CS-019)

| ID | Title | Tranche | Notes |
|---|---|---|---|
| CS-001 | Initiate a run | T1 | ✓ in index |
| **CS-002** | Resolve credentials at the point of use | T6a | CyberArk/Conjur vaulting — same stand-in replacement class as API-key → Entra ID |
| **CS-003** | Add a source of a supported access type by configuration | T4 | Closeable only once all four connectors exist |
| **CS-004** | Acquire from a relational source | T4 | JDBC/Oracle connector |
| **CS-005** | Acquire from a content repository source | T4 | REST/FileNet connector |
| CS-006 | Acquire from a file-transfer source | T2 | ✓ in index |
| CS-007 | Acquire from an object-storage source | T2 | ✓ in index |
| CS-008 | Produce a Parquet extract from a relational source | T2 | ✓ in index |
| **CS-009** | Land file content unchanged | T2 | Pass-through byte integrity — implicit in T2 walking skeleton |
| **CS-010** | Compress a batch before transfer | T4 | `S3Compressor` gzip on `raw/`; CR-02 confirms both modes |
| **CS-011** | Produce a manifest for every batch | T4 | Required manifest fields |
| **CS-012** | Validate a batch before it is cleared | T4 | Batch integrity check |
| CS-013 | Detect schema changes *(deferred BL-005)* | Backlog | ✓ in index |
| **CS-014** | Classify a batch and record its destination | T4 | Governance labelling before `CLASSIFY_AND_PROMOTE` |
| **CS-015** | Recognise duplicate requests instead of re-executing them | T1 | Idempotency on `pipeline_id + batch_date` / `idempotency_key` |
| **CS-016** | Retry transient failures within limits | T3 | Retry/backoff — delivered in T3 |
| **CS-017** | Correlate a run end to end with one identifier | T1 | Trace ID |
| **CS-018** | Record every state transition | T1 | `run_event` table + `RunEventRecorder` — implicit in T1 Orchestrator skeleton |
| CS-019 | Stream data in bounded memory | T4 | ✓ in index |

### Epic B — Mode 1: Scheduled pull (CS-020–CS-029)

| ID | Title | Tranche | Notes |
|---|---|---|---|
| CS-020 | Initiate via the Scheduler Job Adapter | T1/T6a | ✓ in index (stub T1; real Control-M contract T6a) |
| CS-021 | Poll for source readiness | T1/T4 | ✓ in index (stub T1; real JdbcTemplate query T4) |
| CS-022 | Honour the scheduler's readiness signal | T1 | ✓ in index |
| CS-023 | Write to the staging zone | T2 | ✓ in index |
| **CS-024** | Clear a batch for transfer as a single explicit act | T3 | Classify-and-promote — delivered in T3 |
| CS-025 | Publish the transfer event | T4 | ✓ in index |
| **CS-026** | Close a run on the transfer result | T1 | Two-phase transfer-complete callback (`TRANSFER`/`DECOMPRESSION`) |
| **CS-027** | Detect and alert on SLA breach | T1 | SLA deadline scheduled at admission |
| **CS-028** | Keep working on the premises through a cloud outage | T4 | Outage-hold; deferred from T3 — trigger TBD |
| CS-029 | Enforce a transfer-slot ceiling | T1 | ✓ in index |

### Epic C — Mode 2: Synchronous push (CS-030–CS-036)

| ID | Title | Tranche | Notes |
|---|---|---|---|
| CS-030 | Accept an authenticated on-demand push request | T5 | ✓ in index |
| CS-031 | Fetch the referenced content | T5 | ✓ in index |
| CS-032 | Write directly to the landing zone | T5 | ✓ in index |
| **CS-033** | Return a terminal result within a bounded time | T5 | Synchronous push timeout |
| **CS-034** | Shed load rather than fail unpredictably | T5 | Push admission control |
| **CS-035** | Fail fast when the destination is unreachable | T5 | Destination reachability check |
| CS-036 | Drain in-flight requests on scale-down | T5 | ✓ in index |

### Epic D — API edge and identity (CS-037–CS-038)

| ID | Title | Tranche | Notes |
|---|---|---|---|
| CS-037 | Validate gateway tokens | T1/T6a | ✓ in index (API-key stand-in T1; real Entra ID T6a) |
| CS-038 | Enforce per-caller authorisation and rate limiting | T1 | ✓ in index |

### Epic E — Operations (CS-039–CS-043)

| ID | Title | Tranche | Notes |
|---|---|---|---|
| CS-039 | Query run state | T6b | ✓ in index |
| **CS-040** | Resume a failed scheduled run | T1 | Resume from checkpoint |
| **CS-041** | Replay a batch | T1 | Replay creates a new linked run |
| **CS-042** | Isolate a repeatedly failing batch | T6b | Quarantine — deferred from T3 |
| CS-043 | Alert on SLA breach and failure patterns | T6b | ✓ in index |

### Epic F — Non-functional requirements (CS-044–CS-050)

| ID | Title | Tranche | Notes |
|---|---|---|---|
| CS-044 | Identical behaviour across environments via configuration | T6b | ✓ in index |
| **CS-045** | Grant only the access each step needs | T6b | Least-privilege zone access |
| **CS-046** | Keep data content out of telemetry and metadata | T6b | Telemetry content governance |
| **CS-047** | Protect shared dependencies as demand grows | T6b | Connection pooling / per-source ceiling |
| **CS-048** | Be deployable, observable, and reversible | T6b | OpenShift workload readiness |
| **CS-049** | Meet stated throughput and latency targets | T6b | Throughput/latency targets |
| CS-050 | Survive store failures and recover within RTO | T6b | ✓ in index |

### Post-050 extensions (CS-051–CS-059)

| ID | Title | Tranche | Notes |
|---|---|---|---|
| CS-051 | See pipeline configuration without changing it | T6b | ✓ in index |
| **CS-052** | See run information without operating on runs | T6b | Read-only run status/history view |
| CS-053 | Validate via an extensible chain | T1/T4 | ✓ in index (stub T1; real VALIDATE task T4) |
| CS-054 | Check format and size bounds | T4 | ✓ in index |
| **CS-055** | Refuse to run a source that is not fully registered or source is not active | T4 | Registration-completeness check — validation chain member |
| **CS-056** | Check governance metadata is complete and self-consistent | T5 | Blocked on Q-03; natural fit when second mode exercises validation chain |
| CS-057 | Verify data owner *(deferred BL-006)* | Backlog | ✓ in index |
| **CS-058** | Cancel a run | T1 | Cancel endpoint |
| **CS-059** | Enforce zone retention and remove expired content | T6b | Operations Service housekeeping; blocked on Q-03 |

### Epic G — Business date resolution (CS-060–CS-062)

| ID | Title | Tranche | Notes |
|---|---|---|---|
| CS-060 | Resolve special date tokens to a concrete business date | T7 | ✓ in index |
| **CS-061** | Maintain a system-wide anchor date with scheduled roll-over | T7 | Control-M roll-over job |
| CS-062 | Apply per-country business calendars | T7 | ✓ in index |

### Epic H — Post-landing decompression (CS-063–CS-064)

| ID | Title | Tranche | Notes |
|---|---|---|---|
| CS-063 | List compressed objects under a prefix | T4 | ✓ in index |
| CS-064 | Decompress landed objects in place | T4 | ✓ in index |

### Caller-supplied-path source type (CS-065–CS-067)

| ID | Title | Tranche | Notes |
|---|---|---|---|
| CS-065 | Acquire from a caller-supplied path | T4 | ✓ in index |
| CS-066 | Deduplicate caller-supplied-path runs | T4 | ✓ in index |
| CS-067 | Authorise caller-supplied paths | T4 | ✓ in index |

### Object key and onboarding (CS-068–CS-069)

| ID | Title | Tranche | Notes |
|---|---|---|---|
| CS-068 | Canonical object key layout | T4 | ✓ in index |
| CS-069 | Allowlisted system IDs | T4 | ✓ in index |

### Medallion tier routing (CS-070)

| ID | Title | Tranche | Notes |
|---|---|---|---|
| **CS-070** | Route each file to its medallion tier bucket | T4 | Added in v0.9; Bronze/Gold bucket resolved from registry at S3 write time |

## Related

- [[reference/data-acquisition-platform-v1.1]] — the architecture this document implements
- [[reference/data-acquisition-platform-v1.3]] — the v1.3 design update this v0.5 baseline aligns to
- [[reference/data-acquisition-cloud-sync-detailed-design]] — the microservice decomposition (D03) that implements these stories
- [[reference/uc1-scheduled-db-poll-narrative]]
- [[concepts/sync-push-service-architecture]]
- [[concepts/source-registry-and-audit-data-model]]
- [[synthesis/data-acquisition-open-decisions]]
- [[reference/orchestration-service-mini-code-assessment]] — code assessment traceability against these acceptance criteria

## Sources

- External: OCBC Data Acquisition - Cloud Sync User Stories.md
- External: FW__Data_Acquisition_Design_Document/OCBC Data Acquisition - Cloud Sync User Stories.md
- External: Re__IaC_Deployment_Process/OCBC Data Acquisition - Cloud Sync User Stories.md
