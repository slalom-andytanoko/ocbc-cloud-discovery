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

- **Principal consultant thinking built in** — use `/project-context` to customise the toolkit to your engagement. It acts as a principal consultant to build a shared understanding of the project: workloads, drivers, maturity, timeline, stakeholders, and known risks — then uses that context to calibrate every gap analysis and deliverable automatically
- **Stakeholder map that builds itself** — session transcripts are automatically mined for speaker names, roles, and speaking patterns. By session 3, your agent knows who pushes back on security findings, who asks about cost, and who defers to technical leads
- **Multi-source ingestion** — pull from Confluence (`ingest-confluence`), session transcripts (`ingest-session`), IaC repos (`ingest-iac`), and live AWS accounts (`ingest-aws`) into a single structured knowledge base
- **Gap analysis with depth** — the `gap-analysis` skill runs a broad Well-Architected assessment and, when AWS or security packs are installed, automatically invokes focused deep-dives for Landing Zone, IaC, and security posture
- **Traceable wiki** — every page has a `source:` field; every claim links back to the Confluence page, session timestamp, or IaC file that supports it
- **Team input as first-class data** — consultant corrections and stakeholder confirmations override automated analysis when generating deliverables
- **One-command deliverables** — generate findings register, remediation backlog, RAID log, roadmap, and Confluence-ready pages from the accumulated wiki knowledge; presentations are generated as Slalom-branded `.pptx` using the `slalom-pptx` skill with reusable cool-slides shape patterns
- **Multi-agent support** — generates native config for Kiro, GitHub Copilot, Claude Code, and Codex CLI
- **Agent-driven setup** — open the repo in your AI agent and say "set this up"; the agent reads the setup guide, runs `python setup.py` on your behalf, asks for credentials interactively, and troubleshoots failures without you touching the terminal
- **Extensible skill system** — add your own skill submodule to `.skill-repos/`, declare it in `.skill-repos/custom-skill-library.yaml`, and its skills are installed on the next `--refresh`; improvements to central skills in `slalom-discovery-kit` flow to all engagement repos via `git submodule update --remote`

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

That's it. The agent reads [`docs/setup-guide.md`](docs/setup-guide.md) and walks you through everything — asking for credentials, running the setup wizard, and troubleshooting failures. See the [setup guide](https://github.com/Slalom/slalom-discovery-kit/blob/main/docs/setup-guide.md) for the full step-by-step, manual instructions, MCP configuration, and troubleshooting.

## Documentation

> **After running `python setup.py`**, full guides are available at `.skill-repos/slalom-discovery-kit/docs/`.

| Guide | Description | On GitHub |
|-------|-------------|-----------|
| [Setup Guide](docs/setup-guide.md) | Step-by-step installation, MCP credentials, troubleshooting | [![](https://img.shields.io/badge/-GitHub-181717?logo=github&logoColor=white)](https://github.com/Slalom/slalom-discovery-kit/blob/main/docs/setup-guide.md) |
| [Skill Catalogue](.skill-repos/slalom-discovery-kit/docs/skill-catalogue.md) | Every installed skill with invocation examples | [![](https://img.shields.io/badge/-GitHub-181717?logo=github&logoColor=white)](https://github.com/Slalom/slalom-discovery-kit/blob/main/docs/skill-catalogue.md) |
| [Vault Categories](.skill-repos/slalom-discovery-kit/docs/vault-categories.md) | What goes in each wiki directory | [![](https://img.shields.io/badge/-GitHub-181717?logo=github&logoColor=white)](https://github.com/Slalom/slalom-discovery-kit/blob/main/docs/vault-categories.md) |
| [First 30 Minutes](.skill-repos/slalom-discovery-kit/docs/first-30-minutes.md) | Guided walkthrough: ingest → gap-analysis → deliverable | [![](https://img.shields.io/badge/-GitHub-181717?logo=github&logoColor=white)](https://github.com/Slalom/slalom-discovery-kit/blob/main/docs/first-30-minutes.md) |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to propose skill improvements, test across engagements, and submit to the shared skill library.

---

© Slalom Consulting. Proprietary and confidential. Not for distribution outside of Slalom engagements.
