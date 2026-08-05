---
title: Orchestration Service Mini — Code Assessment (Source Document)
category: reference
tags: [aws, ocbc, data-acquisition, orchestration, code-review, source-document]
relationships:
  - target: "[[reference/data-acquisition-cloud-sync-detailed-design]]"
    type: derived_from
  - target: "[[reference/cloud-sync-user-stories]]"
    type: derived_from
  - target: "[[concepts/orchestrator-state-machine-integrity]]"
    type: informs
  - target: "[[concepts/data-onboarding-orchestration-pipeline]]"
    type: related_to
  - target: "[[synthesis/orchestration-service-mini-assessment]]"
    type: informs
sources:
  - "External: OCBC Data Acquisition - Orchestration Service Code Assessment.md"
  - "Code: ocbc-data-acquisition/dod.md"
summary: Independent code review (assessed 2026-08-04) of an early orchestration-service-mini extract against the Cloud Sync Detailed Design v0.1, User Stories v0.5, and dod.md — found a demo-grade skeleton with the right task-queue shape but the durability/concurrency/lifecycle mechanisms largely absent (~7% of acceptance criteria directly asserted, 48.4% branch coverage against an 85% target).
provenance:
  extracted: 0.85
  inferred: 0.15
  ambiguous: 0.0
base_confidence: 0.68
lifecycle: draft
lifecycle_changed: 2026-08-04
tier: supporting
created: 2026-08-04
updated: 2026-08-04
---

# Orchestration Service Mini — Code Assessment (Source Document)

Reference index for an independent code assessment (dated 2026-08-04) of `orchestration-service-mini`
— a standalone two-module extract (`orchestration-service` + `shared-kernel`) implementing a first
tranche of the Orchestrator described in [[reference/data-acquisition-cloud-sync-detailed-design]].
The assessment was run against three references: the Detailed Design (DRAFT v0.1), the
[[reference/cloud-sync-user-stories]] (DRAFT v0.5), and the extract's own `dod.md`.

**This assessed an *earlier* build of the extract than the one now delivered.** A subsequent rebuild
addressed a large share of the findings below — see [[synthesis/orchestration-service-mini-assessment]]
for the reconciliation between what was found and what was fixed.

## Verdict (as assessed)

| Dimension | Result |
|---|---|
| Design principles (§2 of the Detailed Design) | 4 of 8 violated |
| Definition of Done (applicable items) | 5 pass, 7 fail, 4 not verifiable |
| Branch coverage (aggregated) | 48.4% against an 85% target |
| Acceptance criteria with a direct test assertion | ~11 of ~160 (≈7%) |
| Build and tests | Pass (65 tests, 0 failures) |

The assessed code got the *shape* right — decomposition boundary, six-task-type dispatch model, run
state enum matching the design's §6.1 exactly — but the mechanisms each design principle depends on to
actually hold (row locking, atomic state commits, idempotent admission, readiness polling, retry
classification, authentication) were largely not implemented. ^[extracted]

## What the assessed code got right

- Correct component boundary: the Orchestrator dispatches tasks and never touches source data itself.
- Six task types matching the design (`CHECK_READINESS` skipped for `NONE` readiness, `COMPRESS`
  skipped when compression is off, classify+promote fused into one task).
- `Run` state enum matches §6.1 exactly, and the intent to leave `checkpoint` untouched on failure so
  resume knows the last-good step was present in the design, even though the implementation broke it
  (see [[concepts/orchestrator-state-machine-integrity]]).
- Registry-driven config resolution checks active/approved/security-signoff status before admitting a
  run, matching CS-001/CS-055.
- Standardised terminology (`Run`, `RunTask`, `pipelineId`, `batchDate`, `SECURED`) respected throughout.

## Structural gaps found (design-principle level)

See [[concepts/orchestrator-state-machine-integrity]] for the detailed pattern this assessment
surfaces — three violations of the Detailed Design's "database is the state machine" principle and one
"single writer per table" violation, each traced to a specific, reproducible code defect rather than a
theoretical concern.

## Functional/requirement-level gaps found

Against the CS-xxx user stories, whole areas had zero test coverage and, in several cases, no
implementation at all: readiness *polling* (CS-021 — a task result payload was never read, so a
not-ready result silently advanced the run), retry backoff/classification (CS-016 — retries fired
immediately with no exponential backoff and no transient/permanent distinction), business-date
resolution (CS-060–CS-062 — `batch_date` was an unvalidated string), the per-environment transfer-slot
ceiling (CS-029 — only a per-pipeline ceiling existed), authentication and operator entitlement
(CS-037/CS-038 — every endpoint, including the transfer-complete callback, was open), and hold-through-
cloud-outage semantics (CS-028 — no hold state, no bounded backoff). ^[extracted]

Two tests were found to actively **encode incorrect behaviour rather than catch it**: one asserted
`429` for a duplicate run where CS-015/CS-020 require `409`, and another asserted cancel reusing
`FAILED` where CS-058 requires a distinct terminal state — both locked in by a passing test rather than
flagged as failing.

## Definition of Done status (as assessed)

Per the extract's own `dod.md`, the assessed build passed only "no build failures" and "all unit tests
passed" outright; branch coverage, integration tests, Spotless/Checkstyle/PMD, CI/CD availability, and
security scanning were all failing or entirely unconfigured at assessment time. See
[[synthesis/orchestration-service-mini-assessment]] for the current DoD status after the rebuild.

## Recommended order of work (as given by the assessment)

1. Fix the state-corrupting defects (checkpoint/status coupling, row locking, lost updates, cancel
   leaving claimable tasks).
2. Make admission genuinely idempotent and reorder checks so duplicates return `409` before the
   concurrency ceiling can return `429`.
3. Implement readiness polling by actually reading the task result payload.
4. Add exponential backoff with jitter and transient/permanent error classification.
5. Add the DoD tooling (JaCoCo with a working `argLine`, Spotless, Checkstyle, PMD, Testcontainers,
   a CI pipeline).
6. Add tests for the recovery/lifecycle paths and a genuine concurrency test.
7. Fix the two tests encoding wrong behaviour.
8. Move `readiness-mode`/`max_concurrent_runs` into the registry; add the transfer-slot ceiling and
   business-date resolution.
9. Align the API surface (paths, error envelope, status codes) with the Detailed Design §8.
10. Remove or wire up dead code.
11. Reconcile the design document — raise deviations for discussion, close open items.

## Related

- [[reference/data-acquisition-cloud-sync-detailed-design]]
- [[reference/cloud-sync-user-stories]]
- [[concepts/orchestrator-state-machine-integrity]]
- [[concepts/data-onboarding-orchestration-pipeline]]
- [[synthesis/orchestration-service-mini-assessment]]

## Sources

- External: OCBC Data Acquisition - Orchestration Service Code Assessment.md
- Code: ocbc-data-acquisition/dod.md
