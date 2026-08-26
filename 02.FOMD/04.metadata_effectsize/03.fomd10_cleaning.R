library(tibble)
library(readxl)
library(stringr)
library(dplyr)
library(tidyr)
library(metafor)
library(readr)
library(purrr)

# NOTE: There are rows that has the same practice for control and treatment

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
source(file.path(path.metadata.effectsize, "/fomd_fun/fun_lookup_ontologies.R"))

#==========================================================
# Read datasets
#==========================================================
#metadata<-"MD_Rosen_24_Effec_Sc" #Rosenstock et al. 2024. Effects of changing farming practices in African agriculture. 10.1038/s41597-024-03805-z 
metadata<-"MD_Paut,_24_A glo_Sc" #Paut et al. 2024. A global dataset of experimental intercropping and agroforestry studies in horticulture. 10.1038/s41597-023-02831-7

#---fomd10_formated
fomd10_formated <- read_csv(
  file.path(path.metadata.effectsize, "02.fomd10_formated", paste0("fomd10_formated_", metadata, ".csv")),
  show_col_types = FALSE)
  #select(study_id,C_exp_plot_size)

skim(fomd10_formated)


#==========================================================
# Put C_vs_T subpractices in one column for each practice type
# NOTE: There are rows that has the same subpractice for control and treatment
#==========================================================
fomd10.clean <- apply_CT_subpractie(fomd10_formated)

fomd10.clean <- apply_CT_renames_subpractice(fomd10.clean)

summarise_CT_subpractice(fomd10.clean)

#--- Quick checks ----
ct_subpractice_cols <- grep("^CT_.*_subpractice$", names(fomd10.clean), value = TRUE)

comparison_subpractice_list<-purrr::map(ct_subpractice_cols, \(col) {
  fomd10.clean %>%
    dplyr::filter(!is.na(.data[[col]])) %>%
    dplyr::count(column = col, value = .data[[col]], name = "n")
}) %>%
  dplyr::bind_rows()

#==========================================================
# Reclassify C_vs_T subpractices as C_vs_T practice 
# NOTE: There are rows that has the same practice for control and treatment
#==========================================================
fomd10.clean <- apply_CT_practice(fomd10.clean)

ct_practice_cols <- grep("_practice$", names(fomd10.clean), value = TRUE)

comparison_practice_list<-purrr::map(ct_practice_cols, \(col) {
  fomd10.clean %>%
    dplyr::filter(!is.na(.data[[col]])) %>%
    dplyr::count(column = col, value = .data[[col]], name = "n")
}) %>%
  dplyr::bind_rows()

#readr::write_csv(comparison_practice_list, paste0(path.metadata.effectsize, "/era_comparison_practice_list.csv"))

fomd10.clean <- apply_CT_renames_practice(fomd10.clean)

#==========================================================
# Reclassify C_vs_T subpractices as C_vs_T practice theme 
# NOTE: There are rows that has the same practice for control and treatment
#==========================================================
fomd10.clean <- apply_CT_practice_theme(fomd10.clean)

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

#--- Check outcome value information ----
for (col in c("variety_management_subpractice","variety_management_practice","variety_management_theme",                 
              "breed_animal_subpractice","breed_animal_practice","breed_animal_theme" ,                       
              "planting_management_subpractice","planting_management_practice" ,"planting_management_theme",                 
              "diversification_spatial_subpractice", "diversification_spatial_practice","diversification_spatial_theme",             
              "diversification_temporal_subpractice","diversification_temporal_practice","diversification_temporal_theme",            
              "soil_management_subpractice","soil_management_practice","soil_management_theme" ,                    
              "nutrient_management_subpractice" ,"nutrient_management_practice","nutrient_management_theme" ,               
              "pest_management_subpractice","pest_management_practice","pest_management_theme",                     
              "water_management_subpractice","water_management_practice","water_management_theme",
              "biomass_management_subpractice","biomass_management_practice","biomass_management_theme",                  
              "postharvest_subpractice","postharvest_practice" ,"postharvest_theme",                         
              "harvest_subpractice", "harvest_practice","harvest_theme"
              )) {
  cat("---", col, "---\n")
  print(sort(unique(fomd10.clean[[col]])))
}

prueba<-fomd10.clean%>%
  #Pest management-----
