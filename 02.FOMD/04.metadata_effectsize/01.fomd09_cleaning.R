library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(readr)

path.metadata.structure<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Knowledge Hub - General/Agroecology_Knolwedge_Hub/02.FOMD/02.metadata_structure/"
path.metadata.effectsize<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Knowledge Hub - General/Agroecology_Knolwedge_Hub/02.FOMD/04.metadata_effectsize/"

list.files(path.metadata.structure)

#==========================================================
# Read datasets
#==========================================================
#---01_FOMD_ontologies
fomd01.countries<-read_xlsx(file.path(path.metadata.structure,"01_FOMD_ontologies.xlsx"), sheet = "01_countries")
fomd01.outcomes<-read_xlsx(file.path(path.metadata.structure,"01_FOMD_ontologies.xlsx"), sheet = "01_outcomes")
fomd01.practices<-read_xlsx(file.path(path.metadata.structure,"01_FOMD_ontologies.xlsx"), sheet = "01_practices")
sort(unique(fomd01.practices$subpractice))

#---04_FOMD_screening
fomd04<-read_xlsx(file.path(path.metadata.structure,"04_FOMD_screening.xlsx"), sheet = "04_FOMD_screening")%>%
  filter(status %in%c("PI","I"))

#---09_FOMD_metadata_extraction_long
fomd09<-read_xlsx(file.path(path.metadata.structure,"09_FOMD_metadata_extraction_long.xlsx"), sheet = "09_FOMD_metadata_extraction_lon")%>%
  slice(-(1:2))
  
#---10_FOMD_metadata_synthesis_long
fomd10<-read_xlsx(file.path(path.metadata.structure,"10_FOMD_metadata_synthesis_short.xlsx"), sheet = "10_FOMD_metadata_synthesis")%>%
    select(-starts_with("T_"),-index)%>%
    rename_with(~ sub("^C_", "", .x))

names(fomd10)
#==========================================================
# Left join for reclassification
#==========================================================
fomd09.clean<-fomd09%>%
  #---bibliographic----
  left_join(fomd04 %>%select(authors,year,journal,doi,study_id),by ="study_id" )%>%
  
  #---outcome
  left_join(fomd01.outcomes %>%select(pillar,subpillar,indicator, subindicator,effect_size_type),by = c("out_subindicator"="subindicator"))%>%
  rename("out_pillar"="pillar",
         "out_subpillar"="subpillar",
         "out_indicator"="indicator",
         "effect_size_type"="effect_size_type")

#MISING: Convert units
#---bibliographic
sort(unique(fomd09.clean$study_id))  
sort(unique(fomd09.clean$authors))  
sort(unique(fomd09.clean$year))  
sort(unique(fomd09.clean$journal))  
sort(unique(fomd09.clean$doi))  

#---outcome
sort(unique(fomd09.clean$out_subindicator))  
sort(unique(fomd09.clean$out_pillar))  
sort(unique(fomd09.clean$out_subpillar))  
sort(unique(fomd09.clean$out_indicator))  
sort(unique(fomd09.clean$effect_size_type))  

