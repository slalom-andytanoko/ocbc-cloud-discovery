---
name: deliverables
description: >
  Generate discovery deliverable artefacts by synthesising findings, gap analyses, open questions,
  and wiki knowledge into structured output documents. Produces the prioritised remediation backlog,
  current state summary, and recommendations that form the final discovery output.
  Use when the user says "/deliverables", "generate deliverables", "produce the backlog",
  "create the recommendations", "build the final output", or "what do we deliver".
---

# Deliverables — Discovery Artefact Generation

You are generating the final deliverable artefacts for the client AWS Landing Zone discovery engagement. These documents synthesise everything in the wiki into structured outputs suitable for stakeholder review and handoff.

---

## Execution Notes

**Model recommendation:** This skill produces stakeholder-facing documents that require careful reasoning about priority, risk calibration, and consistency across multiple source documents. Use a **thinking/reasoning model** (e.g., Claude with extended thinking, o1/o3) when generating deliverables. The extra reasoning quality justifies the cost for these high-stakes outputs.

**Do not rush:** Read all sources before writing. Contradictions between sources should be surfaced, not papered over. If a finding's severity feels wrong after reading the full context, adjust it with a note explaining why.

---

## Deliverables Mode

All client-facing deliverable files respect the `DELIVERABLES_MODE` environment variable:

| Mode | Behaviour |
|------|-----------|
| `draft` (default if unset) | Filenames include `-DRAFT` suffix. PowerPoint slides include a diagonal "DRAFT" watermark. |
| `prod` | Clean filenames (no suffix). No watermark. Only use when ready for client delivery. |

**Rule**: When `DELIVERABLES_MODE=draft`, ALL generated client-facing files MUST include `-DRAFT` in their filename. This prevents accidental delivery of draft content.

### How Scripts Resolve DELIVERABLES_MODE

Scripts load the mode using this pattern (implemented in all generators):

1. Try `os.environ.get("DELIVERABLES_MODE")` — shell environment takes precedence
2. If not set in shell, read from `.env` file at repo root using:
   - `python-dotenv` (`load_dotenv`) if available
   - Fallback: manual `key=value` parsing with `os.environ.setdefault()`

This means you can set `DELIVERABLES_MODE=prod` in `.env` once and all scripts will use it without needing to prefix every command. Shell env vars still override `.env` for one-off draft runs:

```bash
# Uses .env value (prod if set there)
python3 deliverables/generate-assessment-presentation.py

# Override for a one-off draft
DELIVERABLES_MODE=draft python3 deliverables/generate-assessment-presentation.py
```

**When writing new generator scripts**, include this `.env` loading block after imports:

```python
_env_file = Path(__file__).parent.parent / ".env"
if _env_file.exists():
    try:
        from dotenv import load_dotenv
        load_dotenv(_env_file)
    except ImportError:
        for line in _env_file.read_text().splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                key, _, val = line.partition("=")
                os.environ.setdefault(key.strip(), val.strip())
```

---

## Output Location

All deliverables go to `deliverables/` at the vault root:

```
deliverables/
├── findings.md                        — Central findings register (source of truth)
├── backlog/                           — Individual backlog items (one .md per finding)
│   ├── index.md                       — Dataview dashboard + embedded items
│   ├── presentation.md                — Internal presentation (Obsidian embeds)
│   ├── presentation-client.md         — Client-safe presentation (inlined, no embeds)
│   ├── presentation-workload-readiness.md — Focus-area grouped deck for workload onboarding
│   ├── SEC1-hardcoded-api-credential.md
│   ├── SEC2-no-encryption-controls.md
│   └── ...
├── discovery-assessment.pptx          — Full assessment deck (29 slides, auto-generated)
├── exec-summary.pptx                  — Executive summary deck (8 slides, auto-generated)
├── backlog-workbook.xlsx              — Unified client-handover workbook (all columns; see note below)
├── raid.md                            — RAID log (Risks, Assumptions, Issues, Dependencies)
├── current-state-summary.md           — Executive summary of the current Landing Zone state
├── recommendations.md                 — Consolidated recommendations grouped by domain
├── gap-analysis-full.md               — Comprehensive gap analysis across all domains
├── backlog-workbook.md                — Optional Markdown wiki version of the workbook
├── generate-assessment-presentation.py — Generator script for the full assessment deck
├── generate-exec-summary.py           — Generator script for the exec summary deck
└── estimation-config.yaml             — Phase assignments, effort config (source of truth)
```

> **Note:** `assessment-findings-workbook.xlsx` has been retired. Use `backlog-workbook.xlsx` as the sole client-handover Excel file. The `generate-workbook.py` script has been deleted — do not regenerate it.

---

## Before You Start

