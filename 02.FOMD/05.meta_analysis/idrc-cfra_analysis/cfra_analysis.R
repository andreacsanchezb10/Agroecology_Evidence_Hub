library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(readr)
library(tibble)
library(purrr)


path.metadata.effectsize<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/04.metadata_effectsize"

#==========================================================
# Read functions
#==========================================================
source(file.path(path.metadata.effectsize,"/fomd_fun/fun_load_data_ontologies.R"))


#==========================================================
# Read datasets
#==========================================================
#---01_FOMD_ontologies
fomd01.product.new<-fomd01.product.new%>%
  filter(!is.na(Product.Simple))%>%
  distinct(Product.Type,Product.Simple,SPAM.Food.Group,FAO.Food.SubGroup,FAO.Food.Group) 

#---fomd10.effect.size
fomd10.effect.size<-read_csv(file.path(path.metadata.effectsize,"/fomd10_effect_size.csv"), show_col_types = FALSE)

nrow(fomd10.effect.size) #232257

prueba<-fomd10.effect.size%>%  
  #filter(C_out_mean<0)%>%

  filter(out_subindicator=="Cation Exchange Capacity")%>%
  select(out_subindicator,C_out_mean,T_out_mean)


#==========================================================
#--- Filter only relevant countries
#==========================================================
sort(unique(fomd10.effect.size$country))

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
fomd10.cfra <- fomd10.effect.size %>%
  filter(grepl(pattern.countries, country, ignore.case = TRUE))

sort(unique(fomd10.cfra$country))
sort(unique(fomd10.cfra$C_site_latitude))
sort(unique(fomd10.cfra$T_site_latitude))

#==========================================================
#--- Remove irrelevant out_subindicators
#==========================================================
#--- Remove Animal related out_subindicators----
removed.subindicators<-c("Animal Survival" ,
                         "Animal Mortality" ,
                         "Daily Average Weight Gain",
                         "Egg Yield",
                         "Feed Conversion Ratio (In Out)",
                         "Feed Conversion Ratio (Out In)",
                         "Feed Intake"  ,
                         "Fixed Cost-Animals Purchase",
                         "Final Body Weight Meat Yield",
                         "Fuel Use",
                         "Meat Yield",
                         "Meat Yield-Empty Carcass Meat Yield",
                         "Meat Yield-Final Body Weight",
                         "Meat Yield-Hot Carcass" ,                    
                         "Meat Yield-Slaughter Body", 
                         "Milk Yield",
                         "Nitrogen (Apparent Efficiency Animals Feed)",
                         "Protein Conversion Ratio (In Out)",
                         "Protein Conversion Ratio (Out In)" ,
                         "Reproductive Yield",
                         
                         "Total Weight Gain",
                         "Variable Costs-Animal Feed",
                         "Variable Costs-Veterinary",
                         "Weight Gain" )

fomd10.cfra <- fomd10.cfra %>%
  filter(!tolower(out_subindicator) %in% tolower(removed.subindicators))

sort(unique(fomd10.cfra$out_subindicator)) #57
sort(unique(fomd10.cfra$out_subindicator[fomd10.cfra$out_pillar== "Mitigation"])) 
sort(unique(fomd10.cfra$out_subindicator[fomd10.cfra$out_pillar== "Productivity"])) 
sort(unique(fomd10.cfra$out_subindicator[fomd10.cfra$out_pillar== "Resilience"])) 


#https://caliper.integratedmodelling.org/caliper/browse/showvoc/#/datasets/WCA2020_Crops/unknown/data?resId=https:%2F%2Fstats.fao.org%2Fclassifications%2FWCA2020%2Fcrops%2FBasil
#https://caliper.integratedmodelling.org/caliper/browse/showvoc/#/datasets/ICC1_0/unknown/data?resId=https:%2F%2Fstats.fao.org%2Fclassifications%2FICC%2Fv1.0%2F931

sort(unique(fomd10.cfra$T_crop_diversity)) #51
sort(unique(fomd10.cfra$T_tree_diversity[fomd10.cfra$T_crop_diversity== "Acacia decurrens-Teff/Acacia decurrens-Unspecified Fodder Grass/Acacia decurrens/Acacia decurrens/Acacia decurrens" ])) 

