2026-10-02 — **CFRA Kenya 2A: new heat-map layout, reclassification fixes, report checks** — code in
`02.FOMD/05.meta_analysis/idrc-cfra_analysis/` (edited by Andrea); no docs edited.

- **Figure:** new `cfra_fun/fun_plot_count_grouped.R` (`plot_votes_grouped()`, `grid_legend_small()`): one panel per
  food group (a, b, c… ordered by number of positive strong cells), bold headings "<domain> (vs. <control>)",
  spatial and temporal diversification shown together, fixed outcome order, sized for A4 (7.5 in wide, 7 pt).
  File names `<country>_<archetype>_fig<n><part>.png/.pdf`.
- **Reclassification (`fun_practices_reclassification.R`):** step 5.5a now swaps every C_/T_ column pair with the
  practice (means, crops, varieties), so variety and companion tables are correct after swaps. Mixed-inputs rule
  (organic + mineral in one arm = "Mixed fertilizer"). New exclusions in `exclude_pairs` (inorganic vs mixed, organic
  vs mixed, inorganic vs organic) remove whole comparisons.
- **Data quirks, not fixed:** swap rows written with capitals ("Crop Rotation", "Reduced Tillage", "Zero Tillage")
  no longer match the lower-case labels, so monoculture vs crop rotation and conventional vs reduced/zero tillage
  appear with the AE practice in the control. LM0264 controls are rotations ("Cowpea/Maize") recorded as monoculture.
  NM0110 (Maina 2020, kale) irrigation is drip (fixed in the ERA harmonisation script); its 396 comparisons are weekly
  harvests and planting dates differ between arms. Soybean "Nyala" typed Local (probably improved). "CM" manure
  ambiguous (cattle or chicken).
- **Report:** numbers in 3.2.1 predate the 17:10 data update and the new exclusions (e.g. organic fertilizer yield
  now 99, intercropping 333 of 470, Desmodium 88); Methods still lack the exclusions and reclassifications.
