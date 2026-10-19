library(dplyr)
library(tidyr)
library(stringr)
library(tibble)

#==========================================================
# Practices reclassification
#==========================================================
# Goal: for each effect size, find the practice that is being tested
# (the practice that differs between control and treatment), with clean names.
#
# Steps:
#   1. Practice groups to use
#   2. Rename practices        (e.g. all "Organic mulch (...)" -> "Organic mulch")
#   3. Rename the control for specific pairs only
#                              (e.g. "Crop residues removed" vs "Organic mulch" -> "No residues or mulch" vs "Organic mulch")
#   4. Swap control and treatment when they are the wrong way round
#                              (e.g. "Organic mulch" vs "No residues or mulch" -> "No residues or mulch" vs "Organic mulch")
#   4b. Move practices to another management domain
#   4c. Variety management: local vs improved variety
#   5. Function reclassify_practices() that applies steps 1-4c
#
# Steps 1-4c are the decisions: edit them here. Step 5 does not need to be edited.
#==========================================================

#----------------------------------------------------------
#--- 1. Practice groups to use ----
#----------------------------------------------------------
practice_groups <- c("biomass_management",
                     "diversification_spatial",
                     "diversification_temporal",
                     "harvest",
                     "nutrient_management",
                     "pest_management",
                     "planting_management",
                     # "postharvest" excluded: not an AE/RA production practice (removed in 01.cfra_data.R)
                     "soil_management",
                     "variety_management",
                     "water_management")

#----------------------------------------------------------
#--- 2. Rename practices ----
#----------------------------------------------------------
# Any practice name (control or treatment) that starts with `starts_with` becomes `new_name`
practice_rename <- tribble(
  ~starts_with,                  ~new_name,
  "Crop residues incorporated",  "Residues incorporation",
  "Tree pruning incorporated",   "Residues incorporation",
  "Crop residues retained",      "Residues retention",
  "Crop residues grazed",        "No residues or mulch",
  "Crop residues removed",       "No residues or mulch",
  "No mulch",                    "No residues or mulch",
  "Organic mulch",               "Organic mulch",
  
  "Alleycropping",               "Agroforestry",
  "Boundary Planting",           "Agroforestry",
  "Intercropping",               "Intercropping",
  
  "Woody Fallow (N fixing)","Improved fallow",
  "Crop Rotation (N fixing mixed)", "Crop rotation",
  
  
  "Biochar","Biochar amendment",
  "Inorganic and Organic Fertilizers","Mixed fertilizer",
  "No Fertilizers Applied", "No fertilizer applied",
  "Organic Fertilizer","Organic fertilizer",
  "Organic Fertilizer + Inorganic Fertilizer","Mixed fertilizer",
  
  "Conventional Tillage", "Conventional tillage",
  "Reduced Tillage", "Reduced tillage",
  "Zero Tillage", "Zero tillage",
  
  "Supplemental Irrigation", "Supplemental irrigation"
  
  
  
)

#----------------------------------------------------------
#--- 3. Rename the control for specific pairs only ----
#----------------------------------------------------------
# Only when the control is `C_practice` AND the treatment is `T_practice`,
# the control is renamed to `C_new`. Use names as they are after step 2.
control_rename <- tribble(
  ~C_practice,          ~T_practice,        ~C_new,
  "Residues removed",   "Organic mulch",    "No residues or mulch",
  "No Chemical Applied","Inoculation", "No fertilizer applied"
)

#----------------------------------------------------------
#--- 4. Swap control and treatment ----
#----------------------------------------------------------
# Pairs where the AE/RA practice is in the control and the conventional one in the treatment.
# Control and treatment are swapped, and the direction of the effect is reversed.
# Use names as they are after steps 2, 3 and 4c.
swap_pairs <- tribble(
  ~C_practice,              ~T_practice,
  "Organic mulch",          "No residues or mulch",
  "Residues incorporation",  "No residues or mulch",
   "Crop rotation",          "Monoculture",
  
  "Inorganic Fertilizer",    "No fertilizer applied", 
  "Mixed fertilizer",        "Organic fertilizer",
  "Inoculation",              "No Chemical Applied",
  
  "Reduced tillage",          "Conventional tillage",
  "Zero tillage",          "Conventional tillage",
  
  
  "Local variety","Improved variety" ,            # local variety (AE practice) always in the treatment
)

#----------------------------------------------------------
#--- 4b. Move practices to another management domain ----
#----------------------------------------------------------
# A comparison whose treatment practice is `T_practice` is assigned to `new_group`,
# whatever group it was harmonised in. Use names as they are after steps 2-4.
practice_group_move <- tribble(
  ~T_practice,     ~new_group,
  "Inoculation",   "Nutrient management"
)

