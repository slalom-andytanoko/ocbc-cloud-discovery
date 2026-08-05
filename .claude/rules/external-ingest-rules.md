---
inclusion: fileMatch
globs: external/**
---

# External Folder Ingestion Rules

`external/` holds proprietary/confidential client source material (gitignored, never committed).
Once a file here has been successfully ingested into the wiki, it must be archived.

## Rule

- **After successful ingestion, move (don't copy) the source file into the repo-root**
  **`.processed/` folder** (i.e. `.processed/`, NOT `external/.processed/`). Applies to
  every file type — PDFs, Word docs, images, diagrams, markdown notes — no exceptions.
- **Never move `external/README.md`** — it documents the folder's rules, not source material.
- If ingestion only partially succeeds (e.g. one file in a multi-file drop fails to parse),
  archive only the files that were successfully ingested; leave failed files in place and
  flag the failure to the user.
- `.processed/` is its own top-level `.gitignore` entry (separate from `external/`) —
  nothing in it is ever committed.

## Guardrail

If an ingestion operation completes without archiving its source file(s) into the
repo-root `.processed/`, treat the ingestion as incomplete — archive before reporting success.
