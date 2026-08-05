---
inclusion: fileMatch
globs: docs/sessions/**
---

# Session Transcript Rules

Files in `docs/sessions/` follow a processing pipeline. Not all files are wiki-ingest-ready.

## What's Safe to Ingest

| File | Ingestible? |
|------|-------------|
| `transcript-clean.md` | ✅ Yes — already processed |
| `*.md` (manual notes) | ✅ Yes — human-written |
| `transcript-raw.md` | ❌ Never — raw STT extraction, kept for reference only |
| `*.docx` | ❌ Never — must be processed first via `ingest-session` or `process-session-transcript` |

## Guardrail

If any operation attempts to read or ingest a `.docx` or `transcript-raw.md` from `docs/sessions/`, stop and redirect to the appropriate skill. Do not pass raw transcript content into the wiki pipeline.
