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
summary: DRAFT v0.8 requirements baseline deferring the schema-drift and ownership validators to the backlog, replacing pattern-based file/object enumeration with one-file-per-pipeline-entry, moving file/object readiness onto the Control-M job-dependency signal, resolving the Scheduler Job Adapter contract (Q-25/OQ-08), adding Epic G (business-date resolution) and Epic H (post-landing decompression, resolves Q-15), then adding a caller-supplied-path source type (CS-065–067), a canonical object key layout (CS-068), an allowlisted-system-IDs onboarding gate (CS-069), and (v0.8, gap-analysis reconciliation) the CS-025 event payload carrying source_id so the cloud transfer path can resolve its DataSync task from the event alone.
provenance:
  extracted: 0.9
  inferred: 0.1
  ambiguous: 0.0
base_confidence: 0.68
lifecycle: draft
lifecycle_changed: 2026-08-05
tier: supporting
created: 2026-07-28
updated: 2026-08-05
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
