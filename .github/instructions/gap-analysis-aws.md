---
name: gap-analysis-aws
description: >
  AWS Landing Zone specific gap analysis. Focuses on Control Tower, AFT, OU structure,
  account vending, identity, network, governance, and cost management.
  Produces a structured gap analysis with severity ratings, recommendations, and a
  prioritised remediation backlog for the AWS Landing Zone domain.
  Use when the user says "aws gap analysis", "landing zone assessment", "control tower review",
  "assess landing zone", "review ou structure", "aft review", or "/gap-analysis-aws".
  Also triggers on "account vending assessment", "aws architecture review", "security posture review",
  "security gap analysis", "iam security review", "encryption review", "guardduty review",
  "logging completeness check", "cspm review".
version: 1.0.0
requires_packs: [aws]
---

# Gap Analysis — AWS Landing Zone Deep Dive

You are performing a deep-dive gap analysis of the client's AWS Landing Zone. This skill is
focused exclusively on AWS-specific domains: Landing Zone design, Control Tower, AFT, OU
structure, account vending, identity, network, governance, and cost. It can be invoked
standalone or as an extension of the core `gap-analysis` skill.

---

## Before You Start

1. **Load environment** — read `.env` for vault path
2. **Discover current state pages** — do NOT rely on a hard-coded list of files. Instead:
   - Read `index.md` to get the full list of current wiki pages
   - List and read ALL files in `concepts/` — these describe architectural patterns and decisions
   - List and read ALL files in `entities/` — these describe concrete services and systems
   - Read relevant `journal/` entries for session context and action items
   - Check `synthesis/` for any previous gap analyses or assessments
3. **Load AWS Landing Zone best practices reference** — read `./references/aws-landing-zone-best-practices.md`
4. **Load security checks reference** — read `./references/cloud-security-checks.md`

> **Why dynamic discovery?** The wiki grows with each session ingest. Always discover what's
> available at runtime rather than relying on a hard-coded list that goes stale.

---

## Assessment Domains

| Domain | Wiki Pages (typical) | Best Practice Areas |
|--------|---------------------|---------------------|
| Identity & Access | ou-structure, iam pages | SSO, least privilege, SCPs, permission boundaries |
| Network | landing-zone-current-state, multi-region-strategy | TGW design, segmentation, firewall, DNS, IPAM |
| Governance | ou-structure, change-management-process | SCPs, tagging, Config rules, compliance |
| Cost | landing-zone-current-state | Billing, budgets, cost allocation tags, Savings Plans |
| Reliability | multi-region-strategy | Multi-AZ, DR, backup, RTO/RPO |
| Account Vending | aft pages | AFT pipeline, account requests, baselines |
| Security | guardduty, security-hub, cloudtrail pages | Logging, CSPM, IAM, encryption, S3, network security, incident response |

---

## Step 1: Identify Assessment Scope

Determine which Landing Zone domains to assess. Default is all AWS domains, but the user may
request a focused analysis (e.g., "just review the OU structure" or "focus on account vending").

---

## Step 2: Perform AWS Landing Zone Gap Analysis

For each domain in scope, compare the documented current state against AWS Landing Zone best
practices from the reference document.

### Pillar Scorecard

Score each domain 1-5:
- **1** — Not implemented; critical gaps
- **2** — Partially implemented; significant gaps remain
- **3** — Mostly implemented; some gaps to address
- **4** — Well implemented; minor improvements possible
- **5** — Fully aligned with best practices

### Finding Format

For each finding, produce:

```markdown
### [DOMAIN-N] Finding Title

**Severity:** 🔴 High Risk Issue (HRI) | 🟡 Medium Risk Issue (MRI) | 🟢 Improvement Opportunity
**Domain:** Identity & Access | Network | Governance | Cost | Reliability | Account Vending | Security
**Current State:** What exists today (cite wiki page)
**Best Practice:** What should exist (cite reference)
**Gap:** What's missing or misconfigured
**Risk:** What could go wrong if not addressed
**Recommendation:** Specific action to close the gap
**AWS Services:** Which AWS services/features to use for remediation
**Effort:** Low (< 1 week) | Medium (1-4 weeks) | High (1-3 months)
**Priority:** Quick Win | Foundation | Strategic
```

