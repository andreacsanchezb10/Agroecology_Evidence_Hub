# ERA harmonization — the script, its decisions, and how to run it

`ERA/Script/era_harmonize.R`. Versions and counts: `../../01_status.md`. Raw data model:
`00_era_overview.md`. What happens downstream: `02_era_handoff.md`.

## What it does

One R script turns the four ERA snapshots into one analysis-ready CSV in the `10_` schema shape. You run it
end to end; it reads the snapshots, builds the paired table, applies every cleaning and standardization step,
and writes the CSV plus companion files to `Downloads/`. **Every change to the data is a change to this
script — never edit the output CSV by hand.** It is regenerated from scratch each run.

## How to run

```bash
cd ".../ERA/Script"
"/c/Program Files/R/R-4.4.2/bin/Rscript.exe" era_harmonize.R > ".../Downloads/era_cache/inspect/vNN_run.log" 2>&1
```

- Rscript: `C:/Program Files/R/R-4.4.2/bin/Rscript.exe`. Uses `data.table`, `openxlsx`, `readxl`.
- Takes ~15–20 minutes. Run it in the background and wait; don't poll.
- **Always parse-check first** — a syntax error found 20 minutes in is 20 minutes wasted:
  `Rscript -e 'invisible(parse(".../era_harmonize.R")); cat("PARSE OK\n")'`
- Output: `Downloads/ERA_crop_data_short_vNN.csv` plus companions. A human then moves and **renames** the
  main CSV to `ERA/data/ERA_data_short_vNN.csv` — the word "crop" is dropped.

**Versioning:** `VERSION_TAG <- "vNN"` near the top; bump it for every release. It suffixes every output
filename. Then update `../../_status/era.md` and `03_era_changelog.md` — that is part of shipping, not optional.

## Script shape, top to bottom

1. **Config:** `VERSION_TAG`, `CACHE_DIR` (Downloads/era_cache), `OUT_DIR` (Downloads), and helper functions
   — `nn` (non-blank test), `nc` (numeric coerce), `norm_star` (separator normalizer), `coalesce_chr`,
   `samp_clean`.
2. **Load** the 4 snapshots; build a table-join spec; harmonize per snapshot (including the cc `Herd.Out`
   bridge).
3. **Build `all_pairs`** — the C/T-paired table — and derive columns (plant diversity, subpractices, product,
   animal diversity). **The pairing keys are set here**, including `add_pair_subkey()` (`Pair.Subkey`), the
   v48/v49 fix that stops sub-measurements (taxon, metric, soil depth, species × time) from cross-joining.
   **Anything affecting *which rows pair* belongs at this step, not step 5.**
4. **`fomd_map`** — the big named list mapping output columns to source/derived columns.
5. **Post-build steps** on `fomd_out`: consolidated fert/chem fields, control-label filling, diversification
   reorientation, `practice_primary` / `practice_compared`, the v45 normalization pass, the v46 product fill,
   the v47 duplicate-DOI resolution, the v48 biodiversity taxon→product / metric→subindicator rewrite.
6. **Write** the CSV, companion files and verification log.

## Companion files written each run (to Downloads)

| File | Contents |
|---|---|
| `ERA_to_FOMD_field_map_vNN.csv` | every output column → its ERA source field (pasted into the `10_FOMD_ERA_readme` sheet) |
| `ERA_missing_from_FOMD_vNN.csv` | ERA fields not carried over (documented gaps) |
| `product_to_confirm_vNN.csv` | rows/studies needing a human decision |
| `ERA_harmonization_log_vNN.txt` | the run log |

Also read as an **input**: `ERA/Script/livestock_ss_overrides.csv` (manual livestock sample-size overrides),
and from `era_cache/`: `animal_species_by_study.csv`, `po_paper_resolved.csv`.

Note: those filenames say `to_FOMD` where they mean "to the `10_` schema" — a legacy of the drifted
terminology. **Not renamed on purpose**: the filenames are part of the crosswalk contract with Andrea.
→ `04_era_open_issues.md`

---

# The decisions baked into the script

These are deliberate choices, with reasoning, so nobody re-litigates or accidentally undoes them.

