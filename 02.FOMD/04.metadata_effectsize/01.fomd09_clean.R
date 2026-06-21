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
# Read datasets
#==========================================================
#---01_FOMD_ontologies
fomd01.countries<-read_xlsx(file.path(path.metadata.structure,"01_FOMD_ontologies.xlsx"), sheet = "01_countries")
fomd01.outcomes<-read_xlsx(file.path(path.metadata.structure,"01_FOMD_ontologies.xlsx"), sheet = "01_outcomes")
fomd01.practices<-read_xlsx(file.path(path.metadata.structure,"01_FOMD_ontologies.xlsx"), sheet = "01_practices")
sort(unique(fomd01.practices$subpractice))

#---04_FOMD_screening
fomd04<-read_xlsx(file.path(path.metadata.structure,"04_FOMD_screening.xlsx"), sheet = "04_FOMD_screening")%>%
  filter(ss_id!="MD_Rosen_24_Effec_Sc")%>%
  filter(status =="I")
length(unique(fomd04$study_id))#20

#---09_FOMD_metadata_extraction_long
fomd09<-read_xlsx(file.path(path.metadata.structure,"09_FOMD_metadata_extraction_long.xlsx"), sheet = "09_FOMD_metadata_extraction_lon")%>%
  slice(-(1))
  #filter(row_status=="verified")

length(unique(fomd09$study_id)) #18

#---10_FOMD_metadata_synthesis_long
fomd10<-read_xlsx(file.path(path.metadata.structure,"10_FOMD_metadata_synthesis_short.xlsx"), sheet = "10_FOMD_metadata_synthesis")%>%
    select(-starts_with("T_"))%>%
    rename_with(~ sub("^C_", "", .x))

names(fomd10)

#==============================================
#---- Convert to specify class ----
#==============================================
#--- Clean dates
clean_date <- function(x) {
  x %>%
    na_if("Unspecified") %>%
    as.numeric() %>%
    as.Date(origin = "1899-12-30") %>%
    format("%d/%m/%Y")
}

fomd09.clean <- fomd09 %>%
  mutate(
    across(c(
        #--planting_practice
        planting_date_start, planting_date_end, 
        #--irrigation_practice
        irrig_date_start, irrig_date_end,
        #--harvest_practice
        harvest_date_start, harvest_date_end,
        #--postharvesting_practice
        postharvest_date_start, postharvest_date_end
      ),
      clean_date))%>%
  mutate(across(
    c(starts_with("crop_density"),
      starts_with("tree_density"),
      starts_with("animal_density")),
    
      as.character))
  
(unique(fomd09.clean$planting_date_start))
(unique(fomd09.clean$planting_date_end))

(unique(fomd09.clean$irrig_date_start))
(unique(fomd09.clean$irrig_date_end))

(unique(fomd09.clean$harvest_date_start))
(unique(fomd09.clean$harvest_date_end))

(unique(fomd09.clean$postharvest_date_start))
(unique(fomd09.clean$postharvest_date_end))
class(fomd09.clean$crop_density15)
class(fomd09.clean$tree_density15)
class(fomd09.clean$animal_density05)

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
#---bibliographic----
fomd09.clean<-fomd09.clean%>%
  left_join(fomd04 %>%select(authors,title,year,journal,doi,study_id),by ="study_id" )

# Quick checks
length(unique(fomd09.clean$study_id)) # 18
length(unique(fomd09.clean$authors))  #18
length(unique(fomd09.clean$title)) # 18
sort(unique(fomd09.clean$year))  
sort(unique(fomd09.clean$journal))  
sort(unique(fomd09.clean$doi)) 

