library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(readr)
library(stringdist)

path.metadata.structure<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/02.metadata_structure/"
path.metadata.effectsize<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/04.metadata_effectsize/"

list.files(path.metadata.structure)
list.files(path.metadata.effectsize)

## TO DO: quitar de environment las funciones irrelevantes para este codigo

#==========================================================
# Read functions
#==========================================================
source(file.path(path.metadata.effectsize,"/fomd_fun/fun_fomd09_verified_combined.R"))
source(file.path(path.metadata.effectsize,"/fomd_fun/fun_fomd09_cleaning.R"))
source(file.path(path.metadata.effectsize,"/fomd_fun/fun_lookup_ontologies.R"))

#==========================================================
# Read datasets
#==========================================================
metadata<-"MD_Paut,_24_A glo_Sc" #Paut et al. 2024. A global dataset of experimental intercropping and agroforestry studies in horticulture. 10.1038/s41597-023-02831-7
#metadata<-"MD_Jones_21_A glo_Sc" #Jones et al. 2021. A global database of diversified farming effects on biodiversity and yield. 10.1038/s41597-021-01000-y

#--- Check that every verified-paper .xlsm in a subfolder shares the same columns
check_09FOMD_column_consistency(subfolder = metadata)


#---Combined verified studies from metadata sub folder
fomd09 <- combine_09FOMD_verified(subfolder = metadata)
names(fomd09)
#==============================================
#---- Cleaning the dataset ----
#==============================================
#---- Convert to specify class ----
fomd09.clean <- clean_fomd09_classes(fomd09)

#---- Add bibliographic information from (04_FOMD_screening) ----
fomd09.clean <- add_fomd09_bibliographic(fomd09.clean, path.metadata.structure, metadata)

#---- Add location information ----
fomd09.clean <- add_fomd09_location(fomd09.clean)

#sort(unique(fomd09.clean$study_id[fomd09.clean$site_latlong_type =="Unespecified"]))

#--- Check experiment details ----
for (col in c("exp_design", "exp_plot_size", "exp_field_size", "exp_duration")) {
  cat("---", col, "---\n")
  print(sort(unique(fomd09.clean[[col]])))
}

#--- Check experiment time details ----
for (col in c("time_raw", "time_year_start", "time_year_end", "time_season")) {
  cat("---", col, "---\n")
  print(sort(unique(fomd09.clean[[col]])))
}
#sort(unique(fomd09.clean$study_id[fomd09.clean$system_type==      "natural/seminatural"                                  ]))

#--- Check subpractice details ----
for (col in c("subpractice_description_raw", "system_type")) {
  cat("---", col, "---\n")
  print(sort(unique(fomd09.clean[[col]])))
}

#--- Add commodity crop, livestock, fish ----
fomd09.clean <- add_fomd09_commodity(fomd09.clean)

unmatched_crops <- find_unmatched_crops(fomd09.clean, path.metadata.effectsize)

#sort(unique(fomd09.clean$practice_id[fomd09.clean$crop_tree_variety  =="Pineapple(Unspecified)-Inga edulis(NA)"]))
#sort(unique(fomd09.clean$practice_id[fomd09.clean$crop_tree_variety  =="Maize(Unspecified)/"]))

#-- check if unmached_crops are because of mispealing
fomd01.crops.trees <- local({
  source(file.path(path.metadata.effectsize, "fomd_fun/fun_load_data_ontologies.R"), local = environment())
  
  rbind(
    fomd01.product.new %>%
      filter(!is.na(Product.Simple)) %>%
      distinct(Product.Simple, SPAM.Food.Group, FAO.Food.SubGroup, FAO.Food.Group) %>%
      rename("crop_tree_diversity" = "Product.Simple") %>%
      filter(!is.na(FAO.Food.Group), !is.na(crop_tree_diversity)),
    
    fomd01.vars.crops %>%
      distinct(V.Product, SPAM.Food.Group, FAO.Food.SubGroup, FAO.Food.Group) %>%
      rename("crop_tree_diversity" = "V.Product") %>%
      filter(!is.na(FAO.Food.Group)),
    
    fomd01.trees %>%
      select(tree.latin.name, Tree.Nfix, Tree.Legume) %>%
      rename("crop_tree_diversity" = "tree.latin.name",
             "FAO.Food.SubGroup" = "Tree.Legume",
             "FAO.Food.Group" = "Tree.Nfix") %>%
      mutate(FAO.Food.SubGroup = case_when(FAO.Food.SubGroup == "Yes" ~ "Legume Tree", TRUE ~ "No Legume Tree"),
             FAO.Food.Group = case_when(FAO.Food.Group == "Yes" ~ "N Fix Tree", TRUE ~ "No N Fix Tree"),
             SPAM.Food.Group = "Trees") %>%
      distinct(crop_tree_diversity, FAO.Food.SubGroup, FAO.Food.Group, SPAM.Food.Group)
  ) %>%
    distinct(crop_tree_diversity, SPAM.Food.Group, FAO.Food.SubGroup, FAO.Food.Group) %>%
    arrange(crop_tree_diversity)
})

