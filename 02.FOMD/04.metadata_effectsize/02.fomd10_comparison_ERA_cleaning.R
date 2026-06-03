library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(readr)
library(tibble)
library(purrr)

path.metadata<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/01.metadata_harmonisation/02.metadata"
path.metadata.structure<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/02.metadata_structure"
path.era<-"C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/ERA/data"
list.files(path.metadata)
list.files(path.metadata.structure)
list.files(paste0(path.metadata,"/02.selected"))

#==========================================================
# Read datasets
#==========================================================
#---01_FOMD_ontologies
fomd01.countries<-read_xlsx(file.path(path.metadata.structure,"01_FOMD_ontologies.xlsx"), sheet = "01_countries")
fomd01.sites<-read_xlsx(file.path(path.metadata.structure,"01_FOMD_ontologies.xlsx"), sheet = "01_sites")

fomd01.outcomes<-read_xlsx(file.path(path.metadata.structure,"01_FOMD_ontologies.xlsx"), sheet = "01_outcomes")
fomd01.practices<-read_xlsx(file.path(path.metadata.structure,"01_FOMD_ontologies.xlsx"), sheet = "01_practices")
sort(unique(fomd01.practices$subpractice))

#---04_FOMD_screening
fomd04<-read_xlsx(file.path(path.metadata.structure,"04_FOMD_screening.xlsx"), sheet = "04_FOMD_screening")%>%
  filter(ss_id!="MD_Rosen_24_Effec_Sc")%>%
  filter(status =="I")
length(unique(fomd04$study_id))#20

#---ERA metadata short
md.era.short <- read.csv(file.path(path.era, "ERA_data_short_v6.csv"))

length(unique(md.era.short$study_id)) #1811
length(unique(md.era.short$doi)) #1592
sort(unique(md.era.short$country))

#---10_FOMD_metadata_synthesis_long
fomd10<-read_xlsx(file.path(path.metadata.structure,"10_FOMD_metadata_synthesis_short.xlsx"), sheet = "10_FOMD_metadata_synthesis")%>%
  select(-starts_with("T_"))%>%
  rename_with(~ sub("^C_", "", .x))

names(fomd10)


###########################
###################
#--- NA and empty strings count + percentage per column
n <- nrow(md.era.short)

na_empty_summary1 <- data.frame(
  na_count          = colSums(is.na(md.era.short)),
  empty_count       = colSums(md.era.short == "", na.rm = TRUE),
  total_missing     = colSums(is.na(md.era.short)) + colSums(md.era.short == "", na.rm = TRUE),
  total_missing_pct = round((colSums(is.na(md.era.short)) + colSums(md.era.short == "", na.rm = TRUE)) / n * 100, 2)
)

print(na_empty_summary1)




#---bibliographic----
md.era.short.clean<-md.era.short

# Quick checks
length(unique(md.era.short.clean$study_id)) # 1811
length(unique(md.era.short.clean$authors))  #1353
length(unique(md.era.short.clean$title)) #Missing
sort(unique(md.era.short.clean$year))  
sort(unique(md.era.short.clean$journal))  
sort(unique(md.era.short.clean$doi)) 
length(unique(md.era.short.clean$doi)) #1592

#=========================
#---location----
#=========================
# Fix site_id
sort(unique(md.era.short.clean$site_id[md.era.short.clean$country==""]))

md.era.short.clean<-md.era.short.clean%>%
  mutate(
    site_id= case_when(
      site_id=="Nkwanta Agricultural Station of the Nkwanta South District"~"Nkwanta ARS",TRUE~site_id),
    country= case_when(
      site_id=="NRC, Dokki, Cairo..Cairo University, Agricultural Experimental Station"~"Egypt..Egypt",TRUE~country)
    )
sort(unique(md.era.short.clean$site_id[md.era.short.clean$country==""]))

