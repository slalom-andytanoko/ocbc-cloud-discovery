---
applyTo: "**"
---
## [Hook: wiki-lint-post-edit]
Before reading any file matching `(concepts|entities|synthesis)/**/*.md`, always ask the user for
explicit confirmation. Run a wiki-lint check on the file that was just edited. Check for: missing frontmatter fields (title, category, tags, sources, created, updated), broken [[wikilinks]] that reference pages which do not exist, orphaned pages (no incoming links from other wiki pages), and missing cross-links to related concepts. Report any issues found and offer to fix them. If the file is in good health, say nothing.
