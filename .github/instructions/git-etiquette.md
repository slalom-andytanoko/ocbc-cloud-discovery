---
applyTo: "**"
---
---
inclusion: always
---

# Git Etiquette

## Pushing

- **Do NOT push automatically after commits.** Only push when the user explicitly says "push", "push it", or "commit and push".
- Stage and commit freely (logical groupings), but leave the push for the user to confirm.
- If you've made multiple commits and the user hasn't asked to push, that's fine — they accumulate locally until the user is ready.
- **`git push` must always be a separate, explicit command** — never chain it with `git commit` using `&&` or `;`.
- When asked to "commit and push", run `git commit` first, confirm it succeeds, then run `git push` as a separate step.

## Committing

- Group related changes into logical commits (don't make one mega-commit for unrelated work).
- Use conventional commit prefixes: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`.
- Keep commit messages under 70 chars for the title line. Details go in the body.
- Stage specific files — don't `git add .` unless all changes are related.

## Branches

- Work on `main` unless the user asks for a branch.
- Never force-push without explicit confirmation.

## Rebase Over Merge

- **Prefer rebase over merge** — always rebase feature branches onto the target branch rather than merging.
- When integrating upstream changes: use `git pull --rebase` (or `git pull -r`).
- For PRs: use rebase merge strategy (not squash or merge commit) so the individual commit history is preserved linearly.
- When rebasing introduces conflicts, resolve them commit-by-commit rather than collapsing into a merge commit.
- Never use `git merge` for branch integration unless the user explicitly asks for it.
