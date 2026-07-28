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
path.functions<-"C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/04.metadata_effectsize/fomd_fun"
path.metadata.effectsize<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/04.metadata_effectsize"

list.files(path.era)

list.files(path.metadata)
list.files(path.metadata.structure)
list.files(paste0(path.metadata,"/02.selected"))
list.files(path.functions)

#==========================================================
# Read functions
#==========================================================
source(file.path(path.functions,"/fun_lookup_ontologies.R"))
source(file.path(path.functions,"/fun_load_data_ontologies.R"))
source(file.path(path.functions,"/fun_cleaning.R"))
source(file.path(path.functions,"/fun_cleaning_09_FOMD.R"))
source(file.path(path.functions,"/fun_lookup_commodities.R"))


#==========================================================
# Read datasets
#==========================================================
#---01_FOMD_ontologies
fomd01.outcomes<-fomd01.outcomes%>%
  filter(!is.na(subindicator) )

#---04_FOMD_screening 
## TO CHECK: NEED TO UPDATE THE LIST OF PAPERS FROM ERA IN SCREENING AND IN IDENTIFIED DATASETS!!
fomd04<-read_xlsx(file.path(path.metadata.structure,"04_FOMD_screening.xlsx"), sheet = "04_FOMD_screening")%>%
  filter(ss_id=="MD_Rosen_24_Effec_Sc")%>%
  filter(status =="I")
length(unique(fomd04$study_id))#1720
length(unique(fomd04$study_id_ss))#1811

#---ERA metadata short
#md.era.short <- read.csv(file.path(path.era, "ERA_data_short_v6.csv"))
#md.era.short <- read.csv(file.path(path.era, "ERA_data_short_v12.csv"))
#md.era.short <- read.csv(file.path(path.era, "ERA_data_short_v16.csv"))
#md.era.short <- read.csv(file.path(path.era, "ERA_data_short_v22.csv"))
#md.era.short <- read.csv(file.path(path.era, "ERA_data_short_v24.csv"))
#md.era.short <- read.csv(file.path(path.era, "ERA_data_short_v32.csv"))
#md.era.short <- read.csv(file.path(path.era, "ERA_data_short_v41.csv"))
#md.era.short <- read.csv(file.path(path.era, "ERA_data_short_v45.csv"))
md.era.short <- read.csv(file.path(path.era, "ERA_data_short_v46.csv"))


length(unique(md.era.short$study_id)) #1811 studies
length(unique(md.era.short$doi)) #1592
sort(unique(md.era.short$country))

#---10_FOMD_metadata_synthesis_long
fomd10<-read_xlsx(file.path(path.metadata.structure,"10_FOMD_metadata_synthesis_short.xlsx"), sheet = "10_FOMD_metadata_synthesis")
names(fomd10)


###########################
###################
#--- NA and empty strings count + percentage per column
n <- nrow(md.era.short)

na_empty_summary <- data.frame(
  na_count          = colSums(is.na(md.era.short)),
  empty_count       = colSums(md.era.short == "", na.rm = TRUE),
  total_missing     = colSums(is.na(md.era.short)) + colSums(md.era.short == "", na.rm = TRUE),
  total_missing_pct = round((colSums(is.na(md.era.short)) + colSums(md.era.short == "", na.rm = TRUE)) / n * 100, 2)
)

print(na_empty_summary)

#---bibliographic----
md.era.short.clean<-md.era.short

md.era.short.clean<-md.era.short.clean%>%
  select(-title)%>%
  left_join(fomd04%>%
              select(study_id_ss, title),
            by=c("study_id"= "study_id_ss"))

names(md.era.short.clean)

# Quick checks
length(unique(md.era.short.clean$study_id)) # 1811 studies
length(unique(md.era.short.clean$effect_size_id))  #232257 rows
length(unique(md.era.short.clean$authors))  #1353
length(unique(md.era.short.clean$title)) #958
sort(unique(md.era.short.clean$year))  
sort(unique(md.era.short.clean$journal))  
sort(unique(md.era.short.clean$doi)) 
length(unique(md.era.short.clean$doi)) #1592
sort(unique(md.era.short.clean$title))
#=============================================
#---location----
#=========================
# Fix site_id
sort(unique(md.era.short.clean$site_id[md.era.short.clean$country==""])) #"Cedara Research Station"
sort(unique(md.era.short.clean$site_id[md.era.short.clean$site_type==""])) #10
sort(unique(md.era.short.clean$site_id[md.era.short.clean$site_admin==""])) #13

md.era.short.clean<-md.era.short.clean%>%
  mutate(
    country=case_when(
      site_id=="Cedara Research Station"~"South Africa",
      country=="DRC"~"Congo (Democratic Republic of the)",
      TRUE~country),
    
    site_id= case_when(
      site_id=="Nkwanta Agricultural Station of the Nkwanta South District"~"Nkwanta ARS",
      TRUE~site_id),
    
    site_type=case_when(
      site_type==""&
        site_id %in%c(
          "Animal Production Research Institute, Agriculture Research Center, Ministry of Agriculture, Dokki, Giza",
          "Cedara Research Station",                                                                                            
          "Makoholi Research Station",
          "Nkwanta ARS")~"Researcher Managed & Research Facility",
      TRUE~site_type),
    site_admin=case_when(site_admin=="Ghana"&site_id=="Council for Scientific Research - Manga Station"~"Facility",
                         TRUE~site_admin))

sort(unique(md.era.short.clean$site_id[md.era.short.clean$country==""])) #character(0)
sort(unique(md.era.short.clean$site_id[md.era.short.clean$site_type==""])) #6
sort(unique(md.era.short.clean$site_id[md.era.short.clean$site_admin==""])) #13
sort(unique(md.era.short.clean$site_id[md.era.short.clean$site_latitude==""])) #11
sort(unique(md.era.short.clean$site_id[md.era.short.clean$site_longitude==""])) #11
sort(unique(md.era.short.clean$site_id[md.era.short.clean$site_buffer==""]))
sort(unique(md.era.short.clean$site_admin))

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
  mutate(site_admin = if_else(site_admin=="", site_admin_lookup, site_admin),
         site_latitude = if_else(site_latitude=="", as.character(site_latitude_lookup), site_latitude),
         site_longitude = if_else(site_longitude=="", as.character(site_longitude_lookup), site_longitude),
         site_buffer = if_else(site_buffer=="", as.character(site_buffer_lookup), site_buffer),
         
  ) %>%
  select(-country_lookup,-site_admin_lookup,-site_latitude_lookup)

sort(unique(md.era.short.clean$site_id[is.na(md.era.short.clean$site_admin)]))
sort(unique(md.era.short.clean$site_id[is.na(md.era.short.clean$site_latitude)]))
sort(unique(md.era.short.clean$site_id[is.na(md.era.short.clean$site_longitude)]))
sort(unique(md.era.short.clean$site_id[is.na(md.era.short.clean$site_buffer)]))
sort(unique(md.era.short.clean$site_id[md.era.short.clean$site_type==""]))
sort(unique(md.era.short.clean$site_id[md.era.short.clean$site_agg==""]))
sort(unique(md.era.short.clean$site_id[md.era.short.clean$site_latitude==""]))

md.era.short.clean <- md.era.short.clean%>%
  mutate(site_type = case_when(
    site_type == "" ~ sapply(site_id, function(x) {
      n <- length(stringr::str_split(x, fixed(".."))[[1]])
      paste(rep("Unspecified", n), collapse = "..")
    }),
    TRUE ~ site_type))%>%
  
  mutate(site_agg = case_when(
    site_agg == "" ~ sapply(site_id, function(x) {
      n <- length(stringr::str_split(x, fixed(".."))[[1]])
      paste(rep("Unspecified", n), collapse = "..")
    }),
    TRUE ~ site_agg))%>%
  
  mutate(site_admin = case_when(
    site_admin == ""|is.na(site_admin) ~ sapply(site_id, function(x) {
      n <- length(stringr::str_split(x, fixed(".."))[[1]])
      paste(rep("Unspecified", n), collapse = "..")
    }),
    TRUE ~ site_admin))%>%
  
  mutate(site_latlong_type = case_when(
    site_latlong_type == ""|is.na(site_latlong_type) ~ sapply(site_id, function(x) {
      n <- length(stringr::str_split(x, fixed(".."))[[1]])
      paste(rep("Missing", n), collapse = "..")
    }),
    TRUE ~ site_latlong_type))%>%
  
  mutate(site_latitude = case_when(
    site_latitude == ""|is.na(site_latitude) ~ sapply(site_id, function(x) {
      n <- length(stringr::str_split(x, fixed(".."))[[1]])
      paste(rep("Unspecified", n), collapse = "..")
    }),
    TRUE ~ site_latitude))%>%
  
  mutate(site_longitude = case_when(
    site_longitude == "" |is.na(site_longitude)~ sapply(site_id, function(x) {
      n <- length(stringr::str_split(x, fixed(".."))[[1]])
      paste(rep("Unspecified", n), collapse = "..")
    }),
    TRUE ~ site_longitude))%>%
  
  mutate(site_buffer = case_when(
    site_buffer == "" |is.na(site_buffer) ~ sapply(site_id, function(x) {
      n <- length(stringr::str_split(x, fixed(".."))[[1]])
      paste(rep("Unspecified", n), collapse = "..")
    }),
    TRUE ~ site_buffer))%>%
  mutate(
    site_latitude  = gsub("\\s*\\.\\.\\s*", "..", site_latitude),
    site_longitude = gsub("\\s*\\.\\.\\s*", "..", site_longitude)
  )

# Quick checks
sort(unique(md.era.short.clean$site_id[md.era.short.clean$site_type==""])) #character(0)
sort(unique(md.era.short.clean$site_id[md.era.short.clean$site_agg==""])) #character(0)
sort(unique(md.era.short.clean$site_id[is.na(md.era.short.clean$country)])) #character(0)
sort(unique(md.era.short.clean$site_id[md.era.short.clean$country=="Missing"])) #character(0)
sort(unique(md.era.short.clean$site_id[md.era.short.clean$country=="Unspecified"]))
sort(unique(md.era.short.clean$country)) #61 countries
sort(unique(md.era.short.clean$site_type))
sort(unique(md.era.short.clean$site_id))
sort(unique(md.era.short.clean$site_admin))
sort(unique(md.era.short.clean$site_agg))
sort(unique(md.era.short.clean$site_latlong_type))
sort(unique(md.era.short.clean$site_latitude))
sort(unique(md.era.short.clean$site_longitude))
sort(unique(md.era.short.clean$site_buffer))
sort(unique(md.era.short.clean$site_key))

md.era.short.clean <- md.era.short.clean %>%
  mutate(site_buffer = gsub("\\bNA\\b", "Unspecified", site_buffer))%>%
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

site_cols <- c("country",  "site_type", "site_id", "site_admin",
               "site_agg", "site_latlong_type", "site_latitude", "site_longitude",
               "site_buffer", "site_key")

# Create T_ and C_ versions, keeping originals
md.era.short.clean <- md.era.short.clean %>%
  mutate(across(all_of(site_cols), ~ .x, .names = "T_{.col}")) %>%
  mutate(across(all_of(site_cols), ~ .x, .names = "C_{.col}"))

# Quick checks----
length(unique(md.era.short.clean$T_site_key))  #1891
length(unique(md.era.short.clean$C_site_key))  #1891
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

#=============================================
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

#=============================================
#---experiment_time----
#=========================
## TO CHECK: see what to do here, this can differ from T and C
md.era.short.clean$time_year_start <- gsub("...", "..", md.era.short.clean$time_year_start, fixed = TRUE)

# Quick checks
sort(unique(md.era.short.clean$time_raw)) #does not exist in ERA
sort(unique(md.era.short.clean$time_year_start))
sort(unique(md.era.short.clean$time_year_end))
sort(unique(md.era.short.clean$time_season))

