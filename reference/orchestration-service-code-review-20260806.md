---
title: Orchestration Service / Worker — Code Review (2026-08-06, Source Document)
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
  - target: "[[reference/orchestration-service-mini-code-assessment]]"
    type: related_to
sources:
  - "External: code-review-findings-20260806-1.md"
summary: Third-generation AI-reviewer (Kiro) code review of ocbc-cloud-sync (2026-08-06), run against User Stories v0.9 and the same Detailed Design/dod.md/steering-doc baseline as the 2026-08-05 review. Confirms all 10 findings from that prior review are resolved, then raises 6 Required + 1 nit + 2 optional new findings, concentrated in SLA-deadline edge cases, replay/resume guard gaps, missing rate limiting, and test-traceability (`@DisplayName`/CS-xxx) hygiene.
provenance:
  extracted: 0.85
  inferred: 0.15
  ambiguous: 0.0
base_confidence: 0.7
lifecycle: draft
lifecycle_changed: 2026-08-06
tier: supporting
created: 2026-08-06
updated: 2026-08-06
---

# Orchestration Service / Worker — Code Review (2026-08-06, Source Document)

Reference index for a third-generation AI-reviewer (Kiro) code review of `ocbc-cloud-sync`, dated
2026-08-06 — a follow-up to the review distilled in `deliverables/findings.md` #13
(2026-08-05). Reviewed against User Stories v0.9, the Cloud Sync Detailed Design (v0.1), `dod.md`,
and the repo's own code-review steering doc, scoped to the same CS-xxx story set as the prior review.

## Resolution of the 2026-08-05 findings

All 10 items from the prior review are confirmed resolved in code: callback idempotency, `trace_id`,
SLA-breach dead code, the cancel-in-flight guard, the stale-task threshold, `202` admission response,
the exception-path test matrix, the `DECOMPRESSING` state, the duplicate-dispatch guard, and `trace_id`
propagation into `RunEvent`.

## New findings (Required)

| # | Finding | Fix direction |
|---|---|---|
| 1 | SLA breach detection applies a single environment-wide default deadline; CS-027's exception path ("no SLA deadline configured → report as a configuration gap, don't raise a breach") has no per-pipeline field and no code path to satisfy it. | Add an optional per-pipeline SLA override; fall back to the environment default with a WARN naming the pipeline. |
| 2 | Resume (CS-040) does not check whether the staged batch still exists before allowing a resume — the acceptance criterion ("removed by retention policy → refused, direct to replay") has no implementation, though staged data is out of scope for this tranche's demo executor. | Document as a known limitation pending a real staging zone/connector. |
| 3 | Replay (CS-041) only checks that the *original* run is terminal — it does not guard against a second replay while an earlier replay for the same `pipeline_id`+`batch_date` is still active, allowing two concurrent in-flight runs for the same batch. | Add an active-run existence check for the same pipeline+batch-date before allowing a replay. |
| 4 | No per-caller rate limiting (CS-038) — the API-key guardrail authenticates callers but does not throttle them; a single caller can send unlimited request volume. | Add a simple per-key rate limiter, or explicitly document as an API-gateway-tier concern out of scope for this tranche. |
| 5 | The SLA deadline scheduled at admission is not recorded as its own audit event — steering-doc §4 expects every state change to have a corresponding `RunEvent`. | Add a dedicated `SLA_SCHEDULED` event type, recorded at admission. |
| 6 | All unit tests (21 files) are missing `@DisplayName`; existing integration-test `@DisplayName`s reference `UC-x` use-case IDs rather than the canonical `CS-xxx` user-story IDs the steering doc requires for traceability. | Add `@DisplayName` to every test method; standardise on `CS-xxx` references (multiple IDs where a test covers more than one story). |

## New findings (Nit / Optional)

- **Nit:** `RunCancelService` issues two separate lookup queries (`PENDING`, then `CLAIMED`) where a
  single `status IN (...)` query would do.
- **Optional:** `RunTransferCompletionService`'s `IGNORED` callback path can silently drop a
  newly-detected SLA breach flag because the run is never persisted on that path.
- **Optional:** `RunReplayService` does not schedule a fresh SLA deadline on the replay run, so a
  replayed run is invisible to SLA-breach monitoring for its entire lifecycle.

## Verdict (as assessed)

Architecture and design quality assessed as strong: aggregate-root enforcement (`Run.advanceCheckpoint`/
`fail`/`cancel` as the only mutation paths), clean state-machine separation, correct admission-ceiling
vs. transfer-slot-ceiling split, consistent audit recording via `RunEventRecorder`, DB-level partial
unique index backing the application-level duplicate check, and Testcontainers singleton-pattern usage
avoiding the stale-DataSource problem. No new security or DoD-gate concerns raised.

## Related

- [[deliverables/findings]] #14
- [[synthesis/orchestration-service-mini-assessment]]
- [[concepts/orchestrator-state-machine-integrity]]
- [[reference/orchestration-service-mini-code-assessment]]

## Sources

- External: code-review-findings-20260806-1.md
