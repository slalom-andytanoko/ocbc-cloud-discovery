---
applyTo: "**"
---
# Scripting Standards

## Rule: All Scripts Must Be Python (OS-Agnostic)

Team members use macOS, Linux, and Windows. All automation scripts must run cross-platform without modification.

### Requirements

1. **Use Python 3.10+** for all scripts and automation (not bash, sh, or PowerShell)
2. **Use `pathlib`** for file paths — never hardcode `/` or `\` separators
3. **Use `subprocess.run()`** with list args (not shell=True) when invoking external commands
4. **Use `shutil`** for file copy/move/delete operations
5. **Avoid OS-specific assumptions** — no `source .env` patterns, no `sed`, no `grep` in scripts
6. **For .env loading** — use `python-dotenv` or manual key=value parsing

### Existing Scripts to Rewrite (TEMPLATISE task)

These bash scripts work today but need Python equivalents before the repo is templatised:

| Script | Purpose | Priority |
|--------|---------|----------|
| `setup.sh` | Vault initialisation, submodule wiring, .env generation | During TEMPLATISE |
| `.kiro/skills/discovery-deliverables/scripts/deliver.sh` | Client deliverables pipeline | During TEMPLATISE |

Until rewritten, these remain as bash with a note that they require macOS/Linux.

### When Writing New Scripts

- Always Python. No exceptions.
- Place utility scripts in the skill's `scripts/` directory
- Include a `requirements.txt` or inline `pip install` comment if dependencies are needed
- Use `#!/usr/bin/env python3` shebang for Unix compatibility (Windows ignores it harmlessly)
- Prefer standard library where possible (`pathlib`, `shutil`, `json`, `csv`, `subprocess`)

### Agent Behaviour

When an agent needs to run a multi-step automation task:
- Write a Python script, execute it, then clean up if temporary
- Do NOT write bash one-liners or use shell pipes
- For simple file operations, use the IDE's file tools directly instead of scripting

## Rule: Use `cwd` Parameter — Never `cd &&` Chaining

When running shell commands in this repo, **always use the `cwd` parameter** on the bash tool to set the working directory. Never prepend `cd /path/to/repo &&` to a command.

### Why This Matters

- Auto-approval rules match on the command string. `cd /path && git add file` does NOT match a rule for `git add file`.
- `cd &&` chaining breaks auto-approvals and forces unnecessary manual confirmation prompts.
- The `cwd` parameter is invisible to the command string — the command stays clean and matchable.

### Correct Pattern

```
# CORRECT: set cwd to repo root, command is just the operation
cwd: {{ENGAGEMENT_REPO_ROOT}}
command: git add .kiro/steering/git-etiquette.md

# WRONG: cd-chaining pollutes the command string
command: cd {{ENGAGEMENT_REPO_ROOT}} && git add .kiro/steering/git-etiquette.md
```

This applies to **all** commands: `git`, `python`, `npm`, AWS CLI, etc.
