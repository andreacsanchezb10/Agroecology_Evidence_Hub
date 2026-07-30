# ERA — what it is, and how its raw data is built

Counts and versions: `../../01_status.md`. Project context: `../../02_the_project.md`.

## What ERA is, and its place in the project

**ERA** (Evidence for Resilient Agriculture) is a large curated database of extracted African crop and
livestock field experiments — Rosenstock et al. 2024.

In this project ERA is **one source synthesis among a target of ten or more**, registered as
**`ss_id = MD_Rosen_24_Effec_Sc`**. Both names refer to the same thing: "ERA" in conversation and in this
folder, `MD_Rosen_24_Effec_Sc` in the workbooks and in Andrea's scripts. The protocol chose it as the
**first, baseline** source because it is stable and reproducible, and **all of its studies pass primary-study
screening as status `I`** — data complete, no manual extraction needed. That is why ERA is a pure
harmonization job rather than an extraction job. → `../../03_somd_and_fomd.md`

**ERA is Africa-only.** Every geographic statement in this folder is about ERA, not about the Hub, whose
scope is global. Don't generalize ERA's coverage to the evidence base.

**What ERA is not:** it is not "the data" and not the schema. The target schema is the `10_` template
(`../../05_data_schemas.md`); ERA is one dataset being translated into it.

ERA's own design philosophy, from the team's notes: *"ERA is designed to make a dataset that is useful for
other users, not a single use."* Which is exactly why it needs translating rather than consuming directly.

## What "harmonized" means for ERA

1. **One row = one Control-vs-Treatment outcome comparison.** ERA stores one mean per row; the pipeline
   pairs a control arm with a treatment arm so each output row is a contrast. Most columns become `C_…`/`T_…`
   pairs.
2. **Practices standardized to the ontology** — ERA codes and free text translated to controlled
   `01_practices` names. → `../../06_ontologies.md`
3. **Crops, trees and animals standardized** to the ontology product/variety/tree sheets.
4. **Values made analysis-ready** where possible: aligned type/amount/unit lists, corrected sample sizes,
   labelled variance metrics, explicit control labels.

Outcomes span productivity (yield, biomass, weight gain), resilience (soil, water), mitigation (methane,
CO₂, N₂O) and economics.

---

# The raw ERA data model

You rarely read the raw snapshots by hand — but when a value looks wrong or missing, tracing it back to the
source table is how you diagnose it.

## The four snapshots

ERA is relational: each study's information is spread across many tables linked by keys (study code, site,
time, treatment level-name), exported as four **snapshots**. The pipeline reads all four, joins what it
needs, and pairs control against treatment.

Loaded from `C:/Users/mlolita/Downloads/era_cache/{snap}.RData`; each file loads a single **list of
data.tables** (the object is named `data` for cc — use `get(ls(e)[1], e)` to be safe).

| Snapshot | Focus | Approx. `Data.Out` rows |
|---|---|---|
| `ie` | crops (largest) | ~71,900 |
| `mh` | crops | ~39,100 |
| `sc` | livestock (small ruminants etc.) | ~10,800 |
| `cc` | livestock — "Courageous Camel" | ~9,700 |

## Key tables

Names are consistent across snapshots unless noted.

- **`Data.Out`** — the core: one row per measured observation. `ED.Mean.T` (the mean), `ED.Error` +
  `ED.Error.Type` (dispersion — SE/SD/CV/Grouped…), the outcome (`Out.Subind` / `ED.Outcome`),
  `ED.Comparison` (1/2), `ED.Reps`, `ED.Animals`, `ED.Intake.Item` (livestock feed), `P.Product`,
  `ED.Product.Comp`. **One mean and one error per row** — the contrast is built by pairing two rows.
- **`Out.Out`** — outcome definitions: `Out.Subind`, `Out.Unit`, `Out.Group`.
- **`Pub.Out`** — bibliography: `B.Code`, `B.Author.Last`, `B.Date`, `B.Journal`, `B.DOI`.
- **`Site.Out`**, **`Times.Out`** — location and time.
- **`Prod.Out` / `Plant.Out` / `Plant.Method`** — crop product, planting density and method.
- **`Var.Out`** — variety/breed: `V.Product` (crop *or* animal species), `V.Var` (variety/breed name),
  `V.Animal.Practice` (Improved Breeds / Hybridization / Unimproved Breed), `V.Type`, `V.Trait1`.
