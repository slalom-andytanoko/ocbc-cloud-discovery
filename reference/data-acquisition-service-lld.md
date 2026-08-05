---
title: Cloud Data Acquisition Service — LLD (Source Document)
category: reference
tags: [aws, data-platform, ocbc, data-acquisition, source-document]
relationships:
  - target: "[[entities/cloud-data-acquisition-service]]"
    type: related_to
sources: ["External: Mar 11 _Data-Acquisition-Service-LLD-NarrativeV1.0[63].pdf", "External: data acquisition[68]  -  Read-Only.pptx"]
summary: OCBC's "Cloud Data Acquisition Service — Low Level Design" (v1.0, Liang Chen, 11 Mar 2026, 37 pages) plus the companion architecture slide deck — reference index into the distilled wiki pages.
provenance:
  extracted: 0.9
  inferred: 0.1
  ambiguous: 0.0
base_confidence: 0.59
lifecycle: draft
lifecycle_changed: 2026-07-27
tier: core
created: 2026-07-27
updated: 2026-07-27
---

# Cloud Data Acquisition Service — LLD (Source Document)

> **Superseded, 24 Jul 2026:** a later, more detailed document — "OCBC Data Acquisition Platform on AWS", DRAFT v1.1 — has since been ingested (see [[reference/data-acquisition-platform-v1.1]]). Where the two disagree (e.g. orchestration engine: this document's Airflow-DAG design vs. v1.1's confirmed Temporal.io + Control-M, D04/D16), v1.1 is authoritative. This page is kept for historical reference and because most of its content (four core services, tokenization/encryption approach, BYOK/KMS design, S3 zone design) still holds.

Reference index for OCBC's "Cloud Data Acquisition Service — Low Level Design" (Version 1.0, authored by Liang Chen, dated 11 Mar 2026, 37 pages), and the companion slide deck "data acquisition[68] - Read-Only.pptx" (workstream: Data Acquisition, OCBC + AWS).

Both files are held under `external/.processed/` (proprietary, gitignored) — this page and its linked concept/entity/synthesis pages contain only distilled, paraphrased content per the [[external]] handling rules. No verbatim excerpts are reproduced here.

## Document Contents (as ingested)

1. Executive summary and architecture overview
2. Structured & Unstructured Data Architecture — on-prem Cloud Sync Service (Integration/Control/Security/Orchestration), Secure Data Transmission Service (DataSync over Direct Connect)
3. Streaming Data Acquisition — Confluent Kafka, Cluster/Schema Linking, PrivateLink
4. AWS Architecture — S3 zone design, sensitive data detection
5. OCBC BYOK Architecture and process
6. OCBC internal alignment matrix (11 open decisions)

The slide deck contains four diagram-only slides: "Overall AI Platform Architecture," two "Data Acquisition - Unstructured" slides, and "Data Acquisition - Streaming" — these correspond to the standalone image files ingested alongside it (`Overall AI Platform Arch.png`, `Data Aqusition.png`) and the two UC-1 sequence diagrams (`image001.png`, `image002.png`).

## Distilled Into

- [[entities/cloud-data-acquisition-service]] — the on-prem/AWS landing system itself
- [[entities/ai-platform-architecture]] — the downstream AI Factory platform
- [[concepts/data-onboarding-orchestration-pipeline]] — service breakdown, validation gate, Airflow trigger modes, UC-1 sequence walkthrough
- [[concepts/data-tokenization-and-encryption]] — tokenization techniques and key sync
- [[concepts/streaming-data-acquisition]] — Kafka streaming path
- [[concepts/s3-data-lake-zone-design]] — Gold/Bronze/Egress zone design
- [[concepts/kms-byok-key-management]] — BYOK creation, rotation, IAM model
- [[synthesis/data-acquisition-architecture-overview]] — cross-cutting synthesis of all six source files
- [[synthesis/data-acquisition-open-decisions]] — the alignment matrix of 11 open decisions

## Sources

- External: Mar 11 _Data-Acquisition-Service-LLD-NarrativeV1.0[63].pdf
- External: data acquisition[68]  -  Read-Only.pptx
