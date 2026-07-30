# Agroecology Evidence Hub — project knowledge base

**Read this first.** This folder is the living knowledge base for the Agroecology Evidence Hub: what the
project is, how evidence flows through it, the shared data template, the decisions made, and what's open.

If you are an AI assistant: load `00_START_HERE.md` next, then **only** the docs your task needs.

## What this project is (one paragraph)
The Hub is a **living, ROSES-compliant, AI-assisted systematic review** comparing agroecological with
less- or non-agroecological practices, **globally**. Its distinguishing method is *evidence recycling*: it
harvests the primary-study-level datasets that **previous meta-analyses already extracted**, harmonizes
them into one shared template, and re-analyzes them — rather than reading the primary literature afresh.
ERA is one such harvested source among a target of ten or more. Full framing in `02_the_project.md`.

## Terminology card — get this right
- **SOMD = Second-Order Meta-Data.** Unit of analysis = **a systematic synthesis** (meta-analysis,
  systematic review, vote-count, data paper). Records what each synthesis *concluded*. Folder `01.SOMD/`.
- **FOMD = First-Order Meta-Data.** Unit of analysis = **an individual primary study** (a field
  experiment). Records the measurements needed to compute effect sizes de novo. Folder `02.FOMD/`.
- **The shared data template is the `10_` schema** (`10_FOMD_metadata_synthesis_short.xlsx`) — *not*
  "FOMD". "FOMD" is a stream, not a schema, and not the ontology.
- The ontology is a **workbook**: `01_FOMD_ontologies.xlsx`.
- **`FOMD` / `fomd` inside a filename or object name is a correct namespace prefix** meaning "belongs to
  the first-order stream" (`09_FOMD_*.xlsm`, `fomd_fun/`, `fomd01.*`). **Never "correct" these** — you will
  break `source()` and `read_xlsx()` calls.

Full definitions, the two screening vocabularies, and the deprecated-usage table: `03_somd_and_fomd.md`.

## The five golden rules
1. **Output flow.** Scripts write to `C:/Users/mlolita/Downloads/` first; a **human** moves deliverables
   into a data folder (e.g. `ERA/data/`). Scripts never write into a shared data folder directly.
2. **Never modify the shared workbooks.** Not `01_FOMD_ontologies.xlsx`, not anything in
   `02.metadata_structure/`, not any extractor `.xlsm` in `03.extraction/`. Not by script, not by AI, not
   "just this once with approval". You may only **suggest** additions as a list, or write a **new,
   differently-named** proposal into `Downloads/`. Full rule and the incident behind it: `06_ontologies.md`.
3. **Verify every change against the data** — counts *and* the actual rows you touched. "The script
   finished" is not verification.
4. **No numbers outside `_status/`.** Every version, row count, study count, tally and percentage lives in
   the `_status/` set, which you **read through `01_status.md`** — that index says which file owns what.
   Elsewhere, stay qualitative ("~190k rows"). Before quoting any number, read it from `_status/` and from
   nowhere else. **Write only the `_status/` file you own**; six owned files replaced one shared file so that
   two people stop colliding on every task. → `09_conventions.md` §13
5. **Analysis method is Andrea's.** Effect-size choice, pooling rules, exclusions, variance handling — her
   decisions. Don't invent them; ask. Documenting *data limitations* is different and is encouraged.

## ⚠️ Several people share this folder — read this before you write anything

This is **one OneDrive folder replicated to several machines**, not a copy each. OneDrive never merges: two
people editing one file resolves as last-writer-wins. So:

1. **Use surgical edits, never whole-file rewrites**, on anything in `knowledge/`. A targeted
   find-and-replace *fails loudly* if someone else changed that passage; a whole-file write silently erases
   their work. If an edit fails because the text moved, **re-read the file** — don't force it through.
2. **Write only what you own.** `sources/<X>/` belongs to whoever owns that source; each `_status/` file
   names its owner at the top. The shared docs (`00`, `02`–`09`, this file) change rarely — say so in the
   team chat before editing one.
3. **Never run two Claude sessions against `knowledge/` at once.**
4. **The log is one file per entry** in `_meta/log/` — never a shared list to append to.
5. **Rule 2 is now enforced, not just written.** `.claude/settings.json` at the Hub root, in
   `Agroecology_Evidence_Hub/`, and in `ERA/Script/` denies writes to the master workbooks, the ontology,
   `03.extraction/`, `01.SOMD/`, `ERA/data/`, `protocol/` and `partners/`. If a write there fails, the
   protection is working — **do not route around it.** It cannot stop an R script, only Claude's own edits.

Full detail and the reasoning: `09_conventions.md` §13.

## Doc map — load only what your task needs
| Doc | Load it when… |
|---|---|
| `00_START_HERE.md` | always second; reader paths + glossary |
| `01_status.md` | **before quoting any number** — the index to `_status/`, which holds them all |
| `02_the_project.md` | you need the research question, scope, standards, partners |
| `03_somd_and_fomd.md` | anything touches SOMD/FOMD, screening statuses, or study IDs |
| `04_workflow_and_folders.md` | you need to know where a file lives or what stage it's at |
| `05_data_schemas.md` | you're working with the `06_`/`09_`/`10_` tables or the data template |
| `06_ontologies.md` | a controlled vocabulary is involved, or a term is missing |
| `07_extraction.md` | you're doing or supporting manual extraction from PDFs |
| `08_effect_sizes_and_analysis.md` | effect sizes, meta-analysis code, or the analysis layer |
| `09_conventions.md` | you're writing or running R here |
| `sources/ERA/*` | you're changing or debugging the ERA harmonization |
| `_meta/MAINTENANCE.md` | you're updating these docs |

## ⟳ LIVING-DOC PROTOCOL — do this at the END of every task
**If you learned or changed anything durable that isn't already written here, write it down before you
stop.** It is part of "done". Knowledge gained in a session is otherwise lost.

The trigger is broad — the test is *would the next person, or the next session, be better off knowing this?*
- A **new version shipped** → the source's `changelog` **and** every affected count in `_status/`. Stale numbers are a bug.
- **Learned something about raw data** → that source's `00_*_overview.md`.
- **Found a data-quality problem, even unfixed** → that source's `04_*_open_issues.md`.
- **A decision was made** (including "defer it") → `09_conventions.md`, or the source's own doc.
- **A new source arrived** → copy `sources/_TEMPLATE.md`, register it in `_status/sources.md`.
- **A doc was wrong** → fix it; don't work around it.

Then **always add one new file to `_meta/log/`**, named `YYYY-MM-DD-NN-short-slug.md`, containing
`YYYY-MM-DD — <what changed> — <docs updated>`. One file per entry — never append to a shared list, and never
edit someone else's entry. Convention: `_meta/UPDATE_LOG.md`.
Keep edits surgical (see the shared-folder section above — this is not a style preference). Full protocol, routing table and health check: `_meta/MAINTENANCE.md`.

## Where this base is not authoritative
- The **protocol** (`protocol/Knowledge Hub Protocol.docx`) wins on method and scope. It is a live draft;
  where it and this base disagree, believe it and tell Andrea.
- The **workbooks' own `_readme` sheets** win on per-column meaning.
- **Andrea** wins on analysis method. **Lolita** maintains the ontology. Ownership table: `01_status.md`.
