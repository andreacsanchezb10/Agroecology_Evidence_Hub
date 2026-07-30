# 03 — SOMD and FOMD: the two streams

Covers `01.SOMD/` and `02.FOMD/`. If you searched for "FOMD", this is the right file.

## The two streams in one table

The project runs two coupled review streams. They differ in **what one row is about**.

| | **SOMD** | **FOMD** |
|---|---|---|
| Stands for | **Second-Order Meta-Data** | **First-Order Meta-Data** |
| Unit of analysis | **a systematic synthesis** | **an individual primary study** |
| One row is | a comparison × outcome **as reported by a review** | a study × context × practice × outcome **observation** |
| Records | what each synthesis *concluded* — its scope, methods, reported effect sizes, quality | the actual measurements needed to compute effect sizes **de novo** |
| Folder | `01.SOMD/` | `02.FOMD/` |
| Workbooks | 11, numbered `01`–`11` | `00`–`10` (no `07`) |
| Study types | `MA`, `MD`, `SR`, `VC`, `DM` | `JA`, `S` |
| Held by | largely **JRC** (Schievano et al. 2024) | the Alliance — this is where most local work happens |

"First-order" and "second-order" describe distance from the field experiment. A primary study is first-order
evidence; a meta-analysis of primary studies is second-order. A meta-analysis *of meta-analyses* would be
second-order synthesis — which is why the Hub keeps both registries: to expose overlap and enable it.

## How the streams are coupled

SOMD screening does not just accept or reject a synthesis — **it routes it**. The final screening classes
say which registry each synthesis feeds:

| Class | Means |
|---|---|
| **`SOMD`** | Second-order registry **only** — no usable primary-study dataset available, or it doesn't meet integration requirements |
| **`BMD`** | **Both** — the synthesis is suitable for the second-order registry *and* an eligible primary-study dataset exists |
| **`FOMD`** | First-order **only** — eligible primary-study data exists, but the synthesis itself isn't suitable for the second-order registry |

Historical note that matters when reading older files: these were renamed. Old `B` → `SOMD`, old `MD` →
`FOMD`; `BMD` kept its name. Older drafts also use `_ma_` (meta-analysis level, later SOMD) and `_pa_`
(primary article level, later FOMD) — the Stats4SD platform specification still uses `_pa_` naming, so
`09_pa_metadata_computed` there means today's `09_FOMD_…`.

`05_SOMD_screening.xlsx` carries explicit bridge columns — `fomd_metadata_link`, `fomd_study_list`,
`fomd_metadata` — that hand a synthesis over to the FOMD stream.

## Two screening vocabularies — do not conflate them

There are **two** status vocabularies at two different levels. This is the most common source of confusion
and it is written down nowhere else.

**Synthesis-level** (`05_SOMD_screening.xlsx`, `05_SOMD_key`) — is this *review* eligible?
`A` excluded by the automated OpenAlex pre-screen · `R` excluded at title–abstract · `S` potentially
eligible, go to full text · `borderline` · `O` excluded at full text · `not available` · then the routing
classes `SOMD` / `BMD` / `FOMD` · `unresolved`.

**Primary-study-level** (`04_FOMD_screening.xlsx`, `04_FOMD_key`) — is this *field experiment* usable, and is
its data already extracted?
- **`I`** — Included, **data complete**. The source meta-dataset already extracted everything needed.
  → harmonized **by script**, no manual work. All 1,811 ERA studies are `I`.
- **`PI`** — **P**artially **I**ncluded. The source captured only a subset (e.g. financial outcomes only).
  → **needs manual extraction from the original PDF** → becomes a `09_FOMD_*.xlsm` workbook. → `07_extraction.md`
- `O` excluded at full text · `unresolved` pending second reviewer · `not available`.

Note the collision: **`FOMD` and `O` mean different things in the two vocabularies**, and `MD` is both an
old status name and a live study-type prefix. Always check which level you're reading.

Current tallies: `01_status.md`.

