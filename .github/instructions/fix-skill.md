# fix-skill

A toolkit maintenance skill for safely patching any skill that lives in a git submodule. When you describe a bug or improvement to a skill, this skill identifies the right submodule, creates an isolated git worktree branch inside that submodule, applies the fix, runs any existing tests, and either opens a pull request via `gh pr create` or prints the exact commands for manual PR creation — then cleans up the worktree.

## Trigger phrases

- "fix this skill"
- "create a PR for this skill fix"
- "submit a skill fix"
- "patch this skill"
- "contribute this fix upstream"

## What I do

1. **Identify the target skill and submodule.**
   - Ask the user which skill needs fixing if not already clear from context.
   - Read `.gitmodules` at the engagement repo root to find the submodule path and upstream URL for the repo that contains the skill. Skills live under `.skill-repos/*/skills/<skill-name>/`.
   - Resolve the submodule's absolute path on disk (e.g., `.skill-repos/discovery-kit`).

2. **Verify the upstream remote is reachable.**
   - Run `git ls-remote <upstream-url>` inside the submodule directory.
   - If the remote is unreachable (network error, auth failure, no write access), stop and inform the user. Do not attempt to push.

3. **Create a git worktree on a new branch inside the submodule.**
   - Choose a branch name following the convention: `fix/<skill-name>-<short-description>` (e.g., `fix/gap-analysis-env-var-missing`). Keep the short-description to 3–5 lowercase words joined by hyphens.
   - Create the worktree **outside** the engagement repo to avoid polluting the engagement repo's working tree. Use the path `../<submodule-name>-fix-worktree` relative to the submodule root (e.g., if the submodule is at `.skill-repos/discovery-kit`, the worktree goes at `.skill-repos/discovery-kit/../discovery-kit-fix-worktree`, which resolves to `.skill-repos/discovery-kit-fix-worktree`).
   - Run: `git worktree add ../../<submodule-name>-fix-worktree <branch-name>` from inside the submodule directory.
   - Confirm the worktree was created successfully before continuing.

4. **Apply the described fix in the worktree.**
   - Make all file edits inside the worktree directory, not in the main submodule checkout.
   - Keep changes minimal and focused — only touch what is needed for the fix.
   - After editing, stage the changes: `git add -p` or `git add <files>` inside the worktree.
   - Commit with a conventional message: `fix(<skill-name>): <concise description>` (max 70 chars for the title line).

5. **Run existing tests if available.**
   - Check whether a `tests/` directory exists in the worktree root.
   - If Python test files are present (`tests/*.py` or `tests/test_*.py`), run: `python -m pytest tests/ -v` from the worktree root.
   - If no tests exist, skip this step and note that in the PR description.
   - If tests fail, report the failure to the user before pushing. Do not push a failing branch without user confirmation.

6. **Prompt the user to review the changes before pushing.**
   - Show a summary: branch name, files changed, commit message, test result.
   - Ask: "Ready to push branch `<branch-name>` to `<remote-url>`? (yes/no)"
   - Do not push until the user confirms.

7. **Push the branch to the upstream remote.**
   - From inside the worktree: `git push -u origin <branch-name>`
   - Confirm the push succeeded.

8. **Create a PR (or print fallback instructions).**
   - If `gh` CLI is available (check with `gh --version`):
     - Run: `gh pr create --repo <org>/<repo> --head <branch-name> --title "fix(<skill-name>): <description>" --body "<PR body>"`
     - The PR body should include: what was broken, what was changed, and the test result.
   - If `gh` is not available, see **When `gh` is not available (fallback)** below.

9. **Clean up the worktree.**
   - From inside the submodule: `git worktree remove ../../<submodule-name>-fix-worktree`
   - Confirm the worktree directory has been removed.
   - Note: the branch itself is preserved in the submodule's git history and the remote — only the local checkout is removed.

## Example

