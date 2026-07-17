# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

This is **not a software application** — it is the data and R-script workspace for a systematic
review / meta-analysis evidence-synthesis project on agroecological practices. The repo mixes:

- Raw and harmonised bibliographic/metadata spreadsheets (`.xlsx`, `.csv`, `.xlsm`)
- PDFs and supplementary files of the reviewed studies
- R scripts that clean, harmonise, and analyze that data (readxl/dplyr/tidyr/stringr/purrr/metafor)

There is no build, lint, test, or package-management setup (no `renv.lock`, `DESCRIPTION`, or test
suite). "Running the project" means opening `Agroecology_Evidence_Hub.Rproj` in RStudio and executing
individual `.R` scripts interactively — scripts are meant to be read and run top-to-bottom, checking
the `sort(unique(...))` sanity-check lines as you go, not executed non-interactively end-to-end.

## Two review streams

The repo hosts two parallel evidence-synthesis workflows, each following the same pipeline shape:

- `01.SOMD/` — smaller review stream (currently mostly meta-analyses under `03.PDFs/`, plus its own
  `02.metadata_structure/` master spreadsheets).
- `02.FOMD/` — the larger, more actively developed review stream, with the full pipeline described
  below.

Within each stream, folders are numbered to reflect the systematic-review pipeline order:

```
01.metadata_harmonisation/   raw per-study exports -> harmonised into the master structure files
02.metadata_structure/       master ROSES-style spreadsheets (the "source of truth" tables)
03.extraction / 03.PDFs/     source PDFs, supplementary files, and figure/table extractions
04.metadata_effectsize/      cleaning scripts + computed effect sizes (FOMD only)
05.meta_analysis/            meta-analysis / meta-regression scripts (FOMD only, partly stubbed out)
```

`02.metadata_structure/*.xlsx` files are themselves numbered by ROSES stage (ontologies → search
equations → identified studies → selection criteria → screening → extraction criteria → original/AI/
extraction metadata long tables → synthesis short table). Downstream scripts always read from these
numbered master files, never from the raw per-study exports directly.

## Harmonisation folder convention

Inside `01.metadata_harmonisation/.../01.study_list` (or `01.source_list`) and `02.metadata`, studies
move through numbered subfolders that describe *where a study's data has been merged to*, e.g.:

```
01.accessible / 02.selected / 03.excluded /
04.added_to_02_FOMD_identified_studies /
05.added_to_04_FOMD_screening /
06.integrated
```

Each such folder typically contains a triplet per study: the harmonised data file (`.xlsx`/`.csv`),
an `added_to_NN_*.R` script that performs the merge into the numbered master file, and sometimes a
`.ris` bibliography export. When adding a new study, follow this same triplet pattern and place
outputs in the folder matching how far along the pipeline that study has progressed.

## Study/file ID conventions

- `study_id` / `ss_id` values follow `TYPE_Author_YY_Titl_Jrn`, e.g. `MA_Sanch_22_Finan_Ec`,
  `MD_Paut,_24_A glo_Sc`, `JA_Adhik_18_Impac_SU`. Prefixes seen: `MA` (meta-analysis), `MD`
  (meta-data/data paper), `JA` (journal article), and `SOMD` (used as the study-type prefix for the
  flagship study in the `01.SOMD` stream, e.g. `SOMD_Bosco_26_Evide_Eu` — mirroring that stream's
  folder name the way `MA`/`MD`/`JA` studies live under `02.FOMD`).
- Files are prefixed with the pipeline stage they belong to (`sl_`, `md_`, `added_to_06_`,
  `fomd09_`, `fomd10_`, etc.) — keep this prefix consistent when creating new per-study files so
  downstream `source()`/`read_xlsx()` calls can find them.
- Compound multi-value fields (e.g. multiple crops/countries/sites per row) are serialized as strings
  joined with `".."`, and per-item components are joined with brackets, e.g.
  `Maize[5(plants/m2)]Intercropped`. Splitting/rejoining logic in `fomd_fun/` and the `added_to_*`
  scripts depends on this exact separator — don't introduce different delimiters ad hoc.
- Treatment vs. control columns are prefixed `T_` / `C_` (and `C2_`, `C3_` for multi-arm comparisons).

## Effect-size pipeline (FOMD)

The numbered scripts in `02.FOMD/04.metadata_effectsize/` are **not one single linear chain** — they
are two separate branches that happen to share a folder and a `fomd09`/`fomd10` naming scheme:

- **Manual-extraction branch**: `01.fomd09_clean.R` cleans the manually-extracted
  `09_FOMD_metadata_extraction_long.xlsx` table into `fomd09_cleanv2.csv`; `02.fomd10.R` reads that CSV
  and writes `fomd10_comparison.csv`. As of this writing, nothing downstream reads
  `fomd10_comparison.csv` — this branch appears to be a work-in-progress / dead end, not part of the
  live output.
- **ERA/Rosen branch** (the one that actually feeds later stages): a harmonisation script under
  `01.metadata_harmonisation/02.metadata/04.added_to_06_FOMD_metadata_original_long/`
  (`added_to_10_MD_Rosen_24_Effec_Sc_new.R`) imports the large ERA dataset (`ERA_data_short_v41.csv`,
  ~1,800 studies) and writes `fomd10/fomd10_MD_Rosen_24_Effec_Sc.csv`. `03.fomd10_clean.R` reads that
  file, merges/renames Control-vs-Treatment (sub)practice columns, and writes
  `fomd10_clean/fomd10_clean_MD_Rosen_24_Effec_Sc.csv`. `04.fomd10_effect_size.R` reads that in turn,
  computes means/SDs and effect sizes, and writes `fomd10_effect_size.csv`.

