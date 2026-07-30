# 07 — Manual extraction: the `PI` route

Covers `02.FOMD/03.extraction/`. Counts: `01_status.md`.

## Why this exists

Most studies in the pool need no manual work: their source synthesis already extracted everything, so they
screen as **`I`** and a script harmonizes them. But many source datasets captured only *part* of what the
Hub needs — a financial-outcomes meta-analysis extracted the economics but not the yields, a biodiversity
review recorded the taxa but not the fertiliser regime.

Those studies screen as **`PI`** — partially included. The missing practices, outcomes and moderators have to
be read off the original paper by a person. That is what this stage is.

So: **`PI` is not a quality judgement about the paper. It is a statement about the coverage of the dataset we
inherited.** → `03_somd_and_fomd.md` for both screening vocabularies.

## The flow

```
the PDF  ──►  09_FOMD_<study_id>.xlsm  ──►  01_verified_papers/<ss_id>/  ──►  01.added_to_10_FOMD/
              one workbook per paper,        checked by a second person        (next stage, not yet run)
              filled by a named extractor
              in 02.09_FOMD_extraction/<initials>/
```

- **One workbook per paper**, named `09_FOMD_<study_id>.xlsm` (sometimes with a `V2_`/`V3_` template tag or a
  `_v2` revision suffix). The `study_id` construction is in `03_somd_and_fomd.md` — remember trailing commas
  and spaces are part of it.
- **Extractor folders** under `02.FOMD/03.extraction/02.09_FOMD_extraction/`: `AS` (Andrea), `CC`
  (Charlotte), `MC` (Mario), `Mordecai`. Each may have an `old/` subfolder.
- **Promotion:** once checked, a workbook moves into `01_verified_papers/`, which is organised **by source
  synthesis (`ss_id`)**, not by extractor — the workbook returns to the synthesis it came from.
- `01_verified_papers/01.added_to_10_FOMD/` is the intended next step and is currently **empty**: no verified
  workbook has yet been merged into the template.

## What's inside a workbook

Each `.xlsm` is deliberately **self-contained** — 22–23 sheets:

- **`09_FOMD_metadata_extraction_lon`** — the data-entry sheet.
- **`09_FOMD_readme`** — the field dictionary: for each field its type, unit, description, permitted
  `values` (pointing at the governing ontology sheet) and validation rule. **This is the authority on what
  may go in a cell.**
- `09_look_up_levels` plus an **embedded copy of every ontology sheet** (`01_sites`, `01_practices`,
  `01_outcomes`, `01_product_new`, `01_countries`, `01_fertiliser`, `01_chemicals`, `01_residues`,
  `01_trees`, `01_vars_crops`, `01_vars_animals`, `01_suboutcome_units`, `01_out_econ`, `01_lookuplevels`).
- Helper sheets driving the macros: `sites_lookup`, `variety_lookups`, `breeds_lookup`, `chemical_lookups`,
  `fertiliser_lookups`.

The `.xlsm` (macro-enabled) format exists for those lookups: select a site that already exists in the
ontology and its latitude/longitude auto-populate, and fields validate against the controlled vocabulary as
you type. That is also why each workbook is large.

⚠️ **The embedded ontology copies are snapshots.** A workbook created months ago carries a months-old
vocabulary. If a term seems missing, check the live `01_FOMD_ontologies.xlsx` before requesting it.

## ⚠️ Which template version to use

Two `09_` schemas are in circulation and they are **not compatible** — 424 columns (master, `crop*` and
`tree*` separate) versus 364 (the live V3 template, `crop_tree*` merged). Every extractor workbook checked is
364. **Read `05_data_schemas.md` before creating a new workbook or writing anything that ingests them** —
merging 364-column workbooks into the 424-column master needs a deliberate split step that does not exist
yet.

The live blank template is `02.FOMD/09_FOMD_metadata_extraction_long_stats4sd_V3.xlsm` (loose at the
`02.FOMD/` root). Copy it; don't repurpose someone else's filled workbook.

## Figures and tables

Where a value only exists in a chart, it is digitised (WebPlotDigitizer per the protocol) and saved as CSV in
`03.extraction/01.table_figure_extraction/`, named `<study_id>_<Fig|Tab><n><panel>.csv` — e.g.
`JA_Adhik_18_Impac_SU_Fig1a.csv`, `JA_Kabur_08_Evalu_Jo_Tab2.csv`. Content is raw digitiser output (a label
column plus `Y` and `SE`), so it needs interpreting against the paper, not reading in isolation.

## When a paper needs a term that doesn't exist

Use **`New term request .xlsx`** — 15 sheets, one per vocabulary, each ending in `Accepted` / `Reviewer` /
`Notes` for the ontology maintainer (**Lolita**) to sign off. Record the `study_id` that needs it. **Never
edit the ontology**, and never invent a value in the data sheet hoping it will be tidied later.
→ `06_ontologies.md`

## Per-outcome extraction rules

`05_FOMD_extraction_criteria.xlsx` holds the decision rules extractors follow — how to handle
aggregated-versus-per-year values (biodiversity and economic outcomes: prefer aggregated; **yield: record
each year separately**), that intercropping systems should prioritise **LER**, one row per location per
outcome, and coordinate conversion. Several rules are explicitly inherited from the source reviews ("use the
same rules as Jones and Sanchez et al." for biodiversity, "as Paut et al." for LER, "as Sanchez et al. 2022"
for financial outcomes) so that recycled and hand-extracted data stay comparable.

Full-text exclusion criteria are the 13 named reasons in `03_FOMD_selection_criteria.xlsx`.

## For scripts and AI assistants: read-only

`03.extraction/**` is **live work by named people**, often open in Excel. Do not write to it, reorganise it,
or "clean up" filenames. Existing irregularities — a double dot in
`09_FOMD_JA_Kabur_08_Evalu_J..xlsm`, a misplaced `V3_` tag, a workbook with no `study_id` that looks like a
OneDrive conflict artefact, three `_REMOVED_DUPLICATED` files — are for the extractors to resolve, not for
you to normalise. Report them if they matter; don't touch them.

## Human training material

`how_to_use_extration_file.pptx` at the Hub root (large) walks through filling a workbook, and
`02.FOMD/Training Sessions Summary.docx` summarises the sessions run. Point new extractors there rather than
re-explaining the workbook in prose.
