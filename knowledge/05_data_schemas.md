# 05 — The data template and the tables that feed it

Covers `06_`, `09_` and `10_` in `02.FOMD/02.metadata_structure/`. Sizes: `01_status.md`.

## The template: `10_FOMD_metadata_synthesis_short.xlsx`

**This is the shared data template — the thing every source is harmonized *into*.** Call it "the `10_`
schema", never "the FOMD schema" (`03_somd_and_fomd.md` explains why).

- **One row = one Control-vs-Treatment comparison for one outcome.** That is the unit of a meta-analysis
  effect size.
- Most columns come in **`C_…` / `T_…` pairs** — the control arm's value and the treatment arm's value of
  the same attribute. Shared attributes (study, site, outcome name) are unprefixed.
- "short" means **repeated slots are collapsed**: where the long tables have `crop01…crop15`, the template
  has one `C_crop_tree_diversity` cell holding a joined list; amount and unit are concatenated into one
  field (`C_fert_inorganicN_amount_unit`, `C_chem_name_amount_unit`).
- Standardized values (practices, outcomes, units, crops, animals) come from the ontology, not free text.

Three sheets: **`10_FOMD_metadata_synthesis`** (the schema — headers, no data yet),
**`10_FOMD_ERA_readme`** (the ERA crosswalk + review log → `sources/ERA/02_era_handoff.md`),
**`10_FOMD_readme`** (the analyst-facing data dictionary; exported by `04.fomd10_effect_size.R` as
`fomd10.dictionary.csv`).

### Column families

Not a per-column list — for the literal list use `names(read_excel(f, n_max = 0))` or
`names(fread(f, nrows = 0))`, and for meanings read `10_FOMD_readme`.

| Family | Contents |
|---|---|
| **Identity** | `study_id`, `effect_size_id`, `authors`, `title`, `year`, `journal`, `doi`, `country`, `country_ISO` |
| **Site** (`C_`/`T_`) | country, `site_type`, `site_id`, `site_admin`, `site_agg`, `site_latlong_type`, latitude, longitude, `site_buffer`, `site_key` |
| **Experiment & time** | `exp_design`, `C_/T_exp_plot_size`, `C_/T_exp_field_size`, `exp_duration`, `time_raw`, `time_year_start`, `time_year_end`, `time_season` |
| **System & commodity** (`C_`/`T_`) | `subpractice_description_raw`, `system_type`, `crop_tree_diversity`, `crop_tree_variety`, `crop_tree_density`, `animal_diversity`, `animal_breed`, `animal_density` |
| **Practices** (`C_`/`T_`, the bulk of the schema) | tillage · planting · varietal_crop · varietal_animal · intercrop · crop_seq · agrof · fert · weed · chem · residues · ph · irrig · watharv · harvest · postharvest · land_structure — each with a `_subpractice` (ontology-standardized) plus section-specific fields |
| **Outcome context** | `out_exp_design`, `out_exp_plot_size`, `C_/T_product` (+ `_type`, `_subtype`, `_simple`), `C_/T_econ_inputs`, `bio_func_group`, `bio_ground_ref` |
| **Outcome taxonomy** | `out_subindicator`, `out_indicator`, `out_subpillar`, `out_pillar`, `out_subindicator_unit` |
| **Outcome values** (`C_`/`T_`) | `out_soil_depth_u/_l`, `out_metric`, **`out_value`**, `out_var_metric`, **`out_var_value`**, **`out_sample_size`**, `data_location`, `out_agg_stat`, `out_year`, `out_year_start/_end`, `out_season_start`, `out_season_end` |

To compute an effect size you need, at minimum: `C_/T_out_value`, `C_/T_out_sample_size`,
`C_/T_out_var_value` + `_var_metric`, and `out_subindicator` + `_unit` to know what is being measured and
whether two rows may be pooled at all.

## The tables that feed it

| Table | Shape | One row is | Notes |
|---|---|---|---|
| **`06_FOMD_metadata_original_long`** | long, **364 cols** | one study × context × practice × outcome observation, **for a single arm** | The as-received data harmonized from source datasets. Uses `crop_tree01…15` (crops and trees in one slot family) |
| **`09_FOMD_metadata_extraction_long`** | long, **424 cols** | same, hand-extracted from a PDF | The manual-extraction master. Uses `crop01…15` **and** `tree01…15` separately. Sheets: the data sheet, `09_FOMD_readme` (a full data dictionary), `REMOVED` |
| **`10_FOMD_metadata_synthesis_short`** | wide, **287 cols** | one **C-vs-T comparison** | The template above. Long → wide means pairing two arm rows into one |

