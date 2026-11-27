2026-11-26 — **Fifth pass on `01.fomd09_cleaning.R` (MD_Paut); variance with no metric and LER totals that
don't add up; nothing changed by Claude** — no knowledge doc changed. By Andrea, with Claude.

- Kour,_16's duplicated C1 (entry 04) has been fixed in the workbook.
- 57 rows have a variance value but `out_var_metric` = Unspecified (Biswa_22 rows 31–37, Sekam_03 rows 3–42,
  Verma_23 rows 3–12). `fun_mean_sd_calculation.R` maps Unspecified to SD = NA, so these variances are
  dropped downstream. Andrea checked the papers: Biswa_22 and Sekam_03 do not say which metric it is, so
  Unspecified (and SD = NA) is correct; Verma_23 does say it, so its `out_var_metric` should be filled.
- Partial LERs don't sum to the LER total in 3 rows: Gebru_15 row 4 (C2, sole maize, pLER 1 in two slots),
  Priya_23 rows 8–9 (T4 0.63 + 0.50 vs 0.99; T5 0.48 + 0.27 vs 0.96). Andrea fixed Gebru_15 the same day
  (row 4 now 0.5 + 0.5 = 1). Priya_23's values are what the paper reports, so the mismatch is in the source
  and the extraction is correct.
- Ngwir_12 reuses C3–C5 at two sites, which is fine because `fun_pairing_CT.R` joins on the site columns. The
  duplicated-practice_id check needs `site_id` in its grouping too.
