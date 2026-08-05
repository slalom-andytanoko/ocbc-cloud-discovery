---
title: Cloud Data Acquisition Service
category: entities
tags: [aws, data-platform, ocbc, ingestion]
aliases: [CDAS, Cloud Sync Service]
relationships:
  - target: "[[concepts/data-onboarding-orchestration-pipeline]]"
    type: uses
  - target: "[[concepts/streaming-data-acquisition]]"
    type: uses
  - target: "[[concepts/s3-data-lake-zone-design]]"
    type: uses
  - target: "[[concepts/temporal-io-workflow-orchestration]]"
    type: uses
  - target: "[[concepts/sync-push-service-architecture]]"
    type: uses
  - target: "[[concepts/dal-security-authentication-and-secrets]]"
    type: uses
  - target: "[[entities/ai-platform-architecture]]"
    type: related_to
sources: ["External: Mar 11 _Data-Acquisition-Service-LLD-NarrativeV1.0[63].pdf", "External: Data Aqusition.png", "External: OCBC Data Acquisition Platform on AWS - v1.1.pdf"]
summary: OCBC's standardized service for onboarding structured, unstructured, and streaming enterprise data from the on-prem corporate data center into AWS — now also referred to as the Data Acquisition Layer (DAL) in the current (v1.1) design.
provenance:
  extracted: 0.87
  inferred: 0.13
  ambiguous: 0.0
base_confidence: 0.72
lifecycle: draft
lifecycle_changed: 2026-07-28
tier: core
created: 2026-07-27
updated: 2026-07-28
---

# Cloud Data Acquisition Service

OCBC's Cloud Data Acquisition Service (CDAS) orchestrates the ingestion of enterprise datasets from multiple on-premises systems into AWS through an orchestrated, secured, governed, and validated process with audit control. Data from the OCBC corporate data center is first staged in a controlled on-prem environment (the **Cloud Sync Service**, deployed on Red Hat OpenShift) before secure transfer into the cloud over dedicated network connectivity (AWS Direct Connect — no public internet path is used at any point).

## Purpose

Support secure, scalable, automated ingestion of structured, unstructured, and streaming datasets while enforcing encryption, governance, and lifecycle management consistent with banking regulatory requirements.

## Core On-Prem Components (updated per v1.1)

The current (v1.1, 24 Jul 2026) design describes **six** components, not four — the two additions reflect that the earlier LLD's four-service model only covered the scheduled-pull path (see [[concepts/data-onboarding-orchestration-pipeline]] for detail):
- **Spring Cloud Gateway** — single entry point, MS Entra ID token validation, routing to Orchestration/Sync Push
- **Integration Service** — ingestion gateway; 4 connectors (JDBC/Oracle, REST/WFI, Connect:Direct via NFS·Samba·SFTP/WFTS, S3-compatible/Dell EMC ECS)
- **Control Service** — workflow state machine and validation gate ("brain" of the pipeline)
- **Security Service** — tokenization, classification, and application-level encryption
- **Orchestration Service** — durable run lifecycle for the **scheduled-pull mode (Mode 1)**, backed by **Temporal.io** (self-hosted) — see [[concepts/temporal-io-workflow-orchestration]]
- **Sync Push Service** *(new in v1.1, D24)* — dedicated, stateless, horizontally-scaled service for the **synchronous-push mode (Mode 2)**, deliberately excluding Temporal — see [[concepts/sync-push-service-architecture]]

**Tech stack:** Java 25, Spring Boot 4, on Red Hat OpenShift (D17). **Identity/secrets:** MS Entra ID (D14) + CyberArk Vault via Conjur (D22) — see [[concepts/dal-security-authentication-and-secrets]].

## AWS Account & Region Layout

Confirmed from the architecture diagram, the service maps to dedicated AWS accounts per environment:
- **On-prem-to-Cloud-Data-Acquisition-Account-Prod** — AWS Singapore Region. Orchestration: Amazon EventBridge Rule → AWS Lambda → AWS DataSync Service, writing a Manifest File to S3. A VPC with two private subnets, each with a VPC Endpoint feeding AWS DataSync Agents (Tasks). Lands in **S3 PRD Gold-Staging Zone** and **S3 PRD Bronze Zone**, with lifecycle transition to **S3 Glacier Archive**.
- **On-prem-to-Cloud-Data-Acquisition-Account-Non-Prod** — same Singapore region, mirrored orchestration/VPC pattern, landing in **S3 SIT Gold Zone** and **S3 UAT Gold Zone**.
- **On-prem-to-Cloud-Data-Acquisition-Account-DR** — AWS Malaysia Region. Receives **S3 Cross-Region Replication** of the Prod Gold zone into an **S3 PRD Gold Zone (DR)** bucket, reachable via its own Transit Gateway.
- Connectivity from on-prem to AWS is via **AWS Direct Connect → Direct Connect Gateway → AWS Transit Gateway**, terminating in the per-account VPCs above.

