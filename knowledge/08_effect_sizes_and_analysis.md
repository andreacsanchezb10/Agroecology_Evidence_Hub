# 08 — Effect sizes and analysis

Covers `02.FOMD/04.metadata_effectsize/` and `02.FOMD/05.meta_analysis/`. Line counts and file sizes:
`01_status.md`.

Two parts, and the distinction matters:
- **Part A** describes **what the code currently does** — observed in the files, not prescribed.
- **Part B** is the **house method**, which is Andrea's to define. It is deliberately unwritten.

---

# Part A — What the code does today

Andrea owns these scripts. Document them, don't edit them. Everything here is traceable to a file.

## Two independent branches, not one chain

```
BRANCH A — manual extraction                    BRANCH B — ERA  (the live path)
  09_FOMD_metadata_extraction_long.xlsx           ERA_data_short_vNN.csv
            │                                              │  added_to_10_MD_Rosen_24_Effec_Sc_new.R
            │  01.fomd09_clean.R                           ▼
            ▼                                       fomd10/fomd10_MD_Rosen_24_Effec_Sc.csv
     fomd09_cleanv2.csv                                    │  03.fomd10_clean.R
            │  02.fomd10.R                                 ▼
            ▼                                       fomd10_clean/…csv
     fomd10_comparison.csv                                 │  04.fomd10_effect_size.R
            ✗ nothing currently reads this                 ▼
                                                    fomd10_effect_size.csv
                                                           │
                                                           ▼  05.meta_analysis/
                                                    models + idrc-cfra_analysis/
```

Both branches converge conceptually on the `10_` schema, but only Branch B currently reaches the analysis
scripts. Branch A's output has **no consumer** — it is work in progress, not necessarily abandoned.

Note that Branch B's first step is **Andrea's** ingestion script, not Lolita's `era_harmonize.R`. The two
meet at the `10_` schema, and there is a version lag between them. → `sources/ERA/02_era_handoff.md`

## `04.metadata_effectsize/` — the scripts

| Script | Reads | Writes | Does |
|---|---|---|---|
| `01.fomd09_clean.R` | the ontology sheets; `04_FOMD_screening` (non-ERA, `status == "I"`); `09_` master; `10_` **for its column names** | `fomd09_cleanv2.csv` | Excel-serial date coercion (`origin = "1899-12-30"`), collapses repeated slots, and defines its **own inline** SD-conversion helpers per product component — `SE_SD`, `M_IQR_SD`, `CI_SD` (Higgins & Green 2011 / Hozo et al. 2005), separate from `fomd_fun/`'s set |
| `02.fomd10.R` | `fomd09_cleanv2.csv`; `01_outcomes` | `fomd10_comparison.csv` | Reshapes long → C-vs-T wide by outcome domain; builds biodiversity / yield / economic subsets |
| `03.fomd10_clean.R` | `fomd10/fomd10_MD_Rosen_24_Effec_Sc.csv` | `fomd10_clean/…csv` | C/T subpractice → practice → theme resolution and renaming; practice-domain reclassification; crop/tree → FAO Food Group lookup for both arms; the **commodity-group intersection** (groups common to C and T); attaches **`effect_size_type`** from `01_outcomes` |
| `04.fomd10_effect_size.R` | `fomd10_clean/…csv` | `fomd10_effect_size.csv`; an Ethiopia subset; the field dictionary; a practices-ontology export | mean/SD calculation → CV handling → **lnRR** → **SMD** → assembles the final columns |

`04.` carries the header comment *"THIS IS TEMPORARY, JUST FOR THE CFRA ANALYSIS"* — treat its output as
deliverable-driven, not as a settled pipeline.

**Verified 2026-07-30:** `04.` produces **both** `effect_size_yi` (line 185) and `effect_size_vi` (line 191).
Older documentation claiming it produces only `vi` is stale.

## Methods present in the code

**Effect sizes** — thin `metafor::escalc()` wrappers in `fomd_fun/fun_effect_sizes_calculation.R`
(`vtype = "LS"`):
- **lnRR / Log Response Ratio** — `escalc(measure = "ROM")` → `lnRR`, `lnRR_var`
- **SMD / Standardized Mean Difference** — `escalc(measure = "SMD")` → `SMD`, `SMD_var`
- Which one applies per outcome comes from `01_outcomes$effect_size_type`.
- Final selection: `effect_size_yi` takes the CV-corrected lnRR where available, else plain lnRR, else SMD.
- **Log Partial LER** and **Log Total LER** appear as types in the data but are computed only in
  `fun_effect_sizes.R`, which **no pipeline script sources**. The intercropping/agroforestry-vs-monoculture
  logic that assigns them also lives only there.

**Variance metric → SD** (`fun_mean_sd_calculation.R`), handling 10 metrics:
| From | Conversion |
|---|---|
| `SD`, `Grouped SD` | used directly |
| `SE`, `Grouped SE`, `SEM`, `Grouped SEM` | `SD = SE · √n` (Cochrane Handbook §6.5.2.2) |
| `SED` | `SD = SED · √(n/2)` |
| `CV` | `SD = (CV/100) · mean` |
| `MSE` | `SD = √MSE` (Hedges et al. 1999) |
| `Unspecified` | → NA |

**Missing-SD handling** (`fun_cv_missing_calculation.R`) — the **Nakagawa et al. 2023** (Ecology Letters,
Table 1) CV-substitution estimator, used because a large majority of rows lack a reported SD:
`lnRR = log(m1/m2) + 0.5·(cv2²/n2 − cv1²/n1)`, with a matching variance expression. Missing sample sizes are
imputed with **`mice`** (predictive mean matching). Currently one grouping rule is active — yield/return
outcomes grouped by `C_product_simple`, `T_product_simple`, `out_subindicator`; soil-carbon and WUE rules are
commented out.

