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


#==========================================================
# Read datasets
#==========================================================
#---01_FOMD_ontologies
fomd01.outcomes<-fomd01.outcomes%>%
  filter(!is.na(subindicator) )

#---04_FOMD_screening
fomd04<-read_xlsx(file.path(path.metadata.structure,"04_FOMD_screening.xlsx"), sheet = "04_FOMD_screening")%>%
  filter(ss_id=="MD_Rosen_24_Effec_Sc")%>%
  filter(status =="I")
length(unique(fomd04$study_id))#2106

#---ERA metadata short
#md.era.short <- read.csv(file.path(path.era, "ERA_data_short_v6.csv"))
#md.era.short <- read.csv(file.path(path.era, "ERA_data_short_v12.csv"))
#md.era.short <- read.csv(file.path(path.era, "ERA_data_short_v16.csv"))
#md.era.short <- read.csv(file.path(path.era, "ERA_data_short_v22.csv"))
md.era.short <- read.csv(file.path(path.era, "ERA_data_short_v24.csv"))

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
length(unique(md.era.short.clean$study_id)) # 1811 studies
length(unique(md.era.short.clean$effect_size_id))  #232257 rows
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
sort(unique(md.era.short.clean$site_id[md.era.short.clean$site_longitude==""])) #760
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
sort(unique(md.era.short.clean$C_crop_diversity))

crop_fixes <- c(
  "\\bBalanites aegyptica\\b"              = "Balanites aegyptiaca",
  "\\bBlack [Oo]ats?\\b"                  = "Black Oats",   # catches "Black oat", "Black oats"
  "\\bCommon [Vv]etch\\b"                 = "Common Vetch",
  "\\bCongo Gra\\b"                       = "Congo Grass",
  "\\bCrotalaria spectabili\\b"           = "Crotalaria spectabilis",
  "\\bDesho Gra\\b"                       = "Desho Grass",
  # FIX 1: Use a lookahead so the hyphen is NOT consumed / treated as separator
  "\\bFicus vallis-choudae\\b"            = "Ficus vallis choudae",  # keep as-is (no-op anchor)
  "\\bFicus vallis\\b(?!-choudae)"        = "Ficus vallis choudae",  # only fix incomplete form
  
  "\\bFinger [Mm]illet\\b"               = "Finger Millet",
  "\\bGuinea Gra\\b"                     = "Guinea Grass",
  "\\bHibiscu\\b"                        = "Hibiscus",
  "\\bJute [Mm]allow\\b"                 = "Jute Mallow",   # catches "Jute mallow"
  "\\bKikuyu Gra\\b"                     = "Kikuyu Grass",
  "\\bNapier Gra\\b"                     = "Napier Grass",
  "\\bOat\\b"                            = "Oats",
  "\\bPalisade Gra\\b"                   = "Palisade Grass",
  "\\bPearl [Mm]illet\\b"               = "Pearl Millet",   # catches "Pearl millet" in compounds
  "\\bpersea americana\\b"              = "Persea americana",
  "\\bPiliostigma reticulata\\b"        = "Piliostigma reticulatum",
  "\\b[Pp]urple [Vv]etch\\b"           = "Purple Vetch",
  "\\bRuzigra\\b"                       = "Ruzigrass",
  "\\bSudan [Gg]ra\\b"                 = "Sudan Grass",    # standardise capitalisation
  "\\bSmutsfinger Gra\\b"              = "Smutsfinger Grass",
  "\\bTurkey [Bb]erry\\b"             = "Turkey Berry",    # NEW
  "\\bUnspecified Fodder Gra\\b"       = "Unspecified Fodder Grass",
  "\\b[Uu]nspecified [Ll]egume\\b"    = "Unspecified Legume",
  "\\bVetiver Gra\\b"                  = "Vetiver Grass"
)

md.era.short.clean <- md.era.short.clean %>%
  mutate(
    C_crop_density = ifelse(C_crop_density == "NULL" | is.na(C_crop_density), "Unspecified(Unspecified)", C_crop_density),
    T_crop_density = ifelse(T_crop_density == "NULL" | is.na(T_crop_density), "Unspecified(Unspecified)", T_crop_density)
  )
crop_cols <- c("C_crop_diversity", "T_crop_diversity",
               "C_crop_variety","T_crop_variety",
               "C_crop_density","T_crop_density",
               "C_tree_diversity", "T_tree_diversity",
               "C_tree_density","T_tree_density")


md.era.short.clean[crop_cols] <- lapply(
  md.era.short.clean[crop_cols],
  \(x) gsub("Gliricida sepium", "Gliricidia sepium", x, fixed = TRUE))
md.era.short.clean[crop_cols] <- lapply(
  md.era.short.clean[crop_cols],
  \(x) gsub("Glyricidia sepium", "Gliricidia sepium", x, fixed = TRUE))

md.era.short.clean[crop_cols] <- lapply(
  md.era.short.clean[crop_cols],
  \(x) gsub("Gliricidia sp", "Gliricidia sp.", x, fixed = TRUE))

md.era.short.clean[crop_cols] <- lapply(
  md.era.short.clean[crop_cols],
  \(x) gsub("Gliricidia sp..", "Gliricidia sp.", x, fixed = TRUE))

md.era.short.clean[crop_cols] <- lapply(
  md.era.short.clean[crop_cols],
  \(x) gsub("Patula Pine", "Pinus patula", x, fixed = TRUE))

