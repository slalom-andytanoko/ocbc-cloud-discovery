---
title: Data Acquisition — Open Decisions (Alignment Matrix)
category: synthesis
tags: [ocbc, data-acquisition, open-decisions, governance]
relationships:
  - target: "[[entities/cloud-data-acquisition-service]]"
    type: related_to
  - target: "[[reference/data-acquisition-platform-v1.1]]"
    type: extends
sources: ["External: Mar 11 _Data-Acquisition-Service-LLD-NarrativeV1.0[63].pdf", "External: OCBC Data Acquisition Platform on AWS - v1.1.pdf", "External: OCBC Data Acquisition Platform on AWS - v1.2.md", "External: OCBC Data Acquisition Platform on AWS - v1.3.md", "External: OCBC Data Acquisition - Cloud Sync User Stories.md", "External: Re__IaC_Deployment_Process/OCBC Data Acquisition - Cloud Sync Detailed Design.md"]
summary: OCBC's internal alignment matrix (11 items, 9 Mar 2026) plus v1.1/v1.2/v1.3 design-decision evolution; Temporal-based orchestration in v1.1 is superseded by the in-service orchestration run driver in v1.2, v1.3 defers two validators (schema drift, ownership check) to the backlog while resolving the Control-M scheduler-contract question via a new Scheduler Job Adapter, and the 2026-08-03 Detailed Design closes D03 with a 15-item decision register (DD-01–DD-15) and resolves Q-15 (post-landing decompression ownership).
provenance:
  extracted: 0.9
  inferred: 0.1
  ambiguous: 0.0
base_confidence: 0.7
lifecycle: draft
lifecycle_changed: 2026-08-03
tier: core
created: 2026-07-27
updated: 2026-08-03
---

# Data Acquisition — Open Decisions (Alignment Matrix)

Section 5 of the earlier LLD document ("OCBC internal alignment matrix") lists 11 decision points OCBC had not yet finalised as of 9 Mar 2026. v1.1 (24 Jul 2026) resolved several of these and introduced a numbered decision register. v1.2 (28 Jul 2026) then updated orchestration decisions again (notably removing Temporal.io). v1.3 (31 Jul 2026) retires D20 into assumption A16, resolves the Control-M scheduler-contract question (formerly OQ-08), and defers two validators — schema drift and data-owner verification — to the backlog (BL-005, BL-006). Status below reflects that evolution and is carried into [[open-questions]].

| # | Decision Point | Owner | Status (9 Mar 2026) | Status (v1.1, 24 Jul 2026) |
|---|---|---|---|---|
| 1 | On-prem & cloud unified orchestration solution | TBD | WIP | **Resolved and updated**: v1.1 selected Control-M + Temporal (D04/D16); v1.2 removes Temporal and uses an in-service orchestration run driver (engine-agnostic seam retained). |
| 2 | Data classification process and ownership model | Anand | Already have — needs enhancement for unstructured data | Design confirmed (D18, §13.3 — metadata-driven, DLP out of scope); operational ownership still open |
| 3 | Data acquisition data and process ownership model | Anand | — | Still open |
| 4 | Encryption/tokenization process, technology, and ownership | Radha | — | Technology confirmed (D18 — CMK-KMS at S3 sole layer, no on-prem at-rest); ownership still open |
| 5 | AWS Organization SCP structure | Remy | — | Still open (not addressed in v1.1) |
| 6 | On-prem and AWS key management process/ownership | TISO | — | Vault product confirmed (D22 — CyberArk, via Conjur); operational ownership still open |
| 7 | On-prem and AWS secret management process/ownership | TISO | — | Same as #6 — CyberArk Conjur confirmed as the mechanism; ownership still open |
| 8 | Cloud resource access model (direct desktop vs. EUC) | — | WIP | Not addressed in v1.1 — still open |
| 9 | Operating model for handling infra/job/data/security-compliance failures | Anand | — | Partially addressed — v1.1 defines the alerting/observability model (§14) and outage/resume behaviour (D21), but the human operating-model/runbook question remains open |
| 10 | Code development, build, and promotion process | Anand | — | Still open |
| 11 | Non-prod on-prem environment for the Red Hat OpenShift cluster | Radha | — | **Resolved — A17**: single non-production environment (UAT only, no SIT); UAT runs on the existing on-prem OpenShift cluster, but its databases are AWS-hosted as an interim measure (creating the risks in Appendix E, RSK-01–RSK-05) |

## Current Decision Register (v1.1, D01–D24)

