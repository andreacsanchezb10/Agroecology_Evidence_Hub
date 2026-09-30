2026-09-28 — **New helper `plot_archetype()` for the CFRA policy-archetype maps** — new file
`02.FOMD/05.meta_analysis/idrc-cfra_analysis/fun_plot_archetype.R`; no docs edited.

- Reads an archetype `.gpkg` (ADM choropleth) or `.tif` (5 km grid) from `idrc-cfra_analysis/archetypes/<iso3>/`
  and returns a ggplot. Handles criteria counts (`Criteria_Met_Count`, KEN 2A/2B), ranked tiers where 1 = highest
  (`tier` + `tier_label`, ETH 3A), raster scores (ETH 3B/3C), an out-of-scope mask (`ASAL_County`, KEN 2B) and a
  flag outline (`Low_Female_Education_Flag`, KEN 2A).
- Checked against Trini's report `archetypes/ken/ArchetypesKenya0918.docx`: KEN 2A and 2B reproduce Figures 17
  and 18 (2A: 6/9/26/6 counties meeting 1/2/3/4 criteria; 6 Core Priority; 10 low-female-education counties).
- **Data quirks:** archetype files differ by country (KEN = `Criteria_Met_Count`; ETH 3A = `tier`, reversed). Two
  KEN columns are truncated to `SevPov...` and `PopShare...`. `ggspatial` (scale bar / north arrow) is not installed.