# Add missing location-related rows based on site_id
md.era.short.clean <- md.era.short.clean %>%
  left_join(fomd01.sites%>%
              select(site_id = Site.Id, 
                     country,
                     site_admin=Site.Admin,
                     site_latitude,
                    site_longitude, 
                     site_buffer) %>%
              filter(!is.na(site_id), !is.na(country)) %>%
              distinct(site_id, country,site_admin,site_latitude, site_longitude, site_buffer),
            by = "site_id", suffix = c("", "_lookup")) %>%
  mutate(country = if_else(country=="", country_lookup, country),
         site_admin = if_else(site_admin=="", site_admin_lookup, site_admin),
         site_latitude = if_else(site_latitude=="", as.character(site_latitude_lookup), site_latitude),
         site_longitude = if_else(site_longitude=="", as.character(site_longitude_lookup), site_longitude),
         site_buffer = if_else(site_buffer=="", as.character(site_buffer_lookup), site_buffer),
         
         ) %>%
  select(-country_lookup,-site_admin_lookup,-site_latitude_lookup)
  
sort(unique(md.era.short.clean$site_id[is.na(md.era.short.clean$country)]))

md.era.short.clean <- md.era.short.clean%>%

  mutate(
    country=case_when(
      country==""|is.na(country)&site_id!=""~"Missing",
      country==""|is.na(country)&site_id==""~"Unspecified",
      TRUE~country),
    
    site_type=case_when(
      site_type==""&site_id!=""~"Missing",
      site_type==""&site_id==""~"Unspecified",
      TRUE~site_type),

    site_admin=case_when(
      site_admin==""|is.na(site_admin)&site_id!=""~"Missing",
      site_admin==""|is.na(site_admin)&site_id==""~"Unspecified",
      TRUE~site_admin),
    
    site_agg=case_when(
      site_agg==""~"Unspecified",
      site_agg==""~"Missing",
      TRUE~site_agg),
    
    site_latlong_type=case_when(
      is.na(site_latlong_type)&site_latitude==""|is.na(site_latitude)~"Unspecified",
      is.na(site_latlong_type)&site_latitude!=""|!is.na(site_latitude)~"Missing",
      TRUE~site_latlong_type),
    
    site_latitude=case_when(is.na(site_latitude)~"Unspecified",TRUE~site_latitude),
    site_longitude=case_when(is.na(site_longitude)~"Unspecified",TRUE~site_longitude),
    
    site_buffer=case_when(is.na(site_buffer)~"Unspecified",TRUE~site_buffer)
    )


sort(unique(md.era.short.clean$site_id[is.na(md.era.short.clean$country)]))

md.era.short.clean <- md.era.short.clean %>%
  rowwise() %>%
  mutate(
    site_key = {
      lat  <- strsplit(as.character(site_latitude),  "\\.\\.")[[1]]
      long <- strsplit(as.character(site_longitude), "\\.\\.")[[1]]
      b    <- strsplit(as.character(site_buffer),    "\\.\\.")[[1]]
      
      n <- max(length(lat), length(long), length(b))
      
      pad <- function(x, n) { length(x) <- n; x }
      lat  <- pad(lat, n)
      long <- pad(long, n)
      b    <- pad(b, n)
      
      vals <- mapply(function(la, lo, bu) {
        if (all(is.na(c(la, lo)))) return(NA_character_)
        paste0(
          ifelse(is.na(lo) | lo == "" | lo == "Missing", "NA", trimws(lo)), " ",
          ifelse(is.na(la) | la == "" | la == "Missing", "NA", trimws(la)),
          ifelse(is.na(bu) | bu == "" | bu == "Missing", " BUnspecified", paste0(" B", trimws(bu)))
        )
      }, lat, long, b)
      
      paste0(na.omit(vals), collapse = "..")
    }
  ) %>%
  ungroup()
  

