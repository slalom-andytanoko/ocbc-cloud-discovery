![Python 3.10+](https://img.shields.io/badge/python-3.10%2B-blue) ![Proprietary](https://img.shields.io/badge/license-Slalom%20Proprietary-red)

[![Kiro](https://img.shields.io/badge/agent-Kiro-6B4FBB?logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PC9zdmc+)](https://kiro.dev) [![GitHub Copilot](https://img.shields.io/badge/agent-GitHub%20Copilot-238636?logo=github)](https://github.com/features/copilot) [![Claude Code](https://img.shields.io/badge/agent-Claude%20Code-D97706?logo=anthropic)](https://claude.ai/code) [![Codex CLI](https://img.shields.io/badge/agent-Codex%20CLI-412991?logo=openai)](https://github.com/openai/codex)

# Discovery Toolkit

**Pull information from anywhere. Push findings everywhere. Keep every claim traceable.**

Discovery engagements are information-heavy and time-compressed. Evidence is scattered across Confluence pages, IaC repositories, live AWS accounts, session transcripts, and stakeholder conversations. Deliverables — findings registers, remediation backlogs, implementation roadmaps — need to reflect all of it accurately and stay consistent as the picture evolves.

The Discovery Toolkit is an AI-powered engagement scaffold that makes this seamless:

```
Sources                    Wiki (Knowledge Base)               Destinations
──────────────────────     ─────────────────────────────────   ──────────────────────
Confluence pages      ──►  Concepts  — domain knowledge   ──►  Findings register
Session transcripts   ──►  Entities  — accounts, systems  ──►  Remediation backlog
IaC repositories      ──►  Synthesis — gap analyses       ──►  RAID log
Live AWS accounts     ──►  Reference — standards, docs    ──►  Implementation roadmap
Team commentary       ──►  Questions — open items         ──►  Confluence publish
Jira tickets          ──►  Journal   — session prep notes ──►  Presentation deck
```

Every source gets distilled into the wiki first — nothing goes directly to a deliverable. Every wiki page records where its knowledge came from. Every deliverable traces back to the wiki. When a finding changes, you regenerate — you don't manually hunt for everywhere it appears.

> **New to this repo?** Open it in your AI agent and say:
> **"Follow the setup instructions in docs/setup-guide.md to set up this engagement repo."**
> The agent will walk you through every step — no prior knowledge of the toolkit needed.

## What You Get

- **Multi-source ingestion** — pull from Confluence (`ingest-confluence`), session transcripts (`ingest-session`), IaC repos (`ingest-iac`), and live AWS accounts (`ingest-aws`) into a single structured knowledge base
- **Session preparation** — query the wiki before every stakeholder session to surface gaps, generate question lists, and brief the team on what's already known vs what still needs confirming
- **Gap detection and open questions** — the `gap-analysis` skill compares wiki knowledge against best-practice checklists; open questions are tracked in `open-questions.md` and surfaced automatically during session prep
- **Traceable wiki** — every page has a `source:` field; every claim links back to the Confluence page, session timestamp, or IaC file that supports it
- **Team input as first-class data** — consultant corrections and stakeholder confirmations in `docs/team-input.md` override automated analysis when generating deliverables
- **One-command deliverables** — generate findings register, remediation backlog, RAID log, roadmap, and Confluence-ready pages from the accumulated wiki knowledge
- **Multi-destination publish** — push to Confluence (`publish-confluence`), export to PowerPoint, or output structured Markdown for any downstream tool
- **Discovery skills** — gap analysis, Well-Architected review, session facilitation, stakeholder mapping, and more, installed directly into your agent framework
- **Multi-agent support** — generates native config for Kiro (`.kiro/skills/`), GitHub Copilot (`.github/copilot-instructions.md`), Claude Code (`CLAUDE.md`), and Codex CLI (`AGENTS.md` + `.codex/`)
- **Interactive setup wizard** — `python setup.py` collects client details, wires submodules, configures agent frameworks, and generates every config file automatically
- **Managed skill updates** — skill packs are git submodules; run `git submodule update --remote` to pull improvements from any engagement back into yours

## Prerequisites

- **Python 3.10+** — verify with `python --version`
- **Git 2.x+** — verify with `git --version`
- **[Obsidian](https://obsidian.md/)** — for browsing and editing the wiki vault (free desktop app)
- **One of:** [Kiro](https://kiro.dev/), [GitHub Copilot](https://github.com/features/copilot) (in VS Code), [Claude Code](https://claude.ai/code), or [Codex CLI](https://github.com/openai/codex)

## How This Works

This is a **GitHub template repository**. You never work in this repo directly — you use it to create a new engagement repo, then work in that.

```
slalom-discovery-toolkit-template  ←  you are here (don't touch after step 1)
        │
        │  "Use this template" on GitHub
        ▼
client-name-discovery              ←  your engagement repo (clone and work here)
        │
        ├── .skill-repos/slalom-discovery-kit/   ←  setup wizard + skills (submodule)
        ├── .skill-repos/obsidian-wiki/           ←  wiki skills (submodule)
        └── .skill-repos/slalom-agent-kit/        ←  Slalom tooling (submodule)
```

Skills and the setup wizard live in submodules — they can be updated on a running engagement with `git submodule update --remote` without disturbing your engagement work.

## Quickstart

1. On GitHub: click **"Use this template"** → **"Create a new repository"** → clone it
2. Open the engagement repo in your AI agent (Kiro, Copilot, or Claude Code)
3. Say: **"Read the setup guide and set this engagement repo up"**

That's it. The agent reads [`docs/setup-guide.md`](docs/setup-guide.md) and walks you through everything — asking for credentials, running the setup wizard, and troubleshooting failures. See the setup guide for the full step-by-step, manual instructions, MCP configuration, and troubleshooting.

## Documentation

| Guide | Description |
|-------|-------------|
| [Setup Guide](docs/setup-guide.md) | Step-by-step installation, SSH multi-key config, MCP credentials, troubleshooting |
| [Skill Catalogue](docs/skill-catalogue.md) | Every installed skill: name, description, invocation example |
| [Vault Categories](docs/vault-categories.md) | Directory tree with purpose annotations and example filenames |
| [First 30 Minutes](docs/first-30-minutes.md) | Guided walkthrough: verify setup → ingest a doc → run gap-analysis → generate a deliverable |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to propose skill improvements, test across engagements, and submit to the shared skill library.

---

© Slalom Consulting. Proprietary and confidential. Not for distribution outside of Slalom engagements.
