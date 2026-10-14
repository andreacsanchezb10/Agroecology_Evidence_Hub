# Change log (v1 → v52): project memory

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

## Generalized within-outcome pairing — v49
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

## Animal breed and diversity completion — v50 (released 17 Sept 2026)
Post-build fills from the raw cc `Herd.Out` (`V.Var`): `C/T_animal_breed` and `C/T_varietal_animal_breed` for
single-breed cc studies (multi-breed studies flagged in `product_to_confirm_v50.csv`), and `C/T_animal_diversity`
completed from the recovered species map. Rows/studies unchanged (191,019 / 1,810). Released as
`ERA/data/ERA_data_short_v50.csv`; Andrea's review of it produced v51.

## Andrea's v50 review — v51
Ten points, each verified on the v50 file and, for the data problems, against two or three source PDFs
(`../../_meta/log/2026-09-28-01-era-v51-andrea-review.md`). **Result: 166,297 rows / 1,808 studies / 340 columns.**
- **Pairs now agree on their measurement fields.** New `align_pair_fields()` (step 3, right after each merge): a
  pair is kept only when the sampling window (`ED.Sample.Start/End`), `Out.Unit`, `Out.Agg.Stat` and `Out.WG.Days`
  are equal or blank on one side (a single date inside the other arm's range counts as equal: JO0053's April 2019
  campaign); the blank side is then filled. Removed **24,719 cross-joined pairs in 174 studies**: 18,838 from
  sampling dates (soil moisture, N2O, CO2 and available-N time series: AC0131, NN0415, NN0003, DK0051, CJ0043 ...),
  5,635 from mixed units (JS0070 Mg/ha/yr vs kg/ha/yr; Feed Intake −3,399, the residual flagged in v49), 246 from
  weight-gain durations (DK0047 60/90/120 d). Per study × outcome with the cause: `pair_alignment_v51_reasons.csv`.
  `out_agg_stat`, `out_year_start/_end`, `out_season_start`, `out_year` and the unit now differ between C and T on
  **0 rows**. **DK0053** (Asante 2016, soil NO3) keeps no pair: its control and treatment series were entered on
  disjoint sampling dates (ERA-side issue).
- **mh sampling dates recovered.** mh stores `ED.Sample.Start/End` as Excel serial numbers (2005–2016, 22 studies);
  v50 had lost them. Parsed and written as ISO dates.
- **`out_season_start` re-sourced** to the measurement season (`Time` suffix, else `ED.Start.Season`; values 1–4
  only). It was `Final.Start.Season`, the arm's establishment season, which the papers show is miscoded (CJ0067,
  AC0007, JO0143 established all arms together).
- **`out_comparison_id` implemented** (a `10_` template field never mapped): the pairing key used, `|`-joined in a
  fixed order (study | site | Time | outcome | product | component L1 | component | Pair.Subkey | window | tier).
  12,833 ids, each with ≥1 control and ≥1 treatment arm.