### Remove extra * from C_crop_variety and T_crop_variety
md.era.short.clean <- md.era.short.clean%>%
  mutate(
    # Clean NULL strings in density columns first
    C_crop_density = ifelse(C_crop_density == "NULL" | is.na(C_crop_density), "Unspecified(Unspecified)", C_crop_density),
    T_crop_density = ifelse(T_crop_density == "NULL" | is.na(T_crop_density), "Unspecified(Unspecified)", T_crop_density),
    
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
  if (is.na(diversity) || diversity == "" || diversity == "NULL") return("")
  
  # Helper to clean individual density values
  clean_density <- function(d) {
    if (is.na(d) || d == "" || d == "NULL" || d == "NA") return("Unspecified(Unspecified)")
    return(d)
  }
  
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
    paste0(crop, "[", clean_density(dens), "]")
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

sort(unique(md.era.short.clean$T_crop_density))

### Remove animals from C_crop_diversity and T_crop_diversity
sort(unique(md.era.short.clean$C_animal_diversity[md.era.short.clean$C_crop_diversity=="Cattle-Camel-Small Ruminants"])) #"Cattle*Camel*Small Ruminants"
sort(unique(md.era.short.clean$T_animal_diversity[md.era.short.clean$T_crop_diversity=="Cattle-Camel-Small Ruminants"])) #"Cattle*Camel*Small Ruminants"

md.era.short.clean <- md.era.short.clean%>%
  mutate(
    C_crop_density=case_when(C_crop_diversity=="Cattle-Camel-Small Ruminants"~"",TRUE~C_crop_density),
    T_crop_density=case_when(T_crop_diversity=="Cattle-Camel-Small Ruminants"~"",TRUE~T_crop_density),
    
    C_crop_variety=case_when(C_crop_diversity=="Cattle-Camel-Small Ruminants"~"",TRUE~C_crop_variety),
    T_crop_variety=case_when(T_crop_diversity=="Cattle-Camel-Small Ruminants"~"",TRUE~T_crop_variety),
    
    C_crop_diversity=case_when(C_crop_diversity=="Cattle-Camel-Small Ruminants"~"",TRUE~C_crop_diversity),
    T_crop_diversity=case_when(T_crop_diversity=="Cattle-Camel-Small Ruminants"~"",TRUE~T_crop_diversity))

### Remove trees from C_crop_diversity and T_crop_diversity
# Remove NAs first
tree_species <- sort(unique(na.omit(fomd01.trees$tree.latin.name)))
tree_species
# Escape special regex characters safely
tree_species_escaped <- sapply(tree_species, function(x) str_replace_all(x, "([\\.\\(\\)\\[\\]\\^\\$\\*\\+\\?\\|])", "\\\\\\1"))

# Identify rows where C_crop_diversity contains at least one tree species
pattern <- paste(tree_species_escaped, collapse = "|")

# Copy C_crop_diversity to C_tree_diversity where both conditions are met
md.era.short.clean$C_tree_diversity[grepl(pattern, md.era.short.clean$C_crop_diversity, perl = TRUE) &
                                      (is.na(md.era.short.clean$C_tree_diversity) | md.era.short.clean$C_tree_diversity == "")] <- 
  md.era.short.clean$C_crop_diversity[grepl(pattern, md.era.short.clean$C_crop_diversity, perl = TRUE) & 
                                        (is.na(md.era.short.clean$C_tree_diversity) | md.era.short.clean$C_tree_diversity == "")]

# Copy T_crop_diversity to T_tree_diversity where both conditions are met
md.era.short.clean$T_tree_diversity[grepl(pattern, md.era.short.clean$T_crop_diversity, perl = TRUE) &
                                      (is.na(md.era.short.clean$T_tree_diversity) | md.era.short.clean$T_tree_diversity == "")] <- 
  md.era.short.clean$T_crop_diversity[grepl(pattern, md.era.short.clean$T_crop_diversity, perl = TRUE) & 
                                        (is.na(md.era.short.clean$T_tree_diversity) | md.era.short.clean$T_tree_diversity == "")]


#md.era.short.clean1<-md.era.short.clean%>%
 # filter(doi=="10.1007/s10457-019-00405-4")%>%
  #mutate(across(c("C_tree_diversity","C_tree_density"),
   #             case_when(
    #              doi=="10.1007/s10457-019-00405-4" )))

### ARREGLAR MANUALMENTE
"10.1007/s10457-019-00405-4"
"10.1016/j.agrformet.2018.03.026"

# Build pattern and cleaning function
remove_trees_diversity <- function(x) {
  if (is.na(x) || x == "") return(x)
  
  pattern <- paste(tree_species_escaped, collapse = "|")
  
  # Extract tokens and the separators between them
  tokens <- character(0)
  seps   <- character(0)
  remaining <- x
  
  while (nchar(remaining) > 0) {
    m <- regexpr("[-/]", remaining)
    if (m == -1) {
      tokens <- c(tokens, trimws(remaining))
      break
    }
    tokens    <- c(tokens, trimws(substr(remaining, 1, m - 1)))
    seps      <- c(seps,   substr(remaining, m, m))       # keep "/" or "-"
    remaining <- substr(remaining, m + 1, nchar(remaining))
  }
  
  # Decide which tokens to keep
  keep <- !grepl(paste0("^(", pattern, ")$"), tokens, perl = TRUE)
  
  # Rebuild, preserving only the separators between kept tokens
  kept_tokens <- tokens[keep]
  kept_seps   <- seps[keep[-length(keep)]]   # one fewer sep than tokens
  
  if (length(kept_tokens) == 0) return("")
  
  result <- kept_tokens[1]
  if (length(kept_seps) > 0) {
    for (i in seq_along(kept_seps)) {
      result <- paste0(result, kept_seps[i], kept_tokens[i + 1])
    }
  }
  
  return(trimws(result))
}

# Apply
system.time({
md.era.short.clean$C_crop_diversity <- sapply(md.era.short.clean$C_crop_diversity,remove_trees_diversity)
md.era.short.clean$T_crop_diversity <- sapply(md.era.short.clean$T_crop_diversity,remove_trees_diversity)
})

# Remove trees from C_crop_variety and T_crop_variety
remove_trees_variety <- function(x) {
  if (is.na(x) || x == "") return(x)
  
  split_outside_parens <- function(x) {
    chars <- strsplit(x, "")[[1]]
    depth <- 0
    positions <- c()
    seps <- c()
    for (i in seq_along(chars)) {
      if (chars[i] == "(") depth <- depth + 1
      else if (chars[i] == ")") depth <- depth - 1
      else if (chars[i] %in% c("/", "-") && depth == 0) {
        positions <- c(positions, i)
        seps <- c(seps, chars[i])
      }
    }
    if (length(positions) == 0) return(list(parts = trimws(x), seps = character(0)))
    starts <- c(1, positions + 1)
    ends   <- c(positions - 1, nchar(x))
    parts  <- trimws(substring(x, starts, ends))
    list(parts = parts, seps = seps)
  }
  
  result <- split_outside_parens(x)
  parts  <- result$parts
  seps   <- result$seps
  
  # Single grepl per part using the pre-built pattern
  is_tree <- grepl(paste0("^(", pattern, ")"), parts, perl = TRUE)
  
  keep_parts <- parts[!is_tree]
  
  if (length(keep_parts) == 0) return("")
  if (length(keep_parts) == length(parts)) return(x)  # nothing removed, return original
  
  # Rebuild with correct separators
  kept_idx <- which(!is_tree)
  out <- keep_parts[1]
  if (length(keep_parts) > 1) {
    for (i in 2:length(keep_parts)) {
      sep <- if ((kept_idx[i] - 1) <= length(seps)) seps[kept_idx[i] - 1] else "-"
      out <- paste0(out, sep, keep_parts[i])
    }
  }
  
  return(out)
}

system.time({
  md.era.short.clean$C_crop_variety <- sapply(md.era.short.clean$C_crop_variety, remove_trees_variety)
  md.era.short.clean$T_crop_variety <- sapply(md.era.short.clean$T_crop_variety, remove_trees_variety)
})

### Remove trees from C_crop_density and T_crop_density
remove_trees_density <- function(x) {
  if (is.na(x) || x == "") return(x)
  
  # Split on / or - outside brackets (same logic as before)
  split_outside_brackets <- function(x, delimiters = c("/", "-")) {
    chars <- strsplit(x, "")[[1]]
    depth <- 0
    positions <- c()
    seps <- c()
    for (i in seq_along(chars)) {
      if (chars[i] == "[") depth <- depth + 1
      else if (chars[i] == "]") depth <- depth - 1
      else if (chars[i] %in% delimiters && depth == 0) {
        positions <- c(positions, i)
        seps <- c(seps, chars[i])
      }
    }
    if (length(positions) == 0) return(list(parts = trimws(x), seps = character(0)))
    starts <- c(1, positions + 1)
    ends   <- c(positions - 1, nchar(x))
    parts  <- trimws(substring(x, starts, ends))
    list(parts = parts, seps = seps)
  }
  
  result <- split_outside_brackets(x)
  parts  <- result$parts
  seps   <- result$seps
  
  # Extract the crop name (everything before the first "[")
  crop_names <- sub("\\[.*$", "", parts)
  
  # Check if each crop name matches a tree species
  is_tree <- grepl(paste0("^(", pattern, ")"), crop_names, perl = TRUE)
  
  keep_parts <- parts[!is_tree]
  
  if (length(keep_parts) == 0) return("")
  if (length(keep_parts) == length(parts)) return(x)
  
  # Rebuild with correct separators
  kept_idx <- which(!is_tree)
  out <- keep_parts[1]
  if (length(keep_parts) > 1) {
    for (i in 2:length(keep_parts)) {
      sep <- if ((kept_idx[i] - 1) <= length(seps)) seps[kept_idx[i] - 1] else "-"
      out <- paste0(out, sep, keep_parts[i])
    }
  }
  
  return(out)
}

# Copy C_crop_density to C_tree_density where both conditions are met
md.era.short.clean$C_tree_density[grepl(pattern, md.era.short.clean$C_crop_diversity, perl = TRUE) &
                                    (is.na(md.era.short.clean$C_tree_density) | md.era.short.clean$C_tree_density == "")] <- 
  md.era.short.clean$C_crop_density[grepl(pattern, md.era.short.clean$C_crop_diversity, perl = TRUE) &
                                      (is.na(md.era.short.clean$C_tree_density) | md.era.short.clean$C_tree_density == "")]

# Copy T_crop_diversity to T_tree_diversity where both conditions are met
md.era.short.clean$T_tree_density[grepl(pattern, md.era.short.clean$T_crop_diversity, perl = TRUE) &
                                    (is.na(md.era.short.clean$T_tree_density) | 
                                       md.era.short.clean$T_tree_density == "")] <- 
  md.era.short.clean$T_crop_density[grepl(pattern, md.era.short.clean$T_crop_diversity, perl = TRUE) &
                                      (is.na(md.era.short.clean$T_tree_density) | 
                                         md.era.short.clean$T_tree_density == "")]

## Arreglar MANUALMENTE

"10.1007/s10457-019-00405-4"
"10.1016/j.agrformet.2018.03.026"

# Apply
md.era.short.clean$C_crop_density <- sapply(md.era.short.clean$C_crop_density, remove_trees_density)
md.era.short.clean$T_crop_density <- sapply(md.era.short.clean$T_crop_density, remove_trees_density)

# Apply all fixes to any set of columns
apply_crop_fixes <- function(x, fixes) {
  for (pattern in names(fixes)) {
    x <- str_replace_all(x, regex(pattern), fixes[[pattern]])
  }
  x
}

crop_cols <- c("C_crop_diversity", "T_crop_diversity",
               "C_crop_variety","T_crop_variety",
               "C_crop_density","T_crop_density",
               "C_tree_diversity", "T_tree_diversity",
               "C_tree_density","T_tree_density")

md.era.short.clean <- md.era.short.clean %>%
  mutate(across(all_of(crop_cols), ~ apply_crop_fixes(., crop_fixes)))


md.era.short.clean[crop_cols] <- lapply(
  md.era.short.clean[crop_cols],
  \(x) gsub("Gliricida sepium", "Gliricidia sepium", x, fixed = TRUE))

md.era.short.clean[crop_cols] <- lapply(
  md.era.short.clean[crop_cols],
  \(x) gsub("Glyricidia sepium", "Gliricidia sepium", x, fixed = TRUE))

md.era.short.clean[c("C_crop_variety", "T_crop_variety")] <- lapply(
  md.era.short.clean[c("C_crop_variety", "T_crop_variety")],
  \(x) gsub("(NA)", "(Unspecified)", x, fixed = TRUE))
 
md.era.short.clean[c("C_crop_diversity", "T_crop_diversity")] <- lapply(
  md.era.short.clean[c("C_crop_diversity", "T_crop_diversity")],
  \(x) gsub("-NA", "", x, fixed = TRUE))

# Quick checks
sort(unique(md.era.short.clean$C_crop_diversity))
sort(unique(md.era.short.clean$T_crop_diversity))

## List of missing crops from 01_product_new to pass to Lolita
unique_crops_diversity <- rbind(
  data.frame(crop_diversity = md.era.short.clean %>%
               filter(C_crop_diversity != "") %>%
               pull(C_crop_diversity) %>%
               str_split("[/\\-]") %>%
               unlist() %>%
               str_trim()),
  data.frame(crop_diversity = md.era.short.clean %>%
               filter(T_crop_diversity != "") %>%
               pull(T_crop_diversity) %>%
               str_split("[/\\-]") %>%
               unlist() %>%
               str_trim())) %>%
  distinct(crop_diversity) %>%
  arrange(crop_diversity)%>%
  left_join(fomd01.product.new%>%
              filter(!is.na(Product.Simple))%>%
              distinct(Product.Type,Product.Simple,SPAM.Food.Group,FAO.Food.Group),
            by=c("crop_diversity"="Product.Simple"))%>%
  filter(is.na(Product.Type))

sort(unique(unique_crops_diversity$crop_diversity)) #115
#readr::write_csv(unique_crops, paste0(path.metadata, "/04.added_to_06_FOMD_metadata_original_long/missing_crops_01_products_new.csv"))

sort(unique(md.era.short.clean$C_crop_variety))
sort(unique(md.era.short.clean$T_crop_variety))

extract_variety_names <- function(x) {
  x %>%
    na.omit() %>%
    .[. != ""] %>%
    strsplit("(?<=[)])[/\\-](?=[A-Z])", perl = TRUE) %>%
    unlist() %>%
    trimws() %>%
    regmatches(., regexpr("^[^(]+", .)) %>%
    trimws() %>%
    unique() %>%
    sort()
}

unique_crops_variety <- data.frame(
  crop_variety = unique(c(
    extract_variety_names(md.era.short.clean$C_crop_variety),
    extract_variety_names(md.era.short.clean$T_crop_variety)
  ))) %>%
  arrange(crop_variety)
sort(unique(unique_crops_variety$crop_variety))

sort(unique(md.era.short.clean$C_crop_density))
sort(unique(md.era.short.clean$T_crop_density))

extract_crop_names <- function(x) {
  x %>%
    na.omit() %>%
    .[. != ""] %>%
    # Split on - or / that separate crop entries (i.e., followed by an uppercase letter)
    strsplit("(?<=[)])[/\\-](?=[A-Z])", perl = TRUE) %>%
    unlist() %>%
    trimws() %>%
    # Extract crop name: everything before the first [
    regmatches(., regexpr("^[^\\[]+", .)) %>%
    trimws() %>%
    unique() %>%
    sort()
}

unique_crops_density <- data.frame(
  crop_name = unique(c(
    extract_crop_names(md.era.short.clean$C_crop_density),
    extract_crop_names(md.era.short.clean$T_crop_density)))) %>%
  arrange(crop_name)

sort(unique(unique_crops_density$crop_name))

#=========================
#---commodity_tree----
#=========================
#md.era.short.clean1 <- md.era.short.clean
sort(unique(md.era.short.clean$T_tree_diversity))
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
    C_tree_density= mapply(create_density,C_tree_diversity,C_tree_density),
    T_tree_density = mapply(create_density,T_tree_diversity,T_tree_density))

