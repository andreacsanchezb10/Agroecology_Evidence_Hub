# Agroecology Evidence Hub — repository guidance

**📖 The knowledge base is at `knowledge/` — start with `knowledge/00_START_HERE.md`.**
The doc map and reading paths are there. Load only what your task needs.

This file used to carry the full narrative of the FOMD workflow and R conventions. That content now lives in
the knowledge base, where it can be kept current:

| You want | Read |
|---|---|
| The project, its research question and scope | `knowledge/02_the_project.md` |
| **SOMD vs FOMD**, screening statuses, study IDs | `knowledge/03_somd_and_fomd.md` |
| The pipeline stages, the folder conventions, the `added_to_*` pattern | `knowledge/04_workflow_and_folders.md` |
| The `06_`/`09_`/`10_` tables, the shared template, separators | `knowledge/05_data_schemas.md` |
| The ontologies and how to request a new term | `knowledge/06_ontologies.md` |
| The effect-size pipeline, `fomd_fun/`, the two branches | `knowledge/08_effect_sizes_and_analysis.md` |
| **Working with these R scripts** — paths, style, naming hazards | `knowledge/09_conventions.md` |
| Every count, version and tally | `knowledge/01_status.md` → the `knowledge/_status/` file it points to |

## What this repository is

**Not a software application** — the data and R-script workspace for a living systematic review on
agroecological practices. It mixes harmonised metadata spreadsheets, source PDFs, and R scripts that clean,
harmonise and analyze them. There is **no build, lint, test or package management** (no `renv.lock`, no
`DESCRIPTION`, no test suite). "Running the project" means opening `Agroecology_Evidence_Hub.Rproj` in RStudio
and executing scripts interactively, top to bottom, reading the `sort(unique(...))` sanity-check lines as you
go — not running them non-interactively end to end.

Two parallel streams: `01.SOMD/` (second-order — the syntheses themselves) and `02.FOMD/` (first-order — the
primary studies pulled out of them, and where most work happens).

## The five golden rules

1. **Output flow.** Scripts write to `C:/Users/mlolita/Downloads/` first; a **human** moves deliverables into
   a data folder. Scripts never write into a shared data folder directly.
2. **Never modify the shared workbooks.** Not `01_FOMD_ontologies.xlsx`, not anything in
   `02.FOMD/02.metadata_structure/`, not any extractor `.xlsm` under `03.extraction/`, not `01.SOMD/`'s
   workbooks. Not by script, not by AI, not "just this once with approval". **Suggest** additions as a list, or
   write a **new, differently-named** proposal into `Downloads/`. (A script once saved a stale backup over the
   live ontology and wiped a colleague's edits — `knowledge/06_ontologies.md`.)
3. **Verify every change against the data** — counts *and* the rows you touched.
4. **Numbers live in `knowledge/_status/`** and nowhere else, read through the `knowledge/01_status.md` index.
   Read from there before quoting any figure; **write only the file you own.**
5. **Analysis method is Andrea's.** Don't invent pooling rules; ask.

## ⚠️ Several people share this folder

It is **one OneDrive folder replicated to every machine**, and OneDrive never merges. **Make surgical edits,
never whole-file rewrites**, on anything in `knowledge/`; **write only what you own**; **never run two Claude
sessions against `knowledge/` at once**; add **one new file** to `knowledge/_meta/log/` instead of appending to
a shared list. Rule 2 is also enforced by `deny` rules in `.claude/settings.json` — a failed write to a
protected path is the protection working. → `knowledge/09_conventions.md` §13

## Terminology — commonly got wrong

- **SOMD** = Second-Order Meta-Data — unit of analysis is **a systematic synthesis**.
- **FOMD** = First-Order Meta-Data — unit of analysis is **an individual primary study**.
- The shared data template is **the `10_` schema**, *not* "FOMD". FOMD is a stream, not a schema, and not the
  ontology.
- **`FOMD`/`fomd` inside a filename or object name is a correct namespace prefix** — `09_FOMD_*.xlsm`,
  `fomd_fun/`, `fomd01.*`, `fomd10_*.csv`. **Never rename them**; you'll break `source()` and `read_xlsx()`.

## ⟳ Before you finish

If you learned or changed anything durable that isn't already in `knowledge/`, **write it down** — new
versions, data quirks, problems found but not fixed, decisions made. Then add **one new file** to
`knowledge/_meta/log/`, named `YYYY-MM-DD-NN-short-slug.md`. Full protocol:
`knowledge/_meta/MAINTENANCE.md`.
