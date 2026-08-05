# ingest-aws

Query live AWS configuration via the AWS MCP server, compare against documented state, and distil findings into the wiki via the `wiki-ingest` pipeline.

## Instructions

---
name: ingest-aws
description: >
  Query live AWS configuration via the AWS MCP server and distil findings into the wiki.
  Use when the user says "/ingest-aws", "check AWS config", "query live AWS", or wants to
  validate findings against actual account state.
---

# ingest-aws

Query live AWS configuration via the AWS MCP server, compare against documented state, and distil findings into the wiki via the `wiki-ingest` pipeline.

## Usage

```
/ingest-aws <domain>
```

Where `<domain>` is one of: `organizations`, `security`, `networking`, `identity`

## What It Does

1. Queries the AWS MCP server for the specified domain
2. Writes raw API output to `docs/aws-config/{domain}/{date}-{resource}.md`
3. Compares live state against existing wiki knowledge (searches wiki for relevant pages)
4. Produces a structured discrepancy report
5. Hands off new/updated knowledge to **wiki-ingest** for placement (avoids hardcoding page names)
6. Captures discrepancies as findings in `deliverables/findings.md` if they represent gaps
7. Writes a summary report to `docs/aws-config/{domain}/{date}-summary.md`

## Domain Queries

### organizations
- `ListRoots` → org root and policy types
- `ListOrganizationalUnitsForParent` (recursive) → full OU hierarchy
- `ListAccounts` → all accounts with status and OU placement
- `ListPolicies` (SCP + TAG_POLICY) → all policies
- `DescribePolicy` → policy content for custom SCPs
- `ListPoliciesForTarget` → which policies attached to which OUs/accounts

### security
- `ListDetectors` / `GetDetector` → GuardDuty status per account
- `DescribeTrails` / `GetTrailStatus` → CloudTrail configuration
- `DescribeConfigRules` → Config rules deployed
- `GetComplianceDetailsByConfigRule` → compliance status

### networking
- `DescribeVpcs` → VPC CIDRs and configuration
- `DescribeSubnets` → subnet layout
- `DescribeRouteTables` → routing configuration
- `DescribeTransitGateways` → TGW topology
- `DescribeTransitGatewayRouteTables` → TGW routing
- `DescribeTransitGatewayAttachments` → TGW connections

### identity
- `ListInstances` → IAM Identity Center instance
- `ListPermissionSets` / `DescribePermissionSet` → permission sets
- `ListAccountAssignments` → who has access to what

## Wiki Integration

This skill does NOT hardcode specific wiki page names. Instead:

1. **Discovery phase:** Query the wiki (`wiki-query`) to find existing pages covering the domain topic
2. **Comparison:** Compare live AWS state against whatever the wiki documents
3. **Ingestion:** Pass structured findings to `wiki-ingest` which handles:
   - Page creation vs update decisions
   - Taxonomy placement (concepts/ vs entities/)
   - Cross-linking with existing pages
   - Frontmatter generation

This keeps ingest-aws portable — if wiki page names change, this skill doesn't break.

## Output Format

Raw output files use YAML frontmatter:
```yaml
---
source: "AWS MCP query"
queried_at: 2026-06-05T10:30:00Z
aws_profile: ${AWS_PROFILE}
domain: organizations
resource_type: accounts
---
```

## Discrepancy Reporting

When live state differs from wiki documentation, the summary report lists:
- Domain area
- What differs (resource, attribute)
- Wiki-documented value (or "not documented")
- Live value observed
- Severity assessment (discrepancy vs new discovery vs drift)

## Error Handling

- Auth errors → report "SSO session expired, run `aws sso login --profile $AWS_PROFILE`"
- Partial failures → complete successful queries, report failures in summary
- Server unreachable → report timeout, skip downstream processing

## Prerequisites

- AWS MCP server connected (check MCP panel)
- SSO session active (`aws sso login --profile $AWS_PROFILE`)
- Wiki pages exist for comparison (run after initial session ingestion)

---

## ⚠️ MANDATORY Completion Checklist

You MUST execute every item below before reporting success:

- [ ] Raw API output written to `docs/aws-config/{domain}/`
- [ ] Discrepancy report produced (`docs/aws-config/{domain}/{date}-summary.md`)
- [ ] New findings added to `deliverables/findings.md` (if discrepancies warrant)
- [ ] Wiki pages updated via `wiki-ingest` (or confirmed no changes needed)
- [ ] `log.md` appended with summary of what was queried and key findings
- [ ] `hot.md` updated if significant new knowledge was added
- [ ] Report to user: what was queried, what differs from documentation, what was ingested

