# Review: `added_to_10_MD_Rosen_24_Effec_Sc_new.R`

Script reviewed: `02.FOMD/01.metadata_harmonisation/02.metadata/04.added_to_06_FOMD_metadata_original_long/added_to_10_MD_Rosen_24_Effec_Sc_new.R` (2,182 lines).

`path.metadata.effectsize` is defined at line 13 of this script:
```
path.metadata.effectsize<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/04.metadata_effectsize"
```
The script writes its main output at line 2174 to `path.metadata.effectsize/fomd10/fomd10_MD_Rosen_24_Effec_Sc.csv`, which resolves to:
```
C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/04.metadata_effectsize/fomd10/fomd10_MD_Rosen_24_Effec_Sc.csv
```
That file is ~380 MB, 242,247 data rows, 290 columns.

**Methodology note / limitation:** a direct statistical pass over the live 380 MB output file (NA counts, duplicate detection, numeric range checks) was attempted but not run in this session. The findings below on the generated file are therefore based on (a) static review of the script's logic and (b) the script's own embedded diagnostic comments — several of which record actual counts from the author's own prior runs, labeled by which ERA input version produced them (`v6`/`v24`/`v32`/`v41`). Where a cited count is not explicitly labeled `v41` (the version this script currently reads, set at line 53), that is called out — it means the number is from an earlier run and has not been independently reconfirmed against the current output in this review.

---

## 1. Data quality

### 1.1 Crop/tree names not matching the ontology lookup — confirmed by the script's own v41 run
- **Example:** three separate diagnostic blocks build the set of crop/tree names appearing in `C_crop_tree_diversity`/`T_crop_tree_diversity` (and the `_variety`, `_density` variants), left-join them against `fomd01.crops.trees` (built in `fomd_fun/fun_lookup_commodities.R` from the `01_FOMD_ontologies.xlsx` sheets), and count how many have no match (`FAO.Food.Group` is `NA`).
- **Line numbers:** counts printed at lines 449, 464, 477:
  ```
  449: length(unique(unique_crops_diversity$crop_tree_diversity)) #70-v41: 30
  464: length(unique(unique_crops_variety$crop_tree_diversity))#v41: 40
  477: length(unique(unique_crops_density$crop_tree_diversity)) #v41: 23
  ```
- **Reading:** for the current `v41` input, 30 distinct tokens from the diversity columns, 40 from the variety columns, and 23 from the density columns don't match any name in the crop/tree ontology (some overlap between the three lists is likely, but they're extracted independently and not deduplicated against each other in the script). These are the author's own documented numbers for the exact input this script currently runs on, not a stale prior-version count.
- **Compounding issue:** the diversity-mismatch report is never written out for review — line 450 (`#readr::write_csv(unique_crops_diversity, ...)`) is commented out, so these 30 unmatched names aren't surfaced anywhere outside the console.

### 1.2 The country-mismatch quick-check is broken / inert
- **Example:**
  ```r
  2062: unique_countries <-data.frame(
  2063:   country = md.era.short.clean %>%
  ...
  2070:   left_join(fomd01.countries%>%
  2071:               filter(!is.na(Country))%>%
  2072:               distinct(Country,ISO_3166_1_Alpha_3),
  2073:             by=c("country"="Country"))
  2074:   #filter(is.na(Product.Type))
  ```
- **Line numbers:** 2062–2074.
- **Issue:** the intended "flag countries with no ISO match" filter on line 2074 references `Product.Type` — a column name from the *crop* lookup, not a column that exists on `unique_countries` (which only has `country` and `ISO_3166_1_Alpha_3`). It's also commented out. This looks like a copy-paste of the crop-mismatch block (section 1.1) that was never adapted, so as written, `unique_countries` is built but the actual mismatch filter never executes — country-name mismatches against the ontology are not currently being surfaced by this diagnostic at all, unlike the crop-name equivalent in 1.1.

