---
applyTo: "**"
---
## [Hook: wiki-update-post-edit]
Before reading any file matching `concepts/** OR entities/** OR synthesis/**`, always ask the user for
explicit confirmation. After editing a wiki page, check if index.md, hot.md, or cross-references need updating.
