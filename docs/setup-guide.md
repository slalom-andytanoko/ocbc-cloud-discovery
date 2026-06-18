# Setup Guide

> **Recommended:** Open the engagement repo in your AI agent and say **"Read the setup guide and set this engagement repo up."** The agent will follow these steps for you, ask for inputs where needed, and troubleshoot failures interactively. Manual execution is the fallback.

This guide is written for both **humans** and **AI agents** to follow. Each step includes the exact command to run and what to expect. An agent following this guide can execute every shell step autonomously and prompt the user only where credentials or choices are needed.

> **For agents:** Work through each numbered step in order. Run shell commands directly. Where a step says "ask the user", stop and collect that input before continuing. Steps marked ⚠️ require human action that cannot be automated.

---

## Prerequisites

Before running setup, verify the following are installed. Run each check command — if it fails, follow the fix.

### Python 3.10+

```bash
python --version
```

Expected: `Python 3.10.x` or higher. If not found:

```bash
# macOS
brew install python@3.11

# Linux
sudo apt install python3.11

# Windows: download from https://python.org/downloads
```

### Git 2.x+

```bash
git --version
```

Expected: `git version 2.x.x`. If not found, install from https://git-scm.com.

### Node.js / npm (required for Atlassian MCP server)

```bash
npm --version
```

Expected: `10.x.x` or higher. If not found:

```bash
# macOS
brew install node

# Linux
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs

# Windows: download from https://nodejs.org
```

### uv (required for AWS MCP server)

```bash
uvx --version
```

Expected: `uv x.x.x`. If not found:

```bash
# macOS / Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# Windows (PowerShell)
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

After installing, restart your terminal and verify with `uvx --version`.

### Obsidian

Download from https://obsidian.md and install. No account needed — the vault opens as a local folder.

---

## Step 1 — Clone the repo

```bash
git clone --recurse-submodules <engagement-repo-url>
cd <engagement-repo>
```

Expected: repo clones with submodules populated under `.skill-repos/`.

If submodules are empty after cloning:

```bash
git submodule update --init --recursive
```

---

## Step 2 — Install Python dependencies

```bash
pip install -e ".[dev]"
```

Expected: `Successfully installed discovery-toolkit-x.x.x ...`

---

## Step 3 — Run the setup wizard

```bash
python .skill-repos/slalom-discovery-kit/setup.py
```

The wizard will prompt for the following. **Ask the user for each value before entering it:**

| Prompt | What to ask the user | Example value |
|--------|----------------------|---------------|
| Client name | "What is the client's name?" | `Contoso Financial` |
| Client GitHub org | "What is the client's GitHub organisation slug?" | `contoso-group` |
| Slalom repo name | "What is the name of this engagement repo?" | `contoso-lz-discovery` |
| Confluence base URL | "What is the Confluence base URL?" | `https://contoso.atlassian.net/wiki` |
| Confluence space key | "What is the Confluence space key for this engagement?" | `DISC` |
| Confluence cloud ID | "What is the Confluence cloud ID?" (find it at `<site>.atlassian.net/_edge/tenant_info`) | `a1b2c3d4-...` |
| AWS default region | "What AWS region is the primary region for this engagement?" | `ap-southeast-2` |
| Your name/alias | "What name or alias should be used for this engagement?" | `Jamie` |
| Agent framework(s) | "Which agent frameworks will the team use? (kiro / copilot / claude, comma-separated)" | `kiro` |
| Client deliverables repo | "Is there a client-owned deliverables repo URL? (leave blank to skip)" | _(optional)_ |

After completing all prompts, the wizard generates:
- `.env` with all client-specific values
- `.gitmodules` with submodule configuration
- `.kiro/steering/project-context.md` and `domain-glossary.md`
- `.kiro/settings/mcp.json` (Kiro MCP server registry)
- `docs/skill-catalogue.md`

---

## Step 4 — Verify setup

Run these three checks:

```bash
# Check .env was generated with real values (not placeholders)
head -3 .env
```

Expected: lines like `CLIENT_NAME=Contoso Financial` — not `{{CLIENT_NAME}}`.

```bash
# Check skills are installed
ls .kiro/skills/
```

Expected: multiple subdirectories (gap-analysis, wiki-ingest, discovery-deliverables, ...).

```bash
# Check steering files were generated
ls .kiro/steering/
```

Expected: includes `project-context.md` and `domain-glossary.md`.

If `.kiro/skills/` is empty, reinstall skills:

```bash
python .skill-repos/slalom-discovery-kit/setup.py --refresh
```