## Separators

The standard component separator is **`; `**; the crop/variety hierarchy uses **`*`** (top), then `-`, then
`/`. Legacy `..` / `...` / `$$` appear in older source data and are normalized where safe.

**We deliberately did NOT globally re-standardize every separator** — some columns still use `..` or `,`.
That was scoped out to avoid churn. If asked to "standardize separators", **confirm scope first.**

## Parallel lists must align

Within fertiliser and chemicals, the `type`, `amount` and `unit` lists are position-aligned: component *k*'s
amount and unit sit at slot *k*, and a component with no reported amount keeps an **empty slot** rather than
shifting. Reported "n_types ≠ n_amounts" problems have almost always been this trailing-empty-slot artefact,
not a real mispairing — the `_combined` field is the unambiguous view.

## Consolidated `_combined` fields

`C/T_fert_inorganic_combined`, `_organic_combined` and `C/T_chem_combined` render each component as
`Type(Amount[Unit])`, joined by `; `. A blank amount or unit reads `Type(Unspecified[Unspecified])`.
**N/P/K are NOT in the combined field** — nutrient rates stay in the separate `fert_inorganicN/P/K` columns,
because Andrea builds her own nutrient columns from those. The old `[applied: N…]` suffix was removed in v44.

## Explicit controls — no blank control arm

A blank control arm gets an explicit label so the contrast is legible:
- **Monoculture** — treeless / sole-crop control opposite intercrop, agroforestry or rotation.
- **No Liming (control)**, **No Fertilizer Application**, **No Chemical Application** — for pH, fert, chem.
- **Hand Hoe** / manual method — recovered from `Weed.Out` where a chemical arm's opposite was blank.

## Agroecological C/T orientation

- **Crops:** diversification comparisons are oriented so the **more-diversified arm is the Treatment**.
  `practice_primary` tags the comparison by the hierarchy Agroforestry → Intercropping → Crop rotation →
  Tillage → Residues → Fertiliser → pH → Chemicals → Irrigation → Other. `ct_reoriented = "Yes"` marks
  flipped rows. Verified that no comparison exists in both orientations, so no duplication was introduced.
- **Livestock axes (derived from the data, since cc has no practice labels):** breed (indigenous vs
  improved), feed origin (`D.Source` on-farm vs purchased), feed type (fodder-tree/by-product vs
  concentrate). Feed add/substitution categories exist only in older snapshots, so livestock is classified
  by ingredient content.
- **A fully systematic per-practice orientation across all sections is DEFERRED** — to be designed as one
  coherent rule set with Andrea. **Don't implement it piecemeal.** → `04_era_open_issues.md`

## Product / species fill (v46)

- Crop rows: `C/T_product` (+ `_simple`) filled from `plant_diversity` where blank.
- Animal rows: filled from `animal_diversity`, falling back to a study-level species map
  (`era_cache/animal_species_by_study.csv`, built from `Herd.Out`/`Var.Out` `V.Product`).
- **Gate the animal fill on "not a crop row" (blank `plant_diversity`), NOT on `era_domain == "Animal"`** —
  `era_domain` is blank on many animal rows and the domain gate silently misses them.
- Two studies had no species in ERA at all → recovered from the source **PDFs** (CJ1013 = Goat,
  BO1047 = Sheep) and added to the species map.

## Duplicate-DOI policy (v47)

Same DOI can appear as **sub-splits** (`X.1`/`X.2` — one paper, ERA-split into experiments) or as
**cross-code pairs** (same paper, two codes). Decide complementary-vs-duplicate by **comparing actual outcome
values**, not just outcome *types* — two arms can share outcome types with 0% value overlap and be genuinely
complementary. Only genuine duplicates are removed; v47 removed exactly one. Sub-splits and complementary
pairs keep separate `study_id`s (Andrea merges on the bibliography side).

## Data cleaning

- **`999999`** is an ERA "unknown" sentinel — blanked in nutrient-rate columns.
- Strip literal `"NA"` tokens inside multi-value cells, invalid UTF-8 (seen in `site_id`), and non-breaking
  spaces (U+00A0).
