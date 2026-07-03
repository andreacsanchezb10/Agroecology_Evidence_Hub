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
source(file.path(path.metadata.effectsize,"/fomd_fun/fun_lookup_commodities.R")) 


#==========================================================
# Read datasets
#==========================================================
#---fomd10.effect.size
fomd10.effect.size<-read_csv(file.path(path.metadata.effectsize,"/fomd10_effect_size.csv"), show_col_types = FALSE)

nrow(fomd10.effect.size) #232257


#==========================================================
#--- 1. Filter only relevant CFRA countries-----
sort(unique(fomd10.effect.size$country))

# CFRA countries
cfra.country.names<-c(
  #"Angoloa",
  #"Burundi",
  "Ethiopia",
  "Kenya",
  #"Malawi",
  #"Rwanda",
  #"Tanzania",
  #"Uganda",
  "Zambia")

#pattern.countries <- paste(cfra.countries, collapse = "|")

# Filter rows where country contains any of the target countries
fomd10.cfra <- fomd10.effect.size %>%
  filter(country %in% cfra.country.names)
  
  #filter(grepl(pattern.countries, country, ignore.case = TRUE))

sort(unique(fomd10.cfra$country))
sort(unique(fomd10.cfra$C_site_latitude))
sort(unique(fomd10.cfra$T_site_latitude))

