---
name: ingest-iac
description: >
  Ingest and review Infrastructure-as-Code repositories. Scans Terraform files, CI/CD workflows,
  module structure, and PR processes. Compares against IaC best practices and produces wiki knowledge
  + findings. Supports refresh when repos are updated.
  Use when the user says "/ingest-iac", "review this repo", "ingest terraform", "check IaC",
  "review the landing zone code", "refresh iac review", or adds a new repo submodule.
---

# IaC Ingest — Terraform Repository Review

You are ingesting and reviewing Infrastructure-as-Code repositories to extract architectural knowledge, assess maturity against best practices, and produce findings for the discovery engagement.

---

## Invocation Commands

| Command | Behaviour |
|---------|-----------|
| `/ingest-iac <repo>` | Full ingest + review of a single repo (submodule path or name) |
| `/ingest-iac all` | Ingest/review all repos listed in `docs/repos/README.md` |
| `/ingest-iac refresh <repo>` | Re-scan a previously ingested repo (detects changes since last ingest) |
| `/ingest-iac refresh all` | Refresh all previously ingested repos |
| `/ingest-iac add <github-url> <branch>` | Add a new repo as a submodule and ingest it |

---

## Before You Start

1. **Read `docs/repos/README.md`** — repo → branch → workspace mapping, access status
2. **Read `.gitmodules`** — current submodule configuration
3. **Read existing wiki page** — `concepts/iac-landing-zone-repos.md` (if it exists) for prior findings
4. **Load best practices** — read `./references/iac-best-practices.md`
5. **Read `.manifest.json`** — check if this repo was previously ingested (look for `docs/repos/<name>` entries)

---

## Step 1: Locate the Repository

Resolve the repo path:
- If given a submodule name (e.g., `AWS-BKL-Network`): path is `docs/repos/<name>/`
- If given a relative path: use directly
- If given a GitHub URL with `/ingest-iac add`: add as submodule first (see Step 1b)

**Verify access:**
```bash
ls docs/repos/<name>/
```
If empty, the submodule isn't checked out. Run `git submodule update --init docs/repos/<name>`.

**Switch to deploy branch:**
Check `docs/repos/README.md` for the correct branch. The deploy branch (not `main`) is what's actually running in production.

### Step 1b: Adding a New Repo

When the user provides a GitHub URL:
1. Determine the branch (user provides it, or check `docs/repos/README.md` for convention)
2. Add submodule: `git submodule add -b <branch> <url> docs/repos/<name>`
3. Update `docs/repos/README.md` with the new row
4. Update `.gitmodules` if needed
5. Proceed to Step 2

---

## Step 2: Scan Repository Structure

Read the repo and extract:

### 2a: File Inventory

- List all `.tf` files (top-level and in modules/)
- List CI/CD config (`.github/workflows/`, `.gitlab-ci.yml`, `buildspec.yml`, etc.)
- List Terraform Cloud config (`*.auto.tfvars`, `backend.tf`, `versions.tf`)
- List documentation (`README.md`, `docs/`, `CHANGELOG.md`)
- Check for lock files (`terraform.lock.hcl`)
- Check for policy files (Sentinel `.sentinel`, OPA `.rego`)

### 2b: Terraform Analysis

For each `.tf` file, extract:
- **Resources declared** — `resource "aws_*" "name"` blocks
- **Data sources** — `data "aws_*" "name"` blocks
- **Modules used** — `module "name" { source = "..." }` (local, registry, or git)
- **Variables** — inputs with types, defaults, descriptions
- **Outputs** — exported values
- **Provider configuration** — versions, regions, assume_role
- **Backend** — state storage (S3, Terraform Cloud, etc.)

### 2c: CI/CD & PR Process

