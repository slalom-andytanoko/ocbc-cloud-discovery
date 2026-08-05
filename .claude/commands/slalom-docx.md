# slalom-docx

Three pre-loaded Slalom A4 templates, a per-template style vocabulary, an intent-driven template picker (`recommend_template.py "<intent>"`), a single-CLI cover/footer/property fill helper (`fill_template.py`), a body-builder for whole-body replacement (`body_builder.py`), and a five-check verification gate.

## Instructions

---
name: slalom-docx
description: >
  Create Slalom-branded Word documents using the official Slalom templates
  (proposal-and-delivery, whitepaper, letterhead). Use for any .docx output
  that should follow Slalom branding, fonts, brand palette, or template
  layout. Trigger on: "Slalom proposal", "Slalom SOW", "Slalom RFP",
  "Slalom whitepaper", "Slalom POV", "Slalom letterhead", "Slalom letter",
  "branded docx", "Slalom Word doc", "Slalom delivery doc" - and on
  adjacent phrasings even when "Slalom" is not spoken: "engagement letter",
  "client proposal", "RFP response document", "thought leadership article",
  "consultant cover letter", "executive summary memo", "solution design
  document", "deep dive", "handover", "internal briefing", "POV", "industry
  trend deep dive", "engagement letter", "NDA". Triggers on text replacement,
  branded styling, layout selection, and faithful template-based document
  construction. For non-Slalom-branded Word output (no branding constraint),
  use the bundled `docx` skill instead.
license: Proprietary. scripts/vendor/LICENSE.vendored has the upstream Anthropic terms for the vendored docx primitives; the Slalom branding assets are governed by the marketplace LICENSE.
---

# Slalom DOCX Skill

Three pre-loaded Slalom A4 templates, a per-template style vocabulary, an
intent-driven template picker (`recommend_template.py "<intent>"`), a
single-CLI cover/footer/property fill helper (`fill_template.py`), a
body-builder for whole-body replacement (`body_builder.py`), and a
five-check verification gate.

## Step 0: Preflight

```bash
python3 scripts/preflight.py           # detect only
python3 scripts/preflight.py --install # detect + auto-install
```

If a dependency is missing and you are not ready to auto-install, ask
the user before installing - phrase as "X is needed for [specific
task]; install with `<command>`?"

Scripts run in place under the skill tree; all writes target `--output`
paths or per-invocation temp dirs. The skill tree itself can be
read-only. Workflow B's `cd scripts/lib/docx-js && npm install` is the
only step that writes inside the skill tree - install Workflow B's
`node_modules` to a user-writable location if the skill tree is
read-only.

| Dependency | When required | Detect with |
|---|---|---|
| Vendored `docx` primitives | Always - bundled at `scripts/vendor/` | `[ -f scripts/vendor/office/unpack.py ]` |
| `defusedxml`, `lxml` | Always | `python3 -c "import defusedxml, lxml"` |
| `pandoc` | Verify step C1 (text extract) | `command -v pandoc` |
| Node + npm + `docx` package | Workflow B (escape hatch only) | `command -v node && npm list -g docx` |
| LibreOffice (`soffice`) | Workflow C C3 visual + accept-changes + refresh-fields | `command -v soffice` |
| `pdftoppm` (poppler) | Workflow C C3 page rasterize | `command -v pdftoppm` |

The vendored tree under `scripts/vendor/`:

- **`office/`** - upstream docx primitives: `unpack.py`, `pack.py`,
  `validate.py`, `soffice.py`, plus `helpers/`, `validators/`, `schemas/`.
  See `scripts/vendor/VENDOR.md` for provenance.
- **`accept_changes.py`** - accepts all tracked changes via LibreOffice.
- **`comment.py`** - boilerplate generator for Word comment XML.
- **`templates/*.xml`** - empty comment-XML templates the comment generator
  drops into unpacked archives when adding the first comment.

`scripts/lib/dotx_to_docx.py` does a lossless `.dotx` -> `.docx` swap
that preserves Microsoft Information Protection sensitivity labels and
the letterhead's 18 embedded font files (both dropped by
`soffice --convert-to docx`).

## Step 1: Read the index router

Read `references/index.md` first. It is a short router. Load only what
your task needs - SKILL.md + the index + one workflow file is usually
enough.

CLI getters (do NOT `Read assets/templates-catalog.json` directly):

- `python3 scripts/lib/recommend_template.py "<intent>"` - top-K ranked
  shortlist for a free-text intent description.
- `python3 scripts/lib/get_template_info.py <slug>` - one template's
  full metadata.
- `python3 scripts/lib/get_template_info.py --list` / `--search PATTERN` /
  `--tag TAG [--tag TAG2 ...]` (AND-intersected) - filter the catalog.

### Build pipeline