v1.1 numbers every architectural decision. The full text of each is in the source document; the ones with the most wiki impact are cross-referenced here:

| ID | Decision | Wiki page |
|---|---|---|
| D03 | Physical microservice decomposition — **resolved 2026-08-03**, see the DD-01–DD-15 register below | [[reference/data-acquisition-cloud-sync-detailed-design]] |
| D04 | Temporal.io (self-hosted) is the durable-execution engine for scheduled-pull | [[concepts/temporal-io-workflow-orchestration]] |
| D05 | Orchestration Audit table shares the Source Registry's PostgreSQL database (separate from Temporal's own store) | [[concepts/source-registry-and-audit-data-model]] |
| D13 | Extraction SQL is always registry-held and parameterised — never built programmatically at runtime | [[concepts/source-registry-and-audit-data-model]] |
| D14 | MS Entra ID is the identity provider for external/human DAL access | [[concepts/dal-security-authentication-and-secrets]] |
| D16 | Apache Airflow is **not used** — Temporal (D04) + Control-M cover scheduling/orchestration | [[concepts/temporal-io-workflow-orchestration]] |
| D17 | Java 25 / Spring Boot 4 on Red Hat OpenShift | [[entities/cloud-data-acquisition-service]] |
| D18 | No on-prem encryption at rest; CMK-KMS at S3 is the sole encryption layer; classification is metadata-driven | [[concepts/dal-security-authentication-and-secrets]] |
| D20 | *(retired — superseded by A16)* | — |
| D21 | On-prem DAL must keep operating during an AWS/Direct Connect outage — pull-mode holds/resumes at the `SECURED` checkpoint; push-mode fails fast | [[concepts/temporal-io-workflow-orchestration]], [[concepts/sync-push-service-architecture]] |
| D22 | CyberArk Vault, accessed via Conjur, is the runtime secrets-resolution mechanism | [[concepts/dal-security-authentication-and-secrets]] |
| D24 | A dedicated Sync Push Service (not the Orchestration Service) serves the synchronous-push mode, with no workflow engine | [[concepts/sync-push-service-architecture]] |

## Detailed Design Decisions (DD-01–DD-15, 2026-08-03) — D03 Closed

[[reference/data-acquisition-cloud-sync-detailed-design]] (DRAFT v0.1) closes **D03** with a five-component decomposition — **Orchestrator, Worker, Sync Push Service, Operations Service, Scheduler Job Adapter** — replacing the earlier indicative Integration/Control/Security/Orchestration split. Full register:

| ID | Decision (condensed) |
|---|---|
| DD-01 | Five components, each with a different scaling/failure profile |
| DD-02 | Database-as-task-queue; no broker; no direct service-to-service calls |
| DD-03 | Orchestrator drives readiness via repeated short dispatched tasks, never blocking |
| DD-04 | One task per logical pipeline step (six task types) |
| DD-05 | Classify and promote combined into one task (inseparable at the S3 API level) |
| DD-06 | Transactional row locking on runs; **no persistent lease** — supersedes the v1.3 §9.7.2 lease/TTL/fencing model |
| DD-07 | Stale-task detection recovers from a worker crash between claim and completion |
| DD-08 | Shared pipeline logic (connectors, validation, compression, classification, calendar) is Java libraries, not services |
| DD-09 | Single OpenShift namespace; isolation via Deployment-level resource limits |
| DD-10 | One Spring Cloud Gateway fronts all services |
| DD-11 | Separate `run` (pull) and `push_run` (on-demand) tables — different lifecycles/writers |
| DD-12 | Operations Service proxies write actions (resume/replay/cancel) to the Orchestrator, next phase |
| DD-13 | Per-source connection ceiling enforced by the shared `dal-connectors` library |
| DD-14 | DDD tactical patterns for internal service structure, elaborated during implementation |
| DD-15 | **Post-landing decompression, no on-demand compression** — resolves **Q-15**; see [[reference/data-acquisition-platform-v1.3]] Epic H / CS-063-CS-064 |

**This is a materially different physical topology from what this wiki's [[concepts/data-onboarding-orchestration-pipeline]] previously modelled as four separately-deployed services** (now updated with a superseding note) — see [[deliverables/findings]] #8 for the reconciliation risk this raises against any implementation already underway.

## v1.3 Updates (31 Jul 2026)

