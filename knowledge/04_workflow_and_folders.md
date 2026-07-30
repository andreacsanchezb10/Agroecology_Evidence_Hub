# 04 — The workflow, and the folders that hold it

In this project **the numbered folders *are* the pipeline stages**, so the workflow and the folder map are
one document. All paths are relative to the OneDrive root:
`%USERPROFILE%/OneDrive - CGIAR/Alliance-Agroecology <Knowledge|Evidence> Hub - General/` — shown as `HUB/`.
**The folder name differs per person** (Lolita has "Knowledge", Andrea "Evidence"), so resolve the root,
don't hardcode it → `09_conventions.md` §1.
Note the spaces in the folder name: **always quote paths in the shell.**

## The FOMD workflow, end to end

```
  a published synthesis + its primary-study dataset
                    │
   ┌────────────────▼────────────────┐
   │ 1. IDENTIFY the synthesis       │  from the JRC/Schievano library, team-held evidence,
   └────────────────┬────────────────┘  or WoS/OpenAlex searches          → SOMD stream
                    │  SOMD screening routes it here (class BMD or FOMD)
   ┌────────────────▼────────────────┐
   │ 2. OBTAIN study list + dataset  │  02.FOMD/01.metadata_harmonisation/
   └────────────────┬────────────────┘  01.study_list/ (sl_*) and 02.metadata/ (md_*)
                    │
   ┌────────────────▼────────────────┐
   │ 3. COMPILE the study lists      │  → 02_FOMD_identified_studies.xlsx
   └────────────────┬────────────────┘
   ┌────────────────▼────────────────┐
   │ 4. DE-DUPLICATE                 │  each unique primary study gets a study_id
   └────────────────┬────────────────┘  → 04_FOMD_screening.xlsx
   ┌────────────────▼────────────────┐
   │ 5. SCREEN each primary study    │  status decides the route
   └───────┬─────────────────┬───────┘
     status│= I              │status = PI
   ┌───────▼───────┐  ┌──────▼────────────────────┐
   │ 6a. HARMONIZE │  │ 6b. EXTRACT BY HAND       │  one 09_FOMD_<study>.xlsm per paper
   │  by script    │  │   from the PDF            │  03.extraction/  → 07_extraction.md
   └───────┬───────┘  └──────┬────────────────────┘
           │                 │
   ┌───────▼─────────────────▼───────┐
   │ 7. LONG TABLES                  │  06_FOMD_metadata_original_long (as received)
   └────────────────┬────────────────┘  09_FOMD_metadata_extraction_long (hand-extracted)
   ┌────────────────▼────────────────┐
   │ 8. THE 10_ TEMPLATE             │  10_FOMD_metadata_synthesis_short — one row per
   └────────────────┬────────────────┘  Control-vs-Treatment comparison  → 05_data_schemas.md
   ┌────────────────▼────────────────┐
   │ 9. EFFECT SIZES → META-ANALYSIS │  04.metadata_effectsize/ → 05.meta_analysis/
   └─────────────────────────────────┘                          → 08_effect_sizes_and_analysis.md
```

Semantic standardisation against the ontology (`06_ontologies.md`) happens throughout steps 6–8 — the
harmonisation at step 6 is deliberately **structural only**; mapping free text to controlled vocabulary is a
separate concern.

### The asymmetry at step 7–8 (easy to trip on)

Not every source takes the same route into the template:
- **Jones, Paut, Sanchez** → `added_to_06_*` scripts → **`06_`** (long) → later reshaped to `10_`.
- **ERA** → `added_to_10_MD_Rosen_24_Effec_Sc_new.R` → **straight to `fomd10/`**, skipping `06_`, because
  `era_harmonize.R` already delivers it comparison-shaped (one row per C-vs-T pair). → `sources/ERA/02_era_handoff.md`

So "the ERA pipeline" is really two scripts owned by two people, and they meet at the `10_` schema.

## The harmonisation folder convention

Inside `02.FOMD/01.metadata_harmonisation/`, the subfolders record **how far a source has got**, not what
kind of file it is. A source's files move forward through them:

```
01.accessible/   →  02.selected/  →  03.excluded/
      ↓
04.added_to_02_FOMD_identified_studies/   (study lists merged into 02_)
05.added_to_04_FOMD_screening/            (merged into 04_)
06.integrated/                            (done)
```

The metadata side mirrors it (`04.added_to_06_FOMD_metadata_original_long/`, `05.integrated/`). Each source
typically has a triplet: the data file, an `added_to_NN_*.R` script that merges it, and sometimes a `.ris`.
**Follow the same triplet pattern when adding a source**, and put the files in the folder matching how far it
has actually got.

**Read the folder name as a status.** A file in `03.excluded/` is not broken; it was screened out.

