library(tibble)
library(readxl)
library(stringr)
library(dplyr)
library(tidyr)
library(metafor)
library(readr)

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

sort(unique(fomd01.practices$practice_subtype))
#---fomd10.effectsize
fomd10.comparison<-read_csv(file.path(path.metadata.effectsize,"fomd10_comparison.csv"), show_col_types = FALSE)



sort(unique(fomd10.comparison$C_subpractice))
sort(unique(fomd10.comparison$T_subpractice))
sort(unique(fomd10.comparison$C_tillage_subpractice))
sort(unique(fomd10.comparison$T_tillage_subpractice))

#==========================================================
# Fix practices, subpractices
# There are rows that has the same subpractice for control and treatment
# We need to remove those for subpractice comparison
#==========================================================
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

split_subpractice <- function(x) {
  if (is.na(x) || x == "") return(character(0))
  
  parts <- str_split(x, "-", simplify = FALSE)[[1]] %>%
    str_trim()
  
  parts <- parts[parts != ""]
  
  unique(parts)
}

fomd10.subpractice.clean <- fomd10.comparison

fomd10.subpractice.clean$T_subpractice <- apply(fomd10.subpractice.clean, 1, function(x) {
  out <- c()
  
  for (col in subpractice.list) {
    c_val <- x[[paste0("C_", col)]]
    t_val <- x[[paste0("T_", col)]]
    
    # skip this practice if one side is missing
    if (is.na(c_val) || is.na(t_val)) next
    
    c_parts <- split_subpractice(c_val)
    t_parts <- split_subpractice(t_val)
    
    t_diff <- setdiff(t_parts, c_parts)
    
    if (length(t_diff) > 0) {
      out <- c(out, t_diff)
    }
  }
  
  out <- unique(out)
  
  if (length(out) == 0) NA_character_ else paste(out, collapse = " - ")
})

fomd10.subpractice.clean$C_subpractice <- apply(fomd10.subpractice.clean, 1, function(x) {
  out <- c()
  
  for (col in subpractice.list) {
    c_val <- x[[paste0("C_", col)]]
    t_val <- x[[paste0("T_", col)]]
    
    # skip this practice if one side is missing
    if (is.na(c_val) || is.na(t_val)) next
    
    c_parts <- split_subpractice(c_val)
    t_parts <- split_subpractice(t_val)
    
    c_diff <- setdiff(c_parts, t_parts)
    
    if (length(c_diff) > 0) {
      out <- c(out, c_diff)
    }
  }
  
  out <- unique(out)
  
  if (length(out) == 0) NA_character_ else paste(out, collapse = " - ")
})

subpractice.clean.pairs <- fomd10.subpractice.clean %>%
  distinct(study_id, C_subpractice, T_subpractice) %>%
  arrange(C_subpractice, T_subpractice)

#==========================================================
# Clean practice_type practice_subtype practice_
#==========================================================
library(tibble)
library(purrr)

#--- lookup vector:  values = practice_subtype
lookup.practice.subtype <- fomd01.practices %>%
  transmute(
    subpractice = str_squish(subpractice),
    practice_subtype    = str_squish(practice_subtype)
  ) %>%
  distinct() %>%
  deframe()


fomd10.practice.clean <- fomd10.subpractice.clean %>%

  #---practice_subtype
  mutate(practice_subtype = map_chr(str_split(str_squish(T_subpractice), "-"), \(x) {
    out <- unname(lookup.practice.subtype[str_squish(x)])
    # if something didn't match, keep the original token (change to NA if you prefer)
    out[is.na(out)] <- str_squish(x)[is.na(out)]
    paste(out, collapse = "-")
  }))

sort(unique(fomd10.practice.clean$practice_subtype))

practice.subtype.clean.pairs <- fomd10.practice.clean %>%
  distinct(study_id, C_subpractice, T_subpractice,practice_subtype) %>%
  arrange(C_subpractice, T_subpractice,practice_subtype)

readr::write_csv(fomd10.practice.clean, paste0(path.metadata.effectsize, "/fomd10_comparison_clean.csv"))

