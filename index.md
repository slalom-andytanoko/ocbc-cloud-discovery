---
title: Wiki Index
category: meta
tags: [index, navigation]
updated: 2026-08-07
---

# Wiki Index

## Concepts

- [[concepts/data-onboarding-orchestration-pipeline]] — run state machine and UC-1 sequence walkthrough; v1.3 adds the Scheduler Job Adapter, Control-M-driven readiness for file/object sources, and (2026-08-03) post-landing decompression; service-boundary model superseded by the Detailed Design v0.1
- [[concepts/data-tokenization-and-encryption]] — tokenization techniques and on-prem/AWS key sync
- [[concepts/streaming-data-acquisition]] — Confluent Kafka Cluster Linking / PrivateLink streaming path
- [[concepts/s3-data-lake-zone-design]] — Gold/Bronze/Egress S3 zone design
- [[concepts/kms-byok-key-management]] — BYOK KMS key creation, rotation, IAM model; superseded (v1.4, D27) by one CMK per AWS account rather than per source
- [[concepts/temporal-io-workflow-orchestration]] — historical v1.1 decision context (superseded by v1.2)
- [[concepts/sync-push-service-architecture]] — the dedicated, stateless Sync Push Service for Mode 2 (D24); v1.5 confirms no compression, disambiguates source_ref/source_path, and writes its manifest last
- [[concepts/source-registry-and-audit-data-model]] — Source Registry, Orchestration Audit table (now with run-driver scheduling columns, pipeline_mode discriminator, source_path/extended dedup), manifest contract; file/object readiness moved off polling in v1.3, caller-supplied-path mode added in v1.4
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
- [[reference/data-acquisition-platform-v1.3]] — source document index for the Jul 2026 design update (schema/ownership validators deferred, Control-M-driven readiness); superseded by v1.5
- [[reference/data-acquisition-platform-v1.5]] — source document index for the latest (5 Aug 2026) design update: BYOK one-CMK-per-account (D27), Diamond Zone buckets (A18), caller-supplied-path mode, and the gap-analysis reconciliation of the pull/push parameter handoff
- [[reference/cloud-sync-user-stories]] — source document index for the Cloud Sync requirements baseline (latest ingest v0.8: caller-supplied-path CS-065–067, object key layout CS-068, allowlisted system IDs CS-069, CS-025 source_id)
- [[reference/data-acquisition-cloud-sync-detailed-design]] — source document index for the Cloud Sync microservice decomposition (v0.1), closing D03; updated 2026-08-05 with the gap-analysis reconciliation (DECOMPRESSING state, two-phase callback, task result contract)
- [[reference/uc1-scheduled-db-poll-narrative]] — source document index for the detailed UC-1 walkthrough
- [[reference/orchestration-service-mini-code-assessment]] — source document index for the independent code assessment of an orchestration-service-mini extract, plus its dod.md
- [[reference/orchestration-service-code-review-20260806]] — source document index for the 2026-08-06 follow-up AI-reviewer code review of `ocbc-cloud-sync` (confirms 2026-08-05 findings resolved; 6 new Required + 3 nit/optional findings, all fixed same-day)
- [[reference/orchestration-service-code-review-20260807]] — source document index for the 2026-08-07 connector-story (CS-006/007/008) code review of `ocbc-cloud-sync` (confirms 2026-08-06 findings resolved; 7 Required + 1 nit + 2 optional, mostly accepted tranche-scope deferrals plus a few code fixes; all findings codified into a steering design-decisions/guardrails register)
- [[reference/delivery-tranches-roadmap]] — authoritative six-tranche delivery-sequencing plan (Tranche 1 Orchestrator-only simulated = done; Tranche 2 Worker walking skeleton → S3 = next; 3–6 harden, add connectors/decompression, add push path, add real scheduler/gateway/ops), with the CS-xxx-per-tranche mapping

## Deliverables
