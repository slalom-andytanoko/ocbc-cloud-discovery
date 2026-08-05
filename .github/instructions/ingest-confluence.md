---
name: ingest-confluence
description: >
  Fetch Confluence pages via the Atlassian MCP server and distill their content into the Obsidian wiki.
  Handles deduplication, staleness detection, tracker updates, and wiki page creation.
  Use when the user says "/ingest-confluence <url>", "ingest this confluence page",
  "pull this from confluence", "add this confluence page to the wiki", or provides a Confluence URL.
  Also triggers on "fetch from confluence", "ingest confluence", "pull from confluence".
---

# Confluence Ingest — Atlassian Page Distillation

You are fetching Confluence pages via the Atlassian MCP server and distilling their content into the Obsidian wiki. This skill handles the full lifecycle: fetch, save, track, flag staleness, and distill into wiki pages.

## Content Trust Boundary

Confluence content is **semi-trusted** (internal documentation) but may be outdated, draft, or superseded. Treat it as input to synthesise, not ground truth. Always check `last_modified` dates and flag stale content.

---

## Before You Start

1. **Resolve config** — read `.env` for `OBSIDIAN_VAULT_PATH`
2. **Check MCP availability** — confirm the Atlassian MCP server is connected (try `atlassianUserInfo` if unsure)
3. **Read tracker** — read `docs/confluence/README.md` to check what's already been fetched
4. **Read `.manifest.json`** — check if this page was already ingested into wiki pages
5. **Read `index.md`** — understand existing wiki content for cross-linking

---

## Step 1: Parse the Input

Accept input in these forms:
- Full URL: `https://<client>.atlassian.net/wiki/spaces/<SPACE_KEY>/pages/3863674904/Page+Title`
- Page ID: `3863674904`
- Tiny link: `/wiki/x/Fc1bBw`
- Search query: "find the page about X" → use `search` tool first

Extract:
- **Page ID** — from URL path (`/pages/{pageId}/`) or provided directly
- **Cloud ID** — read `CONFLUENCE_BASE_URL` from `.env` to derive the site hostname (e.g., `client.atlassian.net`)

---

## Step 2: Check for Duplicate

Before fetching, check if this page ID already exists in `docs/confluence/README.md`:
- If found and `Wiki Pages Created` is not "pending": report what was already created, offer to re-ingest
- If found and "pending": skip fetch, proceed to distillation (Step 5)
- If not found: proceed to fetch

---

## Step 3: Fetch the Page

Use the Atlassian MCP `getConfluencePage` tool:
```
cloudId: "<read CONFLUENCE_BASE_URL from .env — use hostname, e.g. client.atlassian.net>"
pageId: "<page_id>"
contentFormat: "markdown"
```

From the response, extract:
- `title` — page title
- `spaceId` / space key — which Confluence space
- `version.createdAt` — last modified date
- `version.number` — version count
- `body` — the markdown content

### Check for Children and Related Pages

After fetching the page, **always check for child pages**:

```
getConfluencePageDescendants(cloudId, pageId, depth=2)
```

If children exist:
1. **List them for the user** with count and titles
2. **Assess relevance** — are these supporting detail (e.g., individual pattern definitions under a catalog), or unrelated subpages?
3. **Recommend batch ingest** if children contain actionable content (security patterns, individual designs, procedures)
4. **At minimum**, note the children's existence in the raw saved file and in the wiki page (e.g., "This page has N child pages covering individual pattern definitions")

Also scan the page body for links to other Confluence pages. If any linked pages appear highly relevant to the discovery (architecture docs, security controls, network designs), mention them to the user as candidates for ingestion.

### Staleness Check

Compare `version.createdAt` to today's date:
- **< 3 months old:** Current — proceed normally
- **3–6 months old:** Add `notes:` field: "⚠️ Last modified {date} — may be outdated. Verify with team."
- **> 6 months old:** Add `notes:` field: "⚠️ Document last modified {date} — predates current engagement. Plans may have evolved. Confirm relevance with team."

