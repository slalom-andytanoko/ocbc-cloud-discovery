---
title: OCBC Data Acquisition Platform on AWS — v1.3 (Source Document)
category: reference
tags: [aws, data-platform, ocbc, data-acquisition, source-document]
relationships:
  - target: "[[reference/data-acquisition-platform-v1.2]]"
    type: supersedes
  - target: "[[entities/cloud-data-acquisition-service]]"
    type: extends
  - target: "[[synthesis/data-acquisition-open-decisions]]"
    type: informs
  - target: "[[reference/cloud-sync-user-stories]]"
    type: related_to
sources: ["External: OCBC Data Acquisition Platform on AWS - v1.3.md", "External: Re__IaC_Deployment_Process/OCBC Data Acquisition Platform on AWS - v1.3.md"]
summary: AWS-authored DRAFT v1.3 (31 Jul 2026, refined 2026-08-03) of the DAL design, deferring schema-drift/ownership validators to the backlog, replacing pattern-based file/object enumeration with one-file-per-pipeline-entry, moving file/object readiness onto a Control-M job dependency, adding a Scheduler Job Adapter to bridge Control-M's synchronous job model with the DAL's async run lifecycle, and (2026-08-03 refinement) adding a post-landing decompression component that resolves Q-15.
provenance:
  extracted: 0.9
  inferred: 0.1
  ambiguous: 0.0
base_confidence: 0.75
lifecycle: draft
lifecycle_changed: 2026-08-03
tier: core
created: 2026-07-31
updated: 2026-08-03
---

# OCBC Data Acquisition Platform on AWS — v1.3 (Source Document)

Reference index for the external source "OCBC Data Acquisition Platform on AWS", DRAFT v1.3, dated 2026-07-31. This page captures the major deltas from v1.2 so downstream concept/synthesis pages can align without reproducing proprietary source text.

## What Changed in v1.3 (Distilled)

1. **Schema change detection deferred (BL-005).** The narrow-form schema drift validator (CS-013) is specified in §9.1.1 but not built in this release — tracked as a backlog item. Type-level column comparison, versioned schema artefacts, and drift-event publication remain permanently out of scope regardless.
2. **Data owner verification deferred (BL-006).** The ownership validator (CS-057) is deferred. When eventually adopted it produces WARN only and runs outside the validation chain's critical path (an unreachable corporate directory must never block acquisition).
3. **One file/object per pipeline entry.** Each file-transfer or object-storage pipeline entry now names exactly one file or object (location + name, or bucket + key). Pattern-based enumeration and multi-file batch matching are removed from source acquisition — a logical multi-file batch is represented as multiple pipeline entries.
4. **File/object readiness via Control-M job dependency, not polling.** Source systems don't support file markers or completion signals, so the `source_file_watch_config` registry table is removed. Control-M's own upstream job-dependency declaration is now the authoritative readiness signal for file/object sources; only relational (DB-poll) sources still use a readiness query.
5. **Readiness query made configurable per source.** The Source Registry holds a parameterised readiness query plus an expected ready value for relational sources; the DAL is agnostic to the shape of the source's own control-table structure (no fixed `BATCH_CONTROL` schema assumed).
6. **Scheduler Job Adapter (new §10.1.1) — resolves OQ-08.** A lightweight, non-OpenShift component running inside the Control-M job's own execution environment. It calls `POST /orchestration/runs/initiate`, then polls the DAL PostgreSQL (read-only, via PgBouncer) for run status until terminal, exiting `0` on `SECURED` and non-zero on failure — bridging the DAL's async run lifecycle with Control-M's synchronous job model so a failed DAL run surfaces as a failed Control-M job natively.

### 2026-08-03 Refinement — Post-Landing Decompression (resolves Q-15)

A re-sent, textually refined copy of this same v1.3 draft (still labelled v1.3, received via `external/Re__IaC_Deployment_Process/`) adds one new capability and a round of terminology cleanup ("scheduler job" used consistently instead of a bare "job" wherever it means the Control-M unit of work, avoiding confusion with a DAL *run*):

7. **Post-landing decompression component (new).** Where a pipeline compresses file/object content before transfer (scheduled path only — see the compression rule above), a configurable AWS-side component now decompresses the landed object back to its original form **after** DataSync transfer and post-transfer verification, and **before** the run is closed. It writes the uncompressed content back under the same customer-managed KMS key, confirms the result against the pre-compression manifest checksum, and removes the compressed original. A failure at this step fails the run; it is skipped for pipelines without decompression enabled or for relational extracts (never externally compressed). This directly resolves the companion user-stories document's previously open **Q-15** ("which downstream stage decompresses landed file content") — the answer is: the DAL platform itself, on the AWS side, as a distinct post-transfer step. See [[reference/data-acquisition-cloud-sync-detailed-design]] for the component-level design (CS-063, CS-064 stories; DD-15 in the detailed-design decision register).

## Net Impact on Existing Knowledge Base

- [[concepts/data-onboarding-orchestration-pipeline]] should drop any residual `BATCH_CONTROL`-polling framing for file/object sources and add the Scheduler Job Adapter as the mechanism that closes the Control-M ↔ DAL async loop.
- [[reference/cloud-sync-user-stories]] should reflect the companion v0.5 user-stories update (CS-013/CS-057 deferred, CS-006/CS-007 one-file-per-entry, CS-020–022 rewritten, new Epic G business-date resolution CS-060–062).
- [[synthesis/data-acquisition-open-decisions]] / [[open-questions]] should mark **OQ-08 (scheduler contract) resolved** by the Scheduler Job Adapter, and record the two new backlog deferrals (BL-005 schema drift, BL-006 ownership check) as scope-reduction items relevant to future backlog planning.
- [[deliverables/findings]] should capture the schema-drift/ownership deferrals as a documented scope reduction (not a documentation gap) — these were previously described as in-scope validators in v1.2/CS-053 and are now explicitly out of the current build.

## Related

- [[reference/data-acquisition-platform-v1.2]]
- [[reference/cloud-sync-user-stories]]
- [[reference/data-acquisition-cloud-sync-detailed-design]]
- [[entities/cloud-data-acquisition-service]]
- [[synthesis/data-acquisition-architecture-overview]]
- [[synthesis/data-acquisition-open-decisions]]

## Sources

- External: OCBC Data Acquisition Platform on AWS - v1.3.md
- External: Re__IaC_Deployment_Process/OCBC Data Acquisition Platform on AWS - v1.3.md