`fomd10_effect_size.csv` is consumed by `02.FOMD/05.meta_analysis/1.data_distribution.R`,
`2.comparison_2_3_levels.R`, and `05.meta_analysis/idrc-cfra_analysis/cfra_analysis.R` — the IDRC/CFRA
country-level analysis (Ethiopia/Kenya/Zambia) is the actual deliverable this branch feeds.
`3.sensitivity_analysis.R`, `4.meta_analysis.R`, and `5.meta_regression.R` are currently empty stubs —
treat them as placeholders, not reference implementations. Note also that `1.data_distribution.R` and
`2.comparison_2_3_levels.R` filter on an `effect_size_yi` column that `04.fomd10_effect_size.R` does
not currently produce (it only writes `effect_size_vi`, via hand-rolled formulas explicitly commented
as `"THIS IS TEMPORARY, JUST FOR THE CFRA ANALYSIS"`) — if a script errors on a missing column, check
for this kind of drift between a pipeline script and its downstream consumers before assuming the bug
is in your edit.

Shared helpers live in `02.FOMD/04.metadata_effectsize/fomd_fun/` and are `source()`-d explicitly at
the top of whichever script needs them (there is no central "load all helpers" entry point):

- `fun_load_data_ontologies.R` — loads the `01_FOMD_ontologies.xlsx` sheets (countries, sites, trees,
  products, outcomes, practices) into `fomd01.*` data frames.
- `fun_lookup_ontologies.R` — generic `apply_lookup_ontologies()` for mapping a `".."`-joined column
  through a reference table.
- `fun_lookup_commodities.R` — builds `fomd01.crops.trees` (crop/tree → FAO Food Group classification)
  from the ontology tables, plus `apply_lookup_commodity_group()` and
  `apply_CT_commodity_group_intersection()` (common commodity groups between C and T arms).
- `fun_cleaning.R` — a single generic helper, `apply_replace_in_cols()` (multi-column `gsub`).
- `fun_cleaning_09_FOMD.R` — the bulk of the domain-specific cleaning logic: `crop_name_fixes` /
  `apply_crop_fixes()` (regex-based crop/tree spelling normalization), `create_density_crop()`,
  `combine_amount_unit()` / `combine_type_amount_unit()` / `combine_fert_inor_type_amount_unit()` /
  `combine_ph_material_amount_unit()`, `move_to_agrof()` (reclassifies agroforestry terms out of the
  intercropping columns), and diagnostic helpers (`check_length_mismatch_*`) used interactively to spot
  amount/unit array-length mismatches.
- `fun_mean_sd.R` — `calculate_mean_sd()`, converting reported SE/SEM/SED/CV/MSE variance metrics to SD
  for both the `C_`/`T_` arms (used by `04.fomd10_effect_size.R`). A separate, simpler set of SD
  conversion formulas (`SE_SD`, `M_IQR_SD`, `CI_SD`, citing Higgins & Green 2011 / Hozo et al. 2005) is
  defined inline in `01.fomd09_clean.R` itself, not in this file.
- `fun_effect_sizes.R` — a `metafor::escalc`-based `compute_effect_size()` (LRR/SMD/MD) and
  `compute_log_total_ler()`. **Not currently `source()`-d by any pipeline script** — treat it as a
  draft/alternate implementation, not the code path actually producing `fomd10_effect_size.csv`.
- `fun_comparison_practice.R` — builds and renames the merged Control-vs-Treatment (sub)practice/theme
  columns (`apply_CT_subpractie()`, `apply_CT_renames_subpractice()`, `apply_CT_practice_theme()`,
  `diagnose_CT_missing_practice()`); sourced by `03.fomd10_clean.R`.
- `fun_analysis_practice.R` — query/summary helpers over the CT-merged data
  (`build_analytical_columns()`, `filter_by()`, `top_comparisons()`); also sourced by
  `03.fomd10_clean.R`.

## Working with these R scripts

- **Every script hardcodes absolute OneDrive paths** (`path.metadata.structure`,
  `path.metadata.effectsize`, `path.functions`, `path.era`, etc.) at the top, specific to one user's
  machine. Before running or modifying a script, update these path variables to match your local
  OneDrive sync location — do not assume the paths in the file are correct.
- Some older scripts (e.g. under `01.metadata_harmonisation/scripts/`) still reference earlier names
  for this OneDrive folder (`Alliance-Agroecology Knowledge Hub`, `Agroecology_Knolwedge_Hub`, even
  `Bioversity`) from before the project/org was renamed. Treat any such path as stale and fix it
  rather than assuming it resolves.
- The established style is dense tidyverse pipelines with frequent `# Quick checks` blocks
  (`sort(unique(df$col))`, `length(unique(df$col))`) after each transformation, plus `## TO CHECK:` /
  `### ARREGLAR` comments marking known-unresolved issues. When editing a script, preserve this
  check-as-you-go style rather than collapsing it — these lines are how the author validates each
  harmonisation step by eye in the RStudio console, not dead code.
- Numeric row/column suffixes like `crop01`..`crop15`, `country01`..`country05`,
  `fert_inorganicN`/`P`/`K`/`P2O5`/`K2O` represent repeated-measure slots (multiple crops/countries/
  nutrients per study row) and are looped over with `sprintf("%02d", 1:N)` — match this pattern when
  adding a new repeated field instead of hand-listing columns.
- Outputs that are large/derived are excluded via `.gitignore` (e.g. generated CSVs under
  `04.metadata_effectsize/fomd10*` and the Rosen ERA-derived CSV) — regenerate them by re-running the
  corresponding script rather than expecting them to be tracked in git.