### Severity Definitions

| Severity | Definition | Response Time |
|----------|-----------|---------------|
| 🔴 HRI | Active security risk, compliance violation, or single point of failure that could cause outage/data loss | Immediate / this sprint |
| 🟡 MRI | Significant gap that increases blast radius or blocks production readiness | Within this engagement |
| 🟢 Improvement | Best practice not yet adopted; adds value but not an active risk | Backlog / future |

### Calibration Guidance

- **Acknowledge strengths explicitly** — if the team has good practices in place (e.g., all IaC,
  Terraform Cloud CI/CD, Transit Gateway), note these as strengths before listing gaps
- **Don't over-flag** — a mature Landing Zone should score 4-5 on most domains
- **Respect information gaps** — if data is insufficient to assess a domain, say so
- **Map to engagement scope** — prioritise findings actionable within this discovery engagement

---

## Step 3: Identity & Access Assessment

Review against `./references/aws-landing-zone-best-practices.md` §1:

**OU Structure**
- Are there separate OUs for Security, Infrastructure, Workloads (Prod), Workloads (Non-Prod), Sandbox, Suspended?
- Are Prod and Non-Prod in separate OUs to enable different SCP policies?
- Is there a Sandbox OU with aggressive cost controls?
- Is there a Suspended OU for decommissioning accounts?

**Service Control Policies**
- Is there a region restriction SCP?
- Are there deny-SCPs for: disabling CloudTrail, GuardDuty, Config; leaving the Org; root user actions; IAM user console access?
- Are SCPs applied per OU (not one-size-fits-all)?

**SSO / Identity Center**
- Is identity centralised via AWS IAM Identity Center?
- Is it federated from a corporate IdP (Entra ID, Okta, etc.)?
- Are permission sets following least privilege and separate for prod vs non-prod?
- Is MFA enforced? No long-lived IAM access keys for human users?

**Service Accounts & Roles**
- Are IAM roles (not users) used for all service-to-service access?
- Is cross-account access done via role assumption?
- Are permission boundaries on delegated admin roles?

---

## Step 4: Network Assessment

Review against `./references/aws-landing-zone-best-practices.md` §2:

**Hub-and-Spoke Design**
- Is there a centralised network account owning Transit Gateway?
- Are there spoke VPCs in workload accounts attached to TGW?
- Is there an inspection VPC with firewall for east-west and north-south traffic?
- Are there separate TGW route tables for prod vs non-prod?

**IP Address Management**
- Is AWS VPC IPAM deployed for centralised IP allocation?
- Are CIDR ranges non-overlapping across all accounts and regions?

**DNS**
- Is there centralised DNS via Route 53 Resolver?
- Are Private Hosted Zones shared to spoke accounts?

**Direct Connect / Connectivity**
- Are connections redundant (2+ DX in different locations)?
- Is encryption in place (MACsec or VPN over DX)?

---

## Step 5: Governance Assessment

Review against `./references/aws-landing-zone-best-practices.md` §4:

**Tagging Strategy**
- Are mandatory tags enforced (Environment, Owner, CostCentre, Project)?
- Is there tag compliance reporting?

**Account Vending (AFT)**
- Is the account request process standardised (AFT or similar)?
- Is an account baseline applied automatically?
- Is account metadata tracked?

**Change Management**
- Are all infrastructure changes via IaC (no ClickOps)?
- Is peer review required for production changes?
- Is rollback capability in place?

---

## Step 6: Cost Assessment

Review against `./references/aws-landing-zone-best-practices.md` §6:

- Is consolidated billing via the Org management account?
- Are AWS Budgets configured with alerts at 50%, 80%, 100%?
- Are cost allocation tags enforced?
- Are right-sizing recommendations reviewed?
- Are Savings Plans or RIs in place for steady-state workloads?

---

