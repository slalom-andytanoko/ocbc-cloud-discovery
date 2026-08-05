---
name: publish-confluence
description: >
  Publish discovery deliverables to Confluence as structured pages.
  Converts markdown to ADF JSON and pushes via Atlassian MCP.
  Tracks publish state and attachment hashes in manifest.json.
  Use when the user says "publish to confluence", "push to confluence",
  "update confluence pages", "sync deliverables", or "confluence status".
  Also triggers on "publish raid", "publish backlog", "publish current state",
  "publish gaps", "/deliverables confluence", "save confluence".
---

# publish-confluence

Publishes discovery deliverables to Confluence. Markdown source files are
converted directly to ADF (Atlassian Document Format) JSON and pushed via
the Atlassian MCP.

## Architecture

```
Markdown Source
    ↓ md_to_adf()
ADF JSON
    ↓ MCP updateConfluencePage(contentFormat='adf')
Confluence
    ↕
manifest.json (page IDs, publish state, attachment MD5 hashes)
```

Single script: `./scripts/publish.py`

## When REST Credentials Are Needed

**REST credentials are only required when uploading changed attachment files.**

| Scenario | REST needed? |
|---|---|
| Page body changed, no attachments | No — MCP only |
| Attachment file changed on disk (new MD5) | Yes — upload via REST |
| Attachment file unchanged (same MD5 as last publish) | No — skip upload, use cached UUID |
| Brand-new page (first publish) | Yes — create page + upload any attachments |

`.env` must contain `CONFLUENCE_EMAIL` and `CONFLUENCE_API_TOKEN` only if any
attachment has changed. Pages without attachments (raid-log, gap-analysis-highlights)
never need REST credentials after the first publish.

## Credential Setup (one-time)

Add to `.env`:
```
CONFLUENCE_EMAIL=your.email@slalom.com
CONFLUENCE_API_TOKEN=your-api-token-here
```
Generate token: https://id.atlassian.com/manage-profile/security/api-tokens

## How Attachments Work

**Upload (REST — ECO-1361):**
The Atlassian MCP has no file upload tool. Changed files are uploaded via
REST multipart POST to `/rest/api/content/{page_id}/child/attachment`.

**MD5 skip:** After upload, the file's MD5 hash is stored in `manifest.json`
under `_assetState[].lastMd5`. On the next publish, if the file hasn't changed,
the upload is skipped and the cached media UUID is reused.

**UUID lookup (MCP — no credentials):**
After uploading, the media UUID is fetched via MCP `searchConfluenceUsingCql`:
```
CQL: type=attachment AND title="file.png" AND container="PAGE_ID"
expand: extensions
→ extensions.fileId      (media UUID for ADF mediaSingle node)
→ extensions.collectionName
```

## ADF vs HTML

All pages use `contentFormat: "adf"` (Atlassian Document Format JSON).

Why not HTML mode (`contentFormat: "html"`)?
- ADF is Confluence's native format — no translation layer.
- Inline marks (bold, italic, code, links) are preserved inside table cells
  and list items, which the HTML→ADF conversion loses.
- `viewpdf`, `viewxls`, `toc` and other macros work as ADF `extension` nodes —
  no REST-only path needed for any page.

## Macro Support (viewpdf, viewxls, toc, expand)

Macros are expressed as ADF `extension` nodes:
```json
{
  "type": "extension",
  "attrs": {
    "extensionType": "com.atlassian.confluence.macro.core",
    "extensionKey": "viewpdf",
    "parameters": {"macroParams": {"name": {"value": "file.pdf"}}},
    "layout": "default"
  }
}
```
Declare them in `manifest.json` under `attachments[].macro`.

## Manifest (`manifest.json`)

Source of truth for page IDs, states, and attachment hashes.
Committed to git.

```json
{
  "spaceKey": "<read CONFLUENCE_SPACE_KEY from .env>",
  "parentPageTitle": "<Parent page title in Confluence>",
  "parentPageId": "<parent page ID>",
  "cloudId": "<read CONFLUENCE_CLOUD_ID from .env>",
  "pages": {
    "architecture-overview": {
      "title": "Architecture Overview",
      "sourceFile": "architecture-overview.md",
      "confluencePageId": "4446879753",
      "state": "published",
      "lastPublished": "2026-06-16T00:00:00Z",
      "assets": [
        {
          "filename": "current-state.png",
          "sourcePath": "deliverables/designs/images/current-state.png",
          "type": "image"
        }
      ],
      "attachments": [],
      "_assetState": [
        {
          "filename": "current-state.png",
          "lastMd5": "abc123...",
          "media_id": "ffa674b4-...",
          "collection": "contentId-4446879753"
        }
      ]
    },
    "landing": {
      "title": "AWS Landing Zone Discovery",
      "sourceFile": "landing.md",
      "confluencePageId": "4440555523",
      "state": "published",
      "assets": [],
      "attachments": [
        {
          "filename": "discovery-assessment.pdf",
          "sourcePath": "deliverables/confluence-staging/.generated/discovery-assessment.pdf",
          "macro": "viewpdf",
          "macroParams": {"data-layout": "full-width"}
        }
      ]
    }
  }
}
```

