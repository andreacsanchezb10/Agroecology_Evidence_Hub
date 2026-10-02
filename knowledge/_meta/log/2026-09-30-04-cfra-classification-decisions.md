2026-09-30 — **CFRA analysis: pipeline split and classification decisions (Andrea)** — code only, in
`02.FOMD/05.meta_analysis/idrc-cfra_analysis/` (edited by Andrea); no docs edited.

- **Pipeline:** `01.cfra_data.R` applies all selection criteria and writes `01.cfra_data/fomd10_cfra.csv`
  (nine CFRA countries). Country scripts (`02.cfra_analysis_KEN.R`) only do the archetype selection
  (`cfra_fun/fun_archetype_selection.R`), practice reclassification, counts and figures. Country-specific
  settings sit in section 0.
- **Decisions:** postharvest practices excluded (not AE/RA production practices; 5 studies, storage only).
  Pest and weed counts harmonised as Biodiversity (`bio_func_group` Pests / Weeds) are moved to
  "Resilience to pests", lower-is-better. Heat-map classes are applied to the % positive rounded to an integer.
- **Variety management** (`fun_practices_reclassification.R`, `variety_origin()`): each arm becomes Local
  (`varietal_crop_type` = Local, or variety name contains "local"/"landrace"), Improved, or Unspecified
  (dropped). Local always in the treatment; improved-vs-improved variety trials dropped. All CFRA data:
  Improved vs Local = 22 studies, 1,189 paired comparisons.
- **Data quirks, not fixed:** some local varieties are typed "Cultivar"/"Unspecified" in `varietal_crop_type`
  (e.g. AC0051, a Fava Bean "Local Variety", a Common Bean "Landrace"). Some variety trials are entered in both
  directions (A vs B and B vs A, e.g. AG0117), so mirror pairs may be double counted elsewhere; not checked yet.
  "Bare Fallow" (JA_Sjogr_10_Effec_Jo, from MD_Jones_21) is probably a natural fallow; check against the paper.
