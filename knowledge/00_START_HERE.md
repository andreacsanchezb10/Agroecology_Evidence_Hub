# 00 — Start here

This folder is the durable, **living** memory of the Agroecology Evidence Hub's data work: what the project
is, how evidence moves through it, what the shared data template looks like, the decisions we made, and
what's still open. It is written for two audiences at once — a person who needs to *use* the data, and an
AI assistant (or engineer) who needs to *change* something. Each doc leads with plain-language context,
then gives exact field names and paths.

It stays current because every task ends by updating the mapped doc (the **living-doc protocol** in
`CLAUDE.md` and `_meta/MAINTENANCE.md`).

## If you only have 3 minutes

- The Hub is a **living systematic review** answering: *how effective are agroecological farming practices
  at improving agronomic, economic, environmental and social outcomes, compared with non-agroecological
  practices?* Scope is **global**.
- Its method is **evidence recycling**. Rather than reading the primary literature afresh, it harvests the
  **primary-study-level datasets that previous meta-analyses already extracted**, harmonizes them into one
  shared template, and re-analyzes them. This single sentence explains most of the folder structure.
- Two streams: **SOMD** (the registry of the syntheses themselves) and **FOMD** (the primary studies pulled
  out of them). Most of the work here is FOMD. → `03_somd_and_fomd.md`
- The shared data template is the **`10_` schema** — one row per **Control-vs-Treatment comparison**, with
  paired `C_…` / `T_…` columns. → `05_data_schemas.md`
- **ERA is one source, not "the data".** It is the synthesis `MD_Rosen_24_Effec_Sc`, the first and largest
  of a target ten or more. Its Africa-only coverage is a property of *ERA*, not of the Hub. → `sources/ERA/`
- Work is split two ways by screening status: studies already fully extracted in a source dataset (`I`) are
  harmonized **by script**; partially-covered studies (`PI`) are extracted **by hand** from the PDF into one
  workbook per paper. → `04_workflow_and_folders.md`, `07_extraction.md`
- **Never modify the shared workbooks or the ontology** — suggest additions instead. **Analysis method is
  Andrea's.** **All numbers live in `_status/`, read through the `01_status.md` index.** **Several people
  share this folder — edit surgically, never rewrite a whole doc.** → `CLAUDE.md`

## Reading paths — start with the one that fits you

Numbers in filenames are **reading order, not stage order**. Follow your path, not the digits.

**A new analyst, or someone who just wants to use the data**
`00` → `02_the_project.md` → `03_somd_and_fomd.md` → `01_status.md` → `05_data_schemas.md` →
`08_effect_sizes_and_analysis.md` → **`sources/ERA/04_era_open_issues.md` before trusting any number.**
That last one is not optional — it's the honest list of what the data cannot currently support.

**Doing manual extraction from papers**
`00` → `03_somd_and_fomd.md` (just the FOMD paragraph) → **`07_extraction.md`** → `06_ontologies.md` (and
`New term request .xlsx` when a term is missing) → `05_data_schemas.md` (**check which template version**) →
`04_workflow_and_folders.md` (where your finished workbook goes). You should not need any ERA doc.

**Changing or debugging the ERA harmonization**
`CLAUDE.md` → `01_status.md` (**which version is where** — three versions are in play) →
`sources/ERA/00_era_overview.md` → `sources/ERA/01_era_harmonization.md` →
**`sources/ERA/02_era_handoff.md`** → `sources/ERA/04_era_open_issues.md` → `09_conventions.md`.
Skip `02`, `03`, `07`.

**An AI assistant with limited context**
`CLAUDE.md` (auto-loads) → `01_status.md` → **exactly one** task doc from the map → the relevant
`sources/ERA/*`. Don't load the whole base; it doesn't fit and it isn't needed.

## Glossary

**The two streams**
- **SOMD — Second-Order Meta-Data.** Unit of analysis = a systematic synthesis. Records what each synthesis
  concluded. Folder `01.SOMD/`.
- **FOMD — First-Order Meta-Data.** Unit of analysis = an individual primary study. Records measurements
  needed to compute effect sizes de novo. Folder `02.FOMD/`.