---

## Step 5 — Configure Atlassian credentials ⚠️

This step requires the user to obtain an API token — it cannot be automated.

**Ask the user:**
1. "Go to https://id.atlassian.com/manage-profile/security/api-tokens and create a token labelled 'Discovery Toolkit'. Paste the token value here."
2. "What is the email address associated with your Atlassian account?"

Then update `.env` with these values:

```bash
# The user provides these — add them to .env
CONFLUENCE_EMAIL=<user's email>
CONFLUENCE_API_TOKEN=<token value>
```

To find the cloud ID (if not already collected in Step 3):

```bash
curl https://<site>.atlassian.net/_edge/tenant_info
```

The `cloudId` field is the value for `CONFLUENCE_CLOUD_ID` in `.env`.

---

## Step 6 — Configure AWS credentials ⚠️

**Ask the user:** "What AWS access key ID and secret should be used for read-only access to the client's AWS environment? What is the profile name to use?"

Then run:

```bash
aws configure --profile <profile-name>
```

Enter the key ID, secret, and default region when prompted.

Verify access:

```bash
aws organizations describe-organization --profile <profile-name>
```

Expected: JSON describing the AWS organisation. If it fails with `AccessDenied`, the credentials don't have sufficient permissions — the user needs to contact the AWS account owner.

---

## Step 7 — Install and verify MCP servers

### Atlassian MCP

Pre-download the MCP remote package:

```bash
npx -y mcp-remote --help
```

Expected: help text from mcp-remote. This caches the package so Kiro can launch it without network delay.

### AWS API MCP

```bash
uvx awslabs.aws-api-mcp-server@latest --help
```

Expected: help text from the AWS API MCP server. If this fails, verify `uv` is installed (see Prerequisites).

### Register in Kiro

The file `.kiro/settings/mcp.json` was generated by the setup wizard. Kiro reads this automatically.

**In Kiro:** open Settings → MCP Servers. The Atlassian and AWS API servers should appear. If they don't, restart Kiro.

To verify the Atlassian connection is working, ask your agent:

```
list my confluence spaces
```

Expected: the agent calls `getConfluenceSpaces` and returns a list of spaces. If it returns an auth error, check `CONFLUENCE_API_TOKEN` and `CONFLUENCE_EMAIL` in `.env`.

---

## Step 8 — Open the vault in Obsidian

Open Obsidian → Open folder as vault → select the repo root.

The vault opens with the directory structure pre-configured. The Dataview plugin is pre-installed and enabled. Backlog queries in `deliverables/backlog/index.md` will work immediately.

---

## Step 9 — Run first health check

Ask your agent:

```
wiki-status
```

Expected: summary showing 0 pages ingested, vault initialised, manifest fresh.

Setup is complete. See `docs/first-30-minutes.md` for the next steps.

---

## Troubleshooting

### `python: command not found`

Use `python3` instead, or install pyenv: `brew install pyenv && pyenv install 3.11.9 && pyenv global 3.11.9`.

### Submodule clone fails with auth error

```bash
ssh -T git@github.com
```

If authentication fails, add your SSH public key (`cat ~/.ssh/id_ed25519.pub`) to https://github.com/settings/keys, then retry `git submodule update --init --recursive`.

### `.kiro/skills/` is empty

```bash
python .skill-repos/slalom-discovery-kit/setup.py --refresh
```

If still empty, check submodules are populated: `ls .skill-repos/obsidian-wiki/`. If empty, run `git submodule update --init --recursive` first.

### MCP connection refused in Kiro

1. Verify `npm --version` and `uvx --version` are available from the terminal Kiro uses
2. Check `.kiro/settings/mcp.json` exists and has the correct server entries
3. Restart Kiro after any changes to `mcp.json`

### Confluence returns 403

The API token doesn't have read access to the target space. Ask the Confluence admin to grant your account (`CONFLUENCE_EMAIL`) View permission on the space, then retry.

### `setup.py: No such file or directory` (or `ModuleNotFoundError`)

You're not in the repo root. Run `pwd`, navigate to the correct directory, then retry.

---

## Multi-Engagement Switching

Each engagement is an isolated repo with its own `.env` and `.kiro/settings/mcp.json`. To switch between engagements:

```bash
cd /path/to/other-engagement
python .skill-repos/slalom-discovery-kit/setup.py --refresh
```

This updates `~/.obsidian-wiki/config` to point to the new vault. The active vault path is printed on completion.

To check which vault is currently active:

```bash
cat ~/.obsidian-wiki/config
```
