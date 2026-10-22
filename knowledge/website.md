# The public website

The Hub's public face: a static site that shows the harmonized comparisons on a map, lets people filter and
download them, and explains the project. Live at **https://mlolita26.github.io/agroecology-evidence-hub/**.

Counts, sizes and versions: `_status/website.md`. Nothing here carries a number.

## What it is, and what it deliberately is not

It is **one folder of files that a browser opens**. No server, no database, no build step beyond one Python
script, no framework, no package manager. The whole site is HTML, CSS and one file of plain JavaScript, and
the code is written to be read by the team rather than by a tool.

That is a choice, not a limitation. The Hub has no web developer and no hosting budget, so anything that
needs a server to stay up, or a dependency tree to build, is something that breaks later with nobody able
to fix it. GitHub Pages serves the folder for free and has no moving parts.

**It is not the Platform.** The Stats4SD platform was a separate, partner-owned thing and is no longer in
the picture; this site does not replace it and does not pretend to its scope.

## Where it lives

`website/` at the Hub root, **outside** `Agroecology_Evidence_Hub/`, and it is a git repository of its own
pushed to GitHub. `website/README.md` is the real manual — layout, every file's job, how to run it locally,
how the languages work, how the caching works. Read that before changing anything.

```
website/
  build.py      turns the clean effect-size CSVs into the site's data files
  docs/         the site itself; this is the folder GitHub Pages serves
  tools/        fetch_boundaries.py, for the country outline files
```

The site is served from `docs/` on `main`, so **pushing to `main` publishes**. There is no staging copy.

## How data reaches it

`build.py` reads every CSV in `02.FOMD/04.metadata_effectsize/03.fomd10_clean` — the same clean `10_` schema
tables the analysis uses — and writes the site's data files into `docs/`. It is standard library only, so
there is nothing to install, and it is run by a person, never on a schedule.

Consequences worth knowing:

- **The site's data is a committed snapshot.** It does not track `03.fomd10_clean`. Somebody has to run
  `build.py` and commit for the site to be current, and nothing warns you when it has drifted. It has
  already been stale once.
- **The site computes its own effect sizes** from the paired `C_…` / `T_…` means, rather than reading the
  effect-size columns. So it does not inherit bugs in the effect-size scripts, but it also does not inherit
  their fixes. It shows the effect size `yi` with its standard error `se` and variance `vi` for each
  comparison, and medians of `yi` as summaries; none of that is a pooled estimate Andrea has ratified. The map is for orientation and download, **not** a
  published analysis.
- **Downloads are always in English**, whatever language the page is in, so that everyone is working from
  one vocabulary. The interface and the data terms are translated for display only.

## Five rules that are enforced in the code

**Positive always means the agroecological practice did better.** The effect size the site shows, `yi`, is
ln(T/C) turned by the outcome's good direction: +1 where a higher value is better, −1 where a lower one is
(costs, erosion, pests, weeds). The direction comes from the `Sign` column of the ontology's `01_outcomes`
sheet, copied read-only by `tools/fetch_outcome_signs.py` into `outcome_signs.csv`. `build.py` adds two
things the sheet does not settle, both marked as belonging in the workbook: the obvious reading of the four
sub-indicators left blank (`SIGN_FIXES`), and a rule for Abundance by organism counted (`BAD_ORGANISMS`:
more weeds or pests is worse), because the sheet marks Abundance "higher is better" for every organism.
Comparisons with no known direction have no `yi`, colour grey, and stay outside "did better". The download
keeps the raw `lnRR` and the `direction`, so anyone can undo it. Lolita decided this on 2026-10-19 after
reading the summary sentence; the counts either way are in `_status/website.md`.

