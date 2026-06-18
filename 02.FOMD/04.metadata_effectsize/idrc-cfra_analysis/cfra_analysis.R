library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(readr)
library(tibble)
library(purrr)

path.metadata.added10<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/01.metadata_harmonisation/02.metadata/04.added_to_06_FOMD_metadata_original_long"
path.metadata.structure<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/02.metadata_structure"


#==========================================================
# Read datasets
#==========================================================
#---01_FOMD_ontologies
fomd01.product_new<-read_xlsx(file.path(path.metadata.structure,"01_FOMD_ontologies.xlsx"), sheet = "01_product_new")%>%
  filter(!is.na(Product.Simple))%>%
  distinct(Product.Type,Product.Simple,SPAM.Food.Group,FAO.Food.SubGroup,FAO.Food.Group) 

#---added_to_10_MD_Rosen_24_Effec_Sc
fomd10.MD_Rosen_24_Effec_Sc <- read.csv(file.path(path.metadata.added10, "added_to_10_MD_Rosen_24_Effec_Sc.csv"))
nrow(fomd10.MD_Rosen_24_Effec_Sc) #232257
fomd10.MD_Rosen_24_Effec_Sc <-fomd10.MD_Rosen_24_Effec_Sc%>%
  filter(!is.na(C_out_value))%>% #231182
  filter(!is.na(T_out_value)) #231181
nrow(fomd10.MD_Rosen_24_Effec_Sc) #231181

sort(unique(fomd10.MD_Rosen_24_Effec_Sc$C_out_value))
is.na(fomd10.MD_Rosen_24_Effec_Sc$C_out_value)

#==========================================================
#--- Filter only relevant countries
#==========================================================
sort(unique(fomd10.MD_Rosen_24_Effec_Sc$country))

# CFRA countries
cfra.countries<-c("Angoloa",
                  "Burundi",
                  "Ethiopia",
                  "Kenya",
                  "Malawi",
                  "Rwanda",
                  "Tanzania",
                  "Uganda",
                  "Zambia")

pattern.countries <- paste(cfra.countries, collapse = "|")

# Filter rows where country contains any of the target countries
fomd10.cfra <- fomd10.MD_Rosen_24_Effec_Sc %>%
  filter(grepl(pattern.countries, country, ignore.case = TRUE))

sort(unique(fomd10.cfra$country))
sort(unique(fomd10.cfra$C_site_latitude))
sort(unique(fomd10.cfra$T_site_latitude))

#==========================================================
#--- Filter only relevant indicators
#==========================================================
#Biodiversity, Resilience, 
#resilience, carbon sequestration, soil fertility, productivity
sort(unique(fomd10.cfra$out_subindicator))
sort(unique(fomd10.cfra$out_subindicator[is.na(fomd10.cfra$out_indicator)])) 
sort(unique(fomd10.cfra$out_indicator)) #16 
#[1] "Animal Survival"      "Biodiversity"         "Carbon Stocks"        "Costs"                "Economic Performance"
#[6] "Efficiency"           "Emissions"            "Feed Intake"          "Fuel Efficiency"      "Gender Equity"       
#[11] "Income"               "Labour"               "Non-Product Yield"    "Pest & Pathogen"      "Product Yield"       
#[16] "Soil Quality"

cfra.indicators<-c("Biodiversity",
                   "Carbon Stocks",
                   "Costs"  ,
                   "Economic Performance",
                   "Efficiency" ,
                   "Emissions",
                   "Gender Equity",
                   "Income" ,
                   "Labour",
                   "Pest & Pathogen",
                   "Product Yield" ,
                   "Soil Quality")
 

# Filter rows where out_indicator contains any of the target indicators
fomd10.cfra <- fomd10.cfra %>%
  filter(tolower(out_indicator) %in% tolower(cfra.indicators))

sort(unique(fomd10.cfra$out_pillar)) #3
sort(unique(fomd10.cfra$out_subpillar)) #12

