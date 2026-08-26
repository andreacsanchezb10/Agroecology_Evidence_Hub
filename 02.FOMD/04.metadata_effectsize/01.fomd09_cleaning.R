library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(readr)

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

#--- Check subpractice details ----
for (col in c("subpractice_description_raw", "system_type")) {
  cat("---", col, "---\n")
  print(sort(unique(fomd09.clean[[col]])))
}

#--- Add commodity crop, livestock, fish ----
fomd09.clean <- add_fomd09_commodity(fomd09.clean)

unmatched_crops <- find_unmatched_crops(fomd09.clean, path.metadata.effectsize)

#sort(unique(fomd09.clean$study_id[fomd09.clean$crop_tree02=="Beet"]))

#--- Check tillage practice---- 
for (col in c("tillage_subpractice_raw", "tillage_subpractice","tillage_method",
              "tillage_method_other","tillage_depth","tillage_frequency"
              )) {
  cat("---", col, "---\n")
  print(sort(unique(fomd09.clean[[col]])))
}

sort(unique(fomd09.clean$study_id[fomd09.clean$tillage_subpractice  =="Reduced or Minimum Tillage..Conventional tillage"]))

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

#sort(unique(fomd09.clean$study_id[fomd09.clean$intercrop_residues_fate =="unspecified"]))

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

#sort(unique(fomd09.clean1$study_id[fomd09.clean1$agrof_shade_mean_min_max  =="0(NA-NA)"]))

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
#sort(unique(fomd09.clean$study_id[fomd09.clean$chem_name_amount_unit   =="NA[0(NA)]" ]))

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
				
#--- Add product information ----
fomd09.clean <- collapse_fomd09_columns(fomd09.clean, prefix = "product0", sep = "..")

for (col in c("product", "econ_inputs", "bio_func_group", "bio_ground_ref"

)) {
  cat("---", col, "---\n")
  print(sort(unique(fomd09.clean[[col]])))
}

unmatched_products <- find_unmatched_products(fomd09.clean, path.metadata.structure)

#sort(unique(fomd09.clean$study_id[fomd09.clean$bio_ground_ref  =="Above ground" ]))

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

sort(unique(fomd09.clean$study_id[fomd09.clean$out_subindicator   =="Total cost" ]))

#--- Check outcome value information ----
for (col in c("out_value_metric", "out_value",
              "out_var_metric", "out_var_value",
              "outc_var_value_l",	"outc_var_value_u",
              "out_sample_size"

)) {
  cat("---", col, "---\n")
  print(sort(unique(fomd09.clean[[col]])))
}

#sort(unique(fomd09.clean$study_id[fomd09.clean$out_sample_size  =="Unspecified" ]))