sort(unique(md.era.short.clean$T_tree_diversity))


tree_cols <- c("C_tree_diversity", "T_tree_diversity",
               "C_tree_density","T_tree_density")

md.era.short.clean <- md.era.short.clean %>%
  mutate(across(all_of(tree_cols), ~ apply_crop_fixes(., crop_fixes)))

sort(unique(md.era.short.clean$T_tree_diversity))

md.era.short.clean[tree_cols] <- lapply(
  md.era.short.clean[tree_cols],
  \(x) gsub("Gliricidia", "Gliricidia sp.", x, fixed = TRUE))

md.era.short.clean[tree_cols] <- lapply(
  md.era.short.clean[tree_cols],
  \(x) gsub("Gliricidia sp. sepium", "Gliricidia sepium", x, fixed = TRUE))

md.era.short.clean[tree_cols] <- lapply(
  md.era.short.clean[tree_cols],
  \(x) gsub("Gliricidia sp. sp.", "Gliricidia sp.", x, fixed = TRUE))

md.era.short.clean[tree_cols] <- lapply(
  md.era.short.clean[tree_cols],
  \(x) gsub("Ficus\u00A0vallis-choudae", "Ficus vallis choudae", x, fixed = TRUE))

sort(unique(md.era.short.clean$T_tree_diversity))

### Remove crops from C_tree_diversity and T_tree_diversity
## List crops from C_tree_diversity and T_tree_diversity
crop_species <- rbind(
  data.frame(tree_diversity = md.era.short.clean %>%
               filter(C_tree_diversity != "") %>%
               pull(C_tree_diversity) %>%
               str_split("[/\\-]") %>%
               unlist() %>%
               str_trim()),
  data.frame(tree_diversity = md.era.short.clean %>%
               filter(T_tree_diversity != "") %>%
               pull(T_tree_diversity) %>%
               str_split("[/\\-]") %>%
               unlist() %>%
               str_trim())) %>%
  distinct(tree_diversity) %>%
  arrange(tree_diversity)%>%
  left_join(fomd01.trees%>%filter(!is.na(tree.latin.name)),
            by=c("tree_diversity"="tree.latin.name"))%>%
  filter(is.na(Tree.Nfix))%>%
  select(tree_diversity)%>%
  left_join(fomd01.product.new,by=c("tree_diversity"="Product.Simple"))
  