```bash
# 1. Pick the template.
python3 scripts/lib/recommend_template.py "deep dive on cloud migration"

# 2. (Optional) Read the top hit's full metadata.
python3 scripts/lib/get_template_info.py proposal-and-delivery-a4

# 3. Fill the cover / footer / doc-property targets.
python3 scripts/lib/fill_template.py \
    --template proposal-and-delivery-a4 \
    --output /tmp/cover.docx \
    --field project_title="Acme Cloud Migration" \
    --field client_company="Acme Corp" \
    --field prepared_by="Jane Smith" \
    --field prepared_on="May 2026" \
    --field slalom_office="Sydney"

# 4. (Optional) Replace the body, splicing on top of the filled cover.
python3 scripts/lib/body_builder.py \
    --slug proposal-and-delivery-a4 \
    --base /tmp/cover.docx \
    --input body.json \
    --output /tmp/output.docx

# 5. Refresh live fields (TOC, TITLE, STYLEREF, DATE).
#    Pass --template <slug> so the post-roundtrip unpack also re-applies
#    explicit white to brand-fill chrome runs that LibreOffice strips;
#    without it, the always-blocking
#    `header_footer_color_unset_on_brand_fill_section` contrast finding
#    will surface on output with any brand-fill section.
python3 scripts/lib/refresh_fields.py \
    --template proposal-and-delivery-a4 \
    /tmp/output.docx

# 6. Verify (Workflow C). See Step 5 for the full gate.
```

`recommend_template.py` is a starting shortlist; read the candidate's
`when_to_use` (or `get_template_info.py <slug>`) before locking it in.
Sibling-ambiguous phrases like "deep dive" land in both proposal and
whitepaper synonym lists; the audience tag (Step 3 of the picker) is
the resolution.

## Step 2: Pick the right template

If the top hit's score is clearly higher than the runner-up and its
`when_to_use_excerpt` matches your intent, that pick is final.

When two templates score close, walk the 5-step picker in
`references/selection.md`:

1. Functional fit - content shape -> candidate templates
2. Formality + length fit - narrows candidates
3. Audience + role - internal-or-client vs external-published vs correspondence
4. Sibling tie-breakers - resolve shared synonyms via context
5. Brand cross-reference - `colors.md`, `fonts.md`, `tables.md`

> All three templates are A4 (~11900 x 16838 DXA, ~8.27" x 11.69").
> Slalom's official templates are A4 globally, including for US
> engagements. The docx-js preset in `references/docx-js.md` mirrors this.

## Step 3: Gather missing key information

```bash
# Full structured walk:
python3 scripts/lib/required_fields.py <slug>

# Required-only filter:
python3 scripts/lib/required_fields.py <slug> --required-only
```