ontology_crops <- fomd01.crops.trees$crop_tree_diversity

reason_unmatched_crops<-unmatched_crops %>%
  rowwise() %>%
  mutate(
    closest_match = ontology_crops[amatch(crop, ontology_crops, maxDist = Inf)],
    edit_distance = stringdist(crop, closest_match, method = "dl")
  ) %>%
  ungroup() %>%
  arrange(edit_distance)

fomd09.clean %>%
  filter(if_any(matches("^crop_tree0[0-9]+$"), ~ .x == "Musa sp.")) %>%
  distinct(study_id, practice_id)

fomd09.clean %>%
  filter(if_any(matches("^product0[0-9]+$"), ~ .x == "Native legumes")) %>%
  distinct(study_id, practice_id)

#--- Check tillage practice---- 
for (col in c("tillage_subpractice_raw", "tillage_subpractice","tillage_method",
              "tillage_method_other","tillage_depth","tillage_frequency"
)) {
  cat("---", col, "---\n")
  print(sort(unique(fomd09.clean[[col]])))
}

#sort(unique(fomd09.clean$study_id[fomd09.clean$tillage_subpractice  =="Reduced or Minimum Tillage..Conventional tillage"]))

#--- Check planting practice----
for (col in c("planting_subpractice_raw", "planting_subpractice","planting_method",
              "planting_date_start","planting_date_end"
)) {
  cat("---", col, "---\n")
  print(sort(unique(fomd09.clean[[col]])))
}

#---- Add improved crop varieties information ----
fomd09.clean <- add_fomd09_varietal(fomd09.clean,  prefix = "varietal_crop",   variety_suffix = "variety")
#sort(unique(fomd09.clean$study_id[fomd09.clean1$varietal_crop_variety == "Fava Bean(Badï)"]))

#---- Add improved animal breed information ----
fomd09.clean <- add_fomd09_varietal(fomd09.clean, prefix = "varietal_animal", variety_suffix = "breed")

#--- Check intercropping practice ----
for (col in c("intercrop_subpractice_raw", "intercrop_subpractice","intercrop_design",
              "intercrop_pattern","intercrop_start_year","intercrop_start_season","intercrop_residues_fate"
)) {
  cat("---", col, "---\n")
  print(sort(unique(fomd09.clean[[col]])))
}

#sort(unique(fomd09.clean$study_id[fomd09.clean$intercrop_start_season =="Long rainiy season"]))

#--- Add crop sequence practice information ----
fomd09.clean <- collapse_fomd09_columns(
  fomd09.clean,
  prefix = "crop_seq_subpractice0",
  sep = "..",
  dedupe = TRUE)

for (col in c("crop_seq_subpractice_raw","crop_seq_start_year","crop_seq_start_season",
              "crop_seq_residues_fate"
)) {
  cat("---", col, "---\n")
  print(sort(unique(fomd09.clean[[col]])))
}

#--- Add agroforestry practice information----
sort(unique(fomd09.clean$agrof_subpractice_raw))
fomd09.clean <- collapse_fomd09_columns(
  fomd09.clean,
  cols = c("agrof_spatial_arrangement_subpractice", "agrof_components_subpractice", "agrof_shade_subpractice"),
  new_col = "agrof_subpractice",
  sep = "..",
  dedupe = TRUE
)

fomd09.clean <- add_fomd09_mean_min_max(fomd09.clean,  prefix = "agrof_shade")
fomd09.clean <- add_fomd09_mean_min_max(fomd09.clean, prefix = "agrof_canopy_height")
fomd09.clean <- add_fomd09_mean_min_max(fomd09.clean, prefix = "agrof_dhb")