#---location----
fomd09.clean<-fomd09.clean%>% 
  rowwise() %>%
  mutate(
    country = paste(unique(na.omit(c_across(starts_with("country0"))),collapse = "..")),
    site_key= {
      coun <- as.character(unlist(pick(all_of(paste0("country", sprintf("%02d", 1:5))))))
      type <- as.character(unlist(pick(all_of(paste0("site_type", sprintf("%02d", 1:5))))))
      id <- as.character(unlist(pick(all_of(paste0("site_id", sprintf("%02d", 1:5))))))
      admin <- as.character(unlist(pick(all_of(paste0("site_admin", sprintf("%02d", 1:5))))))
      agg <- as.character(unlist(pick(all_of(paste0("site_agg", sprintf("%02d", 1:5))))))
      latlong_type <- as.character(unlist(pick(all_of(paste0("site_latlong_type", sprintf("%02d", 1:5))))))
      lat  <- as.character(unlist(pick(all_of(paste0("site_latitude",  sprintf("%02d", 1:5))))))
      long <- as.character(unlist(pick(all_of(paste0("site_longitude", sprintf("%02d", 1:5))))))
      b    <- as.character(unlist(pick(all_of(paste0("site_buffer",    sprintf("%02d", 1:5))))))
    vals <- ifelse(
      is.na(coun) | coun == "",
      NA_character_,
      paste0(
        "[",coun,"]",
        "[",type,"]",
        "[",id,"]",
        "[",admin,"]",
        "[",agg,"]",
        "[",latlong_type,"]",
        "[",lat,"]",
        
        ifelse(is.na(long) | long == "", "", paste0("[", long, "]")),
        ifelse(is.na(b) | b == "", "", paste0("[", b, "]"))
      ))
    paste0(na.omit(vals), collapse = "..")
  })

# Quick checks
sort(unique(fomd09.clean$country))
sort(unique(fomd09.clean$country02))
sort(unique(fomd09.clean$country03))
sort(unique(fomd09.clean$country04))
sort(unique(fomd09.clean$site_key))

#---experiment_details----
## TO CHECK: see what to do here, this can differ from T and C
# Quick checks
sort(unique(fomd09.clean$exp_design))
sort(unique(fomd09.clean$exp_plot_size))
sort(unique(fomd09.clean$exp_field_size))
sort(unique(fomd09.clean$exp_duration))

#---experiment_time----
## TO CHECK: see what to do here, this can differ from T and C
# Quick checks
sort(unique(fomd09.clean$time_raw))
sort(unique(fomd09.clean$time_year_start))
sort(unique(fomd09.clean$time_year_end))
sort(unique(fomd09.clean$time_season))

#---practice----
sort(unique(fomd09.clean$subpractice_description_raw))
sort(unique(fomd09.clean$system_type))

#---commodity_crop----
fomd09.clean<-fomd09.clean%>% 
  mutate( across(
      all_of(paste0("crop", sprintf("%02d", 1:15))),
      ~gsub("_", " ", .x))) %>% 
  rowwise() %>%
  mutate(
  crop_diversity = {
    d <- c_across(all_of(paste0("crop", sprintf("%02d", 01:15))))
    a <- c_across(all_of(paste0("crop_arrangement", sprintf("%02d", 01:15))))
    paste0(na.omit(ifelse(is.na(d) | d == "", NA_character_, paste0(d, ifelse(is.na(a), "", a)))), collapse = "")
  } ,
  crop_variety = {
    c <- c_across(all_of(paste0("crop", sprintf("%02d", 01:15))))
    v <- c_across(all_of(paste0("crop_variety", sprintf("%02d", 01:15))))
    a <- c_across(all_of(paste0("crop_arrangement", sprintf("%02d", 01:15))))
    paste0(na.omit(ifelse(is.na(c) | c == "", NA_character_, paste0(c,"(",v, ")",ifelse(is.na(a), "", a)))), collapse = "")
  } ,
  crop_density= {
    c <- c_across(all_of(paste0("crop", sprintf("%02d", 01:15))))
    d <- c_across(all_of(paste0("crop_density", sprintf("%02d", 01:15))))
    u <- c_across(all_of(paste0("crop_density_unit", sprintf("%02d", 01:15))))
    a <- c_across(all_of(paste0("crop_arrangement", sprintf("%02d", 01:15))))
    paste0(na.omit(ifelse(is.na(d) |d == "",NA_character_,
                          paste0(c,"[",d,ifelse(is.na(u) | u == "", "", paste0("(", u, ")]")),
                                 ifelse(is.na(a) | a == "", "", a)))),collapse = "")
   })

# Quick checks
sort(unique(fomd09.clean$crop_diversity))
sort(unique(fomd09.clean$crop_variety))
sort(unique(fomd09.clean$crop_density))