#----------------------------------------------------------
#--- 4c. Variety management: local vs improved variety ----
#----------------------------------------------------------
# In variety management, each arm (control and treatment) is renamed:
#   "Local variety"       varietal type (varietal_crop_type) is "Local"
#   "Improved variety"    improved practice (improved, early maturity, drought tolerance) and not local
#   "Unspecified variety" anything else, e.g. "Unimproved Variety" without type "Local"
# Comparisons with an unspecified arm are dropped. Comparisons between two improved
# varieties (variety trials) are dropped in 5.6, as control and treatment are the same.
variety_origin <- function(practice, type, variety = NA_character_) {
  # local when the varietal type is "Local" or the variety name says local / landrace
  local_name <- str_detect(coalesce(variety, ""), regex("local|landrace", ignore_case = TRUE))
  case_when(str_detect(coalesce(type, ""), "Local") | local_name                     ~ "Local variety",
            str_detect(practice, "^Improved variety|Early Maturity|Drought Tolerance") &
              !str_detect(practice, "Unimproved")                                   ~ "Improved variety",
            TRUE                                                                    ~ "Unspecified variety")
}

#----------------------------------------------------------
#--- 4d. Excluded contrasts ----
#----------------------------------------------------------
# Paired comparisons testing any of these contrasts are removed entirely, in all
# practice groups (the effect of the other practices tested is confounded with it).
# Use names as they are after steps 2-4c.
exclude_pairs <- tribble(
  ~C_practice,                    ~T_practice,
  "No residues or mulch",         "Plastic mulch",  # not an AE/RA practice
  "No fertilizer applied",        "Inorganic Fertilizer",   # not an AE/RA practice
  "Inorganic Fertilizer",         "No fertilizer applied",
  "Synthetic pesticide",          "No Chemical Applied",
  #"Inorganic Fertilizer",         "Mixed fertilizer",
  "Organic fertilizer",           "Mixed fertilizer",
  #"Inorganic Fertilizer",         "Organic fertilizer",    
  
  "No Chemical Applied"  ,         "Synthetic pesticide"
 
)

#----------------------------------------------------------
#--- 4f. Mixed inputs ----
#----------------------------------------------------------
# In nutrient and pest management, an arm that combines an organic or biological input
# with a mineral or synthetic one is renamed "Mixed fertilizer" / "Mixed pest control".
organic_terms <- "Organic|Biochar|Manure|Compost|Biosolids|Inoculation|Biofertilizer|Biological"
mineral_terms <- "Inorganic|Synthetic|Herbicide|Insecticide|Fungicide"

mixed_inputs <- function(label, group) {
  mixed <- vapply(str_split(coalesce(label, ""), fixed(" + ")), function(parts) {
    parts <- str_trim(parts)
    parts <- parts[!str_detect(parts, regex("^No ", ignore_case = TRUE))]   # "No ... Applied" is not an input
    any(str_detect(parts, organic_terms)) & any(str_detect(parts, mineral_terms))
  }, logical(1))
  case_when(mixed & group == "Nutrient management" ~ "Mixed fertilizer",
            mixed & group == "Pest management"     ~ "Mixed pest control",
            TRUE                                   ~ label)
}

