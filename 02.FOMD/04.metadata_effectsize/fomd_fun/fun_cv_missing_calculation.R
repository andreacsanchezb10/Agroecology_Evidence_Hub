library(dplyr)
library(mice) 

# ------------------------------------------------------------------------
# Goal: some studies don't report a standard deviation (SD). We can't
# compute their precision without one. The fix (Nakagawa et al. 2023,
# Ecology Letters) is to calculate an average CV (= SD / mean) from the
# studies that DO have an SD, and use that average to fill the gap.
#
# Equations used (Nakagawa et al. 2023, Table 1):
#   lnRR = log(m1/m2) + 0.5 * (cv2^2/n2 - cv1^2/n1)
#   var  = cv1^2/n1 + cv2^2/n2 + cv1^4/(2*n1^2) + cv2^4/(2*n2^2)
# where 1 = treatment, 2 = control, n1/n2 = replicate counts per group.
# ------------------------------------------------------------------------


# ----------------------------------------------------------------------
# Define here which columns define a "group" within which CV is averaged.
# Studies in the same group are assumed to have similar variability.

# Each rule = a set of outcomes (out_subindicator values) + the grouping
# variables that should be used for CV-averaging on THAT set of outcomes.
# Add as many rules as you need. Order doesn't matter.
# ----------------------------------------------------------------------
outcome_grouping_rules <- list(
  list(
    #out_indicator=="Product Yield"
    outcomes      = c(
      "Crop Yield", "Biomass Yield","Egg Yield","Meat Yield","Milk Yield",
      "Other Animal Product Yield","Reproductive Yield", "Weight Gain",
                      "Gross Return"),
    grouping_vars = c("C_product_simple","T_product_simple", "out_subindicator")
  )#,
  #list(
  # outcomes      = c("Soil Organic Carbon", "Soil Nitrogen"),
  # grouping_vars = c("Product", "out_subindicator")
  #),
  #list(
  # outcomes      = c("Water Use Efficiency"),
  # grouping_vars = c("out_subindicator")   # e.g. ignore Product here
  # )
)