#==========================================================
#--- Filter only relevant out_subindicator
#==========================================================
#Biodiversity, Resilience, 
#resilience, carbon sequestration, soil fertility, productivity
sort(unique(fomd10.cfra$out_subindicator))
sort(unique(fomd10.cfra$out_subindicator[is.na(fomd10.cfra$out_indicator)])) 
sort(unique(fomd10.cfra$out_indicator)) #16 


cfra.indicators<-c(#"Biodiversity",
                   #"Carbon Stocks",
                   "Costs"  ,
                   "Crop Yield",
                   #"Economic Performance",
                   #"Efficiency" ,
                   #"Emissions",
                   #"Gender Equity",
                   "Income" ,
                   #"Labour",
                   #"Pest & Pathogen",
                   "Product Yield" 
                   #"Soil Quality"
                   )
 

# Filter rows where out_indicator contains any of the target indicators
fomd10.cfra <- fomd10.cfra %>%
  filter(tolower(out_indicator) %in% tolower(cfra.indicators))

sort(unique(fomd10.cfra$out_subindicator))


sort(unique(fomd10.cfra$out_pillar)) #3
sort(unique(fomd10.cfra$out_subpillar)) #12

sort(unique(fomd10.cfra$out_indicator)) #12
sort(unique(fomd10.cfra$out_subindicator[fomd10.cfra$out_indicator== "Costs"])) 
sort(unique(fomd10.cfra$out_subindicator)) #60


