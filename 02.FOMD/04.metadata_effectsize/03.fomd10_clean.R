library(tibble)
library(readxl)
library(stringr)
library(dplyr)
library(tidyr)
library(metafor)
library(readr)
library(purrr)

path.metadata.structure<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/02.metadata_structure"
path.metadata.effectsize<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/04.metadata_effectsize"

list.files(path.metadata.structure)
list.files(path.metadata.effectsize)


#==========================================================
# Read functions
#==========================================================
#source(file.path(path.metadata.effectsize,"/fomd_fun/fun_lookup_ontologies.R")) #Not sure if i'm going to use this here, TO CHECK
#source(file.path(path.metadata.effectsize,"/fomd_fun/fun_load_data_ontologies.R"))
source(file.path(path.metadata.effectsize,"/fomd_fun/fun_comparison_practice.R"))
source(file.path(path.metadata.effectsize,"/fomd_fun/fun_lookup_commodities.R")) 

#---fomd10
fomd10<-read_csv(file.path(path.metadata.effectsize,"/fomd10/fomd10_MD_Rosen_24_Effec_Sc.csv"), show_col_types = FALSE)

sort(unique(fomd10$C_tillage_subpractice))
sort(unique(fomd10$T_tillage_subpractice))

#==========================================================
# Put C_vs_T subpractices in one column for each practice type
# NOTE: There are rows that has the same subpractice for control and treatment
#==========================================================
fomd10.clean <- apply_CT_subpractie(fomd10)

summarise_CT_subpractice(fomd10.clean)

# Quick checks
sort(unique(fomd10.clean$CT_tillage_subpractice))
sort(unique(fomd10.clean$CT_varietal_crop_subpractice))

# Diversitication (spatial and temporal)
sort(unique(fomd10.clean$CT_intercrop_subpractice))
sort(unique(fomd10.clean$CT_intercrop_subpractice))

sort(unique(fomd10.clean$CT_agrof_subpractice))
sort(unique(fomd10.clean$CT_crop_seq_subpractice))

sort(unique(fomd10.clean$CT_fert_subpractice))
sort(unique(fomd10.clean$CT_chem_subpractice))
sort(unique(fomd10.clean$CT_residues_subpractice))
sort(unique(fomd10.clean$CT_ph_subpractice))
sort(unique(fomd10.clean$CT_irrig_subpractice))

#==========================================================
# Reclassify C_vs_T subpractices as C_vs_T practice 
# NOTE: There are rows that has the same practice for control and treatment
#==========================================================
fomd10.clean <- apply_CT_practice(fomd10.clean)

sort(unique(fomd10.clean$CT_intercrop_practice))
sort(unique(fomd10.clean$CT_intercrop_subpractice))
ct_practice_cols <- grep("_practice$", names(fomd10.clean), value = TRUE)

comparison_practice_list<-purrr::map(ct_practice_cols, \(col) {
  fomd10.clean %>%
    dplyr::filter(!is.na(.data[[col]])) %>%
    dplyr::count(column = col, value = .data[[col]], name = "n")
}) %>%
  dplyr::bind_rows()

nrow(comparison_practice_list) #155

#readr::write_csv(comparison_practice_list, paste0(path.metadata.effectsize, "/era_comparison_practice_list.csv"))

fomd10.clean <- apply_CT_renames(fomd10.clean)

nrow(comparison_practice_list) #152

prueba<-fomd10.clean%>%
  select(doi,C_crop_diversity,T_crop_diversity,
         C_agrof_subpractice,T_agrof_subpractice,
         C_intercrop_subpractice,T_intercrop_subpractice,
         CT_agrof_practice,CT_intercrop_practice,
         "practice_compared","practice_compared_detail", "practice_compared_n",
         CT_crop_seq_practice)%>%
  filter(doi=="10.1080/01448765.1991.9754573")
filter(!is.na(CT_agrof_practice)&!is.na(CT_intercrop_practice))

sort(unique(prueba$doi))

#==========================================================
# Reclassify C_vs_T subpractices as C_vs_T practice theme 
# NOTE: There are rows that has the same practice for control and treatment
#==========================================================
fomd10.clean <- apply_CT_practice_theme(fomd10.clean)

sort(unique(fomd10.clean$CT_intercrop_practicetheme)) #17 with the new code

sort(unique(fomd10.clean$CT_agrof_practicetheme))
sort(unique(fomd10.clean$CT_intercrop_practicetheme))

ct_theme_cols <- grep("_practicetheme$", names(fomd10.clean), value = TRUE)

comparison_practicetheme_list<-purrr::map(ct_theme_cols, \(col) {
  fomd10.clean %>%
    dplyr::filter(!is.na(.data[[col]])) %>%
    dplyr::count(column = col, value = .data[[col]], name = "n")
}) %>%
  dplyr::bind_rows()