## On-Prem Layout: Production vs. Non-Production Design Variants ⚠️

The architecture diagrams (`Data Aqusition.png` and, confirmed again in the newly-ingested `data acquisition.pptx`'s "Unstructured" and "Structured Batch Sources" slides) show **two different service breakdowns** for the on-prem side, which do not fully match:

- **Production** — an **Apache Airflow** box wraps a Red Hat OpenShift workload with four labelled functional blocks ("Common Integration service", "Orchestrate/Audit/Validate/Report/Meta Tag Config Mgmt", "Apply compression/tokenization (optional), Parquet format", "Trigger/Polling/Callback/Scheduler Integration") feeding a **Cloud Sync Service** of four services: **Integration Service, Control Service, Security Service, Orchestration Service**.
- **Non-production** — a separate box labelled **"Cloud Data Acquisition Service"** lists **five** different services: **Integration Service, Control Service, Compression Service, Trigger Service, KeyCloak Service** — no Security/Orchestration Service, and a KeyCloak (identity) service instead of MS Entra ID/CyberArk Conjur.

**Update per v1.1 (resolves half of this):** the Airflow half of this discrepancy is now resolved — v1.1 decision **D16** explicitly states Apache Airflow is *not* used; Temporal.io (D04) plus Control-M cover scheduling and orchestration (see [[concepts/temporal-io-workflow-orchestration]]). The diagrams simply have not been refreshed since that decision was made — this is **documentation staleness, not an open architecture question** (see [[deliverables/findings]]).

The **non-prod service-naming mismatch is still unresolved** — v1.1 does not describe a differently-composed non-prod variant, and its own six-component model (Gateway, Integration, Control, Security, Orchestration, Sync Push) does not name a "Compression Service", "Trigger Service", or "KeyCloak Service" anywhere. Still worth confirming with the design owner before using either diagram as a literal build spec for non-prod.

## Source Systems

On-prem enterprise data sources include **EDW Teradata** and **EBP Cloudera** (structured), plus unstructured sources: **WFI, SharePoint, Application DB, NFS, S3 (on-prem), Intellistore, and Ad-hoc** feeds. Shared Storage is organised per source system into a `cloud-sync-<src-system>-control-zone` and a `cloud-sync-<src-system>-zone`, both S3-compatible (also reachable via HDFS/NFS/SMB), with format "Any", compression optional, **metadata tag mandatory**, and classification optional at this staging layer.

## Related

- [[concepts/data-onboarding-orchestration-pipeline]] — Integration/Control/Security/Orchestration service design
- [[concepts/streaming-data-acquisition]] — Kafka-based streaming ingestion path
- [[concepts/s3-data-lake-zone-design]] — Gold/Bronze/Egress zone design
- [[concepts/kms-byok-key-management]] — encryption key management for the data lake
- [[concepts/temporal-io-workflow-orchestration]] — confirmed orchestration engine for Mode 1
- [[concepts/sync-push-service-architecture]] — the new Mode 2 service
- [[concepts/source-registry-and-audit-data-model]] — data model backing all modes
- [[concepts/dal-security-authentication-and-secrets]] — confirmed identity/secrets model
- [[entities/ai-platform-architecture]] — the broader AI Factory platform this service feeds
- [[synthesis/data-acquisition-architecture-overview]] — cross-cutting synthesis of the architecture and sequence flows
- [[reference/data-acquisition-service-lld]] — earlier (Mar 2026) source document summary
- [[reference/data-acquisition-platform-v1.1]] — current (Jul 2026) source document summary

## Sources

- External: Mar 11 _Data-Acquisition-Service-LLD-NarrativeV1.0[63].pdf
- External: Data Aqusition.png
- External: OCBC Data Acquisition Platform on AWS - v1.1.pdf
