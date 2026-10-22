# Status — the public website

**Owner: Lolita.** Read via `../01_status.md`. Figures verified **2026-10-19**.

Live: https://mlolita26.github.io/agroecology-evidence-hub/ — repo `Mlolita26/agroecology-evidence-hub`,
commits `442ae07` … `bb19879`, twenty on 2026-10-19 (the explore-page redesign after the October review,
the plain-words summary, "did better" with the direction from the ontology, the three-level heatmap and a
map fix, sortable filter options, two download buttons, habitats as comparators with the effect-size type
and a compact table, Excel-style heading filters with a Columns picker, a Back button, every row in the
table, and small layout fixes: a 16 px colour stripe, Show all points re-fitting the map, and bigger menu
links with a menu row of their own below 1100 px — before `bb19879` the menu had 9 px of room on a phone
and could not be seen at all).
Context and the rules behind these figures: `../website.md`.

## Published now

**1,832 comparisons / 12 countries** (1,860 until `e2fb07f`, which set aside 28 habitat pairs), from two of
the three syntheses in `03.fomd10_clean`, as re-exported on 2026-10-13/14 (Hub commit `a39b405`, "updates
4"):

- `MD_Jones_21_A glo_Sc` — **883** records: 863 as the source had them, **20 with the arms swapped** (15
  no-chemical/inoculants against synthetic pesticide, 5 zero against conventional tillage); **74 pairs set
  aside as lateral**, all fertiliser against no fertiliser; **28 set aside with no agroecological practice**
  (18 natural habitat and 5 semi-natural habitat against monoculture, 5 natural against semi-natural
  habitat); 161 rows unusable (no coordinates, control mean or contrast).
- `MD_Paut,_24_A glo_Sc` — **949** records: 0 swapped; **16 set aside**, fertiliser against no fertiliser;
  51 unusable.

Before orientation the same files give 1,950. `docs/data.js` 1.8 MB, `docs/data.csv` 1.1 MB.

**Compared with** (`comparatorType`): less agroecological farming **1,802** (of which 42 against timber
plantation and 36 high-shade agroforestry against unshaded parkland monoculture, both verified by the
comparator detail), natural or semi-natural habitat **30** (all agroforestry against forest). **Effect size
type** the ontology assigns (`esType`): log response ratio 1,701, standardised mean difference 117 (Income,
Efficiency), blank 14. The site computes lnRR for all; SMD is Andrea's to compute.

History: 1,464 until 2026-09-30; 1,449 from 2026-09-30 (the Jones source lost the study
`JA_Perry_16_how n_Fo` upstream); 1,860 from 2026-10-19 (the October re-export fills coordinates and means
on about 500 more rows, less the 90 lateral pairs now left out).

## Not published: ERA

`MD_Rosen_24_Effec_Sc` arrived in `03.fomd10_clean` on **2026-09-28 14:38** and is named in `SKIP_SOURCES`
in `build.py`. It builds **87,796 records**, which would take the site to 89,245 records / 49 countries.

Two independent blockers:

1. **Size and rendering.** 65 MB as one `data.js`, past GitHub's 50 MB warning and near its 100 MB block.
   `MAX_DATA_MB` is 20 and the build refuses above it. **Measured 2026-09-30, and it is less bad than first
   written here** — see "What ERA would actually cost" below.
2. **Effect sizes.** Produced by `04.fomd10_effect_size_era.R`, which has the open bug in
   `_meta/log/2026-09-28-02-lnrr-cv-imputation-bug.md`. The site computes its own lnRR and guards
   `c_mean <= 0`, so it escapes the reversed bias-correction sign and the CV imputation, but zero and
   near-zero means would still distort the percentage change it displays.

**Boundary coverage if ERA were included:** of its 49 countries, 20 have no ISO3 code in `build.py`
(Algeria, Burundi, Cabo Verde, Chad, DRC, Costa Rica, Ecuador, Egypt, Gambia, Haiti, Honduras, Ivory Coast,
Madagascar, Mauritius, Namibia, Nicaragua, Sudan, Swaziland, Togo, Venezuela) and 17 more need files
fetched. `build.py` prints both lists every run. `Ivory Coast` and `Swaziland` are not geoBoundaries' names
(Côte d'Ivoire, Eswatini).

## What ERA would actually cost — measured 2026-09-30

Chrome, phone viewport (390 x 844), local server, all 89,245 records. Against the 1,449 shipped today.

| | today | with ERA |
|---|---|---|
| records | 1,449 | 89,245 |
| transferred, gzipped | 62 KB | **2.3 MB** |
| parse | 3 ms | 1,503 ms |
| JS heap after load | 4 MB | 113 MB |
| draw, SVG renderer | 25 ms | 699 ms |
| draw, canvas renderer | 18 ms | 279 ms |

**Hosting is not the problem.** GitHub Pages gzips: the 1.2 MB `data.js` shipped today transfers as 62 KB
(verified against the live site), and 65 MB raw would transfer as about 2.3 MB. The repository would sit near
70 MB against a 1 GB soft limit, and 100 GB/month of bandwidth is roughly 43,000 full visits. **No server and
no paid hosting are needed at this size.** The real costs are the 100 MB hard per-file block, which 65 MB
approaches, and that git keeps every past version forever, so repeated rebuilds accumulate.

**The renderer is the problem, and it is close to a one-line fix.** Panning and zooming re-project every
point, so the first draw is not what matters:

| 89,245 points, phone viewport | SVG (what the site uses now) | canvas |
|---|---|---|
| median frame during pan/zoom | **489 ms — about 2 fps** | **14 ms — smooth** |
| worst frame | 601 ms | 253 ms |
| two pans | 1,038 ms | 192 ms |
| SVG nodes in the DOM | 89,248 | 3 |
| heap | 235 MB | 219 MB |

`L.map()` in `app.js` does not set `preferCanvas`, so it uses SVG and puts one DOM node per record. At 89k
that is unusable. With `preferCanvas: true` the same 89k points pan at 60 fps.

**What is left after that** is memory: ~219 MB of heap. Desktop is comfortable; iOS Safari has been known to
discard tabs in that range, so low-end mobile is the genuine risk. Sending only the fields the map needs, as
columns rather than one object per row, is 260 KB gzipped instead of 2.3 MB and would cut the heap
accordingly, with the full record fetched when somebody opens one.

## How far this shape scales — measured 2026-09-30

Canvas renderer, phone viewport, real records replicated with jittered coordinates. "Pan hitch" is the
worst frame while dragging, which is what a user feels; the *median* frame stays near 17 ms at every size
because idle frames dominate it, so median is not the number to watch.

| records | JS heap | pan hitch | verdict |
|---|---|---|---|
| 89,245 (ERA today) | 83 MB | 275 ms | fine on desktop, noticeable |
| 200,000 | 175 MB | 371 ms | desktop fine, mobile tight |
| 400,000 | 342 MB | 845 ms | fails on mobile |
| 800,000 | 673 MB | 1,810 ms | fails widely |

**Memory is the binding constraint, not speed.** Parse time and heap both scale with the record count, and
mobile browsers discard tabs in the 200–400 MB range.

**Headroom: this shape holds to roughly 200,000 records.** Record yield per primary study varies more than
tenfold between sources — ERA is **48.5** records per study, Jones and Paut **2.7** — so the count depends
far more on which sources arrive than on how many papers do. Against the 1,000+ further papers expected,
that is between ~2,700 and ~48,500 more records, putting the total at **92,000 to 138,000**: inside the
headroom, but with the ~579-study manual backlog and a target of 10+ sources, not indefinitely.

**What changes the ceiling** is not a bigger file but drawing fewer things: aggregate per country or region
at world zoom and load individual points only on drill-down. Cost then follows what is on screen rather
than the size of the dataset, and stops mattering. The site already drills down per country, and the
boundary files are already per country, so the interaction model for this exists.

**Not yet measured:** the comparisons table at 89k rows, the per-filter recount in `render()`, and the
heatmap. Those are app-level costs, separate from the map.

## Measured again 2026-10-21: the whole explore page, not just the map

The September figures covered the map alone with a canvas renderer. This run loads the **real page as
shipped** (SVG markers, heatmap, 5,000-row table cap, per-filter recount) with the current records
replicated and jittered, Chrome 1400 × 900, local server. Times are wall-clock from navigation to the first
table row, then one crop filter ticked, then Clear all. No page errors at any size.

| records | data.js raw / gzipped | load + first render | one filter | Clear all | JS heap | verdict |
|---|---|---|---|---|---|---|
| 1,832 (today) | 1.9 MB / 0.10 MB | 3.7 s | 0.3 s | 2.1 s | 50 MB | fine |
| 18,320 (×10) | 19.5 MB / 1.1 MB | 10 s | 1.5 s | 6.7 s | 153 MB | usable; the build guard (`MAX_DATA_MB` = 20) stops here on purpose |
| 45,800 (×25) | 48.7 MB / 2.8 MB | 12 s | 3.1 s | 9.0 s | 349 MB | desktop only, and unpleasant; phones will drop the tab |
| 91,600 (×50) | 97.5 MB / 5.6 MB | 18 s | 7.2 s | 12.8 s | 391 MB | past GitHub's 100 MB per-file limit as one file; not acceptable |
| 164,880 (×90, ERA scale) | 175 MB / 10 MB | 30 s | 3.9 s | 30 s | 723 MB | fails as one file |

Read with the September table: the map alone was ~3× lighter than this, so **the app-level costs (table,
heatmap, recount, SVG markers) now dominate**, and those are the first thing to fix before any hosting
change — a canvas renderer and a virtualised table would roughly halve every row above.

**Where the data stands against this.** 1,832 rows from 40 studies = **46 rows per study**. Doubling the
current extractions (~3,700 rows, ~4 MB raw / 0.2 MB over the wire) is indistinguishable from today.
1,000 further papers at this yield ≈ 47,000 rows = the ×25 row: works, but that is the point to change
the data format, not the host. ERA is the ×90 row and does not fit this shape at all.

**Hosting is not the constraint; the browser is.** GitHub Pages serves the 0.1 MB gzipped file today and
would serve a 10 MB one; its real limits are 100 MB per file, 1 GB per site, 100 GB/month bandwidth
(soft). Moving the same single file to S3 changes none of the numbers above. What changes them is not
sending the whole dataset to every visitor: split per synthesis and load on demand, or publish Parquet and
query it in the browser with DuckDB-WASM over HTTP range requests (static hosting, GitHub Pages or S3,
no server), or a real database behind an API. The first costs nothing and buys ~×3; the second is the
standard answer for 100k–10M rows on a static site; the third is the one that costs money every month.

Script and generated files: `stress.js` and `stress/` in the session scratchpad (deleted after the run).

## The explore page, since the October 2026 review

- **30 table columns**, study first, no side panel (compared with, effect-size type, good direction, `yi`,
  `se`, `vi` among them; seasons and source synthesis are download-only). Heatmap:
  **14 outcome columns** under three header rows — **2 pillars** (Productivity 4, Resilience 10), **5
  sub-pillars** (Yield 1, Economics 3, Biodiversity 6, Physical 2, Efficiency 2). Biodiversity pools the
  organisms into one column per outcome and lists them in the heading; Efficiency is split by measure
  (energy use, water use) because the outcome is named only after its sub-pillar. **7 UN M49 sub-regions**
  in the region filter; Malawi and Zambia moved from "Southern" to "Eastern Africa" to match M49.
- Colour scale is **`yi`, cut at ±1**: the effect size turned so that positive means the practice did
  better; pink worse, teal better, grey no effect size. `yi` is null for **43** records: 36 Abundance rows
  that name no organism (no direction) and 7 with a zero treatment mean (no lnRR). `se` is null for
  **1,049 of 1,832** (57 %), almost all Paut, whose dispersion is "Unspecified" in the source.
- **Direction table** (`outcome_signs.csv`, from the ontology 2026-10-19): 165 sub-indicators, 114 higher
  is better, 41 lower is better, 10 blank. Of the blanks, four occur in the data and are read the obvious
  way in `build.py`: Damage caused by pest (lower), Soil Available Phosphorus, Soil Available Potassium,
  Energy Use Efficiency (higher).
- **"Did better", with that direction applied** (what the sentence says; the "higher" figures are what it
  said before 438640c):

  | group | comparisons | did better | typical | was "higher" |
  |---|---|---|---|---|
  | all | 1,860 | **57 %** | **+7 %** | 55 % |
  | Yield | 808 | 39 % | −9 % | 39 % |
  | Biodiversity | 418 | 58 % | +14 % | 54 % |
  | Economics | 348 | 73 % | +18 % | 85 % |
  | Physical (soil, pests) | 271 | 87 % | +24 % | 67 % |
  | Efficiency | 15 | 53 % | +10 % | 53 % |
- Biodiversity "of what": the **outcome filter** (25 options) splits Abundance by organism (weeds 115,
  pests 82, natural enemies 46, detritivores 24, migrant 12, resident 12, parasitoids 1, unspecified 42)
  and Richness, Richness Estimator, Diversity, Dominance and Evenness into 1–3 each; the heatmap pooled
  these again on 2026-10-19 (`d8f23a9`) because 17 biodiversity columns could not be read.
- A selection whose points all share one site (Cowpea: 36 comparisons, 1 site) blanked the map until
  `d8f23a9`: bounds with no area, no zoom ceiling. `fitBounds` now stops at zoom 8, the map at 12.
- **Verified 2026-10-19** in Chrome, locally and against the live site: **52 of 52** automated checks pass
  (map and findings side by side at 1400 px and stacked at 390 px; 7 legend swatches, pink left and teal
  right in both themes; region filter first with 7 regions and the country list grouped under them;
  active-filter colouring; two heatmap header rows whose colspans add up; no conventional term among the
  practice rows; 30 table headings each with help text, first column sticky, no percentage column; row
  click and Escape; Spanish and French; download header equal to `KH_COLUMNS`; no external requests; no
  console errors). Re-run after each of the four commits: 52 of 52 for the first three, 56 of 56 after `d8f23a9` (four checks added: pooled biodiversity, organism list in the heading, pillar colspans, the single-site zoom), 59 of 59 after `3ccf247` (sorting), 63 of 63 after `808e78d` (the two downloads: hidden/shown, row counts of each file), 65 of 65 after `e2fb07f` (habitat count in the sentence, the habitat filter), 71 of 71 after `7ece86e` (column picker, a text heading filter, a number range, chips, Clear all), 74 of 74 after `1dadc01` (Back hidden at load, shown after a heatmap click, restoring the count), and 74 of 74 after each of `c2b7587`, `229f2b4`, `8279824` (zoom 2 → 8 on a row click → 2 after Show all points, checked by hand) and `bb19879` (every menu link inside the viewport at 1400, 1180, 1024, 760 and 390 px, title on one line at each, checked locally and live). Script: `verify.js` in the session scratchpad, described in the log entry.

## Vendored dependencies

`docs/vendor/`, 3.3 MB, **zero external requests** — verified 2026-09-30 in Chrome with every non-origin
request blocked, against both a local server and the live site.

- `adm1/` — 12 country region files, 2.8 MB. Trimmed from 14.7 MB by `tools/fetch_boundaries.py`
  (81 % smaller): 4 decimal places, ~11 m, and Douglas-Peucker at 0.003°, ~330 m.
- `fonts/` — 9 woff2 files, 224 KB, 17 font faces.
- Leaflet 1.9.4, topojson-client 3.1.0, world-atlas 2.0.2 countries-110m.

Per-file provenance, versions and licences: `website/docs/vendor/README.md`.

## Languages

Three: English, Spanish, French. English is the source text, in `index.html`. `i18n.js` holds the interface
strings and `vocab.js` the data terms, display only — 145 Spanish, 146 French since 2026-10-19 (pillars,
sub-pillars, organism groups, four sub-indicators and three crops added). The lists differ only over
country names spelled the same in both languages, so nothing is missing.
**Neither has been reviewed by a native speaker or an agronomist.**
