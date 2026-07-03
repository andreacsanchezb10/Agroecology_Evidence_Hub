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
source(file.path(path.metadata.effectsize,"/fomd_fun/fun_comparison_practice.R"))
source(file.path(path.metadata.effectsize,"/fomd_fun/fun_lookup_commodities.R")) 
source(file.path(path.metadata.effectsize, "/fomd_fun/fun_analysis_practice.R"))

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

#nrow(comparison_practice_list) #199

#readr::write_csv(comparison_practice_list, paste0(path.metadata.effectsize, "/era_comparison_practice_list.csv"))

fomd10.clean <- apply_CT_renames(fomd10.clean)

#nrow(comparison_practice_list) #15-

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
# Reclassify C_vs_T subpractices as C_vs_T practice domain 
#==========================================================
fomd10.clean <- build_analytical_columns(fomd10.clean)
 names(fomd10.clean)
### REPORT
#Building analytical columns ...
#variety_management_subpractice            136,699 non-NA rows
#variety_management_practice               18,286 non-NA rows
#variety_management_theme                  18,286 non-NA rows

#breed_animal_subpractice                  21,291 non-NA rows
#breed_animal_practice                     0 non-NA rows
#breed_animal_theme                        0 non-NA rows
 
#planting_management_subpractice           12,995 non-NA rows
#planting_management_practice              5,578 non-NA rows
#planting_management_theme                 0 non-NA rows
 
#diversification_spatial_subpractice       10,236 non-NA rows
#diversification_spatial_practice          10,231 non-NA rows  ## TO CHECK: NEED TO FIX C_agrof_subpractice=="Open Communial Grazing Land
#diversification_spatial_theme             10,231 non-NA rows ## TO CHECK: NEED TO FIX C_agrof_subpractice=="Open Communial Grazing Land

#diversification_temporal_subpractice      24,576 non-NA rows
#diversification_temporal_practice         23,813 non-NA rows  ## TO CHECK: NEED TO FIX "C: Other Time Sequence_vs_T: Other Time Sequence"
#diversification_temporal_theme            23,813 non-NA rows  ## TO CHECK: NEED TO FIX "C: Other Time Sequence_vs_T: Other Time Sequence"

#soil_management_subpractice               33,997 non-NA rows 
#soil_management_practice                  33,997 non-NA rows # READY
#soil_management_theme                     33,997 non-NA rows # READY

#nutrient_management_subpractice           80,179 non-NA rows 
#nutrient_management_practice              80,179 non-NA rows # READY
#nutrient_management_theme                 79,098 non-NA rows

#pest_management_subpractice               18,999 non-NA rows
#pest_management_practice                  18,922 non-NA rows ## TO CHECK: NEED TO FIX "Other"
#pest_management_theme                     5,049 non-NA rows

#water_management_subpractice              47,291 non-NA rows 
#water_management_practice                 47,291 non-NA rows # READY
#water_management_theme                    47,291 non-NA rows # READY

#biomass_management_subpractice            44,163 non-NA rows
#biomass_management_practice               44,163 non-NA rows # READY
#biomass_management_theme                  5,662 non-NA rows




sort(unique(fomd10.clean$diversification_spatial_theme))
sort(unique(fomd10.clean$diversification_temporal_theme))

prueba0<-fomd10.clean%>%
  select(diversification_spatial_theme,
         diversification_temporal_theme)

prueba<-fomd10.clean%>%
  #Nutrient management -----

select(doi, 
       #C_ph_subpractice,T_ph_subpractice,
       #diversification_spatial_subpractice,
       nutrient_management_theme,
       C_fert_inorganic_type_amount_unit,
       #C_fert_inorganicN_amount_unit,
       #C_fert_inorganicP_amount_unit,
       #C_fert_inorganicK_amount_unit,
       #C_fert_inorganicP2O5_amount_unit,
       #C_fert_inorganicK2O_amount_unit,
       
       T_fert_inorganic_type_amount_unit,
       CT_fert_practice,
       #T_fert_inorganicN_amount_unit,
       #T_fert_inorganicP_amount_unit,
       #T_fert_inorganicK_amount_unit,
       #T_fert_inorganicP2O5_amount_unit,
       #T_fert_inorganicK2O_amount_unit,
       T_fert_subpractice,
       nutrient_management_subpractice,nutrient_management_practice ,nutrient_management_theme,
       "practice_compared" ,                   "practice_compared_detail" ,            "practice_compared_n")%>%
  filter(!is.na(nutrient_management_practice))%>%
  filter(is.na(nutrient_management_theme))
  filter(grepl("fertilizer",practice_compared, ignore.case = TRUE))