#=============================================
#---practice----
#=========================
## TO CHECK:NEED TO INFER T_system_type and C_system_type
sort(unique(md.era.short.clean$C_subpractice_description_raw))
sort(unique(md.era.short.clean$T_subpractice_description_raw))

sort(unique(md.era.short.clean$C_system_type))
sort(unique(md.era.short.clean$T_system_type))

#=============================================
#---commodity_crop_tree ----
#=========================
## TO CHECK: 31 Missing crops/trees from the ontologies

# --- Rename crop_tree columns
names(md.era.short.clean) <- gsub("^C_plant_", "C_crop_tree_", names(md.era.short.clean))
names(md.era.short.clean) <- gsub("^T_plant_", "T_crop_tree_", names(md.era.short.clean))

# Apply all fixes to any set of columns
crop_tree_cols <- c("C_crop_tree_diversity", "T_crop_tree_diversity",
                    "C_crop_tree_variety","T_crop_tree_variety",
                    "C_crop_tree_density","T_crop_tree_density")

md.era.short.clean <- md.era.short.clean %>%
  mutate(across(all_of(crop_tree_cols), ~ apply_crop_fixes(., crop_name_fixes)))

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = crop_tree_cols,
  pattern = "Ficus vallis choudae choudae",replacement =  "Ficus vallis choudae") 

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = crop_tree_cols,
  pattern = "Cashew Nut",replacement =  "Cashew")

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = crop_tree_cols,
  pattern = "Cattle-Camel-Small Ruminants-",replacement =  "") 

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = crop_tree_cols,
  pattern = "Cattle(NA)-Camel(NA)-Small Ruminants(NA)",replacement =  "") 

md.era.short.clean[c("C_crop_tree_density", "T_crop_tree_density")] <- lapply(
  md.era.short.clean[c("C_crop_tree_density", "T_crop_tree_density")],
  function(x) gsub("(?<![\\w.])NA(?![\\w.])", "Unspecified(Unspecified)", x, perl = TRUE)
)

### Remove extra * from C_crop_trees_variety and T_crop_trees_variety
md.era.short.clean <- md.era.short.clean%>%
  mutate(
    # Replace ANY sequence of 1 or more * with exactly **
    C_crop_tree_variety = gsub("\\*+", "**", C_crop_tree_variety),
    C_crop_tree_variety = gsub("\\$+", "**", C_crop_tree_variety),
    C_crop_tree_variety = gsub("\\(\\s*NA\\s*\\)", "(Unspecified)", C_crop_tree_variety, ignore.case = TRUE),
    
    T_crop_tree_variety = gsub("\\*+", "**", T_crop_tree_variety),
    T_crop_tree_variety = gsub("\\$+", "**", T_crop_tree_variety),
    T_crop_tree_variety = gsub("\\(\\s*NA\\s*\\)", "(Unspecified)", T_crop_tree_variety, ignore.case = TRUE),
    
    C_crop_tree_density= case_when(C_crop_tree_diversity!=""&C_crop_tree_density==""~ "Unspecified(Unspecified)",TRUE~C_crop_tree_density),
    T_crop_tree_density= case_when(T_crop_tree_diversity!=""&T_crop_tree_density==""~ "Unspecified(Unspecified)",TRUE~T_crop_tree_density)
  )


md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_crop_tree_variety","T_crop_tree_variety"),
  pattern = "Arabica(Unspecified)",replacement =  "Arabica(Arabica)") 

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_crop_tree_variety","T_crop_tree_variety"),
  pattern = "Arabica(",replacement =  "Coffee arabica(") 

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_crop_tree_diversity","T_crop_tree_diversity"),
  pattern = "Arabica",replacement =  "Coffee arabica")

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_crop_tree_variety","T_crop_tree_variety"),
  pattern = "Robusta(Unspecified)",replacement =  "Robusta(Robusta)") 

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_crop_tree_variety","T_crop_tree_variety"),
  pattern = "Robusta(",replacement =  "Coffee robusta(") 

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_crop_tree_diversity","T_crop_tree_diversity"),
  pattern = "Robusta",replacement =  "Coffee robusta")

#Combine crop_tree_diversity + crop_tree_density columns separated by "/" or "-"
md.era.short.clean <- md.era.short.clean%>%
  mutate(
    C_crop_tree_density=mapply(create_density_crop,C_crop_tree_diversity,C_crop_tree_density),
    T_crop_tree_density=mapply(create_density_crop,T_crop_tree_diversity,T_crop_tree_density)
  )


## Quick checks----
sort(unique(md.era.short.clean$C_crop_tree_diversity))
sort(unique(md.era.short.clean$T_crop_tree_diversity))

# List of missing crops from 01_product_new to pass to Lolita
unique_crops_diversity <- rbind(
  data.frame(crop_tree_diversity = md.era.short.clean %>%
               filter(C_crop_tree_diversity != "") %>%
               pull(C_crop_tree_diversity) %>%
               str_split("[/\\-]") %>%
               unlist() %>%
               str_trim()),
  data.frame(crop_tree_diversity = md.era.short.clean %>%
               filter(T_crop_tree_diversity != "") %>%
               pull(T_crop_tree_diversity) %>%
               str_split("[/\\-]") %>%
               unlist() %>%
               str_trim())) %>%
  distinct(crop_tree_diversity) %>%
  arrange(crop_tree_diversity)%>%
  left_join(fomd01.crops.trees,
            
            by="crop_tree_diversity")%>%
  filter(is.na(FAO.Food.Group)) 

length(unique(unique_crops_diversity$crop_tree_diversity)) #70-v41: 57; v45: 34;v46: 16
#readr::write_csv(unique_crops_diversity, paste0(path.era, "/v41_error_report/missing_crops_01.csv"))


unique_crops_variety <- data.frame(
  crop_tree_diversity = unique(c(
    extract_variety_names(md.era.short.clean$C_crop_tree_variety),
    extract_variety_names(md.era.short.clean$T_crop_tree_variety)
  ))) %>%
  arrange(crop_tree_diversity)%>%
  left_join(fomd01.crops.trees,
            by="crop_tree_diversity")%>%
  filter(is.na(FAO.Food.Group)) 
length(unique(unique_crops_variety$crop_tree_diversity))#v45: 63, v46:41

sort(unique(md.era.short.clean$C_crop_tree_density))
sort(unique(md.era.short.clean$T_crop_tree_density))


unique_crops_density <- data.frame(
  crop_tree_diversity = unique(c(
    extract_crop_names(md.era.short.clean$C_crop_tree_density),
    extract_crop_names(md.era.short.clean$T_crop_tree_density)))) %>%
  arrange(crop_tree_diversity)%>%
  left_join(fomd01.crops.trees,
            by="crop_tree_diversity")%>%
  filter(is.na(FAO.Food.Group)) 
length(unique(unique_crops_density$crop_tree_diversity)) #v45: 36; v46:22


#=============================================
#---commodity_animal----
#=========================
md.era.short.clean <- md.era.short.clean%>%
  mutate(
    C_animal_diversity = gsub("\\*+", "-", C_animal_diversity),
    T_animal_diversity = gsub("\\*+", "-", T_animal_diversity),
    C_animal_breed = gsub("\\*+", "**", C_animal_breed),
    T_animal_breed = gsub("\\*+", "**", T_animal_breed))

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,cols = c("C_animal_diversity","T_animal_diversity"),
  pattern = "Gliricidia sepium",replacement =  "") 

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,cols = c("C_animal_diversity","T_animal_diversity"),
  pattern = "Gliricidia sp.",replacement =  "") 

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,cols = c("C_animal_diversity","T_animal_diversity"),
  pattern = "Durum Wheat-Wheat",replacement =  "")

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,cols = c("C_animal_diversity","T_animal_diversity"),
  pattern = "Grevillea robusta",replacement =  "")

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,cols = c("C_animal_diversity","T_animal_diversity"),
  pattern = "Zucchini",replacement =  "")

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,cols = c("C_animal_diversity","T_animal_diversity"),
  pattern = "Seed",replacement =  "")

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,cols = c("C_animal_diversity","T_animal_diversity"),
  pattern = "Unknown Plant",replacement =  "")

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,cols = c("C_animal_diversity","T_animal_diversity"),
  pattern = "Jute mallow",replacement =  "")

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,cols = c("C_animal_breed","T_animal_breed"),
  pattern = "Jute mallow(Sao Jose)",replacement =  "")

# Quick checks-----
sort(unique(md.era.short.clean$C_animal_diversity))
sort(unique(md.era.short.clean$T_animal_diversity))

sort(unique(md.era.short.clean$C_animal_breed))
sort(unique(md.era.short.clean$T_animal_breed))

sort(unique(md.era.short.clean$C_animal_density)) # TO CHECK: Missing
sort(unique(md.era.short.clean$T_animal_density)) # TO CHECK: Missing

#==================================================
#---improved_crop_varieties_practice---- 
#==================================================
## TO CHECK:  CHECK WHEN C SHOULD BE T ---------------
md.era.short.clean <- md.era.short.clean%>%
  mutate(
    C_varietal_crop_variety = gsub("\\*+", "**", C_varietal_crop_variety),
    C_varietal_crop_variety = gsub("\\$+", "**", C_varietal_crop_variety),
    T_varietal_crop_variety = gsub("\\*+", "**", T_varietal_crop_variety),
    T_varietal_crop_variety = gsub("\\$+", "**", T_varietal_crop_variety),
    
    C_varietal_crop_subpractice = gsub("\\*+", "..", C_varietal_crop_subpractice),
    C_varietal_crop_subpractice = gsub("\\$+", "..", C_varietal_crop_subpractice),
    T_varietal_crop_subpractice = gsub("\\*+", "..", T_varietal_crop_subpractice),
    T_varietal_crop_subpractice = gsub("\\$+", "..", T_varietal_crop_subpractice),
    
    C_varietal_crop_type = gsub("\\*+", "..", C_varietal_crop_type),
    C_varietal_crop_type = gsub("\\$+", "..", C_varietal_crop_type),
    T_varietal_crop_type = gsub("\\*+", "..", T_varietal_crop_type),
    T_varietal_crop_type = gsub("\\$+", "..", T_varietal_crop_type),
    
    C_varietal_crop_trait = gsub("\\*+", "..", C_varietal_crop_trait),
    C_varietal_crop_trait = gsub("\\$+", "..", C_varietal_crop_trait),
    T_varietal_crop_trait = gsub("\\*+", "..", T_varietal_crop_trait),
    T_varietal_crop_trait = gsub("\\$+", "..", T_varietal_crop_trait)
  )


md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_varietal_crop_subpractice","T_varietal_crop_subpractice"),
  pattern = "Other Improved Variety (Traits Known)",replacement =  "Improved Variety (Traits Known)") 

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_varietal_crop_subpractice","T_varietal_crop_subpractice"),
  pattern = "Unspecified",replacement =  "Unspecified Variety") 

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_varietal_crop_subpractice","T_varietal_crop_subpractice"),
  pattern = "Unspecified Variety Variety",replacement =  "Unspecified Variety") 

# Quick checks ----
sort(unique(md.era.short.clean$C_varietal_crop_subpractice_raw))
sort(unique(md.era.short.clean$T_varietal_crop_subpractice_raw))

sort(unique(md.era.short.clean$C_varietal_crop_variety))
sort(unique(md.era.short.clean$T_varietal_crop_variety))

sort(unique(md.era.short.clean$C_varietal_crop_subpractice))
sort(unique(md.era.short.clean$T_varietal_crop_subpractice))

sort(unique(md.era.short.clean$C_varietal_crop_type))
sort(unique(md.era.short.clean$T_varietal_crop_type))