unique_crops_diversity <- rbind(
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
  left_join(fomd01.product.new%>%
              filter(!is.na(Product.Simple))%>%
              distinct(Product.Type,Product.Simple,SPAM.Food.Group,FAO.Food.Group),
            by=c("crop_diversity"="Product.Simple"))
  filter(is.na(Product.Type))

head(unique_crops)
sort(unique(unique_crops$crop_diversity))




#==========================================================
#--- Report DEEP-DIVE COUNTRIES:
#--- ETHIOPIA
#==========================================================
sort(unique(fomd10.cfra$effect_size_type))

##---- Filter country == Ethiopia -----
fomd10.cfra.eth<- fomd10.cfra%>%
  filter(country=="Ethiopia")


nrow(fomd10.cfra.eth) #14653
length(unique(fomd10.cfra.eth$study_id)) #200
sort(unique(fomd10.cfra.eth$out_subindicator))#40
sort(unique(fomd10.cfra.eth$out_indicator))#13

sort(unique(fomd10.cfra.eth$CT_crop_FAO_Food_Group))
sort(unique(fomd10.cfra.eth$out_subindicator[fomd10.cfra.eth$out_indicator%in%c("Costs")])) #4
sort(unique(fomd10.cfra.eth$out_subindicator[fomd10.cfra.eth$out_indicator%in%c("Economic Performance")]))#3

sort(unique(fomd10.cfra.eth$out_subindicator[fomd10.cfra.eth$out_indicator%in%c("Income")])) #3
sort(unique(fomd10.cfra.eth$out_subindicator[fomd10.cfra.eth$out_indicator%in%c("Product Yield")])) #2

# Map each indicator to its subindicators
subindicator_list<-fomd10.cfra.eth %>%
  group_by(out_indicator,out_subindicator,effect_size_type) %>%
  summarise(
    out_subindicators = list(sort(unique(out_subindicator))),
    n = n_distinct(out_subindicator)
  )

##---- Remove rows with is.na(effect_size_type) -----
fomd10.cfra.eth<-fomd10.cfra.eth%>%
  filter(!is.na(effect_size_type))

sort(unique(fomd10.cfra.eth$out_subindicator))#37
sort(unique(fomd10.cfra.eth$out_subindicator[fomd10.cfra.eth$out_indicator%in%c("Costs")]))
#"Fixed Cost"    "Labour Cost"   "Total Cost"    "Variable Cost"
sort(unique(fomd10.cfra.eth$out_subindicator[fomd10.cfra.eth$out_indicator%in%c("Economic Performance")]))
#[1] "Benefit Cost Ratio (GMVC)" "Benefit Cost Ratio (NRTC)"
sort(unique(fomd10.cfra.eth$out_subindicator[fomd10.cfra.eth$out_indicator%in%c("Income")]))
#[1] "Gross Margin" "Gross Return" "Net Return" 
nrow(fomd10.cfra.eth) #14645
length(unique(fomd10.cfra.eth$study_id)) #199

##---- Remove rows with is.na(effect_size_vi) -----
fomd10.cfra.eth<-fomd10.cfra.eth%>%
  filter(!is.na(effect_size_vi))

nrow(fomd10.cfra.eth) #13847
length(unique(fomd10.cfra.eth$study_id)) #198

sort(unique(fomd10.cfra.eth$out_subindicator))#36
sort(unique(fomd10.cfra.eth$out_indicator))

sort(unique(fomd10.cfra.eth$out_subindicator[fomd10.cfra.eth$out_indicator%in%c("Costs")]))
#[1] "Fixed Cost"    "Labour Cost"   "Total Cost"    "Variable Cost"
sort(unique(fomd10.cfra.eth$out_subindicator[fomd10.cfra.eth$out_indicator%in%c("Economic Performance")]))#2
#[1] "Benefit Cost Ratio (GMVC)" "Benefit Cost Ratio (NRTC)"
sort(unique(fomd10.cfra.eth$out_subindicator[fomd10.cfra.eth$out_indicator%in%c("Income")]))
#[1] "Gross Margin" "Gross Return" "Net Return" 
sort(unique(fomd10.cfra.eth$out_subindicator[fomd10.cfra.eth$out_indicator%in%c("Soil Quality" )]))

sort(unique(fomd10.cfra.eth$out_indicator[fomd10.cfra.eth$out_subindicator%in%c("Labour Female")]))
"Gender Equity"

sort(unique(fomd10.cfra.eth$out_subindicator[fomd10.cfra.eth$out_indicator%in%c("Non-Product Yield")]))

# Map each subindicators to practices
subindicator_practice_list<-fomd10.cfra.eth %>%
  group_by(out_indicator,out_subindicator,
           #CT_tillage_practice,
           CT_intercrop_practice,
           CT_crop_seq_practice,
           CT_agrof_practice
           #CT_irrig_practice,
           #CT_watharv_practice
           ) %>%
  distinct(out_indicator,out_subindicator,
           #CT_tillage_practice,
           CT_intercrop_practice,
           CT_crop_seq_practice,
           CT_agrof_practice,
           #CT_fert_practice,
           #CT_irrig_practice,
           #CT_watharv_practice  
           )%>%
  summarise(
    #out_subindicators = list(sort(unique(out_subindicator))),
    n = n_distinct(out_subindicator)
  )

##---- check list of practices-----
ct_practice_cols <- grep("_practice$", names(fomd10.cfra.eth), value = TRUE)

eth.practice_list <- purrr::map(ct_practice_cols, \(col) {
  fomd10.cfra.eth %>%                              
    dplyr::mutate(across(all_of(col), as.character)) %>%
    dplyr::filter(!is.na(.data[[col]])) %>%
    dplyr::count(column = col, value = .data[[col]], name = "n")
}) %>%
  dplyr::bind_rows()

#readr::write_csv(eth.practice_list, paste0(path.metadata.effectsize, "/eth.practice_list.csv"))

sort(unique(eth.practice_list$value))

# Coerce all _practicetheme columns to character
ct_theme_cols <- grep("_theme$", names(fomd10.cfra.eth), value = TRUE)

fomd10.cfra.eth <- fomd10.cfra.eth %>%
  mutate(across(all_of(ct_theme_cols), as.character))

# Now run the map safely
eth.practicetheme_list <- purrr::map(ct_theme_cols, \(col) {
  fomd10.cfra.eth %>%
    dplyr::filter(!is.na(.data[[col]])) %>%
    dplyr::count(column = col, value = .data[[col]], name = "n")
}) %>%
  dplyr::bind_rows()

readr::write_csv(eth.practicetheme_list, paste0(path.metadata.effectsize, "/eth.practicetheme_list.csv"))


# Reclassification of subindicators
subindicator_analysis<-c(
  #Biodiversity
  "Biodiversity",
  #"Economic Performance"
  "Benefit Cost Ratio (GMVC)",
  "Benefit Cost Ratio (NRTC)",
  #"Product Yield"
  "Crop Yield",
  "Crop Residue Yield",
  # "Costs"
  "Fixed Cost" ,
  "Labour Cost",
  "Total Cost",
  "Variable Cost",
  # "Income"
  "Gross Margin",
  "Gross Return",
  "Net Return" 
                         )

#fomd10.cfra.eth<-fomd10.cfra.eth%>%
#  filter(out_subindicator%in%subindicator_analysis)

nrow(fomd10.cfra.eth) #5549
length(unique(fomd10.cfra.eth$study_id)) #164

sort(unique(fomd10.cfra.eth$diversification_spatial_practice))



prueba<-fomd10.cfra.eth%>%
  #filter(out_subindicator=="Gross Margin")%>%
  filter(doi=="10.1007/s10457-018-0304-9")%>%
  
  #filter(diversification_spatial_practice=="C: Other Agroforestry_vs_T: Monoculture")%>%
  
  select(doi,diversification_spatial_subpractice,out_subindicator,C_out_mean,T_out_mean,C_out_var_value,T_out_var_value,
         C_intercrop_subpractice,"practice_compared" ,                   "practice_compared_detail" ,            "practice_compared_n")
         
         C_crop_diversity,T_crop_diversity,C_crop_FAO_Food_Group,T_crop_FAO_Food_Group,CT_crop_FAO_Food_Group)

