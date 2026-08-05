---
title: OCBC Data Acquisition Platform on AWS — v1.1 (Source Document)
category: reference
tags: [aws, data-platform, ocbc, data-acquisition, source-document]
relationships:
  - target: "[[entities/cloud-data-acquisition-service]]"
    type: extends
  - target: "[[reference/data-acquisition-service-lld]]"
    type: extends
sources: ["External: OCBC Data Acquisition Platform on AWS - v1.1.pdf"]
summary: AWS-authored DRAFT v1.1 (24 Jul 2026, 69 pages) of the Data Acquisition Layer design — the current, most detailed and authoritative architecture document, superseding the March 2026 LLD narrative in scope and precision.
provenance:
  extracted: 0.95
  inferred: 0.05
  ambiguous: 0.0
base_confidence: 0.7
lifecycle: draft
lifecycle_changed: 2026-07-28
tier: core
created: 2026-07-28
updated: 2026-07-28
---

# OCBC Data Acquisition Platform on AWS — v1.1 (Source Document)

Reference index for **"OCBC Data Acquisition Platform on AWS"**, DRAFT v1.1, authored by AWS, dated 2026-07-24, 69 pages. Version history inside the document shows v1.0 was issued 2026-07-22 and v1.1 restructured Appendix C, resolved the FinOps question (OQ-06), added Spring Cloud Gateway, reworked the authentication section (§13), and documented the single-non-production-environment decision (A17).

Held under `external/.processed/` (proprietary, gitignored) per the [[external]] handling rules — this page and its linked concept/entity/synthesis pages contain only distilled, paraphrased content.

## Relationship to the Previously-Ingested LLD

This document is a distinct, later document lineage from the "Cloud Data Acquisition Service — Low Level Design" (v1.0, Liang Chen, 11 Mar 2026) already summarised at [[reference/data-acquisition-service-lld]] — different title, different authorship attribution, dated over four months later. `^[ambiguous]` It is not explicitly stated to formally replace the March document, but the architecture, terminology, and use-case content overlap so heavily (same four-then-six-service Cloud Sync design, same UC-1 SCHEDULED_DB_POLL walkthrough, same two-zone staging model) that it should be treated as the **current, authoritative design** wherever the two disagree — it is far more detailed, carries numbered decisions (D01–D24) and assumptions (A01–A17), and is dated most recently. `^[inferred]`

## Document Structure (69 pages)

1. Version History
2. Executive Summary
3. Business Context and Scope
4. High-Level Architecture (3 diagrams: system context, on-prem detail, AWS transfer/landing detail)
5. Key Architectural Decisions (D01–D24)
6. Assumptions and Constraints (A01–A17)
7. Deployment and Hosting Strategy
8. Component Summary
9. Detailed Component Design (§9.1–§9.8, including Temporal §9.7 and Sync Push Service §9.8)
10. Interface-Mode Designs (Mode 1 pull, Mode 2 push, event-triggered invocation)
11. Data Model (Source Registry, Orchestration Audit, manifest, run state machine)
12. Network and Connectivity
13. Security and Governance
14. Monitoring, Observability and Alerting
15. Cross-Cutting Non-Functional Requirements
16. Outstanding Questions (OQ-01, OQ-03 remain; OQ-04, OQ-06, and non-prod hosting are resolved)
- Appendix A: Sequence Flows
- Appendix B: DataSync Task vs. Task Execution Lifecycle
- Appendix C: VPC and Subnet Sizing
- Appendix D: PostgreSQL VM Sizing
- Appendix E: Single Non-Production Environment — Risks (RSK-01 to RSK-05)

## Headline Facts

- **Six components**, not four: Spring Cloud Gateway, Orchestration Service, Sync Push Service (new — D24), Integration Service + 4 connectors, Control Service, Security Service.
- **Temporal.io (self-hosted)** is the confirmed orchestration engine (D04); **Apache Airflow is explicitly not used** (D16).
- **Tech stack:** Java 25, Spring Boot 4, on Red Hat OpenShift (D17).
- **Identity/secrets:** MS Entra ID (D14) for external/human auth; CyberArk Vault via Conjur (D22) for runtime secret resolution.
- **Four connectors:** JDBC (Oracle), REST (WFI/IBM FileNet), Connect:Direct via NFS/Samba/SFTP (WFTS), S3-compatible (Dell EMC ECS ObjectStore).
- **No on-prem at-rest encryption** (D18) — CMK-KMS at the S3 destination is the sole encryption layer.
- **Single non-production environment** — UAT (A17); no SIT environment. Databases are AWS-hosted in UAT as an interim measure only; production databases are on-prem.
- **Only 2 outstanding questions remain** requiring OCBC stakeholder input: OQ-01 (performance/scale volumes) and OQ-03 (catalog/lineage expectations).

## Distilled Into

- [[entities/cloud-data-acquisition-service]] — updated with the six-component architecture
- [[concepts/data-onboarding-orchestration-pipeline]] — updated run state machine and step sequence
- [[concepts/temporal-io-workflow-orchestration]] — D04, persistence store placement, checkpoint/resume
- [[concepts/sync-push-service-architecture]] — D24, Mode 2 design
- [[concepts/source-registry-and-audit-data-model]] — §11 data model
- [[concepts/dal-security-authentication-and-secrets]] — §13 auth methods and encryption scope
- [[synthesis/data-acquisition-open-decisions]] — D01–D24 register and outstanding questions
- [[synthesis/data-acquisition-architecture-overview]] — updated cross-cutting synthesis
- [[deliverables/findings]] — Airflow/diagram staleness and single-non-prod-environment risks (RSK-01–RSK-05)

## Related

- [[reference/data-acquisition-service-lld]] — the earlier (Mar 2026) LLD this document supersedes in detail
- [[reference/cloud-sync-user-stories]] — the requirements baseline built from this design
- [[reference/uc1-scheduled-db-poll-narrative]] — a detailed walkthrough of one pull-mode use case

## Sources

- External: OCBC Data Acquisition Platform on AWS - v1.1.pdf