- **`Herd.Out`** (livestock, especially cc) — the animal bridge: `V.Product` (species), `V.Var`/`V.Var_Raw`
  (breed), **`Herd.N` (number of animals — the real n)**, `V.Animal.Practice`.
- **`Fert.Method`** — fertiliser per product: `F.Type`, `F.Amount`, `F.Unit`, nutrient rates
  `F.NI.est / F.PI.est / F.KI.est` (kg N/P/K per ha), `F.NP2O5K2O`, `F.Category`.
- **`Chems.Out`** — chemicals: `C.Type` (Herbicide/Insecticide/Fungicide/Other/vet types), `C.Name`,
  `C.Amount`, `C.Unit`, `C.Target`.
- **`Weed.Out`** (`W.Method`), **`Till.Out`**, **`Res.Method`** (residue fate), **`pH.Method`**, **`Irrig`**,
  **`Int.Out`** (`I.Practice` — intercrop), **`Rot.Out`** (`R.Practice` — rotation/sequence).
- **`AF.Out` / `AF.Trees`** — agroforestry flags (`AF.Boundary`, `AF.Silvopasture`, `AF.Multistrata` = "Yes"),
  `AF.Level.Name`, tree species.
- **`PO.Codes`** — postharvest/harvest codes (`f1`–`f5`, `h17`, `h21`, `h22`, `h30`); mainly in `mh`.
- **`Animals.Out` / `Animal.Diet`** — `D.Item` (feed item), `D.Item.Group`, `D.Source` (**on-farm vs
  purchased**), `D.Item.Is.Tree` (**fodder-tree flag**), `A.Diet.Trees`, `A.Diet.Other`, feed processing
  (`D.Process.Mech/Chem/Bio`), and (sc/mh only) `A.Feed.Add/Sub` categories.
- **`GM.Out` / `GM.Method`** — grazing (rotational/continuous, stocking rate). **`System.Out`** —
  production/housing system (`LS.Prod.Sys.Type`, `LS.Sp.Assoc`, `LS.House.Sys`).
- **`MT.Out`** — the **management/treatment linkage** table: one row per treatment arm with `T.Name`,
  **`T.Control`** (Yes/No — which arm is the control), and the level-name keys tying that arm to its herd,
  diet, fertiliser, pasture and grazing. **For cc especially, this is the spine that connects everything.**

## How Control vs Treatment is formed

ERA stores one mean per row. `T.Control` in `MT.Out` (and `ED.Comparison` / `Ratio.Control` in `Data.Out`)
mark which arm is the control. The pipeline pairs a control row with a treatment row for the same
experiment/outcome, then prefixes source columns with `C.` / `T.` — which is where the output's `C_…`/`T_…`
pairs come from. `T.Control` is populated on ~97% of livestock rows; ~86% of studies have a clear
control+treatment pairing.

## Per-snapshot quirks that WILL bite you

- **Planting:** `ie` uses `P.Prac.Prac` (a practice, often just Yes/No flags plus arrangement); `mh` uses
  `P.Method` (Transplanting, Direct Drilling, Dibble Stick — *methods*, not practices).
- **cc has no treatment key in `Data.Out`** — its rows link to diet/herd only through `MT.Out`. So per-row
  species can be missing even when `Herd.Out` has it; use `MT.Out` or a study-level fallback.
- **cc has no standardized practice names for diet** — `ED.Comparison` is mostly blank or raw codes
  ("TRUE", "T1", "300CFM"). Classify livestock by ingredient content (`D.Source`, `D.Item.Is.Tree`), not by
  labels.
- **Variance is sparse and typed.** Only ~30% of source rows carry `ED.Error`; crop snapshots are worst
  (mh ~15%). Types mix SE / SD / CV / Grouped SEM/SED/SD — **not interchangeable**. → `04_era_open_issues.md`
- **Livestock sample size** used to read as 1 because the real animal count sat in the "head" plot-size
  column; corrected via `Herd.N` plus manual overrides. → `03_era_changelog.md` v22
- **Sub-study IDs.** One paper is sometimes split into `X.1`, `X.2`, … (different experiments or sites).
  Same `B.Code` base plus same DOI = one publication.
- **Sentinels and junk in source text:** `999999`, literal `"NA"`, non-breaking spaces, stray separators.
  The pipeline cleans these. → `01_era_harmonization.md`
