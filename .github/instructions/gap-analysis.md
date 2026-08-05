---
name: gap-analysis
description: >
  Cloud-agnostic gap analysis orchestrator. Compares the current state documented in the wiki
  against best practices for the relevant cloud platform(s). Detects which cloud packs are
  active and triggers the appropriate deep-dive skills.
  Use when the user says "run gap analysis", "compare to best practices", "what are the gaps",
  "assess current state", "what needs fixing", or "/gap-analysis".
  Also triggers on "landing zone assessment", "best practices check".
  NOTE: For a formal Well-Architected Framework Review (AWS) use `/aws-wafr` from slalom-agent-kit.
  For Azure CAF alignment use `/gap-analysis-azure`. This skill orchestrates the broad sweep.
version: 2.0.0
---

# Gap Analysis — Best Practices vs Current State

You are performing a structured gap analysis. Your job is to compare what has been documented
in the wiki (current state) against cloud best practices, and produce actionable findings with
severity and remediation guidance.

This skill is **cloud-agnostic** — it detects which cloud platforms are relevant to the
engagement and orchestrates the appropriate deep-dive skills.

---

## Before You Start

1. **Load environment** — read `.env` for vault path and active packs
2. **Detect active cloud platforms** — check which cloud packs are installed:
   - Look for `ingest-aws` skill → AWS is in scope
   - Look for `ingest-azure` skill → Azure is in scope
   - Look for `ingest-gcp` skill → GCP is in scope
   - If none found, default to platform-agnostic assessment using wiki content
3. **Discover current state pages** — do NOT rely on a hard-coded list of files. Instead:
   - Read `index.md` to get the full list of current wiki pages
   - List and read ALL files in `concepts/` — architectural patterns and decisions
   - List and read ALL files in `entities/` — concrete services and systems
   - Read relevant `journal/` entries for session context and action items
   - Check `synthesis/` for any previous gap analyses
4. **Load cross-platform references** (these are cloud-agnostic):
   - `./references/iac-best-practices.md` — IaC maturity (if IaC is in scope)
   - Do NOT load cloud-specific best practices here — those live under each cloud skill's own
     `references/` directory and are loaded by that skill when it runs

> **Why dynamic discovery?** The wiki grows with each session ingest. Always discover what's
> available at runtime rather than relying on a hard-coded list.

---

## Step 1: Determine Scope and Platform

### Auto-Detection

Based on the wiki content and installed skills, determine:

| Signal | Platform |
|--------|----------|
| Pages mention AWS, OU structure, SCPs, Transit Gateway, AFT | AWS |
| Pages mention Azure, management groups, Entra ID, subscriptions, Azure Policy | Azure |
| Pages mention GCP, projects, folders, org policies, VPC Service Controls | GCP |
| Pages mention Terraform, Bicep, CDK, CloudFormation | IaC (cross-platform) |
| Multiple platforms documented | Multi-cloud |

### Scope Options

Ask the user (or infer from context):
- **Broad sweep** (default) — assess all detected platforms at high level
- **Platform deep-dive** — focus on one platform (triggers cloud-specific skill)
- **Domain-specific** — assess only a particular domain (e.g., "just networking")

---

## Step 2: Orchestrate Cloud-Specific Deep Dives

Based on detected platforms, **delegate** to the appropriate deep-dive skill. Each cloud skill
owns its own best practices reference file and domain expertise — the core gap-analysis skill
does NOT attempt to replicate that knowledge.