### Page state machine

```
local           → first time the .md file exists
local + publish → published
published + md edit → stale  (set manually or by save workflow)
stale + publish → published
```

## Agent Publish Workflow

```python
plans = get_publish_plan()   # from publish.py

for plan in plans:
    # Step 1: new page
    if plan['is_new']:
        result = mcp.createConfluencePage(spaceId, parentId, plan['title'])
        plan['page_id'] = result['id']

    # Step 2: upload changed files only (REST — needs credentials)
    if plan['needs_rest']:
        for asset in plan['changed_files']:
            upload_file(plan['page_id'], REPO_ROOT / asset['sourcePath'])
            # returns MD5 for manifest update

    # Step 3: fetch UUIDs for images (MCP — no credentials)
    for asset in plan['image_assets']:
        result = mcp.searchConfluenceUsingCql(
            cql=f'type=attachment AND title="{asset["filename"]}" AND container="{plan["page_id"]}"',
            expand='extensions'
        )
        info = parse_attachment_uuid_from_cql_result(result, asset['filename'])

    # Step 4: rebuild ADF with real UUIDs
    adf = md_to_adf(plan['md_text'], real_image_info, plan['macro_attachments'])

    # Step 5: publish (MCP — no credentials)
    mcp.updateConfluencePage(
        pageId=plan['page_id'],
        contentFormat='adf',
        body=json.dumps(adf)
    )
```

## Markdown Syntax Reference

| Markdown | Confluence output |
|---|---|
| `:::info` ... `:::` | Info panel (blue) |
| `:::warning` ... `:::` | Warning panel (yellow) |
| `:::note` ... `:::` | Note panel (purple) |
| `:::success` ... `:::` | Success panel (green) |
| `:::error` ... `:::` | Error panel (red) |
| `:::viewpdf path/to/file.pptx:::` | Inline PDF viewer (full-width). Path is relative to staging dir, resolved via manifest sourcePath. PPTX/DOCX auto-converted to PDF before upload. |
| `:::viewxls path/to/workbook.xlsx:::` | Inline Excel viewer. Path resolved via manifest sourcePath. |
| `![alt](filename.png)` | Embedded image (mediaSingle) |
| `[text](path/to/attachment.pptx)` | Download link — resolved to Confluence attachment URL. Path matched against manifest sourcePaths by basename. |
| `**bold**` | Strong mark |
| `*italic*` | Em mark |
| `` `code` `` | Code mark |
| `[text](url)` | Link mark |
| `` ```python `` code block | Code block node |
| `> blockquote` | Note panel |
| `\| table \|` | Table node |

### Macro markers: what they look like in the page

Macro markers (`:::viewpdf:::`, `:::viewxls:::`) are the canonical way to declare
inline file viewers. They appear in the markdown exactly where they will appear in
Confluence. The manifest declares which file to upload and what filename it gets —
the markdown declares where and how it renders.

**Pattern:**
```markdown
[⬇ Download PDF](../../discovery-assessment.pptx)

:::viewpdf ../../discovery-assessment.pptx:::
```

The download link gives users a fallback. The `:::viewpdf:::` marker below it
renders the inline viewer. Both reference the same source path. The publisher:
1. Resolves the path via manifest `sourcePath` → `filename`
2. Auto-converts PPTX → PDF if needed (mtime check)
3. Uploads the PDF as a Confluence attachment
4. Renders the `:::viewpdf:::` as an ADF extension node
5. Resolves the download link to `/download/attachments/{page_id}/{filename}`

## CLI Reference

```
python publish.py --slug architecture-overview    # one page
python publish.py --all                           # all stale pages
python publish.py --all --dry-run                 # preview, no writes
python publish.py --slug gap-analysis-highlights --force  # force republish
```

## MCP Tools Used

| Tool | Purpose | Credentials? |
|------|---------|---|
| `createConfluencePage` | New page creation | No (MCP OAuth) |
| `updateConfluencePage` | Publish ADF body | No (MCP OAuth) |
| `searchConfluenceUsingCql` | UUID lookup for attachments | No (MCP OAuth) |
| `getConfluencePage` | Read page content/version | No (MCP OAuth) |

## Staging Directory

```
deliverables/confluence-staging/
├── *.md           ← Markdown source (one per Confluence page)
├── manifest.json  ← Page IDs, states, attachment MD5 hashes
└── .generated/    ← Debug output — gitignored
```

## Related Skills

- `discovery-deliverables` — generates the markdown this skill publishes
- `ingest-confluence` — reads FROM Confluence (inverse of this skill)
- `generate-architecture` — produces architecture diagram attachments