1. **Read `deliverables/findings.md`** — the central findings register (all HRI/MRI/IMP findings)
2. **Read all `synthesis/` pages** — gap analyses and cross-cutting conclusions
3. **Read `open-questions.md`** — unresolved questions that may become backlog items
4. **Read `reference/org-roadmap.md`** — roadmap items that affect the backlog
5. **Read `docs/team-input.md`** — team opinions and contextual input (influences severity, priority, and tone)
6. **Read `index.md`** — understand what concept/entity pages exist for current-state summarisation
7. **Read key concept pages** — ou-structure, identity-architecture, security-architecture, network-topology, terraform-cloud-iac, tagging-standards, account-vending

**Do NOT use as deliverable sources:**
- `TASKS.md` — internal project tracking for the Slalom discovery team, not client-facing
- Agent framework directories (`.kiro/`, `.claude/`, `.github/copilot/`) — tooling configuration
- `docs/repos/README.md` — internal repo documentation

---

## Invocation Commands

| Command | Behaviour |
|---------|-----------|
| `/deliverables` | Generate all artefacts (except gap-analysis-full which requires all sessions complete) |
| `/deliverables backlog` | Generate/refresh individual backlog item files from findings.md into `deliverables/backlog/` |
| `/deliverables workbook` | Generate `backlog-workbook.xlsx` from `deliverables/backlog/` (reads frontmatter + body) |
| `/deliverables workbook md` | Generate both the workbook and a Markdown wiki version (`backlog-workbook.md`) |
| `/deliverables workbook refresh` | Regenerates backlog files AND the workbook in one go |
| `/deliverables presentation` | Regenerate all presentation outputs (internal, client, workload-readiness) from backlog items |
| `/deliverables exec-summary` | Regenerate the executive summary deck (`exec-summary.pptx`) from backlog data |
| `/deliverables estimate` | Recalculate all backlog item effort_days from `deliverables/estimation-config.yaml` and update phase summary |
| `/deliverables architecture` | Generate architecture diagrams (delegates to `generate-architecture` skill) |
| `/deliverables deliver` | Copy client-facing outputs to `client-deliverables/` submodule, commit, and push to client repo |
| `/deliverables current-state` | Generate the current state summary |
| `/deliverables recommendations` | Generate the recommendations document |
| `/deliverables refresh` | Re-read all sources and update existing artefacts with new information |

---

## Shared Reference Tables

### Effort Lookup

Effort values (base days per T-shirt size, effort classification thresholds) are **project-configurable** and defined in `deliverables/estimation-config.yaml`. Do NOT use hardcoded values — always read from the project config.

See `artefacts/estimation-model.md` for the full estimation formula: `base × work_type_multiplier × complexity_uplift`.

### Base Sizing Heuristics

| Characteristic | Base Size |
|---|---|
| Config change, ≤5 accounts, no complexity | XS or S |
| Documentation or policy document | S |
| New SCP or policy with testing | M |
| Multi-account rollout with validation | M or L |
| Architectural redesign, new services | L or XL |
| Affects >5 accounts or cross-team coordination | L or XL |
| No recommendation / insufficient detail | M (default, days = 0) |

### Complexity Factors

Each applicable factor **increases the T-Shirt size by one level** (capped at XL):

| Factor | Description |
|---|---|
| Stakeholder_Involvement | Requires workshops, decision-making sessions, or cross-team alignment |
| External_Dependency | Blocked by vendors, third-party timelines, or resources outside the team's direct control |
| Consensus_Required | Needs debate, design discussion, or a decision that has not yet been made |

Example: A finding with base size S and two complexity factors (Stakeholder_Involvement + Consensus_Required) → uplift by 2 → final size = L.

### Category Prefix Map

| Category | Prefix | Example IDs |
|---|---|---|
| Security | SEC | SEC1, SEC2, SEC3 |
| Governance | GOV | GOV1, GOV2 |
| Networking | NET | NET1, NET2 |
| Operations | OPS | OPS1, OPS2 |
| Compliance | CMP | CMP1, CMP2 |

Findings with an unrecognised category use prefix **OTH** and are placed after all defined groups.

### Severity-to-Priority Mapping

| Internal Severity | Client-Facing Priority |
|---|---|
| HRI (High Risk Issue) | High |
| MRI (Medium Risk Issue) | Medium |
| IMP (Improvement Opportunity) | Low |

If a finding has an unrecognised severity value, default to **Medium** and include a warning in the generation output.

### Reference Stripping Patterns

Remove ALL of the following from client-facing output text:

- Wiki links: `[[page-name]]` → remove entirely
- GitHub markdown links: `[text](https://github.com/...)` → remove entirely
- Confluence markdown links: `[text](https://*.atlassian.net/...)` → remove entirely
- Raw GitHub URLs: `https://github.com/...`
- Raw Confluence URLs: `https://*.atlassian.net/...`
- Session source references: "Session N transcript", "Session N AI Summary"
- Internal finding IDs: "F1", "F2", etc.
- Open question references: "Q4 in open-questions", "Q2"
- Internal assignments: "Assigned to [team member]", "action item for [team member]"
- Internal status values: "Open", "Acknowledged"

**Rule**: If removing a reference leaves a grammatically incomplete sentence, rewrite the surrounding sentence to be self-contained without the removed reference.

---

