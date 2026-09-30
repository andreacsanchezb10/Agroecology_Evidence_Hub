# Status — the public website

**Owner: Lolita.** Read via `../01_status.md`. Figures verified **2026-09-30**.

Live: https://mlolita26.github.io/agroecology-evidence-hub/ — repo `Mlolita26/agroecology-evidence-hub`,
commit `c39f596`. Context and the rules behind these figures: `../website.md`.

## Published now

**1,449 comparisons / 12 countries**, from two of the three syntheses in `03.fomd10_clean`:

- `MD_Jones_21_A glo_Sc` — 561 records
- `MD_Paut,_24_A glo_Sc` — 888 records

`docs/data.js` 1.2 MB, `docs/data.csv` 765 KB. Site total 6.4 MB, of which `docs/vendor/` is 3.3 MB.

Was 1,464 until 2026-09-30. The Jones source dropped to 561 when it was rebuilt on 2026-09-25; all 15
missing records are the single study `JA_Perry_16_how n_Fo`, removed upstream.

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
strings and `vocab.js` the data terms, display only — 121 Spanish, 122 French. The lists differ only over
three country names spelled the same in both languages (Colombia, Vietnam, Malawi), so nothing is missing.
**Neither has been reviewed by a native speaker or an agronomist.**
