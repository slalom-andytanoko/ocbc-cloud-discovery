---
title: Orchestration Service Mini — Assessment vs. Rebuild Synthesis
category: synthesis
tags: [aws, ocbc, data-acquisition, orchestration, code-review, dod]
relationships:
  - target: "[[reference/orchestration-service-mini-code-assessment]]"
    type: derived_from
  - target: "[[concepts/orchestrator-state-machine-integrity]]"
    type: related_to
  - target: "[[reference/data-acquisition-cloud-sync-detailed-design]]"
    type: related_to
  - target: "[[reference/cloud-sync-user-stories]]"
    type: related_to
sources:
  - "External: OCBC Data Acquisition - Orchestration Service Code Assessment.md"
  - "Code: ocbc-data-acquisition/dod.md"
  - "Code: ocbc-data-acquisition/README.md"
summary: A full rebuild of orchestration-service-mini closed most of the assessment's DoD/tooling gaps and several correctness defects (admission ordering, cancel terminal state, auth guardrail), but deliberately left the deeper state-machine-integrity and requirement-coverage gaps (readiness polling, retry backoff, business-date resolution, row locking) out of scope for this tranche.
provenance:
  extracted: 0.5
  inferred: 0.5
  ambiguous: 0.0
base_confidence: 0.55
lifecycle: draft
lifecycle_changed: 2026-08-04
tier: supporting
created: 2026-08-04
updated: 2026-08-04
---

# Orchestration Service Mini — Assessment vs. Rebuild Synthesis

[[reference/orchestration-service-mini-code-assessment]] reviewed an early build of
`orchestration-service-mini` and found a demo-grade skeleton: right shape, missing mechanisms. A
subsequent full rebuild of the same two modules (`shared-kernel` + `orchestration-service`) — scoped to
five specific use cases plus one authentication guardrail, selected as the smallest coherent slice that
exercises the full `Run` lifecycle — closed a meaningful share of what the assessment flagged, but not
all of it. This page reconciles the two so neither is read in isolation.

## What the rebuild closed

| Assessment finding | Rebuild outcome |
|---|---|
| Duplicate admission returns `429` instead of `409` (Note 3, §5.8) | **Fixed** — duplicate-run rejection now runs ahead of the concurrency ceiling check, so a genuine duplicate always returns `409`. |
| Cancel reuses `FAILED` instead of a distinct terminal state (§5.5, CS-058) | **Fixed** — cancel now moves to a dedicated `CANCELLED` status, distinct from `FAILED`, and stands down any outstanding dispatched task. |
| Every endpoint open, including the transfer-complete callback (CS-037/CS-038) | **Fixed** — a shared-secret API-key guardrail (constant-time compared) is now required on every state-mutating endpoint. Explicitly a stand-in for full mTLS/Entra ID, not a replacement. |
| No JaCoCo/Spotless/Checkstyle/PMD, no CI (DoD tooling) | **Fixed** — all four gates are build-breaking on `mvn verify`; a GitHub Actions CI pipeline runs the same gates. |
| No Testcontainers/Failsafe split, tests only against H2 (§7.3) | **Fixed** — 8 integration tests now run against real Testcontainers Postgres. |
| Branch coverage 48.4% aggregated, 44.6% for `orchestration-service`, against an 85% target | **Fixed** — both modules now enforce ≥85% branch coverage as a build gate. |
| Two tests encoding wrong behaviour as correct (§8, rows 3 and 6) | **Fixed** — both corrected; the 409-before-429 ordering and the distinct-cancelled-state behaviour are now what the tests assert. |

## What remains open (deliberately out of scope for this tranche)

The rebuild's own README documents these as known limitations rather than omitting them silently:

- **Readiness polling (CS-021)** is still a one-shot check against a demo signal table, not a real
  polling loop with a timeout and re-dispatch — the assessment's "breaks every relational pipeline"
  concern still applies to any pipeline needing genuine DB-poll readiness.
- **Retry backoff/classification (CS-016)** is unchanged: all non-`VALIDATE` failures retry
  immediately with no exponential backoff and no transient/permanent distinction.
- **Business-date resolution (CS-060–CS-062)** is unchanged: `batchDate` is taken verbatim from the
  admission request.
- **Row locking / multi-replica dispatch safety** (see [[concepts/orchestrator-state-machine-integrity]]
  failure mode 3) was not independently re-verified as part of the rebuild's stated scope — the five
  use cases it targets do not include a concurrency/multi-replica test.
- **Per-environment transfer-slot ceiling (CS-029)** — the rebuild does implement a global
  transfer-slot ceiling (one of its five selected use cases), which is a partial answer to this gap,
  but registry-driven configuration of that ceiling (vs. an application property) is still open.
- **Task execution is simulated**, not real — there is still no actual extract/validate/compress/
  classify/promote logic or landed-manifest verification.

## Reading the two documents together

Treat [[reference/orchestration-service-mini-code-assessment]] as a description of risk *patterns* an
Orchestrator implementation can fall into (documented generically in
[[concepts/orchestrator-state-machine-integrity]]), not as a live defect list against the current code
— several of its most serious findings (checkpoint/status coupling, the un-acknowledged-completion
re-advance loop) were specifically about the `RunProgressionService`/`transitionTo` design that the
rebuild replaced. Before treating any specific assessment finding as still-open, check whether it falls
under "what the rebuild closed" above; if it's in "what remains open", it is a genuine, currently-true
gap.

## Related

- [[reference/orchestration-service-mini-code-assessment]]
- [[concepts/orchestrator-state-machine-integrity]]
- [[reference/data-acquisition-cloud-sync-detailed-design]]
- [[reference/cloud-sync-user-stories]]

## Sources

- External: OCBC Data Acquisition - Orchestration Service Code Assessment.md
- Code: ocbc-data-acquisition/dod.md
- Code: ocbc-data-acquisition/README.md