---

## Step 4: Save Raw Content

Save to `docs/confluence/<SPACE_KEY>/<slug>.md` with this frontmatter:

```yaml
---
source: confluence
page_id: "<page_id>"
space: "<space_key>"
title: "<page title>"
url: "<full confluence URL>"
version: <version_number>
last_modified: "<ISO-8601 from version.createdAt>"
fetched: "<today YYYY-MM-DD>"
notes: "<staleness warning if applicable>"
---
```

### Slug Generation

From the page title:
1. Lowercase
2. Replace spaces with `-`
3. Remove special characters except `-`
4. Collapse consecutive `-`
5. Cap at 60 characters
6. Prefix with `aws-` if the title starts with "AWS -" (strip the "AWS -" prefix from the slug body)

Examples:
- "Solution Design: DRAFT: AWS Cloud Platform" → `solution-design-aws-cloud-platform`
- "AWS - Deploy Account Factory for Terraform Module (AFT)" → `aws-deploy-account-factory-for-terraform-module-aft`

### Content Cleaning

Before saving the body:
- Remove Confluence blob image references (they can't be rendered outside Confluence)
- Replace `![](blob:...)` with `<!-- image: [description if available] -->`
- Remove empty sections with no content
- Preserve tables, code blocks, and structural headings

---

## Step 5: Update Tracker

Append a row to `docs/confluence/README.md`:

```markdown
| <next#> | <title> | <space> | <page_id> | <fetched_date> | <last_modified> | pending ingest |
```

If the page was already in the tracker (re-fetch), update its `Fetched` and `Last Modified` columns.

---

## Step 6: Distill into Wiki Pages

This step mirrors what `ingest-url` does (see `the ingest-url skill` for the full pattern), adapted for Confluence content:

### Determine Target

Confluence pages typically map to:
- **Reference pages** (`reference/`) — solution designs, RFIs, formal documents
- **Concept pages** (`concepts/`) — architectural patterns, processes, decisions
- **Entity pages** (`entities/`) — specific services, tools, systems

### Extract Knowledge

From the fetched content, identify:
- **Core topic** — what is this page fundamentally about?
- **Key claims/decisions** — the most important assertions
- **Architecture details** — diagrams, tables, configurations
- **Requirements** — functional/non-functional requirements
- **Open items** — things flagged as TBD, pending, or unresolved
- **Cross-references** — links to other Confluence pages or external systems

### Write Wiki Page(s)

Follow wiki conventions:
- YAML frontmatter with `source:` pointing to the Confluence URL
- kebab-case filenames
- Obsidian wikilinks `[[like-this]]`
- One concept per page — split large Confluence pages into multiple wiki pages if they cover distinct topics
- `visibility: visibility/internal` on all pages

**Source attribution:** Always include the full Confluence URL in the `source:` frontmatter field:
```yaml
source: "<CONFLUENCE_BASE_URL from .env>/spaces/<CONFLUENCE_SPACE_KEY>/pages/<page_id>"
```

### Deduplication

Before creating a new wiki page:
1. Check if an existing page already covers this topic (search `index.md`)
2. If yes: **update** the existing page with new information from Confluence, noting the additional source
3. If no: create a new page

### Findings

If the Confluence page reveals discrepancies, security issues, or gaps:
1. Add them to `findings.md` immediately (per steering rules)
2. Use commit-pinned Confluence URLs as the source link

---

## Step 7: Capture Findings

After distillation, scan the ingested content for discrepancies, security issues, gaps, or inconsistencies:

1. **Look for:** missing controls, public exposures, legacy infrastructure creating risk, contradictions with existing wiki, unencrypted resources, ungoverned accounts, outdated software
2. **For each finding**, append to `deliverables/findings.md`:
   - Assign ID (next F# in sequence)
   - Severity (HRI / MRI / IMP)
   - Source: Confluence page URL with section reference
   - Add a detail section with Risk and Recommendation
3. **Update the summary count** at the bottom of findings.md

This step is mandatory — even "informational" Confluence pages can reveal gaps (e.g., a legacy DC with a public IP, or an outdated OS approaching end of support).

---

## Step 8: Update Manifest and Index

**`.manifest.json`** — add entry:
```json
"docs/confluence/<slug>.md": {
  "hash": "ingested-<date>",
  "mode": "full",
  "ingested_at": "<ISO-8601>",
  "confluence_page_id": "<page_id>",
  "confluence_space": "<space_key>",
  "pages_created": ["<path1>", "<path2>"],
  "pages_updated": ["<path3>"]
}
```

**`index.md`** — add new pages under appropriate sections

**`docs/confluence/README.md`** — update the "Wiki Pages Created" column from "pending ingest" to the actual pages created/updated

---

## Step 9: Report to User

```
## Confluence Page Ingested

**Source:** [<title>](<confluence_url>)
**Space:** <space_key> | **Version:** <version> | **Last Modified:** <date>
**Staleness:** <current / potentially outdated / predates engagement>

**Saved to:** docs/confluence/<slug>.md

**Wiki pages created/updated:**
- <list of pages with brief descriptions>

**Findings discovered:** <count, or "none">
```

---

## Batch Mode

When asked to ingest multiple pages (e.g., "ingest all children of page X"):

1. Use `getConfluencePageDescendants` to list child pages
2. Filter to `type: "page"` (skip embeds, whiteboards)
3. Present the list to the user with relevance assessment
4. After user confirms, process each page through Steps 3–7
5. Single tracker update at the end

---

## Handling Child Pages / Page Trees

When the user provides a parent page URL:
1. Fetch the parent page content
2. Use `getConfluencePageDescendants` to discover children
3. Assess relevance of each child (title-based heuristic)
4. Present the tree with recommendations
5. User selects which to ingest

---

## Error Handling

| Error | Action |
|-------|--------|
| Page not found (404) | Report to user; check if it's an embed/whiteboard type |
| MCP connection lost | Advise user to restart MCP server (OAuth token may have expired) |
| Embed type (not fetchable) | Note in tracker as "embed — not fetchable via page API" |
| Content too large (>100KB) | Extract key sections only; note truncation in frontmatter |

---

## Quality Checklist

- [ ] Page ID and URL correctly recorded in frontmatter
- [ ] `last_modified` date checked and staleness noted
- [ ] `docs/confluence/README.md` tracker updated
- [ ] Content cleaned (blob images removed, empty sections stripped)
- [ ] Wiki pages created with correct source attribution
- [ ] At least 2 wikilinks to existing pages in each new wiki page
- [ ] `.manifest.json` updated with pages_created/pages_updated
- [ ] `index.md` updated with new pages
- [ ] Findings added to `findings.md` if discrepancies found
- [ ] No Confluence-internal formatting artifacts in wiki pages


---

## ⚠️ MANDATORY Completion Checklist

**You MUST complete ALL items below before reporting success to the user. Do NOT skip any step.**

1. ✅ **`docs/confluence/README.md`** — Tracker row added/updated with page title, space, page ID, fetch date, and wiki pages created
2. ✅ **`.manifest.json`** — Source entry added with `pages_created` and `pages_updated` arrays
3. ✅ **`index.md`** — All new wiki pages listed under their appropriate sections (Concepts, Entities, Reference)
4. ✅ **`hot.md`** — Recent Activity updated with today's date and pages created/updated
5. ✅ **`log.md`** — Timestamped entry appended (e.g., "2026-06-05 — Confluence ingest: Solution Design → reference/solution-design-aws-cloud-platform.md")
6. ✅ **`deliverables/findings.md`** — Any discrepancies or gaps discovered during distillation added as findings with severity and source

**If you skip these steps, the wiki state will drift and the next session will start with stale context.**
