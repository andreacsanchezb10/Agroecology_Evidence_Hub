# Change log (v1 → v49): project memory

Distilled history of what each release changed. Most fixes originate as review comments from Andrea
(the output consumer). Early version numbers are approximate (reconstructed from script comments &
notes); v32→v47 are precise. Each release = a `VERSION_TAG` bump + full re-run + verification.

## Foundations (≈v1–v18)
- **v5** — planting subpractice gained a `P.Method` fallback (mh lacked `P.Prac.Prac`).
- **v6** — separator normalization to `*` (from `..`); per-component crop **diversity / variety /
  density** builder (system-aware `-`/`/`); first `C_product`/`T_product`.
- **v8** — `varietal_crop_variety` rendered as `crop(variety)`.
- **v9 / v10** — "Monoculture" control label for intercrop / crop-sequence blank control arms.
- **v11–v12** — agroforestry subpractice from AF flags + whitelisted `AF.Level.Name` (dropped leaked
  tree names / codes); `AF.Multistrata` = "Yes" → "Multistrata".
- **v13** — fertiliser **inorganic vs organic** split by family at source (`Fert.Method`).
- **v14 / v15** — `clean_practice_codes` strips embedded ERA codes (`(b41.2)`, `(h7)`) and "0" padding;
  irrigation code cleanup; residue material-unit fix.
- **v16** — outcome value columns; `out_var_metric` cleaned, orphan labels blanked.
- **v17 / v18** — paired **value/unit/amount alignment** (units repeat per component) + de-dup doubling;
  agroforestry treeless control = "Monoculture".

## Livestock, contrast, postharvest (≈v22–v24)
- **v22** — **livestock sample-size fix**: real n = number of animals (`Herd.N`), not the plot "head"
  count; 209 studies corrected; crops unaffected. Overrides in `livestock_ss_overrides.csv`.
- **v23** — derived `practice_compared` / `_detail` / `_n` (the contrast is implicit in ERA; this makes
  it explicit).
- **v24** — new **postharvest** section (`_raw` = `PO.Level.Name`).