- Weeding `"0"` frequency was a placeholder from one dataset → blanked.
- `&` → `and`, plus abbreviation fixes (`Ca` → `Calcium`, `Multistrata` → `Multistrata Agroforestry`) to
  match ontology wording (v45).

## Missingness is reported honestly

Blanks that reflect genuine non-reporting — most rows lack a variance; some studies are unreplicated —
are left blank and **documented**, not invented. `"Unspecified"` is used for a present-but-unlabelled
variance metric. → `04_era_open_issues.md`

## ERA-specific schema notes

Column families are shared and documented in `../../05_data_schemas.md`. ERA-specific additions:
- `study_id` = the ERA `B.Code` (e.g. `AC0029`, `NN0272.1.2`); `era_snapshot` = ie/mh/sc/cc.
- `era_domain` (Plant / Animal / Plant Product / Non-product) — **can be blank; don't gate logic on it.**
- `site_key` = `"lat lon Bbuffer"`.
- Derived analytical columns unique to ERA: `practice_primary`, `ct_reoriented`, `practice_compared`
  (+ `_detail`, `_n`) — the last flags rows whose only difference is the treatment label
  ("Other — contrast only in treatment label").
- Structural agroforestry fields (`_shade`/`_canopy`/`_dhb`) exist but are empty for rows recorded via the
  intercrop schema; all `land_structure_*` are empty because ERA doesn't collect them.

### Harvest / postharvest code map (ERA `PO.Codes` / `H.Prac` → ontology)

| code | ontology name | section |
|---|---|---|
| f1 | Harvest Technique | harvest |
| f2 | Harvesting Timing | harvest |
| f3 | Improved Drying | postharvest |
| f4 | Improved Chemical Storage | postharvest |
| f5 | Improved Physical Storage | postharvest |
| h17 | Traditional harvesting method | harvest |
| h21 | Unimproved Storage Structure | postharvest |
| h22 | Unimprove or No Preservation Technique | postharvest |
| h30 | Uimproved Drying Technique | postharvest |

The odd spellings "Unimprove" / "Uimproved" are the **ontology's own** — match them exactly. `f1`/`f2`/`h17`
belong to **harvest**, the rest to **postharvest** (v44). Only 6 of these codes actually occur in the data
(f1, f4, f5, h17, h21, h22).

---

# Verification recipe — do this after every change

1. **Counts unchanged** unless intended — expected values in `../../01_status.md`. Study count has held at
   1,810 across recent versions; a change there needs explaining.
2. **Touch-test:** re-read only the columns you changed; confirm the intended rows changed and nothing else
   regressed. **Pick fresh example studies** you didn't use while writing the fix.
3. **Ontology conformance** after any practice-name change: every `*_subpractice` token must be in
   `01_practices` `subpractice`, or be an intentional control label, or an accepted residual.
   → `../../06_ontologies.md`
4. **No junk:** zero non-breaking spaces, zero invalid UTF-8 (watch `site_id`), zero stray `NA` tokens, no
   `999999`.
5. For report-driven fixes, re-check the **specific flagged rows** are resolved — or state honestly that the
   residual is a genuine source gap.

## Gotchas

- **Don't shadow the helper functions.** `nc` is a numeric-coercion *function* used by `samp_clean`; a fix
  once assigned `nc <- <vector>` in a loop and clobbered it, and the whole run died later at `samp_clean`.
  Use dotted, unique names for temporaries (`.arm`, `.xcs`, `.ncs`, `.pc`). Don't shadow `nn`, `nc`,
  `norm_star`, `coalesce_chr`, `samp_clean`.
- **Git Bash heredocs** can collapse `\\` → `\` and break R regexes. Prefer writing R files with a file tool,
  or use `[.]` / `[*]` character classes.
- **Never end a backgrounded command with a stray `&`** inside another background wrapper — it detaches the
  real process and you get a false "completed".
- The output CSV is often **moved** to `ERA/data/` between runs, so a verify script should try
  `Downloads/ERA_crop_data_short_vNN.csv` first, then `ERA/data/ERA_data_short_vNN.csv`.

Inspection scripts accumulate under `Downloads/era_cache/inspect/`.
