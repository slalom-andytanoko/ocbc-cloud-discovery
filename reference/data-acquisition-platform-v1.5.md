---
title: OCBC Data Acquisition Platform on AWS — v1.5 (Source Document)
category: reference
tags: [aws, data-platform, ocbc, data-acquisition, source-document]
relationships:
  - target: "[[reference/data-acquisition-platform-v1.3]]"
    type: supersedes
  - target: "[[reference/data-acquisition-cloud-sync-detailed-design]]"
    type: related_to
  - target: "[[reference/cloud-sync-user-stories]]"
    type: related_to
  - target: "[[entities/cloud-data-acquisition-service]]"
    type: extends
  - target: "[[synthesis/data-acquisition-open-decisions]]"
    type: informs
  - target: "[[concepts/kms-byok-key-management]]"
    type: related_to
  - target: "[[concepts/source-registry-and-audit-data-model]]"
    type: related_to
sources: ["External: OCBC Data Acquisition Platform on AWS.md"]
summary: AWS-authored DRAFT v1.5 (5 Aug 2026) of the DAL design, folding in v1.4 (4 Aug 2026 — one CMK per AWS account/BYOK, Diamond Zone per-application buckets, canonical S3 key layout, allowlisted source system IDs, caller-supplied-path pipeline mode) and v1.5's gap-analysis reconciliation of the pull/push parameter handoff (STAGED split into VALIDATED/COMPRESSED, DECOMPRESSING promoted to an audited state, Trigger Lambda task resolution via source_id, manifest-based cloud-side run correlation, push-path compression contradiction removed, source_ref vs source_path disambiguated).
provenance:
  extracted: 0.88
  inferred: 0.12
  ambiguous: 0.0
base_confidence: 0.74
lifecycle: draft
lifecycle_changed: 2026-08-05
tier: core
created: 2026-08-05
updated: 2026-08-05
---

# OCBC Data Acquisition Platform on AWS — v1.5 (Source Document)

Reference index for the external source "OCBC Data Acquisition Platform on AWS", DRAFT v1.5, dated 2026-08-05. This wiki had previously ingested only up to v1.3 ([[reference/data-acquisition-platform-v1.3]]); this page distils both the intervening **v1.4** (2026-08-04) and **v1.5** (2026-08-05) deltas, since neither was ingested individually and v1.5 supersedes v1.4 anyway.

## What Changed in v1.4 (4 Aug 2026, Distilled)

1. **One customer-managed KMS key per AWS account (BYOK) — new D27.** Confirmed with the customer: each DAL account holds a single CMK for landed data, not one CMK per source system as the design previously modelled. `source_governance` drops its per-source KMS key field entirely; segregation between sources/applications now rests on S3 prefix/bucket boundaries plus IAM. Key provisioning, rotation, and key-material origin remain customer-owned. See [[concepts/kms-byok-key-management]] (superseded).
2. **Diamond Zone per-application buckets — new A18.** Diamond Zone S3 buckets are provisioned per application; S3 cross-account replication delivers landed data from the DAL account to the AI-Factory accounts.
3. **Canonical S3 object key layout, formalised.** `<app-bucket>/batch_date=YYYY-MM-DD/<source_system>/<filename>`. S3 versioning handles re-runs of the same batch_date; replays land under a child prefix rather than overwriting.
4. **Allowlisted source system IDs.** A fail-closed onboarding gate: only pre-approved `source_system_id` values can be registered.
5. **Caller-supplied-path pipeline mode.** A new `pipeline_mode` discriminator on `source_pipeline` (`REGISTERED_ITEM` or `CALLER_SUPPLIED_PATH`), a new extension table `source_caller_path_config`, and a new `source_path` column on the audit table with extended deduplication for scheduled runs. See [[concepts/source-registry-and-audit-data-model]].

## What Changed in v1.5 (5 Aug 2026) — Gap-Analysis Reconciliation of the Pull/Push Parameter Handoff (No Scope Change)

6. **State machine reconciled with the Detailed Design.** The collapsed `STAGED` state is split into `VALIDATED` and `COMPRESSED`, matching [[reference/data-acquisition-cloud-sync-detailed-design]] §6.1 and its six-task model. The step table is renumbered (post-transfer verification is now step 10).
7. **`DECOMPRESSING` promoted to an audited run state.** The transfer-completion callback gains a `phase` (`TRANSFER` | `DECOMPRESSION`); a verified decompression-enabled run moves to `DECOMPRESSING` and closes on the decompression-phase callback — giving operators the in-flight visibility CS-064 requires and letting the SLA scan cover the decompression window.
8. **Trigger Lambda task resolution specified.** The transfer event now carries `source_id`; the Lambda resolves the pre-created DataSync task from it, purely by the onboarding naming/tag convention (AWS-side only — decision A11).
9. **Cloud-side run correlation via the manifest.** The post-transfer verification Lambda recovers `run_id`/`trace_id`/`pipeline_id` and a new `compression` indicator from the landed `_manifest.json`, so a DataSync completion event maps back to the correct run without reading any on-premises store (A11).
10. **Push-path compression contradiction removed.** The on-demand path never compresses (DD-15); a stale "compress on the stream" step and its associated compression-skip size limit are removed from the design text — no behaviour change, just removing an inconsistency.
11. **Caller-supplied-path → S3 key mapping made explicit.** The caller's normalised relative path is preserved beneath `<source_system>/` in the landed key.
12. **`source_ref` vs `source_path` disambiguated on the push contract.** Exactly one applies per on-demand request, selected by `pipeline_mode`.

## Net Impact on Existing Knowledge Base

- [[concepts/kms-byok-key-management]] updated to flag the D27 supersession — one account-level CMK, not per-source keys.
- [[concepts/source-registry-and-audit-data-model]] updated with the `pipeline_mode` discriminator, `source_caller_path_config`, the audit table's new `source_path` column and extended dedup, the allowlisted-system-ID gate, and the manifest's new `compression` field / cloud-side run correlation.
- [[concepts/sync-push-service-architecture]] updated to confirm the no-compression behaviour, the `source_ref`/`source_path` disambiguation, and the write-manifest-last convention.
- [[reference/data-acquisition-cloud-sync-detailed-design]] updated in place (still v0.1) with the reciprocal Detailed-Design-side changes from the same 2026-08-05 gap-analysis pass (`DECOMPRESSING` state, two-phase transfer-complete callback, minimal per-task result contract, Operations Service unified view, audit-retention formula).
- [[reference/cloud-sync-user-stories]] (now at v0.8) tracks the corresponding CS-025/CS-065–069 story additions this platform revision implements.
- [[synthesis/data-acquisition-open-decisions]] should record new decisions **D27** (one CMK per account) and **A18** (Diamond Zone per-application buckets) in the decision register.

## Related

- [[reference/data-acquisition-platform-v1.3]]
- [[reference/data-acquisition-cloud-sync-detailed-design]]
- [[reference/cloud-sync-user-stories]]
- [[concepts/kms-byok-key-management]]
- [[concepts/source-registry-and-audit-data-model]]
- [[concepts/sync-push-service-architecture]]
- [[entities/cloud-data-acquisition-service]]
- [[synthesis/data-acquisition-architecture-overview]]
- [[synthesis/data-acquisition-open-decisions]]

## Sources

- External: OCBC Data Acquisition Platform on AWS.md
