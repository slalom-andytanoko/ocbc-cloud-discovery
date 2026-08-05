# slalom-pptx

Two master templates: `slalom` (classic; 141 catalogued layouts across 14 categories, 80 brand icons, 44 brand photos (38 pickable)) and `build` (sleek minimal; 122 layouts across 12 categories, 97 brand icons, 37 brand photos (33 pickable)). Slides, icons, and photos each ship as a single consolidated JSON catalog per template under `assets/templates/<id>/`; agents **search and access them through CLI getters** (slides: `find_slides.py`; icons: `get_icon_info.py`; photos: `get_photo_info.py`) that return one entry / a filtered shortlist at a time. **Reference layouts by slug, not idx** — search with `find_slides.py`, extract with `scripts/lib/extract_layouts.py --out working.pptx <slug ...>` (it resolves the slug to the current master idx via the catalog, so prose never carries a drift-prone number; `rearrange.py` is the underlying idx-only primitive it wraps). Slide visual previews are not pre-baked — render thumbnails on demand via `preview_layouts.py` / `scripts/vendor/modern/thumbnail.py`.

## Instructions

---
name: slalom-pptx
description: >
  Creates Slalom-branded PowerPoint presentations and decks from the official
  Slalom master templates (classic brand-forward and sleek minimal Build),
  handling layout selection, icon/text/photo swaps, and faithful template-based
  slide construction. Use for any deck, slides, one-pager, or PowerPoint output
  that should follow Slalom branding, colors, layouts, or visual style. Triggers
  on: "Slalom presentation", "Slalom deck", "Slalom slides", "branded pptx",
  "Slalom template", "Slalom Build deck", "Build-style", "sleek minimal
  Slalom deck" - and on adjacent phrasings even when "Slalom" is not
  spoken: "client kickoff deck", "QBR slides", "QBR deck", "proposal one-pager",
  "RFP response deck", "internal pitch deck", "client status deck",
  "executive summary slides". Also triggers on icon swaps, text replacement, and
  layout selection on an existing Slalom deck.
---

# Slalom PPTX Skill

Two master templates: `slalom` (classic; 141 catalogued layouts across 14 categories, 80 brand icons, 44 brand photos (38 pickable)) and `build` (sleek minimal; 122 layouts across 12 categories, 97 brand icons, 37 brand photos (33 pickable)). Slides, icons, and photos each ship as a single consolidated JSON catalog per template under `assets/templates/<id>/`; agents **search and access them through CLI getters** (slides: `find_slides.py`; icons: `get_icon_info.py`; photos: `get_photo_info.py`) that return one entry / a filtered shortlist at a time. **Reference layouts by slug, not idx** — search with `find_slides.py`, extract with `scripts/lib/extract_layouts.py --out working.pptx <slug ...>` (it resolves the slug to the current master idx via the catalog, so prose never carries a drift-prone number; `rearrange.py` is the underlying idx-only primitive it wraps). Slide visual previews are not pre-baked — render thumbnails on demand via `preview_layouts.py` / `scripts/vendor/modern/thumbnail.py`.

## Quick reference — what to do, where to go

Start here. Each row is the build moment → the one next move. `⚠️` marks a step real sessions skipped; don't.

| Your situation | Do this |
|---|---|
| **Multi-slide deck** (≥3 slides, or any layout choice) | ⚠️ Ask the **Step 2 mode gate as its own question, before the spine**, then read `references/planning.md` and run its wizard (both modes). Skipping planning is how decks go flat. |
| **One slide / small text edit** (≤2 slides, no new layout) | Skip planning → Step 3 → Workflow A in `references/workflows.md`. |
| **Picking a layout** | `find_slides.py` (`--category`/`--content-shape`/`--facet`/`--intended-use`) + `references/selection.md` (the mood→query matrix). |
| **A layout reports `icon_slots`/`photo_slots`** | ⚠️ Run the asset chain, don't eyeball: `recommend.py` → if empty/low-confidence, `get_icon_info.py --tag/--search`; photos → `get_photo_info.py --for-slide`. Never ship the master default icon/photo. |
| **A layout carries a `contrast_advisory`** | Read your template's `colors.md` approved text/bg combos before writing text (non-light fields clash easily). |
| **Building the slide** | `references/workflows.md` (toolbox A/B/C); `references/patterns.md` / `patterns-advanced.md` for tables, device screens, a 4th callout, or removing master extras — reuse the recipe, don't hand-roll it. |
| **Before delivery** | ⚠️ `python3 scripts/lib/verify.py output.pptx`, then **`Read` every ship render and `d3diff` PNG it lists**. For a client deck also check `references/template-guidance.md` §Accessibility (alt text) + finalization. |