sort(unique(crop_species$tree_diversity))
crop_species <- unique(na.omit(crop_species$tree_diversity))
  
# Escape special regex characters safely
crop_species_escaped <- sapply(crop_species, function(x) str_replace_all(x, "([\\.\\(\\)\\[\\]\\^\\$\\*\\+\\?\\|])", "\\\\\\1"))
  
# Identify rows where C_crop_diversity contains at least one tree species
pattern <- paste(crop_species_escaped, collapse = "|")
  
# Build pattern and cleaning function
remove_crop_diversity <- function(x) {
  if (is.na(x) || x == "") return(x)
  
  pattern <- paste(crop_species_escaped, collapse = "|")
  
  # Extract tokens and the separators between them
  tokens <- character(0)
  seps   <- character(0)
  remaining <- x
  
  while (nchar(remaining) > 0) {
    m <- regexpr("[-/]", remaining)
    if (m == -1) {
      tokens <- c(tokens, trimws(remaining))
      break
    }
    tokens    <- c(tokens, trimws(substr(remaining, 1, m - 1)))
    seps      <- c(seps,   substr(remaining, m, m))       # keep "/" or "-"
    remaining <- substr(remaining, m + 1, nchar(remaining))
  }
  
  # Decide which tokens to keep
  keep <- !grepl(paste0("^(", pattern, ")$"), tokens, perl = TRUE)
  
  # Rebuild, preserving only the separators between kept tokens
  kept_tokens <- tokens[keep]
  kept_seps   <- seps[keep[-length(keep)]]   # one fewer sep than tokens
  
  if (length(kept_tokens) == 0) return("")
  
  result <- kept_tokens[1]
  if (length(kept_seps) > 0) {
    for (i in seq_along(kept_seps)) {
      result <- paste0(result, kept_seps[i], kept_tokens[i + 1])
    }
  }
  
  return(trimws(result))
}

# Apply
system.time({
  md.era.short.clean$C_tree_diversity <- sapply(md.era.short.clean$C_tree_diversity,remove_crop_diversity)
  md.era.short.clean$T_tree_diversity <- sapply(md.era.short.clean$T_tree_diversity,remove_crop_diversity)
  })  

tree_name_fixes <- c(
  "Acacia decurren"            = "Acacia decurrens",
  "Acacia tortili"             = "Acacia tortilis",
  "Artocarpus heterophyllu"    = "Artocarpus heterophyllus",
  "Calliandra calothyrsu"      = "Calliandra calothyrsus",
  "Croton macrostachyu"        = "Croton macrostachyus",
  "Eucalyptus globulu"         = "Eucalyptus globulus",
  "Eucalyptus urograndi"       = "Eucalyptus urograndis",
  "Fernandoa madagascariensi"  = "Fernandoa madagascariensis",
  "Guiera senegalensi"="Guiera senegalensis",

  
  "Jatropha curca"             = "Jatropha curcas",
  "Khaya ivorensi"             = "Khaya ivorensis",
  "Senna spectabili"           = "Senna spectabilis",
  "Tectona grandi"             = "Tectona grandis",
  "Terminalia ivoresensi"      = "Terminalia ivorensis"
)

# Apply to your dataframe columns
#md.era.short.clean <- md.era.short.clean %>%
#  mutate(
#   C_tree_diversity = str_replace_all(C_tree_diversity, regex(paste(names(tree_name_fixes), collapse="|"), ignore_case = TRUE), 
#                                      function(m) tree_name_fixes[str_to_lower(m)]),
#   T_tree_diversity = str_replace_all(T_tree_diversity, regex(paste(names(tree_name_fixes), collapse="|"), ignore_case = TRUE), 
#                                      function(m) tree_name_fixes[str_to_lower(m)])
# )
  
md.era.short.clean[c("C_tree_diversity", "T_tree_diversity")] <- lapply(
  md.era.short.clean[c("C_tree_diversity", "T_tree_diversity")],
  \(x) gsub("-NA", "", x, fixed = TRUE))

md.era.short.clean[c("C_tree_diversity", "T_tree_diversity")] <- lapply(
  md.era.short.clean[c("C_tree_diversity", "T_tree_diversity")],
  \(x) gsub("/NA", "", x, fixed = TRUE))

md.era.short.clean[c("C_tree_density", "T_tree_density")] <- lapply(
  md.era.short.clean[c("C_tree_density", "T_tree_density")],
  \(x) gsub("-NULL", "", x, fixed = TRUE))

md.era.short.clean[c("C_tree_density", "T_tree_density")] <- lapply(
  md.era.short.clean[c("C_tree_density", "T_tree_density")],
  \(x) gsub("/NULL", "", x, fixed = TRUE))

md.era.short.clean[c("C_tree_density", "T_tree_density")] <- lapply(
  md.era.short.clean[c("C_tree_density", "T_tree_density")],
  \(x) gsub("NULL", "", x, fixed = TRUE))

  

# Quick checks
sort(unique(md.era.short.clean$C_tree_diversity))
sort(unique(md.era.short.clean$T_tree_diversity))

unique_trees_diversity <- rbind(
  data.frame(tree_diversity = md.era.short.clean %>%
               filter(C_tree_diversity != "") %>%
               pull(C_tree_diversity) %>%
               str_split("[/\\-]") %>%
               unlist() %>%
               str_trim()),
  data.frame(tree_diversity = md.era.short.clean %>%
               filter(T_tree_diversity != "") %>%
               pull(T_tree_diversity) %>%
               str_split("[/\\-]") %>%
               unlist() %>%
               str_trim())) %>%
  distinct(tree_diversity) %>%
  arrange(tree_diversity)%>%
  left_join(fomd01.trees%>%
              filter(!is.na(tree.latin.name)),
            by=c("tree_diversity"="tree.latin.name"))
filter(is.na(Tree.Nfix))
sort(unique(unique_trees_diversity$tree_diversity))


sort(unique(md.era.short.clean1$C_tree_density))
sort(unique(md.era.short.clean1$T_tree_density))


#=========================
#---commodity_animal----
#=========================
## TO CHECK: density and diversity (there are tree names in diversity)

md.era.short.clean <- md.era.short.clean%>%
  mutate(
    C_animal_diversity = gsub("\\*+", "**", C_animal_diversity),
    T_animal_diversity = gsub("\\*+", "**", T_animal_diversity),
    C_animal_breed = gsub("\\*+", "**", C_animal_breed),
    T_animal_breed = gsub("\\*+", "**", T_animal_breed),
    C_animal_diversity = gsub("Gliricidia sepium", "", C_animal_diversity, fixed = TRUE),
    C_animal_diversity = gsub("Gliricidia sp.", "", C_animal_diversity, fixed = TRUE),
    
    
    across(c(C_animal_diversity, T_animal_diversity), ~ gsub("Durum Wheat**Wheat", "", .x, fixed = TRUE)),
    across(c(C_animal_diversity, T_animal_diversity), ~ gsub("Grevillea robusta", "", .x, fixed = TRUE)),
    
    C_animal_diversity = gsub("Jute mallow", "", C_animal_diversity, fixed = TRUE),

    across(c(C_animal_diversity, T_animal_diversity), ~ gsub("Seed", "", .x, fixed = TRUE)),
    across(c(C_animal_diversity, T_animal_diversity), ~ gsub("Unknown Plant", "", .x, fixed = TRUE)),
    across(c(C_animal_diversity, T_animal_diversity), ~ gsub("Zucchini", "", .x, fixed = TRUE))
    )


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
# TO CHECK: #Poner methods en methods, y subpractices en subpractices
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
md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_intercrop_subpractice", "T_intercrop_subpractice"),
  pattern = "&",replacement = "and") # Apply "&" -> "and" substitution