sort(unique(md.era.short.clean$C_varietal_crop_trait))
sort(unique(md.era.short.clean$T_varietal_crop_trait))

#==================================================
#---improved_animal_breed_practice---- 
#==================================================
md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,cols = c("C_varietal_animal_breed","T_varietal_animal_breed"),
  pattern = "*",replacement =  "**")

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,cols = c("C_varietal_animal_subpractice","T_varietal_animal_subpractice",
                               "C_varietal_animal_type","T_varietal_animal_type"),
  pattern = "*",replacement =  "..")

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,cols = c("C_varietal_animal_subpractice","T_varietal_animal_subpractice",
                              "C_varietal_animal_type","T_varietal_animal_type"),
  pattern = "Unspecified",replacement =  "Unspecified Breed")

# Quick checks ----
sort(unique(md.era.short.clean$C_varietal_animal_subpractice_raw))
sort(unique(md.era.short.clean$T_varietal_animal_subpractice_raw))

sort(unique(md.era.short.clean$C_varietal_animal_breed))
sort(unique(md.era.short.clean$T_varietal_animal_breed))

sort(unique(md.era.short.clean$C_varietal_animal_subpractice))
sort(unique(md.era.short.clean$T_varietal_animal_subpractice))

sort(unique(md.era.short.clean$C_varietal_animal_type))
sort(unique(md.era.short.clean$T_varietal_animal_type))

#=============================================
#---soil_management_practice---- 
#=========================
md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_tillage_subpractice", "T_tillage_subpractice"),
  pattern = "...",replacement =  "..") 

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_tillage_method", "T_tillage_method",
           "C_tillage_method_other","T_tillage_method_other",
           "C_tillage_frequency","T_tillage_frequency"),
  pattern = "; ",replacement =  "..") 

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_tillage_method", "T_tillage_method"),
  pattern = " ..",replacement =  "..") 

# Quick checks ----
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

#=============================================
#---planting_practice----
#=========================
# TO CHECK: #Poner methods en methods, y subpractices en subpractices-----------------
# TO CHECK: WHICH SHOULD BE T OR C-----------------------
md.era.short.clean <- apply_replace_in_cols(md.era.short.clean,
  cols = c("C_planting_subpractice", "T_planting_subpractice"),
  pattern = "...",replacement = "..") 

md.era.short.clean <- apply_replace_in_cols(md.era.short.clean,
  cols = c("C_planting_method", "T_planting_method"),
  pattern = "Zero-tillage Planter",replacement = "Zero-tillage planter") 

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_planting_subpractice", "T_planting_subpractice"),
  pattern = "NA",replacement = "Unspecified") 

# Quick checks ----
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

#=============================================
#---intercropping_practice----
#=========================
md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_intercrop_subpractice", "T_intercrop_subpractice"),
  pattern = "&",replacement = "and") # Apply "&" -> "and" substitution


# Quick checks ----
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

#=============================================
#---crop_sequence_practice----
#=========================
md.era.short.clean <- apply_replace_in_cols(md.era.short.clean,
  cols = c("C_crop_seq_residues_fate", "T_crop_seq_residues_fate"),
  pattern = "; ",replacement = "..")

md.era.short.clean <- apply_replace_in_cols(md.era.short.clean,
  cols = c("C_crop_seq_residues_fate", "T_crop_seq_residues_fate"),
  pattern = "NA",replacement = "Unspecified")

# Quick checks ----
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

#=============================================
#---agroforestry_practice----
#=========================
## TO CHECK: NEED TO FIX C_agrof_subpractice=="Open Communal Grazing Land"----------------
## TO CHECK: THERE ARE AGROFORESTRY PRACTICES IN CROP ROTATION--------------
## TO CHECK : verify later if it is better to keep track of spatial, component, shade..-----------

md.era.short.clean<-md.era.short.clean%>% 
  mutate(
    C_agrof_subpractice= case_when(
      (doi=="10.1080/01448765.1991.9754573"& 
         C_agrof_subpractice=="Monoculture"&
         T_agrof_subpractice=="Living Fences or Hedgerows")~"No Living Fences or Hedgerows or Tree Windbreak",
      TRUE~C_agrof_subpractice)
  )

# Quick checks ----
sort(unique(md.era.short.clean$C_agrof_subpractice_raw))
sort(unique(md.era.short.clean$T_agrof_subpractice_raw))

sort(unique(md.era.short.clean$C_agrof_subpractice)) 
sort(unique(md.era.short.clean$T_agrof_subpractice))

prueba<-md.era.short.clean%>%
  filter(T_agrof_subpractice=="Open Communal Grazing Land")
sort(unique(prueba$C_agrof_subpractice)) 


sort(unique(md.era.short.clean$agrof_shade_mean_min_max)) #Missing from ERA
sort(unique(md.era.short.clean$agrof_canopy_height_mean_min_max)) #Missing from ERA
sort(unique(md.era.short.clean$agrof_dhb_mean_min_max))#Missing from ERA

#==================================================
#---nutrient_management_practice (inorganic)----
#==================================================
# Apply "No Fertilizer Application" -> "No Fertilizers Applied" substitution
md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_fert_subpractice", "T_fert_subpractice"),
  pattern = "No Fertilizer Application",replacement = "No Fertilizers Applied") 

# Apply "Unspecified" -> "Unspecified (if  fertilizer org or inorg was applied)" substitution
md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_fert_subpractice", "T_fert_subpractice"),
  pattern = "Unspecified",replacement = "Unspecified (if  fertilizer org or inorg was applied)")

# Apply  "; -> ".." substitution
md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_fert_subpractice", "T_fert_subpractice",
           "C_fert_inorganic_category", "T_fert_inorganic_category",
           "C_fert_inorganic_type",     "T_fert_inorganic_type",
           "C_fert_inorganic_unit",     "T_fert_inorganic_unit",
           "C_fert_inorganic_amount",   "T_fert_inorganic_amount",
           "C_fert_inorganic_combined","T_fert_inorganic_combined"),
  pattern = "; ",replacement = "..") 
 
# Apply "..." -> ".." substitution
md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_fert_inorganicNPK_unit", "T_fert_inorganicNPK_unit",
           "C_fert_inorganicN", "T_fert_inorganicN",
           "C_fert_inorganicP", "T_fert_inorganicP",
           "C_fert_inorganicK", "T_fert_inorganicK",
           "C_fert_inorganicK2O", "T_fert_inorganicK2O",
           "C_fert_inorganicP2O5", "T_fert_inorganicP2O5"),
  pattern = "...",replacement = "..") 

# Apply "..." -> ".." substitution
md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_fert_inorganicNPK_unit", "T_fert_inorganicNPK_unit",
           "C_fert_inorganicN", "T_fert_inorganicN",
           "C_fert_inorganicP", "T_fert_inorganicP",
           "C_fert_inorganicK", "T_fert_inorganicK",
           "C_fert_inorganicK2O", "T_fert_inorganicK2O",
           "C_fert_inorganicP2O5", "T_fert_inorganicP2O5"),
  pattern = ".. ",replacement = "..") 


# Apply "NA..NA..NA.." -> "NA..NA..NA..NA" substitution
md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_fert_inorganicN", "T_fert_inorganicN",
           "C_fert_inorganicP", "T_fert_inorganicP",
           "C_fert_inorganicK", "T_fert_inorganicK",
           "C_fert_inorganicK2O", "T_fert_inorganicK2O",
           "C_fert_inorganicP2O5", "T_fert_inorganicP2O5"),
  pattern = "NA..NA..NA..",replacement = "NA..NA..NA..NA") 


md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_fert_inorganicN", "T_fert_inorganicN",
           "C_fert_inorganicP", "T_fert_inorganicP",
           "C_fert_inorganicK", "T_fert_inorganicK",
           "C_fert_inorganicK2O", "T_fert_inorganicK2O",
           "C_fert_inorganicP2O5", "T_fert_inorganicP2O5"),
  pattern = "NA..NA..NA..",replacement = "NA..NA..NA..NA") 

 
# Apply "999999" -> "" substitution
md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_fert_inorganicN", "T_fert_inorganicN",
           "C_fert_inorganicP", "T_fert_inorganicP",
           "C_fert_inorganicK", "T_fert_inorganicK",
           "C_fert_inorganicK2O", "T_fert_inorganicK2O",
           "C_fert_inorganicP2O5", "T_fert_inorganicP2O5"),
  pattern = "999999",replacement = "") 

# Extract unique units by splitting on ".." and getting distinct non-empty values
md.era.short.clean <- md.era.short.clean %>%
  mutate(C_fert_inorganic_unit = C_fert_inorganic_unit %>%
           str_replace_all("\\.{2,}", "..") %>%   # collapse 4+ dots into exactly ".."
           str_replace_all("^\\.+|\\.+$", "")) %>%   # strip leading/trailing dots
  mutate(T_fert_inorganic_unit = T_fert_inorganic_unit %>%
           str_replace_all("\\.{2,}", "..") %>%   # collapse 4+ dots into exactly ".."
           str_replace_all("^\\.+|\\.+$", "")) %>%   # strip leading/trailing dots

  mutate(C_fert_inorganic_amount = C_fert_inorganic_amount %>%
           str_replace_all("\\.{2,}", "..") %>%   # collapse 4+ dots into exactly ".."
           str_replace_all("^\\.+|\\.+$", ""))%>%
  mutate(T_fert_inorganic_amount = T_fert_inorganic_amount %>%
           str_replace_all("\\.{2,}", "..") %>%   # collapse 4+ dots into exactly ".."
           str_replace_all("^\\.+|\\.+$", ""))

#Add manually the T_fert_inorganicNPK_unit of this study
md.era.short.clean<-md.era.short.clean%>%
  mutate(T_fert_inorganicNPK_unit=case_when(
    doi=="10.2136/sssaj2018.02.0066"&
    T_fert_inorganicK=="10"&
      T_fert_inorganicNPK_unit==""~"kg/ha",TRUE~T_fert_inorganicNPK_unit))

# Combine amount + unit columns separated by ".."
md.era.short.clean <- md.era.short.clean%>%
  mutate(C_fert_inorganicN_amount_unit= combine_amount_unit(amount = C_fert_inorganicN,unit   = C_fert_inorganicNPK_unit),
         C_fert_inorganicP_amount_unit= combine_amount_unit(amount = C_fert_inorganicP,unit   = C_fert_inorganicNPK_unit),
         C_fert_inorganicK_amount_unit= combine_amount_unit(amount = C_fert_inorganicK,unit   = C_fert_inorganicNPK_unit),
         C_fert_inorganicP2O5_amount_unit= combine_amount_unit(amount = C_fert_inorganicP2O5,unit   = C_fert_inorganicNPK_unit),
         C_fert_inorganicK2O_amount_unit= combine_amount_unit(amount = C_fert_inorganicK2O,unit   = C_fert_inorganicNPK_unit),
         
         T_fert_inorganicN_amount_unit= combine_amount_unit(amount = T_fert_inorganicN,unit   = T_fert_inorganicNPK_unit),
         T_fert_inorganicP_amount_unit= combine_amount_unit(amount = T_fert_inorganicP,unit   = T_fert_inorganicNPK_unit),
         T_fert_inorganicK_amount_unit= combine_amount_unit(amount = T_fert_inorganicK,unit   = T_fert_inorganicNPK_unit),
         T_fert_inorganicP2O5_amount_unit= combine_amount_unit(amount = T_fert_inorganicP2O5,unit   = T_fert_inorganicNPK_unit),
         T_fert_inorganicK2O_amount_unit= combine_amount_unit(amount = T_fert_inorganicK2O,unit   = T_fert_inorganicNPK_unit)
  )

md.era.short.clean <- md.era.short.clean%>%
  rename("C_fert_inorganic_type_amount_unit"="C_fert_inorganic_combined",
         "T_fert_inorganic_type_amount_unit"="T_fert_inorganic_combined")

  