sort(unique(fomd10.cfra$out_indicator)) #12
sort(unique(fomd10.cfra$out_subindicator[fomd10.cfra$out_indicator== "Costs"])) 
sort(unique(fomd10.cfra$out_subindicator)) #60

#--- Relevant out_subindicators----
removed.subindicators<-c("Egg Yield",
                         "Feed Conversion Ratio (In Out)",
                         "Feed Conversion Ratio (Out In)",
                         "Fuel Use",
                         "Meat Yield",
                         "Milk Yield",
                         "Protein Conversion Ratio (In Out)",
                         "Protein Conversion Ratio (Out In)" ,
                         "Reproductive Yield",
                         "Weight Gain" )
            
fomd10.cfra <- fomd10.cfra %>%
  filter(!tolower(out_subindicator) %in% tolower(removed.subindicators))

sort(unique(fomd10.cfra$out_subindicator)) #51
sort(unique(fomd10.cfra$out_subindicator[fomd10.cfra$out_pillar== "Mitigation"])) 
sort(unique(fomd10.cfra$out_subindicator[fomd10.cfra$out_pillar== "Productivity"])) 
sort(unique(fomd10.cfra$out_subindicator[fomd10.cfra$out_pillar== "Resilience"])) 


#https://caliper.integratedmodelling.org/caliper/browse/showvoc/#/datasets/WCA2020_Crops/unknown/data?resId=https:%2F%2Fstats.fao.org%2Fclassifications%2FWCA2020%2Fcrops%2FBasil
#https://caliper.integratedmodelling.org/caliper/browse/showvoc/#/datasets/ICC1_0/unknown/data?resId=https:%2F%2Fstats.fao.org%2Fclassifications%2FICC%2Fv1.0%2F931

sort(unique(fomd10.cfra$T_crop_diversity)) #51
sort(unique(fomd10.cfra$T_tree_diversity[fomd10.cfra$T_crop_diversity== "Acacia decurrens-Teff/Acacia decurrens-Unspecified Fodder Grass/Acacia decurrens/Acacia decurrens/Acacia decurrens" ])) 

unique_crops <- rbind(
  data.frame(crop_diversity = fomd10.cfra %>%
               filter(C_crop_diversity != "") %>%
               pull(C_crop_diversity) %>%
               str_split("[/\\-]") %>%
               unlist() %>%
               str_trim()),
  data.frame(crop_diversity = fomd10.cfra %>%
               filter(T_crop_diversity != "") %>%
               pull(T_crop_diversity) %>%
               str_split("[/\\-]") %>%
               unlist() %>%
               str_trim())) %>%
  distinct(crop_diversity) %>%
  arrange(crop_diversity)%>%
  left_join(fomd01.product_new,
            by=c("crop_diversity"="Product.Simple"))

head(unique_crops)
sort(unique(unique_crops$crop_diversity))



################################################
# Helper function for the repeated logic
make_ct <- function(c_col, t_col) {
  dplyr::case_when(
    c_col != "" & t_col != "" & c_col != t_col ~ paste0(c_col, "_vs_", t_col),
    TRUE ~ NA_character_
  )
}

# Define practice types to iterate over
practices <- c( "intercrop", "crop_seq", "fert")

fomd10.cfra.analysis <- fomd10.cfra %>%
  select(C_tillage_subpractice,T_tillage_subpractice,
         C_intercrop_subpractice,T_intercrop_subpractice,
         C_crop_seq_subpractice,T_crop_seq_subpractice,
         C_fert_subpractice,T_fert_subpractice
  )%>%
  
  mutate(
    CT_tillage_subpractice=case_when(C_tillage_subpractice!=""&T_tillage_subpractice!=""~paste0(C_tillage_subpractice,"_vs_",T_tillage_subpractice),TRUE~NA))%>%
  mutate(
    across(
      .cols = all_of(paste0("C_", practices, "_subpractice")),
      .fns  = ~ make_ct(.x, get(sub("^C_", "T_", cur_column()))),
      .names = "CT_{sub('C_', '', .col)}"
    )
  )

