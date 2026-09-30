2026-09-30 — **Website now serves everything from its own repository; ERA has reached the website's source
folder and does not fit** — `website/README.md`, `website/docs/vendor/README.md` (both new sections; no
`knowledge/` doc edited, see the gap noted at the end).

**Live:** https://mlolita26.github.io/agroecology-evidence-hub/ — commits `33b3677`, `c39f596`.
Publishing **1,449 records / 12 countries** (Jones 561, Paut 888).

## What changed

The pages used to load Leaflet from unpkg, topojson-client from jsdelivr, the three fonts from Google, the
world geometry from unpkg, and one regional boundary file per country click from
`media.githubusercontent.com`. Five servers outside our control, two of them integrity-pinned, and the
boundary fetch had already failed silently once when geoBoundaries moved a file.

All of it is now in `website/docs/vendor/` (3.3 MB) and the site makes **no external request at all**.
Verified in a real browser with every non-origin request blocked, both locally and against the live site: no
request leaves the origin, the 17 font faces load, the map draws 1,641 shapes, and ticking a country fetches
`vendor/adm1/KEN.json` rather than GitHub. No console errors.

- `website/tools/fetch_boundaries.py` (new) downloads the geoBoundaries ADM1 sets and trims them for the web:
  coordinates to four decimal places (about 11 m) and Douglas-Peucker at 0.003° (about 330 m), both well under
  a pixel at the zoom they are drawn as hairlines. **14.7 MB to 2.8 MB, 81 % smaller**, no visible difference.
  Twelve countries fetched. Iterative, not recursive, or a long coastline exceeds Python's recursion limit.
- `build.py` gained `check_boundaries()`, which names any country in the data with no ISO3 code or no boundary
  file and prints the `fetch_boundaries.py` command that fixes it, and `write_iso3()`, which generates
  `docs/iso3.js` so the country codes the browser uses come from the single table in `build.py` rather than a
  second copy in `app.js` that could drift.
- `website/.gitattributes` (new) keeps line-ending conversion away from the woff2 and png files, where it is
  corruption rather than formatting and shows up as missing glyphs on someone else's machine.

Licences checked: Leaflet and topojson-client BSD/ISC, the three fonts SIL OFL 1.1, world-atlas ISC,
geoBoundaries CC BY 4.0. All redistributable; geoBoundaries is credited on the About page.

## Three findings

**1. ERA is now in the website's source folder and one JavaScript file cannot carry it.**
`fomd10_clean_MD_Rosen_24_Effec_Sc.csv` appeared in
`02.FOMD/04.metadata_effectsize/03.fomd10_clean` on 2026-09-28 14:38. The website build reads every CSV in
that folder, so it would now produce **89,245 records** (Jones 561, Paut 888, Rosen 87,796) against the 1,449
the site was built for. As one `data.js` that is **65 MB**: past GitHub's 50 MB warning, near its 100 MB
block, and every visitor would download and parse all of it before the map drew anything. 89,000 Leaflet
circle markers would not render acceptably either.

Two mechanisms now, because the first one alone was the wrong shape:

- `write_outputs()` refuses to write more than `MAX_DATA_MB` (20), says why, and leaves the last dataset that
  fit in place, so the site keeps working. **This is not a number to raise.** It means the data has outgrown
  a single file and needs a real format behind it (Parquet, or per-country files fetched on demand); that is
  a piece of work to plan, not a constant to edit.
- `SKIP_SOURCES` names the syntheses the website does not publish, with the reason beside each, printed on
  every run. The size guard alone made the build all-or-nothing: one source that cannot be published stopped
  the two that could, which is how the stale Jones data below went unnoticed. Everything in the folder is
  published unless it is named in `SKIP_SOURCES`, so an exclusion is a recorded decision, not a silent
  omission. ERA is the only entry.

**Not published, and there is a second reason not to.** `2026-09-28-02-lnrr-cv-imputation-bug.md` records an
open, unfixed bug in `fomd_fun/fun_cv_missing_calculation.R`, used by `04.fomd10_effect_size_era.R` — the
script that produced this file. The website computes its own lnRR from `C_out_value`/`T_out_value` and guards
`c_mean <= 0`, so it does not inherit the reversed bias-correction sign or the outlier-driven CV imputation.
But point 4 of that entry, zero and near-zero means reaching the effect-size step, would affect the
percentage change the website displays. The ERA subset should not go on the public site until that is
resolved, whatever is done about the size.

**1b. The published data was stale, and the guard nearly hid it.** `data.js` held **576** Jones records; the
source has yielded **561** since it was updated on 2026-09-25. All fifteen missing records are the single
study `JA_Perry_16_how n_Fo` (Abundance, Richness, Richness Estimator on agroforestry vs monoculture), so
this is a whole-study removal upstream rather than damage. Now republished at 1,449. Worth noting that the
website's copy of the data can drift from `03.fomd10_clean` without anyone noticing, because nothing compares
them; the build has to be run and committed for the site to be current, and only a person decides when.

**2. ERA's `T_country` is a multi-value column.** A row covering several sites lists one country per site,
joined with `..`, exactly as the coordinates are. The website was storing the whole cell as the country name,
giving values like `"Malawi..Malawi..Malawi"` and `"Burkina Faso..Ghana..Kenya..Malawi..Mali..Niger.."`.
`build.py` now has `first()` and takes the leading value, matching the first coordinate it already plots.
**Country count 121 → 49.** Anything else reading `T_country` from the ERA harmonization should split on `..`
the same way.

After the fix, 20 of those 49 countries have no ISO3 code in `build.py` (Algeria, Burundi, Cabo Verde, Chad,
DRC, Costa Rica, Ecuador, Egypt, Gambia, Haiti, Honduras, Ivory Coast, Madagascar, Mauritius, Namibia,
Nicaragua, Sudan, Swaziland, Togo, Venezuela) and 17 more need boundary files. `build.py` prints both lists
on every run, so this cannot be forgotten. Note `Ivory Coast` and `Swaziland` are not the names geoBoundaries
uses (Côte d'Ivoire, Eswatini) — a name-matching question for whoever adds them.

## Gap worth naming

There is **no website document anywhere in `knowledge/`** — no doc owns the site, its deployment, or its data
pipeline, and `01_status.md` has no figure for it. Everything durable currently lives in `website/README.md`,
`website/docs/vendor/README.md` and five log entries (2026-09-16-01 through -04 and this one). If the site is
going to be a standing output rather than a draft, it needs a doc and a `_status/` owner. Not created here
because adding a top-level `knowledge/` doc changes the doc map and is not mine to decide alone.
