---
title: Orchestration Service / Worker — Code Review (2026-08-07, Source Document)
category: reference
tags: [aws, ocbc, data-acquisition, orchestration, worker, code-review, source-document]
relationships:
  - target: "[[reference/data-acquisition-cloud-sync-detailed-design]]"
    type: derived_from
  - target: "[[reference/cloud-sync-user-stories]]"
    type: derived_from
  - target: "[[concepts/orchestrator-state-machine-integrity]]"
    type: informs
  - target: "[[synthesis/orchestration-service-mini-assessment]]"
    type: informs
  - target: "[[reference/orchestration-service-code-review-20260806]]"
    type: related_to
sources:
  - "External: code-review-findings-20260807-1.md"
summary: Fourth-generation AI-reviewer (Kiro) code review of ocbc-cloud-sync (2026-08-07), run against User Stories v0.9 and the Cloud Sync Detailed Design/dod.md/steering baseline, focused on the newly-implemented connector stories CS-006/007/008. Confirms all 9 findings from the 2026-08-06 review are resolved, then raises 7 Required + 1 nit + 2 optional new findings — most of them accepted tranche-scope deferrals (S3 source read, Parquet landing, business-date resolution, SLA_BREACH-status-vs-flag, API-key-vs-Entra-ID) rather than defects, with a small set of genuine code fixes (permission-denied error classification, callback transfer metrics, rate-limit map eviction, two missing @DisplayName, a stale UC-x comment). All actionable items were fixed same-day and the review's lessons were codified into a new steering register, ocbc-cloud-sync/steering/design-decisions-and-guardrails.md.
provenance:
  extracted: 0.85
  inferred: 0.15
  ambiguous: 0.0
base_confidence: 0.7
lifecycle: draft
lifecycle_changed: 2026-08-07
tier: supporting
created: 2026-08-07
updated: 2026-08-07
---

# Orchestration Service / Worker — Code Review (2026-08-07, Source Document)

Reference index for a fourth-generation AI-reviewer (Kiro) code review of `ocbc-cloud-sync`, dated
2026-08-07 — the follow-up to the 2026-08-06 review distilled in
[[reference/orchestration-service-code-review-20260806]] ([[deliverables/findings]] #14). Reviewed
against User Stories v0.9, the Cloud Sync Detailed Design, `dod.md`, and the repo's own code-review
steering doc, with the new scope being the freshly-implemented connector stories CS-006 (file
source), CS-007 (object storage), and CS-008 (Parquet landing).

## Resolution of the 2026-08-06 findings

All 9 findings from the prior review are confirmed resolved in code: per-pipeline SLA override with a
config-gap WARN fallback; the CS-040 resume staged-data gap documented as a known limitation; the
CS-041 concurrent-replay guard; the CS-038 per-caller rate limiter; the `SLA_SCHEDULED` audit event;
`@DisplayName`/CS-xxx traceability across all tests; the single-query cancel stand-down; SLA-breach
persistence on the `IGNORED` callback path; and a fresh SLA deadline scheduled on replay.

## New findings (Required)

| # | Finding | Fix direction | Disposition |
|---|---|---|---|
| 1 | CS-027 — SLA breach is implemented as a boolean flag (`Run.slaBreached`) overlaid on the run's status, not as the distinct `SLA_BREACH` terminal status the Detailed Design §6.1/§8.2 state machine shows. | Confirm with the design owner whether `SLA_BREACH` should be a separate status or remain a flag; if the flag stays, update §6.1 to match. | Accepted deviation (design-owner decision) |
| 2 | CS-006 — a permission/lock denial (`AccessDeniedException`) on the source read falls through to the generic `EXTRACT_FAILED`/`TRANSIENT` handler instead of being classified `PERMANENT` and naming the file. | Catch the wrapped `AccessDeniedException` and map to `SOURCE_FILE_ACCESS_DENIED`/`PERMANENT`; add a test for an unreadable file. | **Fixed** |
| 3 | CS-007 — no S3 source connector (read side), no ETag/version pre-read check, and no `AbortMultipartUpload` (write side, single-part PUT only). | Document as known limitations; implement when an S3 source connector / multipart upload is added. | Accepted deviation (future tranche) |
| 4 | CS-008 — Parquet landing is not implemented; depends on CS-004 (the JDBC/Oracle source connector), which is not in the implemented set. | Document as a planned future-tranche item. | Accepted deviation (future tranche) |
| 5 | CS-020 — the `POST /runs` 202 response omits `batch_date_resolved`; business-date resolution (Epic G: CS-060/061/062) is not implemented, so there is no resolved date to report. | Document as a future-tranche item; add `batchDateResolved` to `RunResponse` when Epic G lands. | Accepted deviation (future tranche) |
| 6 | Two tests in `WorkerExtractFlowIT` lack `@DisplayName` (steering §10). | Add `@DisplayName` with the CS-006 / DD-06 IDs. | **Fixed** |
| 7 | CS-026 — the transfer-complete callback does not capture `bytes_transferred`/`files_transferred`/`datasync_execution_arn` that the Detailed Design §8.2 callback body specifies. | Add the (nullable) fields to `TransferCompleteRequest` and persist them on the `run` row. | **Fixed** |

## New findings (Nit / Optional)

- **Nit:** `ApiKeyAuthFilter`'s per-key rate-limit `ConcurrentHashMap` grows without eviction; stale
  entries from rotated keys accumulate for the process lifetime. **Fixed** (stale-window eviction).
- **Optional / Consider:** `OrchestrationFlowIT`'s class Javadoc still references the deprecated
  `UC-1`/`UC-3` numbering rather than the canonical `CS-xxx`. **Fixed** (reworded to CS-021/CS-022).
- **Optional / Consider:** the `X-Internal-Api-Key` guardrail remains a stand-in for the full Spring
  Cloud Gateway + Entra ID token validation of the production architecture. No action for this
  tranche; documented. Accepted deviation.

## Resolution status

All five actionable code findings (#2, #6, #7, #8, #9) were fixed same-day and verified via a full
reactor `mvn verify` (unit + Testcontainers integration tests, JaCoCo ≥85%, Spotless/Checkstyle/PMD
green). The five accepted deviations (#1, #3, #4, #5, #10) were recorded as known limitations in the
repo README and `steering/design.md`. All ten findings, plus the prior three reviews, were then
codified into a new steering register, `ocbc-cloud-sync/steering/design-decisions-and-guardrails.md`,
which pairs each finding with the concrete guardrail (a named test, schema rule, or lint gate) that
makes recurrence catchable, and marks the accepted deviations "do not re-flag".

## Verdict (as assessed)

The core Orchestrator lifecycle, the Worker claim-execute-settle pattern, and the domain model were
assessed as correctly implementing the Detailed Design. Findings #3/#4/#5 are "not yet implemented"
for accepted tranche-scoping reasons, not bugs; #1 is a documented divergence pending a design-owner
decision; the remainder were addressable in-tranche and were addressed. No new security or DoD-gate
concerns were raised.

## Related

- [[deliverables/findings]] #15
- [[reference/orchestration-service-code-review-20260806]]
- [[synthesis/orchestration-service-mini-assessment]]
- [[concepts/orchestrator-state-machine-integrity]]

## Sources

- External: code-review-findings-20260807-1.md