#==========================================================
#--- 2. Remove Animal related out_subindicators-------
removed.subindicators<-c("Animal Survival" ,
                         "Animal Mortality" ,
                         "Daily Average Weight Gain",
                         "Egg Yield",
                         "Feed Conversion Ratio (In Out)",
                         "Feed Conversion Ratio (Out In)",
                         "Feed Intake"  ,
                         "Fixed Cost-Animals Purchase",
                         "Final Body Weight",
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

sort(unique(fomd10.cfra$out_subindicator)) #56
sort(unique(fomd10.cfra$out_subindicator[fomd10.cfra$out_pillar== "Mitigation"])) 
sort(unique(fomd10.cfra$out_subindicator[fomd10.cfra$out_pillar== "Productivity"])) 
sort(unique(fomd10.cfra$out_subindicator[fomd10.cfra$out_pillar== "Resilience"])) 
sort(unique(fomd10.cfra$out_subindicator[is.na(fomd10.cfra$out_pillar)])) 

#https://caliper.integratedmodelling.org/caliper/browse/showvoc/#/datasets/WCA2020_Crops/unknown/data?resId=https:%2F%2Fstats.fao.org%2Fclassifications%2FWCA2020%2Fcrops%2FBasil
#https://caliper.integratedmodelling.org/caliper/browse/showvoc/#/datasets/ICC1_0/unknown/data?resId=https:%2F%2Fstats.fao.org%2Fclassifications%2FICC%2Fv1.0%2F931

sort(unique(fomd10.cfra$T_crop_tree_diversity)) #51
sort(unique(fomd10.cfra$T_crop_tree_diversity[fomd10.cfra$T_crop_tree_diversity== "Acacia decurrens-Teff/Acacia decurrens-Unspecified Fodder Grass/Acacia decurrens/Acacia decurrens/Acacia decurrens" ])) 

#==========================================================
#--- 3. Remove animal related rows-----
fomd10.cfra <- fomd10.cfra %>%
  filter(!is.na(C_crop_tree_density))

nrow(fomd10.cfra) #33848
length(unique(fomd10.cfra$study_id)) #321

unmatched_crops <- bind_rows(
  fomd10.cfra %>% 
    select(crop = C_crop_tree_diversity),
  fomd10.cfra %>% 
    select(crop = T_crop_tree_diversity)
) %>%
  # Split compound strings into individual tokens
  mutate(crop = str_split(crop, "[-/]")) %>%
  unnest(crop) %>%
  mutate(crop = str_squish(crop)) %>%
  filter(!is.na(crop), crop != "NA", crop != "") %>%
  distinct(crop) %>%
  # Left join to the reference to find what's missing
  left_join(
    fomd01.crops.trees %>% select(crop_tree_diversity, FAO.Food.Group),
    by = c("crop" = "crop_tree_diversity")
  ) %>%
  filter(is.na(FAO.Food.Group)) %>%
  arrange(crop)
sort(unique(unmatched_crops$crop))

#==========================================================
#--- 4. Reclassify crops ------
sort(unique(fomd10.cfra$CT_crop_FAO_Food_SubGroup))

commodity_rules <- tribble(
  ~trigger,                                  ~old,                                     ~new,
  # Spices & aromatic crops
  "Other permanent spice and aromatic crops", "Stimulant, spice and aromatic crops",   "Spice and aromatic crops",
  "Temporary spice and aromatic crops",      "Stimulant, spice and aromatic crops",   "Spice and aromatic crops",
  
  # Stimulant crops
  "Stimulant crops","Stimulant, spice and aromatic crops","Stimulant crops",
  
  # Fruits
  "Tropical and subtropical fruits", "Fruit and nuts","Fruits"
)
# Start with a copy of the original column
fomd10.cfra <- fomd10.cfra %>%
  mutate(T_crop_FAO_Food_Group_clean = T_crop_FAO_Food_Group,
         CT_crop_FAO_Food_Group_clean= CT_crop_FAO_Food_Group)

# Apply each rule in sequence
for (i in seq_len(nrow(commodity_rules))) {
  trig <- commodity_rules$trigger[i]
  old  <- commodity_rules$old[i]
  new  <- commodity_rules$new[i]
  
  fomd10.cfra <- fomd10.cfra %>%
    mutate(
      T_crop_FAO_Food_Group_clean = if_else(
        str_detect(T_crop_FAO_Food_SubGroup, fixed(trig)),
        str_replace(T_crop_FAO_Food_Group_clean, fixed(old), new),
        T_crop_FAO_Food_Group_clean
      )
    )
}

# Apply each rule in sequence
for (i in seq_len(nrow(commodity_rules))) {
  trig <- commodity_rules$trigger[i]
  old  <- commodity_rules$old[i]
  new  <- commodity_rules$new[i]
  
  fomd10.cfra <- fomd10.cfra %>%
    mutate(
      CT_crop_FAO_Food_Group_clean = if_else(
        str_detect(CT_crop_FAO_Food_SubGroup, fixed(trig)),
        str_replace(CT_crop_FAO_Food_Group_clean, fixed(old), new),
        CT_crop_FAO_Food_Group_clean
      )
    )
}

sort(unique(fomd10.cfra$CT_crop_FAO_Food_Group_clean))

#==========================================================
#--- 5. Practices 
#==========================================================
focal_sub_cols <- c(
  #"variety_management_subpractice",
  #"breed_animal_subpractice",
  #"planting_management_subpractice",
  "diversification_spatial_subpractice",
  "diversification_temporal_subpractice",
  "soil_management_subpractice",
  "nutrient_management_subpractice",
  #"pest_management_subpractice",
  "water_management_subpractice",
  "biomass_management_subpractice"
)
practice_sub_cols <- c(
  "variety_management_subpractice",
  #"breed_animal_subpractice",
  "planting_management_subpractice",
  "diversification_spatial_subpractice",
  "diversification_temporal_subpractice",
  "soil_management_subpractice",
  "nutrient_management_subpractice",
  "pest_management_subpractice",
  "water_management_subpractice",
  "biomass_management_subpractice"
)

fomd10.cfra <- fomd10.cfra %>%
  mutate(
    active_groups = apply(across(all_of(focal_sub_cols)), 1, function(row) {
      active <- names(row)[!is.na(row)]
      active <- gsub("_subpractice", "", active)
      if (length(active) == 0) NA_character_
      else paste(sort(active), collapse = "..")
    })
  )%>%
  mutate(
    practice_groups = apply(across(all_of(practice_sub_cols)), 1, function(row) {
      active <- names(row)[!is.na(row)]
      active <- gsub("_subpractice", "", active)
      if (length(active) == 0) NA_character_
      else paste(sort(active), collapse = "..")
    })
  )
  
  filter(!is.na(active_groups))

# Reclassify themes, practices and subpractices
sort(unique(fomd10.cfra$diversification_spatial_subpractice))


length(unique(fomd10.cfra$study_id)) #321

nrow(fomd10.cfra) #33848

#==========================================================
#--- Report DEEP-DIVE COUNTRIES:
#--- ETHIOPIA, KENYA, ZAMBIA
#==========================================================
sort(unique(fomd10.cfra$water_management_subpractice))
sort(unique(fomd10.cfra$biomass_management_subpractice))
sort(unique(fomd10.cfra$soil_management_subpractice))
sort(unique(fomd10.cfra$active_groups))

#---- CEREALS----
sort(unique(fomd10.cfra$CT_crop_FAO_Food_Group_clean))
cereals.df<-fomd10.cfra%>%
  filter(grepl("Cereals", CT_crop_FAO_Food_Group_clean))%>%
  #filter(grepl(paste(patterns, collapse = "|"), active_groups))%>%
  filter(!is.na(active_groups))%>%
  filter(country=="Ethiopia")
  
sort(unique(cereals.df$out_subindicator))
  
sort(unique(cereals.df$nutrient_management_theme))
sort(unique(cereals.df$nutrient_management_subpractice))
sort(unique(cereals.df$nutrient_management_practice))

sort(unique(cereals.df$water_management_subpractice))

  
sort(unique(cereals.df$diversification_temporal_theme))
sort(unique(cereals.df$diversification_temporal_subpractice))
sort(unique(cereals.df$diversification_temporal_practice))
  
sort(unique(cereals.df$diversification_spatial_subpractice))
sort(unique(cereals.df$diversification_spatial_practice))
sort(unique(cereals.df$diversification_spatial_theme))
  
sort(unique(cereals.df$CT_crop_FAO_Food_Group_clean))
sort(unique(cereals.df$T_crop_tree_diversity))
sort(unique(cereals.df$active_groups))

sort(unique(cereals.df$soil_management_theme))
sort(unique(cereals.df$soil_management_subpractice))
sort(unique(cereals.df$soil_management_practice))

sort(unique(cereals.df$biomass_management_subpractice))
sort(unique(cereals.df$biomass_management_practice))
sort(unique(cereals.df$biomass_management_subpractice))

cereals.df1<-cereals.df%>%
  mutate(diversification_spatial_temporal_theme = case_when(
  !is.na(diversification_spatial_theme) & !is.na(diversification_temporal_theme) ~ 
    paste0(diversification_spatial_theme, "; ", diversification_temporal_theme),
  !is.na(diversification_spatial_theme) ~ diversification_spatial_theme,
  !is.na(diversification_temporal_theme) ~ diversification_temporal_theme,
  TRUE ~ NA_character_
))%>%
  mutate(diversification_spatial_temporal_practice = case_when(
    !is.na(diversification_spatial_practice) & !is.na(diversification_temporal_practice) ~ 
      paste0(diversification_spatial_practice, "; ", diversification_temporal_practice),
    !is.na(diversification_spatial_practice) ~ diversification_spatial_practice,
    !is.na(diversification_temporal_practice) ~ diversification_temporal_practice,
    TRUE ~ NA_character_
  ))
 
sort(unique(cereals.df1$diversification_spatial_temporal_practice))

#cereals.df1$effect_size_direction <- ifelse(cereals.df1$effect_size_vi > 0, "Positive", "Negative")

cereals.df1<-cereals.df1%>%
  
  mutate(effect_size_direction=case_when(
    effect_size_vi > 0~ "Positive",
    effect_size_type=="Standardized Mean Difference" &
      T_out_value>C_out_value~ "Positive",
    TRUE~"Negative"
    
  ))

#readr::write_csv(cereals.df1, paste0(path.metadata.effectsize, "/cereals.df1.csv"))

cereals.df1_analysis<-cereals.df1%>%
  group_by(CT_crop_FAO_Food_Group_clean,
           diversification_spatial_temporal_theme,
           #diversification_spatial_temporal_practice,
           biomass_management_practice,
           nutrient_management_practice,
           #pest_management_practice,
           soil_management_theme,
           active_groups,
           water_management_practice,
           out_indicator,
           effect_size_direction)%>%
  summarise(n_direction = n(), .groups = "drop")

sort(unique(cereals.df1_analysis$out_indicator))

raw_diversification <- cereals.df1_analysis %>%
  group_by(CT_crop_FAO_Food_Group_clean,
           diversification_spatial_temporal_theme,
           biomass_management_practice,
           nutrient_management_practice,
           #pest_management_practice,
           soil_management_theme,
           active_groups,
           #water_management_practice,#nothing to show here for now
           out_indicator) %>%
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
   # practice = diversification_spatial_temporal_theme,
    #diversification_temporal=diversification_temporal_theme,
    #nutrient_management=nutrient_management_theme,
    #water_management=water_management_practice,
    
    impact   = out_indicator,
    pos = Positive,
    neg= Negative
  )
  filter(!is.na(practice))
  
  


