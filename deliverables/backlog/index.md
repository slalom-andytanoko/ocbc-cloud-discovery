---
title: Backlog Index
category: deliverable
tags: [backlog, deliverable]
updated: YYYY-MM-DD
---

# Backlog Index

## Items by Priority

```dataview
TABLE priority, effort_days, phase, status FROM "deliverables/backlog/items"
SORT priority DESC
```

## Items by Phase

```dataview
TABLE priority, effort_days, status FROM "deliverables/backlog/items"
SORT phase ASC, priority DESC
```