## Step 7: Security Assessment

Review against `./references/aws-landing-zone-best-practices.md` §3 and `./references/cloud-security-checks.md`:

### Logging & Monitoring Completeness

| Service | Check | Required |
|---------|-------|----------|
| CloudTrail | Organisation trail, all regions, management + data events | Yes |
| VPC Flow Logs | All VPCs across all accounts | Yes |
| AWS Config | All regions, all accounts, all resource types | Yes |
| GuardDuty | All accounts, all regions, delegated admin in Security account | Yes |
| Security Hub | CIS + AWS FSBP standards enabled | Yes |
| Access Analyzer | All accounts for external access findings | Yes |
| DNS Query Logging | Route 53 Resolver query logging | Recommended |

### Threat Detection (CSPM)

- Is GuardDuty enabled in all accounts and all regions?
- Is Security Hub aggregating findings from all accounts?
- Is delegated admin configured in the Security account?
- Are automated compliance standards active (CIS, AWS FSBP)?
- Is continuous drift detection from security baseline in place?

### IAM Privilege Escalation Risk

Flag dangerous permission combinations from `./references/cloud-security-checks.md`:

| Pattern | Severity | Permissions |
|---------|----------|-------------|
| Lambda PassRole escalation | Critical | iam:PassRole + lambda:CreateFunction |
| EC2 instance profile abuse | Critical | iam:PassRole + ec2:RunInstances |
| CloudFormation PassRole | Critical | iam:PassRole + cloudformation:CreateStack |
| Self-attach policy | Critical | iam:AttachUserPolicy |
| Policy version backdoor | Critical | iam:CreatePolicyVersion |
| Full admin wildcard | Critical | Action=* Resource=* |
| Service-level wildcard | High | iam:* or s3:* or ec2:* |
| Credential harvesting | High | iam:CreateAccessKey + iam:ListUsers |

Also check:
- Are there IAM users with console access (should use SSO)?
- Are there inline policies on IAM users?
- Are cross-account roles using external ID conditions?
- Is Access Analyzer reviewing unused permissions?

### Encryption

| Resource | At Rest | In Transit |
|----------|---------|------------|
| S3 buckets | SSE-KMS (preferred) or SSE-S3 | Enforce HTTPS via bucket policy |
| EBS volumes | Default encryption enabled org-wide | N/A |
| RDS instances | Encrypted at creation (cannot enable after) | Enforce SSL |
| DynamoDB tables | AWS-owned or customer-managed KMS | HTTPS (default) |
| Secrets Manager | KMS encrypted | HTTPS (default) |
| EFS file systems | KMS encrypted | TLS mount helper |

Flag: default encryption not enabled, KMS key rotation not enabled, no per-workload key separation.

### S3 Security

| Check | Required State | Severity if Missing |
|-------|---------------|-------------------|
| Account-level Block Public Access | All 4 flags enabled | Critical |
| Bucket-level Block Public Access | All 4 flags enabled | High |
| Default encryption | SSE-KMS or SSE-S3 | High |
| Bucket ACL | Private | High (Critical if public-read-write) |
| Access logging | Enabled for sensitive buckets | Medium |
| Versioning | Enabled for critical data | Medium |

### Network Security

Flag inbound Security Group rules from 0.0.0.0/0 or ::/0:

| Port | Service | Severity |
|------|---------|----------|
| 22 | SSH | Critical |
| 3389 | RDP | Critical |
| 0-65535 | All traffic | Critical |
| 3306/5432/1433 | Databases | High |
| 27017/6379 | MongoDB/Redis | High |

Also assess:
- Is east-west traffic inspected (centralised firewall)?
- Are workloads in private subnets only?
- Are VPC endpoints deployed for S3, DynamoDB, and common services?

### Incident Response

- Is automated alerting on critical security findings configured?
- Are runbooks documented for common incident types?
- Is there a forensics account for isolated investigation?
- Is a break-glass procedure documented and tested?

---

## Step 8: Cross-Reference with Session Findings