n_cv_calculation <- function(dt, rules, outcome_col = "out_subindicator") {
  
  # Safety check: no outcome should appear in more than one rule
  all_outcomes <- unlist(lapply(rules, `[[`, "outcomes"))
  dupes <- all_outcomes[duplicated(all_outcomes)]
  if (length(dupes) > 0) {
    stop("These outcomes appear in more than one rule: ",
         paste(unique(dupes), collapse = ", "))
  }
  
  # Process each rule separately, then combine
  results <- lapply(rules, function(rule) {
    
    outcomes      <- rule$outcomes
    grouping_vars <- rule$grouping_vars
    
    dt_sub <- dt %>% filter(.data[[outcome_col]] %in% outcomes)
    if (nrow(dt_sub) == 0) return(dt_sub)
    
    needs_product_check <- all(c("C_product", "T_product") %in% grouping_vars)
    
    if (needs_product_check) {
      mismatches <- dt_sub %>%
        filter(!is.na(C_product), !is.na(T_product), C_product != T_product)
      
      if (nrow(mismatches) > 0) {
        warning(nrow(mismatches), " rows dropped for outcomes [",
                paste(outcomes, collapse = ", "),
                "]: C_product != T_product.")
      }
      
      dt_sub <- dt_sub %>%
        filter(is.na(C_product) | is.na(T_product) | C_product == T_product)
    }
    
    if (nrow(dt_sub) == 0) return(dt_sub)
    
    # ================================================================
    # Impute missing sample sizes (n) BEFORE n1/n2 are set below.
    # Uses the rule's own grouping_vars as predictors, so it stays
    # consistent with how CV is grouped for the same set of outcomes.
    # ================================================================
    imp_vars <- dt_sub %>%
      select(T_out_sample_size, C_out_sample_size,
             T_out_mean, C_out_mean,
             all_of(grouping_vars))
    
    imp <- mice(imp_vars, method = "pmm", m = 20, seed = 123, printFlag = FALSE)
    completed_list <- lapply(1:20, function(i) complete(imp, i))
    
    dt_sub <- dt_sub %>%
      mutate(
        T_out_sample_size_imputed = round(rowMeans(sapply(completed_list, `[[`, "T_out_sample_size"))),
        C_out_sample_size_imputed = round(rowMeans(sapply(completed_list, `[[`, "C_out_sample_size")))
      )
    
    # ================================================================
    # Step 1: calculate CV for every row where we have a real SD
    # ================================================================
  dt_sub <- dt_sub %>%
    mutate(
      n1 = coalesce(T_out_sample_size, T_out_sample_size_imputed),
      n2 = coalesce(C_out_sample_size, C_out_sample_size_imputed),
      T_out_cv_reported = T_out_sd / T_out_mean,
      C_out_cv_reported   = C_out_sd / C_out_mean,
      sd_was_reported       = !is.na(T_out_cv_reported) & !is.na(C_out_cv_reported)
    )
    # ================================================================
    # Step 2: calculate the average CV within each group, using only studies
    # that have a real SD (weighted by replicate count of each group)
    # ================================================================
  
  average_cv <- dt_sub %>%
    filter(sd_was_reported) %>%
    group_by(across(all_of(grouping_vars))) %>%
    summarise(
      ## TO CHECK: HOW TO DEAL WITH MISSING N VALUES!
      #This makes each row with a missing n1 (or n2) simply get excluded from that specific 
      #weighted average — instead of nulling out the average for the entire group. 
      #It's a scoped fix: a row missing n1 still contributes to C_out_cv_average (via n2) 
      #if n2 is present; only the specific side missing its sample size drops out of that specific calculation.
      T_out_cv_group_avg = sum(n1 * T_out_cv_reported, na.rm = TRUE) / sum(n1, na.rm = TRUE),
      C_out_cv_group_avg = sum(n2 * C_out_cv_reported, na.rm = TRUE) / sum(n2, na.rm = TRUE),
      .groups = "drop"
    )
  
  # Step 3: attach that average CV back onto the full dataset
  
  dt_sub <- dt_sub %>%
    left_join(average_cv, by = grouping_vars) %>%
    
  # Step 4: for rows with no SD, use the group average CV instead
    mutate(
      T_out_cv_final = if_else(sd_was_reported, T_out_cv_reported, T_out_cv_group_avg),
      C_out_cv_final   = if_else(sd_was_reported, C_out_cv_reported, C_out_cv_group_avg),
      
# ------------------------------------------------------------------------
# Now compute the effect size (lnRR) and its variance, 2 different ways.
# n1 and n2 are kept separate throughout, as required by the formula.
# ------------------------------------------------------------------------
    lnRR_cv_group_avg = log(T_out_mean  / C_out_mean) +
     0.5 * (C_out_cv_group_avg^2 / n2 - T_out_cv_group_avg^2 / n1),
   lnRR_var_cv_group_avg = (T_out_cv_group_avg^2 / n1) + (C_out_cv_group_avg^2 / n2) +
       (T_out_cv_group_avg^4 / (2 * n1^2)) + (C_out_cv_group_avg^4 / (2 * n2^2)),
      
     lnRR_cv_final = log(T_out_mean  / C_out_mean) +
       0.5 * (C_out_cv_final^2 / n2 - T_out_cv_final^2 / n1),
     lnRR_var_cv_final = (T_out_cv_final^2 / n1) + (C_out_cv_final^2 / n2) +
       (T_out_cv_final^4 / (2 * n1^2)) + (C_out_cv_final^4 / (2 * n2^2)),
      
      cv_grouping_method = paste(grouping_vars, collapse = " + ")  # audit trail
    )%>%
    select(-n1,-n2,-sd_was_reported)
  
  dt_sub
  })
  
  dt_processed <- bind_rows(results)
  
  # Rows whose outcome wasn't covered by ANY rule -> kept as-is (untouched)
  dt_unmatched <- dt %>% filter(!.data[[outcome_col]] %in% all_outcomes)
  
  bind_rows(dt_processed, dt_unmatched)
}


