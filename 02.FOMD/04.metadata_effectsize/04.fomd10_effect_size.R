library(readr)
library(dplyr)
library(purrr)
library(metafor) 
library(readxl)
library(metafor)
path.metadata.structure<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/02.metadata_structure"
path.metadata.effectsize<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/04.metadata_effectsize"

list.files(path.metadata.structure)
list.files(path.metadata.effectsize)


#==========================================================
# Read functions
#==========================================================
source(file.path(path.metadata.effectsize,"/fomd_fun/fun_mean_sd_calculation.R"))
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

#---- Replace mean==0 to mean=0.0001 ----
# This step is to avoid Inf values when calculating CV
fomd10.mean.sd <- fomd10.mean.sd %>%
  mutate(
    T_out_mean = if_else(T_out_mean == 0, 0.00001, T_out_mean),
    C_out_mean = if_else(C_out_mean == 0, 0.00001, C_out_mean)
  )

#==========================================================
# Calculate CV and number of samples
# From observations that don't provide variance values or number of samples
#==========================================================
nrow(fomd10.mean.sd[fomd10.mean.sd$C_out_sd == "", ]) #183744
nrow(fomd10.mean.sd[fomd10.mean.sd$T_out_sd == "", ]) #183434

nrow(fomd10.mean.sd[which(is.na(fomd10.mean.sd$C_out_sd)), ]) #183744
nrow(fomd10.mean.sd[which(is.na(fomd10.mean.sd$T_out_sd)), ]) #183434

sort(unique(fomd10.mean.sd$out_subindicator[fomd10.mean.sd$out_indicator == "Product Yield" ])) #9

product.mismatches<- fomd10.mean.sd %>%
  filter(out_subindicator%in%c(
    "Crop Yield", "Biomass Yield","Egg Yield","Meat Yield",
    "Milk Yield","Other Animal Product Yield","Reproductive Yield", "Weight Gain",
                               "Gross Return"                        ))%>%
  filter(C_product_simple != T_product_simple)%>%
  select(study_id,out_subindicator,C_product_simple,T_product_simple)

fomd10.n.cv <- n_cv_calculation(
  dt               = fomd10.mean.sd,                       
  rules            = outcome_grouping_rules,
  outcome_col      = "out_subindicator")

fomd10.n.cv <- fomd10.n.cv%>%
  mutate(
    T_out_sample_size_imputed = coalesce(T_out_sample_size, T_out_sample_size_imputed),
    C_out_sample_size_imputed = coalesce(C_out_sample_size, C_out_sample_size_imputed))

nrow(fomd10.n.cv[which(is.na(fomd10.n.cv$C_out_cv_final)), ])#151013
nrow(fomd10.n.cv[which(fomd10.n.cv$C_out_cv_final == "Inf"), ])#0

nrow(fomd10.n.cv[which(is.na(fomd10.n.cv$T_out_cv_final)), ])#151013
nrow(fomd10.n.cv[which(fomd10.n.cv$T_out_cv_final == "Inf"), ])#0

# Quick checks -----
imp_vars <- fomd10.mean.sd %>%
  filter(out_subindicator %in% outcome_grouping_rules[[1]]$outcomes) %>%
  select(T_out_sample_size, C_out_sample_size, T_out_mean, C_out_mean,
         all_of(outcome_grouping_rules[[1]]$grouping_vars))

imp <- mice(imp_vars, method = "pmm", m = 20, seed = 123)

imp$loggedEvents
imp_vars %>% count(out_subindicator)

names(fomd10.n.cv)

prueba<-fomd10.n.cv%>%
  select(doi,"C_product","T_product",T_product_simple,C_product_simple, 
         out_subindicator,C_out_sample_size,T_out_sample_size,382:397)
  filter(out_subindicator%in%c("Crop Yield", "Biomass Yield", "Gross Return"))%>%
  filter(C_product_simple==T_product_simple)%>%
  filter(T_product_simple=="Maize")
filter(is.na(C_out_cv_filled))
names(fomd10.n.cv)


# Check for NaN in C_out_sd and T_out_sd
cols <- c("C_out_metric","C_out_value","C_out_var_metric","C_out_var_value", "C_out_sample_size",
          "C_out_mean","C_out_sd","C_out_sample_size_imputed","C_out_cv_group_avg","C_out_cv_final",
          "T_out_metric","T_out_value","T_out_var_metric","T_out_var_value", "T_out_sample_size",
          "T_out_mean","T_out_sd","T_out_sample_size_imputed","T_out_cv_group_avg","T_out_cv_final")

data.frame(
  column  = cols,
  n_na    = colSums(is.na(fomd10.n.cv[, cols])),
  pct_na  = colMeans(is.na(fomd10.n.cv[, cols])) * 100)

