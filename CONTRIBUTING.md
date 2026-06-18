# Contributing to the Discovery Toolkit Template

Thanks for investing time in improving the toolkit. Contributions that pass through the
process below make every future engagement better — not just yours.

---

## Table of Contents

1. [How to propose a skill improvement](#1-how-to-propose-a-skill-improvement)
2. [How to test changes across engagements](#2-how-to-test-changes-across-engagements)
3. [Skill quality checklist](#3-skill-quality-checklist)
4. [Release process](#4-release-process)
5. [Governance and branch protection](#5-governance-and-branch-protection)

---

## 1. How to propose a skill improvement

Skills live in the **`slalom-discovery-kit`** submodule repo — not in the template itself.
To propose a change:

1. **Fork** the `slalom-discovery-kit` repo to your personal or team GitHub account.

2. **Create a branch** — use `feat/<skill-name>-<short-description>` or `fix/<skill-name>-<issue>`.

   ```bash
   git checkout -b feat/aws-network-expert-add-ipam-questions
   ```

3. **Locate the skill** — all skills live in the flat `skills/` directory.

   ```
   .skill-repos/discovery-kit/skills/<skill-name>/
   ```

   If the skill is a domain expert skill from the library, it is under:

   ```
   .skill-repos/discovery-kit/library/<pack>/skills/<skill-name>/
   ```

4. **Modify the skill** — edit `SKILL.md` and any supporting files. See the
   [Skill quality checklist](#3-skill-quality-checklist) before committing.

5. **Test on a real or mock engagement** — see [section 2](#2-how-to-test-changes-across-engagements).

6. **Submit a pull request** against the `main` branch of `slalom-discovery-kit`.
   - PR title: `feat(skill): <what changed>` or `fix(skill): <what was broken>`
   - PR description: explain the problem, what changed, and how you tested it
   - Link to any engagement issue or context that motivated the change
   - At least one maintainer approval is required before merge

> **New skill?** If you are proposing an entirely new skill, open a GitHub issue first to
> confirm the skill is in scope for the toolkit before doing the implementation work.

---

## 2. How to test changes across engagements

### Quick test on a fresh template instance

1. **Create a fresh repo from the template** — click "Use this template" on GitHub or:

   ```bash
   git clone https://github.com/slalom-consulting-ltd/discovery-toolkit-template.git \
       my-test-engagement
   cd my-test-engagement
   ```

2. **Point the discovery-kit submodule at your fork/branch:**

   ```bash
   # In .gitmodules, update the discovery-kit url to your fork, then:
   git submodule sync
   git submodule update --init --remote .skill-repos/discovery-kit
   ```

3. **Run the setup wizard** and answer prompts with mock values:

   ```bash
   python setup.py
   # Client name: Test Client
   # Confluence base URL: https://test.atlassian.net/wiki
   # (etc.)
   ```

4. **Verify the modified skill was installed correctly:**

   ```bash
   ls .kiro/skills/<skill-name>/
   # Should show SKILL.md and any supporting files
   ```

5. **Open the engagement in your preferred agent** (Kiro, Claude Code, or Copilot) and invoke
   the skill using its trigger phrase or slash command. Confirm the skill behaves as expected.

### Test the refresh path

If your change affects a file that refresh manages:

```bash
# Simulate a refresh after updating the submodule
git submodule update --remote .skill-repos/discovery-kit
python setup.py --refresh
```

Confirm that:
- Modified skill files are detected if you have local changes
- The overwrite / skip / diff prompt appears correctly
- A clean install installs without errors

### Testing across two different engagement types

Run the same skill against a mock AWS engagement (activate `aws` pack) and a mock core-only
engagement (no platform pack) to confirm client-agnostic behaviour:

```bash
# AWS engagement
python setup.py  # select aws pack
# Core-only engagement
python setup.py  # deselect all platform packs
```

Both should install successfully and the skill should work without referencing AWS-specific
concepts when running in the core-only mode.

---

## 3. Skill quality checklist

Before submitting a PR, verify every item below:

- [ ] **`SKILL.md` is present** — the skill directory contains a `SKILL.md` with at minimum:
  a skill name heading, a one-paragraph description, and at least one invocation example.

- [ ] **Client-agnostic** — the skill contains no hardcoded client names, Confluence space
  keys, GitHub organisation URLs, AWS account IDs, team member names, or any other
  engagement-specific identifiers. Search for obvious offenders:

  ```bash
  grep -ri "client-name\|acme\|atlassian.net\|123456789" \
      .skill-repos/discovery-kit/skills/<skill-name>/
  ```

- [ ] **Reads env vars via `read_env_var()`** — any client-specific value the skill needs at
  runtime (Confluence URL, space key, AWS region, client name) must come from the environment.
  The skill must never assume a value for these. Reference pattern:

  ```python
  # Skills reference env vars by name in SKILL.md instructions, e.g.:
  # "Read CONFLUENCE_SPACE_KEY from environment before querying Confluence."
  ```

  Skill SKILL.md files should document which environment variables they require.

- [ ] **At least one example invocation** — `SKILL.md` must include at least one concrete
  example of how a consultant invokes the skill, showing both the trigger phrase and the
  expected agent behaviour.

- [ ] **No bash scripts** — if the skill includes automation scripts, they must be Python 3.10+
  using `pathlib` and `subprocess.run()` with list args. See `scripting-standards.md`.

- [ ] **Graceful missing env var handling** — if the skill runs a Python helper script, it must
  exit with a non-zero status and a clear error message if a required env var is not set.

---

## 4. Release process

Releases are cut from the `slalom-discovery-kit` and `discovery-toolkit-template` repos
independently. The version in `pyproject.toml` (for `setup.py` and helper scripts) tracks
the template version.

### Steps to cut a release

1. **Update `CHANGELOG.md`** — move items from `[Unreleased]` into a new version section
   using the format in `CHANGELOG.md`. Add today's date.

   ```markdown
   ## [0.2.0] — 2026-09-01

   ### Added
   - ...

   ### Changed
   - ...
   ```

   If there are breaking changes, include the full migration section (see the template at the
   bottom of `CHANGELOG.md`).

2. **Bump the version in `pyproject.toml`:**

   ```toml
   [project]
   name = "discovery-toolkit"
   version = "0.2.0"
   ```

3. **Open a PR** against `main` on the template repo with the CHANGELOG and version bump.
   Require one maintainer approval.

4. **After merge, tag the release:**

   ```bash
   git tag -a v0.2.0 -m "Release 0.2.0 — <one-line summary>"
   git push origin v0.2.0
   ```

5. **Create a GitHub Release** from the tag. Paste the CHANGELOG entry for this version as
   the release notes body. Do not delete or force-push published tags.

6. **Notify running engagements** — post in the toolkit Slack channel (or equivalent) with
   a summary of what changed, especially if there are breaking changes requiring migration.

### Breaking changes

Any change that requires consultants on running engagements to take manual action before
running `python setup.py --refresh` is a breaking change. Breaking changes:

- Require a major version bump (1.x.0 → 2.0.0) or minor if still pre-1.0
- Must include migration instructions in `CHANGELOG.md` using the provided template
- Should be batched where possible to minimise migration burden on running engagements

---

## 5. Governance and branch protection

- The `main` branch of `discovery-toolkit-template` and `slalom-discovery-kit` is protected.
  Direct pushes are blocked. All changes require a PR with at least one maintainer approval.
- Maintainers are listed in `CODEOWNERS` (Slalom internal GitHub org).
- All Slalom consultants have read access to both repos.
- Write access to the default branch is restricted to toolkit maintainers.
- Feature branches (`feat/*`, `fix/*`) are freely creatable by contributors.
- Semantic versioning applies: `MAJOR.MINOR.PATCH`. Pre-1.0 breaking changes bump MINOR.