## Running This Skill

### Generate All Deliverables
```
/deliverables
```
Produces all artefacts (except gap-analysis-full which requires all sessions complete).

### Generate Specific Artefact
```
/deliverables backlog
/deliverables current-state
/deliverables recommendations
```

### Generate Backlog Items
```
/deliverables backlog
```
Generates/refreshes individual backlog item files in `deliverables/backlog/` from `deliverables/findings.md`.

### Generate Backlog Workbook
```
/deliverables workbook
```
Produces `deliverables/backlog-workbook.xlsx` from `deliverables/backlog/` files.

```
/deliverables workbook md
```
Produces both the workbook and a Markdown wiki version (`deliverables/backlog-workbook.md`).

```
/deliverables workbook refresh
```
Regenerates backlog files from findings.md AND then produces the workbook (full pipeline in one go).

### Deliver to Client Repo
```
/deliverables deliver
```
Copies client-facing files (workbook, presentation, recommendations) to the `client-deliverables/` submodule, commits, and pushes to the client repo. Also updates the submodule pointer in the parent repo.

Runs: `bash ./scripts/deliver.sh`

### Generate Risk/Impact Workbook
```
/deliverables workbook-risk
```
Produces `deliverables/backlog-workbook.xlsx` — the backlog workbook (client handover). Columns: ID, Category, Title, Description, Priority, Effort, Deliverables, Risk, Impact, Notes.

Runs: `python ./scripts/generate-presentation.py deliverables/backlog/items deliverables/backlog`

### Generate Presentations
```
/deliverables presentation
```

See `#[[file:artefacts/presentations.md]]` for full details.

Produces markdown presentations (deterministic) + Slalom-branded pptx (AI-driven via slalom-pptx skill). Also generates `deliverables/backlog-workbook.xlsx`.

**Fixing visual issues in the generated PPTX:** Use the iterative pixel-scan loop documented in `#[[file:references/pptx-visual-qa-loop.md]]`. The loop converts the PPTX to PDF via LibreOffice, extracts text y-coordinates with PyMuPDF, maps them to slide inches, and confirms fixes without manual screenshots. Common bugs (Step 9c moving programmatic textboxes, table/subtitle overlap, inherited placeholder bleed-through) and their fixes are documented there.

**Visual patterns reference:** Reusable python-pptx shape patterns (rounded-rect cards, phase badges, flow diagrams) are in `#[[file:references/cool-slides-patterns.md]]`.

### Refresh (after new sessions/ingests)
```
/deliverables refresh
```
Re-reads all sources and updates existing artefacts with new information.

---

## Confluence Publishing

See **`#[[file:./artefacts/confluence-staging.md]]`** for:
- Which deliverables get published and in what format
- Confluence macro markers (`:::viewpdf:::`, `:::viewxls:::`, `:::info:::`, etc.)
- Cross-referencing rules for linking to ingested Confluence pages
- Page conventions (info panel header, full-width layout)

The `/deliverables confluence` commands delegate to the **`publish-confluence` skill**
(`./SKILL.md`), which owns all publishing mechanics.

### Confluence Invocation

```
/deliverables confluence              — publish all stale pages
/deliverables confluence landing      — publish landing page
/deliverables confluence backlog      — publish remediation backlog
```

---

## Quality Checklist

- [ ] Every finding in `findings.md` appears in the remediation backlog
- [ ] Every recommendation has a source reference (finding ID, session, or gap analysis)
- [ ] No orphan recommendations — each maps to a risk statement
- [ ] Effort estimates are calibrated (not all "Medium")
- [ ] Owner suggestions align with client team roles observed in sessions
- [ ] Executive summaries are <200 words and stakeholder-friendly
- [ ] All claims cite wiki pages as evidence
- [ ] Staleness-flagged sources are noted where applicable
- [ ] `cssclass: wide-page` on documents with tables

---

## Relationship to Other Skills

| Skill | Relationship |
|-------|-------------|
| `gap-analysis` | Produces synthesis pages that feed into deliverables |
| `wiki-synthesize` | Discovers concept connections; deliverables is the *output* synthesis |
| `wiki-query` | Used to look up specific facts during artefact generation |
| `ingest-confluence` | Feeds source material that eventually becomes findings/recommendations |
| `generate-architecture` | Produces architecture diagrams (current-state and proposed-state) as deliverables |
| `publish-confluence` | Publishes deliverables to Confluence — owns all write logic, invoked via `/deliverables confluence` |
| `findings` (steering rule) | Ensures issues are captured as they're found; deliverables consolidates them |

---

## Artefact Definitions

Detailed specifications for each artefact are in separate files:

#[[file:./artefacts/backlog-items.md]]
#[[file:./artefacts/raid.md]]
#[[file:./artefacts/current-state.md]]
#[[file:./artefacts/recommendations.md]]
#[[file:./artefacts/gap-analysis.md]]
#[[file:./artefacts/findings.md]]
#[[file:./artefacts/workbook.md]]
#[[file:./artefacts/estimation-model.md]]
