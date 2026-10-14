2026-10-05 — **CFRA Kenya: new evidence-sufficiency rule by agro-ecological zone, map/table functions, effect-size checks**
— no knowledge docs edited; code proposals given to Andrea in chat (she edits the CFRA scripts herself).

- **Method decision (Andrea, report 2.2.1):** evidence for an archetype is sufficient when it has >= 100 comparisons
  (after reclassification and exclusions) and >= 1 study in each *main* agro-ecological zone (GAEZ v4 AEZ57 class
  covering >= 10% of the high-priority areas). Otherwise keep the in-area comparisons and add comparisons from the
  missing main zones elsewhere in the country, then from bordering project countries (Kenya: Ethiopia, Tanzania,
  Uganda) only if none. Zones still empty = evidence gaps. GAEZ classes kept as is (highland/lowland not merged).
- **Kenya result:** 2A sufficient (66 studies, 2,928 comparisons; main zones semi-arid lowland with/without
  limitations and severe soil/terrain limitations; 52 of 66 studies sit in smaller humid/sub-humid zones).
  2B insufficient: all 235 comparisons from Embu (149 from a humid patch = 1% of the area), all also in 2A; the
  desert/arid main zone (32%) has no Kenyan study and is filled by one Ethiopian study (JO0140, 28 comparisons,
  sites ~12°N). **GAEZ rasters for Tanzania and Uganda are missing** from `idrc-cfra_analysis/GAEZ/`.
- **Functions proposed** (for `cfra_fun/`): `site_aez()`, `main_aez()`, `select_evidence()`, `aez_table()`,
  `county_table()`, `plot_aez_evidence()` (official GAEZ colours from `GAEZ_57_lookup.csv`; other zones pale green),
  `plot_distribution()`, `plot_years()`.
- **Effect sizes, not fixed:** the lnRR CV-imputation bug (log 2026-09-28-02) makes `out_effect_size_yi` wrong for
  622 of the 2A comparisons (27 studies; e.g. AG0028 −71.8 vs ln(T/C) +0.31). Vote counting is unaffected (uses the
  means). 59 2A comparisons have no effect size: 34 because `01_outcomes` has no `effect_size_type` for N2O,
  CH4, emissions intensity and SOC change (ontology suggestion for Lolita); 10 because a mean is <= 0 (CJ0039 and
  CJ0014 report negative *crop yields*, probably yield changes, to check against the papers); 15 SMD without SD.
- **Data quirks seen:** "Crotalaria ochrolueca" typo splits a species in Table S8; inorganic vs organic/mixed
  fertilizer contrasts excluded (2A: 22 comparisons, 5 studies), so organic results are vs no fertilizer only.
- **Deferred (Andrea):** median effect-size figure (dot or box plot, log scale) next to vote counting, once the lnRR
  bug is fixed; study-count condition for "strong evidence" and critical appraisal raised as reviewer points.
