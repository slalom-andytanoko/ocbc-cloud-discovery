# Project Context: OCBC Cloud discovery engagement for OCBC covering AWS environments

## What This Repo Is

This is a knowledge vault for the OCBC Cloud discovery engagement for OCBC covering AWS environments engagement. Cloud discovery engagement for OCBC covering AWS environments

The output of this work is:
- A structured wiki of decisions, patterns, and findings
- A prioritised backlog of changes
- Documented gaps between current state and desired state

## How Discovery Works

We run discovery sessions with OCBC stakeholders covering topics relevant to the engagement scope. Each session produces raw notes and transcripts that get processed into wiki knowledge.

## Repo Structure

- `TASKS.md` — **Central task tracker.** Read this at the start of every session to understand current state, blockers, and ownership. Update it when completing tasks or discovering new blockers.
- `docs/` — Raw source material (session transcripts, notes, repos of interest)
- `docs/sessions/` — Per-session folders with transcripts and notes
- `_meta/` — Taxonomy and metadata
- `_raw/` — Staging area for unprocessed wiki drafts
- `index.md` — Wiki page index
- `hot.md` — Recent activity tracker
- `log.md` — Operation log
- `.skill-repos/` — External skill sources (git submodules)
- `.kiro/skills/` — Copied skills for discovery
- `.kiro/steering/` — This context and other steering files

## Key Domain Concepts

aws, security

<!-- Domain concepts above are populated based on activated skill packs during setup. -->
<!-- Add engagement-specific terms below as they emerge during discovery. -->

### External / Proprietary Documents (`external/`)

The `external/` folder contains proprietary documents that are **gitignored and must never be committed**. These are reference materials (e.g., client-provided docs, vendor assessments) that can inform our analysis but:

- **Never reproduce verbatim** in wiki pages or deliverables
- **Always ask for human confirmation** before reading (enforced by hook)
- **Only distilled insights** (paraphrased, attributed) may be written to the wiki
- Source attribution: reference as "External: <filename>" without quoting content

## Source Attribution & Cross-References

When ingesting content from external sources (Confluence, sessions, repos), always include a traceable link back to the original:

- **Confluence pages:** Use the `ingest-confluence` skill which handles fetching, saving, staleness detection, tracker updates, and wiki distillation. Include the full URL in the `source:` frontmatter field.
- **Session transcripts:** Include session number and file path (e.g., `source: "docs/sessions/Session 2 - Topic/transcript-clean.md"`)
- **IaC repos:** Include the GitHub URL to the specific file on the deploy branch. See `docs/repos/README.md` for the repo → branch mapping.
  - **For findings:** Use commit-pinned links (`/blob/{SHA}/...`) so the evidence is preserved even if the code changes later.
  - **For wiki concept pages:** Use branch links (`/blob/{BRANCH}/...`) so they always show the current deployed state.
- **Multiple sources:** Use a list in frontmatter: `sources: ["url1", "session 2", "repo/file"]`

This gives every claim in the wiki a provenance trail. When someone asks "where did this come from?", the source field answers it immediately.

### In findings.md

Each finding's "Source" column should be specific enough to trace back:
- Bad: "Confluence"
- Good: "Confluence: Solution Design (SPACE/pageId) §section"

## Findings & Discrepancies

When you discover a discrepancy, security issue, gap, or inconsistency during any activity, add it to `deliverables/findings.md` immediately. See the `discovery-deliverables` skill for the full findings register format, severity levels, and source attribution rules.

## Discovery Outputs & Post-Discovery Backlog

This discovery does NOT implement changes. It produces a prioritised backlog of work to be done immediately after discovery concludes. Key outputs that feed the backlog:

- **Gap analyses** — each gap becomes a backlog item with severity and effort estimate
- **Open questions** — unresolved questions in `open-questions.md` may become backlog items if they block implementation

## Task Completion Checklist

When a task is finished, update these files before considering it done:

1. **`TASKS.md`** — Move the task from "Active Work" to "Completed" with the completion date. If the task unblocks upcoming work, note that. Update the "Last updated" date at the top.
2. **`log.md`** — Append a timestamped entry describing what was done (e.g. "Ingested Session 2 transcript → 4 new wiki pages created").
3. **`hot.md`** — Update recent activity to reflect the new work.
4. **`index.md`** — Add any new wiki pages created during the task.
5. **`.manifest.json`** — Update if new source files were ingested (tracks what's been processed).
6. **`TASKS.md` Blockers table** — Resolve any blockers that are no longer relevant. Check if completing this task unblocks other tasks.

### Skill Completion Checklists

If a skill defines a `⚠️ MANDATORY Completion Checklist` section, you MUST execute every item in it before reporting success. Do not skip checklist items even if they seem redundant — they exist because they've been missed before.

### When to skip

- `index.md` / `.manifest.json` — only if the task produced new wiki pages or ingested new sources
- `hot.md` — only if the task produced visible wiki changes

### Principle

If an agent completes work but doesn't update the tracker, the next session starts confused. Always leave the project state accurate.

## User Identity

The current user's name/alias is defined in `.env` as `WIKI_USER`. Use this for:
- Team commentary attribution
- Commit message context
- Any action that requires knowing "who is doing this"

If `WIKI_USER` is not set, fall back to the home directory username and match against the domain glossary's Known Speakers table.

## Self-Referencing Vault

This repo IS the Obsidian vault (`OBSIDIAN_VAULT_PATH` = repo root). The `.manifest.json` has `"self_referencing": true`. When running `wiki-update`:

- **Skip project overview page creation** — don't create a project overview page. The steering files serve that purpose.
- **Still do** delta tracking, cross-linking, hot.md/log.md updates, and manifest sync.

This pattern applies to all discovery repos based on this template.
