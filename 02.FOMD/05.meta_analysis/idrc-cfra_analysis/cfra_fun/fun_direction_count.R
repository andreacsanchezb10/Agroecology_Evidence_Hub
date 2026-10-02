library(dplyr)
library(tidyr)
library(stringr)

#==========================================================
# Functions for the CFRA direction-of-effect (vote count) analysis
#==========================================================
# add_direction()      direction of each effect size (+1 better under AE/RA, -1 worse, 0 equal)
# tested_practices()   one row per effect size and tested practice group, with harmonised names
# count_votes()        one vote per study and cell; share of studies with a positive effect
#==========================================================

#----------------------------------------------------------
# add_direction()
#----------------------------------------------------------
# df              effect sizes with out_subindicator, C_out_mean, T_out_mean
# outcome_lookup  tibble: out_subindicator, outcome_group, lower_is_better
# Subindicators not in outcome_lookup are dropped (listed in a message).
add_direction <- function(df, outcome_lookup) {
  missing <- setdiff(unique(df$out_subindicator), outcome_lookup$out_subindicator)
  if (length(missing) > 0) message("Not in outcome_lookup (dropped): ", paste(missing, collapse = "; "))
  
  df %>%
    inner_join(outcome_lookup, by = "out_subindicator") %>%
    mutate(direction = sign(T_out_mean - C_out_mean),
           direction = if_else(lower_is_better, -direction, direction))
}

#----------------------------------------------------------
# tested_practices()
#----------------------------------------------------------
# df                    output of add_direction()
# practice_groups       practice-group column stems, e.g. "nutrient_management"
# level                 "practice" or "subpractice" (which harmonised columns to use)
# practice_recode       tibble: pattern, new_name        -> any name matching pattern becomes new_name
# practice_pair_recode  tibble: C_practice, T_practice, C_new_name -> rename C for that pair only
# practice_swap         tibble: C_practice, T_practice   -> pair stored the wrong way round: swap C/T
#                                                          and reverse the direction
# The three tables use names as they appear after the previous step
# (recode -> pair recode -> swap). Only groups where C and T differ are kept.
tested_practices <- function(df, practice_groups, level = "practice",
                             practice_recode = NULL, practice_pair_recode = NULL, practice_swap = NULL) {
  cols <- paste0(practice_groups, "_", level)
  keep <- intersect(c("archetype", "study_id", "effect_size_id", "outcome_group", "direction"), names(df))
  
  long <- df %>%
    select(all_of(keep), all_of(cols)) %>%
    pivot_longer(all_of(cols), names_to = "practice_group", values_to = "practice") %>%
    filter(!is.na(practice)) %>%
    mutate(practice_group = str_to_sentence(str_replace_all(sub(paste0("_", level, "$"), "", practice_group), "_", " ")),
           C_practice = str_trim(str_remove(str_extract(practice, "^C: .*?(?=_vs_T: )"), "^C: ")),
           T_practice = str_trim(str_remove(str_extract(practice, "_vs_T: .*$"), "^_vs_T: ")))
  
  # 1. Merge practice names
  if (!is.null(practice_recode)) {
    for (i in seq_len(nrow(practice_recode))) {
      long <- long %>%
        mutate(C_practice = if_else(str_detect(C_practice, practice_recode$pattern[i]), practice_recode$new_name[i], C_practice),
               T_practice = if_else(str_detect(T_practice, practice_recode$pattern[i]), practice_recode$new_name[i], T_practice))
    }
  }
  
  # 2. Rename the control for specific pairs
  if (!is.null(practice_pair_recode)) {
    long <- long %>%
      left_join(practice_pair_recode, by = c("C_practice", "T_practice")) %>%
      mutate(C_practice = coalesce(C_new_name, C_practice)) %>%
      select(-C_new_name)
  }
  
  # 3. Swap pairs stored the wrong way round, and reverse their direction
  long$swap <- FALSE
  if (!is.null(practice_swap)) {
    long <- long %>%
      select(-swap) %>%
      left_join(practice_swap %>% mutate(swap = TRUE), by = c("C_practice", "T_practice")) %>%
      mutate(swap = coalesce(swap, FALSE),
             C_new = if_else(swap, T_practice, C_practice),
             T_new = if_else(swap, C_practice, T_practice),
             direction = if_else(swap, -direction, direction)) %>%
      select(-C_practice, -T_practice) %>%
      rename(C_practice = C_new, T_practice = T_new)
  }
  
  # 4. Keep only practice groups where C and T differ (the tested practice)
  long %>% filter(tolower(C_practice) != tolower(T_practice))
}

#----------------------------------------------------------
# count_effects()
#----------------------------------------------------------
# long              output of reclassify_practices()
# by                cell definition, e.g. c("archetype", "practice_group", "T_practice", "C_practice", "outcome_group")
# min_studies_cell  minimum studies for a cell to be reported
#
# For each cell:
#   effect_sizes   number of effect sizes
#   positive       effect sizes with a positive effect (direction = +1)
#   negative       effect sizes with a negative effect (direction = -1)
#   neutral        effect sizes with no difference     (direction =  0)
#   pct_positive   positive / effect_sizes * 100
#   k              number of studies (used for the minimum-evidence threshold)
count_effects <- function(long, by = c("archetype", "practice_group", "T_practice", "C_practice", "outcome_group"),
                          min_studies_cell = 5) {
  long %>%
    group_by(across(all_of(by))) %>%
    summarise(k            = n_distinct(study_id),
              effect_sizes = n_distinct(effect_size_id),
              positive     = sum(direction > 0),
              negative     = sum(direction < 0),
              neutral      = sum(direction == 0),
              .groups = "drop") %>%
    mutate(pct_positive = 100 * positive / (positive + negative + neutral),
           enough = k >= min_studies_cell)
}