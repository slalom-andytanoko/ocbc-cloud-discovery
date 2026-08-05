---
title: UC-1 Scheduled DB Poll — Narrative Walkthrough (Source Document)
category: reference
tags: [aws, ocbc, data-acquisition, use-case, source-document]
relationships:
  - target: "[[reference/data-acquisition-platform-v1.1]]"
    type: derived_from
  - target: "[[concepts/data-onboarding-orchestration-pipeline]]"
    type: extends
  - target: "[[concepts/source-registry-and-audit-data-model]]"
    type: extends
sources: ["External: uc1_scheduled_db_poll_narrative.docx"]
summary: A detailed step-by-step narrative for UC-1 (SCHEDULED_DB_POLL) — an Oracle source, Control-M trigger, on-prem-to-AWS batch handoff — including full data-dictionary listings and two appendices.
provenance:
  extracted: 0.9
  inferred: 0.1
  ambiguous: 0.0
base_confidence: 0.66
lifecycle: draft
lifecycle_changed: 2026-07-28
tier: supporting
created: 2026-07-28
updated: 2026-07-28
---

# UC-1 Scheduled DB Poll — Narrative Walkthrough (Source Document)

Reference index for a standalone narrative document walking through **UC-1 (`SCHEDULED_DB_POLL`)** end-to-end for a representative relational source (Oracle), from Control-M's trigger through to the batch landing in S3. It is the most detailed single-use-case account among the ingested documents and is the primary source for [[concepts/source-registry-and-audit-data-model]]'s data dictionaries.

## Narrative Steps (§2)

0. Onboarding pre-condition — source registered, `BATCH_CONTROL`-style readiness table agreed with the source team, governance sign-off recorded.
1. Control-M fires on schedule, calls `POST /orchestration/runs/initiate` with `source_id`/`pipeline_id`, `batch_date`, `trigger_ref`; Orchestration Service creates `run_id` + audit row (`INITIATED`), Control-M is fire-and-forget from here.
2. Orchestration Service polls the source's read-only readiness table (via the Integration Service's JDBC connector) inside the configured poll window until `ETL_COMPLETE_FLAG` is set, or the window expires (→ SLA alert).
3. Integration Service binds the registry's parameterised SQL template with the batch date and runtime parameters, extracts, converts to Parquet, and writes to the `control-zone`, then writes `_manifest.json` last.
4. Control Service validates (schema, size, checksum, threshold, duplicate check), compresses, updates the manifest.
5. Security Service classifies, tags `target_tier`, promotes the batch (data + manifest) from `control-zone` to the transfer-ready `zone`.
6. Orchestration Service calls EventBridge `PutEvents` (`EVENT_PUBLISHED`); if AWS/Direct Connect is unavailable, the run holds at this checkpoint and retries with backoff — no data loss, resumes automatically.
7. EventBridge Rule → Lambda resolves `target_tier` and calls DataSync `StartTaskExecution`.
8. DataSync agent (from the per-VPC agent pool) pulls the batch and manifest over Direct Connect into the resolved S3 bucket/prefix under the source's CMK, performing its own checksum verification.
9. DataSync's `TaskExecution` state-change event flows back through EventBridge Rule 2 → API Destination → Orchestration Service, which marks the run `COMPLETED`, checks the SLA deadline, and records transfer metrics.

## Data Dictionaries (§3)

Full attribute listings for the three tables also summarised in [[concepts/source-registry-and-audit-data-model]]:
- **Source Registry** (flat, pre-decomposition illustrative model — 27 attributes)
- **Orchestration Audit table** (17 attributes)
- **`BATCH_CONTROL`** (source-owned readiness table — 9 attributes)

## Appendix A — Control-M Acknowledgement Pattern

Describes the "fire-and-forget" contract: Control-M's own job-completion status reflects only that the `initiate` call was accepted (HTTP 202 + `run_id`), not that the underlying batch has landed — actual completion/failure is only visible via the Orchestration Service's run-status API or its alerting channel. This is an important operational nuance: **Control-M "green" does not mean the batch succeeded.**

## Appendix B — DataSync Task vs. Task Execution (older model — superseded)

Describes a **single shared DataSync agent** processing task executions strictly in FIFO order per VPC. This is superseded by the v1.1 PDF's **agent-pool model** (§9.6/Appendix B: one agent per concurrent task, sized 24 in production / 5 in UAT, matching the earlier-ingested architecture diagrams' "AWS DataSync Agents (Tasks)" plural boxes in each private subnet). The FIFO-single-agent description reflects an earlier design iteration and should not be used as current-state; the pool model in [[reference/data-acquisition-platform-v1.1]] is authoritative. `^[inferred]`

## Related

- [[reference/data-acquisition-platform-v1.1]]
- [[concepts/data-onboarding-orchestration-pipeline]]
- [[concepts/source-registry-and-audit-data-model]]
- [[concepts/temporal-io-workflow-orchestration]]

## Sources

- External: uc1_scheduled_db_poll_narrative.docx
