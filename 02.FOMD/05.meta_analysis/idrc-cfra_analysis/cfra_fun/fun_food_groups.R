library(dplyr)
library(tidyr)
library(stringr)

#==========================================================
# Food groups relevant to school meals
#==========================================================
# Food group of each effect size:
#   - crop-level outcomes (yield, inputs efficiency, resilience to pests):
#       food group of the crop on which the outcome was measured (T_product_simple)
#   - resilience to pests measured on an organism (pest or weed counts, product = taxon):
#       food group(s) of the cropping system, as for system-level outcomes
#   - system-level outcomes (soil health, biodiversity, climate mitigation,
#     labour demand, profitability):
#       food group(s) of the whole cropping system (CT_crop_tree_FAO_Food_Group)
# When a system (or product) combines several food groups, the effect size is
# DUPLICATED: one row per food group, flagged with multi_crop_system = TRUE.
# Non-food crops (fodder, stimulants, trees) get NA and are excluded.
#==========================================================

#--- 1. Outcomes measured on a single crop ----
crop_level_outcomes <- c("Yield", "Inputs efficiency", "Resilience to pests")

#--- 2. School-meal food groups, in the order shown in figures ----
food_group_order <- c("Cereals", "Pulses and legumes", "Nuts and seeds", "Roots and tubers",
                      "Vegetables", "Fruits")

#--- 3. FAO food group (and subgroup) -> school-meal food group ----
# Dietary rather than production classification:
#   soybean -> Pulses and legumes; other oilseeds (groundnut, sunflower, sesame) -> Nuts and seeds;
#   nuts in "Fruit and nuts" (e.g. cashew, macadamia) -> Nuts and seeds
fao_to_school <- function(fao_group, fao_subgroup = NA_character_) {
  sub <- coalesce(fao_subgroup, "")
  case_when(
    fao_group == "Cereals"                                              ~ "Cereals",
    fao_group == "Leguminous crops"                                     ~ "Pulses and legumes",
    fao_group == "Oilseed crops and oleaginous fruits" &
      str_detect(sub, "Soya")                                           ~ "Pulses and legumes",
    fao_group == "Oilseed crops and oleaginous fruits"                  ~ "Nuts and seeds",
    str_detect(fao_group, "Fruit and nuts") & str_detect(sub, "Nuts")   ~ "Nuts and seeds",
    str_detect(fao_group, "Root tuber")                                 ~ "Roots and tubers",
    str_detect(fao_group, "Vegetables")                                 ~ "Vegetables",
    str_detect(fao_group, "Fruit and nuts|^Fruits")                     ~ "Fruits",
    TRUE                                                                ~ NA_character_)
}

#--- 4. Main function ----
# df              effect sizes with outcome_group, T_product_simple,
#                 CT_crop_tree_FAO_Food_Group and CT_crop_tree_FAO_Food_SubGroup
# product_lookup  table with columns product (crop name) and food_group (school-meal group)
assign_food_group <- function(df, product_lookup) {
  
  lookup <- setNames(product_lookup$food_group, product_lookup$product)
  
  # food groups of the measured crop; products like "Maize..Lepidoptera" keep the crop part only
  crop_groups <- lapply(str_split(df$T_product_simple, fixed("..")), function(p) {
    fg <- unique(na.omit(unname(lookup[p])))
    if (length(fg) == 0) NA_character_ else fg
  })
  
  # food groups of the treatment cropping system (all crops in the treatment)
  system_groups <- mapply(function(g, s) {
    gs <- str_split(g, fixed(".."))[[1]]
    ss <- str_split(s, fixed(".."))[[1]]
    if (length(ss) != length(gs)) ss <- rep(s, length(gs))
    fg <- unique(na.omit(fao_to_school(gs, ss)))
    if (length(fg) == 0) NA_character_ else fg
  }, df$T_crop_tree_FAO_Food_Group, df$T_crop_tree_FAO_Food_SubGroup, SIMPLIFY = FALSE, USE.NAMES = FALSE)
  
  # crop-level outcomes use the measured crop. Only for pest and weed counts (resilience to pests),
  # whose product is the organism counted, a product with no food group falls back to the system's crops
  no_group <- vapply(crop_groups, function(x) all(is.na(x)), logical(1))
  use_crop <- df$outcome_group %in% crop_level_outcomes &
    !(df$outcome_group %in% "Resilience to pests" & no_group)
  
  # one row per food group (duplicated when the system has several food groups)
  df %>%
    mutate(food_group_basis = if_else(use_crop, "measured crop", "cropping system"),
           food_group = if_else(use_crop, crop_groups, system_groups),
           multi_crop_system = lengths(food_group) > 1) %>%
    unnest(food_group) %>%
    mutate(food_group = factor(food_group, levels = food_group_order))

}

#--- 5. N-fixing trees in the system ----
# Uses the tree classification already in the data: the pipeline looks up each tree's
# Tree.Nfix in the ontology sheet 01_trees and writes "N Fix Tree" / "No N Fix Tree"
# into C_/T_crop_tree_FAO_Food_Group.
add_nfix_trees <- function(df) {
  nfix   <- "(^|[.][.])N Fix Tree($|[.][.])"
  nonfix <- "(^|[.][.])No N Fix Tree($|[.][.])"
  df %>%
    mutate(C_nfix_tree  = str_detect(coalesce(C_crop_tree_FAO_Food_Group, ""), nfix),
           T_nfix_tree  = str_detect(coalesce(T_crop_tree_FAO_Food_Group, ""), nfix),
           T_other_tree = str_detect(coalesce(T_crop_tree_FAO_Food_Group, ""), nonfix),
           trees = case_when(T_nfix_tree & !C_nfix_tree ~ "N-fixing trees added in treatment",
                             T_nfix_tree &  C_nfix_tree ~ "N-fixing trees in both",
                             T_other_tree               ~ "Non-N-fixing trees in treatment",
                             TRUE                       ~ "No trees"))
}