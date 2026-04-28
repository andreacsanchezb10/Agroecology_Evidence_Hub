library(tibble)
library(readxl)
library(stringr)
library(dplyr)
library(tidyr)
library(readr)
library(purrr)



path.metadata.structure<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Knowledge Hub - General/Agroecology_Knolwedge_Hub/02.FOMD/02.metadata_structure/"
path.metadata.effectsize<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Knowledge Hub - General/Agroecology_Knolwedge_Hub/02.FOMD/04.metadata_effectsize/"

list.files(path.metadata.structure)
list.files(path.metadata.effectsize)

#==========================================================
# Read datasets
#==========================================================
#---01_FOMD_ontologies
fomd01.practices<-read_xlsx(file.path(path.metadata.structure,"01_FOMD_ontologies.xlsx"), sheet = "01_practices")%>%
  mutate(practice_subtype= paste0(type,"(",subtype,")"))

#---fomd10.effectsize
fomd10.effectsize<-read_csv(file.path(path.metadata.effectsize,"fomd10_effect_size.csv"), show_col_types = FALSE)%>%
  filter(!is.na(effect_size_yi))
  
  
subpractice.list<-c(
  "tillage_subpractice", #soil_management_practice
  "planting_subpractice", #planting_practice
  "varietal_crop_subpractice", #improved crop varieties: practice
  "varietal_animal_subpractice", #improved breeds: practice
  "intercrop_subpractice", #intercropping: practice
  "crop_seq_subpractice", #crop_sequence_practice
  "agrof_subpractice", #agroforestry_practice
  "fert_subpractice", #nutrient management: practice
  "chem_subpractice", #chemical_management_practice
  "residues_subpractice", #residues_practice
  "ph_subpractice", #pH_amendment_practice
  "irrig_subpractice", #irrigation_practice
  "watharv_subpractice", #water_harvesting_practice
  "harvest_subpractice", #harvest_practice
  "postharvest_subpractice" #postharvesting_practice
  
)

split_clean <- function(x) {
  if (is.na(x) || x == "") return(character(0))
  
  x %>%
    stringr::str_split("-", simplify = FALSE) %>%
    .[[1]] %>%
    stringr::str_trim() %>%
    purrr::discard(~ .x == "") %>%
    unique()
}

compare_subpractice <- function(c_val, t_val) {
  out <- character(length(c_val))
  
  for (i in seq_along(c_val)) {
    c_parts <- split_clean(c_val[i])
    t_parts <- split_clean(t_val[i])
    
    c_only <- setdiff(c_parts, t_parts)
    t_only <- setdiff(t_parts, c_parts)
    
    # remove cases where:
    # 1. both sides are empty
    # 2. one side disappears after overlap removal
    if (length(c_only) == 0 || length(t_only) == 0) {
      out[i] <- NA_character_
    } else {
      out[i] <- paste0(
        paste(c_only, collapse = "-"),
        " vs ",
        paste(t_only, collapse = "-")
      )
    }
  }
  
  out
}

new_cols <- setNames(
  lapply(subpractice.list, function(x) {
    c_col <- paste0("C_", x)
    t_col <- paste0("T_", x)
    
    c_val <- fomd10.effectsize[[c_col]]
    t_val <- fomd10.effectsize[[t_col]]
    
    c_val[c_val == ""] <- NA
    t_val[t_val == ""] <- NA
    
    compare_subpractice(t_val,c_val)
  }),
  paste0("T_C_", subpractice.list)
)

fomd10.distribution <- fomd10.effectsize %>%
  bind_cols(as_tibble(new_cols))

sort(unique(fomd10.distribution$T_C_tillage_subpractice))
sort(unique(fomd10.distribution$T_C_planting_subpractice))
sort(unique(fomd10.distribution$T_C_varietal_crop_subpractice))
sort(unique(fomd10.distribution$T_C_varietal_animal_subpractice))
sort(unique(fomd10.distribution$T_C_intercrop_subpractice))
sort(unique(fomd10.distribution$T_C_crop_seq_subpractice))
sort(unique(fomd10.distribution$T_C_agrof_subpractice))
sort(unique(fomd10.distribution$T_C_fert_subpractice))
sort(unique(fomd10.distribution$T_C_chem_subpractice))
sort(unique(fomd10.distribution$T_C_residues_subpractice))
sort(unique(fomd10.distribution$T_C_ph_subpractice))
sort(unique(fomd10.distribution$T_C_irrig_subpractice))
sort(unique(fomd10.distribution$T_C_watharv_subpractice))
sort(unique(fomd10.distribution$T_C_harvest_subpractice))
sort(unique(fomd10.distribution$T_C_postharvest_subpractice))

#-----------------------------------------------
#---- Match with ontologies ----
#-----------------------------------------------
#--- lookup vector:  values = practice
lookup.practice <- fomd01.practices %>%
  transmute(
    subpractice = str_squish(subpractice),
    practice    = str_squish(practice)
  ) %>%
  distinct() %>%
  deframe()

split_side <- function(x) {
  if (is.na(x) || x == "") return(character(0))
  
  x %>%
    stringr::str_split("-", simplify = FALSE) %>%
    .[[1]] %>%
    stringr::str_trim() %>%
    purrr::discard(~ .x == "") %>%
    unique()
}

map_side_to_practice <- function(side, lookup) {
  vals <- split_side(side)
  if (length(vals) == 0) return(NA_character_)
  
  out <- unname(lookup[vals])
  out[is.na(out)] <- vals[is.na(out)]
  
  out <- unique(out)
  paste(out, collapse = "-")
}

map_tc_subpractice_to_practice <- function(val, lookup) {
  if (is.na(val) || val == "") return(NA_character_)
  
  sides <- stringr::str_split(stringr::str_squish(val), " vs ", simplify = FALSE)[[1]]
  
  if (length(sides) != 2) return(val)
  
  left  <- map_side_to_practice(sides[1], lookup)
  right <- map_side_to_practice(sides[2], lookup)
  
  if (is.na(left) || is.na(right)) return(NA_character_)
  
  paste0(left, " vs ", right)
}

practice_cols <- setNames(
  lapply(subpractice.list, function(x) {
    sub_col <- paste0("T_C_", x)
    
    purrr::map_chr(
      fomd10.distribution[[sub_col]],
      ~ map_tc_subpractice_to_practice(.x, lookup.practice)
    )
  }),
  paste0("T_C_", stringr::str_remove(subpractice.list, "_subpractice$"), "_practice")
)

fomd10.distribution1 <- fomd10.distribution %>%
  bind_cols(as_tibble(practice_cols))

sort(unique(fomd10.distribution1$T_C_tillage_practice))
sort(unique(fomd10.distribution1$T_C_planting_practice))
sort(unique(fomd10.distribution1$T_C_varietal_crop_practice))
sort(unique(fomd10.distribution1$T_C_varietal_animal_practice))
sort(unique(fomd10.distribution1$T_C_intercrop_practice))
sort(unique(fomd10.distribution1$T_C_crop_seq_practice))
sort(unique(fomd10.distribution1$T_C_agrof_practice))
sort(unique(fomd10.distribution1$T_C_fert_practice))
sort(unique(fomd10.distribution1$T_C_chem_practice))
sort(unique(fomd10.distribution1$T_C_residues_practice))
sort(unique(fomd10.distribution1$T_C_ph_practice))
sort(unique(fomd10.distribution1$T_C_irrig_practice))
sort(unique(fomd10.distribution1$T_C_watharv_practice))
sort(unique(fomd10.distribution1$T_C_harvest_practice))
sort(unique(fomd10.distribution1$T_C_postharvest_practice))