#sort(unique(fomd09.clean$study_id[fomd09.clean$agrof_shade_mean_min_max   =="29(NA-NA)"]))

#--- Add nutrient management practice (inorganic) information ----
fomd09.clean <- add_fomd09_fert_inorganic(fomd09.clean)

#sort(unique(fomd09.clean$study_id[fomd09.clean$fert_inorganic_type_amount_unit     =="Urea[20(kg/ha)]..Super phosphate[40(kg/ha)]..muriate of potash[40(kg/ha)]"]))

#--- Add nutrient management practice (organic) information ----
fomd09.clean <- add_fomd09_fert_organic(fomd09.clean)

#sort(unique(fomd09.clean$study_id[fomd09.clean$fert_organic_type_amount_unit  =="Unspecified Manure[0(t/ha)]" ]))

#---Add weeding management moderator information----
fomd09.clean <- add_fomd09_weed(fomd09.clean)

#---Add chemical management practice information ----
fomd09.clean <- add_fomd09_chem(fomd09.clean)
sort(unique(fomd09.clean$study_id[fomd09.clean$chem_name_amount_unit   =="NA[0(NA)]" ]))
sort(unique(fomd09.clean$practice_id[fomd09.clean$chem_name_amount_unit   =="NA[0(NA)]" ]))

#---Add residues management practice information ----
sort(unique(fomd09.clean$residues_subpractice_raw))
fomd09.clean <- collapse_fomd09_columns(fomd09.clean,  prefix = "residues_subpractice0")

fomd09.clean <- add_fomd09_residues(fomd09.clean)

#--- Add pH amendment practice information ----
fomd09.clean <- fomd09.clean %>%
  mutate(
    ph_amount_unit         = combine_amount_unit(ph_material_amount, ph_material_unit),
    ph_material_amount_unit = purrr::map2_chr(ph_material_applied, ph_amount_unit, combine_ph_material_amount_unit)
  )

for (col in c("ph_subpractice_raw", "ph_subpractice","ph_material_amount_unit"
)) {
  cat("---", col, "---\n")
  print(sort(unique(fomd09.clean[[col]])))
}

#--- Add irrigation practice information ----
fomd09.clean <- fomd09.clean %>%
  mutate(
    irrig_water_amount_unit  = combine_amount_unit(irrig_water_amount, irrig_water_unit),
  )

for (col in c("irrig_subpractice_raw", "irrig_subpractice","irrig_method",
              "irrig_date_start", "irrig_date_end","irrig_water_amount_unit",
              "irrig_water_type"
)) {
  cat("---", col, "---\n")
  print(sort(unique(fomd09.clean[[col]])))
}

#---Add water harvesting  practice information ----
sort(unique(fomd09.clean$watharv_subpractice_raw))
fomd09.clean <- collapse_fomd09_columns(fomd09.clean,  prefix = "watharv_subpractice0")

#--- Check harvesting practice information ----
for (col in c("harvest_subpractice_raw", "harvest_subpractice","harvest_date_start",
              "harvest_date_end","harvest_days_after_planting"
)) {
  cat("---", col, "---\n")
  print(sort(unique(fomd09.clean[[col]])))
}

#--- Add postharvesting practice information ----
fomd09.clean <- collapse_fomd09_columns(fomd09.clean,  prefix = "postharvest_subpractice0")

for (col in c("postharvest_subpractice_raw", "postharvest_subpractice","postharvest_date_start",
              "postharvest_date_end","postharvest_days_after_storage"
)) {
  cat("---", col, "---\n")
  print(sort(unique(fomd09.clean[[col]])))
}

#--- Check land structure management practice information ----
for (col in c("land_structure_subpractice_raw", "land_structure_subpractice","land_structure_function",
              "land_structure_origin","land_structure_manage"
)) {
  cat("---", col, "---\n")
  print(sort(unique(fomd09.clean[[col]])))
}

#--- Check outcome experimental design information ----
for (col in c("out_exp_design", "out_exp_plot_size"
)) {
  cat("---", col, "---\n")
  print(sort(unique(fomd09.clean[[col]])))
}