sort(unique(md.era.short.clean$country))
sort(unique(md.era.short.clean$site_type))
sort(unique(md.era.short.clean$site_id))
sort(unique(md.era.short.clean$site_admin))
sort(unique(md.era.short.clean$site_agg))
sort(unique(md.era.short.clean$site_latlong_type))
sort(unique(md.era.short.clean$site_latitude))
sort(unique(md.era.short.clean$site_longitude))
sort(unique(md.era.short.clean$site_buffer))
sort(unique(md.era.short.clean$site_key))
  

site_cols <- c("country",  "site_type", "site_id", "site_admin",
               "site_agg", "site_latlong_type", "site_latitude", "site_longitude",
               "site_buffer", "site_key")

# Create T_ and C_ versions, keeping originals
md.era.short.clean <- md.era.short.clean %>%
  mutate(across(all_of(site_cols), ~ .x, .names = "T_{.col}")) %>%
  mutate(across(all_of(site_cols), ~ .x, .names = "C_{.col}"))

# Quick checks
names(md.era.short.clean)
length(unique(md.era.short.clean$T_site_key))  #1887
length(unique(md.era.short.clean$C_site_key))  #1887

#=========================
#---experiment_details----
#=========================
## TO CHECK: see what to do here, this can differ from T and C

experiment_cols <- c("exp_plot_size",  "exp_field_size")

# Create T_ and C_ versions, keeping originals
md.era.short.clean <- md.era.short.clean%>% 
  mutate(across(all_of(experiment_cols), ~ .x, .names = "T_{.col}")) %>%
  mutate(across(all_of(experiment_cols), ~ .x, .names = "C_{.col}"))

# Quick checks
sort(unique(md.era.short.clean$exp_design))
sort(unique(md.era.short.clean$T_exp_plot_size))
sort(unique(md.era.short.clean$exp_field_size)) #does not exist in ERA
sort(unique(md.era.short.clean$exp_duration))

#=========================
#---experiment_time----
#=========================
## TO CHECK: see what to do here, this can differ from T and C
# Quick checks
sort(unique(md.era.short.clean$time_raw)) #does not exist in ERA
sort(unique(md.era.short.clean$time_year_start))
sort(unique(md.era.short.clean$time_year_end))
sort(unique(md.era.short.clean$time_season))

#=========================
#---practice----
#=========================
## TO CHECK:NEED TO INFER T_system_type and C_system_type
sort(unique(md.era.short.clean$C_subpractice_description_raw))
sort(unique(md.era.short.clean$T_subpractice_description_raw))

sort(unique(md.era.short.clean$C_system_type))
sort(unique(md.era.short.clean$T_system_type))

#=========================
#---commodity_crop----
#=========================
## TO CHECK: variety
create_density <- function(diversity, density) {
  # If either is empty, return empty
  if (diversity == "" | is.na(diversity)) return("")
  
  # Extract the delimiter sequence from diversity string
  # Split keeping delimiters
  div_parts <- strsplit(diversity, "(?<=[^/-])(?=[/-])|(?<=[/-])(?=[^/-])", perl = TRUE)[[1]]
  den_parts <- strsplit(density,   "(?<=[^/-])(?=[/-])|(?<=[/-])(?=[^/-])", perl = TRUE)[[1]]
  
  # Separate crop names and separators
  div_crops <- div_parts[!div_parts %in% c("/", "-")]
  div_seps  <- div_parts[ div_parts %in% c("/", "-")]
  
  den_crops <- den_parts[!den_parts %in% c("/", "-")]
  den_seps  <- den_parts[ den_parts %in% c("/", "-")]
  
  # Pair each crop with its density
  paired <- mapply(function(crop, dens) {
    if (is.na(dens) || dens == "NA") {
      paste0(crop, "[Unspecified(Unspecified)]")
    } else {
      paste0(crop, "[", dens, ")]")
    }
  }, div_crops, den_crops)
  
  # Reconstruct with original separators
  result <- paired[1]
  if (length(div_seps) > 0) {
    for (i in seq_along(div_seps)) {
      result <- paste0(result, div_seps[i], paired[i + 1])
    }
  }
  
  return(result)
}

