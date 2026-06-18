# Changelog

All notable changes to the Discovery Toolkit Template are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

_Changes staged on `feat/templatise` awaiting promotion to the standalone Template_Repo._

---

## [0.1.0] — 2026-07-01

Initial release of the Discovery Toolkit Template — extracted from an AWS AFT
Discovery engagement repo and generalised for reuse across any client discovery engagement.

### Added

- **Template placeholder system** — `{{VARIABLE_NAME}}` double-curly-brace token substitution
  used across all `.tmpl` source files; `TemplateResolver` class validates no unresolved
  placeholders remain after generation.
- **Setup wizard (`setup.py`)** — Python 3.10+ cross-platform CLI that collects engagement
  config interactively (or via `--non-interactive` INI file) and generates `.env`,
  `.gitmodules`, and agent-specific configuration in a single pass.
- **Skill pack architecture** — Flat `skills/` directory in the `discovery-kit` submodule with
  optional domain packs (`aws/`, `azure/`, `gcp/`, `data/`, `security/`) selectable at setup
  time via `library/index.yaml`.
- **Multi-agent adapters** — `setup.py` generates native configuration for Kiro
  (`.kiro/skills/` + `.kiro/steering/`), GitHub Copilot (`.github/copilot-instructions.md`),
  and Claude Code (`CLAUDE.md` + `.claude/commands/`) from the same framework-agnostic skill
  and steering sources.
- **Managed file manifest** — `.kiro/managed-files.json` records SHA-256 hashes of every
  installed file so `python setup.py --refresh` can detect consultant modifications and prompt
  before overwriting.
- **Drift detection** — On refresh, modified files trigger an interactive overwrite / skip /
  diff prompt; `--non-interactive` mode defaults to skip and logs each skipped path to stdout.
- **Deliverables pipeline** — `deliverables/deliverables-config.yaml` toggles which artefact
  types (findings register, backlog, RAID, current-state summary, etc.) are active; the
  `discovery-deliverables` skill reads this config at runtime.
- **Vault scaffold** — Template repository ships with all required Obsidian directories
  (`concepts/`, `entities/`, `synthesis/`, `reference/`, `journal/`, `_archives/`, `_meta/`,
  `_raw/`, `_staging/`, `docs/`, `external/`) each pre-populated with a `README.md` describing
  the directory's purpose and expected content types.
- **`obsidian_wiki_setup.py` module** — Dedicated `setup_lib/` module that encapsulates
  obsidian-wiki submodule integration; sole place that knows about obsidian-wiki's directory
  structure and conventions (`ObsidianWikiInstaller` class with `run()` method).
- **MCP server registry** — `templates/mcp-servers.yaml` defines all required MCP servers in a
  framework-agnostic format; `setup.py` generates framework-native config from it.
- **Documentation set** — `README.md`, `docs/setup-guide.md`, `docs/skill-catalogue.md`,
  `docs/vault-categories.md`, `docs/first-30-minutes.md`, `docs/concepts.md`,
  `docs/architecture.md`, `docs/agent-adapters.md`, `docs/creating-custom-skills.md`.

### Changed

- `setup.sh` replaced by `setup.py` — all vault initialisation, submodule wiring, and `.env`
  generation is now Python 3.10+ and runs identically on macOS, Linux, and Windows.
- `.kiro/steering/project-context.md` is now generated from `templates/project-context.md.tmpl`
  rather than committed directly; contains no client-specific content in the template.
- `.kiro/steering/domain-glossary.md` is now generated from `templates/domain-glossary.md.tmpl`
  with pack-specific STT corrections merged in at setup time.
- Discovery skills are no longer committed directly to `.kiro/skills/`; they originate from the
  `slalom-discovery-kit` git submodule and are installed by `setup.py`.

---

## Breaking Changes Template

> Use the section below as the format for documenting breaking changes in future releases.
> Copy it into the relevant version heading and fill in the details.

```markdown
## Breaking Changes (migration required)

### What changed

Describe what changed and why — e.g. "The `--refresh` flag no longer prompts interactively by
default. Non-interactive behaviour is now opt-in via `--non-interactive`."

### Migration steps

1. Step-by-step instructions a consultant on a running engagement must follow.
2. Include any commands they need to run.
3. Highlight files that must be manually updated if automation cannot handle it.
4. State the impact of NOT migrating (e.g. "Refresh will abort if this step is skipped").
```

---

[Unreleased]: https://github.com/slalom-consulting-ltd/discovery-toolkit-template/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/slalom-consulting-ltd/discovery-toolkit-template/releases/tag/v0.1.0