**Scenario:** The `gap-analysis` skill fails when `AWS_DEFAULT_REGION` is not set in `.env`, crashing with an unhelpful `KeyError` instead of a descriptive message.

**Full flow:**

```
User: "fix this skill — gap-analysis crashes with KeyError when AWS_DEFAULT_REGION is missing"

1. Skill identified: gap-analysis
   Submodule: .skill-repos/discovery-kit
   Remote: git@github.com:Slalom/slalom-discovery-kit.git

2. Verify remote reachable:
   $ git ls-remote git@github.com:Slalom/slalom-discovery-kit.git HEAD
   → reachable ✓

3. Create worktree:
   $ cd .skill-repos/discovery-kit
   $ git worktree add ../../discovery-kit-fix-worktree fix/gap-analysis-env-var-missing
   → Worktree at .skill-repos/discovery-kit-fix-worktree ✓

4. Apply fix:
   Edit .skill-repos/discovery-kit-fix-worktree/skills/gap-analysis/SKILL.md
   → Added descriptive error handling for missing AWS_DEFAULT_REGION
   $ git add skills/gap-analysis/SKILL.md
   $ git commit -m "fix(gap-analysis): descriptive error for missing AWS_DEFAULT_REGION"

5. Run tests:
   $ python -m pytest tests/ -v
   → 12 passed in 0.4s ✓

6. User review prompt:
   Branch: fix/gap-analysis-env-var-missing
   Files: skills/gap-analysis/SKILL.md
   Commit: "fix(gap-analysis): descriptive error for missing AWS_DEFAULT_REGION"
   Tests: 12 passed
   Ready to push? → User confirms: yes

7. Push:
   $ git push -u origin fix/gap-analysis-env-var-missing
   → Branch pushed ✓

8. PR created:
   $ gh pr create --repo Slalom/slalom-discovery-kit \
       --head fix/gap-analysis-env-var-missing \
       --title "fix(gap-analysis): descriptive error for missing AWS_DEFAULT_REGION" \
       --body "..."
   → PR URL: https://github.com/Slalom/slalom-discovery-kit/pull/42

9. Cleanup:
   $ git worktree remove ../../discovery-kit-fix-worktree
   → Worktree removed ✓
```

## Prerequisites

- **Git 2.x+** — worktree support requires Git ≥ 2.5; `git worktree remove` requires Git ≥ 2.17
- **SSH access to the submodule remote** — your local SSH key must have write access to the upstream repository (the one referenced in `.gitmodules`)
- **`gh` CLI** (optional, recommended) — used for creating pull requests automatically; install via `brew install gh` (macOS) or `winget install --id GitHub.cli` (Windows), then authenticate with `gh auth login`
- **Python 3.10+ and pytest** — required only if the submodule contains a `tests/` directory; install pytest with `pip install pytest`

## When `gh` is not available (fallback)

If `gh --version` returns an error or is not found in `PATH`, skip the `gh pr create` step and instead print the following for the user to action manually:

```
gh is not available. To open a PR manually:

1. Push command (already done above):
   git push -u origin fix/<skill-name>-<short-description>

2. Open a PR at:
   https://github.com/<org>/<repo>/compare/fix/<skill-name>-<short-description>?expand=1

   Or navigate to:
   https://github.com/<org>/<repo>/pull/new/fix/<skill-name>-<short-description>

3. Suggested PR title:
   fix(<skill-name>): <concise description>

4. Suggested PR body:
   ## What was broken
   <description of the bug>

   ## What was changed
   <list of files and the nature of the change>

   ## Tests
   <test result or "No tests found">
```

Fill in `<org>`, `<repo>`, `<skill-name>`, and `<short-description>` from the actual values used in steps 1–7.

## Notes

- The worktree is created outside the engagement repo to keep git status clean
- If you don't have push access, the skill will fork-and-PR instead (using `gh repo fork`)
- The fix does NOT affect your engagement's installed skills until you run `python setup.py --refresh`
