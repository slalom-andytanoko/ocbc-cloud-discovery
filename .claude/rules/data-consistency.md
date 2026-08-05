# Data Consistency & Source of Truth

## Rule: Single Source of Truth for Backlog Data

Backlog item metadata (priority, effort, phase, topic, status) lives in ONE place: the item's frontmatter file in `deliverables/backlog/items/`. Everything else either queries it dynamically or references it as a point-in-time snapshot.

### Live Pages (Always Current)

These pages use Dataview queries and read frontmatter directly — they never go stale:

| Page | Mechanism |
|------|-----------|
| `deliverables/backlog/index.md` | Dataview tables + dataviewjs |
| Backlog item files themselves | Frontmatter is the source |
| `deliverables/estimation-config.yaml` | Phase assignments (canonical) |

**Rule:** Never hardcode effort numbers, priorities, or item counts in these files — let Dataview compute them.

### Snapshot Pages (Point-in-Time)

These embed backlog data in prose for narrative or client-facing purposes. They represent a deliberate point-in-time view and MAY drift from the source:

| Page | Purpose | Update Trigger |
|------|---------|----------------|
| `deliverables/implementation-roadmap.md` | Client-facing sequencing plan | After phase/priority changes |
| `synthesis/workload-lens-*.md` | Per-stream readiness assessment | After backlog changes to that stream |
| `deliverables/findings.md` | Findings register with backlog cross-refs | After new findings or backlog mapping changes |

**Rule:** When a backlog item's priority, effort, or phase changes, the `backlog-reference-check` hook will flag stale snapshot references. Update them or explicitly note they're a snapshot ("as of YYYY-MM-DD").

### What Gets Checked by the Hook

The `backlog-reference-check` hook fires after any edit to `deliverables/backlog/items/*.md` and looks for:

1. **Priority drift** — item says "Medium" but a synthesis page says "High"
2. **Effort drift** — item says 1.5 days but roadmap says "3–5 days"
3. **Phase drift** — estimation-config.yaml has the item in phase 2 but roadmap puts it in phase 1
4. **Stale topic text** — item's topic has been reworded but old wording persists elsewhere

### When to Accept Drift

Sometimes drift is intentional:
- A workload lens quotes a *finding* effort range (which is different from the backlog item's calculated effort)
- A narrative page uses approximate language ("~1 week") rather than exact days
- A historical entry (team-input.md, log.md) records what was true at the time

In these cases, the hook will flag but you can dismiss.

### Agent Behaviour

When creating or updating backlog items:
1. Update the item file (frontmatter + body)
2. Update `estimation-config.yaml` if phase assignment changed
3. The hook will automatically check for stale references
4. If the hook finds drift, fix it or note it's intentional

When updating snapshot pages (roadmap, workload lenses):
1. Read current backlog item frontmatter before writing
2. Use accurate current values, not memory from earlier in the conversation
3. Add an `updated:` date in the frontmatter so readers know the freshness