The full tool + reference catalog lives in your template's `references/templates/<id>/index.md` (Step 3). Load only what the row above sends you to.

## Step 0: Preflight

Run the bundled platform-aware preflight script first. It detects every dependency the skill needs and (with `--install`) installs the ones that are missing:

```bash
python3 scripts/preflight.py           # detect only
python3 scripts/preflight.py --install # detect + auto-install
```

If a dependency is missing and you're not ready to auto-install, ask the user before installing — phrase as "X is needed for [specific task]; install with `<command>`?"

If you want to verify by hand, here's what each dependency does, how to detect it, and how to install it (the preflight script picks the right install command automatically; the Install column is the manual fallback):

| Dependency | When required | Detect with | Install |
|---|---|---|---|
| Vendored `pptx` primitives (in this skill) | Always — bundled at `scripts/vendor/` | `[ -f scripts/vendor/legacy/rearrange.py ]` | bundled; nothing to install |
| `python-pptx`, `Pillow`, `defusedxml`, `six` | Always (`Pillow` also drives Pattern 7 device-screen work — aspect/opacity checks and no-browser screen recreation) | `python3 -c "import pptx, defusedxml, six; from PIL import Image"` | `pip install python-pptx Pillow defusedxml six 'markitdown[pptx]'` |
| `markitdown[pptx]` | Always (Step 5 verify) | `python3 -m markitdown --help` | (covered by the `pip install` above) |
| LibreOffice (`soffice`) | On-demand thumbnails (pre/post-synthesis) and Step 5 visual verify | `command -v soffice` (or `command -v libreoffice`) | macOS `brew install --cask libreoffice`; Debian/Ubuntu `sudo apt-get install -y libreoffice`; Fedora/RHEL `sudo dnf install -y libreoffice`; Windows `winget install --silent TheDocumentFoundation.LibreOffice` |

The vendored tree is hybrid:

- **`scripts/vendor/legacy/`** — `rearrange.py`, `replace.py`, `inventory.py` with in-house patches for read-only-master handling, layout-aware overflow detection, and omit-vs-blank semantics. Used by Workflow A (Template Replace).
- **`scripts/vendor/modern/`** — `clean.py`, `unpack.py`, `pack.py`, `validate.py`, `thumbnail.py`, plus `helpers/`, `validators/`, and `schemas/`. Used by Workflow C (Faithful OOXML) and on-demand thumbnails. Smart quotes are auto-escaped on unpack and unescaped on pack.

Call vendored scripts for every file mutation. They are the canonical OOXML surface; reimplementing them risks subtle bytes-differ-from-PowerPoint bugs. See `scripts/vendor/VENDOR.md` for provenance and patch details.

On split-filesystem hosts (a sandbox/VM whose mounted output dir is separate from where your `Read` runs), do unpack/edit/pack in a VM-local tmp dir (create one with `mktemp -d`) and copy only the final `.pptx` to the mounted dir — files `pack.py` writes onto the mount can be non-removable on a second cycle (`rm: Operation not permitted`), and `unpack` overwrites in place so stale state can linger. The image tools (`preview_layouts.py`, `thumbnail.py`, `d3diff.py`) take `--out-dir`/`--out` so the JPG/PNG **lands** on the mount where your `Read` can reach it — but the path they **print** is still VM-side, so translate the printed path host-side (or `Read` the copy you wrote to the mount) before `Read`-ing it; the printed path itself usually won't resolve from where `Read` runs.

## Step 1: Pick the template

Two master templates ship; every getter call below takes `--template <id>` and the index router lives at `references/templates/<id>/index.md`. Pick once, up front:

