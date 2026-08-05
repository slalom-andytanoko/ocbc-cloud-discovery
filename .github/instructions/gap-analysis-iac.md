---
name: gap-analysis-iac
description: >
  IaC-specific gap analysis focused on Terraform standards, drift detection, CI/CD pipelines,
  module structure, state management, and secret handling for AWS Landing Zone infrastructure.
  Produces a structured gap analysis with severity ratings and a prioritised remediation backlog.
  Use when the user says "iac gap analysis", "terraform review", "infrastructure code review",
  "review terraform", "check iac standards", "iac assessment", or "/gap-analysis-iac".
  Also triggers on "terraform pipeline review", "drift detection review", "module review".
version: 1.0.0
requires_packs: [aws]
---

# Gap Analysis — Infrastructure as Code Deep Dive

You are performing a deep-dive gap analysis of the client's Infrastructure as Code practices.
This skill is focused exclusively on IaC: Terraform standards, repository structure, state
management, secret handling, module design, CI/CD pipelines, drift detection, and compliance
as code. It can be invoked standalone or as an extension of the core `gap-analysis` skill.

---

## Before You Start

1. **Load environment** — read `.env` for vault path
2. **Discover current state pages** — do NOT rely on a hard-coded list of files. Instead:
   - Read `index.md` to get the full list of current wiki pages
   - List and read ALL files in `concepts/` — look especially for IaC, Terraform, CI/CD pages
   - List and read ALL files in `entities/` — look for repo descriptions, pipeline configs
   - Read relevant `journal/` entries for IaC-related session notes
   - Check `synthesis/` for any previous IaC assessments
3. **Load IaC best practices reference** — read `./references/iac-best-practices.md`

> **Why dynamic discovery?** The wiki grows with each session ingest. Always discover what's
> available at runtime rather than relying on a hard-coded list that goes stale.

---

## Assessment Domains

| Domain | Wiki Pages (typical) | Best Practice Areas |
|--------|---------------------|---------------------|
| Repository Structure | terraform-cloud-iac, repo pages | Repo-per-account, file organisation, READMEs |
| State Management | terraform-cloud-iac | Remote state, locking, isolation per account |
| Secret & Credential Handling | terraform-cloud-iac, pipeline pages | OIDC, no hardcoded secrets, Secrets Manager |
| Module Design | iac pages | Versioned modules, single-concern, composition |
| Variables & Configuration | terraform pages | Descriptions, types, validation, naming |
| Branch Strategy & CI/CD | change-management-process | GitFlow, plan/apply pipeline, approvals |
| Drift Detection & Compliance | iac pages | Scheduled plans, policy-as-code, alerting |
| AFT-Specific Practices | aft pages | Account requests, global customisations, pipeline security |

---

## Step 1: Identify Assessment Scope

Determine which IaC domains to assess. Default is all, but the user may request a focused
analysis (e.g., "just review our pipeline" or "focus on state management").

---

## Step 2: Perform IaC Gap Analysis

For each domain in scope, compare documented current state against IaC best practices from
the reference document.

### Maturity Scorecard

Score each domain 1-5:
- **1** — Not implemented; critical gaps
- **2** — Partially implemented; significant gaps remain
- **3** — Mostly implemented; some gaps to address
- **4** — Well implemented; minor improvements possible
- **5** — Fully aligned with best practices

### Finding Format

For each finding, produce:

```markdown
### [IaC-N] Finding Title

**Severity:** 🔴 High Risk Issue (HRI) | 🟡 Medium Risk Issue (MRI) | 🟢 Improvement Opportunity
**Domain:** Repository Structure | State Management | Secrets | Modules | CI/CD | Drift Detection
**Current State:** What exists today (cite wiki page or repo)
**Best Practice:** What should exist (cite reference section)
**Gap:** What's missing or misconfigured
**Risk:** What could go wrong if not addressed
**Recommendation:** Specific action to close the gap
**Tools:** Relevant tools (tflint, Checkov, tfsec, Terratest, etc.)
**Effort:** Low (< 1 week) | Medium (1-4 weeks) | High (1-3 months)
**Priority:** Quick Win | Foundation | Strategic
```