readr::write_csv(raw_diversification, paste0(path.metadata.effectsize, "/cereals_effects_eth.csv"))



#---- COMMON BEAN -----







#==========================================================
#--- Report DEEP-DIVE COUNTRIES:
#--- ETHIOPIA, KENYA, ZAMBIA
#==========================================================
sort(unique(fomd10.cfra$effect_size_type))

##---- Filter country == Deep dive -----
fomd10.cfra.ddc<- fomd10.cfra%>%
  filter(country=="Ethiopia"|
           country== "Kenya"|
           country=="Zambia")


nrow(fomd10.cfra.ddc) #30850
length(unique(fomd10.cfra.ddc$study_id)) #297
sort(unique(fomd10.cfra.ddc$out_subindicator))#47
sort(unique(fomd10.cfra.ddc$out_indicator))#13

sort(unique(fomd10.cfra.ddc$CT_crop_FAO_Food_Group))
sort(unique(fomd10.cfra.ddc$out_subindicator[fomd10.cfra.ddc$out_indicator%in%c("Costs")])) #4
sort(unique(fomd10.cfra.ddc$out_subindicator[fomd10.cfra.ddc$out_indicator%in%c("Economic Performance")]))#3

sort(unique(fomd10.cfra.ddc$out_subindicator[fomd10.cfra.ddc$out_indicator%in%c("Income")])) #3
sort(unique(fomd10.cfra.ddc$out_subindicator[fomd10.cfra.ddc$out_indicator%in%c("Product Yield")])) #3