# Quick checks ----
sort(unique(md.era.short.clean$C_fert_subpractice_raw))
sort(unique(md.era.short.clean$T_fert_subpractice_raw))

sort(unique(md.era.short.clean$C_fert_subpractice)) 
sort(unique(md.era.short.clean$T_fert_subpractice)) 

sort(unique(md.era.short.clean$C_fert_inorganic_type_amount_unit)) #TO CHECK: Need to combine type with amount and unit
sort(unique(md.era.short.clean$T_fert_inorganic_type_amount_unit)) #TO CHECK: Need to combine type with amount and unit

## Code to check mismatches for any amount/unit pair: This is ready, nothing to check
mismatch_report <- do.call(rbind, lapply(inorganicNPK_fert_pairs, function(p)
  check_length_mismatch_amount_unit(md.era.short.clean, p[1], p[2])))
View(mismatch_report)

sort(unique(md.era.short.clean$C_fert_inorganicNPK_unit)) # Merged
sort(unique(md.era.short.clean$T_fert_inorganicNPK_unit)) # Merged

sort(unique(md.era.short.clean$C_fert_inorganicN)) # Merged
sort(unique(md.era.short.clean$T_fert_inorganicN)) # Merged
sort(unique(md.era.short.clean$C_fert_inorganicN[md.era.short.clean$C_fert_inorganicNPK_unit==""]))
#character(0)
sort(unique(md.era.short.clean$T_fert_inorganicN[md.era.short.clean$T_fert_inorganicNPK_unit==""]))
#[1] ""

sort(unique(md.era.short.clean$C_fert_inorganicP)) # Merged
sort(unique(md.era.short.clean$T_fert_inorganicP)) # Merged
sort(unique(md.era.short.clean$C_fert_inorganicP[md.era.short.clean$C_fert_inorganicNPK_unit==""]))
#character(0)
sort(unique(md.era.short.clean$T_fert_inorganicP[md.era.short.clean$T_fert_inorganicNPK_unit==""]))
#[1] ""

sort(unique(md.era.short.clean$C_fert_inorganicK)) # Merged
sort(unique(md.era.short.clean$T_fert_inorganicK)) #  Merged
sort(unique(md.era.short.clean$C_fert_inorganicK[md.era.short.clean$C_fert_inorganicNPK_unit==""]))
#character(0)
sort(unique(md.era.short.clean$T_fert_inorganicK[md.era.short.clean$T_fert_inorganicNPK_unit==""]))
#[1] ""   

sort(unique(md.era.short.clean$C_fert_inorganicP2O5))
sort(unique(md.era.short.clean$T_fert_inorganicP2O5))
sort(unique(md.era.short.clean$C_fert_inorganicP2O5[md.era.short.clean$C_fert_inorganicNPK_unit==""]))
#character(0)
sort(unique(md.era.short.clean$T_fert_inorganicP2O5[md.era.short.clean$T_fert_inorganicNPK_unit==""]))
#[1] "" 

sort(unique(md.era.short.clean$C_fert_inorganicK2O)) # Merged
sort(unique(md.era.short.clean$T_fert_inorganicK2O)) # Merged
sort(unique(md.era.short.clean$C_fert_inorganicK2O[md.era.short.clean$C_fert_inorganicNPK_unit==""]))
#[1] ""
sort(unique(md.era.short.clean$T_fert_inorganicK2O[md.era.short.clean$T_fert_inorganicNPK_unit==""]))
#[1] "" 

sort(unique(md.era.short.clean$C_fert_inorganicN_amount_unit)) 
sort(unique(md.era.short.clean$C_fert_inorganicP_amount_unit))  
sort(unique(md.era.short.clean$C_fert_inorganicK_amount_unit))
sort(unique(md.era.short.clean$C_fert_inorganicP2O5_amount_unit)) 
sort(unique(md.era.short.clean$C_fert_inorganicK2O_amount_unit))

sort(unique(md.era.short.clean$T_fert_inorganicN_amount_unit)) 
sort(unique(md.era.short.clean$T_fert_inorganicP_amount_unit))  
sort(unique(md.era.short.clean$T_fert_inorganicK_amount_unit))
sort(unique(md.era.short.clean$T_fert_inorganicP2O5_amount_unit)) 
sort(unique(md.era.short.clean$T_fert_inorganicK2O_amount_unit)) 

#==================================================
#---nutrient_management_practice (organic)----
#==================================================
# Apply  "; -> ".." substitution
md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_fert_organic_category", "T_fert_organic_category",
           "C_fert_organic_type",     "T_fert_organic_type",
           "C_fert_organic_unit",     "T_fert_organic_unit",
           "C_fert_organic_amount",   "T_fert_organic_amount",
           "C_fert_organic_source",   "T_fert_organic_source",
           "C_fert_organic_combined","T_fert_organic_combined"),
  pattern = "; ",replacement = "..") 

# Apply "..." -> ".." substitution
md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_fert_organicN", "T_fert_organicN",
           "C_fert_organicP", "T_fert_organicP",
           "C_fert_organicK", "T_fert_organicK"),
  pattern = "...",replacement = "..") 

# Apply "999999" -> "Unspecified" substitution
md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_fert_organicN", "T_fert_organicN",
           "C_fert_organicP", "T_fert_organicP",
           "C_fert_organicK", "T_fert_organicK"),
  pattern = "999999",replacement = "Unspecified") 

# Combine amount + unit columns separated by ".."
md.era.short.clean <- md.era.short.clean%>%
  mutate(C_fert_organicN_amount_unit= combine_amount_unit(amount = C_fert_organicN,unit   = C_fert_organicNPK_unit),
         C_fert_organicP_amount_unit= combine_amount_unit(amount = C_fert_organicP,unit   = C_fert_organicNPK_unit),
         C_fert_organicK_amount_unit= combine_amount_unit(amount = C_fert_organicK,unit   = C_fert_organicNPK_unit),
         
         T_fert_organicN_amount_unit= combine_amount_unit(amount = T_fert_organicN,unit   = T_fert_organicNPK_unit),
         T_fert_organicP_amount_unit= combine_amount_unit(amount = T_fert_organicP,unit   = T_fert_organicNPK_unit),
         T_fert_organicK_amount_unit= combine_amount_unit(amount = T_fert_organicK,unit   = T_fert_organicNPK_unit)
  )

md.era.short.clean <- md.era.short.clean%>%
  rename("C_fert_organic_type_amount_unit"="C_fert_organic_combined",
         "T_fert_organic_type_amount_unit"="T_fert_organic_combined")

# Quick checks ----
sort(unique(md.era.short.clean$C_fert_organic_category))  
sort(unique(md.era.short.clean$T_fert_organic_category))  

sort(unique(md.era.short.clean$C_fert_organic_type_amount_unit)) # Merged
sort(unique(md.era.short.clean$T_fert_organic_type_amount_unit)) # Merged

sort(unique(md.era.short.clean$C_fert_organic_amount[md.era.short.clean$C_fert_organic_unit==""]))
#[1] ""
sort(unique(md.era.short.clean$T_fert_organic_amount[md.era.short.clean$T_fert_organic_unit==""]))
#[1] ""

sort(unique(md.era.short.clean$C_fert_organicNPK_unit)) # Merged
sort(unique(md.era.short.clean$T_fert_organicNPK_unit)) # Merged

sort(unique(md.era.short.clean$C_fert_organicN)) # Merged
sort(unique(md.era.short.clean$T_fert_organicN)) # Merged
sort(unique(md.era.short.clean$C_fert_organicN[md.era.short.clean$C_fert_organicNPK_unit==""]))
#character(0)
sort(unique(md.era.short.clean$T_fert_organicN[md.era.short.clean$T_fert_organicNPK_unit==""]))
#[1] ""

sort(unique(md.era.short.clean$C_fert_organicP)) # Merged
sort(unique(md.era.short.clean$T_fert_organicP)) # Merged

sort(unique(md.era.short.clean$C_fert_organicP[md.era.short.clean$C_fert_organicNPK_unit==""]))
#character(0)
sort(unique(md.era.short.clean$T_fert_organicP[md.era.short.clean$T_fert_organicNPK_unit==""]))
#[1] ""

sort(unique(md.era.short.clean$C_fert_organicK)) # Merged
sort(unique(md.era.short.clean$T_fert_organicK)) # Merged

sort(unique(md.era.short.clean$C_fert_organicK[md.era.short.clean$C_fert_organicNPK_unit==""]))
#character(0)
sort(unique(md.era.short.clean$T_fert_organicK[md.era.short.clean$T_fert_organicNPK_unit==""]))
#[1] ""

sort(unique(md.era.short.clean$C_fert_organic_source))
sort(unique(md.era.short.clean$T_fert_organic_source))

sort(unique(md.era.short.clean$C_fert_organic_type_amount_unit))  
sort(unique(md.era.short.clean$T_fert_organic_type_amount_unit))

sort(unique(md.era.short.clean$C_fert_organicN_amount_unit))
sort(unique(md.era.short.clean$C_fert_organicP_amount_unit))
sort(unique(md.era.short.clean$C_fert_organicK_amount_unit))
sort(unique(md.era.short.clean$T_fert_organicN_amount_unit))
sort(unique(md.era.short.clean$T_fert_organicP_amount_unit))
sort(unique(md.era.short.clean$T_fert_organicK_amount_unit))

#=============================================
#---weeding_management_moderator----
#=============================================
# Apply "..." -> ".." substitution
md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_weed_method", "T_weed_method",
           "C_weed_frequency_unit", "T_fert_organicP",
           "C_weed_frequency", "T_weed_frequency"),
  pattern = "...",replacement = "..") 


md.era.short.clean<-md.era.short.clean%>%
  mutate(
  C_weed_frequency_unit=case_when((
    C_weed_frequency_unit==""& C_weed_frequency!=""#&
      #study_id %in% c("AG0077","CJ0131")
    )~"season",TRUE~C_weed_frequency_unit),
  T_weed_frequency_unit=case_when((
    T_weed_frequency_unit==""& T_weed_frequency!=""#&
      #study_id %in% c("AG0077","CJ0131")
    )~"season",TRUE~T_weed_frequency_unit))

# Combine weeding frequency + unit columns separated by ".."
md.era.short.clean <- md.era.short.clean%>%
  mutate(C_weed_frequency_unit1= combine_amount_unit(amount = C_weed_frequency,unit   = C_weed_frequency_unit))%>%
  mutate(T_weed_frequency_unit1= combine_amount_unit(amount = T_weed_frequency,unit   = T_weed_frequency_unit))%>%
  mutate(C_weed_frequency_unit=C_weed_frequency_unit1,
         T_weed_frequency_unit=T_weed_frequency_unit1)
         
# Quick checks ----
sort(unique(md.era.short.clean$C_weed_method_raw))
sort(unique(md.era.short.clean$T_weed_method_raw))

sort(unique(md.era.short.clean$C_weed_method))
sort(unique(md.era.short.clean$T_weed_method))

sort(unique(md.era.short.clean$C_weed_frequency_unit)) # Merged
sort(unique(md.era.short.clean$T_weed_frequency_unit)) # Merged

sort(unique(md.era.short.clean$C_weed_frequency)) # Merged
sort(unique(md.era.short.clean$T_weed_frequency)) # Merged

sort(unique(md.era.short.clean$C_weed_frequency_unit1)) # Merged
sort(unique(md.era.short.clean$T_weed_frequency_unit1)) # Merged

