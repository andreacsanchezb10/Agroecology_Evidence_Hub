library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(readr)
library(tibble)
library(purrr)

path.metadata.effectsize<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/04.metadata_effectsize/"
path.meta.analysis<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/05.meta_analysis/idrc-cfra_analysis/"

#==========================================================
# Read datasets
#==========================================================
#---fomd10.effect.size
fomd10<-read_csv(file.path(path.metadata.effectsize,"04.fomd10_effect_size/fomd10_effect_size.csv"), show_col_types = FALSE)
nrow(fomd10) #232257; 192519
sort(unique(fomd10$country))


#==========================================================
#--- Report DEEP-DIVE COUNTRIES:
#--- ETHIOPIA - CEREALS
#==========================================================
sort(unique(fomd10.cfra$water_management_subpractice))
sort(unique(fomd10.cfra$biomass_management_subpractice))
sort(unique(fomd10.cfra$soil_management_subpractice))
sort(unique(fomd10.cfra$active_groups))

#---- CEREALS----
sort(unique(fomd10.cfra$CT_crop_tree_FAO_Food_Group_clean))
cereals.df<-fomd10.cfra%>%
  filter(grepl("Cereals", CT_crop_tree_FAO_Food_Group_clean))%>%
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

sort(unique(cereals.df$CT_crop_tree_FAO_Food_Group_clean))
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


cereals.df1<-cereals.df1%>%
  
  mutate(effect_size_direction=case_when(
    out_subindicator %in% c("Erosion", "Runoff") &
      effect_size_type == "Log Response Ratio" &
      effect_size_vi < 0 ~ "Positive",
    
    out_subindicator %in% c("Erosion", "Runoff") &
      effect_size_type == "Log Response Ratio" &
      effect_size_vi > 0 ~ "Negative",
    
    effect_size_vi > 0~ "Positive",
    effect_size_type=="Standardized Mean Difference" &
      T_out_value>C_out_value~ "Positive",
    TRUE~"Negative"
    
  ))

readr::write_csv(cereals.df1, paste0(path.metadata.effectsize, "/cereals_df_eth.csv"))

sort(unique(cereals.df1$out_indicator))
sort(unique(cereals.df1$out_subindicator[cereals.df1$out_indicator== "Efficiency"])) 

sort(unique(cereals.df1$out_subindicator[cereals.df1$out_indicator== "Soil Quality"])) 
sort(unique(cereals.df1$effect_size_type[cereals.df1$out_subindicator== "Runoff"])) 


cereals.df1_analysis<-cereals.df1%>%
  group_by(CT_crop_tree_FAO_Food_Group_clean,
           diversification_spatial_temporal_theme,
           biomass_management_practice,
           nutrient_management_practice,
           soil_management_theme,
           active_groups,
           water_management_practice,
           out_indicator,
           out_subindicator,
           effect_size_direction)%>%
  summarise(n_direction = n(), .groups = "drop")

sort(unique(cereals.df1_analysis$out_indicator))

raw_diversification <- cereals.df1_analysis %>%
  group_by(CT_crop_tree_FAO_Food_Group_clean,
           diversification_spatial_temporal_theme,
           biomass_management_practice,
           nutrient_management_practice,
           #pest_management_practice,
           soil_management_theme,
           active_groups,
           #water_management_practice,#nothing to show here for now
           out_indicator
           #out_subindicator
  ) %>%
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

readr::write_csv(raw_diversification, paste0(path.metadata.effectsize, "/cereals_effects_eth.csv"))



#---- PULSES -----