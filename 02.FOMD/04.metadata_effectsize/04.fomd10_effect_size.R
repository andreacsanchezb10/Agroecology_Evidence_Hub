library(readr)
library(dplyr)
library(purrr)
library(metafor) 
library(readxl)
library(metafor)
library(skimr)

path.metadata.structure<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/02.metadata_structure/"
path.metadata.effectsize<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/04.metadata_effectsize/"

list.files(path.metadata.structure)
list.files(path.metadata.effectsize)

#==========================================================
# Read functions
#==========================================================
source(file.path(path.metadata.effectsize,"fomd_fun/fun_mean_sd_calculation.R"))
source(file.path(path.metadata.effectsize,"fomd_fun/fun_lookup_ontologies.R")) # TO CHECK VER COMO METER LOAD DATA ONTOLOGIES DENTRO DE ESTA EQUACION
source(file.path(path.metadata.effectsize,"fomd_fun/fun_cv_missing_calculation.R"))
source(file.path(path.metadata.effectsize,"fomd_fun/fun_effect_sizes_calculation.R"))
source(file.path(path.metadata.effectsize,"fomd_fun/fun_pler_ler_calculation.R"))

#==========================================================
# Read datasets
#==========================================================
#---10_FOMD_clean: combine every source's cleaned comparison file
fomd10_clean_dir   <- file.path(path.metadata.effectsize, "03.fomd10_clean")
fomd10_clean_files <- list.files(fomd10_clean_dir, pattern = "^fomd10_clean_.*\\.csv$", full.names = TRUE)

fomd10.clean <- purrr::map_dfr(
  fomd10_clean_files, readr::read_csv,
  show_col_types = FALSE,
  col_types = harmonize_col_types(fomd10_clean_files)
)

# --- quick check ---
skim(fomd10.clean)

length(fomd10_clean_files) # how many source files got combined
nrow(fomd10.clean)
sort(unique(fomd10.clean$study_id))
#sort(unique(fomd10.clean$study_id[is.na(fomd10.clean$C_out_value )]))
#sort(unique(fomd10.clean$study_id[fomd10.clean$C_out_var_metric =="95% Confidence Intervals"]))

#==========================================================
# Calculate Mean and Standard deviation
# From available (raw) values
#==========================================================
#-- Check mean and variance metrics
for (col in c("effect_size_id","C_out_value_metric", "T_out_value_metric",
              "C_out_var_metric", "T_out_var_metric"
              
)) {
  cat("---", col, "---\n")
  print(sort(unique(fomd10.clean[[col]])))
}

skim(fomd10.clean$C_out_value)
skim(fomd10.clean$T_out_value)

skim(fomd10.clean$C_out_var_value)
skim(fomd10.clean$T_out_var_value)

skim(fomd10.clean$C_out_sample_size)
skim(fomd10.clean$T_out_sample_size)


#---- Apply equation to calculate Mean AND SD from raw data ----
fomd10.mean.sd<-calculate_mean_sd(fomd10.clean)

#==========================================================
# Calculate CV and number of samples
# From observations that don't provide variance values or number of samples
#==========================================================
# --- quick checks ---
skim(fomd10.mean.sd$C_out_mean)
skim(fomd10.mean.sd$T_out_mean)
sort(unique(fomd10.mean.sd$study_id[is.na(fomd10.mean.sd$C_out_mean)]))

skim(fomd10.mean.sd$C_out_sd)
skim(fomd10.mean.sd$T_out_sd)

skim(fomd10.mean.sd$C_out_sample_size)
skim(fomd10.mean.sd$T_out_sample_size)

sort(unique(fomd10.mean.sd$out_subpillar))

sort(unique(fomd10.mean.sd$out_subindicator[fomd10.mean.sd$out_subpillar=="Yield"]))
sort(unique(fomd10.mean.sd$out_subindicator[fomd10.mean.sd$out_subpillar=="Biodiversity"]))


#---- Apply equation to calculate sample size AND SD ----
## TO CHECK TOMORROW: WHY I'M CALCULATING EFFECT SIZES HERE IF METAFOR escalc(measure = "ROM" 
## CALCULATE VI AND YI USING THE SAME FORMULA???

fomd10.n.cv <- n_cv_calculation(
  dt               = fomd10.mean.sd,                       
  rules            = outcome_grouping_rules,
  outcome_col      = "out_subindicator")