`08_FOMD_metadata_ai_long.xlsx` is an **empty placeholder** for planned AI-assisted field completion, with
provenance and confidence flags. **`07_` does not exist** — a renumbering artefact; today's `06_` was once
`07_`, which is why some readme sheets still say "section 7".

The `09_FOMD_readme` dictionary is worth knowing about: for every field it gives
`variable / data_type / variable_unit / field_description / notes / values / validation / ref_Source`, where
`values` points at the governing ontology sheet (e.g. `01_countries[country]`,
`01_lookup_levels[Field$Site.Type]`, `Yes, No`, `Free numeric entry (positive)`). It is the authority on
what may go in a cell.

### Field blocks in the long tables

In order: `id → location → experiment_details → experiment_time → practice → commodity_crop →
commodity_trees → commodity_animal → soil_management → planting → improved crop varieties → improved breeds
→ intercropping → crop_sequence → agroforestry → nutrient_management → weeding → chemical_management →
residues → pH_amendment → irrigation → water_harvesting → harvest → postharvesting → landscape_management →
outcome_experimental_design → product_outcome → input_outcome → outcome → outcome_value →
yield_values_for_LER → ler_values → outcome_time → extraction_details → sampling`.

Each practice block typically pairs a `_practice` group (what was done) with a `_moderator` group (context
that might modify the effect). **Animal practices are a known gap** in the block sequence.

## ⚠️ The live schema drift — 424 vs 364

There are **two incompatible `09_` schemas in circulation**:

| Workbook | Cols | Commodity columns |
|---|---|---|
| `02.metadata_structure/09_FOMD_metadata_extraction_long.xlsx` (master) | **424** | `crop01–15` **+** `tree01–15`, separate |
| `09_FOMD_metadata_extraction_long_V2.xlsm` | 424 | identical to master |
| `02.FOMD/09_FOMD_…_stats4sd_V3.xlsm` (**the live blank template**) | **364** | `crop_tree01–15`, merged |
| **every extractor workbook checked** | **364** | `crop_tree01–15`, merged |

The entire difference is that block: the master's `crop01–15 × {_, _variety, _density_unit, _density,
_arrangement}` plus `tree01–15 × {_, _density_unit, _density, _arrangement}` (135 columns) versus V3's
`crop_tree01–15 × 5` (75 columns). V3's column names are **identical to `06_`**.

**Consequence:** the workbooks extractors are filling today cannot be appended to the `09_` master as-is —
ingesting them requires splitting `crop_tree*` into `crop*` / `tree*`. Anyone writing that ingestion step
needs to know this first. (Consistent with `10_FOMD_ERA_readme` carrying both `C_crop_tree_diversity` *and*
separate `C_tree_diversity` / `C_tree_density` rows.)

## Serialization conventions

- **Repeated slots** are numbered two digits and looped with `sprintf("%02d", 1:N)`: `crop01…crop15`,
  `country01…country05`, `animal01…animal05`, `chem_subpractice01…03`. Nutrient rates
  (`fert_inorganicN/P/K/P2O5/K2O`) are kept as **separate columns**, never merged into one.
- **Arm prefixes:** `C_` (control) and `T_` (treatment), plus **`C2_`, `C3_`…** for multi-arm comparisons.
- **Multi-value cells** in the short schema join components with **`..`**; per-item components use brackets —
  e.g. `Maize[5(plants/m2)]Intercropped`. **Parse, don't assume scalar.** The splitting and rejoining logic in
  `fomd_fun/` and the `added_to_*` scripts depends on these exact delimiters — **don't introduce new ones
  ad hoc.**
- **Amount + unit** are concatenated in the short schema (`Type(Amount[Unit])`, blanks rendered as
  `Unspecified`), while the long tables keep them in separate columns.
- ERA's harmonized output uses its own separator hierarchy (`*` / `-` / `/`) for the crop/variety hierarchy —
  an ERA-side convention, documented in `sources/ERA/01_era_harmonization.md`.
- **Parallel lists must stay position-aligned:** component *k*'s amount and unit sit at slot *k*, and a
  component with no reported amount keeps an **empty slot** rather than shifting. Apparent
  "n_types ≠ n_amounts" mismatches are usually this trailing-empty-slot artefact.

## The discipline for this doc

Describe **families, shapes and rules** — never mirror the per-column dictionaries. The `_readme` sheets
carry hundreds of live field rows with review state in them; a copy here would be wrong within a sprint and
would invite someone to edit the copy instead of the source. Same reason `06_ontologies.md` doesn't list
terms.