unmatched_crops <- bind_rows(
  fomd10.cfra.eth %>% 
    select(crop = C_crop_diversity),
  fomd10.cfra.eth %>% 
    select(crop = T_crop_diversity)
) %>%
  # Split compound strings into individual tokens
  mutate(crop = str_split(crop, "[-/]")) %>%
  unnest(crop) %>%
  mutate(crop = str_squish(crop)) %>%
  filter(!is.na(crop), crop != "NA", crop != "") %>%
  distinct(crop) %>%
  # Left join to the reference to find what's missing
  left_join(
    fomd01.crops.trees %>% select(plants, FAO.Food.Group),
    by = c("crop" = "plants")
  ) %>%
  filter(is.na(FAO.Food.Group)) %>%
  arrange(crop)
sort(unique(unmatched_crops$crop))


nrow(fomd10.cfra.eth) #321
length(unique(fomd10.cfra.eth$study_id)) #20
sort(unique(fomd10.cfra.eth$effect_size_type))

##---- Reclassify effect sizes as positive or negative -----
# Log Response Ratio: positive if effect_size_vi > 0
# Standardized Mean Difference: positive if effect_size_vi > 0
fomd10.cfra.eth$effect_size_direction <- ifelse(fomd10.cfra.eth$effect_size_vi > 0, "Positive", "Negative")


sort(unique(fomd10.cfra.eth$water_management_theme))
sort(unique(fomd10.cfra.eth$nutrient_management_theme))

### Rename FAO.Food.Groups labels-----

FAO_Food_Group_labels <- c(
  "Cereals" = "Cereals",
  "Cereals..Leguminous crops"                  = "Cereals-Pulses",
  "Cereals..Oilseed crops and oleaginous fruits" = "Cereals-Oilcrops",
  "Leguminous crops"="Pulses",
  "Stimulant, spice and aromatic crops"= "Stimulants and Spice crops"
)
#-----
focal_sub_cols <- c(
  "diversification_spatial_subpractice",
  "diversification_temporal_subpractice",
  "soil_management_subpractice",
  "nutrient_management_subpractice",
  "pest_management_subpractice",
  "water_management_subpractice",
  "biomass_management_subpractice"
)

fomd10.cfra.eth <- fomd10.cfra.eth %>%
  mutate(
    active_groups = apply(across(all_of(focal_sub_cols)), 1, function(row) {
      active <- names(row)[!is.na(row)]
      active <- gsub("_subpractice", "", active)
      if (length(active) == 0) NA_character_
      else paste(active, collapse = " + ")
    })
  )

prueba0<-fomd10.cfra.eth%>% count(n_focal_groups, active_groups, sort = TRUE)