md.era.short.clean$C_crop_density <- mapply(
  create_density,
  md.era.short.clean$C_crop_diversity,
  md.era.short.clean$C_crop_density
)

md.era.short.clean$T_crop_density <- mapply(
  create_density,
  md.era.short.clean$T_crop_diversity,
  md.era.short.clean$T_crop_density
)

# Quick checks
sort(unique(md.era.short.clean$C_crop_diversity))
sort(unique(md.era.short.clean$T_crop_diversity))

sort(unique(md.era.short.clean$C_crop_variety))
sort(unique(md.era.short.clean$T_crop_variety))

sort(unique(md.era.short.clean$C_crop_density))
sort(unique(md.era.short.clean$T_crop_density))

#=========================
#---commodity_tree----
#=========================
md.era.short.clean$C_tree_density <- mapply(
  create_density,
  md.era.short.clean$C_tree_diversity,
  md.era.short.clean$C_tree_density
)

md.era.short.clean$T_tree_density <- mapply(
  create_density,
  md.era.short.clean$T_tree_diversity,
  md.era.short.clean$T_tree_density
)

# Quick checks
sort(unique(md.era.short.clean$C_tree_diversity))
sort(unique(md.era.short.clean$T_tree_diversity))

sort(unique(md.era.short.clean$C_tree_density))
sort(unique(md.era.short.clean$T_tree_density))

#=========================
#---commodity_animal----
#=========================
## TO CHECK: breed and density

# Quick checks
sort(unique(md.era.short.clean$C_animal_diversity))
sort(unique(md.era.short.clean$T_animal_diversity))

sort(unique(md.era.short.clean$C_animal_breed))
sort(unique(md.era.short.clean$T_animal_breed))

sort(unique(md.era.short.clean$C_animal_density))
sort(unique(md.era.short.clean$T_animal_density))


#=========================
#---soil_management_practice---- 
#=========================
## TO CHECK: C_tillage_subpractice and T_tillage_subpractice

md.era.short.clean$C_tillage_method <- gsub("; ", "..", md.era.short.clean$C_tillage_method)
md.era.short.clean$T_tillage_method <- gsub("; ", "..", md.era.short.clean$T_tillage_method)
md.era.short.clean$C_tillage_method_other <- gsub("; ", "..", md.era.short.clean$C_tillage_method_other)
md.era.short.clean$T_tillage_method_other <- gsub("; ", "..", md.era.short.clean$T_tillage_method_other)
md.era.short.clean$C_tillage_frequency <- gsub("; ", "..", md.era.short.clean$C_tillage_frequency)
md.era.short.clean$T_tillage_frequency <- gsub("; ", "..", md.era.short.clean$T_tillage_frequency)

# Quick checks
sort(unique(md.era.short.clean$C_tillage_subpractice_raw))
sort(unique(md.era.short.clean$T_tillage_subpractice_raw))

sort(unique(md.era.short.clean$C_tillage_subpractice))
sort(unique(md.era.short.clean$T_tillage_subpractice))

sort(unique(md.era.short.clean$C_tillage_method))
sort(unique(md.era.short.clean$T_tillage_method))

sort(unique(md.era.short.clean$C_tillage_method_other))
sort(unique(md.era.short.clean$T_tillage_method_other))

sort(unique(md.era.short.clean$C_tillage_depth))
sort(unique(md.era.short.clean$T_tillage_depth))

sort(unique(md.era.short.clean$C_tillage_frequency))
sort(unique(md.era.short.clean$T_tillage_frequency))

#=========================
#---planting_practice----
#=========================
## TO CHECK: C_planting_method and T_planting_method

# Quick checks
sort(unique(md.era.short.clean$C_planting_subpractice_raw))
sort(unique(md.era.short.clean$T_planting_subpractice_raw))