**File-stage prefixes.** Files carry the pipeline stage they belong to: `sl_` (study list), `md_`
(meta-data), `added_to_06_` / `added_to_10_` (merge scripts), `fomd09_`, `fomd10_` (cleaned outputs). Keep
these consistent when creating per-source files — downstream `source()` and `read_xlsx()` calls rely on them.

## The whole-project folder map

```
HUB/
├─ protocol/                        ← THE authoritative protocol + ROSES refs, flow diagram
├─ partners/                        ← JRC, CIRAD, Stats4SD agreements & specs
├─ presentations/                   ← project framing decks, training material
├─ Schievano et al 2024/            ← the JRC second-order evidence library (local copy)
├─ project_schedule_activities.xlsx ← activities, owners, deadlines, priority countries
│
├─ ERA/                             ← ERA source data + the harmonization script
│  ├─ Script/era_harmonize.R        ← THE ERA pipeline (edit here)      → sources/ERA/
│  │  └─ livestock_ss_overrides.csv ← a pipeline INPUT, not an output
│  ├─ data/                         ← released deliverables (a human moves them here)
│  │  └─ vNN_error_report/          ← Andrea's flagged-issue reports per version
│  └─ dataverse_files/, Video Tutorials/
│
└─ Agroecology_Evidence_Hub/        ← the review machinery (an RStudio project)
   ├─ 01.SOMD/                      ← second-order stream        → 03_somd_and_fomd.md
   │  ├─ 01.metadata_harmonisation/ 02.metadata_structure/ (11 workbooks) 03.PDFs/
   ├─ 02.FOMD/                      ← first-order stream — most work happens here
   │  ├─ 01.metadata_harmonisation/ ← ingest sources (the progression above)
   │  ├─ 02.metadata_structure/     ← THE MASTER WORKBOOKS 00–10 + the ontology
   │  ├─ 03.extraction/             ← manual extraction in progress  → 07_extraction.md
   │  │  ├─ 01.table_figure_extraction/   digitised figures → CSV
   │  │  └─ 02.09_FOMD_extraction/        one .xlsm per paper, by extractor
   │  ├─ 04.metadata_effectsize/    ← cleaning + effect sizes    → 08_…
   │  ├─ 05.meta_analysis/          ← models + idrc-cfra_analysis/ (live deliverable)
   │  └─ 09_FOMD_…_stats4sd_V3.xlsm ← the live blank extraction template (loose at root)
   └─ knowledge/                    ← THIS knowledge base
```

**`02.FOMD/02.metadata_structure/` is the source of truth.** Everything downstream reads the master
workbooks there, never a raw export. → `05_data_schemas.md`, `06_ontologies.md`

## Working / scratch locations (outside the shared drive)

Paths below are shown relative to **your own** Windows profile — `<Downloads>` means
`%USERPROFILE%/Downloads`, which differs per person. Nothing here should be hardcoded to one user
(`09_conventions.md` §1).

- **ERA snapshots (inputs):** `<Downloads>/era_cache/{ie,mh,sc,cc}.RData`, plus helper inputs
  `animal_species_by_study.csv`, `po_paper_resolved.csv`, `inventory_*.csv`. The script downloads the
  snapshots into this cache on first run, so a new machine builds its own.
- **Script outputs:** `<Downloads>/` — for ERA, `ERA_crop_data_short_vNN.csv` plus companion
  field-map, product-to-confirm and log files. A human then moves and **renames** the main CSV to
  `ERA/data/ERA_data_short_vNN.csv` (the word "crop" is dropped).
- **Ad-hoc analysis scripts:** a scratch/temp dir, **not** `ERA/Script/`.
- Inspection scripts accumulate in `Downloads/era_cache/inspect/`.

## Where you MAY write, and where you MUST NOT

| Location | Write? | Note |
|---|---|---|
| `ERA/Script/era_harmonize.R` | ✅ edit | the pipeline; bump `VERSION_TAG` per release |
| **your own** `Downloads/` (`%USERPROFILE%/Downloads`) | ✅ | all script outputs + scratch. Resolve it, never hardcode a person's path |
| `knowledge/` | ✅ | keep it current — living-doc protocol in `CLAUDE.md` |
| `ERA/data/` | ⚠️ human-moved | scripts write to Downloads; a person moves deliverables here |
| `02.FOMD/02.metadata_structure/**` | ⛔ **never** | the master workbooks **and the ontology**. Suggest changes; see rule 2 in `CLAUDE.md` |
| `02.FOMD/03.extraction/**` | ⛔ never | live manual work by named people → `07_extraction.md` |
| `01.SOMD/**` | ⛔ never | JRC-derived and Andrea-maintained |
| `protocol/`, `partners/` | ⛔ never | authored documents |
| Andrea's `04.metadata_effectsize/`, `05.meta_analysis/` | ⛔ don't edit | read and document; they're hers → `08_…` |

Rules text lives in `CLAUDE.md`; this table is where things are, not a second copy of the rules.
