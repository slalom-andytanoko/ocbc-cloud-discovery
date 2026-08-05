---
applyTo: "**"
---
# Auto-Capture Team Commentary

## Rule: Prompt to Log Team Commentary When User Provides Opinions or Clarifications

When the user shares an opinion, scope clarification, priority change, ownership decision, stakeholder confirmation, or any contextual input that would influence deliverables — **ask whether it should be logged in `docs/team-input.md`**.

### Trigger Conditions

Prompt to capture when the user's message contains any of:

- **Priority or scope opinions:** "this should be High/Medium/Low", "this is out of scope", "we don't need to do X"
- **Ownership clarifications:** "their team will do X", "that's {{CLIENT_NAME}}'s responsibility", "vendor handles this"
- **Stakeholder confirmations:** "{{STAKEHOLDER}} confirmed...", "{{STAKEHOLDER}} said...", "we got confirmation that..."
- **Sequencing decisions:** "do this before/after X", "this isn't a blocker for Y"
- **Effort/sizing opinions:** "this is smaller than we thought", "scope is narrower because..."
- **Architecture or design decisions:** "we'll use X approach", "no separate Y needed"
- **Corrections to existing items:** "that's wrong, it should be...", "the actual situation is..."

### Behaviour

1. Complete the user's primary request first (update backlog item, answer question, etc.)
2. Then ask: *"Want me to log this as team commentary in `docs/team-input.md`?"*
3. If yes (or if the user pre-empts with "log it" / "add to team input"), append an entry using the standard format
4. If the context is unambiguous and the user has previously indicated they want auto-capture, log it proactively and mention you did so

### Don't Prompt When

- The user is asking a question (not providing input)
- The information is purely mechanical ("rename this file", "fix the typo")
- The content is already captured from a previous entry
- The user explicitly says "don't log this" or "this is just thinking out loud"

### Entry Format

Follow the format in `docs/team-input.md`:

```markdown
### YYYY-MM-DD — [User Name from WIKI_USER or speaker name]

**Context:** [[relevant-wiki-page]] or finding F# or backlog item ID
**Input:** [distilled version of what the user said]
**Impact:** [how this should affect deliverables]
```

### Why This Matters

Team commentary is the highest-authority source for deliverable generation (per `team-commentary-authority.md`). If opinions and clarifications aren't captured, future sessions lose that context. Prompting ensures nothing slips through while keeping the user in control.