md.era.short.clean <- apply_replace_in_cols(md.era.short.clean,
  cols = c("C_intercrop_subpractice", "T_intercrop_subpractice"),
  pattern = "Alleycropping (Mixed)",replacement = "Alleycropping (N fixing and Non N fixing)") ## Apply "Alleycropping (Mixed)" -> "Alleycropping (N fixing and Non N fixing)" substitution

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
## TO CHECK: NEED TO FIX "C: Other Time Sequence_vs_T: Other Time Sequence"
# CHECK PAPER BY PAPER IF THIS IS OK OR NOT
md.era.short.clean <- apply_replace_in_cols(md.era.short.clean,
  cols = c("C_crop_seq_residues_fate", "T_crop_seq_residues_fate"),
  pattern = "; ",replacement = "..") # Apply ";" -> ".." substitution

md.era.short.clean <- apply_replace_in_cols(md.era.short.clean,
  cols = c("C_crop_seq_residues_fate", "T_crop_seq_residues_fate"),
  pattern = "NA",replacement = "Unspecified") # Apply "NA" -> "Unspecified" substitution

md.era.short.clean <- apply_replace_in_cols(md.era.short.clean,
  cols = c("C_crop_seq_subpractice", "T_crop_seq_subpractice"),
  pattern = "&",replacement = "and") # Apply "&" -> "and" substitution

md.era.short.clean <- apply_replace_in_cols(md.era.short.clean,
  cols = c("C_crop_seq_subpractice", "T_crop_seq_subpractice"),
  pattern = "Improved Fallow (N and Non N fixing)",replacement = "Improved Fallow (N fixing and Non N fixing)") 


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
## TO CHECK: NEED TO FIX C_agrof_subpractice=="Open Communial Grazing Land
## TO CHECK: THERE ARE AGROFORESTRY PRACTICES IN INTERCROPPING AND CROP ROTATION

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_agrof_subpractice", "T_agrof_subpractice"),
  pattern = "Multistrata",replacement = "Multistrata Agroforestry") # Apply "Multistrata" -> "Multistrata Agroforestry" substitution

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_agrof_subpractice", "T_agrof_subpractice"),
  pattern = "Hedgerows",replacement = "Living Fences or Hedgerows") # Apply "Hedgerows" -> "Living Fences or Hedgerows" substitution

md.era.short.clean <- apply_replace_in_cols(
  md.era.short.clean,
  cols = c("C_agrof_subpractice", "T_agrof_subpractice"),
  pattern = "Living Fences or Living Fences or Hedgerows",replacement = "Living Fences or Hedgerows") # Apply "Living Fences or Living Fences or Hedgerows" -> "Living Fences or Hedgerows" substitution

# Remove agroforestry practices from intercropping section

md.era.short.clean<-md.era.short.clean%>%
  mutate(
    C_intercrop_subpractice= case_when(
      (doi=="10.1002/agj2.20555"& 
         C_intercrop_subpractice=="Monoculture"&
         T_intercrop_subpractice=="Multistrata Agroforestry")~NA,TRUE~C_intercrop_subpractice),
    T_intercrop_subpractice= case_when(
      (doi=="10.1002/agj2.20555"& 
         T_intercrop_subpractice=="Multistrata Agroforestry")~NA,TRUE~T_intercrop_subpractice)
    )
  
#md.era.short.clean<-read_csv(file.path(path.metadata.effectsize,"/fomd10/fomd10_MD_Rosen_24_Effec_Sc.csv"), show_col_types = FALSE)

 
md.era.short.clean<-md.era.short.clean%>% 
  mutate(
    C_agrof_subpractice= case_when(
      (doi=="10.1080/01448765.1991.9754573"& 
         C_agrof_subpractice=="Monoculture"&
         T_agrof_subpractice=="Living Fences or Hedgerows")~"No Living Fences or Hedgerows or Tree Windbreak",
      TRUE~C_agrof_subpractice)
  )

##CHECK TO : verify later if it is better to keep track of spatial, component, shade..
sort(unique(md.era.short.clean$C_agrof_subpractice_raw))
sort(unique(md.era.short.clean$T_agrof_subpractice_raw))

sort(unique(md.era.short.clean$C_agrof_subpractice)) 
sort(unique(md.era.short.clean$T_agrof_subpractice))

sort(unique(md.era.short.clean$agrof_shade_mean_min_max)) #Missing from ERA
sort(unique(md.era.short.clean$agrof_canopy_height_mean_min_max)) #Missing from ERA
sort(unique(md.era.short.clean$agrof_dhb_mean_min_max))#Missing from ERA

#==================================================
#---nutrient_management_practice (inorganic)----
#==================================================
## TO CHECK: C_fert_inorganic_type C_fert_inorganic_unit C_fert_inorganic_amount
## TO CHECK: T_fert_inorganic_type T_fert_inorganic_unit T_fert_inorganic_amount

fert_subpractice<-c("C_fert_subpractice",
                    "T_fert_subpractice")

# Apply "Inorganic" -> "Inorganic Fertilizer" substitution
md.era.short.clean[fert_subpractice] <- lapply(
  md.era.short.clean[fert_subpractice],
  \(x) gsub("Inorganic", "Inorganic Fertilizer", x, fixed = TRUE)
)

# Apply "MicroNutrient" -> "Inorganic Micronutrients Inputs" substitution
md.era.short.clean[fert_subpractice] <- lapply(
  md.era.short.clean[fert_subpractice],
  \(x) gsub("MicroNutrient", "Inorganic Micronutrients Inputs", x, fixed = TRUE)
)

# Apply "Organic_Other" -> "Organic (Other)" substitution
md.era.short.clean[fert_subpractice] <- lapply(
  md.era.short.clean[fert_subpractice],
  \(x) gsub("Organic_Other", "Organic (Other)", x, fixed = TRUE)
)

sort(unique(md.era.short.clean$C_fert_subpractice))

sort(unique(md.era.short.clean$C_fert_subpractice))
sort(unique(md.era.short.clean$T_fert_subpractice))

# Columns where "; " should become ".."
npk_in_semicolon_cols <- c(
  "C_fert_subpractice", "T_fert_subpractice",
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

#Add manually the T_fert_inorganicNPK_unit of this study
md.era.short.clean<-md.era.short.clean%>%
  mutate(T_fert_inorganicNPK_unit=case_when(
    doi=="10.2136/sssaj2018.02.0066"&
    T_fert_inorganicK=="10"&
      T_fert_inorganicNPK_unit==""~"kg/ha",TRUE~T_fert_inorganicNPK_unit))

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
         T_fert_inorganicK_amount_unit= combine_amount_unit(amount = T_fert_inorganicK,unit   = T_fert_inorganicNPK_unit),
         T_fert_inorganicP2O5_amount_unit= combine_amount_unit(amount = T_fert_inorganicP2O5,unit   = T_fert_inorganicNPK_unit),
         T_fert_inorganicK2O_amount_unit= combine_amount_unit(amount = T_fert_inorganicK2O,unit   = T_fert_inorganicNPK_unit)
  )
#-------------------------------------------------------
# Code to check mismatch between amount and unit columns
#-------------------------------------------------------
# Check mismatches for any amount/unit pair
check_length_mismatch_amount_unit <- function(df, amount_col, unit_col) {
  amt <- df[[amount_col]]
  unt <- df[[unit_col]]
  
  mismatches <- mapply(function(a, u, i,doi,study_id) {
    if (is.na(a) || a == "") return(NULL)
    na <- length(strsplit(a, "\\.\\.")[[1]])
    nu <- length(strsplit(u, "\\.\\.")[[1]])
    if (na != nu) data.frame(row = i, 
                             doi=doi,study_id=study_id, amount_col, unit_col,
                             n_amounts = na, n_units = nu,
                             amount = a, unit = u)
  }, amt, unt, seq_along(amt),df$doi,df$study_id, SIMPLIFY = FALSE)
  
  do.call(rbind, Filter(Negate(is.null), mismatches))
}

