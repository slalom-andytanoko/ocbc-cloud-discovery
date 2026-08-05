---
name: aws-wafr
description: >
  Run AWS Well-Architected Framework Reviews (WAFR) against the 6 core
  pillars: Security, Operational Excellence, Reliability, Performance
  Efficiency, Cost Optimization, and Sustainability. Use whenever the user
  wants to evaluate an AWS workload against AWS-published best practices.
  Triggers on: "WAFR", "Well-Architected review", "AWS pillar assessment",
  question IDs (SEC-01, OPS-05, REL-13, PERF-02, COST-04, SUS-01), pillar
  names paired with assessment language ("assess security", "audit
  reliability"), and adjacent phrasing like "score my workload", "find AWS
  best-practice gaps", "compliance check against AWS", "Well-Architected
  assessment for client X", "audit my AWS account". Trigger even when the
  user does not say "WAFR" explicitly. Reports are designed for delivery as
  Slalom-branded Word documents via the slalom-docx skill. For Generative AI
  workload reviews specifically, defer to v0.2.0 (tracked in ../../ROADMAP.md).
---

# AWS WAFR Skill

Tiered evidence collection + handler-registry architecture for AWS Well-Architected Framework Reviews. Outputs Slalom-branded Markdown reports ready for `slalom-docx` conversion to Word documents.

## Multi-account model (v0.1.2)

`config.yml` accepts an `accounts[]` list. Each entry maps to one AWS profile; SSO-first, no `sts:AssumeRole`. The profile name is the account key used to scope all artifacts.

```yaml
accounts:
  - profile: acme-management   # first entry = primary (written to aws.{profile,region})
    region: us-east-1
    label: Management
    role: management            # single | management | audit | log-archive | workload
    account_id: "111111111111"  # optional but recommended

  - profile: acme-audit
    region: us-east-1
    label: Audit
    role: audit
    account_id: "222222222222"
```

**Single-account**: one `accounts[]` entry (or omit the block) - flat layout, identical to v0.1.1 behavior. **Multi-account**: two or more entries - each account's cache lands under `.wafr-workspace/accounts/<key>/` and reports under `findings/<key>/<pillar>/`. Assess and enrich commands loop every account with `--account-key KEY`.

## Workspace folders

| Folder | When to populate | Purpose |
|---|---|---|
| `context/` | Before the first assess run | Pre-assessment inputs: `accounts.yml` account map, kickoff transcripts, architecture docs, scope notes |
| `enrichment/` | After assess, before or during enrich | Post-assess refinement: runbooks, decision logs, compensating-control docs |

`context/accounts.yml` is the prescriptive account map. Edit it before `/aws-wafr:init`; the wizard reads it automatically. `enrichment/<pillar>/` (or `enrichment/all/`) holds files whose chunks are cited in reports.

## Step 0: Preflight

```bash
python3 scripts/preflight.py
```

Missing deps: re-run with `--install`. Missing `config.yml`: route the user to `/aws-wafr:init`.

## Step 1: Resolve the question

```bash
python3 scripts/lib/get_question_info.py <ID-or-slug>
```

Returns `{id, alternative_id, pillar, file, title, control_count}`. Load `assets/wafr/<file>` once for control titles and choice descriptions.

## Step 2: Tiered collect

```bash
python3 scripts/orchestrate.py --question <ID> --phase collect [--account-key KEY --profile P --region R]
python3 scripts/orchestrate.py --question <ID> --phase digest  [--account-key KEY]
```

Sequences:

1. **Tier 1** (24h TTL): Resource Groups Tagging API resolves workload-tagged ARNs. Falls back to Resource Explorer or account-wide scope.
2. **Tier 2** (once per session): one call per detected service (`audit_manager`, `aws_config`, `security_hub`, `trusted_advisor`, `compute_optimizer`, `resilience_hub`, `cost_explorer`, `access_analyzer`, `service_quotas`, `backup`, `cloudwatch`, `cloudtrail`, `resource_explorer`). Resolves ~30-50% of controls baseline; +20-30% with Audit Manager enabled.
3. **Tier 3 drill scope**: records which `service:type` handlers have ARNs in workload scope.
4. **Digest construction**: builds per-control digests at `.wafr-workspace/[accounts/<key>/]evidence-cache/digests/<ID>/<control>.json` with `_enrichment` refs matching each recipe's `enrichment_topics`.

Load the active pillar reference only - and only this one:

```bash
# references/pillars/<pillar>.md - scoring nuance + common false positives.
```

Do NOT pre-emptively load other pillar or diagnostic refs.

## Step 3: Sequential control assessment

```bash
python3 scripts/lib/get_digest.py <ID> --list-controls
python3 scripts/lib/get_digest.py <ID> <control>
```

The digest returns `fields`, `provenance`, `sampling` metadata, and `_enrichment` references.

**Enrichment-handling rule**: when a digest contains `_enrichment`, for each entry:

1. Read lines `chunk.start_line` through `chunk.end_line` from the cited file (path is relative to cwd).
2. Factor that content into findings and recommendations.
3. Cite the source file in the report's "Context Applied" subsection.

Example:

```json
{
  "control": "SEC-01-2",
  "fields": {"root_mfa_enabled": false, "root_access_keys_present": true},
  "_enrichment": [{"file": "enrichment/security/2026-04-12-meeting.md", "chunk": {"start_line": 1, "end_line": 45}, "topic": "root_user"}]
}
```

Means: AWS data says root MFA is off; also read `enrichment/security/2026-04-12-meeting.md` lines 1-45 to understand accepted risks or compensating controls.

Score each control: `COMPLIANT` / `PARTIALLY IMPLEMENTED` / `NOT IMPLEMENTED`. Severity: `CRITICAL` / `HIGH` / `MEDIUM` / `LOW`. Write `[.wafr-workspace/accounts/<key>/]current-assessment/assessment-data.json` fresh as a single JSON object:

```json
{
  "controls": [
    {
      "control_id": "<control>",
      "control_title": "...",
      "status": "COMPLIANT | PARTIALLY IMPLEMENTED | NOT IMPLEMENTED",
      "severity": "CRITICAL | HIGH | MEDIUM | LOW",
      "findings": "...",
      "recommendation": "...",
      "evidence_sources_used": ["audit_manager.evidence_by_control"],
      "enrichment_context_applied": [{"file": "...", "start_line": 1, "end_line": 45, "topic": "..."}]
    }
  ],
  "executive_summary": {"overview": "...", "overall": "...", "critical_count": 0},
  "prioritized_recommendations": [{"title": "...", "severity": "...", "description": "..."}]
}
```

**Use CLI getters, never read catalog files directly**:

| Getter | Replaces |
|---|---|
| `get_question_info.py` | `assets/wafr/question-reference.json` |
| `get_capability_info.py` | `.wafr-workspace/aws-capabilities.json` |
| `get_collector_info.py` | `scripts/lib/evidence_recipes/*.json` |
| `get_digest.py` | `.wafr-workspace/evidence-cache/digests/<ID>/<control>.json` |

## Step 4: Finalize

```bash
python3 scripts/orchestrate.py --question <ID> --phase finalize [--account-key KEY]
```

Produces in `findings/[<key>/]<pillar>/`:

- `<ID>-assessment.md` - Slalom-branded YAML front matter + Markdown with per-control "Sources" + "Context Applied" subsections
- `<ID>-assessment.json` - structured sidecar for cross-question rollups

Auto-invoke slalom-docx on the produced Markdown. If unavailable, print:

```
/slalom-docx use the proposal-and-delivery template on findings/<pillar>/<ID>-assessment.md
```

## When something looks wrong

Consult `references/index.md` first. Specific routes:

- **Stale data / cache refresh** -> `references/evidence-caching.md`
- **Tier dispatch confusion** -> `references/tiered-collection.md`
- **Account scaling (50k+ resources)** -> `references/scaling-strategy.md`
- **Capability detection oddities** -> `references/native-services.md`
- **AWS API errors, IAM gaps** -> `references/aws-access.md`
- **Recipe authoring** -> `references/evidence-collectors.md`
- **Enrichment not surfacing** -> `references/enrichment.md`
- **Report format / front matter** -> `references/report-format.md`
- **End-of-session improvement signal** -> `references/feedback.md`

## Pillar mode

```text
/aws-wafr:assess SEC    # or OPS / REL / PERF / COST / SUS
```

For each account in `accounts[]` (or single flat account):

1. Resolve pillar -> question list: `python3 scripts/lib/get_question_info.py --pillar <PILLAR>`.
2. Run the 4-phase flow per question with `--account-key KEY` for each account.
3. On failure: mark the question failed, continue.
4. Render per-account pillar summary: `python3 scripts/lib/report_render.py pillar-summary <pillar> --account-key KEY`.
5. Render cross-account rollup (multi-account only): `python3 scripts/lib/report_render.py cross-account-summary <pillar> <key...>`.
6. Auto-invoke slalom-docx on `findings/[<key>/]<pillar>/_pillar-summary.md`.

Do not shell out to a fresh Claude CLI process.

## Slalom-branded report delivery

All reports include YAML front matter (`prepared_for`, `prepared_by`, `engagement_code`, `slalom_branding.template`) populated from `config.yml`. Every assessment auto-invokes slalom-docx on the produced Markdown. If slalom-docx is not installed, print the manual invocation as a fallback. `enrichment/` and `.wafr-workspace/` are `.gitignored` by default. AWS API calls target only the user's own configured accounts.

For the full reference catalog, see `references/index.md`. For v0.2.0+ deferred items, see `../../ROADMAP.md`.
