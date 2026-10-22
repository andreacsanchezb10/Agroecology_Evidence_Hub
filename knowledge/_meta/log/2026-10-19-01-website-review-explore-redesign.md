2026-10-19 — **Explore page rebuilt after the team review; practice is now always the agroecological arm;
published data moves to the 14 October re-export (1,860 records)** — `website.md` (orientation rule, fourth
enforced rule, two new rows for Andrea), `_status/website.md` (all counts, new "explore page" section),
`website/README.md`, `website/docs/img/README.md`. Website commit `442ae07`, live and verified.

## The review, and what was done about each point

| Reviewer said | Done |
|---|---|
| Remove JRC / WorldFish | Removed, with Stats4SD (Lolita confirmed they are no longer involved). CIRAD remains. |
| Map and findings together; world view shows findings first; region → country like FAOSTAT | Map and a findings panel share one row; sentence, chips and heatmap in the panel, table below. Region filter first, country list grouped under UN M49 regions. Map click still selects a country and wins over a dropdown region. |
| "Control" unclear; say we compare agroecological vs less agroecological | Sentence now: "N comparisons between an agroecological practice and a less agroecological alternative…". |
| Group outcomes by pillar; "abundance of what" | Heatmap columns grouped under `out_subpillar` (Yield, Economics, Physical, Efficiency, Biodiversity); Abundance/Richness split by `bio_func_group`. |
| Pink negative, teal positive | Token order reversed in one place (`ramp()`), legend generated from the same breakpoints. |
| Practice is always the agroecological one | `build.py` orients every pair with `COMPARATOR_TERMS`; see below. |
| Say what n is | Every n is labelled: comparisons, studies, replicates; heatmap caption defines n. |
| No "best practice" at world view | Only said once a filter is active. |
| Photo credits | Footer lists the pages; four credits still to come from Lolita. |
| Active filters invisible | `.dd.active` coloured; chips carry their dimension name. |
| No side drawer; table self-contained | Drawer removed. 28 columns, study first, lat/lon beside country, pillar and sub-pillar, both arms with details, both means with SD and n, lnRR and SE, seasons, synthesis, DOI. Heading tooltips say where each number comes from. |
| Effect size and SE, not % | lnRR everywhere, scale cut at ±1; SE in the table; `value` in the download only. |
| How the table relates to the chart | Caption under the heatmap: median lnRR per practice × outcome, computed from the same rows as the table. |

## Orientation — the one real method step, and it is Andrea's to ratify

