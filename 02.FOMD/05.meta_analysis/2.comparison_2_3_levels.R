library(tibble)
library(readxl)
library(stringr)
library(dplyr)
library(tidyr)
library(metafor)
library(readr)

path.metadata.structure<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Knowledge Hub - General/Agroecology_Knolwedge_Hub/02.FOMD/02.metadata_structure/"
path.metadata.effectsize<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Knowledge Hub - General/Agroecology_Knolwedge_Hub/02.FOMD/04.metadata_effectsize/"

list.files(path.metadata.structure)
list.files(path.metadata.effectsize)

#==========================================================
# Read datasets
#==========================================================
#---fomd10.effectsize
fomd10.effectsize<-read_csv(file.path(path.metadata.effectsize,"fomd10_effect_size.csv"), show_col_types = FALSE)%>%
  filter(!is.na(effect_size_yi))%>%
  #mutate(practice_type=case_when(
  #  C_practice_type==T_practice_type~T_practice_type,
   # TRUE~"no es igual"
  #))%>%
  select(study_id,
         
         
         C_subpractice,
         T_subpractice,
         practice_subtype
         
         )

names(fomd10.effectsize)

sort(unique(fomd10.effectsize$C_subpractice))
sort(unique(fomd10.effectsize$T_subpractice))
sort(unique(fomd10.effectsize$practice_subtype))


#==========================================================
# Summary indicator
#==========================================================
summary.indicator.cols<-c(
  "out_subindicator",
  "effect_size_type",
  "practice_subtype"
)
summary.indicator.cols

fomd10.effectsize<-fomd10.effectsize%>%
  mutate(
    summary_indicator = do.call(paste, c(across(all_of(summary.indicator.cols)), sep = "_")),
    summary_indicator=as.factor(summary_indicator)
    )

levels(fomd10.effectsize$summary_indicator) #7
#[1] "Abundance_Log Response Ratio"              "Biomass Yield_Log Partial LER"             "Biomass Yield_Log Response Ratio"         
#[4] "Crop Yield_Log Partial LER"                "Crop Yield_Log Response Ratio"             "Crop Yield_Log Total LER"                 
#[7] "Gross Margin_Standardized Mean Difference"

#==========================================================
# COMPARISON between 2-level and 3-level model structure
#==========================================================
#--- Heterogeneity of within-study variance (level 2) ----
## Build a two-level model without within-study variance 
#modelnovar2 <- rma.mv(y, v, random = list(~ 1 | effectsizeID, ~ 1 | studyID),
#                     sigma2=c(0,NA), tdist=TRUE, data=dataset)

modelnovar2_model <- function(data, metric_unit) {
  overal_model <- rma.mv(effect_size_yi, effect_size_vi, 
                         random = list(~ 1 | comparison_id, ~ 1 | study_id),
                         data = data,
                         method = "REML", 
                         test = "t",
                         dfs="contain",
                         subset = (summary_indicator == metric_unit))
  
  summary(overal_model, digits = 3)
  
  modelnovar2 <- rma.mv(effect_size_yi, effect_size_vi, 
                        random = list(~ 1 | comparison_id, ~ 1 | study_id),
                        data = data,
                        method = "REML", 
                        test = "t",
                        dfs="contain", 
                        sigma2 = c(0, NA),
                        subset = (summary_indicator == metric_unit))
  
  summary(modelnovar2, digits = 3)
  
  anova_result <- anova(overal_model, modelnovar2)
  return(anova_result)
  
}

# Vector of factor_metric_unit levels
factor_metric_units <- unique(fomd10.effectsize$summary_indicator)
factor_metric_units
data_levels <- levels(fomd10.effectsize$summary_indicator)
data_levels

setdiff(data_levels, factor_metric_units)


# List to store the results of all models
modelnovar2_list <- list()

# Loop over all factor_metric_unit levels and run the models
for (unit in levels(fomd10.effectsize$summary_indicator)) {
  result <- modelnovar2_model(data = fomd10.effectsize, metric_unit = unit)
  modelnovar2_list[[unit]] <- result
}


# Combine overall results into one table
modelnovar2_results_list <- do.call(rbind, modelnovar2_list)

modelnovar2_results<-as.data.frame(modelnovar2_results_list)%>%
  rownames_to_column(., var = "summary_indicator")%>%
  separate(fit.stats.f, into = c("ll.f", "dev.f", "AIC.f","BIC.f","AICc.f"), sep = ", ")%>%
  separate(fit.stats.r, into = c("ll.r", "dev.r", "AIC.r","BIC.r","AICc.r"), sep = ", ")%>%
  select("summary_indicator",     
         "AIC.f" , "AIC.r",
         "LRT" ,"pval")%>%
  mutate_all(~ gsub("AIC = ", "", .))%>%
  dplyr::rename("AIC.three_level" = "AIC.f",
                "AIC.within" = "AIC.r",
                "LRT.within" = "LRT",
                "pval.within"= "pval")%>%
  mutate_at(2:5, as.numeric)%>%
  mutate_at(2:5, ~round(.,4))