| id | Look | Pick when the user says |
|---|---|---|
| `slalom` | Brand-forward classic: Slalom Blue #0C62FB, 5-color accent stripe, white/light fields | (default) any Slalom deck ask with no style signal |
| `build` | Sleek minimal: Cool Black #09091C base, single cyan accent #1BE1F2, dark/light/cyan background discipline | "Build", "Build-style", "Slalom Build", "sleek", "minimal/dark Slalom look" |

`slalom` is the default - use it whenever the request carries no style signal (e.g. "client QBR deck"). Route to `build` on the trigger words above or when the user shows a Build-styled reference deck. Ask only when the user signals a style neither template matches (e.g. asks for colors or a look that is neither classic nor Build); never interrogate a routine request. Carry the chosen `--template <id>` through every getter call for the rest of the session.

**A skill bundle may ship only one template.** This skill is distributed two ways: a unified plugin carrying every template (the routing table above applies), and per-template skill-upload zips that each ship exactly one template. The getters self-scope to whatever is present, so don't assume both templates exist on disk - query the available set (`python3 scripts/lib/find_slides.py` with no `--template` resolves the present default; the bundled template is the default automatically) and use what is present. In a single-template bundle the table collapses to the one shipped template and `--template` is optional.

**Non-branded PowerPoint with no Slalom constraint** (a plain deck that needn't follow any Slalom template, colors, or layouts) is not this skill's job - use the bundled `pptx` skill instead. Everything below assumes a Slalom-branded target.

## Step 2: Plan the deck spine

**Collaboration gate — for a multi-slide deck, the mode question must precede Phase 1 (drafting the spine), picking a layout, or extracting a slide, and must be its OWN standalone question.** Asking content-scoping questions or reading `references/planning.md` first is fine (chat hosts clarify before working) — what is NOT fine is folding the mode choice into a content question, inferring it, or starting the spine without it. For a single slide or a small edit, skip to Step 3 and do not ask. A *small edit* = no new layout selection AND ≤2 slides touched; any request that touches ≥3 slides **or** requires choosing/changing a layout is a multi-slide deck and the gate applies, regardless of phrasing — **when in doubt, treat it as a multi-slide deck and ask.** The one question: **"take the reins"** (you plan, pick every layout, and build autonomously — but still render + self-inspect each high-impact candidate before locking; you only drop the user show/feedback round, never the look) vs **"guided wizard"** (the user steers the spine, mood, and per-slide layout swaps). It is a *process* question, not content — ask it **even if the deck's scope and content are already clarified**; a detailed brief is not permission to skip it, and an agent that already asked content questions must not fold it in. Do not proceed until it is answered, and **record the user's literal answer** (it populates the build's provenance `mode` / `mode_source` at extract time, so a later mode claim has a source to point at instead of being confabulated).

**Take-the-reins is never the agent's default — it is selected exactly two ways: the user explicitly chooses it, or the run is genuinely headless and no user answer can ever come back.** "Genuinely headless" = a batch / cron / CI invocation with no human in the loop. An interactive agent or coding-assistant host is **not** headless: any host where a person is reachable — including ones that run autonomously, drive you through an agent loop, or ask you to be brief — can still surface this one question and relay the answer, so you **must** ask, even mid-autonomous-run. If a user could possibly see the question, the run is interactive; ask. Only when the host truly cannot return an answer do you state the fallback ("proceeding take-the-reins by necessity — headless run; tell me to stop for a guided pass") and proceed. Defaulting to take-the-reins because asking felt heavy, or because the host is autonomous, is exactly the failure this gate exists to prevent. Matters most on client decks, where unilateral layout picks carry the most risk.

For any **multi-slide deck**, read `references/planning.md` and run its flow before building. It exists because the picker, left alone, gravitates to the flattest layout — so plan *structure* before *text* and elicit *mood* before locking layouts. The wizard's **process is a fixed contract; the questions and candidate layouts are inferred from context, not scripted.** `references/planning.md` is the authoritative contract — **the inline outline below is a map, not a substitute.** `references/planning.md` carries detail that lives nowhere else (the product/device-screenshot smell, the `preview_layouts.py --out-dir` / `--contact-sheet` flags); read it for any multi-slide deck, in **both** modes. This is the outline:

1. **Mode prequalifier (Phase 0):** the collaboration gate above. Honor the answer — take-the-reins runs the **identical flow** and infers every wizard input from context (recording the assumptions in the spine spec); it drops only the user show/feedback round, never a phase or the render/self-inspect/strict-D3.
2. **Draft the spine (Phase 1):** decompose the request into ordered slides, each with a `content_shape` (the structural anti-generic signal) — not "headline + bullets" by default.
3. **Infer mood (Phase 2; always — guided asks, take-the-reins infers):** derive the mood axes from audience, deck type, and context. Guided: ask only the axes the context leaves open (not a fixed script), and **ground each question in this deck's subject/audience/stakes — never the bare axis name** ("What tone?" is a failure; ask about *their* deck and map answers silently to facets). Take-the-reins: apply the house-style defaults table in `references/planning.md` Phase 0, state the assumed values, and proceed silently — never skip mood derivation.
4. **Resolve + classify layouts (Phase 3):** per slide, shortlist chosen + alternatives (visual-investment=invest ⇒ photo variant leads on the cover/close); classify each high-impact (layout changes the story) vs structurally-forced (boilerplate).
5. **Layout proposal loop (Phase 3b; both modes):** for each high-impact slide, render candidates with `python3 scripts/lib/preview_layouts.py --template <id> <slug ...>` and inspect them — **`Read` each printed thumbnail path to actually see the JPG; the viewer the tool launches is for the user, and a caption line is not an inspection.** **Guided:** always show the user the rendered image — **never propose by prose or wireframe alone** — take feedback, re-render on changes, and lock; don't auto-pick. **Take-the-reins:** still render + `Read` every candidate's thumbnail yourself (non-negotiable, not the user's to waive — take-the-reins drops only the user show/feedback round, never the render or the look), then auto-lock. Forced slides collapse to one compact review table.
6. **Wizard gate (Phase 4):** before verify, confirm each high-impact slide's candidates were rendered + shown + user-locked (guided) or rendered + self-inspected (take-the-reins), then run the variety check (flag monotony).

For a **single slide** or a small edit (no new layout selection, ≤2 slides touched), skip planning and go straight to Step 3.

## Step 3: Route to the right reference (don't read them all)

Your template's full catalog is `references/templates/<id>/index.md` (the id from Step 1) — every getter's flags, the per-category slide files, all asset paths. **Pull a reference only when a row below (or the Quick reference up top) sends you there.** An agent that reads everything wastes context; one that reads nothing ships flat. Every `scripts/lib/` script answers `--help` for its full flags.

| When you're… | Pull / run |
|---|---|
| planning a multi-slide deck | `references/planning.md` (the wizard contract) — mandatory, both modes |
| translating audience/mood → a layout | `references/selection.md` + `find_slides.py --facet/--content-shape/--intended-use` (mood→query) |
| picking a layout in a category | `references/templates/<id>/slides/<category>.md` (categories are per-template — never assume one template's names on the other) |
| reading one layout's shapes/fonts | `get_inventory.py <slug>` — `_meta` picker context + `slide-N` shape data in one call (iterate keys, skip `_meta`) |
| choosing icons / photos for a slot | `recommend.py <slug>` → if empty/low-confidence, `get_icon_info.py --tag/--search`; photos → `get_photo_info.py --tag/--for-slide` |
| brand colors / fonts / footer / approved combos | `references/templates/<id>/colors.md` |
| building (text swap, OOXML edit, generated asset) | `references/workflows.md` (A/B/C, Icon Swap, thumbnails); recipes → `references/patterns.md` / `patterns-advanced.md` |
| verifying | `references/verify.md` + `python3 scripts/lib/verify.py output.pptx` |
| design system / font tiers / accessibility / finalization | `design-system.md` / `font-sizes.md` / `references/template-guidance.md` |

**Do NOT `Read` the catalog JSONs** (`slides-catalog.json`, `icons-catalog.json`, `photos-catalog.json`) — always go through the getters; that's the progressive-disclosure contract. Getter output carries the `icon_slots`/`photo_slots`/`contrast_advisory` signals and `NEXT:` nudges that tell you the next tool. `jq` is the power-user fallback.

### Selection workflow (chaining the tools)

For any slide that needs branded assets, the selection pipeline is below. **`<id>` and the slugs are placeholders: substitute YOUR Step 1 `--template <id>` and your template's own slugs** — a slug from one template does not exist on the other, and `slalom` is not even a valid template in a Build-only bundle (the commands below use illustrative classic slugs purely to show the chaining). The angle brackets are there to force the substitution.

```bash
# 1. Pick the layout: search the catalog by content_shape + mood facets (see selection.md
#    for the mood->query matrix). Filters AND-combine; returns idx + facets + summary + caveats.
python3 scripts/lib/find_slides.py --template <id> --category cover-slides --facet background=photo
python3 scripts/lib/find_slides.py --template <id> <cover-slug>   # full when_to_use for a finalist
#    (raw `jq '.slides[] | select(...)'` on the template's slides-catalog.json is the power-user fallback.)

# 2. Confirm the pick + get shape data in one call (returns _meta + slide-N keys).
python3 scripts/lib/get_inventory.py --template <id> <cover-slug>

# 3. Pick coordinated icons + photos (good starting shortlist).
python3 scripts/lib/recommend.py --template <id> <cover-slug>

# 4. (Refine) Filter icons by meaning if the shortlist misses; --tag is AND-intersected.
#    To enumerate all icons first (broad inventory: name + tags + one-line when_to_use per row):
python3 scripts/lib/get_icon_info.py --template <id> --list
#    Then narrow by tag (AND-intersected) or look up a specific candidate:
python3 scripts/lib/get_icon_info.py --template <id> --tag outcome --tag growth
python3 scripts/lib/get_icon_info.py --template <id> <icon-slug>   # read when_to_use to disambiguate

# 5. (Refine) Filter photos by 4-axis tags or by what the layout currently uses.
python3 scripts/lib/get_photo_info.py --template <id> --tag subject=person --tag mood=formal
python3 scripts/lib/get_photo_info.py --template <id> --for-slide <cover-slug>

# 6. Extract icon binaries on demand (slalom: PNG + SVG written together; build: SVG only).
python3 scripts/lib/icons.py --template <id> \
    --icon <icon-slug> --out /tmp/<icon-slug>.png
```

Picker-tool boundaries:
- Three distinct tools, don't conflate: `preview_layouts.py` renders + shows candidate **layouts** (the proposal loop); `open_image.py` opens any **image** (the primitive it wraps); `recommend.py` suggests coordinated **icons + photos for a chosen layout**, not layouts.
- `recommend.py` is a starting shortlist, not a verdict — always read the candidates' `when_to_use` prose before locking in a choice. It works best for layouts whose category maps to a clear slot (`cover-slides` -> `slot=cover` photos, `closing-and-copyrights` -> `slot=thank-you`/`closer` photos, `charts-and-graphs` -> `data`-tagged icons). For categories with no slot mapping (content-layouts, layouts-larger-body), photo recommendations fall back to mood overlap only.
- `--tag` on `get_icon_info.py` is AND-intersected. `--tag axis=value` on `get_photo_info.py` is AND both ways: AND across axes, and AND within an axis when you repeat it — a repeated axis keeps only photos carrying ALL the listed values (e.g., `--tag mood=formal --tag mood=cool` keeps only photos tagged BOTH formal and cool, and returns nothing if none carry both).
- Reading the JSON catalogs directly (`Read .../icons-catalog.json`) defeats progressive disclosure - always go through the getters.

## Step 4: Compose tools across workflows

Workflows A, B, and C are a **toolbox**, not a menu. For any Slalom-branded slide, start with A's tools and reach for C or B per element as the slide demands. The labels are kept for backwards compatibility with the procedures in `references/workflows.md`; the relationship between them is composable.

- **A's tools — `extract_layouts.py` extract (by slug) + `replace.py` text-swap.** This is the **default starting move** for any branded slide. Pull a slide from the master by slug (`extract_layouts.py --out working.pptx <slug>`; it resolves slug→idx via the catalog), then swap the text shapes you need to change. Most slides go no further than A. `extract_layouts.py` also writes `working.pptx.provenance.json` (the ordered slugs, plus `mode`/`mode_source` for you to fill from the Step 2 answer) — the `verify.py` gate reads it to self-trigger the mixed-tool + photo-led checks.
- **C's tools — `unpack.py` → edit slide XML → `pack.py` → `validate.py`.** Use these to **extend A** when the slide needs shapes the master doesn't carry: a 4th callout in a 3-callout layout, a merged photo block from another slide, an extra divider. You stay on the A-extracted slide; C just adds what the master lacks.
- **B (PptxGenJS) — primarily an asset generator.** Render custom charts, diagrams, or dataviz as PNG, then drop them into an A- or C-built slide as an image. Reserve "B for the whole slide" only for explicitly throwaway content where the user has waived Slalom branding fidelity.

Pick the toolbox combination that fits the slide. Common patterns are recipe-ized in `references/patterns.md` (recipes 1-5) and `references/patterns-advanced.md` (recipes 6-8 + run-formatting mini). Step-by-step procedures for A, B, and C live in `references/workflows.md`; D (verify) is in `references/verify.md`.

> **Soft line breaks in inventory text use `\x0b` (vertical tab).** That's how python-pptx represents `<a:br/>` from the master. Keep VTs in your replacement JSON — `replace.py` splits on `\x0b` and emits real OOXML breaks. Full details: `references/workflows.md` § *Pitfalls*.

## Step 5: Verify (Workflow D) — run the gate

After every generated `.pptx`, run the **executable gate**:

```bash
python3 scripts/lib/verify.py output.pptx
```

It runs the whole of Workflow D for you: **D0** the 11 renderer-independent lints (incl. `missing-alt-text`), **D1** text (markitdown, auto-falling back to a python-pptx dump on swapped/SVG media), **D2** shape-type structure, and **D3** a single-pane ≥1200px ship render of every slide. It **auto-generates** those renders, **self-triggers** a `d3diff.py` BEFORE/AFTER on any mixed-tool slide and flags a default photo left on a photo-led layout (both read from the `extract_layouts.py` provenance sidecar), and writes the audit record `<deck>.verify.json`. Full spec + the 11-lint detail + the manual D0-D3 fallback: `references/verify.md`.

**Deliver on exit 0 — but `⚠️ Required`: first `Read` every artifact the gate lists.** Exit 0 is necessary, not sufficient. The ship renders and the `d3diff` BEFORE/AFTER PNGs are the *only* check that catches a swap that landed wrong — a recolored icon, a shifted screen, an off-brand photo all pass D0–D2 and the exit code. The gate generates them; reading them is the step that clears the gate, not an optional extra. A mixed-tool/photo deck is not done until each `d3diff-*.png` has been `Read`. The verdict logic:
- **exit 1 (hard FAIL)** — a D0 FAIL, a D1 `_x000B_` escape leak, or a required render/d3diff artifact that didn't materialize. Fix and re-run.
- **needs-review** — a heuristic flag (default photo, mixed-tool suspicion, the alt-text WARN). Look at the flagged slide; re-run with `--reviewed` to record you did and clear the gate. `--quick` skips D3 for fast iteration (not a ship verdict).
- **unverified-d3** — no LibreOffice: D0/D1/D2 still enforced; install it or open the deck in PowerPoint before shipping.

For a **multi-slide deck**, first run the **wizard gate** from `references/planning.md` Phase 4: (1) confirm each high-impact slide was rendered + shown + user-locked (guided) or rendered + `Read`-by-you (take-the-reins — you Read the thumbnail JPGs into context, not just their captions); and (2) flag monotony (e.g. >3 consecutive slides sharing the same `content_shape`, or a deck that never uses a proof shape like `stat-grid` / `outcome-story` / `chart` / `quote-hero`). The wizard gate verifies the *plan*; `verify.py` verifies the *built file*. Both are required.

If the session contained material improvement signal — see `references/feedback.md` for the warrant heuristic — offer the user a feedback path before going idle. Default is silence.