- **Scheduler Job Adapter added (resolves OQ-08).** A lightweight component runs inside the Control-M job itself, calling the initiate endpoint and then polling the DAL PostgreSQL directly for run status until a terminal state — exiting `0` on `SECURED`, non-zero on failure. See [[reference/data-acquisition-platform-v1.3]] and [[concepts/data-onboarding-orchestration-pipeline]].
- **File/object readiness moved off polling.** Source systems have no file-marker/completion signal, so readiness for file/object sources is now the Control-M job dependency itself — no DAL-side file-watch polling. Relational sources keep a registry-held, source-agnostic parameterised readiness query (no fixed `BATCH_CONTROL` schema assumed).
- **One file/object per pipeline entry.** Pattern-based multi-file enumeration is removed from the acquisition contract.
- **Two validators deferred to the backlog:**
  - **BL-005 — Schema change detection (CS-013).** Specified in the validation chain design but not built this release.
  - **BL-006 — Data owner verification (CS-057).** When eventually adopted, WARN-only and outside the validation chain's critical path.
- **New Epic G (business-date resolution)** added to the companion user-stories baseline (v0.5): special date values (`CURRENT_DATE`, `PREVIOUS_MONTH_END_DATE`, etc.) resolved against a system-wide anchor date and per-country business calendars — see [[reference/cloud-sync-user-stories]].

## Outstanding Questions Still Open in v1.1 (§16)

Only two questions remain that require direct OCBC stakeholder input (all others in the original 24-item register, including the former OQ-04 service-to-service auth question and OQ-06 FinOps/cost-attribution question, are now resolved):

| ID | Question |
|---|---|
| OQ-01 | Confirmed performance/scale volumes (peak concurrent runs, largest single-batch size, sustained throughput) needed to finalise DataSync agent-pool sizing and PostgreSQL VM sizing (Appendices C/D) |
| OQ-03 | Catalog/lineage expectations for landed data — whether the DAL itself must register lineage metadata or whether this is purely a downstream (AI platform) concern |

The [[reference/cloud-sync-user-stories]] document's own `Q-01`–`Q-12` open-question register substantially overlaps with OQ-01/OQ-03 (payload/volume profiles, throughput confirmation, retention windows) plus a handful of push-specific implementation details (idempotency edge cases, size/duration limits) not yet elevated to numbered v1.1 decisions — tracked in full at [[reference/cloud-sync-user-stories]] rather than duplicated here.

## Single Non-Production Environment — Risk Register (Appendix E)

Because OCBC will run only one non-production environment (UAT, A17), v1.1's Appendix E documents 5 risks (RSK-01–RSK-05) this creates — e.g. UAT is the only pre-production gate before every release, UAT's AWS-hosted databases mean the D21 on-prem-outage-resume guarantee is unproven until production, and there is no environment to load-test agent-pool/PostgreSQL sizing at production scale before go-live. See [[deliverables/findings]] for these captured as findings.

## Why This Matters for the Engagement

Several of these are direct inputs to gap-analysis and backlog work already tracked in this repo:
- **#1 (orchestration)** directly explains the Control-M vs. Airflow tension flagged in [[synthesis/data-acquisition-architecture-overview]].
- **#5 (SCP structure)** is a prerequisite for the DLP/access guardrails discussed in [[concepts/s3-data-lake-zone-design]].
- **#4 (encryption/tokenization ownership)** and **#6/#7 (key/secret management ownership)** all bear directly on [[concepts/data-tokenization-and-encryption]] and [[concepts/kms-byok-key-management]] — the technical design is documented, but who *owns* running it operationally is not yet settled.

## Related

- [[entities/cloud-data-acquisition-service]]
- [[synthesis/data-acquisition-architecture-overview]]
- [[concepts/data-onboarding-orchestration-pipeline]]
- [[concepts/s3-data-lake-zone-design]]
- [[concepts/data-tokenization-and-encryption]]
- [[concepts/kms-byok-key-management]]
- [[concepts/temporal-io-workflow-orchestration]]
- [[concepts/sync-push-service-architecture]]
- [[concepts/dal-security-authentication-and-secrets]]
- [[reference/data-acquisition-platform-v1.1]]
- [[reference/data-acquisition-platform-v1.3]]
- [[reference/cloud-sync-user-stories]]
- [[reference/data-acquisition-cloud-sync-detailed-design]]

## Sources

- External: Mar 11 _Data-Acquisition-Service-LLD-NarrativeV1.0[63].pdf
- External: OCBC Data Acquisition Platform on AWS - v1.1.pdf
- External: OCBC Data Acquisition - Cloud Sync User Stories.md
- External: OCBC Data Acquisition Platform on AWS - v1.3.md
- External: Re__IaC_Deployment_Process/OCBC Data Acquisition - Cloud Sync Detailed Design.md