#-----------------------------------------------
#---- Convert to specify class ----
#-----------------------------------------------
fomd09.clean<-fomd09.clean%>%
  
  mutate(
    planting_date_start = na_if(planting_date_start, "Unspecified"),
    planting_date_start = as.Date(as.numeric(planting_date_start), origin = "1899-12-30"),
    planting_date_start = format(planting_date_start, "%d/%m/%Y"),
    
    planting_date_end = na_if(planting_date_end, "Unspecified"),
    planting_date_end = as.Date(as.numeric(planting_date_end), origin = "1899-12-30"),
    planting_date_end = format(planting_date_end, "%d/%m/%Y"),
    
    irrig_date_start = na_if(irrig_date_start, "Unspecified"),
    irrig_date_start = as.Date(as.numeric(irrig_date_start), origin = "1899-12-30"),
    irrig_date_start = format(irrig_date_start, "%d/%m/%Y"),
    
    irrig_date_end = na_if(irrig_date_end, "Unspecified"),
    irrig_date_end = as.Date(as.numeric(irrig_date_end), origin = "1899-12-30"),
    irrig_date_end = format(irrig_date_end, "%d/%m/%Y"),
    
    harvest_date_start = na_if(harvest_date_start, "Unspecified"),
    harvest_date_start = as.Date(as.numeric(harvest_date_start), origin = "1899-12-30"),
    harvest_date_start = format(harvest_date_start, "%d/%m/%Y"),
    
    harvest_date_end = na_if(harvest_date_end, "Unspecified"),
    harvest_date_end = as.Date(as.numeric(harvest_date_end), origin = "1899-12-30"),
    harvest_date_end = format(harvest_date_end, "%d/%m/%Y"),
    
    postharvest_date_start = na_if(postharvest_date_start, "Unspecified"),
    postharvest_date_start = as.Date(as.numeric(postharvest_date_start), origin = "1899-12-30"),
    postharvest_date_start = format(postharvest_date_start, "%d/%m/%Y"),
    
    postharvest_date_end = na_if(postharvest_date_end, "Unspecified"),
    postharvest_date_end = as.Date(as.numeric(postharvest_date_end), origin = "1899-12-30"),
    postharvest_date_end = format(postharvest_date_end, "%d/%m/%Y")
    
    )
  
(unique(fomd09.clean$planting_date_start))
(unique(fomd09.clean$planting_date_end))

(unique(fomd09.clean$irrig_date_start))
(unique(fomd09.clean$irrig_date_end))

(unique(fomd09.clean$harvest_date_start))
(unique(fomd09.clean$harvest_date_end))

(unique(fomd09.clean$postharvest_date_start))
(unique(fomd09.clean$postharvest_date_end))

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
fomd09.clean<-fomd09.clean%>% 
  rowwise() %>%
  
  #---location
