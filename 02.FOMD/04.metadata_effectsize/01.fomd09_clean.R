library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(readr)

path.metadata.structure<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/02.metadata_structure/"
path.metadata.effectsize<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/04.metadata_effectsize/"

list.files(path.metadata.structure)
list.files(path.metadata.effectsize)

#==========================================================
# Read functions
#==========================================================
source(file.path(path.metadata.effectsize,"/fomd_fun/fun_fomd09_verified_combined.R"))
source(file.path(path.metadata.effectsize,"/fomd_fun/fun_fomd09_cleaning.R"))

#==========================================================
# Read datasets
#==========================================================
metadata<-"MD_Paut,_24_A glo_Sc" #Paut et al. 2024. A global dataset of experimental intercropping and agroforestry studies in horticulture. 10.1038/s41597-023-02831-7

#---Combined verfified studies from metadata subfolder
fomd09 <- combine_09FOMD_verified(subfolder = metadata)

#==============================================
#---- Cleaning the dataset ----
#==============================================
### things to do:
#- All "unspecified" across the dataset transform to "Unspecified"

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
fomd09.clean <- collapse_fomd09_columns(fomd09.clean,  prefix = "crop_seq_subpractice0")

for (col in c("crop_seq_subpractice_raw", "crop_seq_start_year","crop_seq_start_season",
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
  sep = "-",
  dedupe = TRUE
)

fomd09.clean <- add_fomd09_mean_min_max(fomd09.clean,  prefix = "agrof_shade")
fomd09.clean <- add_fomd09_mean_min_max(fomd09.clean, prefix = "agrof_canopy_height")
fomd09.clean <- add_fomd09_mean_min_max(fomd09.clean, prefix = "agrof_dhb")

#sort(unique(fomd09.clean1$study_id[fomd09.clean1$agrof_shade_mean_min_max  =="0(NA-NA)"]))

#--- Add nutrient management practice (inorganic) information ----
fomd09.clean <- add_fomd09_fert_inorganic(fomd09.clean)

#sort(unique(fomd09.clean$study_id[fomd09.clean$fert_inorganicP_amount_unit     =="Unspecified(Unspecified)"]))

#--- Add nutrient management practice (organic) information ----
fomd09.clean <- add_fomd09_fert_organic(fomd09.clean)

#sort(unique(fomd09.clean1$study_id[fomd09.clean1$fert_organic_type  =="Cow Manure..Grow More..MO STD" ]))

#---Add weeding management moderator information----
fomd09.clean <- add_fomd09_weed(fomd09.clean)

#---Add chemical management practice information ----
fomd09.clean <- add_fomd09_chem(fomd09.clean)


#---Add residues management practice information ----
fomd09.clean1 <- collapse_fomd09_columns(fomd09.clean,  prefix = "residues_subpractice0")





#---01_FOMD_ontologies
fomd01.countries<-read_xlsx(file.path(path.metadata.structure,"01_FOMD_ontologies.xlsx"), sheet = "01_countries")
fomd01.outcomes<-read_xlsx(file.path(path.metadata.structure,"01_FOMD_ontologies.xlsx"), sheet = "01_outcomes")
fomd01.practices<-read_xlsx(file.path(path.metadata.structure,"01_FOMD_ontologies.xlsx"), sheet = "01_practices")
sort(unique(fomd01.practices$subpractice))


#---10_FOMD_metadata_synthesis_long
fomd10<-read_xlsx(file.path(path.metadata.structure,"10_FOMD_metadata_synthesis_short.xlsx"), sheet = "10_FOMD_metadata_synthesis")%>%
    select(-starts_with("T_"))%>%
    rename_with(~ sub("^C_", "", .x))

names(fomd10)

#==========================================================
# Convert multiple columns into one column
#==========================================================
collapse_clean <- function(x, sep = "-") {
  x <- x[x != "" & !is.na(x)]
  if (length(x) == 0) NA_character_ else paste(x, collapse = sep)
}

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

#MISSING: a medida que se vayan agregando mas countries, crops, animals, cambiar el numero de 01:0x

###########################
###################


### HASTA ACA!


fomd09.clean1<-fomd09.clean%>% 
  rowwise() 
  mutate(  
  #---residues_practice
  residues_subpractice= paste(na.omit(c_across(starts_with("residues_subpractice0"))),collapse = "-"),
  
  #---residues_moderator
  residues_material_amount_unit= ifelse(
    is.na(residues_material_amount) & is.na(residues_material_unit),  "",
    paste0(residues_material_amount, "(", residues_material_unit,  ")")),
  
  #---pH_amendment_moderator
  ph_material_amount_unit= ifelse(
    is.na(ph_material_amount) & is.na(ph_material_unit),  "",
    paste0(ph_material_amount, "(", ph_material_unit,  ")")),
  
  #---irrigation_moderator
  irrig_date_start_end= paste0(na.omit(c(irrig_date_start,irrig_date_end)),collapse = "-"),
  
  irrig_water_amount_unit= ifelse(
    is.na(irrig_water_amount) & is.na(irrig_water_unit),  "",
    paste0(irrig_water_amount, "(", irrig_water_unit,  ")")),
  
  #---water_harvesting_practice
  watharv_subpractice= paste(na.omit(c_across(starts_with("watharv_subpractice0"))),collapse = "-"),
  
  #---harvest_moderator
  harvest_date_start_end= paste0(na.omit(c(harvest_date_start,harvest_date_end)),collapse = "-"),
  
  #---postharvesting_practice
  postharvest_subpractice= paste(na.omit(c_across(starts_with("postharv_subpractice0"))),collapse = "-"),
  
  #---postharvesting_moderator
  postharvest_date_start_end= paste0(na.omit(c(harvest_date_start,harvest_date_end)),collapse = "-"),
  
  #---practice
  subpractice = collapse_clean(c_across(all_of(subpractice.list))))
  
#---product_outcome
fomd09.clean<-fomd09.clean%>% 
    rowwise() %>%
    mutate(product= paste(na.omit(c_across(starts_with("product0"))),collapse = "-")) %>%
  ungroup()

# Quick checks
sort(unique(fomd09.clean$product))

#---outcome
fomd09.clean<-fomd09.clean%>%
  left_join(fomd01.outcomes %>%select(pillar,subpillar, indicator, subindicator,effect_size_type),by = c("out_subindicator"="subindicator"))%>%
  rename("out_pillar"="pillar",
         "out_subpillar"="subpillar",
         "out_indicator"="indicator",
         "effect_size_type"="effect_size_type")

# Quick checks
sort(unique(fomd09.clean$out_subindicator))  
sort(unique(fomd09.clean$out_indicator))  
sort(unique(fomd09.clean$out_subpillar))  
sort(unique(fomd09.clean$out_pillar))  
sort(unique(fomd09.clean$out_subindicator_unit))  
sort(unique(fomd09.clean$effect_size_type)) 



#---residues_practice
sort(unique(fomd09.clean$residues_subpractice))
#---residues_moderator
sort(unique(fomd09.clean$residues_material_amount_unit))
#---pH_amendment_moderator
sort(unique(fomd09.clean$ph_material_amount_unit))
#---irrigation_moderator
sort(unique(fomd09.clean$irrig_date_start_end))
#---water_harvesting_practice
sort(unique(fomd09.clean$watharv_subpractice))
#---harvest_moderator
sort(unique(fomd09.clean$harvest_date_start_end))
#---postharvesting_practice
sort(unique(fomd09.clean$postharvest_subpractice))
#---postharvesting_moderator
sort(unique(fomd09.clean$postharvest_date_start_end))
#---practice
sort(unique(fomd09.clean$subpractice))
#---product_outcome
sort(unique(fomd09.clean$product_component))

#-----------------------------------------------
#---- Match with 01_FOMD_ontologies ----
#-----------------------------------------------
library(tibble)
library(purrr)

## MISSING: #For products components classify by type, subtype

#--- lookup vector: names = country, values = ISO_3166_1_Alpha_3
lookup.country.iso <- fomd01.countries %>%
  transmute(
    country = str_squish(Country),
    country.iso    = str_squish(ISO_3166_1_Alpha_3)
  ) %>%
  distinct() %>%
  deframe()


fomd09.clean <- fomd09.clean %>%
  #---location
  mutate(country_ISO = map_chr(str_split(str_squish(country), "-"), \(x) {
    out <- unname(lookup.country.iso[str_squish(x)])
    # if something didn't match, keep the original token (change to NA if you prefer)
    out[is.na(out)] <- str_squish(x)[is.na(out)]
    paste(out, collapse = "-")
    }))
  
  
#Quick check
length(unique(fomd09.clean$country))
sort(unique(fomd09.clean$country))
length(unique(fomd09.clean$country_ISO))
sort(unique(fomd09.clean$country_ISO))



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

readr::write_csv(fomd09.clean, paste0(path.metadata.effectsize, "/fomd09_cleanv2.csv"))

#readr::write_csv(fomd09.clean, paste0(path.metadata.effectsize, "/fomd09_clean.csv"))