#---commodity_tree----
fomd09.clean<-fomd09.clean%>% 
  rowwise() %>%
  mutate(
  tree_diversity = {
      t <- c_across(all_of(paste0("tree", sprintf("%02d", 01:15))))
      a <- c_across(all_of(paste0("tree_arrangement", sprintf("%02d", 01:15))))
      paste0(na.omit(ifelse(is.na(t) | t == "", NA_character_, paste0(t, ifelse(is.na(a), "", a)))), collapse = "")
    },
  tree_density= {
    t <- c_across(all_of(paste0("tree", sprintf("%02d", 01:10))))
    d <- c_across(all_of(paste0("tree_density", sprintf("%02d", 01:15))))
    u <- c_across(all_of(paste0("tree_density_unit", sprintf("%02d", 01:15))))
    a <- c_across(all_of(paste0("tree_arrangement", sprintf("%02d", 01:15))))
    paste0(na.omit(ifelse(is.na(d) |d == "",NA_character_,
                          paste0(t,"[",d,ifelse(is.na(u) | u == "", "", paste0("(", u, ")]")),
                                 ifelse(is.na(a) | a == "", "", a)))),collapse = "")
  })

# Quick checks
sort(unique(fomd09.clean$tree_diversity))
sort(unique(fomd09.clean$tree_density))

#---commodity_animal----
fomd09.clean<-fomd09.clean%>% 
  rowwise() %>%
  mutate(
  animal_diversity = {
    l <- c_across(all_of(paste0("animal", sprintf("%02d", 01:05))))
    a <- c_across(all_of(paste0("animal_arrangement", sprintf("%02d", 01:05))))
    paste0(na.omit(ifelse(is.na(l) | l == "", NA_character_, paste0(l, ifelse(is.na(a), "", a)))), collapse = "")
  },
  
  animal_breed = {
    l <- c_across(all_of(paste0("animal", sprintf("%02d", 01:05))))
    v <- c_across(all_of(paste0("animal_breed", sprintf("%02d", 01:05))))
    a <- c_across(all_of(paste0("animal_arrangement", sprintf("%02d", 01:05))))
    paste0(na.omit(ifelse(is.na(v) | v == "", NA_character_, paste0(l,"(",v, ")",ifelse(is.na(a), "", a)))), collapse = "")
  } ,
  
  animal_density= {
    l <- c_across(all_of(paste0("animal", sprintf("%02d", 01:05))))
    d <- c_across(all_of(paste0("animal_density", sprintf("%02d", 01:02))))
    u <- c_across(all_of(paste0("animal_density_unit", sprintf("%02d", 01:02))))
    a <- c_across(all_of(paste0("animal_arrangement", sprintf("%02d", 01:02))))
    paste0(na.omit(ifelse(is.na(d) |d == "",NA_character_,
                          paste0(l,"[", d,ifelse(is.na(u) | u == "", "", paste0("(", u, ")]")),
                                 ifelse(is.na(a) | a == "", "", a)))),collapse = "")
  })

# Quick checks
sort(unique(fomd09.clean$animal_diversity))
sort(unique(fomd09.clean$animal_breed))
sort(unique(fomd09.clean$animal_density))

#---soil_management_practice---- 

# Quick checks
sort(unique(fomd09.clean$tillage_subpractice_raw))
sort(unique(fomd09.clean$tillage_subpractice))
sort(unique(fomd09.clean$tillage_method))
sort(unique(fomd09.clean$tillage_method_other))
sort(unique(fomd09.clean$tillage_depth))
sort(unique(fomd09.clean$tillage_frequency))

#---planting_practice----

# Quick checks
sort(unique(fomd09.clean$planting_subpractice_raw))
sort(unique(fomd09.clean$planting_subpractice))
sort(unique(fomd09.clean$planting_method))
sort(unique(fomd09.clean$planting_date_start))
sort(unique(fomd09.clean$planting_date_end))

#---improved crop varieties: practice----
fomd09.clean<-fomd09.clean%>% 
  mutate(varietal_crop_name = gsub("_", " ", varietal_crop_name))%>%
  mutate( varietal_crop_variety = ifelse(
    is.na(varietal_crop_name) | varietal_crop_name == "",
    NA_character_,
    paste0(varietal_crop_name, "(", varietal_crop_variety, ")")))

# Quick checks
sort(unique(fomd09.clean$varietal_crop_subpractice_raw))
sort(unique(fomd09.clean$varietal_crop_name))
sort(unique(fomd09.clean$varietal_crop_variety))
sort(unique(fomd09.clean$varietal_crop_subpractice))
sort(unique(fomd09.clean$varietal_crop_type))
sort(unique(fomd09.clean$varietal_crop_trait))