#--- Check outcome LER information ----
for (col in c("out_value_product01", "out_var_value_product01",
              "out_value_product02", "out_var_value_product02",
              "out_value_product03",	"out_var_value_product03",
              "out_value_product04","out_var_value_product04",
              
              "out_value_product05", "out_var_value_product05",
              "ler_value_product01", "ler_var_value_product01",
              "ler_value_product02",	"ler_var_value_product02",
              "ler_value_product03","ler_var_value_product03",
              "ler_value_total","ler_var_total"
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

source(file.path(path.metadata.effectsize,"/fomd_fun/fun_lookup_ontologies.R"))

#--- Reclassifying out_subindicator as out_indicator
fomd09.clean <- apply_lookup_ontologies(
  df        = fomd09.clean,
  path.metadata.structure = path.metadata.structure,
  sheet_name = "01_outcomes",
  key_col   = "subindicator",
  value_col = "indicator",
  src_col   = "out_subindicator",
  new_col   = "out_indicator"
)

#--- Reclassifying out_subindicator as out_subpillar
fomd09.clean <- apply_lookup_ontologies(
  fomd09.clean,
  path.metadata.structure,
  sheet_name = "01_outcomes",
  key_col   = "subindicator",
  value_col = "subpillar",
  src_col   = "out_subindicator",
  new_col   = "out_subpillar"
)

sort(unique(fomd09.clean$out_subindicator[fomd09.clean$out_subpillar==""]))
sort(unique(fomd09.clean$out_subindicator[is.na(fomd09.clean$out_subpillar)]))

#--- Reclassifying out_subindicator as out_pillar
fomd09.clean <- apply_lookup_ontologies(
  fomd09.clean,
  path.metadata.structure,
  sheet_name = "01_outcomes",
  key_col   = "subindicator",
  value_col = "pillar",
  src_col   = "out_subindicator",
  new_col   = "out_pillar"
)

readr::write_csv(fomd09.clean, paste0(path.metadata.effectsize, "01.fomd09_clean/fomd09_clean_",metadata,".csv"))





###########################
###################
#-----------------------------
# Equations to calculate the SD from SE, IC and IQR
#-----------------------------

##Equation to calculate the SD from SE (Higgins & Green 2011)(a= out_variance_value; b= out_sample_size)
##http://handbook-5-1.cochrane.org/chapter_7/7_7_3_2_obtaining_standard_deviations_from_standard_errors_and.htm
SE_SD <- function (out_variance_value, out_sample_size) {  
  result<- out_variance_value * sqrt(out_sample_size)
  return(result)
}

##Equation to calculate the SD from M_IQR (Hozo et al., 2005) 
##(a= N_samples; b=B_error_range; c=B_error_value; d= B_error_range.1)
M_IQR_SD<- function (a, b,c,d) {  
  result<- sqrt(((a + 1)/(48 * a*((a-1)^2))) * (((a^2) + 3) * ((b - (2*c) + d)^2) + (4* (a^2)) * ((d - b)^2)))
  return(result)
}

##Equation to calculate the SD from CI (Higgins & Green 2011) (a= N_samples; b= B_error_value)
##http://handbook-5-1.cochrane.org/chapter_7/7_7_3_2_obtaining_standard_deviations_from_standard_errors_and.htm
CI_SD<- function (a, b) {  
  result<- (sqrt(a) * (b/((qt((1-(0.05/2)), (a - 1)))*2)))
  return(result)
}



#-----------------------------
# Calculate Mean
#-----------------------------
sort(unique(fomd09.clean$out_value_metric))
sort(unique(fomd09.clean$out_value))

fomd09.clean<-fomd09.clean%>%
  mutate(across(
    c(out_value,
      out_var_value,
      outc_var_value_l,
      outc_var_value_u,
      out_sample_size,
      out_value_product_component01,
      out_var_value_product_component01,
      out_value_product_component02,
      out_var_value_product_component02,
      out_value_product_component03,
      out_var_value_product_component03,
      out_value_product_component04,
      out_var_value_product_component04,
      out_value_product_component05,
      out_var_value_product_component05
    ),
    as.numeric))%>%
  mutate(out_mean=case_when(
    out_value_metric=="Mean"~out_value,
    TRUE ~ NA))%>%
  
  mutate(out_mean_product_component01=case_when(
    out_value_metric=="Mean"~out_value_product_component01,
    TRUE ~ NA))%>%
  mutate(out_mean_product_component02=case_when(
    out_value_metric=="Mean"~out_value_product_component02,
    TRUE ~ NA))%>%
  mutate(out_mean_product_component03=case_when(
    out_value_metric=="Mean"~out_value_product_component03,
    TRUE ~ NA))%>%
  mutate(out_mean_product_component04=case_when(
    out_value_metric=="Mean"~out_value_product_component04,
    TRUE ~ NA))%>%
  mutate(out_mean_product_component05=case_when(
    out_value_metric=="Mean"~out_value_product_component05,
    TRUE ~ NA))

    

sort(unique(fomd09.clean$out_mean))
sort(unique(fomd09.clean$out_value_product_component02))
sort(unique(fomd09.clean$out_value_product_component03))
sort(unique(fomd09.clean$out_value_product_component04))
sort(unique(fomd09.clean$out_value_product_component05))

#-----------------------------
# Calculate Standard Deviation (SD)
#-----------------------------
sort(unique(fomd09.clean$out_var_metric))
sort(unique(fomd09.clean$out_var_value))
sort(unique(fomd09.clean$outc_var_value_l))
sort(unique(fomd09.clean$outc_var_value_u))

fomd09.clean<-fomd09.clean%>%
  mutate(out_sd=case_when(
    out_var_metric=="SE (Standard Error)"~SE_SD(out_var_value, out_sample_size),
    #out_var_metric==
    TRUE ~ NA))%>%
  mutate(out_sd_product_component01=case_when(
    out_var_metric=="SE (Standard Error)"~SE_SD(out_var_value_product_component01, out_sample_size),
    #out_var_metric==
    TRUE ~ NA))%>%
  mutate(out_sd_product_component02=case_when(
    out_var_metric=="SE (Standard Error)"~SE_SD(out_var_value_product_component02, out_sample_size),
    #out_var_metric==
    TRUE ~ NA))%>%
  mutate(out_sd_product_component03=case_when(
    out_var_metric=="SE (Standard Error)"~SE_SD(out_var_value_product_component03, out_sample_size),
    #out_var_metric==
    TRUE ~ NA))%>%
  mutate(out_sd_product_component04=case_when(
    out_var_metric=="SE (Standard Error)"~SE_SD(out_var_value_product_component04, out_sample_size),
    #out_var_metric==
    TRUE ~ NA))%>%
  mutate(out_sd_product_component05=case_when(
    out_var_metric=="SE (Standard Error)"~SE_SD(out_var_value_product_component05, out_sample_size),
    #out_var_metric==
    TRUE ~ NA))
  

sort(unique(fomd09.clean$out_sd))
sort(unique(fomd09.clean$out_sd_product_component02))
sort(unique(fomd09.clean$out_sd_product_component03))
sort(unique(fomd09.clean$out_sd_product_component04))
sort(unique(fomd09.clean$out_sd_product_component05))

  
#-----------------------------
# Unselect unnecessary columns
#-----------------------------
names(fomd10)
names(fomd09.clean)
common_cols <- intersect(names(fomd10), names(fomd09.clean))

fomd09.clean <- fomd09.clean[, unique(
  c("practice_id",
    "out_comparison_treatment",
    "out_mean_product_component01",
    "out_sd_product_component01",
    "out_mean_product_component02",
    "out_sd_product_component02",
    "out_mean_product_component03",
    "out_sd_product_component03",
    "out_mean_product_component04",
    "out_sd_product_component04",
    "out_mean_product_component05",
    "out_sd_product_component05",
    common_cols))]

names(fomd09.clean)

list(
  only_in_fomd10 = setdiff(names(fomd10), names(fomd09.clean)),
  only_in_fomd09 = setdiff(names(fomd09.clean), names(fomd10))
)
fomd09.clean$out_mean_product_component02
sort(unique(fomd09.clean$subpractice))


#fomd09.cleanx<-fomd09.clean%>%
 # select(study_id,practice_theme,practice_type,practice, subpractice)%>%
  #filter(practice_theme=="Crop Management-Agroforestry-Inorganic Fertilizer-Pest management")