mutate(
  country = paste(na.omit(c_across(starts_with("country0"))),collapse = ".."),
  site_type= paste(na.omit(c_across(starts_with("site_type0"))),collapse = ".."),
  site_id= paste(na.omit(c_across(starts_with("site_id0"))),collapse = ".."),
  site_admin= paste(na.omit(c_across(starts_with("site_admin0"))),collapse = ".."),
  site_agg= paste(na.omit(c_across(starts_with("site_agg0"))),collapse = ".."),
  site_latlong_type= paste(na.omit(c_across(starts_with("site_latlong_type0"))),collapse = ".."),
  site_latitude= paste(na.omit(c_across(starts_with("site_latitude0"))),collapse = ".."),
  site_longitude= paste(na.omit(c_across(starts_with("site_longitude0"))),collapse = ".."),
  site_buffer= paste(na.omit(c_across(starts_with("site_buffer0"))),collapse = ".."),
  site_key= {
    long <- c_across(all_of(paste0("site_longitude", sprintf("%02d", 01:02))))
    lat <- c_across(all_of(paste0("site_latitude", sprintf("%02d", 01:02))))
    b <- c_across(all_of(paste0("site_buffer", sprintf("%02d", 01:02))))
    paste0(na.omit(ifelse(is.na(long) |long == "",NA_character_,
                          paste0(long,ifelse(is.na(lat) | lat == "", "", paste0(" ", lat, " B")),
                                 ifelse(is.na(b) | b == "", "", b)))),collapse = "..")
  },

  #---commodity_crop
  crop_diversity = {
    d <- c_across(all_of(paste0("crop", sprintf("%02d", 01:03))))
    a <- c_across(all_of(paste0("crop_arrangement", sprintf("%02d", 01:03))))
    paste0(na.omit(ifelse(is.na(d) | d == "", NA_character_, paste0(d, ifelse(is.na(a), "", a)))), collapse = "")
  } ,
  crop_variety = {
      v <- c_across(all_of(paste0("crop_variety", sprintf("%02d", 01:03))))
      a <- c_across(all_of(paste0("crop_arrangement", sprintf("%02d", 01:03))))
      paste0(na.omit(ifelse(is.na(v) | v == "", NA_character_, paste0(v, ifelse(is.na(a), "", a)))), collapse = "")
  } ,
  crop_density= {
    d <- c_across(all_of(paste0("crop_density", sprintf("%02d", 01:03))))
    u <- c_across(all_of(paste0("crop_density_unit", sprintf("%02d", 01:03))))
    a <- c_across(all_of(paste0("crop_arrangement", sprintf("%02d", 01:03))))
    paste0(na.omit(ifelse(is.na(d) |d == "",NA_character_,
                          paste0(d,ifelse(is.na(u) | u == "", "", paste0("(", u, ")")),
                                 ifelse(is.na(a) | a == "", "", a)))),collapse = "")
   },
  
  #---commodity_tree
  tree_diversity = {
      t <- c_across(all_of(paste0("tree", sprintf("%02d", 01:02))))
      a <- c_across(all_of(paste0("tree_arrangement", sprintf("%02d", 01:02))))
      paste0(na.omit(ifelse(is.na(t) | t == "", NA_character_, paste0(t, ifelse(is.na(a), "", a)))), collapse = "")
    },
  tree_density= {
    d <- c_across(all_of(paste0("tree_density", sprintf("%02d", 01:02))))
    u <- c_across(all_of(paste0("tree_density_unit", sprintf("%02d", 01:02))))
    a <- c_across(all_of(paste0("tree_arrangement", sprintf("%02d", 01:02))))
    paste0(na.omit(ifelse(is.na(d) |d == "",NA_character_,
                          paste0(d,ifelse(is.na(u) | u == "", "", paste0("(", u, ")")),
                                 ifelse(is.na(a) | a == "", "", a)))),collapse = "")
  },
  
  #---commodity_animal
  animal_diversity = {
    l <- c_across(all_of(paste0("animal", sprintf("%02d", 01:02))))
    a <- c_across(all_of(paste0("animal_arrangement", sprintf("%02d", 01:02))))
    paste0(na.omit(ifelse(is.na(l) | l == "", NA_character_, paste0(l, ifelse(is.na(a), "", a)))), collapse = "")
  },
  
  animal_breed = {
    v <- c_across(all_of(paste0("animal_breed", sprintf("%02d", 01:02))))
    a <- c_across(all_of(paste0("animal_arrangement", sprintf("%02d", 01:02))))
    paste0(na.omit(ifelse(is.na(v) | v == "", NA_character_, paste0(v, ifelse(is.na(a), "", a)))), collapse = "")
  } ,
  
  animal_density= {
    d <- c_across(all_of(paste0("animal_density", sprintf("%02d", 01:02))))
    u <- c_across(all_of(paste0("animal_density_unit", sprintf("%02d", 01:02))))
    a <- c_across(all_of(paste0("animal_arrangement", sprintf("%02d", 01:02))))
    paste0(na.omit(ifelse(is.na(d) |d == "",NA_character_,
                          paste0(d,ifelse(is.na(u) | u == "", "", paste0("(", u, ")")),
                                 ifelse(is.na(a) | a == "", "", a)))),collapse = "")
  },
  
  #---planting_moderator
  planting_date_start_end= paste0(na.omit(c(planting_date_start,planting_date_end)),collapse = "-"),
  
  #---crop_sequence_practice
  crop_seq_subpractice= paste(na.omit(c_across(starts_with("crop_seq_subpractice0"))),collapse = "-"),
  
  
  #---agroforestry_practice
  agrof_subpractice = paste(
    na.omit(c_across(any_of(c("agrof_spatial_arrangement_subpractice",
                              "agrof_components_subpractice",
                              "agrof_temporal_subpractice",
                              "agrof_shade_subpractice")))),  collapse = "-"),
  
  agrof_subpractice = case_when(
    agrof_subpractice=="Monoculture"~"Monoculture_Landscape management",
    TRUE~agrof_subpractice
  ),
  #---agroforestry_moderator
  agrof_shade_mean_min_max =  ifelse(
    is.na(agrof_shade_mean) & is.na(agrof_shade_min) & is.na(agrof_shade_max),  "",
    paste0(agrof_shade_mean, "(", agrof_shade_min, "-", agrof_shade_max, ")")),
  
  agrof_canopy_height_mean_min_max= ifelse(
    is.na(agrof_canopy_height_mean) & is.na(agrof_canopy_height_min) & is.na(agrof_canopy_height_max),  "",
    paste0(agrof_canopy_height_mean, "(", agrof_canopy_height_min, "-", agrof_canopy_height_max, ")")),
  
  agrof_dhb_mean_min_max=ifelse(
    is.na(agrof_dhb_mean) & is.na(agrof_dhb_min) & is.na(agrof_dhb_max),  "",
    paste0(agrof_dhb_mean, "(", agrof_dhb_min, "-", agrof_dhb_max, ")")),
  
  #---weeding_management_moderator
  weed_frequency_unit= ifelse(
    is.na(weed_frequency) & is.na(weed_frequency_unit),  "",
    paste0(weed_frequency, "(", weed_frequency_unit,  ")")),
  
  #---chemical_management_practice
  chem_subpractice= paste(na.omit(c_across(starts_with("chem_subpractice0"))),collapse = "-"),
  
  #---chemical_management_moderator
  chem_name_amount_unit = {
    n <- c_across(all_of(paste0("chem_name", sprintf("%02d", 1:3))))
    a <- c_across(all_of(paste0("chem_amount", sprintf("%02d", 1:3))))
    u <- c_across(all_of(paste0("chem_unit", sprintf("%02d", 1:3))))
    
    vals <- ifelse( is.na(n) | n == "", "NA",
      paste0(n, ":",
             ifelse(is.na(a) | a == "", "Unspecified", a),
             ifelse(is.na(u) | u == "", "", paste0("(", u, ")"))
             ))
    if (all(vals == "NA")) "" else paste(vals, collapse = "-")
  },
  
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
  subpractice = collapse_clean(c_across(all_of(subpractice.list))),
  
  #---product_outcome
  product_component= paste(na.omit(c_across(starts_with("product_component0"))),collapse = "-")) %>%
  ungroup()

