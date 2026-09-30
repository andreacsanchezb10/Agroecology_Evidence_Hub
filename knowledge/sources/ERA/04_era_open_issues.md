# ERA — open issues and deferred decisions

What is deliberately unfinished or known-imperfect, with impact and next step. Keep this doc honest — it's
how a successor avoids re-discovering the same things.

**If you are about to pool or analyze this data, read this file first.** It is the honest list of what the
data cannot currently support. Counts here are approximate and version-dependent; exact current figures are
in `../../01_status.md`.

---

# A. Ours to fix — data-quality items

## Within-outcome cross-join pairing (fixed for the main families in v48/v49)

The C/T pairing cross-multiplied sub-measurements that share one outcome and `Out.Code`. Quantified at
**~48,600 spurious rows (≈21%)** before the fix (`inflation_by_outcome_v48.csv` in Downloads). **Fixed** for
the unambiguous, high-impact families via `Pair.Subkey`: ~~Soil\* (depth + group)~~, ~~Pest & Pathogen
(species × time)~~, ~~Biodiversity (taxon + metric)~~ — removing ~39k spurious rows.

**v51 extended the fix to the measurement fields** (`align_pair_fields()`, step 3): sampling window, unit,
aggregation statistic and weight-gain duration must agree within a pair — another 24,719 rows in 174 studies
(`pair_alignment_v51_reasons.csv`). Still open from this: **DK0053** (Asante 2016, soil NO3) keeps no pair because
its control and treatment series were entered on disjoint sampling dates; needs a correction in ERA.

Still open, **deferred pending Andrea** because `Out.Group`'s meaning is ambiguous there and auto-matching
would not be safe:
- **Feed Intake** (~3,700 spurious, ~30%) — what does its `Out.Group` distinguish? Confirm the right unit.
  **v51:** 3,399 of these went with the unit rule (arms recorded in different units); the `Out.Group` question
  remains.