- Review action items from journal pages
- Note gaps already acknowledged by the team (reduces discovery priority, not remediation)
- Flag open questions where more data is needed

---

## Step 9: Produce Output

Write the gap analysis to `synthesis/gap-analysis-aws-{date}.md`:

```markdown
---
title: "Gap Analysis: AWS Landing Zone Deep Dive"
category: synthesis
tags: [aws, landing-zone, control-tower, aft, gap-analysis]
created: {ISO-8601}
updated: {ISO-8601}
source: "wiki current state pages + aws-landing-zone-best-practices reference"
visibility: visibility/internal
---

# Gap Analysis: AWS Landing Zone Deep Dive

## Executive Summary

[3-5 sentences: domains assessed, findings count, severity distribution, top priorities, maturity]

## Domain Scorecard

| Domain | Score (1-5) | Key Strength | Key Gap |
|--------|-------------|--------------|---------|
| Identity & Access | {score} | {strength} | {gap} |
| Network | {score} | {strength} | {gap} |
| Governance | {score} | {strength} | {gap} |
| Cost | {score} | {strength} | {gap} |
| Reliability | {score} | {strength} | {gap} |
| Account Vending | {score} | {strength} | {gap} |
| Security | {score} | {strength} | {gap} |

## Severity Distribution

| Severity | Count |
|----------|-------|
| 🔴 High Risk Issues | N |
| 🟡 Medium Risk Issues | N |
| 🟢 Improvement Opportunities | N |

## Remediation Roadmap

### Quick Wins (< 1 week)
- [Finding title] — [summary] — [AWS service]

### Foundation (1-4 weeks)
- [Finding title] — [summary] — [AWS service]

### Strategic (1-3 months)
- [Finding title] — [summary] — [AWS service]

---

## Detailed Findings

### Identity & Access

[Findings...]

### Network

[Findings...]

### Governance

[Findings...]

### Cost

[Findings...]

### Reliability

[Findings...]

### Account Vending

[Findings...]

---

## Strengths (What's Working Well)

[Explicitly acknowledge good practices already in place]

## Gaps Already Acknowledged by Team

[Gaps the client team has already identified in sessions]

## Information Gaps (Need More Data)

[Areas where we don't have enough information to assess]

## Next Steps

[Concrete actions the team should take this week]
```

---

## Step 10: Update Wiki

1. Write the gap analysis page to `synthesis/`
2. Update `index.md` to include the new synthesis page
3. Update `hot.md` with the activity
4. Log the operation in `log.md`

---

## Step 11: Report to User

```
## AWS Landing Zone Gap Analysis Complete

**Domains assessed:** Identity & Access, Network, Governance, Cost, Reliability, Account Vending, Security
**Findings:** N total (X HRI, Y MRI, Z improvements)

### Top Priority Items
1. [Finding] — Severity / Effort / Priority
2. ...

### Information Gaps
- [Area where we can't assess yet]

> Full analysis: synthesis/gap-analysis-aws-{date}.md
```

---

## Best Practices Sources

- `./references/aws-landing-zone-best-practices.md`
- `./references/cloud-security-checks.md`
- AWS Well-Architected Framework (all pillars, especially Security)
- AWS Control Tower best practices
- AFT (Account Factory for Terraform) recommended patterns
- AWS Security Reference Architecture (SRA)
- CIS AWS Foundations Benchmark
- AWS Foundational Security Best Practices (FSBP)

---

## ⚠️ MANDATORY Completion Checklist

1. ✅ **`synthesis/gap-analysis-aws-{date}.md`** — Written with full domain scorecard, findings, and remediation roadmap
2. ✅ **`deliverables/findings.md`** — All new HRI/MRI/IMP findings appended with IDs, severity, source, and recommendations
3. ✅ **`index.md`** — New synthesis page added under the Synthesis section
4. ✅ **`hot.md`** — Recent Activity updated with today's date, scope, and finding count
5. ✅ **`log.md`** — Timestamped entry appended
6. ✅ **`open-questions.md`** — Information gaps added as open questions for future sessions
