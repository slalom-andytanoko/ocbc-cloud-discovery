---
title: Wiki Index
category: meta
tags: [index, navigation]
updated: 2026-08-04
---

# Wiki Index

## Concepts

- [[concepts/data-onboarding-orchestration-pipeline]] — run state machine and UC-1 sequence walkthrough; v1.3 adds the Scheduler Job Adapter, Control-M-driven readiness for file/object sources, and (2026-08-03) post-landing decompression; service-boundary model superseded by the Detailed Design v0.1
- [[concepts/data-tokenization-and-encryption]] — tokenization techniques and on-prem/AWS key sync
- [[concepts/streaming-data-acquisition]] — Confluent Kafka Cluster Linking / PrivateLink streaming path
- [[concepts/s3-data-lake-zone-design]] — Gold/Bronze/Egress S3 zone design
- [[concepts/kms-byok-key-management]] — BYOK KMS key creation, rotation, IAM model
- [[concepts/temporal-io-workflow-orchestration]] — historical v1.1 decision context (superseded by v1.2)
- [[concepts/sync-push-service-architecture]] — the dedicated, stateless Sync Push Service for Mode 2 (D24)
- [[concepts/source-registry-and-audit-data-model]] — Source Registry, Orchestration Audit table (now with run-driver scheduling columns), manifest contract; file/object readiness moved off polling in v1.3
- [[concepts/dal-security-authentication-and-secrets]] — MS Entra ID (D14), CyberArk Vault via Conjur (D22), encryption scope (D18)
- [[concepts/orchestrator-state-machine-integrity]] — checkpoint/status coupling, un-acknowledged completions, row locking, and admission-idempotency failure patterns surfaced by a real Orchestrator code assessment

## Entities

- [[entities/cloud-data-acquisition-service]] — OCBC's on-prem/AWS data onboarding service (DAL)
- [[entities/ai-platform-architecture]] — OCBC's AWS AI Factory platform

## Synthesis

- [[synthesis/data-acquisition-architecture-overview]] — cross-cutting synthesis of the data acquisition + AI platform architecture
- [[synthesis/data-acquisition-open-decisions]] — alignment matrix (11 items) plus the current D01–D24 decision register, and the DD-01–DD-15 Detailed Design register closing D03
- [[synthesis/orchestration-service-mini-assessment]] — reconciles the orchestration-service-mini code assessment's findings against what a subsequent rebuild fixed vs. left open

## Reference

- [[reference/data-acquisition-service-lld]] — source document index for the earlier (Mar 2026) Cloud Data Acquisition Service LLD — superseded by v1.1
- [[reference/data-acquisition-platform-v1.1]] — source document index for the current (Jul 2026) design
- [[reference/data-acquisition-platform-v1.2]] — source document index for the Jul 2026 design update
- [[reference/data-acquisition-platform-v1.3]] — source document index for the latest (Jul 2026, refined 2026-08-03) design update
- [[reference/cloud-sync-user-stories]] — source document index for the Cloud Sync requirements baseline (latest ingest v0.5, 2026-08-03 refinement adds Epic H)
- [[reference/data-acquisition-cloud-sync-detailed-design]] — source document index for the Cloud Sync microservice decomposition (v0.1), closing D03
- [[reference/uc1-scheduled-db-poll-narrative]] — source document index for the detailed UC-1 walkthrough
- [[reference/orchestration-service-mini-code-assessment]] — source document index for the independent code assessment of an orchestration-service-mini extract, plus its dod.md

## Deliverables