sort(unique(md.era.short.clean$C_planting_subpractice))
sort(unique(md.era.short.clean$T_planting_subpractice))

sort(unique(md.era.short.clean$C_planting_method))
sort(unique(md.era.short.clean$T_planting_method))

sort(unique(md.era.short.clean$C_planting_date_start))
sort(unique(md.era.short.clean$T_planting_date_start))

sort(unique(md.era.short.clean$C_planting_date_end))
sort(unique(md.era.short.clean$T_planting_date_end))

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

#=========================
#---intercropping_practice----
#=========================
##TO CHECK:C_intercrop_subpractice and T_intercrop_subpractice

# Quick checks
sort(unique(md.era.short.clean$C_intercrop_subpractice_raw))
sort(unique(md.era.short.clean$T_intercrop_subpractice_raw))

sort(unique(md.era.short.clean$C_intercrop_subpractice))
sort(unique(md.era.short.clean$T_intercrop_subpractice))

sort(unique(md.era.short.clean$intercrop_design)) #Missing from ERA (in the process of getting it)
sort(unique(md.era.short.clean$intercrop_pattern)) #Missing from ERA (in the process of getting it)

sort(unique(md.era.short.clean$C_intercrop_start_year))
sort(unique(md.era.short.clean$T_intercrop_start_year))

sort(unique(md.era.short.clean$C_intercrop_start_season))
sort(unique(md.era.short.clean$T_intercrop_start_season))

sort(unique(md.era.short.clean$C_intercrop_residues_fate))
sort(unique(md.era.short.clean$T_intercrop_residues_fate))

#=========================
#---crop_sequence_practice----
#=========================
## TO CHECK: C_crop_seq_subpractice and T_crop_seq_subpractice
md.era.short.clean$C_crop_seq_residues_fate <- gsub("; ", "..", md.era.short.clean$C_crop_seq_residues_fate)
md.era.short.clean$T_crop_seq_residues_fate <- gsub("; ", "..", md.era.short.clean$T_crop_seq_residues_fate)

# Quick checks
sort(unique(md.era.short.clean$C_crop_seq_subpractice_raw))
sort(unique(md.era.short.clean$T_crop_seq_subpractice_raw))

sort(unique(md.era.short.clean$C_crop_seq_subpractice))
sort(unique(md.era.short.clean$T_crop_seq_subpractice))

sort(unique(md.era.short.clean$C_crop_seq_start_year))
sort(unique(md.era.short.clean$T_crop_seq_start_year))

sort(unique(md.era.short.clean$C_crop_seq_start_season))
sort(unique(md.era.short.clean$T_crop_seq_start_season))

sort(unique(md.era.short.clean$C_crop_seq_residues_fate))
sort(unique(md.era.short.clean$T_crop_seq_residues_fate))

#=========================
#---agroforestry_practice----
#=========================
##CHECK TO : verificar later if it is better to keep track of spatial, component, shade..
## TO CHECK: C_agrof_subpractice and T_agrof_subpractice
sort(unique(md.era.short.clean$C_agrof_subpractice_raw))
sort(unique(md.era.short.clean$T_agrof_subpractice_raw))

sort(unique(md.era.short.clean$C_agrof_subpractice))
sort(unique(md.era.short.clean$T_agrof_subpractice))

sort(unique(md.era.short.clean$agrof_shade_mean_min_max)) #Missing from ERA
sort(unique(md.era.short.clean$agrof_canopy_height_mean_min_max)) #Missing from ERA
sort(unique(md.era.short.clean$agrof_dhb_mean_min_max))#Missing from ERA


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


#=========================
#---product_outcome----
#=========================
md.era.short.clean$C_product <- gsub("\\*", "..", md.era.short.clean$C_product)
md.era.short.clean$C_product <- gsub(" & ", "..", md.era.short.clean$C_product, fixed = TRUE)
md.era.short.clean$C_product <- gsub(", ", "..", md.era.short.clean$C_product, fixed = TRUE)