### 1.3 Column-drop step at the end silently NA-fills columns — contradicts an earlier `rename()` in the same script
- **Example:**
  ```r
  2137: fomd10.names <- unique(names(fomd10))
  2138: fomd10.names<-c(fomd10.names,"practice_compared","practice_compared_detail", "practice_compared_n")
  ...
  2144: missing_cols <- setdiff(fomd10.names, names(md.era.short.clean))
  2145: missing_cols
  2146: #[1] "C_fert_inorganic_type_amount_unit" "T_fert_inorganic_type_amount_unit" "C_chem_name_amount_unit"
  2147: #[4] "T_chem_name_amount_unit"
  2150: md.era.clean <- md.era.short.clean
  2153: for (col in missing_cols) {
  2154:   md.era.clean[[col]] <- NA
  2155: }
  2158: md.era.clean <- md.era.clean[, fomd10.names, drop = FALSE]
  ```
- **Line numbers:** 2137–2158, contradicted by 964–966 and 1277–1279.
- **Issue:** the printed `missing_cols` result (recorded as a comment at lines 2146–2147, from a previous run) lists exactly the four columns that earlier in *this same script* are explicitly created via `rename()`:
  ```r
  964: md.era.short.clean <- md.era.short.clean%>%
  965:   rename("C_fert_inorganic_type_amount_unit"="C_fert_inorganic_combined",
  966:          "T_fert_inorganic_type_amount_unit"="T_fert_inorganic_combined")
  ```
  ```r
  1277: md.era.short.clean <- md.era.short.clean%>%
  1278:   rename("C_chem_name_amount_unit"="C_chem_combined",
  1279:          "T_chem_name_amount_unit"="T_chem_combined")
  ```
  If the recorded `missing_cols` comment is still accurate, then something between lines ~1279 and 2144 is dropping these four columns again before the final `md.era.clean[, fomd10.names]` selection, and every one of the 242,247 output rows gets a plain `NA` (line 2154) for all four columns instead of the real values computed earlier — a silent, full-column data loss. If instead the comment is stale (left over from a run predating the two `rename()` calls above), it's misleading anyone reading the script now into thinking these columns are still missing. Either way this is worth a live re-check (`setdiff(fomd10.names, names(md.era.short.clean))` re-run against the current code) before trusting these four columns in the output file.

### 1.4 Organic-fertilizer "type_amount_unit" column doesn't actually combine type + amount + unit
- **Example:**
  ```r
  1076: # Combine fertilizer type + amount + unit separated by ".."
  1077: #md.era.short.clean <- md.era.short.clean%>%
  1078:  # mutate(C_fert_organic_amount_unit1= combine_amount_unit(amount = C_fert_organic_amount, unit   = C_fert_organic_unit),
  1079:   #        T_fert_organic_amount_unit1= combine_amount_unit(amount = T_fert_organic_amount, unit   = T_fert_organic_unit))%>%
  1080: #  mutate(C_fert_organic_type_amount_unit= mapply(combine_type_amount_unit,C_fert_organic_type,C_fert_organic_amount_unit1),
  1081:  #        T_fert_organic_type_amount_unit= mapply(combine_type_amount_unit,T_fert_organic_type,T_fert_organic_amount_unit1)
  1082:   #)
  ...
  1095: md.era.short.clean <- md.era.short.clean%>%
  1096:   rename("C_fert_organic_type_amount_unit"="C_fert_organic_combined",
  1097:          "T_fert_organic_type_amount_unit"="T_fert_organic_combined")
  ```