#--- Heterogeneity of between-study variance (level 3) ----
# Build a two-level model without between-study variance;
# Perform a likelihood-ratio-test to determine the significance of the between-study variance.
#modelnovar3 <- rma.mv(y, v, random = list(~ 1 | effectsizeID, ~ 1 | studyID),
#                    sigma2=c(NA,0), tdist=TRUE, data=dataset)
#anova(overall,modelnovar3)
modelnovar3_model <- function(data, metric_unit) {
  overal_model <- rma.mv(effect_size_yi, effect_size_vi, 
                         random = list(~ 1 | comparison_id, ~ 1 | study_id),
                         data = data,
                         method = "REML", 
                         test = "t",
                         dfs="contain",
                         subset = (summary_indicator == metric_unit))
  
  summary(overal_model, digits = 3)
  
  modelnovar3 <- rma.mv(effect_size_yi, effect_size_vi, 
                        random = list(~ 1 | comparison_id, ~ 1 | study_id),
                        data = data,
                        method = "REML", 
                        test = "t",
                        dfs="contain", 
                        sigma2 = c(NA, 0),
                        subset = (summary_indicator == metric_unit))
  
  summary(modelnovar3, digits = 3)
  
  anova_result <- anova(overal_model, modelnovar3)
  return(anova_result)
  
}

# Vector of factor_metric_unit levels
factor_metric_units <- unique(fomd10.effectsize$summary_indicator)

# List to store the results of all models
modelnovar3_list <- list()

# Loop over all factor_metric_unit levels and run the models
for (unit in levels(fomd10.effectsize$summary_indicator)) {
  result <- modelnovar3_model(data = fomd10.effectsize, metric_unit = unit)
  modelnovar3_list[[unit]] <- result
}

# Combine overall results into one table
modelnovar3_results_list <- do.call(rbind, modelnovar3_list)

modelnovar3_results <- as.data.frame(modelnovar3_results_list)%>%
  rownames_to_column(., var = "summary_indicator")%>%
  separate(fit.stats.f, into = c("ll.f", "dev.f", "AIC.f","BIC.f","AICc.f"), sep = ", ")%>%
  separate(fit.stats.r, into = c("ll.r", "dev.r", "AIC.r","BIC.r","AICc.r"), sep = ", ")%>%
  select("summary_indicator",     
         "AIC.r",
         "LRT" ,"pval")%>%
  mutate_all(~ gsub("AIC = ", "", .))%>%
  dplyr::rename("AIC.between" = "AIC.r",
                "LRT.between" = "LRT",
                "pval.between"= "pval")%>%
  mutate_at(2:4, as.numeric)%>%
  mutate_at(2:4, ~round(.,4))
names(modelnovar3_results)

#==========================================================
# Results of the comparison between the three-level and two-level model 
#==========================================================
#structures for each determinant factor, based on the Akaike Information Criterion (AIC), 
#Likelihood Ratio Test (LRT) and p-value. The three-level model was chosen as the best model
#when its AIC was lower and the LRT statistically significant comparing to both two-level models. 
fomd10.effectsize_class<-fomd10.effectsize%>%
  select(summary_indicator)
fomd10.effectsize_class<-unique(fomd10.effectsize_class)

comparison<- modelnovar2_results%>%
  left_join(modelnovar3_results, by= "summary_indicator")%>%
  mutate(best_model= if_else(pval.within<=0.05 & pval.between<=0.05, "Three-level",
                             "Two-level"))%>%
  mutate(pval.within= as.character(pval.within),
         pval.between= as.character(pval.between))%>%
  mutate(pval.within = if_else(pval.within==0, "< 0.0001", pval.within),
         pval.between= if_else(pval.within==0, "< 0.0001", pval.between))%>%
  mutate(LRT.pval.within = paste("LRT = ", LRT.within,", p = ",pval.within, sep = ""),
         LRT.pval.between = paste("LRT = ", LRT.between,", p = ",pval.between, sep = ""))%>%
  mutate_all(~ gsub(" = <", " <", .))%>%
  left_join(pcc_factor_class_unit, by= "summary_indicator")%>%
  select("factor_category","summary_indicator",
         "AIC.three_level", "AIC.within",   "AIC.between",
         "LRT.pval.within", "LRT.pval.between",
         "best_model")

length((comparison$best_model[comparison$best_model %in% "Three-level"])) #12
length((comparison$best_model[comparison$best_model %in% "Two-level"])) #59
sort(unique(comparison$summary_indicator))

write.csv(comparison, "results/comparison_best_model.csv", row.names=FALSE)