#                                              column   n_na       pct_na
#C_out_metric                           C_out_metric      0  0.000000000
#C_out_value                             C_out_value   1075  0.462849344
#C_out_var_metric                   C_out_var_metric 183067 78.820875151
#C_out_var_value                     C_out_var_value 183067 78.820875151
#C_out_sample_size                 C_out_sample_size  12722  5.477552883
#C_out_mean                               C_out_mean   1075  0.462849344
#C_out_sd                                   C_out_sd 183744 79.112362598
#C_out_sample_size_imputed C_out_sample_size_imputed   9690 59.506064403
#C_out_cv_group_avg               C_out_cv_group_avg 151013 65.019784118
#C_out_cv_final                       C_out_cv_final 151013 65.019784118
#T_out_metric                           T_out_metric      0  0.000000000
#T_out_value                             T_out_value      6  0.002583345
#T_out_var_metric                   T_out_var_metric 182996 78.790305567
#T_out_var_value                     T_out_var_value 182996 78.790305567
#T_out_sample_size                 T_out_sample_size  12722  5.477552883
#T_out_mean                               T_out_mean      6  0.002583345
#T_out_sd                                   T_out_sd 183434 78.978889764
#T_out_sample_size_imputed T_out_sample_size_imputed   9690 59.506064403
#T_out_cv_group_avg               T_out_cv_group_avg 151013 65.019784118
#T_out_cv_final                       T_out_cv_final 151013 65.019784118

#readr::write_csv(prueba, paste0(path.metadata.effectsize, "/prueba.csv"))


#==========================================================
# Checking out_subindicators with effect_size_type
#==========================================================
sort(unique(fomd10.n.cv$out_subindicator))#121
sort(unique(fomd10.n.cv$out_indicator))#16
sort(unique(fomd10.n.cv$effect_size_type))

sort(unique(fomd10.n.cv$out_subindicator[is.na(fomd10.n.cv$effect_size_type )]))#72
sort(unique(fomd10.n.cv$out_subindicator[fomd10.n.cv$effect_size_type == "Log Response Ratio" ]))#46
sort(unique(fomd10.n.cv$out_subindicator[fomd10.n.cv$effect_size_type == "Standardized Mean Difference" ]))#3
#"Gross Margin"            "Marginal Rate of Return" "Net Return"

missing.effect.size.type<-fomd10.n.cv %>%
  #select(doi,out_subindicator, out_effect_size) 
  distinct(out_subindicator, effect_size_type)%>%
  arrange(effect_size_type)%>%
  filter(is.na(effect_size_type)) #93-72 out_subindicator with effect_size_type==NA

#==========================================================
# Calculate Effect sizes 
#==========================================================
#--------- Calculate Log Response Ratio ------------
## THIS IS TEMPORARY, JUST FOR THE CFRA ANALYSIS, LATER I NEED TO IMPLEMENT A EQUATION
## TO CHECK: there are negative yield values, see what to do here!

## First: Replace the C_out_mean==0 and T_out_mean==0 by 0.00001
names(fomd10.n.cv)

library(metafor)

fomd10.lRR.effectsize<-
  escalc(measure = "ROM", m1i= T_out_sd, m2i= C_out_sd,
       sd1i= T_out_mean,sd2i= C_out_mean,
       n1i= T_out_sample_size_imputed, n2i= C_out_sample_size_imputed, 
       data= fomd10.n.cv, 
       var.names=c("lnRR","lnRR_var"),
       vtype="LS",digits=4)

fomd10.effectsize <- fomd10.n.cv %>%
  filter(effect_size_type=="Log Response Ratio")%>%
  filter(T_out_sd<0)%>%
  select(doi,"C_product","T_product",T_product_simple,C_product_simple, 
         out_subindicator,C_out_sample_size,
         C_out_var_metric,C_out_var_value,
         T_out_var_metric,T_out_var_value,

         T_out_sample_size,382:397)

sort(unique(fomd10.effectsize$T_out_sd))

  mutate(
    rom = escalc(measure = "ROM",
                 m1i = T_out_mean, m2i = C_out_mean,
                 sd1i = T_out_sd,  sd2i = C_out_sd,
                 n1i = T_out_sample_size_imputed, n2i = C_out_sample_size_imputed,
                 data = ., vtype = "LS", digits = 4)
  )


var.names=c("Financial_mean","Financial_var")


fomd10.effectsize<-fomd10.n.cv%>%
%>%
mutate(
  


  
  case_when(
  #Use the lRR values already calculated using the cv_final values
  effect_size_type=="Log Response Ratio"& !is.na(lnRR_cv_final)~lnRR_cv_final,
  #Calculate lRR for the other rows
  effect_size_type=="Log Response Ratio"& is.na(lnRR_cv_final)~
    ,
    
  
  TRUE~NA))
  
  

  
  
)






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