- **Line numbers:** 1076–1097.
- **Issue:** the block that would actually build `type[amount(unit)]` strings for organic fertilizer (mirroring what's done for inorganic fertilizer at lines 950–962) is commented out. What ends up in the final `C_fert_organic_type_amount_unit`/`T_fert_organic_type_amount_unit` columns is just a rename of whatever `C_fert_organic_combined`/`T_fert_organic_combined` already held from the ERA import — the column name promises a "type + amount + unit" combination, but for organic fertilizer that combination is never actually computed in this script, unlike its inorganic counterpart.

### 1.5 Self-patched replacement collisions indicate the `gsub`-chain approach is fragile
- **Example:**
  ```r
  1261: "Unspecified"= "Unspecified (if pesticide org or inorg was applied)",
  1262: "Mechanical"= "Mechanical (Unspecified)",
  1263: "Mechanical (Unspecified) (Unspecified (if pesticide org or inorg was applied))"="Mechanical (Unspecified)",
  1264: "Hand Weeding (Unspecified (if pesticide org or inorg was applied))"="Hand Weeding (Unspecified)"
  ```
- **Line numbers:** 1248–1274 (block), collision-patches at 1263–1264.
- **Issue:** lines 1263–1264 exist only to undo a compounding artifact that the two replacements directly above them (1261–1262) already produced once, because they're applied in sequence over the same string (`"Unspecified"` inside `"Mechanical (Unspecified)"` gets re-matched by the next rule). This confirms the pattern-by-pattern `gsub` chaining approach used throughout the script (86 total `apply_replace_in_cols()` calls — see §2.4) is order-sensitive and has already produced at least one wrong value that had to be manually patched; it's plausible similar compounding artifacts exist elsewhere in the ~86-call chain without a corresponding patch yet written.

### 1.6 Columns the author has explicitly flagged as wrong or missing, still unresolved
- **`C_postharvest_subpractice` / `T_postharvest_subpractice`** — line 1808: `## TO CHECK: C_postharvest_subpractice and T_postharvest_subpractice LOOK LIKE RAW VARIABLES`; line 1819–1820: `sort(unique(...)) # THE VALUES LOOK WRONG`. No cleaning step is applied to these two columns anywhere in the script (contrast with every other subpractice column, which gets `apply_replace_in_cols()` treatment) — they pass through as raw ERA values into the final output.
- **Post-harvest timing fields entirely absent** — lines 1825–1832 mark six columns as `#MISSING`: `C_postharvest_date_start`, `T_postharvest_date_start`, `C_postharvest_date_end`, `T_postharvest_date_end`, `C_postharvest_days_after_storage`, `T_postharvest_days_after_storage`.
- **`bio_func_group` / `bio_ground_ref`** — line 1898–1899: `#TO FIX from ERA need to complete manually for the included papers`, i.e. known-incomplete fields the author has not yet manually filled in.

### 1.7 Documented (but not-yet-v41-reconfirmed) high null-rates on outcome-variance fields
These are the author's own `nrow()`/`na_empty_summary1` checks; the most recent number quoted in each comment is labeled `v32`, one ERA-version prior to the `v41` file this script currently reads (line 53) — i.e. plausible current values, not confirmed for `v41`:
- Lines 1965–1966: `C_out_var_metric`/`T_out_var_metric` empty for ~183,067 / ~182,996 of the (then) ~232k rows — roughly 3 out of 4 rows have no stated variance-metric type.
- Lines 1971/1973: `C_out_var_value`/`T_out_var_value` empty for a similar ~183k/~183k rows.
- Line 1979 vs. lines 1965–1971: line 1979 reports 0 rows (v32) with a variance *value* present but no variance *metric* type (would be uninterpretable), while lines 1965 and 1971 report *different* NA counts for what should be closely related fields, checked a few lines apart in the same script — worth reconciling in R directly rather than assumed consistent.
- Lines 1992/1998: `C_out_sample_size` reported as missing for 12,722 rows at line 1992 and 49,183 rows at line 1998, a few lines apart, apparently checking the same underlying condition (`is.na(C_out_sample_size)`) against what should be the same data — this discrepancy is not explained in the script and should be re-verified live rather than treated as reconciled.

### 1.8 No integrity/uniqueness check before writing output
- **Observation:** the script writes three files (lines 2169, 2174, 2180) but at no point calls `duplicated()`, `distinct()`, `stopifnot()`, or any equivalent on `study_id`/`effect_size_id`/the C-vs-T comparison key before writing. `effect_size_id` is inherited directly from the ERA import (referenced from line 56 onward) rather than freshly constructed and de-duplicated by this script. Whether duplicate `effect_size_id`s or duplicate C-vs-T comparisons exist in the 242,247-row output was not independently verified in this review (see methodology note above) and would need a live pass over the file to confirm.

---

## 2. Efficiency

### 2.1 Seven near-identical `sapply()` passes over the same column, each re-deriving the same token count
- **Example:**
  ```r
  159: mutate(site_type = case_when(
  160:   site_type == "" ~ sapply(site_id, function(x) {
  161:     n <- length(stringr::str_split(x, fixed(".."))[[1]])
  162:     paste(rep("Unspecified", n), collapse = "..")
  163:   }),
  164:   TRUE ~ site_type))%>%
  ```
  ...repeated with only the fill string changed for `site_agg` (167), `site_admin` (174), `site_latlong_type` (181), `site_latitude` (188), `site_longitude` (195), `site_buffer` (202).
- **Line numbers:** 158–210 (the seven blocks span this range; individual `sapply(` calls at 160, 167, 174, 181, 188, 195, 202).
- **Impact:** each `sapply(site_id, ...)` iterates all ~242,247 rows of `site_id`, so this pattern runs the *same* `str_split(x, fixed(".."))` + count logic independently ~1.7M times total (7 × 242,247) to answer one question per row ("how many `..`-separated tokens does this `site_id` have?"). That count could be computed once — e.g. `n_tokens <- lengths(strsplit(site_id, "..", fixed = TRUE))`, fully vectorized — and reused across all seven `mutate()`s, cutting this section from 7 row-by-row passes to 1 vectorized pass plus 7 cheap `strrep`/`paste` fills.

### 2.2 Explicit `rowwise()` over the full 242k-row table to build `site_key`
- **Example:**
  ```r
  229: md.era.short.clean <- md.era.short.clean %>%
  230:   mutate(site_buffer = gsub("\\bNA\\b", "Unspecified", site_buffer))%>%
  231:   rowwise() %>%
  232:   mutate(
  233:     site_key = {
  234:       lat  <- strsplit(as.character(site_latitude),  "\\.\\.")[[1]]
  235:       long <- strsplit(as.character(site_longitude), "\\.\\.")[[1]]
  236:       b    <- strsplit(as.character(site_buffer),    "\\.\\.")[[1]]
  ...
  245:       vals <- mapply(function(la, lo, bu) { ... }, lat, long, b)
  254:       paste0(na.omit(vals), collapse = "..")
  257:   }) %>%
  257:   ungroup()
  ```
- **Line numbers:** 229–257.
- **Impact:** `rowwise()` turns the tibble into one group per row (~242,247 groups) for the duration of this `mutate()`; each group does 3 `strsplit()` calls plus a `mapply()` plus a `paste0()`. This is the classic "row-wise operation that could be columnar" pattern the review was asked to flag — dplyr's rowwise grouping overhead alone (not just the string work inside) is non-trivial at this row count. A `purrr::pmap_chr()` over the three columns (still technically row-by-row, but without the rowwise-tibble grouping overhead) or a fully vectorized padding-and-paste approach would avoid re-grouping the whole table into single-row groups.

### 2.3 The same ontology file is loaded from disk twice
- **Example:**
  ```r
  25: source(file.path(path.functions,"/fun_lookup_ontologies.R"))
  26: source(file.path(path.functions,"/fun_load_data_ontologies.R"))
  27: source(file.path(path.functions,"/fun_cleaning.R"))
  28: source(file.path(path.functions,"/fun_cleaning_09_FOMD.R"))
  29: source(file.path(path.functions,"/fun_lookup_commodities.R"))
  ```
  and, inside `fomd_fun/fun_lookup_commodities.R` (lines 4–8):
  ```r
  local({
    source(file.path(path.metadata.effectsize, "/fomd_fun/fun_load_data_ontologies.R"),
           local = environment())
    ...
  ```
- **Line numbers:** 25–29 in this script; the redundant inner `source()` is in `fomd_fun/fun_lookup_commodities.R` lines 7–8, triggered by line 29 here.
- **Impact:** line 26 already loads all seven `01_FOMD_ontologies.xlsx` sheets (`fomd01.countries`, `fomd01.sites`, `fomd01.trees`, `fomd01.product.new`, `fomd01.vars.crops`, `fomd01.outcomes`, `fomd01.practices`) into the global environment. `fun_lookup_commodities.R`, sourced three lines later at line 29, re-sources the exact same file internally just to rebuild `fomd01.crops.trees` from three of those tables — meaning the xlsx file gets opened and every sheet re-parsed by `readxl::read_xlsx()` a second time, unconditionally, on every run, for no result that isn't already sitting in the environment from line 26.

### 2.4 86 sequential single-pattern column replacements instead of one multi-pattern pass per column set
- **Example (representative of the pattern, repeated with different single patterns throughout the script):**
  ```r
  1050: md.era.short.clean <- apply_replace_in_cols(
  1051:   md.era.short.clean,
  1052:   cols = c("C_fert_organic_category", "T_fert_organic_category", ...),
  1058:   pattern = "; ",replacement = "..")
  1061: md.era.short.clean <- apply_replace_in_cols(
  1062:   md.era.short.clean,
  1063:   cols = c("C_fert_organicN", "T_fert_organicN", ...),
  1066:   pattern = "...",replacement = "..")
  1069: md.era.short.clean <- apply_replace_in_cols(
  ...
  1074:   pattern = "999999",replacement = "Unspecified")
  ```
  and the two places the script itself groups patterns into a named vector but still loops one-`gsub`-call-at-a-time:
  ```r
  1267: for (pat in names(replacements)) {
  1268:   md.era.short.clean <- apply_replace_in_cols(
  1269:     md.era.short.clean,
  1270:     cols        = c("C_chem_subpractice", "T_chem_subpractice"),
  1271:     pattern     = pat,
  1272:     replacement = replacements[[pat]]
  1273:   )
  1274: }
  ```
  (same shape again at line 1355, over `C_residues_subpractice`/`T_residues_subpractice`).
- **Line numbers:** 86 total call sites across the script (`grep -c "apply_replace_in_cols("` = 86); the two `for`-loop instances are at 1267–1274 and 1355–1362.
- **Impact:** `apply_replace_in_cols()` (`fomd_fun/fun_cleaning.R`) does `df[cols] <- lapply(df[cols], \(x) gsub(pattern, replacement, x, fixed = fixed))` — a full `gsub` scan of every targeted column, all ~242,247 rows, per call. With 86 call sites, several column sets (e.g. the inorganic-fertilizer columns, the residues columns) get 5–10 of these back-to-back on the *same* columns. Each of the two `for`-loops alone turns what could be a single `stringr::str_replace_all(x, replacements)` vectorized multi-pattern call into 14 separate full-column passes. Consolidating same-column-set replacements into one multi-pattern call would cut the number of full-table string scans roughly 5–10× in the heaviest sections.

### 2.5 Diagnostic mismatch check rebuilds row-by-row objects instead of a vectorized comparison
- **Example:**
  ```r
  991: ## Code to check mismatches for any amount/unit pair: This is ready, nothing to check
  992: mismatch_report <- do.call(rbind, lapply(inorganicNPK_fert_pairs, function(p)
  993:   check_length_mismatch_amount_unit(md.era.short.clean, p[1], p[2])))
  994: View(mismatch_report)
  ```
  `check_length_mismatch_amount_unit()` (`fomd_fun/fun_cleaning_09_FOMD.R`) does:
  ```r
  mismatches <- mapply(function(a, u, i, doi, study_id) {
    ...
    if (na != nu) data.frame(row = i, doi=doi, study_id=study_id, ...)
  }, amt, unt, seq_along(amt), df$doi, df$study_id, SIMPLIFY = FALSE)
  do.call(rbind, Filter(Negate(is.null), mismatches))
  ```
- **Line numbers:** 992–994 (call site in this script); `inorganicNPK_fert_pairs` has 10 pairs (defined at lines 407–419).
- **Impact:** for each of the 10 fertilizer amount/unit pairs, `mapply()` iterates all ~242,247 rows, constructing either `NULL` or a fresh one-row `data.frame` per row (so up to ~2.4M row-level object constructions total across the 10 pairs), before `rbind`-ing the non-null ones together. A vectorized length comparison (e.g. counting `..`-separated tokens per column with `lengths(strsplit(...))` and comparing the two integer vectors directly, only materializing rows where they differ) would avoid building ~2.4M small R objects just to throw most of them away as `NULL`.

### 2.6 Per-row character-by-character parsing runs even on empty/short strings
- **Example (call site in this script):**
  ```r
  416: C_crop_tree_density=mapply(create_density_crop,C_crop_tree_diversity,C_crop_tree_density),
  417: T_crop_tree_density=mapply(create_density_crop,T_crop_tree_diversity,T_crop_tree_density)
  ```
  `create_density_crop()` (`fomd_fun/fun_cleaning_09_FOMD.R`) contains its own nested helpers that loop character-by-character to respect parenthesis nesting:
  ```r
  split_outside_parens <- function(x, delimiters = c("/", "-")) {
    ...
    chars <- strsplit(x, "")[[1]]
    depth <- 0
    for (i in seq_along(chars)) { ... }
  }
  ```
- **Line numbers:** 416–417 (call site in this script).
- **Impact:** for both `C_` and `T_` columns, every one of the ~242,247 rows triggers a function call that, internally, `strsplit`s the string into individual characters and loops over them twice (once in `split_outside_parens`, once in `get_seps_outside_parens`) to track parenthesis depth — effectively an O(row count × string length) nested loop running row-by-row via `mapply` rather than any vectorized approach, and it runs unconditionally even for rows where `diversity`/`density` are empty (the emptiness check happens inside the function, after the call and argument-matching overhead have already been paid for all ~484,000 calls across both columns).

---

## Summary of line references
| # | Area | Lines |
|---|------|-------|
| 1.1 | Crop/tree ontology mismatches (documented) | 449, 464, 477 (report not written: 450) |
| 1.2 | Broken country-mismatch check | 2062–2074 |
| 1.3 | `missing_cols` contradicts earlier `rename()` | 2137–2158 vs. 964–966, 1277–1279 |
| 1.4 | Organic fert. "type_amount_unit" not actually combined | 1076–1097 |
| 1.5 | Self-patched replacement collision | 1248–1274 |
| 1.6 | Author-flagged wrong/missing columns | 1808, 1819–1820, 1825–1832, 1898–1899 |
| 1.7 | High null-rate / inconsistent NA counts (v32-labeled) | 1965–1966, 1971, 1973, 1979, 1992, 1998 |
| 1.8 | No dedup/integrity check before write | 2169, 2174, 2180 |
| 2.1 | 7× redundant `sapply` over `site_id` | 158–210 |
| 2.2 | `rowwise()` over 242k rows for `site_key` | 229–257 |
| 2.3 | Ontology xlsx loaded twice | 25–29 (+ `fun_lookup_commodities.R` 7–8) |
| 2.4 | 86 sequential single-pattern replacements | script-wide; loops at 1267–1274, 1355–1362 |
| 2.5 | Row-by-row mismatch-report construction | 992–994 |
| 2.6 | Per-row char-by-char density parsing | 416–417 |