# Map each indicator to its subindicators
subindicator_list<-fomd10.cfra.ddc %>%
  group_by(out_indicator,out_subindicator,effect_size_type) %>%
  summarise(
    out_subindicators = list(sort(unique(out_subindicator))),
    n = n_distinct(out_subindicator)
  )

##---- Remove rows with is.na(effect_size_type) -----
fomd10.cfra.ddc<-fomd10.cfra.ddc%>%
  filter(!is.na(effect_size_type))

sort(unique(fomd10.cfra.ddc$out_subindicator))#37
sort(unique(fomd10.cfra.ddc$out_subindicator[fomd10.cfra.ddc$out_indicator%in%c("Costs")]))
#"Fixed Cost"    "Labour Cost"   "Total Cost"    "Variable Cost"
sort(unique(fomd10.cfra.ddc$out_subindicator[fomd10.cfra.ddc$out_indicator%in%c("Economic Performance")]))
#[1] "Benefit Cost Ratio (GMVC)" "Benefit Cost Ratio (NRTC)"
sort(unique(fomd10.cfra.ddc$out_subindicator[fomd10.cfra.ddc$out_indicator%in%c("Income")]))
#[1] "Gross Margin" "Gross Return" "Net Return" 
nrow(fomd10.cfra.ddc) #14645
length(unique(fomd10.cfra.ddc$study_id)) #199

##---- Remove rows with is.na(effect_size_vi) -----
fomd10.cfra.ddc<-fomd10.cfra.ddc%>%
  filter(!is.na(effect_size_vi))

nrow(fomd10.cfra.ddc) #29598
length(unique(fomd10.cfra.ddc$study_id)) #1295

sort(unique(fomd10.cfra.ddc$out_subindicator))#36
sort(unique(fomd10.cfra.ddc$out_indicator))#12