sort(unique(md.era.short.clean$C_weed_frequency[is.na(md.era.short.clean$C_weed_frequency_unit)]))
sort(unique(md.era.short.clean$C_weed_frequency[md.era.short.clean$C_weed_frequency_unit==""]))
#[1] "" 
sort(unique(md.era.short.clean$T_weed_frequency[is.na(md.era.short.clean$T_weed_frequency_unit)]))
sort(unique(md.era.short.clean$T_weed_frequency[md.era.short.clean$T_weed_frequency_unit==""]))
#[1] "" 

#=========================
#---chemical_management_practice----
#=========================
## TO CHECK  C_chem_subpractice,T_chem_subpractice --------------------------

# Apply "..." -> ".." substitution
md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_chem_subpractice", "T_chem_subpractice",
           "C_chem_name", "T_chem_name",
           "C_chem_amount_unit", "T_chem_amount_unit",
           "C_chem_amount","T_chem_amount",
           "C_chem_combined", "T_chem_combined"),
  pattern = "; ",replacement = "..") 

md.era.short.clean <- md.era.short.clean %>%
  mutate(C_chem_amount_unit = C_chem_amount_unit %>%
           str_replace_all("\\.{2,}", "..") %>%   # collapse 4+ dots into exactly ".."
           str_replace_all("^\\.+|\\.+$", "")) %>%   # strip leading/trailing dots
  mutate(T_chem_amount_unit = T_chem_amount_unit %>%
           str_replace_all("\\.{2,}", "..") %>%   # collapse 4+ dots into exactly ".."
           str_replace_all("^\\.+|\\.+$", ""))%>%    # strip leading/trailing dots
  
  mutate(C_chem_amount = C_chem_amount %>%
           str_replace_all("\\.{2,}", "..") %>%   # collapse 4+ dots into exactly ".."
           str_replace_all("^\\.+|\\.+$", ""))%>%
  mutate(T_chem_amount = T_chem_amount %>%
           str_replace_all("\\.{2,}", "..") %>%   # collapse 4+ dots into exactly ".."
           str_replace_all("^\\.+|\\.+$", ""))

# Apply "..." -> ".." substitution
md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_chem_combined", "T_chem_combined"),
  pattern = "()",replacement = "(Unspecified[Unspecified])") 
  
replacements <- c(
  "Inoculation - Seed"= "Seed inoculation",
  "Inoculation - Soil" = "Soil inoculation",
  "Vaccine" = "Animal (Vaccine)",
  "Acaricide"= "Animal (Acaricide)",
  "Antihelmintic"= "Animal (Antihelmintic)",
  "Antibiotic"= "Animal (Antibiotic)",
  "Antimicrobial"="Animal (Antimicrobial)",
  "Antiparasitic"= "Animal (Antiparasitic)",
  "Antiprotozoal"="Animal (Antiprotozoal)",
  "Growth Promotor"= "Animal (Growth Promoter)",
  "Growth promoter"="Animal (Growth Promoter)",
  
  "Unspecified"= "Unspecified (if pesticide org or inorg was applied)",
  "Mechanical"= "Mechanical (Unspecified)",
  "Mechanical (Unspecified) (Unspecified (if pesticide org or inorg was applied))"="Mechanical (Unspecified)",
  "Hand Weeding (Unspecified (if pesticide org or inorg was applied))"="Hand Weeding (Unspecified)"
)

for (pat in names(replacements)) {
  md.era.short.clean <- apply_replace_in_cols(
    md.era.short.clean,
    cols        = c("C_chem_subpractice", "T_chem_subpractice"),
    pattern     = pat,
    replacement = replacements[[pat]]
  )
}
sort(unique(grep("Hand Weeding", md.era.short.clean$C_chem_subpractice, value = TRUE)))

md.era.short.clean <- md.era.short.clean%>%
  rename("C_chem_name_amount_unit"="C_chem_combined",
         "T_chem_name_amount_unit"="T_chem_combined")

# Quick checks----
sort(unique(md.era.short.clean$C_chem_subpractice_raw))
sort(unique(md.era.short.clean$T_chem_subpractice_raw))

sort(unique(md.era.short.clean$C_chem_subpractice))
sort(unique(md.era.short.clean$T_chem_subpractice))

sort(unique(md.era.short.clean$C_chem_name))
sort(unique(md.era.short.clean$T_chem_name))

sort(unique(md.era.short.clean$C_chem_amount_unit)) 
sort(unique(md.era.short.clean$T_chem_amount_unit))

sort(unique(md.era.short.clean$C_chem_name_amount_unit)) 
sort(unique(md.era.short.clean$T_chem_name_amount_unit))

#=========================
#---residues_practice----
#=========================
# Columns where "; " should become ".."
res_semicolon_cols <- c(
  "C_residues_OC_unit","T_residues_OC_unit",
  "C_residues_N_unit","T_residues_N_unit",
  "C_residues_P_unit", "T_residues_P_unit",
  "C_residues_K_unit","T_residues_K_unit",
  
  "C_residues_OC", "T_residues_OC",
  "C_residues_N",     "T_residues_N",
  "C_residues_P",     "T_residues_P",
  "C_residues_K",   "T_residues_K",
  "C_residues_tree",   "T_residues_tree",
  "C_residues_material","T_residues_material",
  "C_residues_material_unit","T_residues_material_unit",
  "C_residues_material_source","T_residues_material_source",
  "C_residues_material_amount","T_residues_material_amount"
)

# Apply  "; -> ".." substitution
md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = res_semicolon_cols,
  pattern = "; ",replacement = "..") 

replacements <- c(
  "Incorp. - Herb Non-N-fixing"= "Crop Residue Incorporation (Non N fixing)",
  
  "Mulch - Herb Non-N-fixing" = "Mulch Herb (Non N fixing)",
  "Mulch (Non N fixing)"= "Mulch Herb (Non N fixing)",
  
  "Mulch - Herb N-fixing"= "Mulch Herb (N fixing)",
  "Mulch (N fixing)"="Mulch Herb (N fixing)",
  
  "Mulch (N fixing & Non N fixing)"="Mulch Herb (N fixing and Non N fixing)",
  
  "Mulch - Herb Unspecified"="Mulch Herb (Unspecified)",
  
  "Mulch - Tree N-fixing"     = "Tree Prunings Mulched (N fixing)",
  
  "Mulch - Tree Non-N-fixing"= "Tree Prunings Mulched (Non N fixing)",
  
  "Mulch - Tree Unspecified"= "Tree Prunings Mulched (Unspecified)",
    
    "Mulch - Plastic"="Plastic Mulch",
  
  "Mulch - Other Material"="Mulch (Other Materials)",
  
  "Incorp. - Tree N-fixing"="Tree Prunings Incorporated (N fixing)",
  "Incorp. - Tree Non-N-fixing"="Tree Prunings Incorporated (Non N fixing)",
  "Incorp. - Tree Unspecified"="Tree Prunings Incorporated (Unspecified)"
  

  
)

for (pat in names(replacements)) {
  md.era.short.clean <- apply_replace_in_cols(
    md.era.short.clean,
    cols        = c("C_residues_subpractice","T_residues_subpractice"),
    pattern     = pat,
    replacement = replacements[[pat]]
  )
}


res_space_cols <- c(
  "C_residues_OC", "T_residues_OC",
  "C_residues_N",     "T_residues_N",
  "C_residues_P",     "T_residues_P",
  "C_residues_K",   "T_residues_K",
  "C_residues_material_amount","T_residues_material_amount")

# Apply " " -> "" substitution
md.era.short.clean[res_space_cols] <- lapply(
  md.era.short.clean[res_space_cols],
  \(x) trimws(gsub("\\s+", "", x)))

# Apply "..." -> ".." substitution
md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = res_semicolon_cols,
  pattern = "...",replacement = "..") 

#Add manually the C_residues_OC_unit of this study
md.era.short.clean<-md.era.short.clean%>%
  mutate(C_residues_OC_unit=case_when(
    (doi=="10.1080/03650340.2012.684877"&
      C_residues_OC=="33.70..23.90"&
      C_residues_OC_unit=="")~"g/kg",TRUE~C_residues_OC_unit))%>%
  mutate(C_residues_OC=case_when(
    (C_residues_OC_unit==""&
    (C_residues_OC=="0.00"|
       C_residues_OC=="0.00..0.00"|
      C_residues_OC=="0.00..0.00..0.00"))~"",TRUE~C_residues_OC))%>%
  
  mutate(T_residues_OC_unit=case_when(
    (doi=="10.1080/03650340.2012.684877"&
       T_residues_OC=="33.70..23.90"&
       T_residues_OC_unit=="")~"g/kg",TRUE~T_residues_OC_unit))%>%
  mutate(T_residues_OC=case_when(
    (T_residues_OC_unit==""&
       (T_residues_OC=="0.00"|
          T_residues_OC=="0.00..0.00"|
          T_residues_OC=="0.00..0.00..0.00"))~"",TRUE~T_residues_OC))

#Add manually the C_residues_N_unit of this study
md.era.short.clean<-md.era.short.clean%>%
  mutate(C_residues_N=case_when(
    (C_residues_N_unit==""&
       (C_residues_N=="0.00..0.00"|
          C_residues_N=="0.00..0.00..0.00"|
          C_residues_N=="0.00..0.00..0.00..0.00..0.00..0.00..0.00..0.00..0.00..0.00"))~"",TRUE~C_residues_N))%>%
  mutate(T_residues_N=case_when(
    (C_residues_N_unit==""&
       (T_residues_N=="0.00"|
          T_residues_N=="0.00..0.00"|
          T_residues_N=="0.00..0.00..0.00"|
          T_residues_N=="0.00..0.00..0.00..0.00..0.00..0.00..0.00..0.00..0.00..0.00"))~"",TRUE~T_residues_N))
  
  
#Add manually the C_residues_P_unit of this study
md.era.short.clean<-md.era.short.clean%>%
  mutate(C_residues_P_unit=case_when(
    (doi=="10.1016/j.heliyon.2021.e07881"&
       C_residues_P=="0.1..0.1.."&
       C_residues_P_unit=="%..%..%")~"%..%",TRUE~C_residues_P_unit))%>%
  mutate(C_residues_P=case_when(
    (doi=="10.1016/j.heliyon.2021.e07881"&
       C_residues_P=="0.1..0.1..")~"0.1..0.1",TRUE~C_residues_P))%>%
  mutate(T_residues_P_unit=case_when(
    (doi=="10.1016/j.heliyon.2021.e07881"&
       T_residues_P=="0.1..0.1.."&
       T_residues_P_unit=="%..%..%")~"%..%",TRUE~T_residues_P_unit))%>%
  mutate(T_residues_P=case_when(
    (doi=="10.1016/j.heliyon.2021.e07881"&
       T_residues_P=="0.1..0.1..")~"0.1..0.1",TRUE~T_residues_P))%>%
  
  mutate(C_residues_P=case_when(
    (C_residues_P_unit==""&
       (C_residues_P=="0.000..0.000"|
          C_residues_P=="0.000..0.000..0.000"))~"",TRUE~C_residues_P))%>%
  
  mutate(T_residues_P=case_when(
    (T_residues_P_unit==""&
       (T_residues_P=="0.000..0.000"|
          T_residues_P=="0.000..0.000..0.000"))~"",TRUE~T_residues_P))
  