# Run for all relevant pairs
pairs <- list(
  c("T_fert_inorganicN",   "T_fert_inorganicNPK_unit"),
  c("T_fert_inorganicP",   "T_fert_inorganicNPK_unit"),
  c("T_fert_inorganicK",   "T_fert_inorganicNPK_unit"),
  c("T_fert_inorganicP2O5","T_fert_inorganicNPK_unit"),
  c("T_fert_inorganicK2O", "T_fert_inorganicNPK_unit"),
  
  c("C_fert_inorganicN",   "C_fert_inorganicNPK_unit"),
  c("C_fert_inorganicP",   "C_fert_inorganicNPK_unit"),
  c("C_fert_inorganicK",   "C_fert_inorganicNPK_unit"),
  c("C_fert_inorganicP2O5","C_fert_inorganicNPK_unit"),
  c("C_fert_inorganicK2O", "C_fert_inorganicNPK_unit")
)
#this is ready, there is nothing to check
mismatch_report <- do.call(rbind, lapply(pairs, function(p)
  check_length_mismatch_amount_unit(md.era.short.clean, p[1], p[2])))
View(mismatch_report)



#-------------------------------------------------------
# Code to check mismatch between type, amount and unit columns
#-------------------------------------------------------
check_length_mismatch_type_amount_unit <- function(df, type_col, amount_col, unit_col) {
  typ <- df[[type_col]]
  amt <- df[[amount_col]]
  unt <- df[[unit_col]]
  
  mismatches <- mapply(function(t, a, u, id,doi) {
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
               doi=doi,
               type_col  = type_col,
               amount_col = amount_col,
               unit_col  = unit_col,
               n_types   = nt,
               n_amounts = na,
               n_units   = nu,
               type      = t,
               amount    = a,
               unit      = u)
    
  }, typ, amt, unt, df$study_id, df$doi,SIMPLIFY = FALSE)
  
  do.call(rbind, Filter(Negate(is.null), mismatches))
}

# Run for all relevant triplets
pairs <- list(
  c("C_fert_inorganic_type", "C_fert_inorganic_amount", "C_fert_inorganic_unit"),
  c("T_fert_inorganic_type", "T_fert_inorganic_amount", "T_fert_inorganic_unit")
)

report_CT_fert_inorganic <- do.call(rbind, lapply(pairs, function(p)
  check_length_mismatch_type_amount_unit(md.era.short.clean, p[1], p[2], p[3])
))

View(report_CT_fert_inorganic)

readr::write_csv(report_CT_fert_inorganic, paste0(path.era, "/v24_error_report/report_CT_fert_inorganic.csv"))

#------------
# Quick checks
sort(unique(md.era.short.clean$C_fert_subpractice_raw))
sort(unique(md.era.short.clean$T_fert_subpractice_raw))

sort(unique(md.era.short.clean$C_fert_subpractice)) 
sort(unique(md.era.short.clean$T_fert_subpractice)) 

sort(unique(md.era.short.clean$C_fert_inorganic_category)) 
sort(unique(md.era.short.clean$T_fert_inorganic_category)) 

sort(unique(md.era.short.clean$C_fert_inorganic_type)) 
sort(unique(md.era.short.clean$T_fert_inorganic_type)) 

sort(unique(md.era.short.clean$C_fert_inorganic_unit)) #TO CHECK: Need to combine type with amount and unit
sort(unique(md.era.short.clean$T_fert_inorganic_unit)) #TO CHECK: Need to combine type with amount and unit

sort(unique(md.era.short.clean$C_fert_inorganic_amount)) #TO CHECK: Need to combine type with amount and unit
sort(unique(md.era.short.clean$T_fert_inorganic_amount)) #TO CHECK: Need to combine type with amount and unit

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

# Apply "999999" -> "Unspecified" 
md.era.short.clean[npk_or_cols] <- lapply(
  md.era.short.clean[npk_or_cols],
  \(x) gsub("999999", "Unspecified", x, fixed = TRUE)
)

# Reusable function to combine fertilizer type + amount + unit separated by ".."
combine_type_amount_unit <- function(applied, amount_unit) {
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

# Combine fertilizer type + amount + unit separated by ".."
md.era.short.clean <- md.era.short.clean%>%
  mutate(C_fert_organic_amount_unit1= combine_amount_unit(amount = C_fert_organic_amount, unit   = C_fert_organic_unit),
         T_fert_organic_amount_unit1= combine_amount_unit(amount = T_fert_organic_amount, unit   = T_fert_organic_unit))%>%
  mutate(C_fert_organic_type_amount_unit= mapply(combine_type_amount_unit,C_fert_organic_type,C_fert_organic_amount_unit1),
         T_fert_organic_type_amount_unit= mapply(combine_type_amount_unit,T_fert_organic_type,T_fert_organic_amount_unit1)
  )

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
sort(unique(md.era.short.clean$C_fert_organic_category))  
sort(unique(md.era.short.clean$T_fert_organic_category))  

sort(unique(md.era.short.clean$C_fert_organic_type)) # Merged 
sort(unique(md.era.short.clean$T_fert_organic_type)) # Merged

sort(unique(md.era.short.clean$C_fert_organic_unit)) # Merged
sort(unique(md.era.short.clean$T_fert_organic_unit)) # Merged

sort(unique(md.era.short.clean$C_fert_organic_amount)) # Merged
sort(unique(md.era.short.clean$T_fert_organic_amount)) # Merged

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

#=========================
#---weeding_management_moderator----
#=========================
## TO CHECK: C_weed_frequency_unit T_weed_frequency_unit

# Columns needing "..." -> ".."
weed_cols <- c(
  "C_weed_method", "T_weed_method",
  "C_weed_frequency_unit", "T_fert_organicP",
  "C_weed_frequency", "T_weed_frequency"
)

# Apply "..." -> ".." 
md.era.short.clean[weed_cols] <- lapply(
  md.era.short.clean[weed_cols],
  \(x) gsub("...", "..", x, fixed = TRUE)
)
### check it the number of frequencies match the units
pruebaC<-md.era.short.clean%>%
  dplyr::select(C_weed_method,C_weed_frequency,C_weed_frequency_unit)%>%
  filter(C_weed_frequency_unit=="")%>%
  filter(C_weed_frequency!="")

pruebaT<-md.era.short.clean%>%
  dplyr::select(T_weed_method,T_weed_frequency,T_weed_frequency_unit)%>%
  filter(T_weed_frequency_unit=="")%>%
  filter(T_weed_frequency!="")


# Run for all relevant pairs
pairs <- list(
  c("C_weed_frequency",   "C_weed_frequency_unit"),
  c("T_weed_frequency",   "T_weed_frequency_unit")
)

# Report for Lolita
report_CT_weeding_frequency_unit <- do.call(rbind, lapply(pairs, function(p)
  check_length_mismatch_amount_unit(md.era.short.clean, p[1], p[2])
))
readr::write_csv(report_CT_weeding_frequency_unit, paste0(path.era, "/v24_error_report/report_CT_weeding_frequency_unit.csv"))


View(mismatch_report_weeding_frequency)

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
## TO CHECK  C_chem_subpractice,T_chem_subpractice
## TO CHECK: "C_chem_name", "C_chem_amount", "C_chem_amount_unit" "T_chem_name", "T_chem_amount", "T_chem_amount_unit"
md.era.short.clean$C_chem_subpractice <- gsub("; ", "..", md.era.short.clean$C_chem_subpractice, fixed = TRUE)
md.era.short.clean$T_chem_subpractice <- gsub("; ", "..", md.era.short.clean$T_chem_subpractice, fixed = TRUE)

md.era.short.clean$C_chem_name <- gsub("; ", "..", md.era.short.clean$C_chem_name, fixed = TRUE)
md.era.short.clean$T_chem_name <- gsub("; ", "..", md.era.short.clean$T_chem_name, fixed = TRUE)

md.era.short.clean$C_chem_amount_unit <- gsub("; ", "..", md.era.short.clean$C_chem_amount_unit, fixed = TRUE)
md.era.short.clean$T_chem_amount_unit <- gsub("; ", "..", md.era.short.clean$T_chem_amount_unit, fixed = TRUE)

md.era.short.clean$C_chem_amount <- gsub("; ", "..", md.era.short.clean$C_chem_amount, fixed = TRUE)
md.era.short.clean$T_chem_amount <- gsub("; ", "..", md.era.short.clean$T_chem_amount, fixed = TRUE)

# Run for all relevant triplets
pairs <- list(
  c("C_chem_name", "C_chem_amount", "C_chem_amount_unit"),
  c("T_chem_name", "T_chem_amount", "T_chem_amount_unit")
)

# Report for Lolita
report_CT_chem_name_amount_unit <- do.call(rbind, lapply(pairs, function(p)
  check_length_mismatch_type_amount_unit(md.era.short.clean, p[1], p[2], p[3])
))

View(report_CT_chem_name_amount_unit)
readr::write_csv(report_CT_chem_name_amount_unit, paste0(path.era, "/v24_error_report/report_CT_chem_name_amount_unit.csv"))

# Quick checks
sort(unique(md.era.short.clean$C_chem_subpractice_raw))
sort(unique(md.era.short.clean$T_chem_subpractice_raw))

sort(unique(md.era.short.clean$C_chem_subpractice))
sort(unique(md.era.short.clean$T_chem_subpractice))

# Helper function for the repeated logic
make_ct <- function(c_col, t_col) {
  dplyr::case_when(
    c_col != "" & t_col != "" #& c_col != t_col 
    ~ paste0(c_col, "_vs_", t_col),
    TRUE ~ NA_character_
  )
}

# Define practice types to iterate over
practices <- c( "chem")

report_CT_chem_subpractice <- md.era.short.clean %>%
  select(
    doi,study_id  ,
    C_chem_subpractice,T_chem_subpractice
  )%>%
  mutate(
    across(
      .cols = all_of(paste0("C_", practices, "_subpractice")),
      .fns  = ~ make_ct(.x, get(sub("^C_", "T_", cur_column()))),
      .names = "CT_{sub('C_', '', .col)}"
    )
  )

readr::write_csv(report_CT_chem_subpractice, paste0(path.era, "/v24_error_report/report_CT_chem_subpractice.csv"))

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
## TO CHECK: T_residues_N_unit and T_residues_N
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
  "C_residues_material_source","T_residues_material_source",
  "C_residues_material_amount","T_residues_material_amount"
)