select(doi,study_id, C_chem_subpractice,T_chem_subpractice,
       CT_chem_subpractice,
       pest_management_subpractice,pest_management_practice ,pest_management_theme,
      # "practice_compared" ,                   "practice_compared_detail" ,            "practice_compared_n"
      )%>%
  filter(!is.na(pest_management_subpractice))%>%
  filter(is.na(pest_management_practice))
sort(unique(prueba$CT_chem_subpractice))

  #Soil management-----
select(doi, soil_management_subpractice,soil_management_practice ,soil_management_theme)%>%
      # "practice_compared" ,                   "practice_compared_detail" ,            "practice_compared_n")%>%
  filter(!is.na(soil_management_subpractice))%>%
  filter(is.na(soil_management_practice))


  # variety crop ----
  select(doi, C_varietal_crop_subpractice,T_varietal_crop_subpractice,
         CT_varietal_crop_subpractice,
         variety_management_subpractice ,variety_management_practice,variety_management_theme,
         "practice_compared" ,                   "practice_compared_detail" ,            "practice_compared_n")%>%
  filter(!is.na(variety_management_subpractice))%>%
  filter(is.na(variety_management_practice))
  #nutrient management ----
  select(doi, CT_fert_subpractice,CT_fert_practice,
         nutrient_management_subpractice ,nutrient_management_practice,nutrient_management_theme,
         "practice_compared" ,                   "practice_compared_detail" ,            "practice_compared_n")%>%
  filter(!is.na(nutrient_management_subpractice))%>%
  filter(is.na(nutrient_management_practice))

  
  # post-harvest practices
  select(doi, C_postharvest_subpractice,T_postharvest_subpractice,
         CT_postharvest_subpractice,postharvest_subpractice,
         postharvest_practice,harvest_theme,
         "practice_compared" ,                   "practice_compared_detail" ,            "practice_compared_n")%>%
  filter(!is.na(postharvest_subpractice))%>%
  filter(is.na(postharvest_practice))

  
  # harvest practices ----
  select(doi, C_harvest_subpractice,T_harvest_subpractice,
         CT_harvest_subpractice,harvest_subpractice,
         harvest_practice,harvest_theme,
         "practice_compared" ,                   "practice_compared_detail" ,            "practice_compared_n")%>%
  filter(!is.na(harvest_subpractice))%>%
  filter(is.na(harvest_practice))


  

sort(unique(prueba$CT_varietal_crop_subpractice))

  #Biomass management-----
select(doi, C_residues_subpractice_raw,T_residues_subpractice_raw,
       C_residues_material,T_residues_material,
       biomass_management_subpractice,biomass_management_practice ,biomass_management_theme,
       "practice_compared" ,                   "practice_compared_detail" ,            "practice_compared_n")%>%
  filter(!is.na(biomass_management_subpractice))%>%
  filter(is.na(biomass_management_practice))




sort(unique(prueba$practice_compared))
x<-prueba[grepl("Inorganic fertilizer", prueba$practice_compared, ignore.case = TRUE), ]

#Water management-----
select(doi, C_irrig_subpractice,
       water_management_subpractice,water_management_practice ,water_management_theme,
       "practice_compared" ,                   "practice_compared_detail" ,            "practice_compared_n")%>%
  filter(!is.na(water_management_subpractice))%>%
  filter(is.na(water_management_practice))

distinct(water_management_subpractice)
sort(unique(fomd10.clean$C_planting_subpractice))
sort(unique(fomd10.clean$C_planting_method))
  




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



  
#==========================================================
# Reclassify C and T crops and trees as FAO commodity 
#==========================================================
#--- Reclassifying C_crop_tree_diversity as C_crop_tree_FAO_Food_Group
fomd10.clean <- apply_lookup_commodity_group(
  df        = fomd10.clean,
  ref       = fomd01.crops.trees,
  key_col   = "crop_tree_diversity",
  value_col = "FAO.Food.Group",
  src_col   = "C_crop_tree_diversity",
  new_col   = "C_crop_tree_FAO_Food_Group"
)
sort(unique(fomd10.clean$C_crop_tree_FAO_Food_Group))