fomd10.n.cv <- fomd10.n.cv%>%
  mutate(
    T_out_sample_size_imputed = coalesce(T_out_sample_size, T_out_sample_size_imputed),
    C_out_sample_size_imputed = coalesce(C_out_sample_size, C_out_sample_size_imputed))
names(fomd10.n.cv)
skim(fomd10.n.cv$C_out_cv_final)
skim(fomd10.n.cv$T_out_cv_final)

## TO CHECK: there is a problem here, the code did not calculate n of samples for some rows of C
skim(fomd10.n.cv$C_out_sample_size)
skim(fomd10.n.cv$C_out_sample_size_imputed)

skim(fomd10.n.cv$T_out_sample_size)
skim(fomd10.n.cv$T_out_sample_size_imputed)

prueba<-fomd10.n.cv%>%
  filter(out_subindicator=="Crop Yield",
         C_product_simple=="Wheat"
         )%>%
  
  #filter(is.na(C_out_sample_size))%>%
  select(study_id,
         out_subindicator,
         C_product,T_product,
         C_product_simple,T_product_simple,
         C_out_sample_size,
         T_out_sample_size,
         C_out_sample_size_imputed,
         T_out_sample_size_imputed
         )

# Check for NaN in C_out_sd and T_out_sd
cols <- c("C_out_value_metric","T_out_value_metric",
          
          "C_out_value","T_out_value",
          "C_out_var_metric","T_out_var_metric",
          
          "C_out_var_value", "T_out_var_value",
          "C_out_sample_size","T_out_sample_size",
          "C_out_mean","T_out_mean",
          "C_out_sd","T_out_sd",
          "C_out_sample_size_imputed","T_out_sample_size_imputed",
          "C_out_cv_group_avg","T_out_cv_group_avg",
          "C_out_cv_final", "T_out_cv_final")

data.frame(
  column  = cols,
  n_na    = colSums(is.na(fomd10.n.cv[, cols])),
  pct_na  = colMeans(is.na(fomd10.n.cv[, cols])) * 100)

#==========================================================
# Calculate pLER and LER
#==========================================================
fomd10.ler<- fun_calculate_ler(fomd10.n.cv)
  select(study_id,
         out_subindicator,
         C_out_value_metric,
         C_out_value,
         C_out_var_metric,
         C_out_var_value,
         C_out_sample_size,
         T_out_value_metric,
         T_out_value,
         T_out_var_metric,
         T_out_var_value,
         T_out_sample_size,
         
         pler_value,
         pler_var_value,
         ler_value_total,
         ler_var_value_total,
         ler_comparison_id,
         C_product,
         T_product,
         C_product_simple,
         T_product_simple,
         T_crop_tree_diversity,
         
         C_out_mean,
         T_out_mean,
         C_out_sd,
         T_out_sd,
         C_out_cv_final,
         T_out_cv_final,
         "C_out_sample_size_imputed","T_out_sample_size_imputed",
         "pler_value_calc" ,"pler_var_calc",  
         "ler_calc_n_rows"  ,                   
         "ler_value_calc" ,                      "ler_sd_calc"  ,
         ler_product ,
         ler_effect_size_type,ler_effect_size_yi,ler_effect_size_vi
         
  )
## there is a problem with JA_Dua, _17_Effec_LR ler since there are multiple controls
## TO CHECK: HOW TO RESOLVE THE PROBLEM WITH DUA..
## HOW TO GET var LER values need to be calculated
crop_check <- fomd10.mean.sd %>%
  filter(!is.na(ler_comparison_id)) %>%
  mutate(n_crops_expected = lengths(strsplit(T_crop_tree_diversity, "-"))) %>%
  group_by(ler_comparison_id) %>%
  mutate(n_rows_actual = n()) %>%
  ungroup() %>%
  distinct(study_id,ler_comparison_id, T_crop_tree_diversity, T_product, n_crops_expected, n_rows_actual) %>%
  filter(n_rows_actual != n_crops_expected)

nrow(crop_check)
crop_check

#==========================================================
# Checking out_subindicators with effect_size_type
#==========================================================
sort(unique(fomd10.n.cv$out_subindicator))#37
sort(unique(fomd10.n.cv$out_indicator))#13
sort(unique(fomd10.n.cv$out_effect_size_type))#2