#----------------------------------------------------------
#--- 5. Function ----
#----------------------------------------------------------
# df      effect sizes with the <group>_practice columns and a `direction` column
#         (direction = +1 better, -1 worse under the treatment)
# level   "practice" (default) or "subpractice": which harmonised columns to use
#
# Returns one row per effect size and tested practice group, with columns:
#   practice_group, C_original, T_original (names before reclassification),
#   C_practice, T_practice (names after reclassification), swapped, direction (+ id columns)
# An effect size appears once for each practice group in which control and treatment differ.
reclassify_practices <- function(df, level = "practice") {
  
  # 5.1 One row per effect size and practice group
  cols <- paste0(practice_groups, "_", level)
  cols <- cols[cols %in% names(df)]
  
  long <- df %>%
    pivot_longer(all_of(cols), names_to = "practice_group", values_to = "practice") %>%
    filter(!is.na(practice))
  
  # 5.2 Split "C: X_vs_T: Y" into control (X) and treatment (Y)
  long <- long %>%
    mutate(practice_group = sub(paste0("_", level, "$"), "", practice_group),
           practice_group = str_to_sentence(str_replace_all(practice_group, "_", " ")),
           C_practice = str_trim(str_remove(str_extract(practice, "^C: .*?(?=_vs_T: )"), "^C: ")),
           T_practice = str_trim(str_remove(str_extract(practice, "_vs_T: .*$"), "^_vs_T: ")),
           # keep the names before reclassification, to compare
           C_original = C_practice,
           T_original = T_practice)
  
  # 5.2b Variety management: local vs improved variety (step 4c)
  if (all(c("C_varietal_crop_type", "T_varietal_crop_type") %in% names(long))) {
    long <- long %>%
      mutate(is_variety = practice_group == "Variety management",
             C_practice = if_else(is_variety, variety_origin(C_practice, C_varietal_crop_type, C_varietal_crop_variety), C_practice),
             T_practice = if_else(is_variety, variety_origin(T_practice, T_varietal_crop_type, T_varietal_crop_variety), T_practice)) %>%
      
      filter(!(is_variety & (C_practice == "Unspecified variety" | T_practice == "Unspecified variety"))) %>%
      select(-is_variety)
  }
  
  # 5.2c Mixed inputs (step 4f): organic or biological + mineral or synthetic in the same arm
  long <- long %>%
    mutate(C_practice = mixed_inputs(C_practice, practice_group),
           T_practice = mixed_inputs(T_practice, practice_group))
  
  # 5.3 Rename practices (step 2)
  for (i in seq_len(nrow(practice_rename))) {
    long <- long %>%
      mutate(C_practice = if_else(str_starts(C_practice, fixed(practice_rename$starts_with[i])),
                                  practice_rename$new_name[i], C_practice),
             T_practice = if_else(str_starts(T_practice, fixed(practice_rename$starts_with[i])),
                                  practice_rename$new_name[i], T_practice))
  }
  
  # 5.4 Rename the control for specific pairs (step 3)
  long <- long %>%
    left_join(control_rename, by = c("C_practice", "T_practice")) %>%
    mutate(C_practice = coalesce(C_new, C_practice)) %>%
    select(-C_new)
  
  # 5.5 Swap control and treatment, and reverse the direction (step 4)
  long <- long %>%
    left_join(swap_pairs %>% mutate(swapped = TRUE), by = c("C_practice", "T_practice")) %>%
    mutate(swapped = coalesce(swapped, FALSE),
           C_old = C_practice,
           C_practice = if_else(swapped, T_practice, C_practice),
           T_practice = if_else(swapped, C_old, T_practice),
           direction  = if_else(swapped, -direction, direction)) %>%
    select(-C_old)
  
  # 5.5a Swap every other control/treatment column pair as well (means, crops, varieties,
  #      subpractices...), so that C_ always describes the control and T_ the treatment
  pairs <- intersect(sub("^C_", "", grep("^C_", names(long), value = TRUE)),
                     sub("^T_", "", grep("^T_", names(long), value = TRUE)))
  pairs <- setdiff(pairs, c("practice", "original"))   # practice already swapped; original kept as recorded
  for (p in pairs) {
    cc <- paste0("C_", p); tt <- paste0("T_", p)
    if (!identical(class(long[[cc]]), class(long[[tt]]))) {
      long[[cc]] <- as.character(long[[cc]]); long[[tt]] <- as.character(long[[tt]])
    }
    tmp <- long[[cc]]
    long[[cc]][long$swapped] <- long[[tt]][long$swapped]
    long[[tt]][long$swapped] <- tmp[long$swapped]
  }
  # effect size (log response ratio) changes sign
  if ("out_effect_size_yi" %in% names(long)) long$out_effect_size_yi[long$swapped] <- -long$out_effect_size_yi[long$swapped]
  
  
  # 5.5b Rename the control again, for pairs that were swapped in 5.5
  long <- long %>%
    left_join(control_rename, by = c("C_practice", "T_practice")) %>%
    mutate(C_practice = coalesce(C_new, C_practice)) %>%
    select(-C_new)
  
  # 5.5c Move practices to another management domain (step 4b)
  long <- long %>%
    left_join(practice_group_move, by = "T_practice") %>%
    mutate(practice_group = coalesce(new_group, practice_group)) %>%
    select(-new_group)
  
  # 5.6 Keep only practice groups where control and treatment differ (the tested practice)
  long <- long %>% filter(tolower(C_practice) != tolower(T_practice))
  
  # 5.7 Remove paired comparisons testing an excluded contrast (step 4d), in all practice groups
  excluded_ids <- long %>%
    semi_join(exclude_pairs, by = c("C_practice", "T_practice")) %>%
    distinct(effect_size_id)
  long %>% anti_join(excluded_ids, by = "effect_size_id")

}