#Add manually the C_residues_K_unit and T_residues_K_unit of this study
md.era.short.clean<-md.era.short.clean%>%
  mutate(C_residues_K_unit=case_when(
    (doi=="10.1016/j.fcr.2017.05.013"&
       C_residues_K=="43.20"&
       C_residues_K_unit=="")~"mg/kg",TRUE~C_residues_K_unit))%>%
  
  mutate(C_residues_K_unit=case_when(
    (doi=="10.1007/s10705-018-9928-4"&
       C_residues_K=="13.80..15.80"&
       C_residues_K_unit=="")~"kg/ha..kg/ha",TRUE~C_residues_K_unit))%>%
  
  mutate(C_residues_K=case_when(
    (C_residues_K_unit==""&
       (C_residues_K=="0.00"|
          C_residues_K== "0.00..0.00"))~"",TRUE~C_residues_K))%>%
  
  mutate(T_residues_K_unit=case_when(
    (doi=="10.1016/j.fcr.2017.05.013"&
       T_residues_K=="43.20"&
       T_residues_K_unit=="")~"mg/kg",TRUE~T_residues_K_unit))%>%
  
  mutate(T_residues_K_unit=case_when(
    (doi=="10.1007/s10705-018-9928-4"&
       T_residues_K=="13.80..15.80"&
       T_residues_K_unit=="")~"kg/ha..kg/ha",TRUE~T_residues_K_unit))%>%
  
  mutate(T_residues_K=case_when(
    (T_residues_K_unit==""&
       (T_residues_K=="0.00"|
          T_residues_K== "0.00..0.00"))~"",TRUE~T_residues_K))%>%
  mutate(T_residues_N_unit=case_when(
    (doi=="10.1016/j.heliyon.2021.e08005"&
       T_residues_N%in%c("60","30")&
       T_residues_N_unit=="")~"kg/ha",TRUE~T_residues_N_unit))%>%
  mutate(T_residues_N_unit=case_when(
    (doi=="10.1016/j.geodrs.2018.e00193"&
       T_residues_N%in%c("60")&
       T_residues_N_unit=="")~"%",TRUE~T_residues_N_unit))

# Combine amount + unit columns separated by ".."
md.era.short.clean <- md.era.short.clean%>%
  mutate(
    C_residues_N=case_when(C_residues_N=="0.00"& C_residues_N_unit==""~"",TRUE~C_residues_N),
    T_residues_N=case_when(T_residues_N=="0.00"& T_residues_N_unit==""~"",TRUE~T_residues_N),
    C_residues_P=case_when(C_residues_P=="0.000"& C_residues_P_unit==""~"",TRUE~C_residues_P),
    T_residues_P=case_when(T_residues_P=="0.000"& T_residues_P_unit==""~"",TRUE~T_residues_P),
    
    C_residues_OC_amount_unit= combine_amount_unit(amount = C_residues_OC,unit   = C_residues_OC_unit),
    T_residues_OC_amount_unit= combine_amount_unit(amount = T_residues_OC,unit   = T_residues_OC_unit),
    
    C_residues_N_amount_unit= combine_amount_unit(amount = C_residues_N,unit   = C_residues_N_unit),
    T_residues_N_amount_unit= combine_amount_unit(amount = T_residues_N,unit   = T_residues_N_unit), #not ready to merge, mismatches
    
    C_residues_P_amount_unit= combine_amount_unit(amount = C_residues_P,unit   = C_residues_P_unit),
    T_residues_P_amount_unit= combine_amount_unit(amount = T_residues_P,unit   = T_residues_P_unit),
    
    C_residues_K_amount_unit= combine_amount_unit(amount = C_residues_K,unit   = C_residues_K_unit),
    T_residues_K_amount_unit= combine_amount_unit(amount = T_residues_K,unit   = T_residues_K_unit),
    
    C_residues_material_amount_unit= combine_amount_unit(amount = C_residues_material_amount,unit = C_residues_material_unit),
    T_residues_material_amount_unit= combine_amount_unit(amount = T_residues_material_amount,unit = T_residues_material_unit)
  )


# Quick checks ----
sort(unique(md.era.short.clean$C_residues_subpractice_raw))
sort(unique(md.era.short.clean$T_residues_subpractice_raw))

sort(unique(md.era.short.clean$C_residues_subpractice)) 
sort(unique(md.era.short.clean$T_residues_subpractice)) 

sort(unique(md.era.short.clean$C_residues_OC_unit)) # Merged
sort(unique(md.era.short.clean$T_residues_OC_unit))# Merged

sort(unique(md.era.short.clean$C_residues_OC)) # Merged
sort(unique(md.era.short.clean$T_residues_OC)) # Merged

sort(unique(md.era.short.clean$C_residues_OC[is.na(md.era.short.clean$C_residues_OC_unit)]))
sort(unique(md.era.short.clean$C_residues_OC[md.era.short.clean$C_residues_OC_unit==""]))
#[1] ""             
sort(unique(md.era.short.clean$T_residues_OC[is.na(md.era.short.clean$T_residues_OC_unit)]))
sort(unique(md.era.short.clean$T_residues_OC[md.era.short.clean$T_residues_OC_unit==""]))
#[1] ""         

sort(unique(md.era.short.clean$C_residues_N_unit)) # Merged
sort(unique(md.era.short.clean$T_residues_N_unit)) # Merged

sort(unique(md.era.short.clean$C_residues_N)) # Merged
sort(unique(md.era.short.clean$T_residues_N)) # Merged

sort(unique(md.era.short.clean$C_residues_N[is.na(md.era.short.clean$C_residues_N_unit)]))
sort(unique(md.era.short.clean$C_residues_N[md.era.short.clean$C_residues_N_unit==""]))
#[1] character(0)
sort(unique(md.era.short.clean$T_residues_N[is.na(md.era.short.clean$T_residues_N_unit)]))
sort(unique(md.era.short.clean$T_residues_N[md.era.short.clean$T_residues_N_unit==""]))
#[1] ""

sort(unique(md.era.short.clean$C_residues_P_unit)) # Merged
sort(unique(md.era.short.clean$T_residues_P_unit)) # Merged

sort(unique(md.era.short.clean$C_residues_P)) # Merged
sort(unique(md.era.short.clean$T_residues_P)) # Merged

sort(unique(md.era.short.clean$C_residues_P[is.na(md.era.short.clean$C_residues_P_unit)]))
sort(unique(md.era.short.clean$C_residues_P[md.era.short.clean$C_residues_P_unit==""]))
#[1] ""  
sort(unique(md.era.short.clean$T_residues_P[is.na(md.era.short.clean$T_residues_P_unit)]))
sort(unique(md.era.short.clean$T_residues_P[md.era.short.clean$T_residues_P_unit==""]))
#[1] ""  "0" 

sort(unique(md.era.short.clean$C_residues_K_unit)) # Merged
sort(unique(md.era.short.clean$T_residues_K_unit)) # Merged

sort(unique(md.era.short.clean$C_residues_K)) # Merged
sort(unique(md.era.short.clean$T_residues_K)) # Merged

sort(unique(md.era.short.clean$C_residues_K[is.na(md.era.short.clean$C_residues_K_unit)]))
sort(unique(md.era.short.clean$C_residues_K[md.era.short.clean$C_residues_K_unit==""]))
#[1] ""            
sort(unique(md.era.short.clean$T_residues_K[is.na(md.era.short.clean$T_residues_K_unit)]))
sort(unique(md.era.short.clean$T_residues_K[md.era.short.clean$T_residues_K_unit==""]))
#[1] ""      

sort(unique(md.era.short.clean$C_residues_tree))
sort(unique(md.era.short.clean$T_residues_tree))

sort(unique(md.era.short.clean$C_residues_processing))
sort(unique(md.era.short.clean$C_residues_processing))

sort(unique(md.era.short.clean$C_residues_material))
sort(unique(md.era.short.clean$T_residues_material))

sort(unique(md.era.short.clean$C_residues_material_unit)) # Merged
sort(unique(md.era.short.clean$T_residues_material_unit)) # Merged

sort(unique(md.era.short.clean$C_residues_material_amount)) # Merged
sort(unique(md.era.short.clean$T_residues_material_amount)) # Merged

sort(unique(md.era.short.clean$C_residues_material_amount[is.na(md.era.short.clean$C_residues_material_unit)]))
sort(unique(md.era.short.clean$C_residues_material_amount[md.era.short.clean$C_residues_material_unit==""]))
#  character(0)
sort(unique(md.era.short.clean$T_residues_material_amount[is.na(md.era.short.clean$T_residues_material_unit)]))
sort(unique(md.era.short.clean$T_residues_material_amount[md.era.short.clean$T_residues_material_unit==""]))
#[1] ""     

sort(unique(md.era.short.clean$C_residues_OC_amount_unit)) 
sort(unique(md.era.short.clean$T_residues_OC_amount_unit)) 

sort(unique(md.era.short.clean$C_residues_N_amount_unit))
sort(unique(md.era.short.clean$T_residues_N_amount_unit)) 

sort(unique(md.era.short.clean$C_residues_P_amount_unit))
sort(unique(md.era.short.clean$T_residues_P_amount_unit))

sort(unique(md.era.short.clean$C_residues_K_amount_unit))
sort(unique(md.era.short.clean$T_residues_K_amount_unit))

sort(unique(md.era.short.clean$C_residues_material_amount_unit))
sort(unique(md.era.short.clean$T_residues_material_amount_unit))

sort(unique(md.era.short.clean$C_residues_material_source))
sort(unique(md.era.short.clean$T_residues_material_source))

#=========================
#---pH_amendment_practice----
#=========================
# Apply "; " -> ".." substitution
md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_ph_material_applied", "T_ph_material_applied",
           "C_ph_material_amount",     "T_ph_material_amount"),
  pattern = "; ",replacement = "..") 

# Apply "+" -> ".." substitution
md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_ph_material_applied", "T_ph_material_applied",
           "C_ph_material_amount",     "T_ph_material_amount"),
  pattern = "+",replacement = "..") 

# Apply "..." -> ".." 
md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_ph_subpractice", "T_ph_subpractice"),
  pattern = "...",replacement = "..") 

# Apply "..." -> ".." 
md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_ph_subpractice", "T_ph_subpractice"),
  pattern = "Liming or Ca Addition",replacement = "Liming or Calcium Addition") 


# Merge ph_material_amount(ph_material_unit) into ph_material_amount_unit
md.era.short.clean <- md.era.short.clean%>%
  mutate(C_ph_material_amount_unit1= combine_amount_unit(amount = C_ph_material_amount, unit   = C_ph_material_unit),
         T_ph_material_amount_unit1= combine_amount_unit(amount = T_ph_material_amount, unit   = T_ph_material_unit))%>%
  mutate(C_ph_material_amount_unit= mapply(combine_ph_material_amount_unit,C_ph_material_applied,C_ph_material_amount_unit1),
         T_ph_material_amount_unit= mapply(combine_ph_material_amount_unit,T_ph_material_applied,T_ph_material_amount_unit1)
  )

# Quick checks ----
sort(unique(md.era.short.clean$C_ph_subpractice_raw))
sort(unique(md.era.short.clean$T_ph_subpractice_raw))

sort(unique(md.era.short.clean$C_ph_subpractice))
sort(unique(md.era.short.clean$T_ph_subpractice))

sort(unique(md.era.short.clean$C_ph_material_applied))
sort(unique(md.era.short.clean$T_ph_material_applied))

sort(unique(md.era.short.clean$C_ph_material_unit)) # Merged
sort(unique(md.era.short.clean$T_ph_material_unit)) # Merged

sort(unique(md.era.short.clean$C_ph_material_amount)) # Merged
sort(unique(md.era.short.clean$T_ph_material_amount)) # Merged

sort(unique(md.era.short.clean$C_ph_material_amount_unit))
sort(unique(md.era.short.clean$T_ph_material_amount_unit))