sort(unique(fomd10.n.cv$out_subindicator[is.na(fomd10.n.cv$out_effect_size_type )]))
sort(unique(fomd10.n.cv$out_subindicator[fomd10.n.cv$out_effect_size_type == "Log Response Ratio" ]))
sort(unique(fomd10.n.cv$out_subindicator[fomd10.n.cv$out_effect_size_type == "Standardized Mean Difference" ]))

#==========================================================
# Calculate Effect sizes 
#==========================================================
### THINGS TO DO: I NEED TO CALCULATE SMD USING THE CALCULATED SD, ASK DAMIEN HOW TO DO IT.

sort(unique(fomd10.n.cv$T_out_sample_size_imputed))
sort(unique(fomd10.n.cv$C_out_sample_size_imputed))

x<-fomd10.n.cv %>%
  select(study_id,
         out_subindicator,
    C_out_mean,
         T_out_mean,
         C_out_sd,
         T_out_sd,
         C_out_sample_size_imputed,
         T_out_sample_size_imputed,
         C_out_cv_group_avg,
         T_out_cv_group_avg,
         C_out_cv_final,
         T_out_cv_final
         #out_cv_grouping_method,
         #out_effect_size_type,
    #out_effect_size_yi,
    #out_effect_size_vi
  )



fomd10.effectsize <- fomd10.n.cv %>%
  calc_lnRR_effectsize(T_out_mean, C_out_mean,
                      T_out_sd, C_out_sd,
                      T_out_sample_size_imputed, C_out_sample_size_imputed)%>%
  calc_SMD_effectsize(T_out_mean, C_out_mean,
                       T_out_sd, C_out_sd,
                       T_out_sample_size_imputed, C_out_sample_size_imputed)%>%
  
  mutate(
    out_effect_size_yi=case_when(
      out_effect_size_type=="Log Response Ratio"& !is.na(lnRR_cv_final)~lnRR_cv_final,
      out_effect_size_type=="Log Response Ratio"& is.na(lnRR_cv_final)~lnRR,
      out_effect_size_type=="Standardized Mean Difference"~SMD,
      
      TRUE~NA),
    out_effect_size_vi=case_when(
      out_effect_size_type=="Log Response Ratio"& !is.na(lnRR_var_cv_final)~lnRR_var_cv_final,
      out_effect_size_type=="Log Response Ratio"& is.na(lnRR_var_cv_final)~lnRR_var,
      out_effect_size_type=="Standardized Mean Difference"~SMD_var,
      
      TRUE~NA)
    )

  names(fomd10.effectsize)
  
  x<-fomd10.effectsize%>%
    
  select(study_id,
                out_subindicator,
         out_effect_size_type,
                C_out_mean,
                T_out_mean,
                C_out_sd,
                T_out_sd,
                C_out_sample_size_imputed,
                T_out_sample_size_imputed,
                C_out_cv_group_avg,
                T_out_cv_group_avg,
                C_out_cv_final,
                T_out_cv_final,
         lnRR_cv_group_avg,
         lnRR_cv_final,effect_size_yi,
         effect_size_vi)

#==========================================================
#--------- Check for missing columns
#==========================================================
fomd10.cols<-read_xlsx(
    file.path(path.metadata.structure,"10_FOMD_metadata_synthesis_short.xlsx"),
    sheet = "10_FOMD_metadata_synthesis")
fomd10.cols<-names(fomd10.cols)
  
list(
    fomd10_clean = setdiff(names(fomd10.effectsize), fomd10.cols),   # produced by a branch, but not in the 10_ schema — will get silently dropped by select(any_of(fomd10.cols))
    only_in_fomd10_schema   = setdiff(fomd10.cols, names(fomd10.effectsize))    # expected by the schema, but no branch currently produces it — will end up entirely missing/empty in the final output
  )

irrelevant_cols<- c(
"T_out_cv_reported",                    "C_out_cv_reported",                   
 "lnRR_cv_group_avg" ,                   "lnRR_var_cv_group_avg",               
 "lnRR_cv_final" ,                       "lnRR_var_cv_final" ,                  
 "lnRR" ,                                "lnRR_var" ,                           
"SMD" ,                                 "SMD_var"  )

#--------- Remove irrelevant columns ------------

fomd10.effectsize<-fomd10.effectsize%>%
  select(-irrelevant_cols)
  

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