md.era.short.clean$T_product <- gsub("\\*", "..", md.era.short.clean$T_product)
md.era.short.clean$T_product <- gsub(" & ", "..", md.era.short.clean$T_product, fixed = TRUE)
md.era.short.clean$T_product <- gsub(", ", "..", md.era.short.clean$T_product, fixed = TRUE)

md.era.short.clean$C_product_type <- gsub("**", "..", md.era.short.clean$C_product_type, fixed = TRUE)
md.era.short.clean$T_product_type <- gsub("**", "..", md.era.short.clean$T_product_type, fixed = TRUE)

md.era.short.clean$C_product_subtype <- gsub("**", "..", md.era.short.clean$C_product_subtype, fixed = TRUE)
md.era.short.clean$T_product_subtype <- gsub("**", "..", md.era.short.clean$T_product_subtype, fixed = TRUE)

md.era.short.clean$C_product_simple <- gsub("**", "..", md.era.short.clean$C_product_simple, fixed = TRUE)
md.era.short.clean$T_product_simple <- gsub("**", "..", md.era.short.clean$T_product_simple, fixed = TRUE)

md.era.short.clean$C_econ_inputs <- gsub("; ", "..", md.era.short.clean$C_econ_inputs)
md.era.short.clean$T_econ_inputs <- gsub("; ", "..", md.era.short.clean$T_econ_inputs)

sort(unique(md.era.short.clean$C_product))
sort(unique(md.era.short.clean$T_product))

sort(unique(md.era.short.clean$C_product_type)) #to RECLASIFIED AGAIN BASED ON C_product_simple
sort(unique(md.era.short.clean$T_product_type))#to RECLASIFIED AGAIN BASED ON T_product_simple

sort(unique(md.era.short.clean$C_product_subtype)) #to RECLASIFIED AGAIN BASED ON C_product_simple
sort(unique(md.era.short.clean$T_product_subtype)) #to RECLASIFIED AGAIN BASED ON T_product_simple

sort(unique(md.era.short.clean$C_product_simple)) #to RECLASIFIED AGAIN BASED ON C_product_simple
sort(unique(md.era.short.clean$T_product_simple)) #to RECLASIFIED AGAIN BASED ON T_product_simple

sort(unique(md.era.short.clean$C_econ_inputs)) 
sort(unique(md.era.short.clean$T_econ_inputs)) 

sort(unique(md.era.short.clean$bio_func_group)) #Missing from ERA
sort(unique(md.era.short.clean$bio_ground_ref))#Missing from ERA

#=========================
#---product_outcome----
#=========================
md.era.short.clean<-md.era.short.clean

sort(unique(md.era.short.clean$out_subindicator))
sort(unique(md.era.short.clean$out_indicator)) #to RECLASIFIED AGAIN BASED ON out_subindicator
sort(unique(md.era.short.clean$out_subpillar)) #to RECLASIFIED AGAIN BASED ON out_subindicator
sort(unique(md.era.short.clean$out_pillar)) #to RECLASIFIED AGAIN BASED ON out_subindicator
sort(unique(md.era.short.clean$out_subindicator_unit))

sort(unique(md.era.short.clean$C_out_soil_depth_u))
sort(unique(md.era.short.clean$T_out_soil_depth_u))

sort(unique(md.era.short.clean$C_out_soil_depth_l))
sort(unique(md.era.short.clean$T_out_soil_depth_l))

#=========================
#---outcome_value----
#=========================
# Fix the values to "Mean"
md.era.short.clean$C_out_metric <- gsub("mean", "Mean", md.era.short.clean$C_out_metric, fixed = TRUE)
md.era.short.clean$T_out_metric <- gsub("mean", "Mean", md.era.short.clean$T_out_metric, fixed = TRUE)