### If AWS is in scope:
- **Trigger `/gap-analysis-aws`** — it loads its own `references/aws-landing-zone-best-practices.md`
- For a quick broad sweep (user doesn't want full deep-dive), perform a high-level check
  against wiki content using your training knowledge of AWS best practices

### If Azure is in scope:
- **Trigger `/gap-analysis-azure`** — it loads its own `references/azure-caf-best-practices.md`
- For a quick broad sweep, perform a high-level check using CAF training knowledge

### If GCP is in scope:
- **Trigger `/gap-analysis-gcp`** — it loads its own `references/gcp-caf-best-practices.md`
- For a quick broad sweep, perform a high-level check using Architecture Framework training knowledge

### If IaC is in scope:
- **Trigger `/gap-analysis-iac`** — uses its own `references/iac-best-practices.md`

### Multi-cloud engagements
When multiple platforms are detected:
1. Trigger each relevant cloud-specific skill
2. After deep-dives complete, produce a cross-platform synthesis covering shared concerns
   (identity federation, network connectivity, governance consistency, cost visibility)
3. Highlight cross-platform gaps (e.g., inconsistent tagging, disconnected monitoring)

---

## Step 3: Cross-Platform Assessment Domains

These domains apply regardless of cloud provider:

| Domain | What to Assess |
|--------|---------------|
| Identity & Access | Centralised identity, least privilege, MFA, privileged access management, break-glass |
| Network | Segmentation, hybrid connectivity, DNS, firewall, encryption in transit |
| Security | CSPM, logging, SIEM, key management, encryption at rest, incident response |
| Governance | Policy-as-code, tagging, resource lifecycle, compliance, change management |
| Operations | IaC maturity, CI/CD, drift detection, monitoring, alerting, documentation |
| Cost | Budgets, allocation, optimisation, accountability, anomaly detection |
| Reliability | HA, DR, backup, RTO/RPO, resilience testing |

---

## Step 4: Perform Gap Analysis

For each domain in scope, compare documented current state against best practices.

### Pillar Scorecard

Score each domain 1-5:
- **1** — Not implemented; critical gaps
- **2** — Partially implemented; significant gaps remain
- **3** — Mostly implemented; some gaps to address
- **4** — Well implemented; minor improvements possible
- **5** — Fully aligned with best practices

### Finding Format

```markdown
### [DOMAIN-N] Finding Title

**Severity:** 🔴 High Risk Issue (HRI) | 🟡 Medium Risk Issue (MRI) | 🟢 Improvement Opportunity
**Domain:** Identity & Access | Network | Security | Governance | Operations | Cost | Reliability
**Platform:** AWS | Azure | GCP | Cross-Platform
**Current State:** What exists today (cite wiki page)
**Best Practice:** What should exist (cite reference)
**Gap:** What's missing or misconfigured
**Risk:** What could go wrong if not addressed
**Recommendation:** Specific action to close the gap
**Services/Tools:** Which cloud services or tools to use
**Effort:** Low (< 1 week) | Medium (1-4 weeks) | High (1-3 months)
**Priority:** Quick Win | Foundation | Strategic
```

### Severity Definitions

| Severity | Definition | Response Time |
|----------|-----------|---------------|
| 🔴 HRI | Active security risk, compliance violation, or single point of failure | Immediate / this sprint |
| 🟡 MRI | Significant gap that increases blast radius or blocks production readiness | Within this engagement |
| 🟢 Improvement | Best practice not yet adopted; adds value but not an active risk | Backlog / future |

### Calibration Guidance

- **Acknowledge strengths explicitly** — note good practices before listing gaps
- **Don't over-flag** — a mature architecture should score 4-5 on most domains
- **Respect information gaps** — if data is insufficient, say so
- **Map to engagement scope** — prioritise findings actionable within this engagement

---

## Step 5: Cross-Reference with Session Findings

- Review action items from journal pages
- Check open questions that relate to gaps
- Note gaps already acknowledged by the team

---

## Step 6: Produce Output

Write the gap analysis to `synthesis/gap-analysis-{date}.md`:

```markdown
---
title: "Gap Analysis: Current State vs Best Practices"
category: synthesis
tags: [gap-analysis, {platform-tags}]
created: {ISO-8601}
updated: {ISO-8601}
source: "wiki current state + cloud best practices references"
visibility: visibility/internal
---

# Gap Analysis: Current State vs Best Practices

## Executive Summary

[3-5 sentences: platforms assessed, domains covered, findings count, severity distribution, top priorities]

## Platforms Detected

| Platform | Packs Active | Deep-Dive Available |
|----------|-------------|---------------------|
| AWS | aws | `/gap-analysis-aws` |
| Azure | azure | `/gap-analysis-azure` |
| IaC | core | `/gap-analysis-iac` |

## Domain Scorecard

| Domain | Score (1-5) | Key Strength | Key Gap | Platform |
|--------|-------------|--------------|---------|----------|
| Identity & Access | {score} | {strength} | {gap} | {platform} |
| Network | {score} | {strength} | {gap} | {platform} |
| Security | {score} | {strength} | {gap} | {platform} |
| Governance | {score} | {strength} | {gap} | {platform} |
| Operations | {score} | {strength} | {gap} | {platform} |
| Cost | {score} | {strength} | {gap} | {platform} |
| Reliability | {score} | {strength} | {gap} | {platform} |

## Severity Distribution

| Severity | Count |
|----------|-------|
| 🔴 High Risk Issues | N |
| 🟡 Medium Risk Issues | N |
| 🟢 Improvement Opportunities | N |

## Remediation Roadmap

### Quick Wins (< 1 week)
- [Finding title] — [summary] — [service/tool]

### Foundation (1-4 weeks)
- [Finding title] — [summary] — [service/tool]

### Strategic (1-3 months)
- [Finding title] — [summary] — [service/tool]

---

## Detailed Findings

[Findings grouped by domain...]

---

## Strengths (What's Working Well)

[Explicitly acknowledge good practices]

## Information Gaps (Need More Data)

[Areas we can't assess yet — become questions for future sessions]

## Recommended Deep Dives

Based on findings, consider running:
- `/gap-analysis-aws` — for AWS Landing Zone detail
- `/gap-analysis-azure` — for Azure CAF alignment detail
- `/gap-analysis-iac` — for IaC standards and practices

## Next Steps

[Concrete actions the team should take this week]
```

---

## Step 7: Update Wiki

1. Write the gap analysis page to `synthesis/`
2. Update `index.md` to include the new synthesis page
3. Update `hot.md` with the activity
4. Log the operation in `log.md`

---

## Step 8: Report to User

```
## Gap Analysis Complete

**Platforms:** [detected platforms]
**Scope:** [domains assessed]
**Findings:** N total (X HRI, Y MRI, Z improvements)

### Top Priority Items
1. [Finding] — Severity / Effort / Priority
2. ...

### Recommended Deep Dives
- [skill] — [reason]

### Information Gaps
- [Area where we can't assess yet]

> Full analysis: synthesis/gap-analysis-{date}.md
```

---

## Integration with Cloud-Specific Skills

### Skill Hierarchy

```
gap-analysis (this skill — orchestrator)
├── Broad sweep: wiki vs best practices (all platforms)
├── Detects active cloud packs
├── Triggers or recommends deep-dives:
│   ├── /gap-analysis-aws — AWS Landing Zone deep-dive
│   ├── /gap-analysis-azure — Azure CAF deep-dive
│   ├── /gap-analysis-iac — IaC maturity review
│   └── /gap-analysis-gcp — GCP Organisation deep-dive
└── Produces: prioritised remediation backlog
```

### Related Skills (from slalom-agent-kit)

- `/aws-wafr` — **Formal** AWS Well-Architected Framework Review. Uses the structured
  6-pillar question-based assessment methodology. Use this when the user explicitly asks
  for a "WAF review" or "Well-Architected review". This is complementary to gap-analysis —
  wafr is a formal review tool, gap-analysis is a discovery-phase comparison.

### When to use which

| User says | Skill to trigger | Why |
|-----------|-----------------|-----|
| "run gap analysis" | `/gap-analysis` | Broad discovery-phase sweep |
| "aws gap analysis" / "landing zone assessment" | `/gap-analysis-aws` | AWS-specific deep-dive |
| "azure gap analysis" / "CAF review" | `/gap-analysis-azure` | Azure-specific deep-dive |
| "WAF review" / "Well-Architected review" | `/aws-wafr` | Formal 6-pillar AWS assessment |

Use `/gap-analysis` for the initial broad sweep. Use platform-specific skills for
detailed assessments of individual cloud environments.

---

## Incremental Analysis

The gap analysis can be run incrementally:
- After each session ingest (new information may reveal or close gaps)
- After remediation work (to track progress)
- On specific domains (e.g., "run gap analysis on network only")
- On specific platforms (e.g., "run gap analysis for Azure only")

When running incrementally, read the previous analysis and:
- Mark closed gaps as "Resolved"
- Add new gaps discovered
- Update severity/priority based on new information

---

## Security & Trust

- Gap analysis findings may contain sensitive security information
- Mark all gap analysis pages with `visibility/internal`
- Do not include specific credentials, keys, or exploit details
- Focus on architectural and configuration gaps, not active vulnerabilities

---

## ⚠️ MANDATORY Completion Checklist

**You MUST complete ALL items below before reporting success. Do NOT skip any step.**

1. ✅ **`synthesis/gap-analysis-{date}.md`** — Written with scorecard, findings, and remediation roadmap
2. ✅ **`deliverables/findings.md`** — All new HRI/MRI/IMP findings appended with IDs, severity, source
3. ✅ **`index.md`** — New synthesis page added
4. ✅ **`hot.md`** — Recent Activity updated
5. ✅ **`log.md`** — Timestamped entry appended
6. ✅ **`open-questions.md`** — Information gaps added as open questions

**If you skip these steps, the wiki state will drift and the next session will start with stale context.**