out_indicator_recla <- c(
  "Non-Product Yield"= "Yield",
  "Product Yield" = "Yield"
)

diversification_spatial_temporal_theme_recla<-c(
  "C: Monoculture_vs_T: Agroforestry; C: Monoculture_vs_T: Improved Fallow"="C: Monoculture_vs_T: Agroforestry"
)


fomd10.cfra.eth_analysis<-fomd10.cfra.eth%>%
  mutate(CT_crop_FAO_Food_Group_label = recode(CT_crop_FAO_Food_Group, !!!FAO_Food_Group_labels),
         out_indicator_recla= recode(out_indicator, !!!out_indicator_recla)
         
         )

fomd10.cfra.eth_analysis<-fomd10.cfra.eth_analysis%>%
  mutate(diversification_spatial_temporal_practice = case_when(
    !is.na(diversification_spatial_practice) & !is.na(diversification_temporal_practice) ~ 
      paste0(diversification_spatial_practice, "; ", diversification_temporal_practice),
    !is.na(diversification_spatial_practice) ~ diversification_spatial_practice,
    !is.na(diversification_temporal_practice) ~ diversification_temporal_practice,
    TRUE ~ NA_character_
  ))%>%
  mutate(diversification_spatial_temporal_theme = case_when(
    !is.na(diversification_spatial_theme) & !is.na(diversification_temporal_theme) ~ 
      paste0(diversification_spatial_theme, "; ", diversification_temporal_theme),
    !is.na(diversification_spatial_theme) ~ diversification_spatial_theme,
    !is.na(diversification_temporal_theme) ~ diversification_temporal_theme,
    TRUE ~ NA_character_
  ))%>%
  mutate(diversification_spatial_temporal_theme = recode(diversification_spatial_temporal_theme, !!!diversification_spatial_temporal_theme_recla)
  )

  

fomd10.cfra.eth_analysis<-fomd10.cfra.eth_analysis%>%
  group_by(CT_crop_FAO_Food_Group_label,
           diversification_spatial_temporal_theme,
           #diversification_spatial_temporal_practice,
           #biomass_management_practice,
           #nutrient_management_theme,
           #pest_management_practice,
           #soil_management_practice,
           #active_groups,
           #water_management_practice, #nothing to show here for now
           out_indicator_recla,
           effect_size_direction)%>%
  summarise(n_direction = n(), .groups = "drop")

raw_diversification <- fomd10.cfra.eth_analysis %>%
  group_by(CT_crop_FAO_Food_Group_label,
           diversification_spatial_temporal_theme,
           #biomass_management_practice,
           #nutrient_management_theme,
           #pest_management_practice,
           #soil_management_practice,
           #active_groups,
           #water_management_practice,#nothing to show here for now
           out_indicator_recla) %>%
  mutate(n = sum(n_direction)) %>%
  ungroup() %>%
  mutate(prop = n_direction / n) %>%
  
  # Drop n_direction BEFORE pivoting so it doesn't prevent row collapse
  select(-n_direction) %>%
  
  pivot_wider(
    names_from  = effect_size_direction,
    values_from = prop,
    values_fill = 0
  ) %>%
  
  rename(
    practice = diversification_spatial_temporal_theme,
    #diversification_temporal=diversification_temporal_theme,
    #nutrient_management=nutrient_management_theme,
    #water_management=water_management_practice,
    
    impact   = out_indicator_recla,
    pos = Positive,
    neg= Negative
  )%>%
  filter(!is.na(CT_crop_FAO_Food_Group_label))%>%
  filter(!is.na(practice))%>%
  
  filter(!practice%in%
           c("C: Agroforestry_vs_T: Agroforestry",
             "C: Crop rotation_vs_T: Crop rotation",
             "C: Intercropping_vs_T: Intercropping"
           ))%>%
  filter(CT_crop_FAO_Food_Group_label!="Stimulants and Spice crops")
  filter(diversification_spatial!="C: Agroforestry_vs_T: Monoculture"
         )%>% 
  filter(diversification_spatial!="C: Intercropping_vs_T: Monoculture")
  
  sort(unique(raw_diversification$practice))
  
head(raw)

sort(unique(raw$CT_crop_FAO_Food_Group))





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


