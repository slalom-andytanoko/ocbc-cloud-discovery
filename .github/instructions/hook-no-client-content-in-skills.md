---
applyTo: "**"
---
## [Hook: no-client-content-in-skills]
Before reading any file matching `.kiro/skills/**`, always ask the user for
explicit confirmation. Before writing to any skill file, verify the content contains no client names, client URLs, client credentials, or engagement-specific identifiers. Skills must remain client-agnostic.