### Severity Definitions

| Severity | Definition | Response Time |
|----------|-----------|---------------|
| 🔴 HRI | Active security risk (e.g., hardcoded secrets), no state locking, no remote state | Immediate / this sprint |
| 🟡 MRI | Significant gap that increases blast radius, blocks reliability, or hinders team velocity | Within this engagement |
| 🟢 Improvement | Best practice not yet adopted; adds value but not an active risk | Backlog / future |

### Calibration Guidance

- **Acknowledge strengths** — if the team uses Terraform Cloud, has CI/CD, uses modules, call these out
- **Don't over-flag** — mature teams should score 4-5 on most domains
- **Respect information gaps** — flag areas where we don't have enough data to assess
- **Avoid duplicating AWS-level findings** — if a gap is Landing Zone architecture (not IaC practice), refer to `gap-analysis-aws`

---

## Step 3: Repository Structure Assessment

Review against `./references/iac-best-practices.md` §1:

- Is a repo-per-account (or repo-per-domain) pattern used?
- Is there consistent file organisation (`main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`, `locals.tf`)?
- Does every repo have a `README.md`?
- Are resources grouped logically in files (not split arbitrarily)?

---

## Step 4: State Management Assessment

Review against §2:

- Is remote state in use (S3 + DynamoDB, or Terraform Cloud)?
- Is state encryption at rest enabled?
- Is state isolated per account/environment (no shared state across accounts)?
- Is state versioning enabled for recovery?
- Are `terraform_remote_state` data sources used for cross-stack references?

---

## Step 5: Secret & Credential Handling Assessment

Review against §3:

- Are there any hardcoded secrets, tokens, or access keys in `.tf` files or committed to git?
- Is OIDC workload identity used for CI/CD → AWS authentication?
- Are workspace variables (marked sensitive) used for secrets in Terraform Cloud?
- Are AWS Secrets Manager or Parameter Store used for application secrets?
- Are `sensitive = true` flags set on sensitive variable definitions?

---

## Step 6: Module Design Assessment

Review against §4:

- Are modules self-contained, tested, and versioned?
- Are module versions pinned (not using `main` or `latest`)?
- Are modules sourced from a private registry or pinned git refs?
- Are modules focused (one concern per module)?
- Is module nesting shallow (max 2-3 levels)?

---

## Step 7: Variables & Configuration Assessment

Review against §5:

- Do all variables have `description` fields?
- Are `type` constraints used?
- Are `validation` blocks used for business rules?
- Are sensitive variables marked with `sensitive = true`?
- Are resource IDs and ARNs coming from data sources or variables (not hardcoded)?
- Is there a consistent naming convention defined in `locals.tf`?

---

## Step 8: Branch Strategy & CI/CD Assessment

Review against §6:

- Is a GitFlow or branch-protection model in place for infrastructure repos?
- Is there an automated pipeline with: validate → security scan → plan → review → apply → verify?
- Are security scans (Checkov, tfsec) in the pipeline?
- Are PR reviews required? Are branch protection rules enforced?
- Is `terraform apply` only run from CI/CD (not from developer laptops)?

---

## Step 9: Drift Detection & Compliance Assessment

Review against §7:

- Are scheduled `terraform plan` runs in place to detect drift?
- Are drift alerts configured?
- Is Sentinel, OPA, or similar policy-as-code enforced?
- Are compliance reports generated?

---

## Step 10: AFT-Specific IaC Assessment

Review against §9:

- Are all account requests via the AccountRequest repo (GitOps)?
- Are global customisations minimal, stable, and version-controlled?
- Are account customisations idempotent and tested in sandbox first?
- Is the AFT management account protected (restricted merge access, audit logging)?

---

## Step 11: Cross-Reference with Session Findings

- Review action items from journal pages related to IaC or Terraform
- Note gaps already acknowledged by the team
- Flag open questions where more data is needed

