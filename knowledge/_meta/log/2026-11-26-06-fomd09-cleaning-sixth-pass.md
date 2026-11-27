2026-11-26 — **Sixth pass on `01.fomd09_cleaning.R` (MD_Paut); no new issues found** — no knowledge doc changed.
By Andrea, with Claude.

- Confirmed in the data: Verma_23's `out_var_metric` is now SEM (21 rows), and Gebru_15 row 4 now sums to its
  LER total. The duplicated-practice_id check (grouped by site and year) flags nothing.
- Checked with nothing found: SE/SEM/IQR rows missing the sample size or bounds, zero variances, % outcomes
  outside 0–100, LER/pLER out of range, variance above 3× the mean, values with no value metric.
- Nyawa_21 reports Mean with IQR (15 rows). Andrea checked the paper the same day: it does report mean and IQR,
  so the extraction is correct.
