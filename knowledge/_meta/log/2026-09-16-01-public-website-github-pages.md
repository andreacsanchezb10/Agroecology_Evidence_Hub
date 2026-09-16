2026-09-16 — Public website built and published (Lolita's request). New folder `website/` at the **Hub
root** (outside `Agroecology_Evidence_Hub/`, so it is a **separate git repo**):
github.com/Mlolita26/agroecology-evidence-hub, served by GitHub Pages from `main` / `docs` at
**https://mlolita26.github.io/agroecology-evidence-hub/**. Verified live: page, `app.js`, both stylesheets
all return 200.

Architecture is deliberately minimal: `build.py` (standard library only) reads every CSV in
`02.FOMD/04.metadata_effectsize/03.fomd10_clean` and writes `docs/data.js` + `docs/data.csv`; `docs/` is the
whole site (`index.html`, `styles.css`, `explore.css`, `app.js`) and is what Pages serves. No server, no
database, no build tooling. UI carried over verbatim from the Claude Design handoff
(`Downloads/Knowledge Hub Interactive Map.zip`, kept there, not copied into the Hub).

**The dataset IS published**, on Lolita's decision, so the site can be circulated for feedback with every
option working. `docs/data.js` and `docs/data.csv` are committed; the live site serves all 1464 comparisons
and the Download button returns the current selection. (First published without them, git-ignored, then
un-ignored the same day: an empty site was no use for feedback.) Still Draft 0.4 / not yet citable, and it
is public, so the harmonised data of both source syntheses is now openly downloadable and indexable.
`app.js` keeps a "no dataset loaded" banner as a guard for a fresh clone before `build.py` has been run.

Pipeline verified against the design handoff's 1464-record reference: **same 1464 records, same set**, and
every field matches except three known, deliberate points. (1) Coordinates and other numeric cells can carry
the schema's `..` multi-value separator (e.g. `T_site_latitude` = `-8.517..-8.367` in
`JA_Perry_16_how n_Fo`); `number()` takes the first value. Missing this dropped 30 records on the first run.
(2) A reported dispersion of exactly `0` is treated as *no dispersion*, so `lnRR_SE` is null there rather
than an understated number. (3) Study labels keep compound surnames (`Ayala Sánchez et al. 2009`); the
handoff's prototype truncated to the first word. Two of 1464 `value` cells differ by 0.1 pp from the
prototype, which rounded halves the JavaScript way; left as Python's rounding.

Derivation notes not written down elsewhere: practice/comparator come from the first `*_theme` column whose
two sides differ (`C: … _vs_T: …`), label = first term of the ` + ` list, detail = treatment side of the
matching `*_practice` column; the source has **no region column**, so country→region is a 12-entry lookup in
`build.py`; `SEM`/`SE` are converted to SD with `sqrt(n)`, while IQR, 95% CI and `Unspecified` give null.

Git: new repo only, the shared `Agroecology_Evidence_Hub` repo was **not** touched. `.git/` for `website/`
is inside the synced OneDrive tree, so the one-person-at-a-time rule applies to it too.