#--- Reclassifying T_crop_diversity as T_crop_FAO_Food_Group
fomd10.clean <- apply_lookup_commodity_group(
  df        = fomd10.clean,
  ref       = fomd01.crops.trees,
  key_col   = "crop_tree_diversity",
  value_col = "FAO.Food.Group",
  src_col   = "T_crop_tree_diversity",
  new_col   = "T_crop_tree_FAO_Food_Group"
)
sort(unique(fomd10.clean$T_crop_tree_FAO_Food_Group))

#--- Get the FAO_Food_Groups that are common in the C and T practices
fomd10.clean <- apply_CT_commodity_group_intersection(
  df      = fomd10.clean,
  col_C   = "C_crop_tree_FAO_Food_Group",
  col_T   = "T_crop_tree_FAO_Food_Group",
  new_col = "CT_crop_tree_FAO_Food_Group"
)

sort(unique(fomd10.clean$CT_crop_tree_FAO_Food_Group))

#--- Reclassifying C_crop_diversity as C_crop_FAO_Food_SubGroup
fomd10.clean <- apply_lookup_commodity_group(
  df        = fomd10.clean,
  ref       = fomd01.crops.trees,
  key_col   = "crop_tree_diversity",
  value_col = "FAO.Food.SubGroup",
  src_col   = "C_crop_tree_diversity",
  new_col   = "C_crop_tree_FAO_Food_SubGroup"
)
sort(unique(fomd10.clean$C_crop_tree_FAO_Food_SubGroup))

#--- Reclassifying T_crop_diversity as T_crop_FAO_Food_SubGroup
fomd10.clean <- apply_lookup_commodity_group(
  df        = fomd10.clean,
  ref       = fomd01.crops.trees,
  key_col   = "crop_tree_diversity",
  value_col = "FAO.Food.SubGroup",
  src_col   = "T_crop_tree_diversity",
  new_col   = "T_crop_tree_FAO_Food_SubGroup"
)
sort(unique(fomd10.clean$T_crop_tree_FAO_Food_SubGroup))

#--- Get the CT_crop_FAO_Food_SubGroup that are common in the C and T practices
fomd10.clean <- apply_CT_commodity_group_intersection(
  df      = fomd10.clean,
  col_C   = "C_crop_tree_FAO_Food_SubGroup",
  col_T   = "T_crop_tree_FAO_Food_SubGroup",
  new_col = "CT_crop_tree_FAO_Food_SubGroup"
)

sort(unique(fomd10.clean$CT_crop_tree_FAO_Food_SubGroup))

#==========================================================
#---- Match with 01_FOMD_ontologies ----
#==========================================================
#--- Reclassifying out_subindicator as effect_size_type
fomd10.clean <- apply_lookup_ontologies(
  df        = fomd10.clean,
  path.metadata.structure = path.metadata.structure,
  sheet_name       = "01_outcomes",
  key_col   = "subindicator",
  value_col = "effect_size_type",
  src_col   = "out_subindicator",
  new_col   = "out_effect_size_type"
)

x<-fomd10.clean %>%
  #select(doi,out_subindicator, out_effect_size) 
  distinct(out_subindicator, out_effect_size_type)%>%
  arrange(out_effect_size_type)
  filter(is.na(out_effect_size_type)) #93-73 out_subindicator with effect_size_type==NA

  
  
  
# ============================================================
# Get all unique individual crop commodity from both columns
# ============================================================
unmatched_crops <- bind_rows(
  fomd10.clean %>% 
    select(crop = C_crop_tree_diversity),
  fomd10.clean %>%
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
nrow(unmatched_crops) #16 crops missing Commodity reclassification

# ============================================================
#--------- Remove irrelevant columns ------------
# ============================================================
practices <- c("tillage", "planting", "varietal_crop", "varietal_animal",
               "intercrop", "crop_seq", "agrof", "fert", "chem",
               "residues", "ph", "irrig", "watharv", "postharvest", "harvest")

pattern <- paste0("^CT_(", paste(practices, collapse = "|"), ")_(subpractice|practice|practicetheme)$")


fomd10.clean<-fomd10.clean%>%
  select(-matches(pattern),
         -"n_focal_groups",-"is_bundled" ,                         
         -"has_variety_bg"  ,-"is_vet_chem" )


readr::write_csv(fomd10.clean, paste0(path.metadata.effectsize, "/fomd10_clean/fomd10_clean_MD_Rosen_24_Effec_Sc.csv"))