If the user's prompt already names every required field, skip ahead -
write a one-line confirmation summary first ("Drafting a proposal for
X with client Y, dated Z, prepared by W.") so the user sees what you have.

If anything is missing, ask the user via your platform's interactive
question / clarification mechanism. Batch related fields into one
interaction. For each missing field offer four options:

```
A. I'll provide the value now (free text)
B. Use a placeholder ([PROJECT TITLE], [CLIENT COMPANY], etc.)
C. Find it for me (only when public_sourceable is true)
D. Skip - leave the template's default
```

When the user picks "Find it for me", use your web search capability
to source the value. Some fields are NOT public-sourceable - notably
internal Slalom opportunity IDs and recipient personal contact
details. The catalog flags this as `public_sourceable=False`.

After sourcing, always show the value back to the user before writing
it into the document with a "use as-is / edit / skip" follow-up.

Full protocol: `references/information-gathering.md`. Slalom office
address fallback: `references/slalom-offices.md`.

When the document includes tables, see `references/tables.md`.

## Step 4: Compose tools across workflows

Workflows A, B, and C are a **toolbox**, not a menu. For any
Slalom-branded document, start with A and reach for B per element only
when A cannot produce the shape you need.

- **A. Template Replace.** The default for every branded deliverable.
  - **Cover fill**: `python3 scripts/lib/fill_template.py --template <slug>
    --output <path> --field key=value [--field ...]` walks the
    per-template sentinel map, edits cover / footer / doc-property
    targets, sanitizes `UnresolvedMention` placeholders, normalizes
    smart quotes, and repacks. Per-template boundaries:
    `references/templates.md` § *fill_template.py boundaries*.
  - **Body replace**: `python3 scripts/lib/body_builder.py --slug <slug>
    --base <cover.docx> --input body.json|body.md --output <path>`.
    Structured Python blocks (or minimal Markdown) -> branded body.
    Auto-preserves sectPr/headers/footers/TOC, auto-strips demo charts
    on `body-with-demo-objects` sections, sweeps orphaned chart parts,
    sanitizes `UnresolvedMention`, validates brand-fill safety by
    construction. Pass `--base <docx>` to splice on top of an
    already-filled cover. Library form:
    `from body_builder import Document, Heading, Paragraph, BulletList, Table`.
    Per-template section roles + page-background classification:
    `references/section-map.md`. Full recipe:
    `references/body-replace.md`.
  - **Manual escape hatch (small targeted swaps)**: when the change is
    a single-paragraph edit, unpack via
    `python3 scripts/vendor/office/unpack.py <file.docx> unpacked/`,
    edit `unpacked/word/document.xml`, and repack via
    `python3 scripts/vendor/office/pack.py unpacked/ output.docx --original <file.docx>`.
    Procedure: `references/workflows.md` § *Manual editing*.

- **B. docx-js (escape hatch).** From-scratch generation with a
  Slalom-branded styles preset. Reserve for "B for the whole document"
  when the deliverable shape does not fit any of the three templates
  and the user has explicitly waived template fidelity. **C2 lineage
  check fails on docx-js output by design** - cite the failure in the
  verification report and confirm the user waived template fidelity.

- **C. Verify.** Always last. See Step 5.

Procedures for A and B plus common mix patterns:
`references/workflows.md`.

> **Smart quotes.** `fill_template.py` and `body_builder.py` both run
> `typography.smart_quotes` on user input (straight `'` / `"` / `--` /
> `---` -> curly). When you hand-edit `word/document.xml` directly,
> use XML entities for curly quotes: `&#x2019;` (right single /
> apostrophe), `&#x201C;` `&#x201D;` (curly doubles), `&#x2018;` (left
> single). `unpack.py` already escapes these on extract.

## Step 5: Verify (Workflow C)

After every generated `.docx`, run all five C2 checks plus C3. Each
catches a different failure mode; if LibreOffice or poppler is missing,
run C1 + C2 only and flag the doc as **unverified** rather than
passing silently. Per-check evidence templates:
`references/workflows.md` § *Workflow C*.

1. **C1 Text** - `pandoc --track-changes=all output.docx -o /tmp/check.md`.
   Confirms expected text; no placeholder leakage.
2. **C2 Lineage + Structure + Contrast + Stray-objects + Brand-fill**:
   - `python3 scripts/lib/lineage_check.py output.docx --template <slug>`
   - `python3 scripts/vendor/office/validate.py output.docx --original assets/templates/<slug>.docx`
   - `python3 scripts/lib/contrast_check.py output.docx --template <slug> --original assets/templates/<slug>.docx`
   - `python3 scripts/lib/stray_objects_check.py output.docx --original assets/templates/<slug>.docx`
   - `python3 scripts/lib/brand_fill_lint.py output.docx --template <slug>`
   - `python3 scripts/lib/dangling_style_check.py output.docx --original assets/templates/<slug>.docx`
3. **C3 Visual** -
   `python3 scripts/lib/rasterize.py output.docx --out /tmp/pages/`
   followed by a visual eyeball. For 20+ page builds, add
   `--montage /tmp/contact-sheet.png` (ImageMagick) to also write a
   single tiled image - eyeballing 24 individual PNGs is impractical
   on autonomous runs and leads to under-sampled review.

### Verification gate

The doc is **NOT ready until C1, C2 (a + b + c + d + e + f), AND C3 have
all run AND been inspected, with concrete evidence cited per check.**
Implicit success ("looks good", "tests passed") is not acceptable.
Cite specific evidence (absent placeholder strings, present lineage
signatures, contrast findings count, stray-objects findings count,
brand-fill findings count, observed visual artifacts) before declaring
the doc ready.

### Refresh live fields before delivery

For deliverables with a Word TOC field, running headers carrying TITLE
or STYLEREF, or DATE fields:

```bash
python3 scripts/lib/refresh_fields.py output.docx
```

Sequence any direct `word/footer*.xml` edits AFTER `refresh_fields` -
LibreOffice may renumber footer parts during the round-trip. The
`--template <slug>` flag re-applies explicit white text to every
text-bearing run in chrome parts referenced by brand-fill sections
(via `section_resolver`), restoring the colours the round-trip strips.

**Never run `refresh_fields.py` or `soffice --convert-to docx` against
the letterhead.** The LibreOffice round-trip drops the 18 embedded
`.odttf` font files. Hand-assembly via `unpack` + `pack` preserves them;
the letterhead does not ship live fields needing refresh.

No-soffice fallback: `soffice --convert-to docx output.docx`
round-trips and recomputes fields as a side effect.

## Step 6: Write a confirmation summary

After all checks pass, write the user a 2-3 line summary of what you
produced: which template, which key fields, where the file is. Do not
paste the full document content; the user can open it.

If the session contained material improvement signal - see
`references/feedback.md` for the warrant heuristic - offer the user a
feedback path before going idle. Default is silence.

