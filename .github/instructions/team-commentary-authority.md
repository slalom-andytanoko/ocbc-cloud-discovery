---
applyTo: "**"
---
# Team Commentary Authority

## Rule: Team Commentary Is Non-Negotiable

`docs/team-input.md` contains team opinions, context, and corrections from people with direct engagement knowledge. This is the **highest-authority source** for deliverable generation — above automated analysis, above raw session transcripts, above Jira ticket descriptions.

### Mandatory Behaviour

1. **ALWAYS read `docs/team-input.md` BEFORE generating or updating any deliverable** — backlog items, findings, RAID, recommendations, presentations, workbooks, or architecture outputs.

2. **If team commentary contradicts a finding, backlog item, or estimate** — the commentary wins. Update the deliverable to reflect the commentary. Do not silently ignore it.

3. **If team commentary narrows scope** (e.g., "we're using MID Server batch, not Service Graph Connector") — the deliverable MUST reflect the narrower scope. Adjust effort estimates, deliverables lists, and action steps accordingly.

4. **If team commentary changes priority or sequencing** (e.g., "NET2 is not a blocker for first workload") — update priority, phase assignment, and sequencing tables.

5. **If team commentary adds an assumption** — add it to `deliverables/raid.md` Assumptions table immediately.

6. **Cross-reference check**: When updating any specific backlog item, grep `docs/team-input.md` for that item's ID (e.g., `OPS12`, `NET2`) or topic keywords. If commentary exists, incorporate it.

### Why This Matters

Automated analysis produces findings from code review and session transcripts — but the discovery team has context that no automation can infer. They know what the client actually said informally, what scope was narrowed in side conversations, and what the real implementation approach will be. Ignoring this context produces deliverables that are technically correct but practically wrong.

### Conflict Resolution Order

When sources disagree, priority order is:

1. **Team commentary** (`docs/team-input.md`) — highest authority
2. **Session transcripts** (direct stakeholder quotes)
3. **Wiki concept/entity pages** (distilled from sessions)
4. **Jira tickets** (may be stale or over-scoped)
5. **Automated analysis** (IaC review, gap analysis tooling)

### Jira Ticket Count Does NOT Inflate Priority

The HA backlog contains many aspirational items. Having Jira tickets related to a finding does NOT make it High priority. Priority must be determined independently by:

1. **Active risk exposure** — is there a live vulnerability or compliance violation right now?
2. **Blocks workload onboarding** — can teams deploy their first workload without this?
3. **Explicit stakeholder urgency** — did someone in a discovery session say "we need this before X"?

If a backlog item's only evidence for High priority is "there are Jira tickets for it" — that's Medium at best. Many HA tickets are roadmap aspirations logged for tracking, not urgent needs.

Similarly: items that are "nice to have for operational maturity" (automated incident routing, proactive drift detection, etc.) are Medium unless a stakeholder explicitly said they block first-workload readiness.

### For Agents

- If you generate a backlog item or update a finding without checking team commentary first, you have produced an unreliable output.
- When team commentary suggests an effort estimate change, recalculate using the estimation model with the corrected scope (don't just manually override the number).
- Attribution: when a deliverable reflects team commentary, note it in Internal Notes (e.g., "Scope narrowed per team commentary 2026-06-05").