sort(unique(md.era.short.clean$C_out_metric))
sort(unique(md.era.short.clean$T_out_metric))
na_empty_summary1["C_out_metric", ]
na_empty_summary1["T_out_metric", ]

sort(unique(md.era.short.clean$C_out_value))
sort(unique(md.era.short.clean$T_out_value))
na_empty_summary1["C_out_value", ]
na_empty_summary1["T_out_value", ]

sort(unique(md.era.short.clean$C_out_var_metric))
sort(unique(md.era.short.clean$T_out_var_metric))
na_empty_summary1["C_out_var_metric", ]
na_empty_summary1["T_out_var_metric", ]

sort(unique(md.era.short.clean$C_out_var_value))
sort(unique(md.era.short.clean$T_out_var_value))
na_empty_summary1["C_out_var_value", ]
na_empty_summary1["T_out_var_value", ]

sort(unique(md.era.short.clean$C_out_sample_size))
sort(unique(md.era.short.clean$T_out_sample_size))
na_empty_summary1["C_out_sample_size", ]
na_empty_summary1["T_out_sample_size", ]

sort(unique(md.era.short.clean$C_data_location))
sort(unique(md.era.short.clean$T_data_location))


#-----------------------------------------------
#---- Match with 01_FOMD_ontologies ----
#-----------------------------------------------
library(tibble)
library(purrr)

#=========================
#---location----
#=========================
#--- lookup vector: names = country, values = ISO_3166_1_Alpha_3
lookup.country.iso <- fomd01.countries %>%
  transmute(
    country = str_squish(Country),
    country.iso    = str_squish(ISO_3166_1_Alpha_3)
  ) %>%
  distinct() %>%
  deframe()

sort(unique(md.era.short.clean$country))
sort(unique(md.era.short.clean$country_ISO))

#---location
md.era.short.clean <- md.era.short.clean %>%
  mutate(country_ISO = case_when(
    country_ISO == "" & country != "" ~ map_chr(str_split(str_squish(country), "\\.\\."), \(x) {
      tokens <- str_squish(x)
      out <- unname(lookup.country.iso[tokens])
      #out[is.na(out)] <- tokens[is.na(out)]  # keep original if no match
      paste(out, collapse = "..")
    }),
    TRUE ~ country_ISO
  ))

sort(unique(md.era.short.clean$country))
sort(unique(md.era.short.clean$country_ISO))
# hay un problema con India

md.era.short.clean1 <- md.era.short.clean %>%
  filter(is.na(country_ISO))


#Remove duplicate country and country_ISO
md.era.short.clean <- md.era.short.clean %>%
  mutate(
    country     = map_chr(str_split(str_squish(country), "\\.\\."), \(x) paste(unique(str_squish(x)), collapse = "..")),
    country_ISO = map_chr(str_split(str_squish(country_ISO), "\\.\\."), \(x) paste(unique(str_squish(x)), collapse = ".."))
  )

sort(unique(md.era.short.clean$country))
sort(unique(md.era.short.clean$country_ISO))

#=========================
#---product_outcome----
#=========================
md.era.short.clean1<-md.era.short.clean

#--- lookup vector: names = product, values = ISO_3166_1_Alpha_3
lookup.country.iso <- fomd01.countries %>%
  transmute(
    country = str_squish(Country),
    country.iso    = str_squish(ISO_3166_1_Alpha_3)
  ) %>%
  distinct() %>%
  deframe()



n <- nrow(md.era.short)

na_empty_summary1 <- data.frame(
  na_count          = colSums(is.na(md.era.short)),
  empty_count       = colSums(md.era.short == "", na.rm = TRUE),
  total_missing     = colSums(is.na(md.era.short)) + colSums(md.era.short == "", na.rm = TRUE),
  total_missing_pct = round((colSums(is.na(md.era.short)) + colSums(md.era.short == "", na.rm = TRUE)) / n * 100, 2)
)

print(na_empty_summary1)