#sort(unique(fomd09.clean$study_id[fomd09.clean$out_exp_plot_size   =="NA" ]))

#--- Add product information ----
fomd09.clean <- collapse_fomd09_columns(fomd09.clean, prefix = "product0", sep = "..")

for (col in c("product", "econ_inputs", "bio_func_group", "bio_ground_ref"
              
)) {
  cat("---", col, "---\n")
  print(sort(unique(fomd09.clean[[col]])))
}

unmatched_products <- find_unmatched_products(fomd09.clean, path.metadata.structure)

#sort(unique(fomd09.clean$study_id[fomd09.clean$product01   =="Maize Core"]))

#--- Check subindicator information ----
for (col in c("out_subindicator", "out_subindicator_unit",
              "out_soil_depth_l", "out_soil_depth_u",
              "out_soil_depth_u",	"out_npv_discount_rate",
              "out_npv_econ_period",	"out_wg_start",	
              "out_wg_start_unit",	"out_wg_days",
              "out_comparison_treatment"
              
)) {
  cat("---", col, "---\n")
  print(sort(unique(fomd09.clean[[col]])))
}

#sort(unique(fomd09.clean$study_id[fomd09.clean$out_subindicator =="Shannon Index" ]))

#--- Check outcome value information ----
for (col in c("out_value_metric", "out_value",
              "out_var_metric", "out_var_value",
              "outc_var_value_l",	"outc_var_value_u",
              "out_sample_size"
              
)) {
  cat("---", col, "---\n")
  print(sort(unique(fomd09.clean[[col]])))
}

#--- Check outcome LER information ----
for (col in c("out_value_product01", "out_var_value_product01",
              "out_value_product02", "out_var_value_product02",
              "out_value_product03",	"out_var_value_product03",
              "out_value_product04","out_var_value_product04",
              
              "out_value_product05", "out_var_value_product05",
              "pler_value_product01", "pler_var_value_product01",
              "pler_value_product02",	"pler_var_value_product02",
              "pler_value_product03","pler_var_value_product03",
              "ler_value_total","ler_var_value_total"
)) {
  cat("---", col, "---\n")
  print(sort(unique(fomd09.clean[[col]])))
}					

#sort(unique(fomd09.clean$study_id[fomd09.clean$out_var_value_product01    =="unspecified" ]))

#--- Check outcome value information ----
for (col in c("data_location", "out_agg_stat",
              "out_year", "out_year_start",
              "out_year_end",	"out_season_start",
              "out_season_end"
              
)) {
  cat("---", col, "---\n")
  print(sort(unique(fomd09.clean[[col]])))
}

#==========================================================
#---- Match with 01_FOMD_ontologies ----
#==========================================================
library(tibble)
library(purrr)

#source(file.path(path.metadata.effectsize,"/fomd_fun/fun_lookup_ontologies.R"))

#--- Reclassifying out_subindicator as out_indicator
fomd09.clean <- apply_lookup_ontologies(
  df        = fomd09.clean,
  path.metadata.structure = path.metadata.structure,
  sheet_name = "01_outcomes",
  key_col   = "subindicator",
  value_col = "indicator",
  src_col   = "out_subindicator",
  new_col   = "out_indicator",
  sep=".."
)

#--- Reclassifying out_subindicator as out_subpillar
fomd09.clean <- apply_lookup_ontologies(
  df= fomd09.clean,
  path.metadata.structure,
  sheet_name = "01_outcomes",
  key_col   = "subindicator",
  value_col = "subpillar",
  src_col   = "out_subindicator",
  new_col   = "out_subpillar",
  sep=".."
)

sort(unique(fomd09.clean$out_subindicator[fomd09.clean$out_subpillar==""]))
sort(unique(fomd09.clean$out_subindicator[is.na(fomd09.clean$out_subpillar)]))

#--- Reclassifying out_subindicator as out_pillar
fomd09.clean <- apply_lookup_ontologies(
  df= fomd09.clean,
  path.metadata.structure,
  sheet_name = "01_outcomes",
  key_col   = "subindicator",
  value_col = "pillar",
  src_col   = "out_subindicator",
  new_col   = "out_pillar",
  sep=".."
)

readr::write_csv(fomd09.clean, paste0(path.metadata.effectsize, "01.fomd09_clean/fomd09_clean_",metadata,".csv"))