#---intercropping_practice----
# Quick checks
sort(unique(fomd09.clean$intercrop_subpractice_raw))
sort(unique(fomd09.clean$intercrop_subpractice))
sort(unique(fomd09.clean$intercrop_design))
sort(unique(fomd09.clean$intercrop_pattern))
sort(unique(fomd09.clean$intercrop_start_year))
sort(unique(fomd09.clean$intercrop_start_season))
sort(unique(fomd09.clean$intercrop_residues_fate))

#---crop_sequence_practice----
fomd09.clean<-fomd09.clean%>% 
  rowwise() %>%
  mutate(crop_seq_subpractice= paste(na.omit(c_across(starts_with("crop_seq_subpractice0"))),collapse = "-"))

# Quick checks
sort(unique(fomd09.clean$crop_seq_subpractice_raw))
sort(unique(fomd09.clean$crop_seq_subpractice))
sort(unique(fomd09.clean$crop_seq_start_year))
sort(unique(fomd09.clean$crop_seq_start_season))
sort(unique(fomd09.clean$crop_seq_residues_fate))

#---agroforestry_practice----
##CHECK TO : verificar later if it is better to keep track of spatial, component, shade..
fomd09.clean<-fomd09.clean%>% 
  rowwise() %>%
  mutate(
    agrof_subpractice = paste(unique(na.omit(c_across(any_of(c("agrof_spatial_arrangement_subpractice",
                                                               "agrof_components_subpractice",
                                                               "agrof_shade_subpractice"))))),collapse = "-"),
    agrof_shade_mean_min_max =  ifelse(
    is.na(agrof_shade_mean) & is.na(agrof_shade_min) & is.na(agrof_shade_max),  "",
    paste0(agrof_shade_mean, "(", agrof_shade_min, "-", agrof_shade_max, ")")),
    
    agrof_canopy_height_mean_min_max= ifelse(
    is.na(agrof_canopy_height_mean) & is.na(agrof_canopy_height_min) & is.na(agrof_canopy_height_max),  "",
    paste0(agrof_canopy_height_mean, "(", agrof_canopy_height_min, "-", agrof_canopy_height_max, ")")),
  
  agrof_dhb_mean_min_max=ifelse(
    is.na(agrof_dhb_mean) & is.na(agrof_dhb_min) & is.na(agrof_dhb_max),  "",
    paste0(agrof_dhb_mean, "(", agrof_dhb_min, "-", agrof_dhb_max, ")")))%>%
  ungroup()

# Quick checks
sort(unique(fomd09.clean$agrof_subpractice_raw))
sort(unique(fomd09.clean$agrof_subpractice))
sort(unique(fomd09.clean$agrof_shade_mean_min_max))
sort(unique(fomd09.clean$agrof_canopy_height_mean_min_max))
sort(unique(fomd09.clean$agrof_dhb_mean_min_max))

#---nutrient_management_practice (inorganic)----
fomd09.clean<-fomd09.clean%>%
  rowwise() %>%
  mutate(
    fert_inorganic_type_amount_unit = if_else(
      any(is.na(c(fert_inorganic_type
                  ))),
      NA_character_,
      {
        types   <- strsplit(fert_inorganic_type, "\\.\\.")[[1]]
        amounts <- strsplit(fert_inorganic_amount, "\\.\\.")[[1]]
        units   <- strsplit(fert_inorganic_unit, "\\.\\.")[[1]]
        
        paste0(
          types, "[", amounts, "(", units, ")]",
          collapse = "..")} )) %>%
  mutate(
    fert_inorganicN = if_else(is.na(fert_inorganicN),NA_character_,paste0(fert_inorganicN, "(", fert_inorganicNPK_unit, ")")),
    fert_inorganicP = if_else(is.na(fert_inorganicP),NA_character_,paste0(fert_inorganicP, "(", fert_inorganicNPK_unit, ")")),
    fert_inorganicK = if_else(is.na(fert_inorganicK),NA_character_,paste0(fert_inorganicK, "(", fert_inorganicNPK_unit, ")")),
    fert_inorganicP2O5 = if_else(is.na(fert_inorganicP2O5),NA_character_,paste0(fert_inorganicP2O5, "(", fert_inorganicNPK_unit, ")")),
    fert_inorganicK2O = if_else(is.na(fert_inorganicK2O),NA_character_,paste0(fert_inorganicK2O, "(", fert_inorganicNPK_unit, ")")))%>%
  ungroup()