---

## Step 12: Produce Output

Write the gap analysis to `synthesis/gap-analysis-iac-{date}.md`:

```markdown
---
title: "Gap Analysis: Infrastructure as Code Assessment"
category: synthesis
tags: [iac, terraform, ci-cd, drift-detection, gap-analysis]
created: {ISO-8601}
updated: {ISO-8601}
source: "wiki current state pages + iac-best-practices reference"
visibility: visibility/internal
---

# Gap Analysis: Infrastructure as Code Assessment

## Executive Summary

[3-5 sentences: domains assessed, findings count, severity distribution, top priorities, maturity]

## Domain Scorecard

| Domain | Score (1-5) | Key Strength | Key Gap |
|--------|-------------|--------------|---------|
| Repository Structure | {score} | {strength} | {gap} |
| State Management | {score} | {strength} | {gap} |
| Secret Handling | {score} | {strength} | {gap} |
| Module Design | {score} | {strength} | {gap} |
| Variables & Config | {score} | {strength} | {gap} |
| Branch Strategy & CI/CD | {score} | {strength} | {gap} |
| Drift Detection | {score} | {strength} | {gap} |
| AFT-Specific Practices | {score} | {strength} | {gap} |

## Severity Distribution

| Severity | Count |
|----------|-------|
| 🔴 High Risk Issues | N |
| 🟡 Medium Risk Issues | N |
| 🟢 Improvement Opportunities | N |

## Remediation Roadmap

### Quick Wins (< 1 week)
- [Finding title] — [summary] — [tool/service]

### Foundation (1-4 weeks)
- [Finding title] — [summary] — [tool/service]

### Strategic (1-3 months)
- [Finding title] — [summary] — [tool/service]

---

## Detailed Findings

### Repository Structure
[Findings...]

### State Management
[Findings...]

### Secret & Credential Handling
[Findings...]

### Module Design
[Findings...]

### Variables & Configuration
[Findings...]

### Branch Strategy & CI/CD
[Findings...]

### Drift Detection & Compliance
[Findings...]

### AFT-Specific Practices
[Findings...]

---

## Strengths (What's Working Well)

[Explicitly acknowledge good IaC practices already in place]

## Gaps Already Acknowledged by Team

[Gaps the client team has already identified in sessions]

## Information Gaps (Need More Data)

[Areas where we don't have enough information to assess]

## Next Steps

[Concrete actions the team should take this week]
```

---

## Step 13: Update Wiki

1. Write the gap analysis page to `synthesis/`
2. Update `index.md` to include the new synthesis page
3. Update `hot.md` with the activity
4. Log the operation in `log.md`

---

## Step 14: Report to User

```
## IaC Gap Analysis Complete

**Domains assessed:** Repository Structure, State Management, Secrets, Modules, CI/CD, Drift Detection, AFT
**Findings:** N total (X HRI, Y MRI, Z improvements)

### Top Priority Items
1. [Finding] — Severity / Effort / Priority
2. ...

### Information Gaps
- [Area where we can't assess yet]

> Full analysis: synthesis/gap-analysis-iac-{date}.md
```

---

## Best Practices Sources

- `./references/iac-best-practices.md`
- HashiCorp Terraform best practices
- AWS AFT guidance
- Checkov / tfsec / tflint documentation

---

## ⚠️ MANDATORY Completion Checklist

1. ✅ **`synthesis/gap-analysis-iac-{date}.md`** — Written with full domain scorecard, findings, and remediation roadmap
2. ✅ **`deliverables/findings.md`** — All new HRI/MRI/IMP findings appended with IDs, severity, source, and recommendations
3. ✅ **`index.md`** — New synthesis page added under the Synthesis section
4. ✅ **`hot.md`** — Recent Activity updated with today's date, scope, and finding count
5. ✅ **`log.md`** — Timestamped entry appended
6. ✅ **`open-questions.md`** — Information gaps added as open questions for future sessions