- **`FOMD` in a filename** (`09_FOMD_*.xlsm`, `fomd_fun/`) = a namespace prefix, correct as-is, never rename.
- **The `10_` schema** = the shared data template. Not "the FOMD schema" — see `03_somd_and_fomd.md`.

**Identifiers**
- **`ss_id`** — a source synthesis (e.g. `MD_Rosen_24_Effec_Sc` = ERA).
- **`study_id`** — a primary study. Both follow `TYPE_Auth5_YY_Titl5_Jr2`: type, first 5 chars of first
  author's surname *string*, 2-digit year, first 5 chars of title, first 2 chars of journal. The
  truncations are raw, so trailing commas and spaces are **part of the ID** (`Alam,`, `Paut,`, `Glor `).
- **TYPE prefixes** — `JA` journal article (a primary study), `MA` meta-analysis, `MD` meta-data/data
  paper, `SR` systematic review, `VC` vote-counting, `DM` data map, `S` serial.

**The two screening vocabularies** (easy to confuse — see `03_somd_and_fomd.md`)
- **Synthesis-level:** `A` auto-excluded, `R` excluded at title/abstract, `S` go to full text, `borderline`,
  `O` excluded at full text, then the routing classes `SOMD` (second-order only), `BMD` (both), `FOMD`
  (first-order only), `unresolved`, `not available`.
- **Primary-study-level:** **`I`** included and data complete (already extracted in the source dataset — no
  manual work), **`PI`** partially included (needs manual top-up extraction from the PDF), `O` excluded,
  `unresolved`, `not available`.

**Tables**
- **`06_`** the as-received long table. **`09_`** the manual-extraction long table (one row per arm ×
  outcome). **`10_`** the wide comparison table — the target template, `C_`/`T_` paired.

**Data concepts**
- **Ontology** — the controlled vocabularies in `01_FOMD_ontologies.xlsx`. **Never modified by script or
  AI**; **Lolita maintains it by hand.** → `06_ontologies.md`
- **subpractice** — the standardized name of a management practice within a section (tillage, fertiliser,
  agroforestry…), drawn from the ontology.
- **C / T** — Control and Treatment arms of a comparison.
- **out_subindicator** — the outcome measured (Crop Yield, Meat Yield, Methane Emissions…).
- **lnRR** — log response ratio. **SMD** — standardized mean difference. The two effect-size types the
  ontology assigns per outcome.

**Standards and framing**
- **ROSES** — the reporting standard this review follows (**not** PRISMA).
- **PICOC** — Population, Intervention, Comparator, Outcomes, Context: the scoping framework.
- **ERA** — Evidence for Resilient Agriculture; the synthesis `MD_Rosen_24_Effec_Sc` (Rosenstock et al.
  2024). Africa-only. Study id = `B.Code`. Snapshots `ie`, `mh` (crops), `sc`, `cc` (livestock).

**People** — **Andrea Sanchez** PI; **owns the analysis method**, does most extraction and all the
effect-size code. **Lolita Mueller** **maintains the ontology** and owns the ERA harmonization.
**Charlotte Chemarin**, **Mario Contreras**, **Silvia Araujo de Lima**, **Mordecai** extraction and
screening. **Sarah Jones**, **Damien Beillouin** (CIRAD) senior. **Stats4SD** platform.

## Be aware: what is solid and what isn't

Not everything here carries the same weight. Specifically:
- The **protocol is a live draft** with placeholders and at least one internal contradiction. This base
  summarizes only its stable parts and points at it for the rest.
- **`analysis.md` no longer exists** — the house analysis method is unwritten, deliberately. The
  method section of `08_effect_sizes_and_analysis.md` is Andrea's to fill.
- Several **meta-analysis scripts are empty stubs**, and one cleaning branch has no consumer. `01_status.md`
  says which.
- **Three ERA versions are simultaneously in play** (built / released / ingested downstream). If something
  looks wrong, check which version you're holding before investigating.
- The **SOMD stream is documented at definition depth only** — a deliberate limit, not an oversight.
