2026-09-28 — **Bug found (not fixed) in the lnRR effect sizes: missing-SD imputation and bias correction** —
no docs edited yet; to be filed in `08_effect_sizes_and_analysis.md` Part A (code facts) and the ERA
`04_era_open_issues.md` (data limitation) by the code owner.

**Where:** `02.FOMD/04.metadata_effectsize/fomd_fun/fun_cv_missing_calculation.R`, `n_cv_calculation()`, used by
both `04.fomd10_effect_size.R` and `04.fomd10_effect_size_era.R`. Found while checking the CFRA Kenya subset
(`fomd10_cfra_ken.csv`).

1. **The group-average CV is broken by outliers.** Step 2 takes an n-weighted *arithmetic* mean of
   `T_out_sd / T_out_mean` over rows with a reported SD. Rows whose mean is zero, near zero or negative get
   absurd CVs and dominate the average. Example: CJ0014 (maize), `T_out_mean` = 0.0001, SD 0.79 → CV ≈ 7,900,
   weight n = 18. Result for the Maize/Maize/Crop Yield group: `T_out_cv_group_avg` ≈ 20.8 (2,081 %), while
   `C_out_cv_group_avg` ≈ 0.52. Every maize row without a reported SD then receives CV_T = 20.8.
2. **The bias-correction sign is reversed.** The code (and the header comment) uses
   `log(T/C) + 0.5*(cv_C^2/n_C − cv_T^2/n_T)`. Lajeunesse (2015) / Nakagawa et al. (2023) use
   `log(T/C) + 0.5*(cv_T^2/n_T − cv_C^2/n_C)`.
3. **Combined effect**, e.g. AG0028 Ogendo 2018 (maize, Nakuru): C 5.27, T 7.21 → ln(T/C) = +0.31; stored
   `out_effect_size_yi` = −71.8. The variance (`lnRR_var_cv_final`) is inflated the same way.
4. Zero/negative means reach the lnRR step (the note "replace 0 by 0.00001" in the script); lnRR is undefined
   for them.
5. `04.fomd10_effect_size.R` does not run top to bottom: dangling pipes after `fun_calculate_ler(...)` and
   after the `x <- ... filter(...)` check. The `escalc()` lnRR uses the reported sample sizes, while the CV
   branch uses the imputed ones.

**Suggested fix (for Andrea to decide — method is hers):** exclude rows with mean ≤ 0 from CV averaging and
from lnRR; use a robust group CV (median, or Nakagawa's pooled CV² from rows passing Geary's test); correct
the sign; re-run and compare against plain ln(T/C).