**Models** (`05.meta_analysis/2.comparison_2_3_levels.R`) — **`metafor::rma.mv()`**, `method = "REML"`,
`test = "t"`, `dfs = "contain"`, random effects `~1|comparison_id` and `~1|study_id`. It selects between a
two-level and three-level model by AIC plus likelihood-ratio tests, iterating over
`out_subindicator × effect_size_type × practice_subtype`. No `lme4` anywhere — multilevel meta-analysis is
entirely metafor.

## `05.meta_analysis/` — state

- `1.data_distribution.R` — builds `T_C_<practice>_subpractice` contrast labels across the practice families
  by set-differencing the C and T parts. Implemented.
- `2.comparison_2_3_levels.R` — the model selection above. Implemented; writes `comparison_best_model.csv`.
- **`3.sensitivity_analysis.R`, `4.meta_analysis.R`, `5.meta_regression.R` — empty stubs (0 bytes).** The
  headline meta-analysis and meta-regression are not written yet.
- **`idrc-cfra_analysis/`** — the live deliverable. Filters to **Ethiopia / Kenya / Zambia**, drops
  animal outcomes, and produces descriptive aggregations, country plots and maps (GAEZ agro-ecological-zone
  rasters, FAO crop-classification crosswalks). No `rma`/`escalc` here — it is aggregation and mapping.

## `fomd_fun/` — the helper library

12 files. **There is no central "load all helpers" entry point** — each script `source()`s exactly the
helpers it needs at the top. If you add a helper, source it explicitly where it's used. Ontology loading and generic lookup (`fun_load_data_ontologies.R`, `fun_lookup_ontologies.R`);
commodity/FAO-group lookups and the C-vs-T intersection (`fun_lookup_commodities.R`); string cleaning
(`fun_cleaning.R`); domain cleaning for the `09_` tables — crop-name fixes, density construction,
amount+unit combining, agroforestry moves, length-mismatch diagnostics (`fun_cleaning_09_FOMD.R`);
C/T practice resolution and missing-practice diagnosis (`fun_comparison_practice.R`); analytical column
construction and filtering (`fun_analysis_practice.R`); the SD conversions
(`fun_mean_sd_calculation.R`); the CV substitution and `mice` imputation (`fun_cv_missing_calculation.R`);
the live `escalc` wrappers (`fun_effect_sizes_calculation.R`); and the unsourced draft
(`fun_effect_sizes.R`).

## Things that will trip you up

- **A missing-column error is usually the branch/version mismatch**, not a bug in your code. Check which
  CSV you're reading and which script produced it.
- The intermediate CSVs are **hundreds of megabytes**; one is currently 0 bytes and needs regenerating, and
  there is a large interrupted-write artefact in `fomd10/`. See `01_status.md`.
- These scripts hardcode **absolute OneDrive paths for one machine**, and Andrea's use a **different folder
  name** from Lolita's. That is deliberate for single-user scripts, not a defect to fix.
  → `09_conventions.md` §1

---

# Part B — The house method

> **Intentionally blank. Andrea owns this.**
>
> How to compute and choose effect sizes, what may be pooled with what, how to weight and cluster, how to
> handle missing variance, what to exclude — these are **Andrea's decisions**, not something to be inferred
> from the code above or written by an AI assistant. Part A says what the code *does*; it does not say what
> the method *should be*, and the two are not the same thing.
>
> **If you are Claude or another AI assistant:** do not fill this in. Do not reconstruct it from Part A. If a
> task needs a method decision that isn't documented, **ask** — and if Andrea answers, record her answer here
> attributed to her.
>
> **If you are Andrea:** this is your page. Anything you write here becomes the method everyone, including
> Claude, follows. Part A above is a factual map of your own scripts — correct or delete anything wrong in it.

## What belongs here when filled

- The mental model for using a `10_`-schema table.
- Which effect size applies to which outcome, and why.
- Rules for what may and may not be pooled together — units, outcomes, sources, regions.
- How to handle missing or unusable variance.
- De-duplication and clustering rules before pooling.
- Weighting, model structure, sensitivity and publication-bias approach.
- Reusable, version-stamped snippets worth keeping.

---

# Part C — Where the facts live meanwhile

Part B is about *method*. The *facts* it would build on are documented and safe to rely on:

| You need | Look in |
|---|---|
| What a column means | `05_data_schemas.md`, then the workbook's own `_readme` sheet |
| The controlled vocabulary, incl. `effect_size_type` per outcome | `06_ontologies.md` → `01_outcomes` |
| Which version of which table is current | `01_status.md` |
| **Known data limitations before any pooling** | **`sources/ERA/04_era_open_issues.md`** |
| Decisions already baked into the ERA data | `sources/ERA/01_era_harmonization.md` |
| What changed between ERA versions | `sources/ERA/03_era_changelog.md` |

`sources/ERA/04_era_open_issues.md` is the important one. It is the honest list of what the data cannot
currently support — missing variance, cross-snapshot double counting, unit heterogeneity, unresolved C/T
orientation. Read it before pooling anything.

## Related, exploratory — not method

An agroecology-gradient track exists: scoring each arm on a Gliessman-style agroecology level and defining
the control as the *lower-level* arm rather than trusting a source's C/T labels. Artifacts:
`ERA/Script/era_agroecology_beta.R`, its crosswalk, and HTML/CSV/docx outputs; plus
`presentations/Control_trt_decision_method_slides.pptx`. **Exploratory, not an agreed method** — recorded
here so it's findable, not so it's followed.
