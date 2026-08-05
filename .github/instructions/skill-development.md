---
applyTo: "**"
---
---
inclusion: always
---

# Skill Development Rules

When adding, renaming, or removing a skill in the `skills/` directory, you MUST also update
all downstream documentation and configuration. Skills are never standalone — they are
part of a catalogue that users and the setup wizard depend on.

## Mandatory Updates When a Skill Changes

### 1. `library/index.yaml`
- If adding a new skill: add it to the appropriate pack's `skills:` list
- If creating a new pack: add a full pack entry with `id`, `name`, `description`, `mandatory`, `source`, `skills`
- If removing a skill: remove from its pack entry

### 2. `docs/skills.md`
- Add or remove the skill row in the appropriate pack table
- Include: skill directory name, slash command (`/skill-name`), one-line description

### 3. `docs/cheatsheet.md`
- Add or remove the skill from the relevant phase table (ingestion, analysis, deliverables, etc.)
- Include both the slash command and natural language alternative

### 4. `CHANGELOG.md`
- Add an entry under `## [Unreleased]` → `### Added` / `### Changed` / `### Removed`

## Skill File Structure

Every skill directory MUST contain a `SKILL.md` with YAML frontmatter:

```yaml
---
name: skill-name
description: >
  What the skill does and when to trigger it.
  List trigger phrases here.
version: 1.0.0
requires_packs: [optional-pack-id]  # only if skill requires a specific pack
---
```

## Reference Files

- Cloud-specific or domain-specific best practices go in `./references/` within the skill directory
- Each skill owns its own references — do NOT put cloud-specific references in another skill's directory
- Reference paths in SKILL.md use relative `./references/filename.md` format (agent-agnostic)

## Agent-Agnostic Paths

- NEVER use `.kiro/skills/`, `.claude/commands/`, or any other framework-specific path
- Use `./references/` for files relative to the skill itself
- Use `./scripts/` for scripts bundled with the skill
- The installed path varies by agent framework — relative paths work everywhere

## Skill Naming

- Directory name = slash command name (e.g., `skills/gap-analysis-aws/` → `/gap-analysis-aws`)
- Use kebab-case
- Prefix with domain: `ingest-*`, `gap-analysis-*`, `publish-*`

## Testing

- If the skill includes Python scripts, add tests in `tests/`
- Run `pytest tests/ -x -q` before committing
- Run `ruff check` on any Python files