names(fomd09.clean)
#---location
sort(unique(fomd09.clean$country))
sort(unique(fomd09.clean$site_type))
sort(unique(fomd09.clean$site_id))
sort(unique(fomd09.clean$site_admin))
sort(unique(fomd09.clean$site_latlong_type))
sort(unique(fomd09.clean$site_latitude))
sort(unique(fomd09.clean$site_longitude))
sort(unique(fomd09.clean$site_buffer))
sort(unique(fomd09.clean$site_key))
#---commodity_crop
sort(unique(fomd09.clean$crop_diversity))
sort(unique(fomd09.clean$crop_variety))
table(fomd09.clean$crop_diversity,fomd09.clean$crop_variety)
sort(unique(fomd09.clean$crop_density))
#---commodity_tree
sort(unique(fomd09.clean$tree_diversity))
sort(unique(fomd09.clean$tree_density))
#---commodity_animal
sort(unique(fomd09.clean$animal_diversity))
#---planting_moderator
sort(unique(fomd09.clean$planting_date_start_end))
#---intercropping_practice
sort(unique(fomd09.clean$intercrop_subpractice))
#---crop_sequence_practice
sort(unique(fomd09.clean$crop_seq_subpractice))
#---agroforestry_practice
sort(unique(fomd09.clean$agrof_subpractice))
#---agroforestry_moderator
sort(unique(fomd09.clean$agrof_shade_mean_min_max))
sort(unique(fomd09.clean$agrof_canopy_height_mean_min_max))
sort(unique(fomd09.clean$agrof_dhb_mean_min_max))
#---weeding_management_moderator
sort(unique(fomd09.clean$weed_frequency_unit))
#---chemical_management_practice
sort(unique(fomd09.clean$chem_subpractice))
#---chemical_management_moderator
sort(unique(fomd09.clean$chem_name_amount_unit))
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
#---- Match with ontologies ----
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
  
  
#---location
sort(unique(fomd09.clean$country))
sort(unique(fomd09.clean$country_ISO))
       
#---practice
sort(unique(fomd09.clean$subpractice))


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

readr::write_csv(fomd09.clean, paste0(path.metadata.effectsize, "/fomd09_clean.csv"))



