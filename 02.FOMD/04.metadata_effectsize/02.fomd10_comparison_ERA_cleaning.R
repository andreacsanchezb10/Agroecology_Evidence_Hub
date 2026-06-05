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

fomd01.outcomes<-read_xlsx(file.path(path.metadata.structure,"01_FOMD_ontologies.xlsx"), sheet = "01_outcomes")%>%
  filter(!is.na(subindicator) )
fomd01.practices<-read_xlsx(file.path(path.metadata.structure,"01_FOMD_ontologies.xlsx"), sheet = "01_practices")
sort(unique(fomd01.practices$subpractice))

#---04_FOMD_screening
fomd04<-read_xlsx(file.path(path.metadata.structure,"04_FOMD_screening.xlsx"), sheet = "04_FOMD_screening")%>%
  filter(ss_id!="MD_Rosen_24_Effec_Sc")%>%
  filter(status =="I")
length(unique(fomd04$study_id))#20

#---ERA metadata short
#md.era.short <- read.csv(file.path(path.era, "ERA_data_short_v6.csv"))
md.era.short <- read.csv(file.path(path.era, "ERA_data_short_v12.csv"))

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
length(unique(md.era.short.clean$effect_size_id))  #232257
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
sort(unique(md.era.short.clean$site_id[md.era.short.clean$country==""])) "Cedara Research Station"
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
    
sort(unique(md.era.short.clean$site_id[md.era.short.clean$country==""]))
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
    TRUE ~ site_buffer))

# Quick checks
sort(unique(md.era.short.clean$site_id[md.era.short.clean$site_type==""]))
sort(unique(md.era.short.clean$site_id[md.era.short.clean$site_agg==""]))
sort(unique(md.era.short.clean$site_id[is.na(md.era.short.clean$country)]))
sort(unique(md.era.short.clean$site_id[md.era.short.clean$country=="Missing"]))
sort(unique(md.era.short.clean$site_id[md.era.short.clean$country=="Unspecified"]))
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
  
# Quick checks
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
length(unique(md.era.short.clean$T_site_key))  #1890
length(unique(md.era.short.clean$C_site_key))  #1890

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
md.era.short.clean$time_year_start <- gsub("...", "..", md.era.short.clean$time_year_start, fixed = TRUE)


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
md.era.short.clean <- md.era.short.clean%>%
  mutate(
    # Replace ANY sequence of 1 or more * with exactly **
    C_crop_variety = gsub("\\*+", "**", C_crop_variety),
    C_crop_variety = gsub("\\$+", "**", C_crop_variety),
    C_crop_variety = gsub("\\(\\s*NA\\s*\\)", "(Unspecified)", C_crop_variety, ignore.case = TRUE),
    
    T_crop_variety = gsub("\\*+", "**", T_crop_variety),
    T_crop_variety = gsub("\\$+", "**", T_crop_variety),
    T_crop_variety = gsub("\\(\\s*NA\\s*\\)", "(Unspecified)", T_crop_variety, ignore.case = TRUE)
  )
  
# Reusable function to combine crop_diversity + crop_density columns separated by "/" or "-"
create_density <- function(diversity, density) {
  if (is.na(diversity) || diversity == "") return("")
  
  # Split on / or - outside parentheses
  # Strategy: track parenthesis depth character by character
  split_outside_parens <- function(x, delimiters = c("/", "-")) {
    if (is.na(x) || x == "") return(character(0))
    chars <- strsplit(x, "")[[1]]
    depth <- 0
    positions <- c()
    for (i in seq_along(chars)) {
      if (chars[i] == "(") depth <- depth + 1
      else if (chars[i] == ")") depth <- depth - 1
      else if (chars[i] %in% delimiters && depth == 0) positions <- c(positions, i)
    }
    if (length(positions) == 0) return(trimws(x))
    
    # Extract parts and separators
    starts <- c(1, positions + 1)
    ends   <- c(positions - 1, nchar(x))
    parts  <- trimws(substring(x, starts, ends))
    parts
  }
  
  get_seps_outside_parens <- function(x, delimiters = c("/", "-")) {
    if (is.na(x) || x == "") return(character(0))
    chars <- strsplit(x, "")[[1]]
    depth <- 0
    seps  <- c()
    for (i in seq_along(chars)) {
      if (chars[i] == "(") depth <- depth + 1
      else if (chars[i] == ")") depth <- depth - 1
      else if (chars[i] %in% delimiters && depth == 0) seps <- c(seps, chars[i])
    }
    seps
  }
  
  div_crops <- split_outside_parens(diversity)
  den_crops <- split_outside_parens(density)
  div_seps  <- get_seps_outside_parens(diversity)
  
  if (length(den_crops) == 1) den_crops <- rep(den_crops, length(div_crops))
  
  if (length(div_crops) == 0) return("")
  
  paired <- mapply(function(crop, dens) {
    if (is.na(dens) || dens == "NA" || dens == "") {
      paste0(crop, "[Unspecified(Unspecified)]")
    } else {
      paste0(crop, "[", dens, "]")
    }
  }, div_crops, den_crops)
  
  result <- paired[1]
  if (length(div_seps) > 0) {
    for (i in seq_along(div_seps)) {
      result <- paste0(result, div_seps[i], paired[i + 1])
    }
  }
  
  return(as.character(result))
}