## Agroecological structure & the v32 review (≈v28–v38)
- **v28** — merged crops + trees into `plant_diversity` / `_variety` / `_density` (Andrea's request).
- **v31** — Tier-1 diversification **C/T reorientation** (more-diversified arm = Treatment);
  `practice_primary`, `ct_reoriented`.
- **v32** — Tier-2 explicit no-input controls (No Liming, No Fertilizer Application) + the batch of v24
  review answers.
- **v33** — moved Alley Cropping / Multistrata / Other Agroforestry from intercrop → **agrof** subpractice.
- **v34** — recovered missing chemical **control** (Hand Hoe / No Chemical Application) from `Weed.Out`.
- **v35** — fert/chem carry-forward + consolidated `name(amount[unit])` **combined** fields.
- **v36** — `varietal_animal_subpractice_raw`.
- **v37 / v38** — plant-name normalization (nbsp, aliases); NPK `[applied: …]` suffix (later removed).
- **Ontology additions** — 64 crops → `01_product_new`, 8 trees → `01_trees` (FAO cols left blank).

## Postharvest cleanup & sentinel (v39–v43)
- **v39** — postharvest subpractice = standardized name from **`PO.Codes`** (authoritative, mainly mh).
- **v40** — keyword imputation of raw + paper-review overrides. **Reverted in v41** — verification showed
  all reviewed studies already had `PO.Codes`, and some paper guesses disagreed with ERA; overrides were
  removed, keeping PO.Codes + keyword only.
- **v41** — postharvest overrides removed; **agroforestry raw-move** (for pure-AF rows the raw ERA
  level-name moves intercrop→agrof so raw and cleaned agree).
- **v42 / v43** — **`999999` sentinel** blanked in NPK columns (v43 also handled the `...`-separated tail).

## Andrea's v41-review (8 points) — v44
Planting = ontology practices only (methods → `planting_method`); variety values mapped to ontology
(Drought Tolerant Variety→Drought Tolerance, etc.; `$$`→`*`); crop-seq "Other Time Sequence" resolved by
crop count (rice→Monoculture, 2-crop→Simple Crop Rotation); **fert combined re-spec** (`Type(Amount[Unit])`,
`Unspecified` blanks, N/P/K removed); chem "Other" → **Adjuvant/Other**; harvest values cleaned to
ontology names via codes; **f1/f2/h17 moved from postharvest → harvest**.
(Bug caught & fixed mid-work: a loop variable `nc` clobbered the `nc()` helper → renamed to dotted names.)

## Audit-driven normalization — v45
A data-quality pass fixing issues found by auditing (not all flagged by Andrea): `&`→`and` (intercrop,
residues, organic fert); spelling unification (`Liming or Ca Addition`→`…Calcium…`, `Growth
Promotor/promoter`→`Growth Promoter`); ontology-exact remaps (agroforestry, fert category, irrigation,
residues); misspelling `Communial`→`Communal`; stray `NA` tokens removed; invalid UTF-8 stripped
(`site_id`); non-breaking spaces normalized. Deliberately NOT done: global separator re-standardization,
and `$$` in variety *companion* columns.

## Product completion — v46
Filled `C/T_product` + `_simple` to ~100%: crops from `plant_diversity`; animals from
`animal_diversity` → study-level **species map** (`animal_species_by_study.csv` from `Herd.Out`/`Var.Out`).
Gate on "not a crop row", not `era_domain`. Two studies had no species in ERA → recovered from the
**PDFs**: CJ1013 = Goat, BO1047 = Sheep. Ambiguous agroforestry-biomass products (HK0202.1, JS0204,
NN0376) flagged in `product_to_confirm_v46.csv`.

## Duplicate-DOI resolution — v47
Andrea flagged duplicate DOIs across the 1,811 studies. Classified 49 groups: **35 sub-splits** (one
paper split by ERA) + **14 cross-code pairs**; value-level comparison showed **13 complementary** (keep
both) and **1 true duplicate**. Removed exactly one — **`CJ0124`**, keeping the more complete **`NN0420`**
and porting CJ0124's `site_buffer` + planting dates first. **Result: 232,209 rows / 1,810 studies.**
Sub-splits and complementary pairs keep their separate study_ids (Andrea merges on the bibliography side).

## Biodiversity taxon & metric — v48
Andrea flagged that biodiversity **products weren't biodiversity-related** and that all biodiversity rows
carried one `out_subindicator` ("Biodiversity"), so the data compared abundance-vs-Shannon and even
earthworms-vs-beetles. Root cause was **ours, not ERA's**: ERA stores the measured organism in `Out.Group`
and the metric in the unit, but the C/T pairing keyed on `Out.Subind` (="Biodiversity") + `P.Product`
(=crop) and, because every biodiversity outcome shares `Out.Code`=203, `allow.cartesian` produced the full
**taxon×metric cross-product** (e.g. DK0114 144 raw obs → 1,134 paired rows).
Fix: added a scoped `Bio.Key` = `Out.Group ‖ Out.Unit` to the pairing keys (`add_bio_key()`), **NA for every
non-biodiversity row** so other outcomes pair identically; then a post-build step sets `C/T_product` (+`_simple`)
to the taxon and rewrites `out_subindicator` to the metric (Abundance / Shannon-Wiener Index / Taxonomic
Richness / Evenness / Simpson / Margalef) derived from the unit. **Result: 230,267 rows / 1,810 studies.**
Verified: non-biodiversity rows **unchanged** (229,213 both versions, 0 diff by snapshot & indicator);
biodiversity 2,996 → 1,054 rows, **0** with `C_product ≠ T_product`; DK0114 1,134→126, NN0261 80→20, NN0376 4→2.
Deliberately **not** extended to the sibling `Beneficial Organisms` subindicator (`Out.Code`=268) — same
structure but messier `Out.Group` (mixes organisms with sampling locations); see `open_issues.md`.

## Generalized within-outcome pairing — v49 (current)
Investigation showed biodiversity was **one instance of a general bug**: wherever ERA records several
sub-measurements under one outcome (different taxa, **soil depths**, **pest species × sampling times**),
the C/T pairing cross-joined them because the distinguishing field (`Out.Group` / `Out.Depth` / metric)
wasn't a pairing key. Quantified: **~48,600 spurious rows (≈21%)** remained in v48, concentrated in Soil
Quality (soil measured at multiple depths) and Pest & Pathogen (species × time). Generalized `add_bio_key`
→ **`add_pair_subkey()`** (`Pair.Subkey`): matches **depth universally** (only depth-resolved outcomes
carry one) and matches **taxon/species (`Out.Group`) + metric (`Out.Unit`)** for the unambiguous, high-impact
families — **Biodiversity, Pest & Pathogen, Soil\***. NA elsewhere, so untouched outcomes pair identically.
**Result: 191,019 rows / 1,810 studies.** Verified against the quantification exactly: Soil Quality
72,596→45,812 (−26,784), Pest & Pathogen 16,312→4,061 (−12,251), Soil Moisture −20,278, Pest & Pathogen
(Numbers) −11,030; **biodiversity unchanged** (1,054); deferred outcomes (Feed Intake, Emissions, Income,
Costs, yields) **unchanged** — only Soil Carbon Stocks (−153) and Biomass Yield (−60) shifted, both from
correct depth-matching of their depth-resolved rows. Still deferred pending Andrea: Feed Intake (`Out.Group`
meaning unclear), Beneficial Organisms, and small residuals on emissions/yields — see `open_issues.md`.
