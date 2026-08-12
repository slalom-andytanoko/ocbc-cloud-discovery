---
title: Open Questions
category: meta
tags: [questions, tracking]
updated: 2026-08-11
cssclass: wide-page
---

# Open Questions

Questions raised during discovery sessions that require follow-up or confirmation.

> See also [[questions]] — the forward-looking consolidated register that pulls these
> still-open items together with the implementation- and delivery-level questions that
> block completing the Cloud Sync build.

| # | Question | Domain | Raised | Owner | Status | Resolution |
|---|----------|--------|--------|-------|--------|------------|
| 1 | Which on-prem & cloud unified orchestration solution will OCBC standardize on — Control-M end-to-end / Control-M on-prem + Managed Airflow in cloud / Airflow on-prem & cloud (Astronomer)? | Orchestration | External: Data Acquisition LLD (2026-03-09 alignment matrix) | TBD | **Resolved** | Finalized by v1.2 (28 Jul 2026): Control-M remains the external trigger, and durable execution is implemented as an in-service orchestration run driver (Temporal removed; Airflow excluded). See [[reference/data-acquisition-platform-v1.2]] and historical context at [[concepts/temporal-io-workflow-orchestration]]. Diagrams still need redraw — tracked as [[deliverables/findings]] #2. |
| 2 | Data classification process and ownership model for unstructured data — how will the existing (structured) process be enhanced? | Data Governance | External: Data Acquisition LLD | Anand | Open | v1.1 confirms the technical design is metadata-driven with DLP out of scope (D18, §13.3), but the operational ownership question remains open. |
| 3 | What is the data acquisition data and process ownership model? | Data Governance | External: Data Acquisition LLD | Anand | Open | Not addressed in v1.1. |
| 4 | What encryption/tokenization process, technology, and ownership model will OCBC adopt (audit of currently available tech/systems/processes needed)? | Security | External: Data Acquisition LLD | Radha | Open | Technology confirmed by v1.1 (D18 — CMK-KMS at S3 as sole encryption layer, no on-prem at-rest encryption); operational ownership still open. |
| 5 | What AWS Organization SCP structure will govern the data acquisition and AI platform accounts? | Governance | External: Data Acquisition LLD | Remy | Open | Not addressed in v1.1. |
| 6 | What is the on-prem and AWS key management process and ownership model? | Security | External: Data Acquisition LLD | TISO | Open | v1.1 confirms CyberArk Vault via Conjur as the mechanism (D22, see [[concepts/dal-security-authentication-and-secrets]]); operational ownership still open. |
| 7 | What is the on-prem and AWS secret management process and ownership model? | Security | External: Data Acquisition LLD | TISO | Open | Same resolution as #6 — CyberArk Conjur confirmed as the mechanism; ownership still open. |
| 8 | Will cloud resource access be direct desktop access or via EUC (Amazon WorkSpaces, Citrix, etc.)? | Access Model | External: Data Acquisition LLD | — | Open (WIP) | Not addressed in v1.1. |
| 9 | What is the operating model for handling infra/job/data/security-compliance failures? | Operations | External: Data Acquisition LLD | Anand | Open | v1.1 defines the alerting/observability model (§14) and outage/resume behaviour (D21), but the human operating-model/runbook question remains open. |
| 10 | What is the code development, build, and promotion process? | DevOps | External: Data Acquisition LLD | Anand | Open | Not addressed in v1.1. |
| 11 | What non-prod on-prem environment will host the data acquisition service's Red Hat OpenShift cluster? | Environments | External: Data Acquisition LLD | Radha | **Resolved** | Confirmed by v1.1 (A17): single non-production environment (UAT only, no SIT), on the existing on-prem OpenShift cluster — but its databases are AWS-hosted as an interim measure, creating documented delivery risks (Appendix E, RSK-01–RSK-05; see [[deliverables/findings]] #4/#5). |
| 12 | Confirmed performance/scale volumes (peak concurrent runs, largest single-batch size, sustained throughput) — needed to finalise DataSync agent-pool sizing and PostgreSQL VM sizing. | Performance / Sizing | External: OCBC Data Acquisition Platform on AWS - v1.1.pdf (OQ-01, §16) | TBD | Open | Also tracked by the User Stories doc's Q-06/Q-10 (push size/duration limits, DataSync throughput confirmation) — see [[reference/cloud-sync-user-stories]]. |
| 13 | Catalog/lineage expectations for landed data — does the DAL itself need to register lineage metadata, or is this purely a downstream (AI platform) concern? | Data Governance | External: OCBC Data Acquisition Platform on AWS - v1.1.pdf (OQ-03, §16) | TBD | Open | — |
| 14 | Scheduler contract — how does Control-M know a DAL run succeeded or failed, given the DAL run is asynchronous? | Orchestration | External: OCBC Data Acquisition Platform on AWS - v1.3.md (OQ-08, §16) | Data platform team + Control-M operators | **Resolved** | v1.3 (31 Jul 2026): a **Scheduler Job Adapter** runs inside the Control-M job, calls the initiate endpoint, then polls the DAL PostgreSQL directly for run status until terminal — exits 0 on `SECURED`, non-zero on failure. See [[reference/data-acquisition-platform-v1.3]] and [[concepts/data-onboarding-orchestration-pipeline]]. |
| 15 | Does readiness for structured sources come from the bank's existing ingestion control framework (with its business-date control table pattern), or does each source expose its own readiness table? Also whether the DAL polls the framework directly or takes the signal through the Control-M job dependency. | Readiness / Governance | External: OCBC Data Acquisition Platform on AWS - v1.3.md (OQ-07, §16) | Data platform team | Open | If the framework is reused, per-source readiness contracting becomes one integration rather than a negotiation with every source system team, and readiness-signal ownership moves to one platform team. |
| 16 | Do any sources land files intraday, outside a scheduled poll window, needing continuous event-driven pickup? Today such a batch is not detected until the next scheduled run. | Readiness / Scheduling | External: OCBC Data Acquisition Platform on AWS - v1.3.md (OQ-09, §16) | Data platform team + source system teams | Open | — |
| 17 | Schema-baseline governance and alert-recipient lists: who owns approving a schema baseline when a source legitimately changes shape, and for which sources is the (now backlog-deferred, BL-005) schema check enabled; also the email recipient lists per alert severity, and whether email alone is sufficient. | Governance / Observability | External: OCBC Data Acquisition Platform on AWS - v1.3.md (OQ-10, §16) | Data platform team + data engineering + observability team | Open | — |