#==========================================================
# Reclassify C and T crops and trees as FAO commodity 
# NOTE: There are rows that has the same practice for control and treatment
#==========================================================
#--- Reclassifying C_crop_diversity as C_crop_FAO_Food_Group
fomd10.clean <- apply_lookup_commodity_group(
  df        = fomd10.clean,
  ref       = fomd01.crops.trees,
  key_col   = "plants",
  value_col = "FAO.Food.Group",
  src_col   = "C_crop_diversity",
  new_col   = "C_crop_FAO_Food_Group"
)
sort(unique(fomd10.clean$C_crop_FAO_Food_Group))

#--- Reclassifying T_crop_diversity as T_crop_FAO_Food_Group
fomd10.clean <- apply_lookup_commodity_group(
  df        = fomd10.clean,
  ref       = fomd01.crops.trees,
  key_col   = "plants",
  value_col = "FAO.Food.Group",
  src_col   = "T_crop_diversity",
  new_col   = "T_crop_FAO_Food_Group"
)
sort(unique(fomd10.clean$T_crop_FAO_Food_Group))

#--- Get the FAO_Food_Groups that are common in the C and T practices
fomd10.clean <- apply_CT_commodity_group_intersection(
  df      = fomd10.clean,
  col_C   = "C_crop_FAO_Food_Group",
  col_T   = "T_crop_FAO_Food_Group",
  new_col = "CT_crop_FAO_Food_Group"
)

sort(unique(fomd10.clean$CT_crop_FAO_Food_Group))

# ============================================================
# Get all unique individual crop tokens from both columns
# ============================================================
unmatched_crops <- bind_rows(
  fomd10.clean %>% 
    select(crop = C_crop_diversity),
  fomd10.clean %>% 
    select(crop = T_crop_diversity)
) %>%
  # Split compound strings into individual tokens
  mutate(crop = str_split(crop, "[-/]")) %>%
  unnest(crop) %>%
  mutate(crop = str_squish(crop)) %>%
  filter(!is.na(crop), crop != "NA", crop != "") %>%
  distinct(crop) %>%
  # Left join to the reference to find what's missing
  left_join(
    fomd01.crops.trees %>% select(plants, FAO.Food.Group),
    by = c("crop" = "plants")
  ) %>%
  filter(is.na(FAO.Food.Group)) %>%
  arrange(crop)

print(unmatched_crops)
nrow(unmatched_crops) #107-105 crops missing Commodity reclassification

readr::write_csv(fomd10.clean, paste0(path.metadata.effectsize, "/fomd10_clean/fomd10_clean_MD_Rosen_24_Effec_Sc.csv"))



###########################################################
#NEXT STEPS: Create a column for diversification spatial comparison, diversification temporal comparison and so on...
# RECLASIFY CROPS AND PRODUCTS...

prueba<-diagnose_CT_missing_practice(fomd10.clean)%>%
  filter(source_col=="CT_crop_seq_subpractice")
sort(unique(prueba$source_col))
sort(unique(prueba$CT_subpractice))

prueba0<-fomd10.clean0%>%
  #filter(country=="Ethiopia")%>%
select(doi,
       #C_crop_diversity,T_crop_diversity, 
       
       #C_tree_diversity,T_tree_diversity,
       CT_intercrop_subpractice,CT_intercrop_practice,
       CT_intercrop_practicetheme,
       #CT_crop_seq_subpractice,CT_crop_seq_practice,
       CT_agrof_subpractice,CT_agrof_practice,
       
       "practice_compared","practice_compared_detail", "practice_compared_n")
  
    mutate(
      
      diversitication_spatial= case_when(
        C_intercrop_subpractice !=T_intercrop_subpractice~paste0("Intercroppin: ",CT_intercrop_practice),TRUE~NA))%>%
  
  select(C_intercrop_subpractice,T_intercrop_subpractice,CT_intercrop_practice,diversitication_spatial)
        
        paste0("Intercroppin: ",CT_intercrop_practice,"Agroforestry: ",CT_agrof_practice),
      
      diversitication_spatial=case_when(
      C_intercrop_practice ==T_intercrop_practice~""
    )
  )
  
  
  #filter(str_detect(CT_intercrop_practice, "Agroforestry"))%>%
  #filter(CT_intercrop_practice=="C: Crop Rotation (N fixing mixed)_vs_T: Crop Rotation (N fixing mixed)")
  
  select(doi,
         #C_crop_diversity,T_crop_diversity, 
         
         #C_tree_diversity,T_tree_diversity,
         CT_intercrop_subpractice,CT_intercrop_practice,
         CT_crop_seq_subpractice,CT_crop_seq_practice,
         CT_agrof_subpractice,CT_agrof_practice,
         
         "practice_compared","practice_compared_detail", "practice_compared_n")
sort(unique(prueba0$doi))



sort(unique(fomd10.clean$C_intercrop_subpractice))

# Get the CT_ subpractice column names
ct_cols <- grep("^CT_.*_subpractice$", names(prueba), value = TRUE)

# Check if any row has NA in ALL CT_ subpractice columns
all_na_rows <- prueba %>%
  filter(if_all(all_of(ct_cols), is.na))

# View the count and the rows
nrow(all_na_rows)#35798-32259-32730-32645
all_na_rows




################



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

