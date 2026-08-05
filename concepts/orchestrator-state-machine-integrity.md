---
title: Orchestrator State-Machine Integrity Patterns
category: concepts
tags: [aws, orchestration, ocbc, data-acquisition, state-machine, concurrency]
relationships:
  - target: "[[reference/data-acquisition-cloud-sync-detailed-design]]"
    type: extends
  - target: "[[reference/orchestration-service-mini-code-assessment]]"
    type: derived_from
  - target: "[[concepts/data-onboarding-orchestration-pipeline]]"
    type: related_to
  - target: "[[concepts/source-registry-and-audit-data-model]]"
    type: related_to
sources:
  - "External: OCBC Data Acquisition - Orchestration Service Code Assessment.md"
summary: The Detailed Design's "database is the state machine" and "single writer per table" principles have concrete, checkable failure modes — checkpoint/status coupling, un-acknowledged completions, missing row locking, and non-idempotent admission — surfaced by a real code assessment of the Orchestrator extract.
provenance:
  extracted: 0.6
  inferred: 0.4
  ambiguous: 0.0
base_confidence: 0.6
lifecycle: draft
lifecycle_changed: 2026-08-04
tier: supporting
created: 2026-08-04
updated: 2026-08-04
---

# Orchestrator State-Machine Integrity Patterns

[[reference/data-acquisition-cloud-sync-detailed-design]] states two of its eight design principles as
mandatory: **"database is the state machine"** (every status change is a committed row update) and
**"single writer per table"** (exactly one service writes each table). Both sound like they hold
automatically once the schema matches the design's tables. [[reference/orchestration-service-mini-code-assessment]]
found, by running the code rather than reading it, that they don't — and that the failure modes are
specific and recurring enough to name as a pattern any Orchestrator implementation (this extract or a
future full build) should check for explicitly.

## Failure mode 1: checkpoint moves in lockstep with status

If a `checkpoint`/`last-good-step` field is updated by the *same* generic transition method used for
forward progress, a transitional status (e.g. `EVENT_PUBLISHED` on the way to `TRANSFERRING`) can be
skipped entirely when two transitions happen in one transaction — Hibernate (or an equivalent ORM)
emits a single UPDATE carrying only the final in-memory value, so the intermediate committed row state
never existed. Worse, `checkpoint` then reflects a state that has **no mapping in the resume logic**,
so a failure at that exact point cannot be resumed (`resume` throws/500s instead of restarting at the
right step). ^[extracted]

**The fix pattern:** give the failure-recording path (and any transition that must survive independent
of the "current" status) its own method that does *not* route through the same generic
`transitionTo(newStatus)` helper used for happy-path progress — see also the equivalent Java-specific
note in the engagement's own gotcha log (checkpoint-overwrite issue, `Run.fail()` deliberately leaving
checkpoint untouched). ^[inferred]

## Failure mode 2: completion is derived at read time, not committed

If "has this task's completion been processed" is re-derived on every scan tick from the *latest* task
row rather than from an explicit `acknowledged` column (or equivalent committed marker), a settled task
that the orchestrator has already advanced past will be reprocessed indefinitely — every scan tick
re-observes "task X is COMPLETED" and re-fires the same advance logic, writing duplicate audit rows
forever for any run sitting in a terminal-adjacent waiting state. ^[extracted]

**The fix pattern:** the "have I already acted on this" answer must itself be a committed database
fact (an `acknowledged` boolean or an idempotency key checked before acting), not something computed
from data that doesn't change once the tick loop stops advancing it.

## Failure mode 3: no row locking under multi-replica dispatch

A design that assumes a scan loop is safe to run on 2+ replicas concurrently (to avoid a persistent
lease/"slow owner" problem — see [[reference/data-acquisition-cloud-sync-detailed-design]]'s
database-as-task-queue model) requires **both** a `FOR UPDATE SKIP LOCKED`-style claim query **and** a
dispatch guard that checks for already-in-flight tasks for the same run before dispatching a new one.
Dropping a persistent lease without also implementing the locking that was supposed to replace it
leaves the run row with no concurrency protection at all — two replicas can select and dispatch the
same run in the same cycle. ^[extracted]

## Failure mode 4: admission idempotency without an enforced constraint

A duplicate-run-rejection guarantee that only checks "does a row already exist for this key" at READ
COMMITTED isolation, with no unique database constraint and no pessimistic lock, is a race: two
concurrent admissions for the same natural key (e.g. `pipeline_id + batch_date`) can both pass the
existence check and both insert. **The enforcement has to live in the schema** (a unique
partial index on the natural key, excluding replay rows) — an application-level check alone is
advisory, not a guarantee, under concurrent load. ^[extracted]

## Failure mode 5: ordering of admission-time guards determines caller-visible error semantics

When both a duplicate-run check and a concurrency-ceiling check exist, the *order* they run in decides
whether a genuine retry of an already-processed batch is reported as "already done" (`409`, the correct
outcome per CS-015/CS-020) or "try again later" (`429`, telling an external scheduler like Control-M to
retry something that will never succeed). Running the duplicate check first — before the ceiling check
can short-circuit — is not a minor ordering detail; it's the difference between a caller correctly
distinguishing "already ran" from "system is busy". ^[extracted]

## Why this matters beyond this one extract

None of these five failure modes are exotic — each is a small, specific, testable mechanism (a
dedicated failure-transition method, a committed acknowledgement flag, `FOR UPDATE SKIP LOCKED` plus a
dispatch guard, a unique constraint, and check-ordering) rather than a large redesign. That is exactly
why they're worth naming as a checklist: they are also exactly the kind of gap that a design document's
prose ("the database is the state machine") does not make visually obvious in code review, and that
only surfaces when a probe test actually drives a run through the full task sequence and reads the
committed rows back. ^[inferred]

## Related

- [[reference/data-acquisition-cloud-sync-detailed-design]]
- [[reference/orchestration-service-mini-code-assessment]]
- [[synthesis/orchestration-service-mini-assessment]]
- [[concepts/data-onboarding-orchestration-pipeline]]
- [[concepts/source-registry-and-audit-data-model]]

## Sources

- External: OCBC Data Acquisition - Orchestration Service Code Assessment.md
