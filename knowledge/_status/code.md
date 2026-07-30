# Status — code state

**Owner: Andrea** (these are her scripts). Read via `../01_status.md`. Figures verified **2026-07-30**.

What the code *does* is documented in `../08_effect_sizes_and_analysis.md` Part A. This file is only the
counts and the what-runs-what-doesn't.

## `02.FOMD/04.metadata_effectsize/` — two independent branches, not one chain

- **ERA branch (live):** `added_to_10_MD_Rosen_24_Effec_Sc_new.R` (~2,140 lines) → `03.fomd10_clean.R`
  (431 lines) → `04.fomd10_effect_size.R` (267 lines). Outputs are large: `fomd10_clean_*.csv` ~552 MB,
  `fomd10_effect_size.csv` ~676 MB.
- **Manual-extraction branch:** `01.fomd09_clean.R` (770) → `02.fomd10.R` (686) → `fomd10_comparison.csv`.
  **Nothing currently reads that output.**
- `fomd_fun/`: 12 helper files, ~1,985 lines.
- `fomd10/fomd10_MD_Rosen_24_Effec_Sc.csv` is currently **0 bytes** (needs regenerating), and there is a
  ~380 MB file literally named `9B8AA000` in that folder — an interrupted-write artefact.

## `02.FOMD/05.meta_analysis/`

- `1.data_distribution.R` (200 lines) and `2.comparison_2_3_levels.R` (227 lines) are implemented.
- **`3.sensitivity_analysis.R`, `4.meta_analysis.R`, `5.meta_regression.R` are 0 bytes — empty stubs.**
- `idrc-cfra_analysis/` is the live deliverable: `cfra_analysis.R` (1,040) + `cfra_plots.R` (1,605),
  filtered to Ethiopia / Kenya / Zambia.
- `fun_effect_sizes.R` (282 lines) is a draft — **not sourced by any pipeline script**.

**Verified 2026-07-30:** `04.fomd10_effect_size.R` **does** produce `effect_size_yi` (line 185) as well as
`effect_size_vi` (line 191). Any claim that it produces only `vi` is stale.