# Quick checks
sort(unique(fomd09.clean$fert_subpractice_raw))
sort(unique(fomd09.clean$fert_subpractice))
sort(unique(fomd09.clean$fert_inorganic_category))
sort(unique(fomd09.clean$fert_inorganic_type_amount_unit))
sort(unique(fomd09.clean$fert_inorganicN))
sort(unique(fomd09.clean$fert_inorganicP))
sort(unique(fomd09.clean$fert_inorganicK))
sort(unique(fomd09.clean$fert_inorganicP2O5))
sort(unique(fomd09.clean$fert_inorganicK2O))

#---nutrient_management_practice (organic)----
fomd09.clean<-fomd09.clean%>%
  rowwise() %>%
  mutate(
    fert_organic_type_amount_unit = if_else(
      any(is.na(c(fert_organic_type
      ))),
      NA_character_,
      {
        types   <- strsplit(fert_organic_type, "\\.\\.")[[1]]
        amounts <- strsplit(fert_organic_amount, "\\.\\.")[[1]]
        units   <- strsplit(fert_organic_unit, "\\.\\.")[[1]]
        
        paste0(
          types, "[", amounts, "(", units, ")]",
          collapse = "..")} )) %>%
  mutate(
    fert_organicN = if_else(is.na(fert_organicN),NA_character_,paste0(fert_organicN, "(", fert_organicNPK_unit, ")")),
    fert_organicP = if_else(is.na(fert_organicP),NA_character_,paste0(fert_organicP, "(", fert_organicNPK_unit, ")")),
    fert_organicK = if_else(is.na(fert_organicK),NA_character_,paste0(fert_organicK, "(", fert_organicNPK_unit, ")")))%>%
  ungroup()

# Quick checks
sort(unique(fomd09.clean$fert_organic_category))
sort(unique(fomd09.clean$fert_organic_type))
sort(unique(fomd09.clean$fert_organic_amount))
sort(unique(fomd09.clean$fert_organic_type_amount_unit))
sort(unique(fomd09.clean$fert_organicNPK_unit))
sort(unique(fomd09.clean$fert_organicN))
sort(unique(fomd09.clean$fert_organicP))
sort(unique(fomd09.clean$fert_organicK))
sort(unique(fomd09.clean$fert_organic_source))

#---weeding_management_moderator----
fomd09.clean<-fomd09.clean%>% 
  rowwise() %>%
  mutate( 
  weed_frequency_unit= ifelse(
    is.na(weed_frequency) & is.na(weed_frequency_unit),  NA,
    paste0(weed_frequency, "(", weed_frequency_unit,  ")")))
  
# Quick checks
sort(unique(fomd09.clean$weed_method_raw))
sort(unique(fomd09.clean$weed_method))
sort(unique(fomd09.clean$weed_frequency_unit))

#---chemical_management_practice ----
### HASTA ACA!
fomd09.clean<-fomd09.clean%>% 
    rowwise() %>%
    mutate( 
  chem_subpractice= paste(na.omit(c_across(starts_with("chem_subpractice0"))),collapse = ".."),
  
  chem_name_amount_unit = {
    subpractice <- c_across(all_of(paste0("chem_subpractice", sprintf("%02d", 1:3))))
    name   <- c_across(all_of(paste0("chem_name", sprintf("%02d", 1:3))))
    amount <- c_across(all_of(paste0("chem_amount", sprintf("%02d", 1:3))))
    unit   <- c_across(all_of(paste0("chem_unit", sprintf("%02d", 1:3))))
    
    keep <- !(is.na(subpractice) | subpractice == "")
    
    if (!any(keep)) {
      NA_character_
    } else {
      vals <- ifelse(
        is.na(name[keep]) | name[keep] == "",
        "NA[0(NA)]",
        paste0(
          name[keep], "[",
          ifelse(is.na(amount[keep]) | amount[keep] == "", "NA", amount[keep]),
          "(",
          ifelse(is.na(unit[keep]) | unit[keep] == "", "NA", unit[keep]),
          ")]"))
      
      paste(vals, collapse = "..")
    }}) %>%
  ungroup()

sort(unique(fomd09.clean$chem_subpractice_raw))
sort(unique(fomd09.clean$chem_subpractice))
sort(unique(fomd09.clean$chem_name01))
sort(unique(fomd09.clean$chem_name_amount_unit))




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