filter(nutrient_management_practice=="C: Inorganic Fertilizer_vs_T: Inorganic Fertilizer")
sort(unique(prueba$nutrient_management_practice))





  
  #Biomass management-----
select(doi, C_residues_subpractice_raw,T_residues_subpractice_raw,
       C_residues_material,T_residues_material,
       biomass_management_subpractice,biomass_management_practice ,biomass_management_theme,
       "practice_compared" ,                   "practice_compared_detail" ,            "practice_compared_n")%>%
  filter(!is.na(biomass_management_subpractice))%>%
  filter(is.na(biomass_management_practice))




sort(unique(prueba$practice_compared))
x<-prueba[grepl("Inorganic fertilizer", prueba$practice_compared, ignore.case = TRUE), ]



  #Pest management-----
select(doi, C_chem_subpractice,
       pest_management_subpractice,pest_management_practice ,pest_management_theme,
       "practice_compared" ,                   "practice_compared_detail" ,            "practice_compared_n")%>%
  filter(!is.na(pest_management_subpractice))%>%
  filter(is.na(pest_management_practice))



  #Water management-----
select(doi, C_irrig_subpractice,
       water_management_subpractice,water_management_practice ,water_management_theme,
       "practice_compared" ,                   "practice_compared_detail" ,            "practice_compared_n")%>%
  filter(!is.na(water_management_subpractice))%>%
  filter(is.na(water_management_practice))

distinct(water_management_subpractice)
sort(unique(fomd10.clean$C_planting_subpractice))
sort(unique(fomd10.clean$C_planting_method))
  



#Soil management-----
select(doi, soil_management_subpractice,soil_management_practice ,soil_management_theme,
       "practice_compared" ,                   "practice_compared_detail" ,            "practice_compared_n")%>%
  filter(!is.na(soil_management_subpractice))%>%
  filter(is.na(soil_management_practice))
#diversification spatial-----
  select(doi,study_id,country,
         C_crop_tree_diversity,T_crop_tree_diversity,
         diversification_spatial_subpractice,
         out_subindicator,C_subpractice_description_raw,T_subpractice_description_raw,C_out_value,T_out_value,
         C_data_location       ,T_data_location,
         
         diversification_spatial_practice ,diversification_spatial_theme,
         "practice_compared" ,                   "practice_compared_detail" ,            "practice_compared_n")%>%
  filter(study_id=="AC0157")

  filter(doi=="10.1007/s10457-018-0304-9")
  
  filter(!is.na(diversification_spatial_subpractice))%>%
  filter(grepl("T: Monoculture",diversification_spatial_practice, ignore.case = TRUE))%>%
  filter(country=="Ethiopia")

  filter(is.na(diversification_spatial_practice))
  distinct(diversification_spatial_practice,diversification_spatial_theme)
  sort(unique(prueba$diversification_spatial_subpractice))
  sort(unique(prueba$doi))
  
  
#diversification temporal-----
  #select(doi, diversification_temporal_subpractice,diversification_temporal_practice ,diversification_temporal_theme,
  #      "practice_compared" ,                   "practice_compared_detail" ,            "practice_compared_n")%>%
  #filter(!is.na(diversification_temporal_subpractice))%>%
  #filter(is.na(diversification_temporal_practice))
#Planting management #Poner methods en methods, y subpractices en subpractices
select(doi, C_planting_method,T_planting_method,
       planting_management_subpractice,planting_management_practice ,planting_management_theme,
       "practice_compared" ,                   "practice_compared_detail" ,            "practice_compared_n")%>%
  filter(!is.na(planting_management_subpractice))%>%
  filter(is.na(planting_management_practice))