md.era.short.clean <- md.era.short.clean%>%
  mutate(
    C_crop_density=mapply(create_density,C_crop_diversity,C_crop_density),
    T_crop_density=mapply(create_density,T_crop_diversity,T_crop_density)
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
md.era.short.clean <- md.era.short.clean%>%
  mutate(
    C_tree_density=case_when((!is.na(C_tree_diversity)|C_tree_diversity!="")& is.na(C_tree_density)~"Unspecified(Unspecified)",TRUE~C_tree_density),
    C_tree_density=gsub("NA", "Unspecified(Unspecified)", C_tree_density, fixed = TRUE),
    T_tree_density=case_when(
      (!is.na(T_tree_diversity)|T_tree_diversity!="")& is.na(T_tree_density)~"Unspecified(Unspecified)",
      T_tree_density=="NA-NA-NA-NA-NA-NA-NA-NA-NA-NA-NA"~"NA-NA-NA-NA-NA-NA-NA-NA-NA-NA-NA-NA",
      TRUE~T_tree_density),
    T_tree_density=gsub("NA", "Unspecified(Unspecified)", T_tree_density, fixed = TRUE),
    
    )%>%
  mutate(
    C_tree_density1= mapply(create_density,C_tree_diversity,C_tree_density),
    T_tree_density1 = mapply(create_density,T_tree_diversity,T_tree_density))

# Quick checks
sort(unique(md.era.short.clean$C_tree_diversity))
sort(unique(md.era.short.clean$T_tree_diversity))

sort(unique(md.era.short.clean$C_tree_density))
sort(unique(md.era.short.clean$T_tree_density))

sort(unique(md.era.short.clean$C_tree_density1))
sort(unique(md.era.short.clean$T_tree_density1))

#=========================
#---commodity_animal----
#=========================
## TO CHECK: density
md.era.short.clean <- md.era.short.clean%>%
  mutate(
    C_animal_diversity = gsub("\\*+", "**", C_animal_diversity),
    T_animal_diversity = gsub("\\*+", "**", T_animal_diversity),
    C_animal_breed = gsub("\\*+", "**", C_animal_breed),
    T_animal_breed = gsub("\\*+", "**", T_animal_breed))
    
# Quick checks
sort(unique(md.era.short.clean$C_animal_diversity))
sort(unique(md.era.short.clean$T_animal_diversity))

sort(unique(md.era.short.clean$C_animal_breed))
sort(unique(md.era.short.clean$T_animal_breed))

sort(unique(md.era.short.clean$C_animal_density)) # TO CHECK: Missing
sort(unique(md.era.short.clean$T_animal_density)) # TO CHECK: Missing

#==================================================
#---improved_crop_varieties_practice---- 
#==================================================
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

# Quick checks
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

#=========================
#---soil_management_practice---- 
#=========================
md.era.short.clean$C_tillage_subpractice <- gsub("...", "..", md.era.short.clean$C_tillage_subpractice, fixed = TRUE)
md.era.short.clean$T_tillage_subpractice <- gsub("...", "..", md.era.short.clean$T_tillage_subpractice, fixed = TRUE)
md.era.short.clean$C_tillage_method <- gsub("; ", "..", md.era.short.clean$C_tillage_method, fixed = TRUE)
md.era.short.clean$C_tillage_method <- gsub(" ..", "..", md.era.short.clean$C_tillage_method, fixed = TRUE)
md.era.short.clean$T_tillage_method <- gsub("; ", "..", md.era.short.clean$T_tillage_method, fixed = TRUE)
md.era.short.clean$T_tillage_method <- gsub(" ..", "..", md.era.short.clean$T_tillage_method, fixed = TRUE)
md.era.short.clean$C_tillage_method_other <- gsub("; ", "..", md.era.short.clean$C_tillage_method_other, fixed = TRUE)
md.era.short.clean$T_tillage_method_other <- gsub("; ", "..", md.era.short.clean$T_tillage_method_other, fixed = TRUE)
md.era.short.clean$C_tillage_frequency <- gsub("; ", "..", md.era.short.clean$C_tillage_frequency, fixed = TRUE)
md.era.short.clean$T_tillage_frequency <- gsub("; ", "..", md.era.short.clean$T_tillage_frequency, fixed = TRUE)

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
md.era.short.clean$C_planting_subpractice <- gsub("...", "..", md.era.short.clean$C_planting_subpractice, fixed = TRUE)
md.era.short.clean$T_planting_subpractice <- gsub("...", "..", md.era.short.clean$T_planting_subpractice, fixed = TRUE)
md.era.short.clean$C_planting_subpractice <- gsub("NA", "Unspecified", md.era.short.clean$C_planting_subpractice, fixed = TRUE)
md.era.short.clean$T_planting_subpractice <- gsub("NA", "Unspecified", md.era.short.clean$T_planting_subpractice, fixed = TRUE)

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

#=========================
#---intercropping_practice----
#=========================
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
md.era.short.clean$C_crop_seq_residues_fate <- gsub("; ", "..", md.era.short.clean$C_crop_seq_residues_fate, fixed = TRUE)
md.era.short.clean$T_crop_seq_residues_fate <- gsub("; ", "..", md.era.short.clean$T_crop_seq_residues_fate, fixed = TRUE)
md.era.short.clean$C_crop_seq_residues_fate <- gsub("NA", "Unspecified", md.era.short.clean$C_crop_seq_residues_fate, fixed = TRUE)
md.era.short.clean$T_crop_seq_residues_fate <- gsub("NA", "Unspecified", md.era.short.clean$T_crop_seq_residues_fate, fixed = TRUE)

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

sort(unique(md.era.short.clean$C_agrof_subpractice)) # TO CHECK: I think Monoculture is missing here
sort(unique(md.era.short.clean$T_agrof_subpractice))

sort(unique(md.era.short.clean$agrof_shade_mean_min_max)) #Missing from ERA
sort(unique(md.era.short.clean$agrof_canopy_height_mean_min_max)) #Missing from ERA
sort(unique(md.era.short.clean$agrof_dhb_mean_min_max))#Missing from ERA

#==================================================
#---nutrient_management_practice (inorganic)----
#==================================================
## TO CHECK: C_fert_subpractice C_fert_organic_type
# C_fert_inorganic_type_amount_unit  T_fert_inorganic_type_amount_unit

# Columns where "; " should become ".."
npk_in_semicolon_cols <- c(
  "C_fert_inorganic_category", "T_fert_inorganic_category",
  "C_fert_inorganic_type",     "T_fert_inorganic_type",
  "C_fert_inorganic_unit",     "T_fert_inorganic_unit",
  "C_fert_inorganic_amount",   "T_fert_inorganic_amount"
)

# Columns needing only "..." -> ".."
npk_in_unit_cols <- c(
  "C_fert_inorganicNPK_unit", "T_fert_inorganicNPK_unit"
)

# Columns needing "..." -> "..", strip whitespace, and remove "999999"
npk_in_cols <- c(
  "C_fert_inorganicN",    "T_fert_inorganicN",
  "C_fert_inorganicP",    "T_fert_inorganicP",
  "C_fert_inorganicK",    "T_fert_inorganicK",
  "C_fert_inorganicP2O5", "T_fert_inorganicP2O5",
  "C_fert_inorganicK2O",  "T_fert_inorganicK2O"
)

# Columns needing "NA..NA..NA.." -> "NA..NA..NA..NA"
npd_in_NA_amount_cols<- c(
  "C_fert_inorganicN", "T_fert_inorganicN",
  "C_fert_inorganicP", "T_fert_inorganicP",
  "C_fert_inorganicK", "T_fert_inorganicK",
  "C_fert_inorganicK2O", "T_fert_inorganicK2O",
  "C_fert_inorganicP2O5", "T_fert_inorganicP2O5")
  
# Apply "; " -> ".." substitution
md.era.short.clean[npk_in_semicolon_cols] <- lapply(
  md.era.short.clean[npk_in_semicolon_cols],
  \(x) gsub("; ", "..", x, fixed = TRUE)
)

# Apply "..." -> ".." only
md.era.short.clean[npk_in_unit_cols] <- lapply(
  md.era.short.clean[npk_in_unit_cols],
  \(x) gsub("...", "..", x, fixed = TRUE)
)

# Apply "..." -> "..", strip whitespace, remove "999999"
md.era.short.clean[npk_in_cols] <- lapply(
  md.era.short.clean[npk_in_cols],
  \(x) trimws(gsub("999999", "", gsub("\\s+", "", gsub("...", "..", x, fixed = TRUE))))
)

# Apply "NA..NA..NA.." -> "NA..NA..NA..NA"
md.era.short.clean[npd_in_NA_amount_cols] <- lapply(
  md.era.short.clean[npd_in_NA_amount_cols],
  \(x) trimws(gsub("NA..NA..NA..", "NA..NA..NA..NA", x, fixed = TRUE))
)

# Function to clean a category string
clean_fert_category <- function(x, remove_cats) {
  sapply(x, function(val) {
    if (is.na(val) || val == "") return(val)
    
    # Split by ".."
    parts <- strsplit(val, "\\.\\.")[[1]]
    
    # Remove any part that matches the organic categories
    parts_clean <- parts[!parts %in% remove_cats]
    
    # Rejoin remaining parts
    if (length(parts_clean) == 0) return("")
    paste(parts_clean, collapse = "..")
  }, USE.NAMES = FALSE)
}

# Define the organic categories to remove
organic_to_remove <- c("Ash", "Biosolid", "Compost", "Manure", "Organic_Other")

# Apply to both columns
md.era.short.clean<-md.era.short.clean%>%
  mutate(
    C_fert_inorganic_category =clean_fert_category(C_fert_inorganic_category, organic_to_remove),
    T_fert_inorganic_category = clean_fert_category(T_fert_inorganic_category, organic_to_remove))

# Reusable function to combine amount + unit columns separated by ".."
combine_amount_unit <- function(amount, unit, sep = "..") {
  mapply(function(amt, unt) {
    if (is.na(amt) || amt == "") return(amt)
    
    amounts <- strsplit(amt, "\\.\\.") [[1]]
    units   <- strsplit(unt, "\\.\\.") [[1]]
    
    # Single unit: recycle across all amounts (not a problem)
    if (length(units) == 1) {
      units <- rep(units, length(amounts))
    }
    
    units <- ifelse(is.na(units) | units == "", "Unspecified", units)
    
    # Only warn when MULTIPLE units exist but count doesn't match amounts
    if (length(units) > 1 && length(amounts) != length(units)) {
      warning(paste("Length mismatch: amounts =", length(amounts),
                    "units =", length(units), "— recycling units."))
      units <- rep_len(units, length(amounts))
    }
    
    paste(paste0(amounts, "(", units, ")"), collapse = sep)
    
  }, amount, unit, USE.NAMES = FALSE)
}

# Combine amount + unit columns separated by ".."
md.era.short.clean <- md.era.short.clean%>%
  mutate(C_fert_inorganicN_amount_unit= combine_amount_unit(amount = C_fert_inorganicN,unit   = C_fert_inorganicNPK_unit),
         C_fert_inorganicP_amount_unit= combine_amount_unit(amount = C_fert_inorganicP,unit   = C_fert_inorganicNPK_unit),
         C_fert_inorganicK_amount_unit= combine_amount_unit(amount = C_fert_inorganicK,unit   = C_fert_inorganicNPK_unit),
         C_fert_inorganicP2O5_amount_unit= combine_amount_unit(amount = C_fert_inorganicP2O5,unit   = C_fert_inorganicNPK_unit),
         C_fert_inorganicK2O_amount_unit= combine_amount_unit(amount = C_fert_inorganicK2O,unit   = C_fert_inorganicNPK_unit),
         
         T_fert_inorganicN_amount_unit= combine_amount_unit(amount = T_fert_inorganicN,unit   = T_fert_inorganicNPK_unit),
         T_fert_inorganicP_amount_unit= combine_amount_unit(amount = T_fert_inorganicP,unit   = T_fert_inorganicNPK_unit),
         #T_fert_inorganicK_amount_unit= combine_amount_unit(amount = T_fert_inorganicK,unit   = T_fert_inorganicNPK_unit),
         T_fert_inorganicP2O5_amount_unit= combine_amount_unit(amount = T_fert_inorganicP2O5,unit   = T_fert_inorganicNPK_unit),
         T_fert_inorganicK2O_amount_unit= combine_amount_unit(amount = T_fert_inorganicK2O,unit   = T_fert_inorganicNPK_unit)
  )
#-------------------------------------------------------
# Code to check mismatch between amount and unit columns
#-------------------------------------------------------
check_length_mismatch <- function(df, amount_col, unit_col) {
  amt <- df[[amount_col]]
  unt <- df[[unit_col]]
  
  mismatches <- mapply(function(a, u, id) {
    if (is.na(a) || a == "") return(NULL)
    na <- length(strsplit(a, "\\.\\.")[[1]])
    nu <- length(strsplit(u, "\\.\\.")[[1]])
    # Ignore single-unit rows — those are fine
    if (nu == 1) return(NULL)
    if (na != nu) data.frame(study_id = id, amount_col, unit_col,
                             n_amounts = na, n_units = nu,
                             amount = a, unit = u)
  }, amt, unt, df$study_id, SIMPLIFY = FALSE)
  
  do.call(rbind, Filter(Negate(is.null), mismatches))
}


# Check mismatches for any amount/unit pair
check_length_mismatch <- function(df, amount_col, unit_col) {
  amt <- df[[amount_col]]
  unt <- df[[unit_col]]
  
  mismatches <- mapply(function(a, u, i) {
    if (is.na(a) || a == "") return(NULL)
    na <- length(strsplit(a, "\\.\\.")[[1]])
    nu <- length(strsplit(u, "\\.\\.")[[1]])
    if (na != nu) data.frame(row = i, amount_col, unit_col,
                             n_amounts = na, n_units = nu,
                             amount = a, unit = u)
  }, amt, unt, seq_along(amt), SIMPLIFY = FALSE)
  
  do.call(rbind, Filter(Negate(is.null), mismatches))
}

# Run for all relevant pairs
pairs <- list(
  c("T_fert_inorganicN",   "T_fert_inorganicNPK_unit"),
  c("T_fert_inorganicP",   "T_fert_inorganicNPK_unit"),
  c("T_fert_inorganicP2O5","T_fert_inorganicNPK_unit"),
  c("T_fert_inorganicK2O", "T_fert_inorganicNPK_unit"),
  c("C_fert_inorganicN",   "C_fert_inorganicNPK_unit"),
  c("C_fert_inorganicK2O", "C_fert_inorganicNPK_unit")
)

mismatch_report <- do.call(rbind, lapply(pairs, function(p)
  check_length_mismatch(md.era.short.clean, p[1], p[2])
))

View(mismatch_report)


#-------------------------------------------------------
# Code to check mismatch between type, amount and unit columns
#-------------------------------------------------------
check_length_mismatch <- function(df, type_col, amount_col, unit_col) {
  typ <- df[[type_col]]
  amt <- df[[amount_col]]
  unt <- df[[unit_col]]
  
  mismatches <- mapply(function(t, a, u, id) {
    # Use type as the reference if amount is empty
    if ((is.na(t) || t == "") && (is.na(a) || a == "")) return(NULL)
    
    nt <- if (is.na(t) || t == "") NA else length(strsplit(t, "\\.\\.") [[1]])
    na <- if (is.na(a) || a == "") NA else length(strsplit(a, "\\.\\.") [[1]])
    nu <- if (is.na(u) || u == "") NA else length(strsplit(u, "\\.\\.") [[1]])
    
    # Single unit is fine — not a mismatch
    if (!is.na(nu) && nu == 1) return(NULL)
    
    # Flag if any of the three differ from each other
    counts <- na.omit(c(nt, na, nu))
    if (length(unique(counts)) <= 1) return(NULL)
    
    data.frame(study_id  = id,
               type_col  = type_col,
               amount_col = amount_col,
               unit_col  = unit_col,
               n_types   = nt,
               n_amounts = na,
               n_units   = nu,
               type      = t,
               amount    = a,
               unit      = u)
    
  }, typ, amt, unt, df$study_id, SIMPLIFY = FALSE)
  
  do.call(rbind, Filter(Negate(is.null), mismatches))
}

# Run for all relevant triplets
pairs <- list(
  #c("C_fert_inorganic_type", "C_fert_inorganic_amount", "C_fert_inorganic_unit"),
  #c("T_fert_inorganic_type", "T_fert_inorganic_amount", "T_fert_inorganic_unit"),
  c("C_fert_inorganic_type", "C_fert_inorganic_amount", "C_fert_inorganic_unit"),
  c("T_fert_inorganic_type", "T_fert_inorganic_amount", "T_fert_inorganic_unit")
)

mismatch_report <- do.call(rbind, lapply(pairs, function(p)
  check_length_mismatch(md.era.short.clean, p[1], p[2], p[3])
))

View(mismatch_report)


#------------
# Quick checks
sort(unique(md.era.short.clean$C_fert_subpractice_raw))
sort(unique(md.era.short.clean$T_fert_subpractice_raw))

sort(unique(md.era.short.clean$C_fert_subpractice)) #TO CHECK: IT DOESN'T EXIST NOW
sort(unique(md.era.short.clean$T_fert_subpractice)) #TO CHECK: IT DOESN'T EXIST NOW

sort(unique(md.era.short.clean$C_fert_inorganic_category)) 
sort(unique(md.era.short.clean$T_fert_inorganic_category)) 

sort(unique(md.era.short.clean$C_fert_inorganic_type)) #TO CHECK: Need to separate organic and inorganic
sort(unique(md.era.short.clean$T_fert_inorganic_type)) #TO CHECK: Need to separate organic and inorganic

sort(unique(md.era.short.clean$C_fert_inorganic_unit)) #TO CHECK: Need to separate organic and inorganic and combine type with amount and unit
sort(unique(md.era.short.clean$T_fert_inorganic_unit)) #TO CHECK: Need to separate organic and inorganic and combine type with amount and unit

sort(unique(md.era.short.clean$C_fert_inorganic_amount)) #TO CHECK: Need to separate organic and inorganic and combine type with amount and unit
sort(unique(md.era.short.clean$T_fert_inorganic_amount)) #TO CHECK: Need to separate organic and inorganic and combine type with amount and unit

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
sort(unique(md.era.short.clean$T_fert_inorganicK)) # TO CHECK: Not ready to merge
sort(unique(md.era.short.clean$C_fert_inorganicK[md.era.short.clean$C_fert_inorganicNPK_unit==""]))
#character(0)
sort(unique(md.era.short.clean$T_fert_inorganicK[md.era.short.clean$T_fert_inorganicNPK_unit==""]))
#[1] ""   "10"

sort(unique(md.era.short.clean$C_fert_inorganicP2O5))
sort(unique(md.era.short.clean$T_fert_inorganicP2O5))
sort(unique(md.era.short.clean$C_fert_inorganicP2O5[md.era.short.clean$C_fert_inorganicNPK_unit==""]))
#character(0)
sort(unique(md.era.short.clean$T_fert_inorganicP2O5[md.era.short.clean$T_fert_inorganicNPK_unit==""]))
#[1] ""   "10"

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

#=========================
#---nutrient_management_practice (organic)----
#=========================
# Columns where "; " should become ".."
npk_or_semicolon_cols <- c(
  "C_fert_organic_category", "T_fert_organic_category",
  "C_fert_organic_type",     "T_fert_organic_type",
  "C_fert_organic_unit",     "T_fert_organic_unit",
  "C_fert_organic_amount",   "T_fert_organic_amount",
  "C_fert_organic_source",   "T_fert_organic_source"
)

# Columns needing "..." -> ".."
npk_or_cols <- c(
  "C_fert_organicN", "T_fert_organicN",
  "C_fert_organicP", "T_fert_organicP",
  "C_fert_organicK", "T_fert_organicK"
)

# Apply "; " -> ".." substitution
md.era.short.clean[npk_or_semicolon_cols] <- lapply(
  md.era.short.clean[npk_or_semicolon_cols],
  \(x) gsub("; ", "..", x, fixed = TRUE)
)

# Apply "..." -> ".." 
md.era.short.clean[npk_or_cols] <- lapply(
  md.era.short.clean[npk_or_cols],
  \(x) gsub("...", "..", x, fixed = TRUE)
)

# Define the inorganic categories to remove
inorganic_to_remove <- c("Biochar","Inorganic", "MicroNutrient")

# Apply to both columns
md.era.short.clean<-md.era.short.clean%>%
  mutate(
    C_fert_organic_category =clean_fert_category(C_fert_organic_category, inorganic_to_remove),
    T_fert_organic_category = clean_fert_category(T_fert_organic_category, inorganic_to_remove))

# Combine amount + unit columns separated by ".."
md.era.short.clean <- md.era.short.clean%>%
  mutate(C_fert_organicN_amount_unit= combine_amount_unit(amount = C_fert_organicN,unit   = C_fert_organicNPK_unit),
         C_fert_organicP_amount_unit= combine_amount_unit(amount = C_fert_organicP,unit   = C_fert_organicNPK_unit),
         C_fert_organicK_amount_unit= combine_amount_unit(amount = C_fert_organicK,unit   = C_fert_organicNPK_unit),
         
         T_fert_organicN_amount_unit= combine_amount_unit(amount = T_fert_organicN,unit   = T_fert_organicNPK_unit),
         T_fert_organicP_amount_unit= combine_amount_unit(amount = T_fert_organicP,unit   = T_fert_organicNPK_unit),
         T_fert_organicK_amount_unit= combine_amount_unit(amount = T_fert_organicK,unit   = T_fert_organicNPK_unit)
  )

# Quick checks
sort(unique(md.era.short.clean1$C_fert_organic_category))  
sort(unique(md.era.short.clean1$T_fert_organic_category))  

sort(unique(md.era.short.clean$C_fert_organic_type))  #TO CHECK: Need to separate organic and inorganic
sort(unique(md.era.short.clean$T_fert_organic_type))  #TO CHECK: Need to separate organic and inorganic

sort(unique(md.era.short.clean$C_fert_organic_unit)) #TO CHECK: Need to separate organic and inorganic and combine type with amount and unit
sort(unique(md.era.short.clean$T_fert_organic_unit)) #TO CHECK: Need to separate organic and inorganic and combine type with amount and unit

sort(unique(md.era.short.clean$C_fert_organic_amount)) #TO CHECK: Need to separate organic and inorganic and combine type with amount and unit
sort(unique(md.era.short.clean$T_fert_organic_amount)) #TO CHECK: Need to separate organic and inorganic and combine type with amount and unit

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

sort(unique(md.era.short.clean$C_fert_organicN_amount_unit))
sort(unique(md.era.short.clean$C_fert_organicP_amount_unit))
sort(unique(md.era.short.clean$C_fert_organicK_amount_unit))
sort(unique(md.era.short.clean$T_fert_organicN_amount_unit))
sort(unique(md.era.short.clean$T_fert_organicP_amount_unit))
sort(unique(md.era.short.clean$T_fert_organicK_amount_unit))

#=========================
#---weeding_management_moderator----
#=========================
## TO CHECK: C_weed_frequency_unit T_weed_frequency_unit
md.era.short.clean$C_weed_method <- gsub("...", "..", md.era.short.clean$C_weed_method, fixed = TRUE)
md.era.short.clean$T_weed_method <- gsub("...", "..", md.era.short.clean$T_weed_method, fixed = TRUE)

md.era.short.clean$C_weed_frequency_unit <- gsub("...", "..", md.era.short.clean$C_weed_frequency_unit, fixed = TRUE)
md.era.short.clean$T_weed_frequency_unit <- gsub("...", "..", md.era.short.clean$T_weed_frequency_unit, fixed = TRUE)

md.era.short.clean$C_weed_frequency <- gsub("...", "..", md.era.short.clean$C_weed_frequency, fixed = TRUE)
md.era.short.clean$T_weed_frequency <- gsub("...", "..", md.era.short.clean$T_weed_frequency, fixed = TRUE)

# Quick checks
sort(unique(md.era.short.clean$C_weed_method_raw))
sort(unique(md.era.short.clean$T_weed_method_raw))

sort(unique(md.era.short.clean$C_weed_method))
sort(unique(md.era.short.clean$T_weed_method))

sort(unique(md.era.short.clean$C_weed_frequency_unit)) # TO CHECK not ready to merge
sort(unique(md.era.short.clean$T_weed_frequency_unit)) # TO CHECK not ready to merge

sort(unique(md.era.short.clean$C_weed_frequency)) # TO CHECK not ready to merge
sort(unique(md.era.short.clean$T_weed_frequency)) # TO CHECK not ready to merge

sort(unique(md.era.short.clean$C_weed_frequency[is.na(md.era.short.clean$C_weed_frequency_unit)]))
sort(unique(md.era.short.clean$C_weed_frequency[md.era.short.clean$C_weed_frequency_unit==""]))
#[1] ""                                   "2"                                  "3"                                  "4"                                 
#[5] "NA...1...1...1...1...2...2...2...2" "NA...4" 
sort(unique(md.era.short.clean$T_weed_frequency[is.na(md.era.short.clean$T_weed_frequency_unit)]))
sort(unique(md.era.short.clean$T_weed_frequency[md.era.short.clean$T_weed_frequency_unit==""]))
#[1] ""                                   "2"                                  "3"                                  "4"                                 
#[5] "NA...1...1...1...1...2...2...2...2" "NA...4" 

#=========================
#---chemical_management_practice----
#=========================
md.era.short.clean$C_chem_subpractice <- gsub("; ", "..", md.era.short.clean$C_chem_subpractice, fixed = TRUE)
md.era.short.clean$T_chem_subpractice <- gsub("; ", "..", md.era.short.clean$T_chem_subpractice, fixed = TRUE)

md.era.short.clean$C_chem_name <- gsub("; ", "..", md.era.short.clean$C_chem_name, fixed = TRUE)
md.era.short.clean$T_chem_name <- gsub("; ", "..", md.era.short.clean$T_chem_name, fixed = TRUE)

md.era.short.clean$C_chem_amount_unit <- gsub("; ", "..", md.era.short.clean$C_chem_amount_unit, fixed = TRUE)
md.era.short.clean$T_chem_amount_unit <- gsub("; ", "..", md.era.short.clean$T_chem_amount_unit, fixed = TRUE)

md.era.short.clean$C_chem_amount <- gsub("; ", "..", md.era.short.clean$C_chem_amount, fixed = TRUE)
md.era.short.clean$T_chem_amount <- gsub("; ", "..", md.era.short.clean$T_chem_amount, fixed = TRUE)

# Quick checks
sort(unique(md.era.short.clean$C_chem_subpractice_raw))
sort(unique(md.era.short.clean$T_chem_subpractice_raw))

sort(unique(md.era.short.clean$C_chem_subpractice))
sort(unique(md.era.short.clean$T_chem_subpractice))

sort(unique(md.era.short.clean$C_chem_name))
sort(unique(md.era.short.clean$T_chem_name))

sort(unique(md.era.short.clean$C_chem_amount_unit)) # TO CHECK not ready to merge
sort(unique(md.era.short.clean$T_chem_amount_unit)) # TO CHECK not ready to merge

sort(unique(md.era.short.clean$C_chem_amount)) # TO CHECK not ready to merge
sort(unique(md.era.short.clean$T_chem_amount)) # TO CHECK not ready to merge

sort(unique(md.era.short.clean$C_chem_amount[is.na(md.era.short.clean$C_chem_amount_unit)]))
sort(unique(md.era.short.clean$C_chem_amount[md.era.short.clean$C_chem_amount_unit==""]))
#[1] ""   "12" 
sort(unique(md.era.short.clean$T_chem_amount[is.na(md.era.short.clean$T_chem_amount_unit)]))
sort(unique(md.era.short.clean$T_chem_amount[md.era.short.clean$T_chem_amount_unit==""]))
#[1] ""   "12"

#=========================
#---residues_practice----
#=========================
## TO CHECK: A LOT OF THINGS TO CHECK HERE!!

md.era.short.clean$C_residues_OC <- gsub("; ", "..", md.era.short.clean$C_residues_OC, fixed = TRUE)
md.era.short.clean$T_residues_OC <- gsub("; ", "..", md.era.short.clean$T_residues_OC, fixed = TRUE)
md.era.short.clean$C_residues_OC <- trimws(gsub("\\s+", "", md.era.short.clean$C_residues_OC))
md.era.short.clean$T_residues_OC <- trimws(gsub("\\s+", "", md.era.short.clean$T_residues_OC))

md.era.short.clean$C_residues_N <- gsub("; ", "..", md.era.short.clean$C_residues_N, fixed = TRUE)
md.era.short.clean$T_residues_N <- gsub("; ", "..", md.era.short.clean$T_residues_N, fixed = TRUE)
md.era.short.clean$C_residues_N <- trimws(gsub("\\s+", "", md.era.short.clean$C_residues_N))
md.era.short.clean$T_residues_N <- trimws(gsub("\\s+", "", md.era.short.clean$T_residues_N))

md.era.short.clean$C_residues_P <- gsub("; ", "..", md.era.short.clean$C_residues_P, fixed = TRUE)
md.era.short.clean$T_residues_P <- gsub("; ", "..", md.era.short.clean$T_residues_P, fixed = TRUE)
md.era.short.clean$C_residues_P <- trimws(gsub("\\s+", "", md.era.short.clean$C_residues_P))
md.era.short.clean$T_residues_P <- trimws(gsub("\\s+", "", md.era.short.clean$T_residues_P))

md.era.short.clean$C_residues_K <- gsub("; ", "..", md.era.short.clean$C_residues_K, fixed = TRUE)
md.era.short.clean$T_residues_K <- gsub("; ", "..", md.era.short.clean$T_residues_K, fixed = TRUE)
md.era.short.clean$C_residues_K <- trimws(gsub("\\s+", "", md.era.short.clean$C_residues_K))
md.era.short.clean$T_residues_K <- trimws(gsub("\\s+", "", md.era.short.clean$T_residues_K))

md.era.short.clean$C_residues_tree <- gsub("; ", "..", md.era.short.clean$C_residues_tree, fixed = TRUE)
md.era.short.clean$T_residues_tree <- gsub("; ", "..", md.era.short.clean$T_residues_tree, fixed = TRUE)

md.era.short.clean$C_residues_material <- gsub("; ", "..", md.era.short.clean$C_residues_material, fixed = TRUE)
md.era.short.clean$T_residues_material <- gsub("; ", "..", md.era.short.clean$T_residues_material, fixed = TRUE)
md.era.short.clean$C_residues_material <- gsub(", ", "..", md.era.short.clean$C_residues_material, fixed = TRUE)
md.era.short.clean$T_residues_material <- gsub(", ", "..", md.era.short.clean$T_residues_material, fixed = TRUE)
md.era.short.clean$C_residues_material <- gsub(",\n", "..", md.era.short.clean$C_residues_material, fixed = TRUE)
md.era.short.clean$T_residues_material <- gsub(",\n", "..", md.era.short.clean$T_residues_material, fixed = TRUE)

md.era.short.clean$C_residues_material_source <- gsub("; ", "..", md.era.short.clean$C_residues_material_source, fixed = TRUE)
md.era.short.clean$T_residues_material_source <- gsub("; ", "..", md.era.short.clean$T_residues_material_source, fixed = TRUE)

md.era.short.clean$C_residues_material_amount <- gsub("; ", "..", md.era.short.clean$C_residues_material_amount, fixed = TRUE)
md.era.short.clean$T_residues_material_amount <- gsub("; ", "..", md.era.short.clean$T_residues_material_amount, fixed = TRUE)
md.era.short.clean$C_residues_material_amount <- trimws(gsub("\\s+", "", md.era.short.clean$C_residues_material_amount))
md.era.short.clean$T_residues_material_amount <- trimws(gsub("\\s+", "", md.era.short.clean$T_residues_material_amount))

# Quick checks
sort(unique(md.era.short.clean$C_residues_subpractice_raw))
sort(unique(md.era.short.clean$T_residues_subpractice_raw))

sort(unique(md.era.short.clean$C_residues_subpractice)) # TO CHECK
sort(unique(md.era.short.clean$T_residues_subpractice)) # TO CHECK

sort(unique(md.era.short.clean$C_residues_OC_unit)) # TO CHECK not ready to merge
sort(unique(md.era.short.clean$T_residues_OC_unit))# TO CHECK not ready to merge

sort(unique(md.era.short.clean$C_residues_OC)) # TO CHECK not ready to merge
sort(unique(md.era.short.clean$T_residues_OC)) # TO CHECK not ready to merge

sort(unique(md.era.short.clean$C_residues_OC[is.na(md.era.short.clean$C_residues_OC_unit)]))
sort(unique(md.era.short.clean$C_residues_OC[md.era.short.clean$C_residues_OC_unit==""]))
#[1] ""             "0"            "33.70..23.90"
sort(unique(md.era.short.clean$T_residues_OC[is.na(md.era.short.clean$T_residues_OC_unit)]))
sort(unique(md.era.short.clean$T_residues_OC[md.era.short.clean$T_residues_OC_unit==""]))
#[1] ""             "0"            "33.70..23.90"

sort(unique(md.era.short.clean$C_residues_N_unit)) #Ready to merge
sort(unique(md.era.short.clean$T_residues_N_unit)) # TO CHECK not ready to merge
 
sort(unique(md.era.short.clean$C_residues_N)) #Ready to merge
sort(unique(md.era.short.clean$T_residues_N)) # TO CHECK not ready to merge

sort(unique(md.era.short.clean$C_residues_N[is.na(md.era.short.clean$C_residues_N_unit)]))
sort(unique(md.era.short.clean$C_residues_N[md.era.short.clean$C_residues_N_unit==""]))
#[1] ""             "0"            "33.70..23.90"
sort(unique(md.era.short.clean$T_residues_N[is.na(md.era.short.clean$T_residues_N_unit)]))
sort(unique(md.era.short.clean$T_residues_N[md.era.short.clean$T_residues_N_unit==""]))
#[1] ""       "0"      "102"    "122"    "1294.4" "142"    "163"    "183"    "203"    "22.5"   "25"     "3.53"   "30"     "4.14"   "4.26"   "45"    
#[17] "60"     "61"     "83"     "90"  

sort(unique(md.era.short.clean$C_residues_P_unit)) #Ready to merge
sort(unique(md.era.short.clean$T_residues_P_unit)) #Ready to merge

sort(unique(md.era.short.clean$C_residues_P)) #Ready to merge
sort(unique(md.era.short.clean$T_residues_P)) #Ready to merge

sort(unique(md.era.short.clean$C_residues_P[is.na(md.era.short.clean$C_residues_P_unit)]))
sort(unique(md.era.short.clean$C_residues_P[md.era.short.clean$C_residues_P_unit==""]))
#[1] ""  "0"
sort(unique(md.era.short.clean$T_residues_P[is.na(md.era.short.clean$T_residues_P_unit)]))
sort(unique(md.era.short.clean$T_residues_P[md.era.short.clean$T_residues_P_unit==""]))
#[1] ""  "0" 

sort(unique(md.era.short.clean$C_residues_K_unit)) # TO CHECK not ready to merge
sort(unique(md.era.short.clean$T_residues_K_unit)) # TO CHECK not ready to merge
 
sort(unique(md.era.short.clean$C_residues_K)) # TO CHECK not ready to merge
sort(unique(md.era.short.clean$T_residues_K)) # TO CHECK not ready to merge

sort(unique(md.era.short.clean$C_residues_K[is.na(md.era.short.clean$C_residues_K_unit)]))
sort(unique(md.era.short.clean$C_residues_K[md.era.short.clean$C_residues_K_unit==""]))
#[1] ""             "0"            "13.80..15.80" "43.2"  
sort(unique(md.era.short.clean$T_residues_K[is.na(md.era.short.clean$T_residues_K_unit)]))
sort(unique(md.era.short.clean$T_residues_K[md.era.short.clean$T_residues_K_unit==""]))
#[1] ""             "0"            "13.80..15.80" "43.2"

sort(unique(md.era.short.clean$C_residues_tree))
sort(unique(md.era.short.clean$T_residues_tree))

sort(unique(md.era.short.clean$C_residues_material))
sort(unique(md.era.short.clean$T_residues_material))

sort(unique(md.era.short.clean$C_residues_processing))
sort(unique(md.era.short.clean$C_residues_processing))

sort(unique(md.era.short.clean$C_residues_material_source))
sort(unique(md.era.short.clean$T_residues_material_source))

sort(unique(md.era.short.clean$C_residues_material_unit)) # TO CHECK not ready to merge
sort(unique(md.era.short.clean$T_residues_material_unit)) # TO CHECK

sort(unique(md.era.short.clean$C_residues_material_amount)) # TO CHECK not ready to merge
sort(unique(md.era.short.clean$T_residues_material_amount)) # TO CHECK

sort(unique(md.era.short.clean$C_residues_material_amount[is.na(md.era.short.clean$C_residues_material_unit)]))
sort(unique(md.era.short.clean$C_residues_material_amount[md.era.short.clean$C_residues_material_unit==""]))
#[1] "0"    "10"   "100"  "11"   "12"   "13"   "15"   "2.5"  "20"   "2700" "3.5"  "30"   "300"  "33"   "4"    "40"   "4000" "50"   "800"  "900"   
sort(unique(md.era.short.clean$T_residues_material_amount[is.na(md.era.short.clean$T_residues_material_unit)]))
sort(unique(md.era.short.clean$T_residues_material_amount[md.era.short.clean$T_residues_material_unit==""]))
#[1] ""                         "0"                        "0.5"                      "0.90..3.20..12.20..18.30" "0.94"                    
#[6] "1"                        "1.2"                      "1.3"                      "1.40..4.80..18.40..27.60" "1.5"                     
#[11] "1.6"                      "10"                       "100"                      "11"                       "11.27"                   
#[16] "11.33"                    "11.58"                    "11.92"                    "112.5"                    "116"                     
#[21] "12"                       "12.00..6.00"              "12.5"                     "13"                       "1400"                    
#[26] "15"                       "15.81"                    "1500"                     "16.02"                    "1600"                    
#[31] "1666"                     "17"                       "19.19"                    "19.61"                    "2"                       
#[36] "2.4"                      "2.41"                     "2.5"                      "2.6"                      "2.7" 

#=========================
#---pH_amendment_practice----
#=========================
combine_material_amount_unit <- function(applied, amount_unit) {
  if (applied == "" || is.na(applied)) return("")
  
  applied_parts     <- strsplit(applied,     "\\.\\.")[[1]]
  amount_unit_parts <- strsplit(amount_unit, "\\.\\.")[[1]]
  
  if (length(applied_parts) == length(amount_unit_parts)) {
    pairs <- mapply(function(a, au) {
      if (is.na(au) || grepl("^NA$|^NA\\(|\\(NA\\)", au)) {
        paste0(a, "[Unspecified(Unspecified)]")
      } else {
        au_clean <- gsub("/ha|/m2|/plant", "", au)
        paste0(a, "[", au_clean, "]")
      }
    }, applied_parts, amount_unit_parts)
  } else {
    # NA guard here too
    au <- amount_unit_parts[1]
    if (is.na(au) || grepl("^NA$|^NA\\(|\\(NA\\)", au)) {
      pairs <- paste0(applied_parts, "[Unspecified(Unspecified)]")
    } else {
      au_clean <- gsub("/ha|/m2|/plant", "", au)
      pairs <- paste0(applied_parts, "[", au_clean, "]")
    }
  }
  
  paste(pairs, collapse = "..")
}
  
md.era.short.clean$C_ph_subpractice <- gsub("...", "..", md.era.short.clean$C_ph_subpractice, fixed = TRUE)
md.era.short.clean$T_ph_subpractice <- gsub("...", "..", md.era.short.clean$T_ph_subpractice, fixed = TRUE)

md.era.short.clean$C_ph_material_applied <- gsub("; ", "..", md.era.short.clean$C_ph_material_applied, fixed = TRUE)
md.era.short.clean$T_ph_material_applied <- gsub("; ", "..", md.era.short.clean$T_ph_material_applied, fixed = TRUE)
md.era.short.clean$C_ph_material_applied <- gsub("+", "..", md.era.short.clean$C_ph_material_applied, fixed = TRUE)
md.era.short.clean$T_ph_material_applied <- gsub("+", "..", md.era.short.clean$T_ph_material_applied, fixed = TRUE)

md.era.short.clean$C_ph_material_amount <- gsub("; ", "..", md.era.short.clean$C_ph_material_amount, fixed = TRUE)
md.era.short.clean$T_ph_material_amount <- gsub("; ", "..", md.era.short.clean$T_ph_material_amount, fixed = TRUE)

# Merge ph_material_amount(ph_material_unit) into ph_material_amount_unit
md.era.short.clean <- md.era.short.clean%>%
  mutate(C_ph_material_amount_unit1= combine_amount_unit(amount = C_ph_material_amount, unit   = C_ph_material_unit),
         T_ph_material_amount_unit1= combine_amount_unit(amount = T_ph_material_amount, unit   = T_ph_material_unit))%>%
  mutate(C_ph_material_amount_unit= mapply(combine_material_amount_unit,C_ph_material_applied,C_ph_material_amount_unit1),
         T_ph_material_amount_unit= mapply(combine_material_amount_unit,T_ph_material_applied,T_ph_material_amount_unit1)
  )

# Quick checks
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
md.era.short.clean$C_irrig_subpractice <- gsub("...", "..", md.era.short.clean$C_irrig_subpractice, fixed = TRUE)
md.era.short.clean$T_irrig_subpractice <- gsub("...", "..", md.era.short.clean$T_irrig_subpractice, fixed = TRUE)

md.era.short.clean$C_irrig_water_unit <- gsub("mmweek", "mm/week", md.era.short.clean$C_irrig_water_unit, fixed = TRUE)
md.era.short.clean$T_irrig_water_unit <- gsub("mmweek", "mm/week", md.era.short.clean$T_irrig_water_unit, fixed = TRUE)

md.era.short.clean$C_irrig_water_amount <- gsub("; ", "..", md.era.short.clean$C_irrig_water_amount, fixed = TRUE)
md.era.short.clean$T_irrig_water_amount <- gsub("; ", "..", md.era.short.clean$T_irrig_water_amount, fixed = TRUE)


# Merge irrig_water_amount(irrig_water_unit) into irrig_water_amount_unit
md.era.short.clean <- md.era.short.clean%>%
  mutate(C_irrig_water_amount_unit= combine_amount_unit(amount = C_irrig_water_amount,unit   = C_irrig_water_unit),
         T_irrig_water_amount_unit= combine_amount_unit(amount = T_irrig_water_amount,unit   = T_irrig_water_unit)
         )

# Quick checks
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
## TO CHECK C_watharv_subpractice and T_watharv_subpractice
md.era.short.clean$C_watharv_subpractice <- gsub(", ", "..", md.era.short.clean$C_watharv_subpractice, fixed = TRUE)
md.era.short.clean$T_watharv_subpractice <- gsub(", ", "..", md.era.short.clean$T_watharv_subpractice, fixed = TRUE)

# Quick checks
sort(unique(md.era.short.clean$C_watharv_subpractice_raw))
sort(unique(md.era.short.clean$T_watharv_subpractice_raw))

sort(unique(md.era.short.clean$C_watharv_subpractice))
sort(unique(md.era.short.clean$T_watharv_subpractice))


#---harvest_practice----


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
md.era.short.clean$C_product <- gsub("\\*", "..", md.era.short.clean$C_product, fixed = TRUE)
md.era.short.clean$C_product <- gsub(" & ", "..", md.era.short.clean$C_product, fixed = TRUE)
md.era.short.clean$C_product <- gsub(", ", "..", md.era.short.clean$C_product, fixed = TRUE)
md.era.short.clean$C_product <- gsub("*", "..", md.era.short.clean$C_product, fixed = TRUE)

md.era.short.clean$T_product <- gsub("\\*", "..", md.era.short.clean$T_product, fixed = TRUE)
md.era.short.clean$T_product <- gsub(" & ", "..", md.era.short.clean$T_product, fixed = TRUE)
md.era.short.clean$T_product <- gsub(", ", "..", md.era.short.clean$T_product, fixed = TRUE)
md.era.short.clean$T_product <- gsub("*", "..", md.era.short.clean$T_product, fixed = TRUE)

md.era.short.clean$C_product_type <- gsub("**", "..", md.era.short.clean$C_product_type, fixed = TRUE)
md.era.short.clean$T_product_type <- gsub("**", "..", md.era.short.clean$T_product_type, fixed = TRUE)

md.era.short.clean$C_product_subtype <- gsub("**", "..", md.era.short.clean$C_product_subtype, fixed = TRUE)
md.era.short.clean$T_product_subtype <- gsub("**", "..", md.era.short.clean$T_product_subtype, fixed = TRUE)

md.era.short.clean$C_product_simple <- gsub("**", "..", md.era.short.clean$C_product_simple, fixed = TRUE)
md.era.short.clean$T_product_simple <- gsub("**", "..", md.era.short.clean$T_product_simple, fixed = TRUE)

md.era.short.clean$C_econ_inputs <- gsub("; ", "..", md.era.short.clean$C_econ_inputs)
md.era.short.clean$T_econ_inputs <- gsub("; ", "..", md.era.short.clean$T_econ_inputs)

# Quick checks
sort(unique(md.era.short.clean$C_product)) #MAKE A LIST OF MISSING PRODUCTS FROM 01_product_new
sort(unique(md.era.short.clean$T_product)) #MAKE A LIST OF MISSING PRODUCTS FROM 01_product_new

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
#---outcome----
#=========================
md.era.short.clean$out_subindicator <- gsub("Labor Cost" , "Labour Cost" , md.era.short.clean$out_subindicator, fixed = TRUE)

# Quick checks
sort(unique(md.era.short.clean$out_subindicator))
nrow(md.era.short.clean[md.era.short.clean$out_subindicator == "", ]) #15 rows with empty out_subindicator, is this ok?

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
md.era.short.clean$C_out_metric <- gsub("mean", "Mean", md.era.short.clean$C_out_metric, fixed = TRUE)
md.era.short.clean$T_out_metric <- gsub("mean", "Mean", md.era.short.clean$T_out_metric, fixed = TRUE)

md.era.short.clean$C_out_var_metric <- gsub("SE (Standard Error)Figure 2", "SE (Standard Error)", md.era.short.clean$C_out_var_metric, fixed = TRUE)
md.era.short.clean$T_out_var_metric <- gsub("SE (Standard Error)Figure 2", "SE (Standard Error)", md.era.short.clean$T_out_var_metric, fixed = TRUE)

md.era.short.clean$C_out_var_metric <- gsub("SE (Standard Error)'", "SE (Standard Error)", md.era.short.clean$C_out_var_metric, fixed = TRUE)
md.era.short.clean$T_out_var_metric <- gsub("SE (Standard Error)'", "SE (Standard Error)", md.era.short.clean$T_out_var_metric, fixed = TRUE)

md.era.short.clean<-md.era.short.clean%>%
  mutate(
    C_out_var_value=as.character(C_out_var_value),
    C_out_var_value=case_when(is.na(C_out_var_value)&C_out_var_metric=="Unspecified"~"Unspecified",TRUE~C_out_var_value),
    T_out_var_value=as.character(T_out_var_value),
    T_out_var_value=case_when(is.na(T_out_var_value)&T_out_var_metric=="Unspecified"~"Unspecified",TRUE~T_out_var_value))


# Quick checks
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
nrow(md.era.short.clean[md.era.short.clean$C_out_var_metric == "", ]) #182058
nrow(md.era.short.clean[md.era.short.clean$T_out_var_metric == "", ]) #0

sort(unique(md.era.short.clean$C_out_var_value))
sort(unique(md.era.short.clean$T_out_var_value))
na_empty_summary1["C_out_var_value", ]
nrow(md.era.short.clean[md.era.short.clean$C_out_var_value == "", ])
na_empty_summary1["T_out_var_value", ]
nrow(md.era.short.clean[md.era.short.clean$T_out_var_value == "", ])

md.era.short.clean %>%
  filter(!is.na(C_out_var_value), C_out_var_value != "", C_out_var_metric == "") %>%
  nrow() #88 there are 88 rows that have C_out_var_value but don't have C_out_var_metric

md.era.short.clean %>%
  filter(!is.na(T_out_var_value), T_out_var_value != "", T_out_var_metric == "") %>%
  nrow() #86 there are 86 rows that have C_out_var_value but don't have C_out_var_metric

md.era.short.clean %>%
  filter(!is.na(C_out_var_value), C_out_var_metric != "") %>%
  nrow() #49094 there are 49094 rows that have C_out_var_metric but don't have C_out_var_value

md.era.short.clean %>%
  filter(!is.na(T_out_var_value), T_out_var_metric != "") %>%
  nrow() #49183 there are 49183 rows that have T_out_var_metric but don't have T_out_var_value

sort(unique(md.era.short.clean$C_out_sample_size))
sort(unique(md.era.short.clean$T_out_sample_size))
na_empty_summary1["C_out_sample_size", ]
na_empty_summary1["T_out_sample_size", ]

sort(unique(md.era.short.clean$C_data_location))
sort(unique(md.era.short.clean$T_data_location))

#=========================
#---outcome_time----
#=========================
# Quick checks
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

md.era.short.clean <- md.era.short.clean %>%
  mutate(country_ISO = map_chr(str_split(str_squish(country), "\\.\\."), \(x) {
    tokens <- str_squish(x)
    out <- unname(lookup.country.iso[tokens])
    if (any(is.na(out))) return(NA_character_)
    #out[is.na(out)] <- tokens[is.na(out)]  # keep original if no match
    paste(out, collapse = "..")
  }))

sort(unique(md.era.short.clean$country))
sort(unique(md.era.short.clean$country_ISO))

#Remove duplicate country and country_ISO
md.era.short.clean <- md.era.short.clean %>%
  mutate(
    country = map_chr(str_split(str_squish(country), "\\.\\."), \(x) paste(unique(str_squish(x)), collapse = "..")),
    country_ISO = map_chr(str_split(str_squish(country_ISO), "\\.\\."), \(x) paste(unique(str_squish(x)), collapse = ".."))
  )

sort(unique(md.era.short.clean$country))
sort(unique(md.era.short.clean$country_ISO))

#=========================
#---product_outcome----
#=========================
#I NEED TO DO THIS
md.era.short.clean<-md.era.short.clean

#--- lookup vector: names = product_simple, values = ISO_3166_1_Alpha_3
lookup.country.iso <- fomd01.countries %>%
  transmute(
    country = str_squish(Country),
    country.iso    = str_squish(ISO_3166_1_Alpha_3)
  ) %>%
  distinct() %>%
  deframe()


sort(unique(md.era.short.clean$country))
sort(unique(md.era.short.clean$country_ISO))

#=========================
#---outcome----
#=========================
#--- lookup vector: names = out_subindicator, values = out_indicator
lookup.indicator <- fomd01.outcomes %>%
  transmute(
    out_subindicator= str_squish(subindicator),
    out_indicator    = str_squish(indicator)
  ) %>%
  distinct() %>%
  deframe()

sort(unique(md.era.short.clean$out_subindicator))
sort(unique(md.era.short.clean$out_indicator))

md.era.short.clean <- md.era.short.clean %>%
  mutate(out_indicator = map_chr(str_split(str_squish(out_subindicator), "\\.\\."), \(x) {
    tokens <- str_squish(x)
    out <- unname(lookup.indicator[tokens])
    if (any(is.na(out))) return(NA_character_)
    paste(out, collapse = "..")
  }))

sort(unique(md.era.short.clean$out_subindicator))
sort(unique(md.era.short.clean$out_indicator))

#--- lookup vector: names = out_subindicator, values = out_subpillar
lookup.subpillar <- fomd01.outcomes %>%
  transmute(
    out_subindicator= str_squish(subindicator),
    out_subpillar    = str_squish(subpillar)
  ) %>%
  distinct() %>%
  deframe()

sort(unique(md.era.short.clean$out_subindicator))
sort(unique(md.era.short.clean$out_subpillar))

md.era.short.clean <- md.era.short.clean %>%
  mutate(out_subpillar = map_chr(str_split(str_squish(out_subindicator), "\\.\\."), \(x) {
    tokens <- str_squish(x)
    out <- unname(lookup.subpillar[tokens])
    if (any(is.na(out))) return(NA_character_)
    #out[is.na(out)] <- tokens[is.na(out)]  # keep original if no match
    paste(out, collapse = "..")
  }))


prueba<- md.era.short.clean%>%
  filter(is.na(out_subpillar))
sort(unique(md.era.short.clean$out_subindicator))
sort(unique(md.era.short.clean$out_subpillar))
sort(unique(md.era.short.clean$out_subindicator[md.era.short.clean$out_subpillar==""]))
sort(unique(md.era.short.clean$out_subindicator[is.na(md.era.short.clean$out_subpillar)]))


#--- lookup vector: names = out_subindicator, values = out_pillar
lookup.pillar <- fomd01.outcomes %>%
  transmute(
    out_subindicator= str_squish(subindicator),
    out_pillar    = str_squish(pillar)
  ) %>%
  distinct() %>%
  deframe()

sort(unique(md.era.short.clean$out_subindicator))
sort(unique(md.era.short.clean$out_pillar))

md.era.short.clean <- md.era.short.clean %>%
  mutate(out_pillar = map_chr(str_split(str_squish(out_subindicator), "\\.\\."), \(x) {
    tokens <- str_squish(x)
    out <- unname(lookup.pillar[tokens])
    if (any(is.na(out))) return(NA_character_)
    #out[is.na(out)] <- tokens[is.na(out)]  # keep original if no match
    paste(out, collapse = "..")
  }))

sort(unique(md.era.short.clean$out_subindicator))
sort(unique(md.era.short.clean$out_pillar))
sort(unique(md.era.short.clean$out_subindicator[md.era.short.clean$out_pillar==""]))
sort(unique(md.era.short.clean$out_subindicator[is.na(md.era.short.clean$out_pillar)]))






n <- nrow(md.era.short)

na_empty_summary1 <- data.frame(
  na_count          = colSums(is.na(md.era.short)),
  empty_count       = colSums(md.era.short == "", na.rm = TRUE),
  total_missing     = colSums(is.na(md.era.short)) + colSums(md.era.short == "", na.rm = TRUE),
  total_missing_pct = round((colSums(is.na(md.era.short)) + colSums(md.era.short == "", na.rm = TRUE)) / n * 100, 2)
)

print(na_empty_summary1)