**The practice is always the agroecological arm.** The sources label their arms control and treatment
their own way, and sometimes the conventional arm is the "treatment". `build.py` holds a list of
conventional terms, `COMPARATOR_TERMS`, written from the level-0 row of `control_treatment_scoring.md`
together with its rule that the absence of an input is not agroecology. A comparison whose source
treatment carries one of those terms, and whose control does not, is turned round before anything is
computed. One where both arms carry one has no agroecological side: it is set aside and not published.
The build prints every swap and every pair set aside on each run, so the list is checked against the data
every time. The list is Andrea's to ratify; counts are in `_status/website.md`. A natural or semi-natural
habitat is never the practice: against farming it is the comparator and the comparison is marked as such
(`comparatorType`, a filter and a column, named in the summary sentence); against conventional farming, or
another habitat, the pair has no agroecological practice and is set aside too.

**Everything is served from the repository.** The site loads no script, stylesheet, font or map data from
anyone else's server. Libraries, fonts and the boundary files are all committed under `docs/vendor/`, which
has its own README saying where each came from, its licence, and how to update it. This replaced loading
from several CDNs, one of which had already broken silently. Do not reintroduce an external `<script>` or
`<link>`; the point is that the site still works years from now, and that visitors are not announced to
third parties.

**A synthesis is published unless it is named in `SKIP_SOURCES`.** That list at the top of `build.py` carries
the reason beside each entry, and the build prints it on every run, so leaving a source out is a decision
somebody recorded rather than something that quietly happened. ERA is currently the only entry — see
`_status/website.md` for why and what it would take to include it.

**The build refuses to publish a dataset too large to load.** The whole dataset goes to the browser as one
file, and past a point that costs more to parse and hold in memory than a page can afford. The cost is
*not* mainly the download — the server compresses it, so what travels is a small fraction of the file on
disk. Past a ceiling, `build.py` writes nothing, explains, and leaves the last dataset that fit in place,
so the published site keeps working.

Hitting that ceiling does not mean the data cannot be shown; it means it has outgrown *this shape*. Sending
only the fields the map needs, splitting by country, or moving to Parquet are all ways forward, and
`_status/website.md` has the measured cost of each. Raising the number without changing the shape is the one
option that is not.

## Asking for data, and reaching us

The Get involved page is a dataset-submission form and the Contact page a message form. Both have no
backend: they open the visitor's own mail client, addressed to Lolita. A browser cannot attach a file that
way, so the form asks people to attach the dataset themselves and says so. If submissions ever need to be
collected properly rather than mailed, that needs a service and a decision.

## Open, and who decides

| Item | Whose call |
|---|---|
| Spanish and French reviewed by a native speaker **and** an agronomist — currently unreviewed | Andrea / team |
| Photograph rights: most hero images have no cleared licence recorded | Lolita |
| The repository sits on a personal GitHub account, not an institutional one | Lolita / Sarah |
| The list of conventional terms that orients each comparison, and leaving out pairs with no agroecological side | Andrea |
| The good direction per outcome: four blank `Sign` cells in `01_outcomes`, and Abundance, whose direction depends on the organism and so cannot sit in a per-sub-indicator column; both live in `build.py` until the workbook has them | Lolita (workbook), Andrea (method) |
| Whether the site shows ERA at all, and under what caveat | Andrea |
| Whether to publish a real analysis rather than a percentage change | Andrea |
| Intercrop component yields compared with the *other* crop's sole stand (Belay 2009, Choudhary 2014, Gebru 2015: the largest effect sizes on the site, lnRR −3.4 to +4.1, are of this kind); and lnRR on counts near zero (129 rows with an arm below 0.5). Keep, restrict to whole-system rows, or use LER — see the 2026-10-19 log | Andrea |
| Biswas et al. (Paut): 7 published yield rows whose treatment unit is "m3/ha/yr..t/ha/yr", timber volume and crop mass added, set against a single-unit control; small values, meaningless ratio | Andrea |
| Perry et al. 2016 richness rows: the forest arm (109 species, n = 8) looks like a pooled total set against per-sample means (6.72, n = 32). Check against the paper | Lolita / Jones extraction |
| A domain name, and anything that costs money | Sarah |

The map, the filters, the languages and the forms are all documented in `website/README.md`; this doc exists
so the knowledge base knows the site is there and who owns the decisions about it.
