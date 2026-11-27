2026-11-26 — **Fourth pass on `01.fomd09_cleaning.R` (MD_Paut); one more duplicated practice_id; nothing
changed by Claude** — no knowledge doc changed. By Andrea, with Claude.

- Alvar_16's duplicated C3/C4 (entry 03) has been fixed in the workbook: the unfertilised controls are now C5/C6.
- Kour,_16 uses C1 for both sole maize and sole rajmash in every outcome and year (Excel rows 4, 8, 12, 16,
  20, 24 are the rajmash rows), so T1/T2 point to an ambiguous C1 within the same sub-indicator.
- The corrected `fix_num_text()` is in the script: 0 cells in scientific notation on today's data.
- The duplicated-practice_id check needs `out_year` and `out_year_start` in its grouping. Without them it
  flags Bhard_21 and Ngwir_12, which are the same treatment in different years.
