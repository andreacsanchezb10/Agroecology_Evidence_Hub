library(readr)
library(dplyr)
library(purrr)
library(metafor) 
library(readxl)

path.metadata.structure<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/02.metadata_structure"
path.metadata.effectsize<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/04.metadata_effectsize"

list.files(path.metadata.structure)
list.files(path.metadata.effectsize)


#==========================================================
# Read functions
#==========================================================
source(file.path(path.metadata.effectsize,"/fomd_fun/fun_mean_sd.R"))
#source(file.path(path.metadata.effectsize,"/fomd_fun/fun_load_data_ontologies.R"))
source(file.path(path.metadata.effectsize,"/fomd_fun/fun_lookup_ontologies.R")) # TO CHECK VER COMO METER LOAD DATA ONTOLOGIES DENTRO DE ESTA EQUACION
source(file.path(path.metadata.effectsize,"/fomd_fun/fun_cv_missing_calculation.R"))


#==========================================================
# Read datasets
#==========================================================
#---10_FOMD_clean
fomd10.clean<-read_csv(file.path(path.metadata.effectsize,"/fomd10_clean/fomd10_clean_MD_Rosen_24_Effec_Sc.csv"), show_col_types = FALSE)
  
#==========================================================
# Calculate Mean and Standard deviation
# From available variance values
#==========================================================
#-- Check mean metrics
sort(unique(fomd10.clean$C_out_metric))
sort(unique(fomd10.clean$T_out_metric))

#-- Check variance metrics
sort(unique(fomd10.clean$C_out_var_metric))
sort(unique(fomd10.clean$T_out_var_metric))

#---- Apply equation to calculate Mean AND SD ----
fomd10.mean.sd<-calculate_mean_sd(fomd10.clean)


# Quick checks ----
# Check for NaN in C_out_sd and T_out_sd
cols <- c("C_out_metric","C_out_value","C_out_var_metric","C_out_var_value", "C_out_sample_size","C_out_mean","C_out_sd",
          "T_out_metric","T_out_value","T_out_var_metric","T_out_var_value", "T_out_sample_size","T_out_mean","T_out_sd")

data.frame(
  column  = cols,
  n_na    = colSums(is.na(fomd10.mean.sd[, cols])),
  pct_na  = colMeans(is.na(fomd10.mean.sd[, cols])) * 100)

NA.out_sd<-fomd10.mean.sd %>%
  filter(is.na(T_out_sd)) %>%
  select(doi,
         C_out_value,C_out_var_metric, C_out_var_value, C_out_sample_size,C_out_mean,C_out_sd,
         T_out_value,T_out_var_metric, T_out_var_value, T_out_sample_size, T_out_mean,T_out_sd)
nrow(NA.out_sd) #is.na(C_out_sd) 183,744
nrow(NA.out_sd) #is.na(T_out_sd) 183434



#==========================================================
# Calculate Standard deviation
# From observations that don't provide variance values
#==========================================================
product.mismatches<- fomd10.mean.sd %>%
  filter(C_product_simple != T_product_simple)


dt_result <- cv_calculation(
  dt               = fomd10.mean.sd,                       # your original dataframe
  rules            = outcome_grouping_rules,
  outcome_col      = "out_subindicator"        # default, can omit if same name
)
prueba<-dt_result%>%
  select(authors,doi,"C_product","T_product",T_product_simple,C_product_simple, out_subindicator,T_out_sample_size,382:396)%>%
  filter(out_subindicator%in%c("Crop Yield", "Biomass Yield", "Gross Return"))%>%
  filter(C_product_simple==T_product_simple)%>%
  filter(T_product_simple=="Maize")
filter(is.na(C_out_cv_filled))
names(dt_result)

readr::write_csv(prueba, paste0(path.metadata.effectsize, "/prueba.csv"))

dt_result
NA.out_sd<-dt_result %>%
  filter(is.na(C_out_cv_filled))
nrow(NA.out_sd) #is.na(C_out_sd) 157,316
nrow(NA.out_sd) #is.na(T_out_sd) 157,316


sort(unique(fomd10.clean$T_out_metric))

#==========================================================
# Reclassifying out_subindicator as effect_size_type
#==========================================================
sort(unique(fomd10.effect.size$out_subindicator))

fomd10.effect.size <- apply_lookup_ontologies(
  df        = fomd10.effect.size,
  ref       = fomd01.outcomes,
  key_col   = "subindicator",
  value_col = "effect_size_type",
  src_col   = "out_subindicator",
  new_col   = "effect_size_type"
)


x<-fomd10.effect.size %>%
  #select(doi,out_subindicator, out_effect_size) 
  distinct(out_subindicator, effect_size_type)%>%
  arrange(effect_size_type)%>%
  filter(is.na(effect_size_type)) #93-73 out_subindicator with effect_size_type==NA


#==========================================================
# Calculate Effect sizes 
#==========================================================
#--------- Calculate Log Response Ratio ------------
## THIS IS TEMPORARY, JUST FOR THE CFRA ANALYSIS, LATER I NEED TO IMPLEMENT A EQUATION
## TO CHECK: there are negative yield values, see what to do here!

## First: Replace the C_out_mean==0 and T_out_mean==0 by 0.00001

fomd10.effect.size<-fomd10.effect.size%>%
    mutate(C_out_mean=case_when(C_out_mean==0 & effect_size_type=="Log Response Ratio"~0.00001,TRUE~C_out_mean),
           T_out_mean=case_when(T_out_mean==0 & effect_size_type=="Log Response Ratio"~0.00001,TRUE~T_out_mean))%>%
  mutate(
    effect_size_vi=case_when( 
      (!is.na(C_out_mean)& !is.na(T_out_mean) &effect_size_type=="Log Response Ratio")~log(T_out_mean/C_out_mean),
      TRUE~NA))

#--------- Calculate Standardized Mean Difference ------------

  
fomd10.effect.size<-fomd10.effect.size%>%
  #mutate(C_out_mean=case_when(C_out_mean==0 & effect_size_type=="Log Response Ratio"~0.00001,TRUE~C_out_mean),
  #       T_out_mean=case_when(T_out_mean==0 & effect_size_type=="Log Response Ratio"~0.00001,TRUE~T_out_mean))%>%
  
  mutate(
    effect_size_vi=case_when( 
      (!is.na(C_out_mean)&
          !is.na(T_out_mean) &
          !is.na(C_out_sd)&
          !is.na(T_out_sd)&
          !is.na(C_out_sample_size)&
          !is.na(T_out_sample_size)&
          effect_size_type=="Standardized Mean Difference")~
        (T_out_mean - C_out_mean) / (sqrt(((T_out_sample_size-1)*T_out_sd^2 + (C_out_sample_size-1)*C_out_sd^2) / (T_out_sample_size+C_out_sample_size-2))),
      TRUE~effect_size_vi))  

readr::write_csv(fomd10.effect.size, paste0(path.metadata.effectsize, "/fomd10_effect_size.csv"))
  

# Quick checks
    select(doi,country,effect_size_type,out_subindicator,C_out_mean,T_out_mean,effect_size_vi,C_data_location)%>%
    #filter(doi=="10.1016/j.fcr.2022.108788")
    filter(effect_size_type=="Log Response Ratio")
    filter(is.na(effect_size_vi))%>%
    filter(out_subindicator=="Crop Yield")




 ##############################################################