Look for:
- **Branch protection rules** — (can't read from here, note as "check GitHub settings")
- **GitHub Actions / workflows** — what runs on PR, on push to deploy branch
- **Terraform plan on PR** — is `terraform plan` run before merge?
- **Terraform apply trigger** — manual vs auto-apply on merge to deploy branch
- **Required reviewers** — CODEOWNERS file, workflow approval gates
- **Linting/validation** — `terraform fmt`, `terraform validate`, `tflint`, `checkov`, `tfsec`
- **Policy-as-code** — Sentinel policies, OPA/Conftest, custom scripts

### 2d: Secrets & Credentials

Scan for:
- Hardcoded credentials (API keys, passwords, access keys in any file)
- `.env` files committed
- Terraform variables with `default` values that look like secrets
- References to secrets management (Vault, AWS Secrets Manager, SSM Parameter Store)

---

## Step 3: Assess Against Best Practices

Compare findings against `./references/iac-best-practices.md`. Score each dimension:

| Dimension | What to Check |
|-----------|---------------|
| **State Management** | Remote backend, state locking, encryption, no local state |
| **Module Design** | Reusable modules, pinned versions, no inline resources in root |
| **Provider Hygiene** | Version constraints, provider aliases for multi-region/account |
| **Variable Management** | All vars typed, sensitive vars marked, no hardcoded values |
| **CI/CD Maturity** | Plan-on-PR, apply-on-merge, no manual applies, drift detection |
| **Security Scanning** | Static analysis (tfsec/checkov), secrets scanning, policy gates |
| **Code Quality** | Formatting (fmt), validation, naming conventions, file organisation |
| **Documentation** | README per module, variable descriptions, architecture decisions |
| **Testing** | Terratest, plan assertions, integration tests |
| **Secrets Handling** | No hardcoded secrets, external secrets manager, OIDC for auth |

### Severity Mapping

| Finding | Severity |
|---------|----------|
| Hardcoded credentials in code | HRI |
| No state locking / local state | HRI |
| No plan-on-PR (changes go straight to apply) | MRI |
| No security scanning in CI | MRI |
| Missing provider version constraints | MRI |
| No module pinning (using `main` branch refs) | MRI |
| Missing variable descriptions | IMP |
| No README or architecture docs | IMP |
| No testing framework | IMP |
| Formatting inconsistencies | IMP |

---

## Step 4: Produce Wiki Knowledge

### Update `concepts/iac-landing-zone-repos.md`

Add or update the section for this repo:

```markdown
### <Repo Name>

**Deploy branch:** `<branch>` → TFC Workspace: `<workspace>` → Account: `<account>`
**Last reviewed:** <date> (commit: `<short-sha>`)

**Resources:**
- <summary of what's declared — e.g., "Organizations OU structure, account creation, GuardDuty org config">

**Modules:**
- <list of modules used, their sources>

**CI/CD:**
- <summary of PR process, apply triggers, gates>

**Findings:** F<n>, F<n> (see findings.md)
```

### Create entity pages (if warranted)

If a repo manages a distinct, significant piece of infrastructure not already documented, create an entity or concept page. For example, a dedicated GuardDuty repo might warrant an entity page.

---

## Step 5: Produce Findings

For each issue discovered, append to `deliverables/findings.md`:
- Assign ID (next F# in sequence)
- Severity (HRI / MRI / IMP)
- Domain: "IaC" or "Security" depending on the finding
- Source: commit-pinned GitHub link (`/blob/{SHA}/path/to/file#L<line>`)
- Add detail section with Risk and Recommendation

**Source link format** (commit-pinned for evidence preservation):
```
https://github.com/<CLIENT_GITHUB_ORG from .env>/<REPO>/blob/<SHA>/<file>#L<line>
```
Get SHA from: `git -C docs/repos/<name> rev-parse HEAD`

---

## Step 6: Update Tracker

Update `docs/repos/README.md`:
- Mark access status
- Update "Last Reviewed" column (add one if not present)
- Note the commit SHA reviewed

---

## Refresh Mode

When invoked with `/ingest-iac refresh <repo>`:

1. **Check for changes** — compare current HEAD SHA against the SHA recorded in `.manifest.json` or `docs/repos/README.md`
2. **If unchanged** — report "No changes since last review" and exit
3. **If changed** — run `git -C docs/repos/<name> log --oneline <old-sha>..HEAD` to show what changed
4. **Diff analysis** — focus review on changed files only (`git -C docs/repos/<name> diff <old-sha>..HEAD --name-only`)
5. **Update findings** — check if existing findings are still valid; mark resolved ones if the code has been fixed
6. **Update wiki** — refresh the repo section in `concepts/iac-landing-zone-repos.md` with new commit SHA and any changes

### Refresh All

For `/ingest-iac refresh all`:
1. Iterate through all repos in `docs/repos/README.md` with ✅ access
2. Run `git submodule update --remote` to pull latest
3. Refresh each repo that has new commits
4. Present a combined summary

---

## Report to User

After completing the review:

```
## IaC Review: <Repo Name>

**Branch:** `<deploy-branch>` | **Commit:** `<short-sha>` | **Files:** <count> .tf files
**Mode:** <initial | refresh (N commits since last review)>

### Architecture Summary
<2-3 sentences describing what this repo manages>

### Maturity Scorecard
| Dimension | Score (1-5) | Notes |
|-----------|-------------|-------|
| State Management | X | ... |
| CI/CD Maturity | X | ... |
| Security Scanning | X | ... |
| Code Quality | X | ... |

### Findings (<count>)
| ID | Severity | Finding | File |
|----|----------|---------|------|
| F<n> | HRI/MRI/IMP | ... | path/to/file |

### Changes Since Last Review (refresh mode only)
- <commit message 1>
- <commit message 2>
- Resolved: F<n> (code now fixed)
```

---

## Integration with Other Skills

| Skill | Relationship |
|-------|-------------|
| `gap-analysis` | Loads `iac-best-practices.md` reference; IaC findings feed into the gap analysis |
| `discovery-deliverables` | Findings from IaC review become backlog items |
| `ingest-confluence` | Solution design docs may reference expected repo structure |
| `security-assessment` | Hardcoded credentials and missing security scanning are security findings |

---

## ⚠️ MANDATORY Completion Checklist

**You MUST complete ALL items below before reporting success to the user. Do NOT skip any step.**

1. ✅ **`concepts/iac-landing-zone-repos.md`** — Repo section added/updated with resources, modules, CI/CD summary, and commit SHA
2. ✅ **`deliverables/findings.md`** — All new findings appended with IDs, severity, commit-pinned source links, and recommendations
3. ✅ **`docs/repos/README.md`** — Access status, review date, and commit SHA updated. Include empty repos with a note (e.g., "EMPTY — no commits").
4. ✅ **`.manifest.json`** — Entry added/updated with repo path, commit SHA, and pages_updated
5. ✅ **`index.md`** — Any new wiki pages added to appropriate sections
6. ✅ **`hot.md`** — Recent Activity updated with repo name, finding count, and review mode
7. ✅ **`log.md`** — Timestamped entry appended (e.g., "2026-06-04 — IaC ingest: AWS-BKL-Network @ abc1234 → 2 MRI, 1 IMP")

**If you skip these steps, the wiki state will drift and the next session will start with stale context.**