- **Beneficial Organisms** (`Out.Code` 268, ~180 rows / 8 studies) — same structure as the fixed biodiversity
  rows, but its `Out.Group` mixes real organisms with sampling *locations* ("Under canopy", "3m away from the
  periphery"). Needs cleaning before the same taxon→product + pairing treatment can be applied.
- **Small residuals** on Nitrous Oxide (~1,100), Biomass/Crop Yield (~1–2k, mostly legitimate), Weight Gain —
  likely sampling-time/position sub-measurements. Low priority; confirm before touching.

## Biodiversity follow-ups (after the v48 taxon/metric fix)

- **~170 biodiversity rows have no taxon** (`Out.Group` blank in ERA) → product left as the crop; metric still
  set where the unit is informative. Candidate for a flag list to Andrea.
- **~335 biodiversity rows keep the generic "Biodiversity" subindicator** — their unit didn't map to a standard
  metric (values like `0`, `n/200 g soil`, `% total bacteria`, `log (CFU/g soil)`). Logged in the v48
  harmonization log. Needs a call on the metric labels — **an outcome-ontology decision, so Lolita's**,
  though Andrea raised the underlying biodiversity problem.
- **A few studies encode the metric IN `Out.Group`** (e.g. AG0054 → "Richness" / "Shannon Weiner Diversity
  index" with unit `0`), so v48 put the metric name into `product`. Edge case; fix only if Andrea wants it.

## Statistical-integrity items (surfaced by audit; fixes offered, not applied)

- **Missing variance is ~70–80% of rows**, and mostly **genuine non-reporting** — ≈94% of missing rows have no
  variance anywhere in that study+outcome (crop yield and GHG worst). **This is a hard limit of the primary
  literature, not a harmonization gap.** A recoverable ~18k rows could inherit a **grouped SE/SED**
  (~17,700 rows use grouped metrics) plus arm-copy — a legitimate imputation, not yet implemented. Note the
  downstream pipeline already applies a CV-substitution approach to this problem
  (`../../08_effect_sizes_and_analysis.md`).
- **Negative variances (~57 rows)** — impossible SE values (e.g. NJ0122 Biomass SE = −17.65). Should be blanked
  or `abs()`-ed.
- **Zero variances (~460 rows)** — implausible, and they break inverse-variance weighting. Blank or flag.
- **Mixed variance metrics** in `out_var_value` — SE / SD / **CV** / Grouped types are **not
  interchangeable** (CV especially). Must be standardized per metric before pooling.
- **Identical C == T outcome values (~3,354 rows)** — zero-effect ties; some may be extraction errors.
- **Cross-snapshot double-counting (~24,982 key-duplicate rows).** The *same* observation appears in more than
  one snapshot (e.g. `AG0050` Ado Ekiti Animal Survival CTR→CPL 93.33→97.77% in **both mh and sc**). A
  **non-independence risk for meta-analysis**, and **separate from** the DOI-duplicate work, which was
  study-level. Needs a dedicated cross-snapshot dedup pass; **parked at the user's request.**

## Unit and completeness caveats

- **Unit heterogeneity within outcomes** — Crop Yield alone has 17+ units (Mg/ha, kg/ha, g/plant, Mg/acre, DM
  vs fresh…). Mostly convertible, but **DM vs fresh is not** — must be converted before pooling.
- **`n == 1` on ~6,600 rows** — unreplicated; some genuinely so (single-plot or observational). Worth confirming.
- **`era_domain` blank or odd** on ~1,200 rows (blank, or `Plant**Plant Product`). **Don't gate logic on it.**
- **~35 fully-empty columns** — most intentional (postharvest dates, agroforestry shade/canopy/DBH, all
  `land_structure_*`: ERA doesn't collect them). **`animal_density` is not recoverable** (checked v51): the cc
  `GM.Method` stocking-rate fields are empty on all 9 rows and `Herd.N` is a head count.

## Naming legacy

- **Output filenames say `to_FOMD`** (`ERA_to_FOMD_field_map_vNN.csv`, `ERA_missing_from_FOMD_vNN.csv`) where
  they mean "to the `10_` schema" — a legacy of the drifted terminology (`../../03_somd_and_fomd.md`).
  **Deliberately not renamed:** those filenames are part of the crosswalk contract with Andrea's readme sheet,
  so renaming is a coordinated break, not a cleanup. Deferred.

---

# B. Deferred by agreement — design decisions, not bugs

- **Systematic Control/Treatment orientation across all practice sections.** Only the crop diversification
  hierarchy (Tier-1) and the no-input controls (Tier-2) are oriented today. A coherent per-practice rule set —
  fertiliser (organic/none = treatment, chemical = control), pesticide (organic/manual = treatment), and so on
  — is to be designed **with Andrea, as one framework, not piecemeal.** **This is the highest-value next
  design task.** Related exploratory work: `era_agroecology_beta.R` and
  `presentations/Control_trt_decision_method_slides.pptx`.
- **Livestock feed axes as harmonized columns.** The livestock agroecology analysis (breed / feed origin /
  feed type) exists as findings plus `animal_species_by_study.csv` and the Courageous-Camel DB export, but
  dedicated `C/T_feed_origin` / `C/T_feed_type` columns were scoped and never built. Building them (from
  `D.Source`, `D.Item.Is.Tree`, ingredient groups) is what would make the livestock meta-analysis filterable.

---

# C. Needs a human decision — not pipeline work

These are **not pending work for the pipeline**. They are Andrea's, or the ERA data team's.

- **Duplicate DOIs — merges.** The 35 sub-split groups and 13 complementary cross-code pairs still carry
  separate `study_id`s. Merging them to one `study_id` per publication is a bibliography decision (list in
  `duplicate_DOI_resolution.csv`). Only the one true duplicate was removed, in v47.
- **Ambiguous agroforestry-biomass product** (HK0202.1, JS0204) — filled with the crop mix and flagged
  in `product_to_confirm_vNN.csv` for her to pick the intended component. (NN0376 left this list: excluded in v51.)
- **Grazing / pasture management has no family in the schema.** ERA records it (`A.Pasture.Man`, `A.Grazing`,
  code d19) for livestock studies; NN0376 (exclosure vs open grazing) was excluded in v51 for that reason. A
  family sourced from those fields would recover it for all livestock studies. → Andrea.
- **Template drift** (v51): the `10_` sheet has 328 columns; 116 have no output counterpart (per-arm site fields
  `C_/T_country`, `*_amount_unit`, single `out_agg_stat`, effect-size / LER columns) and 128 output columns are
  not in the sheet. Lists in `template_drift_v51.csv`. Which side moves is Andrea's call.
- **`Final.Start.Season` is miscoded at source** for at least CJ0067, AC0007, JO0143 (papers: all arms established
  together). v51 stopped using it for outcome timing; the ERA data team should be told. Same for DK0053's
  disjoint sampling dates.

---

## How to pick up an open item

1. Read the relevant doc: `00_era_overview.md` (raw model), `01_era_harmonization.md` (the script and its
   decisions), `../../05_data_schemas.md` (the target schema).
2. Reproduce the finding with a small **read-only** script against the current
   `ERA_data_short_vNN.csv` — check `../../01_status.md` for which version that is.
3. Implement in `era_harmonize.R` at the right stage — pairing changes belong with the pairing keys, not in a
   post-build step (`01_era_harmonization.md`). Use dotted variable names, parse-check, run, verify.
4. Record it here **and** in `03_era_changelog.md`, update `../../_status/era.md`, and add a new entry file to
   `../../_meta/log/`.
