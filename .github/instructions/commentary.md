---
name: commentary
description: >
  Capture and structure team opinions, observations, and contextual input that should influence
  wiki content and deliverables. Provides a low-friction way for consultants to contribute their
  expertise without editing wiki pages directly.
  Use when the user says "/commentary", "add team input", "team opinion", "I think...",
  "we should note that...", or when a team member wants to record an observation about
  a finding, wiki page, or architectural decision.
---

# Team Commentary — Structured Team Input

You are helping the consulting discovery team capture opinions, observations, and contextual knowledge that should influence the wiki and deliverables. This is the human judgment layer that complements the factual wiki content.

## Purpose

The wiki captures *what we know* from sessions, code, and docs. Team commentary captures *what we think* — professional opinions that should shape severity ratings, recommendation tone, and priority.

Examples:
- "F2 is the one the client will resist — needs stronger justification"
- "The legacy accounts (F7) are less risky than they look because Azure covers them"
- "Based on my experience, the primary workload migration timeline will slip — plan for delay"
- "The China requirements are aspirational — don't over-invest there yet"

---

## File Location

`docs/team-input.md` — a single shared file for the whole team.

---

## How to Add Commentary

When a team member wants to record input, append an entry to `docs/team-input.md`:

**Identifying the user:** Read `WIKI_USER` from `.env` to get the current user's name/alias. If not set, fall back to parsing the home directory path and matching against the domain glossary. If neither works, ask who is providing the commentary.

```markdown
### <date> — <person>

**Context:** <what this relates to — [[finding ID]], [[wiki page]], open question, or topic>
**Input:** <the opinion, observation, or context>
**Impact:** <how this should influence deliverables — e.g., "upgrade severity", "soften recommendation", "add as risk in RAID">
```

Use `[[wikilinks]]` in entries to cross-reference wiki pages, findings, and open questions. This makes the commentary discoverable in Obsidian's graph view and backlinks panel.

### Entry Types

| Type | When to use | Example |
|------|------------|---------|
| Severity adjustment | Team disagrees with a finding's rating | "F12 should be MRI not IMP — the client mentioned pharma workloads coming soon" |
| Context / nuance | Team has information not in session transcripts | "The client has a history of resisting OU restructures — frame as risk, not mandate" |
| New observation | Team spots something not captured anywhere | "The lack of a break-glass procedure isn't documented but came up informally with the security lead" |
| Priority signal | Team thinks something should be higher/lower in the backlog | "Encryption SCP (F14) should be immediate — it's a compliance requirement, not just best practice" |
| Recommendation refinement | Team wants to adjust how we frame a recommendation | "Don't recommend splitting the Aggregator (F6) — the client doesn't have the team to manage two accounts" |
| Dependency / blocker | Team knows about something blocking progress | "The CSPM decision is waiting on budget approval — nothing we can do to accelerate" |

---

## How This Feeds Into the Workflow

```
docs/team-input.md
     │
     ├── wiki-query reads it → influences answers about "what do we think"
     ├── gap-analysis reads it → calibrates severity ratings
     ├── discovery-deliverables reads it → adjusts backlog priority, RAID entries, recommendation tone
     └── findings refresh reads it → updates severity/status based on team consensus
```

### Rules for Consuming Commentary

When generating deliverables or updating the wiki:

1. **Read `docs/team-input.md`** as a first-class source alongside sessions and findings
2. **Team opinions take precedence** over auto-generated severity when they provide specific reasoning
3. **Don't silently override** — if commentary contradicts a finding, note both perspectives and which was adopted
4. **Attribution matters** — keep the person's name attached when their expertise is the basis for a judgment call

---

## Prompting the Team

When asking the team for input (e.g., during a review session), use prompts like:

- "Looking at F1–F13, do any severities feel wrong based on what you've seen?"
- "Are there findings we should add that didn't come from sessions? Things you noticed?"
- "Which recommendations will the client push back on? How should we frame them?"
- "Are there dependencies or timelines we're not capturing?"

---

## File Structure

```yaml
---
title: Team Commentary
category: meta
tags: [team-input, opinions]
updated: <today>
---
```

Entries are chronological, newest at the top. Each entry has a date, person, context reference, input, and impact statement.

---

## Creating the File

If `docs/team-input.md` doesn't exist, create it with this template:

```markdown
---
title: Team Commentary
category: meta
tags: [team-input, opinions]
updated: 2026-06-02
---

# Team Commentary

Shared log of team opinions, observations, and contextual input that should influence the wiki and deliverables. Append entries below — newest first.

---

## How to Add an Entry

```
### YYYY-MM-DD — Name

**Context:** [finding ID / wiki page / topic]
**Input:** [your observation or opinion]
**Impact:** [how this should affect deliverables]
```

---

## Entries

<!-- Add new entries below this line, newest first -->
```

---

## Quality Signals

Good commentary is:
- **Specific** — references a finding ID, wiki page, or concrete topic
- **Actionable** — states what should change (severity, tone, priority)
- **Attributed** — has a name attached (accountability for the judgment)
- **Justified** — gives a reason ("because...", "based on...", "in my experience...")

Bad commentary:
- "I think security is important" — too vague
- Unsigned entries — can't weight expertise
- Contradicts without reasoning — "F2 is wrong" vs "F2 should be MRI because the client already has IAM Identity Center for access separation"