x<-prueba[grepl("planting", prueba$practice_compared, ignore.case = TRUE), ]


  
#==========================================================
# Reclassify C and T crops and trees as FAO commodity 
# NOTE: There are rows that has the same practice for control and treatment
#==========================================================
#--- Reclassifying C_crop_diversity as C_crop_FAO_Food_Group
fomd10.clean <- apply_lookup_commodity_group(
  df        = fomd10.clean,
  ref       = fomd01.crops.trees,
  key_col   = "crop_tree_diversity",
  value_col = "FAO.Food.Group",
  src_col   = "C_crop_tree_diversity",
  new_col   = "C_crop_FAO_Food_Group"
)
sort(unique(fomd10.clean$C_crop_FAO_Food_Group))

#--- Reclassifying T_crop_diversity as T_crop_FAO_Food_Group
fomd10.clean <- apply_lookup_commodity_group(
  df        = fomd10.clean,
  ref       = fomd01.crops.trees,
  key_col   = "crop_tree_diversity",
  value_col = "FAO.Food.Group",
  src_col   = "T_crop_tree_diversity",
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

#--- Reclassifying C_crop_diversity as C_crop_FAO_Food_SubGroup
fomd10.clean <- apply_lookup_commodity_group(
  df        = fomd10.clean,
  ref       = fomd01.crops.trees,
  key_col   = "crop_tree_diversity",
  value_col = "FAO.Food.SubGroup",
  src_col   = "C_crop_tree_diversity",
  new_col   = "C_crop_FAO_Food_SubGroup"
)
sort(unique(fomd10.clean$C_crop_FAO_Food_SubGroup))

#--- Reclassifying T_crop_diversity as T_crop_FAO_Food_SubGroup
fomd10.clean <- apply_lookup_commodity_group(
  df        = fomd10.clean,
  ref       = fomd01.crops.trees,
  key_col   = "crop_tree_diversity",
  value_col = "FAO.Food.SubGroup",
  src_col   = "T_crop_tree_diversity",
  new_col   = "T_crop_FAO_Food_SubGroup"
)
sort(unique(fomd10.clean$T_crop_FAO_Food_SubGroup))

#--- Get the CT_crop_FAO_Food_SubGroup that are common in the C and T practices
fomd10.clean <- apply_CT_commodity_group_intersection(
  df      = fomd10.clean,
  col_C   = "C_crop_FAO_Food_SubGroup",
  col_T   = "T_crop_FAO_Food_SubGroup",
  new_col = "CT_crop_FAO_Food_SubGroup"
)

sort(unique(fomd10.clean$CT_crop_FAO_Food_SubGroup))

# ============================================================
# Get all unique individual crop commodity from both columns
# ============================================================
unmatched_crops <- bind_rows(
  fomd10.clean %>% 
    #filter(country=="Ethiopia")%>%
    select(crop = C_crop_tree_diversity),
  fomd10.clean %>%
    #filter(country=="Ethiopia")%>%
    
    select(crop = T_crop_tree_diversity)
) %>%
  # Split compound strings into individual tokens
  mutate(crop = str_split(crop, "[-/]")) %>%
  unnest(crop) %>%
  mutate(crop = str_squish(crop)) %>%
  filter(!is.na(crop), crop != "NA", crop != "") %>%
  distinct(crop) %>%
  # Left join to the reference to find what's missing
  left_join(
    fomd01.crops.trees %>% select(crop_tree_diversity, FAO.Food.Group),
    by = c("crop" = "crop_tree_diversity")
  ) %>%
  filter(is.na(FAO.Food.Group)) %>%
  arrange(crop)

print(unmatched_crops)
nrow(unmatched_crops) #107-105-97 crops missing Commodity reclassification

readr::write_csv(fomd10.clean, paste0(path.metadata.effectsize, "/fomd10_clean/fomd10_clean_MD_Rosen_24_Effec_Sc.csv"))




subpractice.list<-c(
  "tillage_subpractice", #soil_management_practice READY
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





