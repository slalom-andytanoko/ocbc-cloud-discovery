# review-feedback

Triage assistant for stakeholder feedback on published Confluence pages. Fetches comments, analyses them in context, proposes resolutions, and executes them with user confirmation.

## Instructions

---
name: review-feedback
description: >
  Review and triage stakeholder feedback from Confluence page comments. Analyses comments in context,
  proposes resolutions, and executes end-to-end (edit content, reply, resolve).
  Use when the user says "check for feedback", "any comments?", "review confluence comments",
  "triage comments", "check confluence", "stakeholder feedback", or "comments on our pages".
---

# review-feedback

Triage assistant for stakeholder feedback on published Confluence pages. Fetches comments, analyses them in context, proposes resolutions, and executes them with user confirmation.

## Commands

| Command | Description |
|---------|-------------|
| `check for feedback` | Fetch all open comments across published pages |
| `comments on [slug]` | Review comments on a specific page |
| `comments --open` | Only unresolved comments |
| `comments --dangling` | Inline comments whose anchored text no longer exists |

## How It Works

### 1. Fetch Comments

- Read `deliverables/confluence-staging/manifest.json` to find published pages (those with `confluencePageId`)
- For each target page:
  - Fetch inline comments via `getConfluencePageInlineComments` (resolutionStatus: open)
  - Fetch footer comments via `getConfluencePageFooterComments`
- Present count: "Found N open comments across M pages"

### 2. Present Each Comment

For each comment, display:
- **Page title** and **anchored text** (for inline comments — the selected text the comment is attached to)
- **Author** and **date**
- **Comment body** (what the stakeholder said)
- **Thread** (any existing replies)

### 3. Analyse and Propose Resolution

The agent reads the comment in context:
- What section of the page is it on?
- What does the staging markdown say in that area?
- Is this a correction, a question, a request for more detail, or a challenge?
- Does it relate to an existing finding, backlog item, or wiki page?

Then proposes one of:

| Resolution Type | What the agent does |
|-----------------|---------------------|
| **Content update** | Identifies the specific text to change in the staging .md file, shows the diff, applies if user agrees |
| **Clarification reply** | Drafts a reply explaining the rationale (e.g., "This is scoped to X because..."), posts via MCP if user agrees |
| **Scope/priority change** | Suggests updating the relevant backlog item or finding, shows the proposed change |
| **Already addressed** | Points out where in the current content the concern is already covered, drafts a reply saying so |
| **Out of scope** | Explains why, drafts a reply noting it's captured for future consideration |
| **Needs discussion** | Flags for team discussion, captures in `docs/team-input.md` with the commenter's context |

### 4. Execute Resolution (with user confirmation)

After the user chooses an action:

- **If content was updated:** Edit the staging .md file. The page state becomes `stale` (needs re-publish).
- **Reply to the commenter:** Post a reply via `createConfluenceFooterComment` or `createConfluenceInlineComment` (as a reply to the parent comment) explaining what was done.
- **Resolve the comment:** Mark as resolved in Confluence.
- **If captured as team input:** Append to `docs/team-input.md` in the standard format.
- **If backlog/finding updated:** Edit the relevant file and note the source.

### 5. Summary

After processing all comments:
```
Feedback Review Summary:
  Pages reviewed: 3
  Comments found: 7
  Resolved: 4 (2 content updates, 1 reply, 1 already addressed)
  Deferred: 2 (captured as team input)
  Skipped: 1
  Content changes: raid-log.md, gap-analysis-highlights.md (now stale — re-publish to update Confluence)
```

## Example Interaction

```
📝 Page: RAID Log
💬 Inline comment by Ton (2026-06-13) on "ServiceNow CMDB integration will be daily batch upload":
   "We confirmed with ND&Co this will use MID Server batch, not Service Graph Connector. Can you update?"
   Status: open

🔍 Analysis: The comment confirms assumption A1 with additional specificity.
   Current text says "daily batch upload" but doesn't mention the MID Server mechanism.
   This is a factual correction that should be incorporated.

📋 Proposed: Update raid-log.md A1 to read "daily batch upload via MID Server"
   and reply "Updated in next version — thanks for confirming."

   [Apply & Resolve] [Reply only] [Capture as team input] [Skip]
```

```
📝 Page: Gap Analysis Highlights  
💬 Footer comment by Julian (2026-06-14):
   "The priority for WAF/DDoS should be High not Medium — we've had incidents on the internal apps"
   Status: open

🔍 Analysis: Julian is challenging SEC25's priority rating. He has direct context
   as the security stakeholder. This aligns with team-commentary-authority rules
   (stakeholder input wins over automated analysis).

📋 Proposed:
   1. Update SEC25 backlog item priority: Medium → High
   2. Update gap-analysis-highlights.md table row
   3. Reply: "Agreed — updated to High based on your incident context."
   4. Capture as team commentary

   [Apply all] [Just capture] [Discuss with team] [Skip]
```

## Data Sources

- **Comments from:** Confluence pages tracked in `deliverables/confluence-staging/manifest.json`
- **Context from:** The staging .md files, backlog items, findings.md, team-input.md
- **Writes to:** Staging .md files, backlog items, team-input.md, Confluence (replies + resolution)

## MCP Tools Used

| Tool | Purpose |
|------|---------|
| `getConfluencePageInlineComments` | Fetch inline comments (with anchor text) |
| `getConfluencePageFooterComments` | Fetch footer comments |
| `createConfluenceInlineComment` | Post reply to inline comment thread |
| `createConfluenceFooterComment` | Post reply to footer comment |

## Triggers

This skill activates on:
- "check for feedback"
- "any comments?"
- "review confluence comments"
- "triage comments"
- "stakeholder feedback"
- "comments on our pages"
- "check confluence comments"
- "confluence feedback"

## Related Skills

- `publish-confluence` — owns the markdown → Confluence pipeline (this skill reads its manifest)
- `team-commentary` — captures team opinions (this skill can write to team-input.md)
- `discovery-deliverables` — generates the content that receives feedback