sort(unique(fomd10.cfra.ddc$out_subindicator[fomd10.cfra.ddc$out_indicator%in%c("Costs")]))
#[1] "Fixed Cost"    "Labour Cost"   "Total Cost"    "Variable Cost"
sort(unique(fomd10.cfra.ddc$out_subindicator[fomd10.cfra.ddc$out_indicator%in%c("Economic Performance")]))#2
#[1] "Benefit Cost Ratio (GMVC)" "Benefit Cost Ratio (NRTC)"
sort(unique(fomd10.cfra.ddc$out_subindicator[fomd10.cfra.ddc$out_indicator%in%c("Income")]))
#[1] "Gross Margin" "Gross Return" "Net Return" 
sort(unique(fomd10.cfra.ddc$out_subindicator[fomd10.cfra.ddc$out_indicator%in%c("Soil Quality" )]))

sort(unique(fomd10.cfra.ddc$out_indicator[fomd10.cfra.ddc$out_subindicator%in%c("Labour Female")]))
#"Gender Equity"

sort(unique(fomd10.cfra.ddc$out_subindicator[fomd10.cfra.ddc$out_indicator%in%c("Non-Product Yield")]))

# Map each subindicators to practices
subindicator_practice_list<-fomd10.cfra.ddc %>%
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

##---- Reclassify effect sizes as positive or negative -----
# Log Response Ratio: positive if effect_size_vi > 0
# Standardized Mean Difference: positive if effect_size_vi > 0
fomd10.cfra.ddc$effect_size_direction <- ifelse(fomd10.cfra.ddc$effect_size_vi > 0, "Positive", "Negative")


sort(unique(fomd10.cfra.ddc$water_management_theme))
sort(unique(fomd10.cfra.ddc$nutrient_management_theme))

### Rename FAO.Food.Groups labels-----

FAO_Food_Group_labels <- c(
  "Cereals" = "Cereals",
  "Cereals..Leguminous crops"                  = "Cereals-Legumes",
  "Leguminous crops"="Legumes",
  "Oilseed crops and oleaginous fruits"="Oilseed crops",
  "Root tuber crops with high starch or inulin content"= "Root tuber crops",
  "Vegetables and melons"   =  "Vegetables"
  
)

out_indicator_recla <- c(
  "Non-Product Yield"= "Yield",
  "Product Yield" = "Yield"
)

diversification_spatial_temporal_theme_recla<-c(
  "C: Monoculture_vs_T: Agroforestry; C: Monoculture_vs_T: Improved Fallow"="C: Monoculture_vs_T: Agroforestry",
  "C: Monoculture_vs_T: Agroforestry; C: Crop rotation_vs_T: Crop rotation"="C: Monoculture_vs_T: Agroforestry",
  "C: Monoculture_vs_T: Agroforestry; C: Monoculture_vs_T: Crop rotation"="C: Monoculture_vs_T: Agroforestry",
  "C: Monoculture_vs_T: Intercropping + Green manure"="C: Monoculture_vs_T: Intercropping"
  )

fomd10.cfra.ddc_analysis<-fomd10.cfra.ddc%>%
  mutate(CT_crop_FAO_Food_Group_label = recode(CT_crop_FAO_Food_Group, !!!FAO_Food_Group_labels),
         out_indicator_recla= recode(out_indicator, !!!out_indicator_recla))

fomd10.cfra.ddc_analysis<-fomd10.cfra.ddc_analysis%>%
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



fomd10.cfra.ddc_analysis<-fomd10.cfra.ddc_analysis%>%
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

raw_diversification <- fomd10.cfra.ddc_analysis %>%
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





############
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
  filter(country=="Ethiopia"|
           country== "Kenya"|
           country=="Zambia")


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
    select(crop = C_crop_tree_diversity),
  fomd10.cfra.eth %>% 
    select(crop = T_crop_tree_diversity)
) %>%
  # Split compound strings into individual tokens
  mutate(crop = str_split(crop, "[-/]")) %>%
  unnest(crop) %>%
  mutate(crop = str_squish(crop)) %>%
  filter(!is.na(crop), crop != "NA", crop != "") %>%
  distinct(crop) %>%
  # Left join to the reference to find what's missing
  left_join(
    fomd01.trees.crops %>% select(crop_tree_diversity, FAO.Food.Group),
    by = c("crop" = "crop_tree_diversity")
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


