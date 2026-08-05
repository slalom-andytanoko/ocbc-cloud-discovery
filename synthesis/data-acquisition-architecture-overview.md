---
title: Data Acquisition Architecture — Cross-Cutting Synthesis
category: synthesis
tags: [aws, data-platform, ai-platform, ocbc, data-acquisition]
relationships:
  - target: "[[entities/cloud-data-acquisition-service]]"
    type: extends
  - target: "[[entities/ai-platform-architecture]]"
    type: extends
sources:
  - "External: Mar 11 _Data-Acquisition-Service-LLD-NarrativeV1.0[63].pdf"
  - "External: data acquisition[68]  -  Read-Only.pptx"
  - "External: Overall AI Platform Arch.png"
  - "External: Data Aqusition.png"
  - "External: image001.png"
  - "External: image002.png"
  - "External: OCBC Data Acquisition Platform on AWS - v1.1.pdf"
  - "External: OCBC Data Acquisition - Cloud Sync User Stories.md"
  - "External: uc1_scheduled_db_poll_narrative.docx"
  - "External: data acquisition.pptx"
  - "External: OCBC Data Acquisition Platform on AWS - v1.3.md"
summary: How the on-prem Cloud Data Acquisition Service (now six components), its AWS landing accounts, and the wider AI Factory platform fit together — read across all ingested source files, with the Control-M/Airflow tension resolved by v1.1 and the Control-M scheduler-contract question (OQ-08) resolved by v1.3's Scheduler Job Adapter.
provenance:
  extracted: 0.6
  inferred: 0.35
  ambiguous: 0.05
base_confidence: 0.8
lifecycle: draft
lifecycle_changed: 2026-07-31
tier: core
created: 2026-07-27
updated: 2026-07-31
---

# Data Acquisition Architecture — Cross-Cutting Synthesis

This page connects the two architecture diagrams and two sequence diagrams from the "Data Acquisition" workstream deck with the narrative LLD document, to give a single end-to-end picture.

## The Big Picture

```
OCBC Corporate Data Center (on-prem, Red Hat OpenShift)
  Sources: Teradata EDW, Cloudera/EBP, WFI, SharePoint, App DBs, NFS, on-prem S3, Intellistore
        │
        ▼
  Cloud Sync Service (Integration / Control / Security / Orchestration)
        │  (AWS Direct Connect only — no public internet)
        ▼
On-prem-to-Cloud-Data-Acquisition-Account (Prod/Non-Prod, AWS Singapore; DR, AWS Malaysia)
  AWS DataSync agents (private subnets) → S3 Gold-Staging / Bronze zones
        │
        ▼
Cloud-Data-Acquisition-Account (AI platform side)
  SageMaker Lakehouse Catalog, Gold Zone (curated)
        │
        ▼
AI-Factory-SS-Account (shared services: eval, registry, feature store, MLflow)
        │
        ▼
OCBC AI-Non-Production-Account / AI-Production-Account (AI Lab Suites: experimentation + serving)
        │
        ▼
AI-Control-Tower-Account (governance: observability, CI/CD, SecOps, FinOps)
```

See [[entities/cloud-data-acquisition-service]] for the on-prem/landing detail and [[entities/ai-platform-architecture]] for the AI Factory detail. This connecting flow between the two is `^[inferred]` — the two diagrams were not explicitly cross-referenced in the source, but the account names and data flow direction make the relationship clear.

## Two Ingestion Paths, One Governance Model

- **Batch (structured/unstructured), scheduled-pull mode**: on-prem Cloud Sync Service → AWS DataSync over Direct Connect → S3, orchestrated by **Control-M (schedule) + an in-service orchestration run driver backed by DAL PostgreSQL** (v1.2), superseding the earlier v1.1 Temporal choice and the older per-source-Airflow-DAG design. See [[concepts/data-onboarding-orchestration-pipeline]], [[concepts/source-registry-and-audit-data-model]], and [[reference/data-acquisition-platform-v1.2]].
- **Batch (structured/unstructured), synchronous-push mode**: a dedicated, stateless **Sync Push Service** (v1.1, D24) writes directly to S3 with no on-prem staging and no workflow engine — see [[concepts/sync-push-service-architecture]].
- **Streaming**: on-prem Confluent Kafka → Confluent Cluster/Schema Linking → Confluent Cloud on AWS via PrivateLink. See [[concepts/streaming-data-acquisition]]. (Newly confirmed by the `data acquisition.pptx` "Streaming" slide: separate Kafka Consumer/Producer accounts each running a Lambda Kafka Consumer/Producer against an RDS "FastDB" sink and an S3 "LakeHouse" sink, connecting to a Confluent Cloud Multi-Tenant VPC running Kafka Connect/Schema Registry/KSQLDB/Flink.)

All paths converge on the same protection model — see [[concepts/data-tokenization-and-encryption]] (tokenize/encrypt before leaving on-prem), [[concepts/kms-byok-key-management]] (BYOK CMK per source, SSE-KMS at rest), and [[concepts/dal-security-authentication-and-secrets]] (MS Entra ID + CyberArk Conjur, D14/D22, and the explicit "no on-prem at-rest encryption" decision D18) — and land in the same [[concepts/s3-data-lake-zone-design]] (Gold/Bronze/Egress zones).

