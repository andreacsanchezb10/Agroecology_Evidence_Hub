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
source(file.path(path.metadata.effectsize,"/fomd_fun/fun_effect_sizes_calculation.R"))

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
## To calculate LOG RESPONSE RATIO effect size -> zero values have to be replaced by 0.0001

fomd10.mean.sd <- fomd10.mean.sd %>%
  mutate(
    T_out_mean = if_else(effect_size_type=="Log Response Ratio"&T_out_mean == 0, 0.0001, T_out_mean),
    C_out_mean = if_else(effect_size_type=="Log Response Ratio"&C_out_mean == 0, 0.0001, C_out_mean)
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
## THIS IS TEMPORARY, JUST FOR THE CFRA ANALYSIS, LATER I NEED TO IMPLEMENT A EQUATION
## TO CHECK: there are negative yield values, see what to do here!

## First: Replace the C_out_mean==0 and T_out_mean==0 by 0.00001
names(fomd10.n.cv)


fomd10.effectsize <- fomd10.n.cv %>%
  calc_lnRR_effectsize(T_out_mean, C_out_mean,
                      T_out_sd, C_out_sd,
                      T_out_sample_size_imputed, C_out_sample_size_imputed)%>%
  calc_SMD_effectsize(T_out_mean, C_out_mean,
                       T_out_sd, C_out_sd,
                       T_out_sample_size_imputed, C_out_sample_size_imputed)%>%
  
  mutate(
    effect_size_yi=case_when(
      effect_size_type=="Log Response Ratio"& !is.na(lnRR_cv_final)~lnRR_cv_final,
      effect_size_type=="Log Response Ratio"& is.na(lnRR_cv_final)~lnRR,
      effect_size_type=="Standardized Mean Difference"~SMD,
      
      TRUE~NA),
    effect_size_vi=case_when(
      effect_size_type=="Log Response Ratio"& !is.na(lnRR_var_cv_final)~lnRR_var_cv_final,
      effect_size_type=="Log Response Ratio"& is.na(lnRR_var_cv_final)~lnRR_var,
      effect_size_type=="Standardized Mean Difference"~SMD_var,
      
      TRUE~NA)
    )

  names(fomd10.effectsize)
  
  
  select(doi,"C_product","T_product",
         out_subindicator,effect_size_type,
         C_out_mean,T_out_mean,
         C_out_sd,T_out_sd,
         T_out_sample_size_imputed, C_out_sample_size_imputed,
         "lnRR", "lnRR_var",
         SMD,
         C_out_cv_group_avg,T_out_cv_group_avg,
         C_out_cv_final,
         T_out_cv_final,
         lnRR_cv_group_avg,
         lnRR_cv_final,effect_size_yi,
         effect_size_vi)


#--------- Remove irrelevant columns ------------
practices <- c("tillage", "planting", "varietal_crop", "varietal_animal",
               "intercrop", "crop_seq", "agrof", "fert", "chem",
               "residues", "ph", "irrig", "watharv", "postharvest", "harvest")

pattern <- paste0("^CT_(", paste(practices, collapse = "|"), ")_(subpractice|practice|practicetheme)$")


fomd10.effectsize<-fomd10.effectsize%>%
  select(-matches(pattern),
         -"n_focal_groups",-"is_bundled" ,                         
         -"has_variety_bg"  ,-"is_vet_chem",
         -"C_out_cv_reported" ,
         -"T_out_cv_reported",
         "lnRR_cv_group_avg" ,                  
         
         "lnRR_var_cv_group_avg",                "lnRR_cv_final" ,                      
         "lnRR_var_cv_final",                    "cv_grouping_method" ,                 
         "lnRR" ,                                "lnRR_var" ,                           
         "SMD" ,                                 "SMD_var"  )

names(fomd10.effectsize)

sort(unique(fomd10.effectsize$T_out_sd))

write_csv(fomd10.effectsize, paste0(path.metadata.effectsize, "/fomd10_effect_size.csv"))


#==========================================================
# #Subset the Ethiopia data to send to the Modelling team
#==========================================================
fomd10.effectsize.eth<-fomd10.effectsize%>%
  filter(str_detect(country, "Ethiopia"))
write_csv(fomd10.effectsize.eth, paste0(path.metadata.effectsize, "/fomd10_subset_modelling_teams/ETH.fomd10_effect_size.v1.csv"))

#---10_FOMD_metadata_dictionary
fomd10.dictionary<-read_xlsx(file.path(path.metadata.structure,"10_FOMD_metadata_synthesis_short.xlsx"), sheet = "10_FOMD_readme")%>%
  select(4:7)
names(fomd10.dictionary)

write_csv(fomd10.dictionary, paste0(path.metadata.effectsize, "/fomd10_subset_modelling_teams/fomd10.dictionary.csv"))

#---01_FOMD_ontologies: 01_practices
ontologies_01practices<-read_xlsx(file.path(path.metadata.structure,"01_FOMD_ontologies.xlsx"), sheet = "01_practices")%>%
  select(-"code.ERA",
         -"theme.code.ERA",-"practice.code.ERA",-"subpractice.code.ERA",
         -"Subpractice.Suffix",-"practice_description",-"Subpractice.Suffix" ,-"Subpractice.S",
         -"note_for_lolita")
names(ontologies_01practices)
write_csv(ontologies_01practices, paste0(path.metadata.effectsize, "/fomd10_subset_modelling_teams/ontologies_01practices.csv"))