#=========================
#---irrigation_practice----
#=========================
md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_irrig_subpractice", "T_irrig_subpractice"),
  pattern = "...",replacement = "..") 

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_irrig_subpractice", "T_irrig_subpractice"),
  pattern = " + ",replacement = "..") 

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_irrig_subpractice", "T_irrig_subpractice"),
  pattern = "Deficit",replacement = "Deficit Irrigation") 

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_irrig_subpractice", "T_irrig_subpractice"),
  pattern = "Deficit Irrigation Irrigation",replacement = "Deficit Irrigation") 

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_irrig_subpractice", "T_irrig_subpractice"),
  pattern = "Fully Irrigated",replacement = "Fully Irrigated Control or Experiment") 

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_irrig_subpractice", "T_irrig_subpractice"),
  pattern = "Fully Irrigated Control or Experiment Control or Experiment",replacement = "Fully Irrigated Control or Experiment") 

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_irrig_subpractice", "T_irrig_subpractice"),
  pattern = "Supplemental",replacement = "Supplemental Irrigation") 

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_irrig_subpractice", "T_irrig_subpractice"),
  pattern = "Supplemental Irrigation Irrigation",replacement = "Supplemental Irrigation") 

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_irrig_subpractice", "T_irrig_subpractice"),
  pattern = "APRI",replacement = "Alternate Partial Rootzone Irrigation") 

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_irrig_subpractice", "T_irrig_subpractice"),
  pattern = "Unspecified",replacement = "Unspecified (if it was irrigated)") 

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_irrig_water_unit", "T_irrig_water_unit"),
  pattern = "mmweek",replacement = "mm/week") 

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_irrig_water_amount", "T_irrig_water_amount"),
  pattern = "; ",replacement = "..") 

# Merge irrig_water_amount(irrig_water_unit) into irrig_water_amount_unit
md.era.short.clean <- md.era.short.clean%>%
  mutate(C_irrig_water_amount_unit= combine_amount_unit(amount = C_irrig_water_amount,unit   = C_irrig_water_unit),
         T_irrig_water_amount_unit= combine_amount_unit(amount = T_irrig_water_amount,unit   = T_irrig_water_unit)
  )

# Quick checks ----
sort(unique(md.era.short.clean$C_irrig_subpractice_raw))
sort(unique(md.era.short.clean$T_irrig_subpractice_raw))

sort(unique(md.era.short.clean$C_irrig_subpractice))
sort(unique(md.era.short.clean$T_irrig_subpractice))

sort(unique(md.era.short.clean$C_irrig_method))
sort(unique(md.era.short.clean$T_irrig_method))

sort(unique(md.era.short.clean$C_irrig_date_start))
sort(unique(md.era.short.clean$T_irrig_date_start))

sort(unique(md.era.short.clean$C_irrig_date_end))
sort(unique(md.era.short.clean$T_irrig_date_end))

sort(unique(md.era.short.clean$C_irrig_water_unit)) # Merged
sort(unique(md.era.short.clean$T_irrig_water_unit)) # Merged

sort(unique(md.era.short.clean$C_irrig_water_amount)) # Merged
sort(unique(md.era.short.clean$T_irrig_water_amount)) # Merged

sort(unique(md.era.short.clean$C_irrig_water_amount[md.era.short.clean$C_irrig_water_unit==""]))
sort(unique(md.era.short.clean$T_irrig_water_amount[md.era.short.clean$T_irrig_water_unit==""]))

sort(unique(md.era.short.clean$C_irrig_water_amount_unit))
sort(unique(md.era.short.clean$T_irrig_water_amount_unit))

sort(unique(md.era.short.clean$C_irrig_water_type))
sort(unique(md.era.short.clean$T_irrig_water_type))

#=========================
#---water_harvesting_practice----
#=========================
md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_watharv_subpractice", "T_watharv_subpractice"),
  pattern = "; ",replacement = "..") 

# Quick checks ----
sort(unique(md.era.short.clean$C_watharv_subpractice_raw))
sort(unique(md.era.short.clean$T_watharv_subpractice_raw))

sort(unique(md.era.short.clean$C_watharv_subpractice))
sort(unique(md.era.short.clean$T_watharv_subpractice))

#=========================
#---harvesting_practice----
#=========================
# Quick checks ----
sort(unique(md.era.short.clean$C_harvest_subpractice_raw))
sort(unique(md.era.short.clean$T_harvest_subpractice_raw))

sort(unique(md.era.short.clean$C_harvest_subpractice))
sort(unique(md.era.short.clean$T_harvest_subpractice))

sort(unique(md.era.short.clean$C_harvest_date_start))
sort(unique(md.era.short.clean$T_harvest_date_start))

sort(unique(md.era.short.clean$C_harvest_date_end))
sort(unique(md.era.short.clean$T_harvest_date_end))

sort(unique(md.era.short.clean$C_harvest_days_after_planting))
sort(unique(md.era.short.clean$T_harvest_days_after_planting))

#=========================
#---postharvesting_practice----
#=========================
md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_postharvest_subpractice", "T_postharvest_subpractice"),
  pattern = "; ",replacement = "..") 

# Quick checks ----
sort(unique(md.era.short.clean$C_postharvest_subpractice_raw)) 
sort(unique(md.era.short.clean$T_postharvest_subpractice_raw)) 

sort(unique(md.era.short.clean$C_postharvest_subpractice)) # THE VALUES LOOK WRONG
sort(unique(md.era.short.clean$T_postharvest_subpractice)) # THE VALUES LOOK WRONG

sort(unique(md.era.short.clean$C_postharvest_subpractice))
sort(unique(md.era.short.clean$T_postharvest_subpractice))

sort(unique(md.era.short.clean$C_postharvest_date_start)) #MISSING
sort(unique(md.era.short.clean$T_postharvest_date_start)) #MISSING

sort(unique(md.era.short.clean$C_postharvest_date_end)) #MISSING
sort(unique(md.era.short.clean$T_postharvest_date_end)) #MISSING

sort(unique(md.era.short.clean$C_postharvest_days_after_storage)) #MISSING
sort(unique(md.era.short.clean$T_postharvest_days_after_storage)) #MISSING

#=========================
#---outcome_experimental_design----
#=========================
## TO CHECK: check what to do here separate by T and C or leave it like this
# Quick checks
sort(unique(md.era.short.clean$out_exp_design))
sort(unique(md.era.short.clean$out_exp_plot_size))

#=========================
#---product_outcome----
#=========================
# TO CHECK: #MAKE A LIST OF MISSING PRODUCTS FROM 01_product_new----------
md.era.short.clean$C_product <- gsub("\\*", "..", md.era.short.clean$C_product, fixed = TRUE)
md.era.short.clean$T_product <- gsub("\\*", "..", md.era.short.clean$T_product, fixed = TRUE)

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_product", "T_product"),
  pattern=" & ", replacement = "..")

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_product", "T_product"),
  pattern=", ", replacement = "..")

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_product", "T_product"),
  pattern="*", replacement = "..")

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_product_type", "T_product_type",
           "C_product_subtype","T_product_subtype",
           "C_product_simple","T_product_simple"),
  pattern = "**",replacement = "..")

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_econ_inputs", "T_econ_inputs"),
  pattern="; ", replacement = "..")

# ort items within a string alphabetically
md.era.short.clean$C_econ_inputs <- sapply(md.era.short.clean$C_econ_inputs, sort_econ_inputs)
md.era.short.clean$T_econ_inputs <- sapply(md.era.short.clean$T_econ_inputs, sort_econ_inputs)

# Quick checks ----
sort(unique(md.era.short.clean$C_product)) #MAKE A LIST OF MISSING PRODUCTS FROM 01_product_new
sort(unique(md.era.short.clean$T_product)) #MAKE A LIST OF MISSING PRODUCTS FROM 01_product_new
na_empty_summary["C_product", ] #in v6 17064 missing values; in v24 3150 empty values; in v32 1646; in v46 0
na_empty_summary["T_product", ] #in v6 17064 missing values; in v24 3150 empty values; in v32 1646; in v46 0


sort(unique(md.era.short.clean$C_product_type)) #to RECLASIFIED AGAIN BASED ON C_product_simple
sort(unique(md.era.short.clean$T_product_type))#to RECLASIFIED AGAIN BASED ON T_product_simple

sort(unique(md.era.short.clean$C_product_subtype)) #to RECLASIFIED AGAIN BASED ON C_product_simple
sort(unique(md.era.short.clean$T_product_subtype)) #to RECLASIFIED AGAIN BASED ON T_product_simple

sort(unique(md.era.short.clean$C_product_simple)) #to RECLASIFIED AGAIN BASED ON C_product_simple
sort(unique(md.era.short.clean$T_product_simple)) #to RECLASIFIED AGAIN BASED ON T_product_simple

sort(unique(md.era.short.clean$C_econ_inputs)) 
sort(unique(md.era.short.clean$T_econ_inputs)) 

sort(unique(md.era.short.clean$bio_func_group)) #TO FIX from ERA need to complete manually for the included papers
sort(unique(md.era.short.clean$bio_ground_ref)) #TO FIX from ERA need to complete manually for the included papers

#=========================
#---outcome----
#=========================
md.era.short.clean$out_subindicator <- gsub("Labor Cost" , "Labour Cost" , md.era.short.clean$out_subindicator, fixed = TRUE)

# Quick checks -----
sort(unique(md.era.short.clean$out_subindicator))

#Explanation from Lolita:
#Only 15 rows. I opened the source papers: 7 of them I could fill with confidence 
#(NN0165 = Milk Yield, NN0272 = Feed Conversion Ratio – both confirmed against the paper's tables). 
#The other 8 I left blank on purpose: 3 are a fertilizer-cost figure that doesn't match any of our outcome categories,
#and 5 (JS0232) had values I couldn't trace to anything in the published paper, so we can exclude those.
nrow(md.era.short.clean[md.era.short.clean$out_subindicator == "", ]) #15 in v6, 8 in v24  rows with empty out_subindicator, is this ok?
#v46 8 missing
sort(unique(md.era.short.clean$out_indicator)) # RECLASSIFIED BASED ON out_subindicator
sort(unique(md.era.short.clean$out_subpillar)) # RECLASSIFIED BASED ON out_subindicator
sort(unique(md.era.short.clean$out_pillar)) # RECLASSIFIED BASED ON out_subindicator
sort(unique(md.era.short.clean$out_subindicator_unit))

sort(unique(md.era.short.clean$C_out_soil_depth_u))
sort(unique(md.era.short.clean$T_out_soil_depth_u))

sort(unique(md.era.short.clean$C_out_soil_depth_l))
sort(unique(md.era.short.clean$T_out_soil_depth_l))

#=========================
#---outcome_value----
#=========================
## TO CHECK: Missing values in C_out_var_metric and T_out_var_metric
## Missing sample sizes C_out_sample_size and T_out_sample_size
md.era.short.clean$C_out_metric <- gsub("mean", "Mean", md.era.short.clean$C_out_metric, fixed = TRUE)
md.era.short.clean$T_out_metric <- gsub("mean", "Mean", md.era.short.clean$T_out_metric, fixed = TRUE)

#There are rows with   C_out_var_metric==SE (Standard Error) & C_out_var_value<0
#That is not possible, code to convert SE to positive values
md.era.short.clean<-md.era.short.clean %>%
  mutate(C_out_var_value = if_else(C_out_var_metric == "SE (Standard Error)" & C_out_var_value < 0,
                                   C_out_var_value * -1,
                                   C_out_var_value),
         T_out_var_value = if_else(T_out_var_metric == "SE (Standard Error)" & T_out_var_value < 0,
                                   T_out_var_value * -1,
                                   T_out_var_value) )
  
md.era.short.clean<-md.era.short.clean%>%
  mutate(
    C_out_var_value=as.character(C_out_var_value),
    C_out_var_value=case_when(is.na(C_out_var_value)&C_out_var_metric=="Unspecified"~"Unspecified",TRUE~C_out_var_value),
    T_out_var_value=as.character(T_out_var_value),
    T_out_var_value=case_when(is.na(T_out_var_value)&T_out_var_metric=="Unspecified"~"Unspecified",TRUE~T_out_var_value))