## UC-1 Sequence Walkthrough (SCHEDULED_DB_POLL)

The two sequence diagrams (`image001.png` on-prem, `image002.png` cloud) trace one concrete run end-to-end and are the clearest evidence of how the four Cloud Sync services, Control-M, EventBridge, Lambda, and DataSync interact in practice. Full step breakdown lives in [[concepts/data-onboarding-orchestration-pipeline]] under "Sequence Walkthrough". Notably:

- Control-M (not Airflow) is the on-prem scheduler shown triggering the Orchestration Service in this diagram — worth reconciling with the LLD narrative's description of Airflow DAGs as the primary trigger mechanism. `^[ambiguous]`
- The cloud side is explicitly "fully event-driven... zero polling" once EventBridge receives the on-prem `PutEvents` call — DataSync's own built-in checksum verification replaces a separate validation Lambda.

## Notable Design Tensions / Watch Items

- **Control-M vs. Airflow as on-prem orchestrator — RESOLVED; Temporal subsequently superseded.** The old ambiguity between a sequence diagram (Control-M) and the narrative LLD (Airflow DAGs) was first resolved in v1.1 (Control-M + Temporal, Airflow excluded), then updated again in v1.2 where Temporal is removed and replaced by an in-service orchestration run driver. The remaining loose end is **documentation staleness**: architecture diagrams that still show Airflow (and in some places imply Temporal-era assumptions) need redraw to align to v1.2. See [[reference/data-acquisition-platform-v1.2]] and [[deliverables/findings]].
- **Physical decomposition still deferred (D03)** — the six-component model (Gateway, Integration, Control, Security, Orchestration, Sync Push) and its data model remain "indicative" pending a dedicated decomposition workshop; the [[reference/cloud-sync-user-stories]] document is the explicit vehicle meant to close this decision.
- **Two document lineages for the same system** — the March 2026 LLD (Liang Chen) and the July 2026 v1.1 ("OCBC Data Acquisition Platform on AWS", AWS-authored) are different document titles/authors covering the same system, four+ months apart; v1.1 is far more detailed and numbered, and should be treated as authoritative wherever the two disagree. See [[reference/data-acquisition-platform-v1.1]].
- **Manual BYOK key rotation, capped at 25** — an operational constraint that will need a runbook and monitoring for rotations-remaining (see [[concepts/kms-byok-key-management]]).
- **Streaming network design is explicitly provisional** — the source document says to "check with Confluent for optimal connectivity architecture" (see [[concepts/streaming-data-acquisition]]).
- **Single non-production environment (A17)** — UAT is the only pre-prod environment, and its databases are AWS-hosted as an interim measure only, unlike production's on-prem placement — creating documented delivery risks (Appendix E, RSK-01–RSK-05 in the v1.1 lineage). See [[synthesis/data-acquisition-open-decisions]] and [[deliverables/findings]].
- **Two validation-chain checks deferred to the backlog (v1.3)** — schema-drift detection (BL-005) and data-owner verification (BL-006) were specified as part of the validation chain in v1.2/CS-053 but are not built in the current release. Not a documentation gap; a deliberate scope reduction — see [[deliverables/findings]] and [[reference/data-acquisition-platform-v1.3]].
- **Scheduler contract resolved, readiness model split by source type (v1.3)** — a new **Scheduler Job Adapter** running inside the Control-M job bridges Control-M's synchronous model with the DAL's async run lifecycle (resolves former OQ-08). Readiness itself now differs by source type: relational sources still poll a registry-held, source-agnostic query; file/object sources rely on the Control-M job dependency alone (no DAL-side polling), and each pipeline entry names exactly one file/object. See [[concepts/data-onboarding-orchestration-pipeline]].

## Related

- [[entities/cloud-data-acquisition-service]]
- [[entities/ai-platform-architecture]]
- [[concepts/data-onboarding-orchestration-pipeline]]
- [[concepts/data-tokenization-and-encryption]]
- [[concepts/streaming-data-acquisition]]
- [[concepts/s3-data-lake-zone-design]]
- [[concepts/kms-byok-key-management]]
- [[concepts/temporal-io-workflow-orchestration]]
- [[concepts/sync-push-service-architecture]]
- [[concepts/source-registry-and-audit-data-model]]
- [[concepts/dal-security-authentication-and-secrets]]
- [[synthesis/data-acquisition-open-decisions]]
- [[reference/data-acquisition-service-lld]]
- [[reference/data-acquisition-platform-v1.1]]
- [[reference/data-acquisition-platform-v1.2]]
- [[reference/data-acquisition-platform-v1.3]]
- [[reference/cloud-sync-user-stories]]
- [[reference/uc1-scheduled-db-poll-narrative]]

## Sources

- External: Mar 11 _Data-Acquisition-Service-LLD-NarrativeV1.0[63].pdf
- External: data acquisition[68]  -  Read-Only.pptx
- External: Overall AI Platform Arch.png
- External: Data Aqusition.png
- External: image001.png
- External: image002.png
- External: OCBC Data Acquisition Platform on AWS - v1.1.pdf
- External: OCBC Data Acquisition - Cloud Sync User Stories.md
- External: uc1_scheduled_db_poll_narrative.docx
- External: data acquisition.pptx
- External: OCBC Data Acquisition Platform on AWS - v1.3.md