## Identifiers

Both `ss_id` (a synthesis) and `study_id` (a primary study) use the same construction:

```
TYPE _ Auth5 _ YY _ Titl5 _ Jr2
 │      │       │      │       └── first 2 chars of the journal name
 │      │       │      └────────── first 5 chars of the title
 │      │       └───────────────── 2-digit publication year
 │      └───────────────────────── first 5 chars of the first author's surname STRING
 └──────────────────────────────── record type
```

`MD_Rosen_24_Effec_Sc` = Rosenstock et al. 2024, *"Effect(s)…"*, Scientific Data — i.e. **ERA**.

**The truncations are raw character slices, so trailing commas and spaces are part of the ID.** `Alam,`,
`Paut,`, `Glor `, `Ogol ` are correct and must not be "cleaned". Type prefixes: `JA` journal article (a
primary study), `MA` meta-analysis, `MD` meta-data/data paper, `SR` systematic review, `VC` vote-counting,
`DM` data map, `S` serial, `SOMD` used for the SOMD stream's own flagship synthesis
(`SOMD_Bosco_26_Evide_Eu`, the JRC European farming-practices evidence base).

## ⚠️ Deprecated and wrong usages

The phrase "FOMD" drifted in this project's own documentation to mean "the shared schema". It does not.
Three buckets:

| Usage | Verdict | Say instead |
|---|---|---|
| "the shared FOMD schema", "FOMD-format table", "harmonized to FOMD" | **wrong** | "the **`10_` schema**" / "the `10_` template" |
| "FOMD" = the ontology | **wrong** | "`01_FOMD_ontologies.xlsx`" — the ontology is a *workbook* |
| "FOMD manual extraction" as the name of a **source** | **wrong** | it's the **`PI` extraction route**, which *all* sources feed — not a source |
| "the FOMD stream", "first-order meta-data" | correct | — |
| `FOMD` as a screening class (first-order only) | correct | distinct from `BMD` |
| **`FOMD` / `fomd` inside a filename or object name** | **correct — never rename** | `01_FOMD_ontologies.xlsx`, `09_FOMD_*.xlsm`, `fomd_fun/`, `fomd01.*`, `fomd10_*.csv` |

That last row is the one that bites. `FOMD` in a name is a **namespace prefix** meaning "belongs to the
first-order stream". Renaming those files or objects breaks `source()` and `read_xlsx()` calls, and the
`ERA_to_FOMD_field_map_vNN.csv` filenames are part of the crosswalk contract with Andrea. Fix prose, never
paths. (The remaining filename inconsistency is logged, deliberately unresolved, in
`sources/ERA/04_era_open_issues.md`.)

## Why SOMD is documented only this far

**A deliberate limit, not an oversight.** SOMD's substance is the JRC's second-order library, which JRC
owns and continues to develop; the team is partly waiting on JRC to release quantitative second-order data.
Documenting its workflow in detail would mean documenting someone else's moving target.

So this base covers: what SOMD is, its unit of analysis, its workbooks, and — the part that actually
affects local work — **how SOMD screening routes records into FOMD**. If the SOMD stream becomes a local
working area, give it a doc set of its own.

For reference, `01.SOMD/02.metadata_structure/` holds: `01_SOMD_ontologies` (farming-practice definitions),
`02_SOMD_search_eq` (search equations — SOMD does its own database searching, FOMD does not),
`03_SOMD_identified_studies`, `04_SOMD_selection_criteria`, `05_SOMD_screening`, `06_SOMD_synthesis` (a
standardized report per synthesis), `08_pico_combinations`, `09_SOMD_quality_assessment` (16 criteria),
`10_ma_moderator_factors`, `11_ma_pico_cat_results`. Source PDFs and full upstream data dumps are in
`01.SOMD/03.PDFs/`.

Note the asymmetry: SOMD has a search-equation workbook because it searches databases directly. FOMD has
none — **FOMD studies arrive via SOMD**, not via their own search.