res_space_cols <- c(
  "C_residues_OC", "T_residues_OC",
  "C_residues_N",     "T_residues_N",
  "C_residues_P",     "T_residues_P",
  "C_residues_K",   "T_residues_K",
  "C_residues_material_amount","T_residues_material_amount"
)

# Apply "; " -> ".." substitution
md.era.short.clean[res_semicolon_cols] <- lapply(
  md.era.short.clean[res_semicolon_cols],
  \(x) gsub("; ", "..", x, fixed = TRUE)
)

# Apply " " -> "" substitution
md.era.short.clean[res_space_cols] <- lapply(
  md.era.short.clean[res_space_cols],
  \(x) trimws(gsub("\\s+", "", x)))

# Apply "..." -> ".." substitution
md.era.short.clean[res_semicolon_cols] <- lapply(
  md.era.short.clean[res_semicolon_cols],
  \(x) gsub("...", "..", x, fixed = TRUE))

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
          T_residues_K== "0.00..0.00"))~"",TRUE~T_residues_K))
  

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
    #T_residues_N_amount_unit= combine_amount_unit(amount = T_residues_N,unit   = T_residues_N_unit), #not ready to merge, mismatches
    
    C_residues_P_amount_unit= combine_amount_unit(amount = C_residues_P,unit   = C_residues_P_unit),
    T_residues_P_amount_unit= combine_amount_unit(amount = T_residues_P,unit   = T_residues_P_unit),
    
    C_residues_K_amount_unit= combine_amount_unit(amount = C_residues_K,unit   = C_residues_K_unit),
    T_residues_K_amount_unit= combine_amount_unit(amount = T_residues_K,unit   = T_residues_K_unit),
    
    C_residues_material_amount_unit= combine_amount_unit(amount = C_residues_material_amount,unit   = C_residues_material_unit),
    T_residues_material_amount_unit= combine_amount_unit(amount = T_residues_material_amount,unit   = T_residues_material_unit)
  )

# Run for all relevant pairs
pairs <- list(
  c("C_residues_OC",   "C_residues_OC_unit"),
  c("T_residues_OC",   "T_residues_OC_unit"), 
  
  c("C_residues_N",   "C_residues_N_unit"), 
  c("T_residues_N","T_residues_N_unit"), #missing units
  
  c("C_residues_P", "C_residues_P_unit"), 
  c("T_residues_P",   "T_residues_P_unit"), 
  
  c("C_residues_K",   "C_residues_K_unit"),
  c("T_residues_K",   "T_residues_K_unit"),
  
  c("C_residues_material_amount",   "C_residues_material_unit"),
  c("T_residues_material_amount",   "T_residues_material_unit")
  )

#Report for Lolita
report_residues_N_unit <- do.call(rbind, lapply(pairs, function(p)
  check_length_mismatch_amount_unit(md.era.short.clean, p[1], p[2])))%>%
  filter(amount_col=="T_residues_N")

sort(unique(report_residues_N_unit$amount))
View(report_residues_N_unit)

readr::write_csv(report_residues_N_unit, paste0(path.era, "/v24_error_report/report_residues_N_unit.csv"))

# Quick checks
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
sort(unique(md.era.short.clean$T_residues_N_unit)) # TO CHECK not ready to merge

sort(unique(md.era.short.clean$C_residues_N)) # Merged
sort(unique(md.era.short.clean$T_residues_N)) # TO CHECK not ready to merge

sort(unique(md.era.short.clean$C_residues_N[is.na(md.era.short.clean$C_residues_N_unit)]))
sort(unique(md.era.short.clean$C_residues_N[md.era.short.clean$C_residues_N_unit==""]))
#[1] character(0)
sort(unique(md.era.short.clean$T_residues_N[is.na(md.era.short.clean$T_residues_N_unit)]))
sort(unique(md.era.short.clean$T_residues_N[md.era.short.clean$T_residues_N_unit==""]))
#[1] ""       "102"    "122"    "1294.4" "142"    "163"    "183"    "203"    "22.5"   "25"     "3.53"   "30"     "4.14"   "4.26"   "45"     "60"    
#[17] "61"     "83"     "90"  

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
#sort(unique(md.era.short.clean$T_residues_N_amount_unit)) #TO CHECK: not ready

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
  cols = c("Ca", "Calcium"),
  pattern = "...",replacement = "..") 


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
#md.era.short.clean<-read_csv(file.path(path.metadata.effectsize,"/fomd10/fomd10_MD_Rosen_24_Effec_Sc.csv"), show_col_types = FALSE)

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
  cols = c("C_irrig_water_unit", "T_irrig_water_unit"),
  pattern = "mmweek",replacement = "mm/week") 

#md.era.short.clean$C_irrig_water_unit <- gsub("mmweek", "mm/week", md.era.short.clean$C_irrig_water_unit, fixed = TRUE)
#md.era.short.clean$T_irrig_water_unit <- gsub("mmweek", "mm/week", md.era.short.clean$T_irrig_water_unit, fixed = TRUE)

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
md.era.short.clean$C_watharv_subpractice <- gsub(", ", "..", md.era.short.clean$C_watharv_subpractice, fixed = TRUE)
md.era.short.clean$T_watharv_subpractice <- gsub(", ", "..", md.era.short.clean$T_watharv_subpractice, fixed = TRUE)

