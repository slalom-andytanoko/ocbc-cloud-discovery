---
title: Remediation Backlog
category: deliverables
tags: [backlog, remediation, deliverable]
cssclass: wide-page
updated: YYYY-MM-DD
---

# Remediation Backlog

Individual backlog items distilled from [[deliverables/findings|findings]]. Each item
is one file in `deliverables/backlog/items/` with structured frontmatter that drives
estimation, phase planning, and Jira sync.

See `deliverables/estimation-config.yaml` to adjust effort multipliers, AI acceleration
rates, buffer, and phase assignments. Ask your agent to re-estimate after any change.

> **Skill invocation by framework:**
> - **Kiro:** `/deliverables` (trigger phrase match)
> - **Claude Code:** `/discovery-deliverables` (slash command from filename)
> - **Copilot / Codex:** natural language — `"generate deliverables"`, `"run deliverables estimate"`

---

## Items by Priority

```dataview
TABLE
  id AS "ID",
  topic AS "Topic",
  priority AS "Priority",
  phase AS "Phase",
  tshirt AS "Size",
  effort_days AS "Days",
  effort_days_ai AS "Days (AI)",
  status AS "Status"
FROM "deliverables/backlog/items"
WHERE id != null AND status != "Deferred"
SORT choice(priority = "High", 0, choice(priority = "Medium", 1, 2)) ASC, phase ASC
```

---

## Items by Phase

```dataview
TABLE
  id AS "ID",
  topic AS "Topic",
  priority AS "Priority",
  tshirt AS "Size",
  effort_days AS "Days",
  effort_days_ai AS "Days (AI)",
  status AS "Status"
FROM "deliverables/backlog/items"
WHERE id != null AND status != "Deferred"
SORT phase ASC, choice(priority = "High", 0, choice(priority = "Medium", 1, 2)) ASC
```

---

## Deferred Items

```dataview
TABLE
  id AS "ID",
  topic AS "Topic",
  priority AS "Priority",
  phase AS "Phase"
FROM "deliverables/backlog/items"
WHERE id != null AND status = "Deferred"
SORT id ASC
```

---

## Phase Effort Summary

> **Note:** Update this table by running `/deliverables estimate` after assigning or
> re-estimating items. The totals include the buffer from `estimation-config.yaml`.

| Phase | Items | Total Days | Total Days (AI) | Notes |
|-------|-------|-----------|-----------------|-------|
| Phase 1 | — | — | — | Critical path |
| Phase 2 | — | — | — | Hardening |
| Phase 3 | — | — | — | Continuous improvement |
| **Total** | — | — | — | |