Sources label their arms control/treatment their own way; in Jones 43 published pairs had the conventional
arm as treatment. `build.py` now holds `COMPARATOR_TERMS` (Monoculture, Conventional Tillage, Inorganic
Fertilizer, External input dependency, No Fertilizers Applied, Synthetic pesticide, Plastic mulch, No mulch,
Irrigation/Full irrigation/No irrigation, Unimproved variety, No Inoculation, No liming), written from the
level-0 row of `control_treatment_scoring.md` plus its "absence is not agroecology" rule. Decision per
pair, on the union of `_theme` and `_practice` terms: treatment conventional and control not → **swap** the
arms before computing; both conventional → **lateral, set aside, not published**; otherwise keep. The
swap is done by choosing the column prefixes once, so lnRR, SE and the control-mean gate are computed
already oriented. Left out of the set on purpose: `Natural Fallow`, `Timber plantation`, `No Chemical
Applied` (its pairs carry `Inoculants` on the same side, so they swap and the practice reads "Inoculants /
No Chemical Applied" — a label oddity to look at).

Result on the 14 Oct files: Jones 911 published (868 kept, 43 swapped: 18 natural habitat + 5 semi-natural
habitat vs monoculture, 15 no-chemical vs synthetic pesticide, 5 zero vs conventional tillage), 74 lateral
(all fertiliser vs no fertiliser), 161 unusable; Paut 949 (0 swapped), 16 lateral, 51 unusable. **1,860
records, 12 countries.** All 43 swapped records were spot-checked against the source rows: record C equals
source T in every one. The build prints every swapped and every set-aside pair on each run, and
`python build.py --dry-run` prints it without writing.

## Other facts worth keeping

- `out_pillar`, `out_subpillar` and `bio_func_group` exist in the clean CSVs and were never read before.
  Pillars are Productivity / Resilience / Mitigation / Other; the reviewer's "pillars" are the sub-pillars.
  `Costs` sits under two pillars in the ontology, so grouping is by sub-pillar.
- The 14 Oct re-export (Hub commit `a39b405`) has the same row counts as before but ~500 more rows with
  coordinates and means, which is why 1,449 became 1,950 before orientation. Lolita chose to publish from
  the current files rather than freeze the 25 Sept ones (which are in Hub git at `b353a41`).
- `REGIONS` in `build.py` now covers all 34 ISO3 countries with UN M49 sub-regions; Malawi and Zambia move
  from "Southern" to "Eastern Africa" accordingly.
- `lnRR_SE` is empty for 1,049 of 1,860 records (56 %), almost all Paut, whose dispersion is "Unspecified".
- `data.js` now ends with `window.KH_COLUMNS`, the column order of `data.csv`; `app.js` reads it for the
  download instead of keeping its own list.
- The dataviz palette validator (bundled skill) is built for categorical palettes and fails the diverging
  ramp on checks that do not apply; what applies — lightness monotonic from each pole to the sand midpoint,
  adjacent-step CVD separation — holds in both themes. The pale near-zero steps are below 3:1 against the
  surface, as before; text on cells uses `inkOn()`.
- The Edit tool could not match the old explore block in `index.html` (whitespace); it was replaced by line
  markers with a small Python script. Playwright's bundled browser is still absent here; `npm i playwright`
  in the session scratchpad and `channel: 'chrome'` works.

## Follow-up the same day (commit `c97ec89`)

Lolita read the summary sentence and found it unclear, so it changed again. It now quotes no lnRR: "1,860
field comparisons between an agroecological practice and a less agroecological way of farming, across all
outcomes: yield, income and costs, biodiversity, soil and pests, and efficiency. In 55% of them the
agroecological plot came out higher, typically about 6% more." The outcome groups are the sub-pillars
present in the selection, in everyday words (`groupYield`… in `KH_UI`; the heatmap keeps the ontology's
names). Every visible "lnRR" label became "Effect size (log response ratio)" and "Effect size standard
error". Antarctica is dropped from the world geometry on load.

Two questions she then asked are open at the time of writing: whether the sentence should say *did better*
rather than *came out higher* (which needs a direction per outcome; see item 3 below — the ontology's `Sign`
marks Abundance `p`, which is wrong for weeds and pests, and leaves four sub-indicators blank), and whether
the sentence should list the pillars (Productivity, Resilience) with their sub-pillars rather than the
sub-pillars alone. Measured for the decision: pooled across all outcomes, 55 % "higher" becomes 57 %
"better" under the obvious direction rule; by group, Economics 85 % → 73 %, Physical 67 % → 87 %,
Biodiversity 54 % → 58 %, Yield unchanged at 39 %.

## Second follow-up the same day (commit `438640c`): "did better"

Lolita's answer to the open question: the sentence must say when the practice **did better**, not when
its number was bigger. So every displayed figure is now turned by the outcome's good direction.

- New `tools/fetch_outcome_signs.py` reads the ontology's `01_outcomes` sheet **read-only** and writes
  `website/outcome_signs.csv` (165 sub-indicators: 114 `p`, 41 `n`, 10 blank). `build.py` reads it; it stays
  standard-library.
- `build.py` gives each record `direction` (+1 / −1 / 0), `yi` = lnRR × direction (positive = better; null
  when the direction is unknown), `se`, `vi` = se². `lnRR` stays raw in the download. Two gaps the ontology
  leaves are written in `build.py` with a note that they belong in the workbook: `SIGN_FIXES` for the four
  blank sub-indicators in the data, and `BAD_ORGANISMS` for Abundance, which the sheet marks `p` for every
  organism although more weeds or pests is worse. **42** Abundance rows name no organism and have no
  direction; with the 7 zero-mean rows, 49 records have no `yi`, colour grey and sit outside the percentage.
- Sentence now: "…across all outcomes: productivity (yield, income and costs) and resilience
  (biodiversity, soil and pests, efficiency). In 57 % of them the agroecological practice did better,
  typically about 7 % better." Pillars with their sub-pillars, in that order, biodiversity first within
  resilience. Legend ends read worse / same / better. Table: 30 columns, with "Good direction" in words.
- Also at Lolita's request: filter buttons are a translucent accent wash, bold and larger; the home page
  has a band under the header leading to Explore; the R names `yi`/`vi` are used in the download and the
  table headings.
- The first attempt failed its own check twice before pushing (the list joiner wrote "yield and income and
  costs"; the meta line called 49 records "direction unknown" when 7 of them are zero-mean). Both fixed
  before the push; the push guard (`verify.js` must report 0 failed) is what caught them.

**For Lolita's workbook:** fill the four blank `Sign` cells; decide how Abundance should carry a direction
(it cannot be per sub-indicator — a rule by `bio_func_group`, or a column). Until then `build.py` holds both.

## Third follow-up the same day (commit `d8f23a9`)

- Lolita found the biodiversity part of the heatmap unreadable (17 columns). With `yi` now turned so
  positive is better for every organism, pooling is sound again: back to **one column per outcome**, the
  organisms listed with counts in the column heading, the outcome filter keeping each split, and a column
  click selecting all of them. 14 columns in all.
- Three header rows, pillar / sub-pillar / outcome. An outcome named only after its sub-pillar
  (Efficiency) is split by its measure instead — energy use efficiency, water use efficiency — which was
  her "efficiency is not clear" point.
- The caption defines *n*: the number of field comparisons in the cell, pairs of plots, not studies. The
  meta line keeps countries, crops and studies and drops the replicate median and the no-effect-size count.
- **Bug found by Lolita:** choosing Cowpea blanked the map. All 36 Cowpea comparisons share one site, so
  the bounds had no area and Leaflet zoomed in without limit (`getMaxZoom()` is infinite with no tile
  layer). `fitBounds` now has `maxZoom: 8`, the map `maxZoom: 12`. The same would have hit any single-site
  selection. "Abundance · Pests", which she also reported, has 10 sites and behaves in the test; most
  likely the same fault seen on a different selection.

## Fourth and fifth follow-ups the same day (`3ccf247`, `808e78d`)

- Filter options can be sorted: A–Z / Z–A by name, n ↓ / n ↑ by the count beside each option (which
  follows the other filters, so the order is refreshed on every render). Countries sort within their region
  headings. Options are moved, not rebuilt, so ticks and listeners survive.
- Downloads: the toolbar button and the footer button are gone; two big accent buttons sit next to the
  "Comparisons" heading — "Download the complete dataset" always, "Download this selection (n)" only once a
  filter is set. File names say `complete` or `selection`.
- Checks: 63 of 63, locally and live.

**Open from the orientation check Lolita asked for** (answered in chat, not yet acted on): 58 published
comparisons have a natural or semi-natural habitat on one side. 28 of them (monoculture vs habitat, habitat
vs habitat) contain no agroecological practice and should be set aside under the rule already adopted; the
30 agroforestry-vs-habitat ones are in the Hub's stated scope but must not be pooled silently with
"vs conventional" — proposed: a "Compared with" filter and an adaptive sentence. Also proposed: add
`Timber plantation` to `COMPARATOR_TERMS` (42 pairs, orientation then verified rather than assumed). The 36
agroforestry-vs-agroforestry (shade level) pairs keep the source's order; nothing in the data says which is
more agroecological. The negative biodiversity cells Lolita noticed are the agroforestry-vs-forest pairs
(richness median −0.80, n 8) pulling cells that also hold agroforestry-vs-monoculture (+0.40, n 4).

## Sixth follow-up the same day (`e2fb07f`): habitats, effect-size type, compact table

Lolita read the meeting recording (13 Oct) against what was done and asked for three of the open items.

- **Habitats.** A natural or semi-natural habitat is never the practice. `HABITATS` in `build.py`: against
  conventional farming or another habitat the pair has no agroecological practice and is set aside (28:
  18 natural and 5 semi-natural habitat vs monoculture, 5 natural vs semi-natural); against farming it is
  the comparator and the pair is marked. **1,832 records** now. New field `comparatorType` (less
  agroecological farming 1,802 / natural or semi-natural habitat 30 / another agroecological practice 0),
  a sixth filter "Compared with", a table column, and the sentence names it: "…and a less agroecological
  way of farming (or, for 30 of them, a natural habitat)". `Timber plantation` joined `COMPARATOR_TERMS`
  (42 Paut pairs verified). The 36 agroforestry-vs-agroforestry pairs turned out verified by their
  comparator detail, "Parklands + Monoculture + Unshaded": high-shade multistrata vs unshaded parkland.
  This was the cause of the negative biodiversity cells Lolita noticed: agroforestry-vs-forest richness
  (median −0.80) pooled with agroforestry-vs-monoculture (+0.40).
- **Effect-size type.** `esType` from the row's `out_effect_size_type`: 1,701 log response ratio, 117
  standardised mean difference (Income, Efficiency), 14 blank. A table column and download field; the help
  says the site computes lnRR for every row and SMD is not computed here. Andrea asked for this at 19:28.
- The countries · crops · studies line is gone (Andrea found it out of place; Lolita agreed on reading the
  transcript). Table compacted: smaller type, long cells clipped with the full text as tooltip, seasons and
  source synthesis removed from the table (download only). 30 columns.
- Checks: 65 of 65, locally and live.

**Still open from the recording** (listed to Lolita, her choice): Explore as three entries — Visualise,
Metadata, Download — à la FAOSTAT (1:20, 12:13); a Metadata page with the references (13:03); "Area"
instead of Country, countries before regions, UN continents (8:02); a column chooser for the table (24:06);
Land Equivalent Ratio computed differently (24:45, Andrea); the font (14:39); photo credits (14:47); a
review day with Sarah (11:14). Deferred by Andrea to next year: browsing by practice family, meta-analysis
alongside the medians, a box plot per cell.

## Seventh follow-up the same day (`7ece86e`): heading filters, Columns, tighter map

- Every table heading except DOI carries a funnel that opens an Excel-style filter: text columns list
  the values left by the other filters, with counts and a search; number columns take a from/to range.
  These narrow the whole page (map, heatmap, sentence, table), appear as chips, and clear with Clear all.
  Headings that already have a toolbar filter open that one. Andrea's column chooser (24:06) is the
  **Columns** button beside the downloads; the choice is kept in `localStorage`.
- Gone from every view: the toolbar counter "n / n comparisons" (its elements stay hidden because the
  download button and the checks read them) and the "Country view: … Thin lines are regional
  boundaries" note. The map fits a selection with 14 px of padding and may go to zoom 9, so a country
  fills the frame.
- Checks: 71 of 71, locally and live. Two of the new checks had to be corrected before the push (a `$`
  lost in a Node one-liner; a stale zoom threshold) — the push guard caught both.

## Eighth to sixteenth follow-ups the same day (`b393160` … `bb19879`)

Small requests from Lolita while she clicked through the live site, each pushed on its own:

- The **Columns** picker moved from the download buttons to beside the "Comparisons" title (`b393160`).
- A **Back** button at the top of the findings panel (`1dadc01`): a heatmap cell, row or column, a country
  clicked on the map, Clear all and World view each replace the selection in one go, so the view before
  each is kept (up to twenty) and restored most recent first. Toolbar ticks are not recorded; unticking is
  the way back from those.
- On the explore page the masthead now runs edge to edge, so the site title sits at the same 20 px as the
  first filter instead of floating in at 106 px (`4011a25`). Other pages are unchanged.
- The colour stripe on each table row is 8 px instead of 3 (`00555ed`).
- The table shows every row (`c2b7587`): the 300-row cap per render is 5,000 now, so all 1,832 are on
  the page. A full re-render (map, heatmap, 1,832 × 30 table) measured 411 ms in Chrome; the footer note
  only returns above the cap.
- The colour stripe is 16 px (`229f2b4`), twice the 8 px of the morning.
- **Show all points** re-fits the map to the current selection (`8279824`): after a row or point click
  had flown to zoom 8, clearing the highlight left the map there; `clearSel()` now calls `applyMapMode()`,
  so it returns to the world view, or to the selected country or region.
- **Menu links bigger** (`bb19879`): 13 → 15.5 px, medium weight, the current page bold with a 3 px
  underline. Found while measuring: on a phone the menu had **9 px of room** on the live site and could
  not be seen at all (title + language + theme filled the row; the nav had `overflow:auto` and no
  width). Below 1100 px the menu now takes a full row of its own under the title (`flex-wrap` on
  `.mh-2-in`, `order:5` on `nav.main`); below 760 px the links wrap onto two lines. `--mh` is measured
  by `measureHead()` on resize, so the sticky offsets and the explore stage height follow.
- Checks: 74 of 74 after each.

## Effect-size review the same evening: the extreme values are real, and most are a design question

Lolita asked whether any response ratios were "really high" the way the old percentage figures had
been. Checked all 1,825 published `lnRR` values against the source rows (`check` in the session
scratchpad, `outliers.txt`):

- **Distribution:** median +0.05, quartiles −0.27 / +0.36, 1st–99th percentile −2.31 / +1.86; 234 rows
  beyond ±1 (×2.7), 41 beyond ±2 (×7.4), 9 beyond ±3 (×20), 1 beyond ±4. Jones 35 of the 41, Paut 6.
- **No unit or metric mismatch** between the two arms in Jones (0 of 1,146). Paut has 7 Biswas et al.
  rows, all published, where the control is in m³/ha/yr (timber) or t/ha/yr (crop) and the treatment
  unit reads "m3/ha/yr..t/ha/yr": a tree + crop system whose yield figure is the two added together.
  Timber volume over crop mass is not a ratio that means anything, though the values are small (lnRR
  −0.88 to +0.06) and hide in the middle of the distribution. A Paut extraction quirk; for Andrea.
- **No typo found** among the 25 most extreme rows; every one reproduces from two means the source holds.
  What makes them extreme is the comparison, not the extraction:
  - **Intercrop component yield against the *other* crop's sole stand** (Belay 2009: bean yield in a
    4-maize:1-bean intercrop vs sole bean, 0.2 vs 5.8 kg/plot, lnRR −3.37; Choudhary 2014: 1-maize:5-black
    gram vs sole black gram, −2.41; Gebru 2015: gross return of a tomato–maize intercrop vs sole *maize*,
    171,078 vs 2,811 Birr/ha, +4.11, while the same intercrop vs sole *tomato* is +0.27). A component's
    yield in a mixture is mostly its land share, and a mixture that contains a high-value crop earns more
    than the low-value sole crop by construction. Both are legitimate numbers from the papers and both are
    the classic intercropping pitfall; whether to keep them, keep only total-system rows, or move to LER
    is Andrea's (14 LER rows already exist, unused). 14 of the 41 are of this kind.
  - **Pest and weed counts after a strong treatment** (Khan 2006/2008: Striga and stemborer counts under
    maize–Desmodium, 511 → 24 and 47.8 → 3.7, lnRR −3.06 and −2.70). Real, well-replicated (n = 20), and
    the direction rule turns them positive, as it should. 24 of the 41.
  - **Counts near zero** (Armbrecht 2007: 0.2 vs 9.5 individuals per trap in sun vs shade coffee, +3.86;
    Sileshi 2008 detritivores 0.2 vs 2.2 per plot). lnRR is unstable when a mean is a fraction of an
    individual; 129 published rows have an arm below 0.5 and 11 of those are beyond ±2. A method matter.
- **One row pair worth checking against the paper:** Perry et al. 2016 (cocoa agroforest vs primary
  forest, lnRR −2.87 and −2.79). The forest arm reads 109 species and 148 jack-knife "per sample" with
  n = 8, the agroforest 6.72 and 8.38 with n = 32. 109 species per sample looks like a total pooled over
  the 8 samples set against a per-sample mean. Jones's extraction; flagged, not changed. Both rows are in
  the habitat-comparator set, so they already carry that mark on the site.
- **The old percentages were these same rows.** +5,987 % was Gebru's +4.11; +4,650 % was Armbrecht's
  +3.86. The scale changed, the data did not; on the ±1 colour ramp they now all sit at the end stop.

Nothing was changed in the data or the build. Recorded in `website.md` open items for Andrea.

## For Andrea

1. Ratify or amend `COMPARATOR_TERMS` and the lateral exclusion (90 pairs, all fertiliser vs none).
2. The site shows medians of lnRR as descriptive summaries, labelled as such; nothing pooled.
3. The ontology's `Sign` column (lower is better for costs, pests, weeds) is not applied; the text says
   "higher value", not "better".
4. The pest-management swap label ("Inoculants / No Chemical Applied") and natural/semi-natural habitat as
   "less agroecological alternative" read awkwardly; wording, not data.

## Still open

Spanish and French unreviewed by a native speaker or an agronomist (now 145/146 vocabulary terms); four photo
credits; the repository on a personal GitHub account. The Hub repo (`Agroecology_Evidence_Hub/`) was **not**
committed — it holds other people's uncommitted ERA work — so these `knowledge/` edits are on disk only.
