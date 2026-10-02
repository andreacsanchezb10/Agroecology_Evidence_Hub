library(dplyr)
library(tidyr)
library(stringr)

#==========================================================
# practice_detail(): detail of one tested practice (T vs C)
#==========================================================
# Use it to describe a practice with positive effects: which crops, companion species,
# systems, subpractices, background management and studies are behind the result.
#
# long            output of reclassify_practices() (one row per comparison and practice group)
# archetype_name  archetype, e.g. "2A - Soil restoration"
# T_name, C_name  treatment and control practice, as shown in the figure (after reclassification)
# food            food group (optional), e.g. "Cereals"
# outcome         outcome group (optional), e.g. "Yield"
# data            optional: comparisons before reclassification (e.g. arc.data), for $background
# extra           optional: columns added to $companions and summarised in $extra,
#                 e.g. "T_intercrop_subpractice", "T_fert_subpractice"
#
# Returns a list of tables. In every table:
#   Studies, Comparisons, Positive, Neutral, Negative, % positive
#   $outcomes      by outcome group and subindicator
#   $subpractices  by harmonised subpractice (more detailed than the practice)
#   $systems       by control and treatment cropping system (crops grown)
#   $crops         by crop on which the outcome was measured
#   $companions    by measured crop, species added in the treatment, and the `extra` columns
#   $background    other management, the same in control and treatment (needs `data`)
#   $extra         by the `extra` columns
#   $studies       one row per study
#==========================================================

# positive, neutral and negative comparisons, as in count_effects()
summarise_effects <- function(x) {
  x %>%
    summarise(Studies     = n_distinct(study_id),
              Comparisons = n_distinct(effect_size_id),
              `Positive comparisons`    = n_distinct(effect_size_id[direction > 0]),
              `Neutral comparisons`     = n_distinct(effect_size_id[direction == 0]),
              `Negative comparisons`    = n_distinct(effect_size_id[direction < 0]),
              .groups = "drop") %>%
    mutate(`% positive comparisons` = round(100 * `Positive comparisons` / Comparisons)) %>%
    arrange(desc(Comparisons))
}

# same inputs in any order -> one label (components sorted alphabetically)
sort_inputs <- function(x) {
  vapply(str_split(coalesce(x, ""), "\\.{2,}| \\+ "), function(p) {
    p <- sort(str_trim(p[p != ""]))
    if (length(p) == 0) NA_character_ else paste(p, collapse = " + ")
  }, character(1))
}

practice_detail <- function(long, archetype_name, T_name, C_name, food = NULL, outcome = NULL,
                            data = NULL, extra = NULL) {
  
  # 1. Comparisons of this practice
  sel <- long %>%
    filter(archetype == archetype_name, T_practice == T_name, C_practice == C_name)
  if (!is.null(food))    sel <- sel %>% filter(food_group == food)
  if (!is.null(outcome)) sel <- sel %>% filter(outcome_group == outcome)
  if (nrow(sel) == 0) stop("No comparisons for this selection. Check the names in the figure.")
  
  # one row per comparison (removes the food-group duplication)
  pc <- sel %>% distinct(effect_size_id, .keep_all = TRUE)
  extra_cols <- intersect(extra, names(pc))
  pc <- pc %>% mutate(across(all_of(extra_cols), ~ if (is.character(.x)) sort_inputs(.x) else .x))
  
  # 2. Harmonised subpractice column of this practice group (e.g. diversification_spatial_subpractice)
  sub_col <- paste0(str_replace_all(tolower(unique(sel$practice_group)[1]), " ", "_"), "_subpractice")
  
  # 3. Companion species: species in the treatment system other than the measured crop
  companions <- pc %>%
    mutate(added = mapply(function(t, m) {
      species  <- str_trim(str_split(coalesce(t, ""), "[-/]")[[1]])
      measured <- str_trim(str_split(coalesce(m, ""), fixed(".."))[[1]])
      a <- setdiff(species, c(measured, "Fallow"))
      if (length(a) == 0 || all(a == "")) NA_character_ else paste(sort(a), collapse = " + ")
    }, T_crop_tree_diversity, T_product_simple, USE.NAMES = FALSE))
  
  # 4. Background management (needs `data`): other practice groups where control and treatment are the same
  background <- NULL
  if (!is.null(data)) {
    groups_cols <- intersect(paste0(practice_groups, "_practice"), names(data))
    background <- data %>%
      semi_join(pc %>% select(effect_size_id), by = "effect_size_id") %>%
      distinct(effect_size_id, .keep_all = TRUE) %>%
      select(-direction) %>%
      left_join(pc %>% select(effect_size_id, direction), by = "effect_size_id") %>%   # direction after swaps
      select(study_id, effect_size_id, direction, all_of(groups_cols)) %>%
      pivot_longer(all_of(groups_cols), names_to = "group", values_to = "label") %>%
      filter(!is.na(label)) %>%
      mutate(group = str_to_sentence(str_replace_all(str_remove(group, "_practice$"), "_", " ")),
             C = str_trim(str_remove(str_extract(label, "^C: .*?(?=_vs_T: )"), "^C: ")),
             T = str_trim(str_remove(str_extract(label, "_vs_T: .*$"), "^_vs_T: "))) %>%
      filter(tolower(C) == tolower(T)) %>%
      group_by(`Practice group` = group, `In both arms` = C) %>%
      summarise_effects()
  }
  
  # 5. Tables
  list(
    outcomes     = pc %>% group_by(`Outcome` = outcome_group, `Indicator` = out_subindicator) %>%
      summarise_effects(),
    subpractices = if (sub_col %in% names(pc)) pc %>% group_by(`Subpractice` = .data[[sub_col]]) %>%
      summarise_effects() else NULL,
    systems      = pc %>% group_by(`Control system` = C_crop_tree_diversity,
                                   `Treatment system` = T_crop_tree_diversity) %>%
      summarise_effects(),
    crops        = pc %>% group_by(`Measured crop` = T_product_simple) %>% summarise_effects(),
    companions   = companions %>% group_by(`Measured crop` = T_product_simple, `Companion species` = added,
                                           across(all_of(extra_cols))) %>%
      summarise_effects(),
    background   = background,
    extra        = if (length(extra_cols) > 0) pc %>% group_by(across(all_of(extra_cols))) %>%
      summarise_effects() else NULL,
    studies      = pc %>% group_by(`Study` = study_id, `Authors` = authors, `Year` = year) %>%
      summarise_effects()
  )
}


with_header <- function(df, label = NULL) {
  df[] <- lapply(df, as.character)
  out  <- rbind(names(df), df)                       # column names become a row
  if (!is.null(label)) out <- rbind(c(label, rep("", ncol(df) - 1)), out)   # label row on top
  names(out) <- paste0("V", seq_along(out))
  out
}