- **Seven template columns added:** `C/T_varietal_animal_trait` (mh `V.Trait`, 4 studies), `out_npv_discount_rate`,
  `out_npv_econ_period`, `out_wg_start`, `out_wg_start_unit`, `out_wg_days` (all present in ERA `Data.Out`; the
  readme's "Missing from ERA" was wrong; values checked against DK0085, HK0306.1, NJ0037, BO1018, DK0037).
  `out_wg_start` had been blanked by the year-sentinel step because its name contains "Start"; weight columns are
  now excluded from that step (also repairs the herd starting weights).
- **NN0376 excluded** (grazing exclosure vs open communal grazing, Haftay 2013): the bare token `Grazing` in the
  agroforestry whitelist had admitted it, the treeless-control rule stamped "Monoculture" and the reorientation
  swapped the arms (sign inverted). Token removed (sweep: no other study relied on it), the "Monoculture" rule is
  gated to plant systems, study removed at Andrea's request (`excluded_studies_v51.csv`).
- **Template drift reported, not padded:** the `10_` sheet now has 328 columns, 116 without an output
  counterpart (per-arm site fields, `*_amount_unit`, effect-size columns) and 128 output columns not in it
  (`template_drift_v51.csv`). Andrea's decision.
- `animal_density` confirmed not recorded in ERA (the 9 cc stocking-rate rows are empty).

## Explicit no-application labels — v52 (current)
Andrea (1 Oct), analysing the Kenya subset of v51, reported that in 4,002 rows / 51 studies one arm carries a
subpractice while the other is blank, so the comparison looks one-sided and is dropped; and that in 181 rows /
17 studies the two arms are identical in every subpractice column. Measured globally the first problem is
**46,236 rows across 526 studies** — not a Kenya issue.

**Confirmed that a blank arm means the practice was not applied**, from the source papers and the arm names:
NN0261 (Ayuke et al. 2011, Table 1 p. 150) lists the control's organic input as "None" against *Leucaena*
prunings at 5 t/ha; control arms are named for the absence (JO0188 "NO MULCH (CK)", NM0110 "Rainfed", AG0072's
ERA level is literally "No mulch", AG0117's is "No Fertilizer Based On MT.Out"). Two exceptions, both guarded:
a practice listed in the study's `Base.Codes` was applied to **every** arm (CJ0039 has b16-b21 there and an arm
named "Control_N"), and water harvesting has no term in the vocabulary.

**ERA already owns the vocabulary.** `ERA/dataverse_files/03g. Practice_Codes.tab` defines an "h" series of
control terms and the arms already carry the codes in `MT.Out$T.Codes`; the script had never read either file.
v52 reads them, so most labels are **recovered from ERA rather than invented**. Only "No Residues Applied" and
"No Water Harvesting" are new (Lolita's decision: do not reuse ERA's "Crop Residues Removed", which asserts
more than a blank tells us).

**New step 6g**, before the Tier-1 reorientation, fills the blank arm by three routes in priority order, both
arms symmetrically: (1) the arm's own h-code, (2) its raw level name where that states the absence,
(3) inference when the sibling arm has the practice. Route 3 is guarded by `Base.Codes`, by the arm's own
presence codes and by "receipt" columns showing the input was applied, and is disabled for `cc` (no codes at
all). A fourth route handles the three diversification families: where the blank arm's own crop list shows
several crops the missing label is **positive**, not an absence, and is read off that list using ERA's
nitrogen-fixing table (`03e. EU_Codes.tab`) to give the wording already in use ("Intercrop (N fixing and Non
N fixing)", "Rotation (Non N fixing)").

**Background management gets its own columns (final design, Lolita 1 Oct).** The first attempt wrote the
study-level practice into the *blank arm's* practice column. That was wrong and we caught it before release:
on **18,522 of 18,556 rows (99.8 %)** the other arm still showed only its distinguishing practice, so
CJ0039 read control "Inorganic K..Inorganic P" against treatment "Manure" — implying the treatment got no K
or P when it got all three. A property of every arm cannot live in one arm's column. Eight row-level
columns `background_<family>_subpractice` now carry it, populated for **every** row of a study that has it,
not only where an arm was blank: fert 43,925, varietal_crop 31,696, irrig 18,134, ph 14,906, tillage 7,810,
watharv 4,299, residues 987, chem 0. **The arm column keeps its shared-template meaning** — what
distinguishes this arm — which matters because ten other source datasets use the same field, and the
agroecology-gradient scoring needs each arm's full set read as `arm + background`, on the same basis for
both arms.

**Report the split, not the raw count.** One-arm-empty 46,236 → **19,051**, of which **18,556 are explained
by the background column** and **495 are genuinely unexplained** (tillage 361, intercrop 99, residues 24,
fert 11). A blank now means one thing only: this arm had nothing EXTRA in that family.

**A pre-existing v51 error this exposed.** The v32 Tier-2 rule wrote "No Fertilizer Application" on a blank
arm without ever checking whether the study applied fertiliser to every plot — its own comment claimed
"not constant background" but no such test existed. **14,334 fertiliser arms carried that false label, and
carried it in v51 and every earlier version.** The fert, ph and chem rules now consult the background
column. The flip sets are deliberately left alone so orientation does not move further than the decision
below already moves it.

**The earlier route 2b (superseded, kept for the record).** The single largest remaining source of blanks was a practice recorded
once for the whole study (`MT.Out$Base.Codes`) rather than on each arm. The guard was right to refuse an
*absence* term there, but it had nothing to put in its place, so 4,614 tillage and 13,275 fertiliser arms
stayed blank and a blank reads as "not applied". v52 resolves the practice's **own name** from the code table
and writes that. Evidence that `Base.Codes` is the fallback background for an arm whose own codes name
nothing in that family: the two sets are **complementary, not overlapping** — across a 4,000-row sample,
62 % of rows share no code between `Base.Codes` and the arm's own codes and the mean overlap is 0.16;
CJ0039's "Control_N" arm did receive the N that only `Base.Codes` records; and in JS0278 the base code (b39)
is the same practice the arm's own codes give. **18,556 arms filled this way**, 12,768 of them fertiliser
across **141 studies**. The largest single beneficiary is EO0131 (4,608 rows): its study-level record is
no-till and its treatment carries reduced tillage, which reads as a no-till background with reduced tillage
on the treatment. Worth a sanity check against the paper.

**Route 1b — the arm's own codes.** Same omission, mirrored: the guard refuses an absence term when the
arm's own codes name a practice in that family, but nothing was written in its place. Resolving the name
from those codes clears all 847 varietal-crop arms, which carry h55.2 — a code the absence lookup does not
match because it only knows h55.

**Two "receipt" columns were evidence of nothing.** The inference guard treated a filled detail column as
proof the arm received the input. Two of them fail that test outright:
- `residues_N` / `residues_OC` are properties of the study's residue *material*, not of the arm: filled on
  **74 %** of arms with no residue practice against **12 %** of arms that have one, which is backwards.
- `tillage_method` is **identical on C and T in 100 %** of the one-sided rows, and filled on 82 % of arms
  with no tillage practice against 52 % of arms that have one. It lists the trial's implements, not the
  arm's, so it can neither prove this arm was tilled nor name its practice.

Both dropped. `residues_material`, its amount, `tillage_depth` and `tillage_frequency` stay.

**Trees are not in ERA's crop table.** `03e. EU_Codes` covers crop products, so all **63** agroforestry
species on these arms were missing from it and the intercrop/rotation label could not be named — Gliricidia,
Tephrosia, Acacia, Leucaena, Macadamia, Ziziphus, Grevillea and so on. Nitrogen fixation is a property of
the genus, so `.NFIX_GENUS` resolves by genus: nodulating Fabaceae, the actinorhizal *Alnus* and
*Casuarina*, and — as non-fixing — the Caesalpinioid legumes (*Senna*, *Cassia*, *Tamarindus*,
*Piliostigma*, *Acrocarpus*, *Delonix*) that are legumes but do not nodulate. **24 species remain
unresolved across 86 occurrences**, listed in `nfix_unresolved_v52.csv`; those arms get the unsuffixed
"Intercrop (Unspecified)" / "Rotation (Unspecified)" rather than nothing, following the
"Improved Fallow (Unspecified)" wording already in the vocabulary.

**95,730 arms labelled** in total (51,193 inferred, 21,243 by level name, 18,556 from the study-level record,
12,866 by code, 4,462 positive diversification, 2,268 Monoculture, 271 from the arm's own codes, 86
unspecified diversification); only **909 refused** by a guard, each listed with its reason in
`subpractice_fill_v52.csv`.

| family | one-sided | explained by background | genuinely unexplained |
|---|---|---|---|
| fertiliser | 13,286 | 13,275 | 11 |
| tillage | 4,991 | 4,630 | 361 |
| water harvesting | 483 | 483 | 0 |
| varietal crop | 154 | 154 | 0 |
| intercrop | 99 | 0 | 99 |
| irrigation | 14 | 14 | 0 |
| residues | 24 | 0 | 24 |
| crop sequence | 0 | 0 | 0 |
| liming | 0 | 0 | 0 |
| **total** | **19,051** | **18,556** | **495** |

Kenya crop subset: 4,058 rows / 53 studies -> 647 / 12 one-sided, of which **4 rows in 1 study** are
unexplained. Rows carrying any tillage practice rise 22,786 -> 30,526. CJ0039's control is correctly blank
with `background_fert_subpractice` = "Inorganic K Inputs..Inorganic P Inputs" beside it, so the row reads:
both arms got K and P, the treatment also got manure, the contrast is manure.

**Caveat on the study-level route.** The arm that was blank now shows the study-wide practices; the other arm
still shows only what ERA recorded as distinguishing it, although it received the study-wide inputs too. So
in CJ0039 the control reads "Inorganic K..Inorganic P" and the treatment reads "Manure", when the treatment
in truth received K, P *and* manure. The direction of the contrast is right and the control is no longer
falsely blank, but the two arms are not written on the same basis. Appending the base practices to the
non-blank arm would change values already in v51, so it was not done.

**Tillage recovered for the `mh` snapshot.** `C_tillage_subpractice` read `Till.Practice`, a column `mh` does
not have, so it was empty on every mh row while the level names plainly differed (ConvTill vs Basin, NoTill vs
RedTill). v52 derives it from `Till.Codes`: **6,421 rows gain a two-sided tillage contrast** and rows carrying
any tillage practice rise from 22,786 to 30,492. This resolves EO0145, DK0129 and NJ0041 from Andrea's
identical-C/T list outright (8, 7 and 5 rows to zero).

**Orientation: 54 rows in 3 studies change, everything else holds.** The gates of the v32/v34 input rules now
read a pre-fill snapshot (`HASV0`/`VALDIFF0`), so an absence label cannot move them: "Monoculture" is
`.divval`-FALSE exactly like a blank. **166,215 of 166,297 rows join to v51 with identical outcome means and
variances**, and `practice_compared` / `practice_compared_n` are identical on every one.

**378 rows change C/T**, every one matching a v51 row with the arms swapped; `ct_reoriented` 2,438 -> 2,748.
Most are the deliberate correction: where the blank arm was the CONTROL and its own crop list showed several
crops, the row ran against the convention that the monoculture is the control (4,793 intercrop comparisons
that way, none reversed). Those 390 arms (249 intercrop, 141 crop_seq) are now labelled and flipped —
**Lolita's decision, 1 Oct**. The rest are knock-on: labelling a blank Tier-1 arm changes which practice is
the primary contrast, so a different tier claims the row with a different `side`. Mechanism: labelling the
blank arm makes *both* arms diversified at that tier, so `.cd != .td` is FALSE and the tier no longer claims
the row; a lower tier then claims `practice_primary` with a different `side`. JS0006.1 is the clear case —
both arms are intercrops, the real contrast is rotation against continuous cropping, and the rotation sat on
the control, so it is now the treatment. All three readings look more correct than v51's, but they are
changes and Andrea is told explicitly.

**The invariant still holds after the flip:** `verify_v52.R` section 7 confirms zero rows end up with a
diversified control against a baseline treatment, because the reorientation moves the monoculture into the
control exactly as intended.

**195 rows** whose *treatment* arm is newly labelled "No Liming (control)" would have been re-oriented by the
pre-existing `.l_rev` sub-rule; that was deliberately suppressed so that no effect-size sign moves without
Andrea's decision.

**Diagnosed, not fixed.** Intercrop and crop sequence barely move because there the blank arm is genuinely
multi-crop: the missing label is *positive*, not an absence (5,703 and 1,578 rows). CJ0146's biochar is absent
for a different reason — `Fert.Method` and `Res.Method` join on `Site.ID`, but multi-site studies store it in
`Data.Out` as a concatenation ("KARI Embu_1..KARI Embu_2") that never matches the single-site detail rows:
**6,389 raw rows across ~204 studies**, 1,951 of them carrying a fertiliser level. Proposed for v53. Per-study
verdicts for all 17 identical-C/T studies are in `identical_CT_diagnosis_v52.csv`.