sort(unique(fomd10.cfra.analysis$C_tillage_subpractice))
sort(unique(fomd10.cfra.analysis$T_tillage_subpractice))
sort(unique(fomd10.cfra.analysis$CT_tillage_subpractice))

sort(unique(fomd10.cfra.analysis$C_intercrop_subpractice))
sort(unique(fomd10.cfra.analysis$T_intercrop_subpractice))
sort(unique(fomd10.cfra.analysis$CT_intercrop_subpractice))

sort(unique(fomd10.cfra.analysis$C_crop_seq_subpractice))
sort(unique(fomd10.cfra.analysis$T_crop_seq_subpractice))
sort(unique(fomd10.cfra.analysis$CT_crop_seq_subpractice))

sort(unique(fomd10.cfra.analysis$C_fert_subpractice))
sort(unique(fomd10.cfra.analysis$T_fert_subpractice))
sort(unique(fomd10.cfra.analysis$CT_fert_subpractice))


fomd10.cfra.analysis %>%
  summarise(
    total_rows   = n(),
    na_count     = sum(is.na(CT_tillage_subpractice)),
    na_pct       = round(na_count / total_rows * 100, 1)
  )



#==========================================================
#--- Report n_rows and n_studies
#==========================================================
# Per country
country.outpillar<-fomd10.cfra %>%
  group_by(country,out_pillar) %>%
  summarise(
    n_effect_sizes     = n(),
    n_studies  = n_distinct(study_id)
  ) %>%
  arrange(desc(n_effect_sizes))


# --- Helper: parse "a..b..c" coordinate strings into a list of values -------
parse_coords <- function(coord_str) {
  str_split(coord_str, fixed(".."))[[1]] %>% as.numeric()
}

# --- Expand multi-coordinate rows into one row per point --------------------
expand_sites <- function(df, country_col, lat_col, lon_col, out_pillar) {
  df %>%
    select(country = {{ country_col }},
           lat_str = {{ lat_col }},
           lon_str = {{ lon_col }},
           out_pillar=out_pillar) %>%
    mutate(out_pillar = out_pillar,
           row_id = row_number()) %>%
    rowwise() %>%
    mutate(
      lats = list(parse_coords(lat_str)),
      lons = list(parse_coords(lon_str))
    ) %>%
    ungroup() %>%
    mutate(coords = map2(lats, lons, ~ tibble(lat = .x, lon = .y))) %>%
    select(row_id, country, out_pillar, coords) %>%
    unnest(coords)
}

# --- Build the unified points table -----------------------------------------
x <- fomd10.cfra %>%
  select(C_country, C_site_latitude, C_site_longitude,out_pillar)%>%
  distinct(C_country,
           C_site_latitude,
           C_site_longitude,
           out_pillar) 

control_pts  <- expand_sites(x, C_country, C_site_latitude, C_site_longitude, out_pillar)

cfra.sites <- control_pts %>%
  filter(!is.na(lat), !is.na(lon))

# Find rows where parsing produces NAs
error<-x %>%
  mutate(row_id = row_number()) %>%
  rowwise() %>%
  mutate(
    lats = list(parse_coords(C_site_latitude)),
    lons = list(parse_coords(C_site_longitude)),
    has_na = any(is.na(lats)) | any(is.na(lons))
  ) %>%
  ungroup() %>%
  filter(has_na) %>%
  select(row_id, C_country, C_site_latitude, C_site_longitude)


  
  

# Per indicators (Productivity, Resilience, Biodiversity) 
subindicator<-fomd10.cfra %>%
  filter(country=="Ethiopia")%>%
  group_by(out_pillar,out_subindicator) %>%
  summarise(
    n_rows     = n(),
    n_studies  = n_distinct(study_id)
  ) %>%
  arrange(desc(n_rows))


C_site_latitude