# Quick checks
sort(unique(md.era.short.clean$C_watharv_subpractice_raw))
sort(unique(md.era.short.clean$T_watharv_subpractice_raw))

sort(unique(md.era.short.clean$C_watharv_subpractice))
sort(unique(md.era.short.clean$T_watharv_subpractice))

#=========================
#---postharvesting_practice----
#=========================
## TO CHECK: C_postharvest_subpractice_raw and T_postharvest_subpractice_raw missing
## TO CHECK: C_postharvest_subpractice and T_postharvest_subpractice LOOK LIKE RAW VARIABLES

# Quick checks
sort(unique(md.era.short.clean$C_postharvest_subpractice_raw)) #MISSING
sort(unique(md.era.short.clean$T_postharvest_subpractice_raw)) #MISSING

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
# TO CHECK: #MAKE A LIST OF MISSING PRODUCTS FROM 01_product_new

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
na_empty_summary1["C_product", ] #in v6 17064 missing values; in v24 3150 empty values
na_empty_summary1["T_product", ] #in v6 17064 missing values; in v24 3150 empty values

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

# Quick checks
sort(unique(md.era.short.clean$out_subindicator))

#Explanation from Lolita:
#Only 15 rows. I opened the source papers: 7 of them I could fill with confidence 
#(NN0165 = Milk Yield, NN0272 = Feed Conversion Ratio – both confirmed against the paper's tables). 
#The other 8 I left blank on purpose: 3 are a fertilizer-cost figure that doesn't match any of our outcome categories,
#and 5 (JS0232) had values I couldn't trace to anything in the published paper, so we can exclude those.
nrow(md.era.short.clean[md.era.short.clean$out_subindicator == "", ]) #15 in v6, 8 in v24  rows with empty out_subindicator, is this ok?

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

md.era.short.clean<-md.era.short.clean%>%
  mutate(
    C_out_var_value=as.character(C_out_var_value),
    C_out_var_value=case_when(is.na(C_out_var_value)&C_out_var_metric=="Unspecified"~"Unspecified",TRUE~C_out_var_value),
    T_out_var_value=as.character(T_out_var_value),
    T_out_var_value=case_when(is.na(T_out_var_value)&T_out_var_metric=="Unspecified"~"Unspecified",TRUE~T_out_var_value))

# Quick checks
sort(unique(md.era.short.clean$C_out_metric))
sort(unique(md.era.short.clean$T_out_metric))
na_empty_summary1["C_out_metric", ] #0
na_empty_summary1["T_out_metric", ] #0

sort(unique(md.era.short.clean$C_out_value))
sort(unique(md.era.short.clean$T_out_value))

#Explanation from Lolita
#C_out_value / T_out_value and C_out_sample_size / T_out_sample_size: 
#the blanks here are genuine gaps in the source papers, not a processing error. 
#For the missing outcome values it's only 9 studies, and they're all ratio/efficiency results 
#(Land Equivalent Ratio, Nitrogen/Phosphorus Agronomic Efficiency) that don't have a control value by definition. 
#Overall the outcome data is about 99.5% complete

na_empty_summary1["C_out_value", ]
nrow(md.era.short.clean[md.era.short.clean$C_out_value == "", ]) #1075 missing C_out_value values
na_empty_summary1["T_out_value", ]
nrow(md.era.short.clean[md.era.short.clean$T_out_value == "", ]) #6 missing T_out_value values

sort(unique(md.era.short.clean$C_out_var_metric))
sort(unique(md.era.short.clean$T_out_var_metric))
nrow(md.era.short.clean[md.era.short.clean$C_out_var_metric == "", ]) #182058
nrow(md.era.short.clean[md.era.short.clean$T_out_var_metric == "", ]) #183074

sort(unique(md.era.short.clean$C_out_var_value))
sort(unique(md.era.short.clean$T_out_var_value))
na_empty_summary1["C_out_var_value", ]
nrow(md.era.short.clean[md.era.short.clean$C_out_var_value == "", ]) #183075
na_empty_summary1["T_out_var_value", ]
nrow(md.era.short.clean[md.era.short.clean$T_out_var_value == "", ])#182988

#Reports for Lolita
report_C_out_var_metric<-md.era.short.clean %>%
  filter(!is.na(C_out_var_value), C_out_var_value != "", C_out_var_metric == "") %>%
  select(authors,study_id,doi,C_out_var_metric,C_out_var_value, C_data_location)
nrow(report_C_out_var_metric) #88 there are 88 rows that have C_out_var_value but don't have C_out_var_metric

readr::write_csv(report_C_out_var_metric, paste0(path.era, "/v24_error_report/report_C_out_var_metric.csv"))

report_T_out_var_metric<- md.era.short.clean %>%
  filter(!is.na(T_out_var_value), T_out_var_value != "", T_out_var_metric == "") %>%
  select(authors,study_id,doi,T_out_var_metric,T_out_var_value, T_data_location)
nrow(report_T_out_var_metric) #86 there are 86 rows that have C_out_var_value but don't have C_out_var_metric

readr::write_csv(report_T_out_var_metric, paste0(path.era, "/v24_error_report/report_T_out_var_metric.csv"))

sort(unique(md.era.short.clean$C_out_sample_size))
sort(unique(md.era.short.clean$T_out_sample_size))
na_empty_summary1["C_out_sample_size", ] #in v6 17064 missing values; in v24 16896
na_empty_summary1["T_out_sample_size", ] #in v6 17064 missing values; in v24 16896

report_C_out_sample_size<-md.era.short.clean %>%
  filter(is.na(C_out_sample_size)) %>%
  select(authors,study_id,doi,C_out_var_metric,C_out_var_value, C_out_sample_size, C_data_location)
nrow(report_C_out_sample_size) #49183 there are 49183 rows that have T_out_var_metric but don't have T_out_var_value

readr::write_csv(report_C_out_sample_size, paste0(path.era, "/v24_error_report/report_C_out_sample_size.csv"))

report_T_out_sample_size<-md.era.short.clean %>%
  filter(is.na(T_out_sample_size)) %>%
  select(authors,study_id,doi,T_out_var_metric,T_out_var_value, T_out_sample_size, T_data_location)
nrow(report_T_out_sample_size) #49183 there are 49183 rows that have T_out_var_metric but don't have T_out_var_value

readr::write_csv(report_T_out_sample_size, paste0(path.era, "/v24_error_report/report_T_out_sample_size.csv"))


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
#---product_outcome----
#=========================
#I NEED TO DO THIS BUT LATER AFTER EFFECT SIZE CALCULATION


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
#[1] "C_fert_inorganic_type_amount_unit" "T_fert_inorganic_type_amount_unit" "C_chem_name_amount_unit"          
#[4] "T_chem_name_amount_unit"           "T_residues_N_amount_unit"         


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


#md.era.clean <- read.csv(file.path(path.metadata, "/04.added_to_06_FOMD_metadata_original_long/added_to_10_MD_Rosen_24_Effec_Sc.csv"))

readr::write_csv(md.era.clean, paste0(path.metadata.effectsize, "/fomd10/fomd10_MD_Rosen_24_Effec_Sc.csv"))

#readr::write_csv(md.era.short.clean, paste0(path.metadata.effectsize, "/fomd10/fomd10_MD_Rosen_24_Effec_Sc.csv"))

#==========================================================
# Record of missing values in each row
#========================================================== 
n <- nrow(md.era.short)

na_empty_summary1 <- data.frame(
  na_count          = colSums(is.na(md.era.short)),
  empty_count       = colSums(md.era.short == "", na.rm = TRUE),
  total_missing     = colSums(is.na(md.era.short)) + colSums(md.era.short == "", na.rm = TRUE),
  total_missing_pct = round((colSums(is.na(md.era.short)) + colSums(md.era.short == "", na.rm = TRUE)) / n * 100, 2)
)

print(na_empty_summary1)


