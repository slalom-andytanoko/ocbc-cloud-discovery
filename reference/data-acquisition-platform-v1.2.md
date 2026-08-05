---
title: OCBC Data Acquisition Platform on AWS — v1.2 (Source Document)
category: reference
tags: [aws, data-platform, ocbc, data-acquisition, source-document]
relationships:
  - target: "[[reference/data-acquisition-platform-v1.1]]"
    type: supersedes
  - target: "[[entities/cloud-data-acquisition-service]]"
    type: extends
  - target: "[[synthesis/data-acquisition-open-decisions]]"
    type: informs
sources: ["External: OCBC Data Acquisition Platform on AWS - v1.2.md"]
summary: AWS-authored DRAFT v1.2 (28 Jul 2026) of the DAL design, updating v1.1 with workflow-engine removal, explicit operations surface, corrected on-prem-to-AWS push authentication path, and clarified replay/idempotency semantics.
provenance:
  extracted: 0.9
  inferred: 0.1
  ambiguous: 0.0
base_confidence: 0.75
lifecycle: draft
lifecycle_changed: 2026-07-29
tier: core
created: 2026-07-29
updated: 2026-07-29
---

# OCBC Data Acquisition Platform on AWS — v1.2 (Source Document)

Reference index for the external source "OCBC Data Acquisition Platform on AWS", DRAFT v1.2, dated 2026-07-28.

This page captures the major deltas from v1.1 so downstream concept/synthesis pages can align without reproducing proprietary source text.

## What Changed in v1.2 (Distilled)

1. Temporal.io is removed. Durable execution is now implemented as an orchestration run driver inside the Orchestration Service, backed by DAL PostgreSQL, while keeping an engine-agnostic seam for future adoption.
2. Operations ownership is made explicit via a dedicated operations surface: run query, resume, replay, cancel, and quarantine inspection.
3. The on-prem-to-AWS sync-push write path is corrected with actor-specific authentication handling, endpoint clarifications, and per-request scoping.
4. On-demand mode can now return relational-extract outputs (Parquet when the source is relational), rather than limiting this to scheduled mode.
5. Compression is treated as a shared cross-mode capability, not a scheduled-only step.
6. `BATCH_CONTROL` readiness polling is withdrawn. Scheduled readiness defaults to upstream Control-M dependency or file arrival signal.
7. Replay writes to a new destination with a pointer object (`_current.json`) updated last, preserving immutable historical outputs.
8. On-demand idempotency is caller-scoped (`UNIQUE (caller_identity, idempotency_key)`) to avoid cross-caller collisions.

## Net Impact on Existing Knowledge Base

- [[concepts/temporal-io-workflow-orchestration]] needs to be treated as historical context, with v1.2 execution model superseding the prior Temporal choice.
- [[concepts/data-onboarding-orchestration-pipeline]] should use Control-M/file-arrival readiness, not `BATCH_CONTROL` polling.
- [[concepts/source-registry-and-audit-data-model]] should align idempotency uniqueness semantics with caller scoping.
- [[concepts/sync-push-service-architecture]] should reflect the corrected authentication/write-path semantics.
- [[synthesis/data-acquisition-open-decisions]] should treat D04/D05/D25 updates as the current decision baseline.

## Related

- [[reference/data-acquisition-platform-v1.1]]
- [[entities/cloud-data-acquisition-service]]
- [[synthesis/data-acquisition-architecture-overview]]
- [[synthesis/data-acquisition-open-decisions]]

## Sources

- External: OCBC Data Acquisition Platform on AWS - v1.2.md