# Quick checks ----
sort(unique(md.era.short.clean$C_out_metric))
sort(unique(md.era.short.clean$T_out_metric))
na_empty_summary["C_out_metric", ] #0
na_empty_summary["T_out_metric", ] #0

sort(unique(md.era.short.clean$C_out_value))
sort(unique(md.era.short.clean$T_out_value))

sort(unique(md.era.short.clean$C_out_var_value))
sort(unique(md.era.short.clean$T_out_var_value))

#Explanation from Lolita
#C_out_value / T_out_value and C_out_sample_size / T_out_sample_size: 
#the blanks here are genuine gaps in the source papers, not a processing error. 
#For the missing outcome values it's only 9 studies, and they're all ratio/efficiency results 
#(Land Equivalent Ratio, Nitrogen/Phosphorus Agronomic Efficiency) that don't have a control value by definition. 
#Overall the outcome data is about 99.5% complete

na_empty_summary["C_out_value", ]
nrow(md.era.short.clean[md.era.short.clean$C_out_value == "", ]) #1075 missing C_out_value values
na_empty_summary["T_out_value", ]
nrow(md.era.short.clean[md.era.short.clean$T_out_value == "", ]) #6 missing T_out_value values

sort(unique(md.era.short.clean$C_out_var_metric))
sort(unique(md.era.short.clean$T_out_var_metric))
nrow(md.era.short.clean[md.era.short.clean$C_out_var_metric == "", ]) #in v6 182058; in v32 183067
nrow(md.era.short.clean[md.era.short.clean$T_out_var_metric == "", ]) #183074; in v32 182996

sort(unique(md.era.short.clean$C_out_var_value))
sort(unique(md.era.short.clean$T_out_var_value))
na_empty_summary1["C_out_var_value", ]
nrow(md.era.short.clean[md.era.short.clean$C_out_var_value == "", ]) #183075; in v32 183067
na_empty_summary["T_out_var_value", ]
nrow(md.era.short.clean[md.era.short.clean$T_out_var_value == "", ])#182988; in v32 182996

#Reports for Lolita
report_C_out_var_metric<-md.era.short.clean %>%
  filter(!is.na(C_out_var_value), C_out_var_value != "", C_out_var_metric == "") %>%
  select(authors,study_id,doi,C_out_var_metric,C_out_var_value, C_data_location)
nrow(report_C_out_var_metric) # in v6 88 there are 88 rows that have C_out_var_value but don't have C_out_var_metric; in v32 0

#readr::write_csv(report_C_out_var_metric, paste0(path.era, "/v32_error_report/report_C_out_var_metric.csv"))

report_T_out_var_metric<- md.era.short.clean %>%
  filter(!is.na(T_out_var_value), T_out_var_value != "", T_out_var_metric == "") %>%
  select(authors,study_id,doi,T_out_var_metric,T_out_var_value, T_data_location)
nrow(report_T_out_var_metric) #in v6 86 there are 86 rows that have C_out_var_value but don't have C_out_var_metric; in v32 0

#readr::write_csv(report_T_out_var_metric, paste0(path.era, "/v24_error_report/report_T_out_var_metric.csv"))

sort(unique(md.era.short.clean$C_out_sample_size))
sort(unique(md.era.short.clean$T_out_sample_size))
na_empty_summary["C_out_sample_size", ] #in v6 17064 missing values; in v24 16896; in v32 12722
na_empty_summary["T_out_sample_size", ] #in v6 17064 missing values; in v24 16896; in v32 12722

report_C_out_sample_size<-md.era.short.clean %>%
  filter(is.na(C_out_sample_size)) %>%
  select(authors,study_id,doi,C_out_var_metric,C_out_var_value, C_out_sample_size, C_data_location)
nrow(report_C_out_sample_size) #49183 there are 49183 rows that don't have C_out_sample_size; in v32 12722

#readr::write_csv(report_C_out_sample_size, paste0(path.era, "/v24_error_report/report_C_out_sample_size.csv"))

report_T_out_sample_size<-md.era.short.clean %>%
  filter(is.na(T_out_sample_size)) %>%
  select(authors,study_id,doi,T_out_var_metric,T_out_var_value, T_out_sample_size, T_data_location)
nrow(report_T_out_sample_size) #49183 there are 49183 rows that don't have T_out_sample_size; in v32 12722

#readr::write_csv(report_T_out_sample_size, paste0(path.era, "/v24_error_report/report_T_out_sample_size.csv"))

sort(unique(md.era.short.clean$C_data_location))
sort(unique(md.era.short.clean$T_data_location))

#=========================
#---outcome_time----
#=========================
# Quick checks----
sort(unique(md.era.short.clean$C_out_agg_stat))
sort(unique(md.era.short.clean$T_out_agg_stat))

sort(unique(md.era.short.clean$C_out_year))
sort(unique(md.era.short.clean$T_out_year))

sort(unique(md.era.short.clean$C_out_year_start))
sort(unique(md.era.short.clean$T_out_year_start))

sort(unique(md.era.short.clean$C_out_year_end))
sort(unique(md.era.short.clean$T_out_year_end))

sort(unique(md.era.short.clean$C_out_season_start))
sort(unique(md.era.short.clean$T_out_season_start))

sort(unique(md.era.short.clean$C_out_season_end))
sort(unique(md.era.short.clean$T_out_season_end))

#-----------------------------------------------
#---- Match with 01_FOMD_ontologies ----
#-----------------------------------------------
library(tibble)
library(purrr)

#=========================
#---location----
#=========================
#--- Reclassifying country as ISO_3166_1_Alpha_3
md.era.short.clean <- apply_lookup_ontologies(
  df        = md.era.short.clean,
  ref       = fomd01.countries,
  key_col   = "Country",
  value_col = "ISO_3166_1_Alpha_3",
  src_col   = "country",
  new_col   = "country_ISO1"
)

#Remove duplicate country and country_ISO
md.era.short.clean <- md.era.short.clean %>%
  mutate(
    country = map_chr(str_split(str_squish(country), "\\.\\."), \(x) paste(unique(str_squish(x)), collapse = "..")),
    country_ISO1 = map_chr(str_split(str_squish(country_ISO1), "\\.\\."), \(x) paste(unique(str_squish(x)), collapse = ".."))
  )

# Quick checks
# All the studied countries are in fomd01.countries
unique_countries <-data.frame(
  country = md.era.short.clean %>%
               pull(country) %>%
               str_split("\\.\\.") %>%
               unlist() %>%
               str_trim())%>%
  distinct(country) %>%
  arrange(country)%>%
  left_join(fomd01.countries%>%
              filter(!is.na(Country))%>%
              distinct(Country,ISO_3166_1_Alpha_3),
            by=c("country"="Country"))
  #filter(is.na(Product.Type))

sort(unique(md.era.short.clean$country))
sort(unique(md.era.short.clean$country_ISO))

#=========================
#---outcome----
#=========================
#--- Reclassifying out_subindicator as out_indicator
md.era.short.clean <- apply_lookup_ontologies(
  df        = md.era.short.clean,
  ref       = fomd01.outcomes,
  key_col   = "subindicator",
  value_col = "indicator",
  src_col   = "out_subindicator",
  new_col   = "out_indicator"
)

# Quick checks
sort(unique(md.era.short.clean$out_subindicator))
sort(unique(md.era.short.clean$out_indicator))

#--- Reclassifying out_subindicator as out_subpillar
md.era.short.clean <- apply_lookup_ontologies(
  df        = md.era.short.clean,
  ref       = fomd01.outcomes,
  key_col   = "subindicator",
  value_col = "subpillar",
  src_col   = "out_subindicator",
  new_col   = "out_subpillar"
)

# Quick checks
sort(unique(md.era.short.clean$out_subindicator))
sort(unique(md.era.short.clean$out_subpillar))

sort(unique(md.era.short.clean$out_subindicator[md.era.short.clean$out_subpillar==""]))
sort(unique(md.era.short.clean$out_subindicator[is.na(md.era.short.clean$out_subpillar)]))

#--- Reclassifying out_subindicator as out_pillar
md.era.short.clean <- apply_lookup_ontologies(
  df        = md.era.short.clean,
  ref       = fomd01.outcomes,
  key_col   = "subindicator",
  value_col = "pillar",
  src_col   = "out_subindicator",
  new_col   = "out_pillar"
)

sort(unique(md.era.short.clean$out_subindicator))
sort(unique(md.era.short.clean$out_pillar))
sort(unique(md.era.short.clean$out_subindicator[md.era.short.clean$out_pillar==""]))
sort(unique(md.era.short.clean$out_subindicator[is.na(md.era.short.clean$out_pillar)]))

#==========================================================
# Unselect unnecessary columns
#==========================================================  
fomd10.names <- unique(names(fomd10))
fomd10.names<-c(fomd10.names,"practice_compared","practice_compared_detail", "practice_compared_n")
fomd10.names
names(md.era.short.clean)

#--- Clean columns
# columns missing in md.era.short.clean
missing_cols <- setdiff(fomd10.names, names(md.era.short.clean))
missing_cols

# add missing columns as NA
md.era.clean <- md.era.short.clean

for (col in missing_cols) {
  md.era.clean[[col]] <- NA
}

# keep only columns in fomd10.names, in the same order
md.era.clean <- md.era.clean[, fomd10.names, drop = FALSE]

# check
list(
  only_in_md.era.clean = setdiff(names(md.era.clean), fomd10.names),
  only_in_fomd10.names = setdiff(fomd10.names, names(md.era.clean))
)


names(md.era.clean)

readr::write_csv(md.era.clean, paste0(path.metadata, "/04.added_to_06_FOMD_metadata_original_long/added_to_10_MD_Rosen_24_Effec_Sc.csv"))


#md.era.short.clean <- read.csv(file.path(path.metadata, "/04.added_to_06_FOMD_metadata_original_long/added_to_10_MD_Rosen_24_Effec_Sc.csv"))

readr::write_csv(md.era.clean, paste0(path.metadata.effectsize, "/fomd10/fomd10_MD_Rosen_24_Effec_Sc.csv"))

#readr::write_csv(md.era.short.clean, paste0(path.metadata.effectsize, "/fomd10/fomd10_MD_Rosen_24_Effec_Sc.csv"))

df_subset <- md.era.clean[1:10000, ]

readr::write_csv(df_subset, paste0(path.metadata.effectsize, "/fomd10/subset.fomd10_MD_Rosen_24_Effec_Sc.csv"))



### biodiversity rows checking

sort(unique(md.era.short.clean$out_subindicator))
sort(unique(md.era.short.clean$out_subindicator[md.era.short.clean$out_indicator=="Biodiversity"]))

biodiversity<-md.era.short.clean%>%
  filter(out_indicator=="Biodiversity")%>%
  filter(doi=="10.1016/j.agee.2018.11.020")%>%
  select(doi,study_id,effect_size_id, 
         C_product,T_product,
         C_out_value,T_out_value,
         bio_func_group,	bio_ground_ref,
         out_subindicator,
         C_out_soil_depth_l,	C_out_soil_depth_u,
         T_out_soil_depth_l,	T_out_soil_depth_u,
         
         C_site_id,
         out_subindicator_unit,
         
         C_out_var_value,T_out_var_value,
         C_data_location,T_data_location,
         practice_compared
         
  )

readr::write_csv(biodiversity, paste0(path.era, "/v46_error_report/biodiversity_JO0120.csv"))

names(md.era.short.clean)
sort(unique(biodiversity$C_product))
sort(unique(biodiversity$out_subindicator))
sort(unique(biodiversity$out_subindicator_unit))


names(biodiversity)
sort(unique(biodiversity$study_id))
sort(unique(biodiversity$doi))
sort(unique(biodiversity$title))
sort(unique(md.era.short.clean$doi[md.era.short.clean$title=="Rangeland vegetation responses to traditional enclosure management in eastern Ethiopia"]))


