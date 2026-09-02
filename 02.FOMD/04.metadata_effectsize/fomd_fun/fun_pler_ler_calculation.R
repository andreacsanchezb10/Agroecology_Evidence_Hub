#==========================================================
# Function: Calculate Total LER (value + SD) from paired Partial LER rows
#==========================================================
# Total LER = sum of Partial LERs for every crop in an intercrop system
# (e.g. Maize/Bean LER = pler_maize + pler_bean). This function:
#   1. Calculates each crop's Partial LER (pler_value_calc) and its
#      variance (pler_var_calc) from the paired T/C means, SD (via CV),
#      and sample sizes.
#   2. Sums those per-crop values within each ler_comparison_id group to
#      get the study's Total LER (ler_value_calc) and its SD (ler_sd_calc).
#   3. Falls back to the study's own DIRECTLY reported Total LER
#      (ler_value_total / ler_var_value_total) for studies that never
#      provided raw per-crop yields to calculate from.
#==========================================================
fun_calculate_ler <- function(dt) {
  
  # --- Defensive numeric conversion ---
  # These columns can arrive as character depending on which pairing branch
  # produced them (e.g. "Unspecified" text mixed into a raw-numeric column
  # upstream forces read_csv/bind_rows to guess character for the whole
  # column) — convert once here so the arithmetic below never fails on type.
  dt <- dt %>%
    mutate(
      T_out_mean                  = as.numeric(T_out_mean),
      C_out_mean                  = as.numeric(C_out_mean),
      T_out_cv_final               = as.numeric(T_out_cv_final),
      C_out_cv_final               = as.numeric(C_out_cv_final),
      T_out_sample_size_imputed    = as.numeric(T_out_sample_size_imputed),
      C_out_sample_size_imputed    = as.numeric(C_out_sample_size_imputed),
      ler_value_total               = as.numeric(ler_value_total),
      ler_var_value_total           = as.numeric(ler_var_value_total)
    )
  
  dt <- dt %>%
    mutate(
      
      # --- Partial LER per crop: Treatment mean (intercropping/agroforestry) / Control (monoculture) mean ---
      # Only for rows that belong to an LER comparison (ler_comparison_id not NA) Ratio",
      #which are studies that reported Total LER directly instead).
      pler_value_calc = case_when(
        !is.na(ler_comparison_id) & out_subindicator != "Land Equivalent Ratio" ~ T_out_mean / C_out_mean,
        TRUE ~ NA_real_
      ),
      
      # --- Variance of that ratio (delta method / propagation of error) ---
      # pler^2 * [ (CV_T^2 / n_T) + (CV_C^2 / n_C) ]
      # CV_final (SD/mean) is used instead of raw SD because CV_final is
      # already gap-filled by n_cv_calculation() for studies that didn't
      # report their own SD — using raw SD here would leave those rows NA.
      pler_var_calc = case_when(
        !is.na(ler_comparison_id) & out_subindicator != "Land Equivalent Ratio" ~
          pler_value_calc^2 * (
            (T_out_cv_final^2 / T_out_sample_size_imputed) +
              (C_out_cv_final^2 / C_out_sample_size_imputed)
          ),
        TRUE ~ NA_real_
      )
    ) %>%
    
    # --- Combine every crop's Partial LER into the study's Total LER ---
    # All rows sharing one ler_comparison_id belong to the same intercrop
    # comparison (one row per crop component).
    group_by(ler_comparison_id) %>%
    mutate(
      ler_calc_n_rows = if_else(is.na(ler_comparison_id), NA_integer_, n()),  # how many crop components contributed — useful for QA
      
      # Total LER = sum of Partial LERs. na.rm = TRUE skips rows with no
      # per-crop value (e.g. the "Land Equivalent Ratio"-tagged rows, which
      # get their value from the fallback step below instead).
      ler_value_calc = sum(pler_value_calc, na.rm = TRUE),
      
      # Variances of independent quantities ADD (not their SDs) — so the
      # Total LER's variance is the sum of each crop's own pler_var_calc,
      # and its SD is the square root of that sum.
      # Guard: if a crop DOES have a pler_value_calc but its OWN variance
      # is missing, we don't actually know the group's combined variance —
      # sum(..., na.rm = TRUE) would silently treat the missing one as
      # zero variance (understating the true uncertainty), so force NA
      # instead of a falsely-precise number.
      ler_sd_calc = if_else(
        any(!is.na(pler_value_calc) & is.na(pler_var_calc)),
        NA_real_,
        sqrt(sum(pler_var_calc, na.rm = TRUE))
      ),
      
      # which crops make up this LER comparison — every crop component's
      # own C_product_simple/T_product_simple across the group, deduped
      # and alphabetized, so the same string appears on every row of the
      # group regardless of row order
      ler_product = if_else(is.na(ler_comparison_id), NA_character_, paste(sort(unique(T_product_simple)), collapse = "..")),
      ) %>%
    ungroup() %>%
    
    mutate(
      # --- Fallback: studies with no raw per-crop data, only a directly
      # reported Total LER (out_subindicator == "Land Equivalent Ratio" rows,
      # excluded above so pler_value_calc is NA for them) ---
      ler_value_calc = case_when(
        is.na(pler_value_calc) & !is.na(ler_value_total) ~ ler_value_total,
        # rows with no LER comparison at all (e.g. Biodiversity/Economics) and
        # no reported Total LER either -> genuinely not applicable, keep NA
        is.na(ler_comparison_id) & is.na(ler_value_total) ~ NA_real_,
        TRUE ~ ler_value_calc
      ),
      
      # Same fallback for the SD. ler_var_value_total is a VARIANCE (matches
      # the "_var_value" naming convention used elsewhere), so sqrt() it to
      # stay on the same scale (SD) as ler_sd_calc.
      ler_sd_calc = case_when(
        is.na(pler_var_calc) & !is.na(ler_var_value_total) ~ sqrt(ler_var_value_total),
        # value reported but variance wasn't -> genuinely unknown, not zero
        is.na(pler_var_calc) & !is.na(ler_value_total) & is.na(ler_var_value_total) ~ NA_real_,
        is.na(ler_comparison_id) & is.na(ler_var_value_total) ~ NA_real_,
        TRUE ~ ler_sd_calc
      )
    )%>%
    
    mutate(
      # --- Effect size: log-transform the ratio, delta method for its variance ---
      # Var(log(X)) ≈ Var(X)/X^2 = (SD(X)/X)^2 — same relationship already
      # used for lnRR elsewhere in this pipeline (fun_cv_missing_calculation.R),
      # just applied directly since ler_value_calc/ler_sd_calc are already a
      # single combined ratio + its SD, not two raw groups escalc() could use.
      ler_effect_size_type = if_else(!is.na(ler_comparison_id), "Log LER", NA_character_),
      ler_effect_size_yi = if_else(!is.na(ler_comparison_id), log(ler_value_calc), NA_real_),
      ler_effect_size_vi = if_else(!is.na(ler_comparison_id), (ler_sd_calc / ler_value_calc)^2, NA_real_)
    )
  
  dt
}


