library(readr)
library(dplyr)
library(purrr)
library(metafor) 
library(readxl)

path.metadata.structure<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Knowledge Hub - General/Agroecology_Knolwedge_Hub/02.FOMD/02.metadata_structure/"
path.metadata.effectsize<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Knowledge Hub - General/Agroecology_Knolwedge_Hub/02.FOMD/04.metadata_effectsize/"

list.files(path.metadata.structure)
list.files(path.metadata.effectsize)

#==========================================================
# Read datasets
#==========================================================
#---10_FOMD_metadata_synthesis_long
fomd10.names<-names(read_xlsx(file.path(path.metadata.structure,"10_FOMD_metadata_synthesis_short.xlsx"), sheet = "10_FOMD_metadata_synthesis"))
fomd10.names
#---10_FOMD_comparison_clean
fomd10.clean<-read_csv(file.path(path.metadata.effectsize,"fomd10_comparison_clean.csv"), show_col_types = FALSE)
  

sort(unique(fomd10.clean$out_subindicator))
sort(unique(fomd10.clean$effect_size_type))
length(unique(fomd10.clean$effect_size_type))

sort(unique(fomd10.clean$out_subpillar))
sort(unique(fomd10.clean$C_out_mean_product_component01))

#==========================================================
# Determine effect_size_type for out_subpillar=="Yield" & is.na(effect_size_type)
#==========================================================
sort(unique(fomd10.clean$T_agrof_subpractice))
sort(unique(fomd10.clean$T_intercrop_subpractice))

fomd10.effectsize.type<-fomd10.clean%>%
  mutate(
    effect_size_type=case_when(
      out_subpillar=="Yield"&
        is.na(effect_size_type)&
        str_detect(T_intercrop_subpractice, regex("Intercropping", ignore_case = TRUE)) &
        str_detect(C_intercrop_subpractice, regex("Monoculture", ignore_case = TRUE)) ~ "Log Partial LER",
      TRUE~effect_size_type))%>%
  mutate(
    effect_size_type=case_when(
      out_subpillar=="Yield"&
        is.na(effect_size_type)&
        str_detect(T_agrof_subpractice, regex("Alleycropping|Agroforestry", ignore_case = TRUE)) &
        str_detect(C_agrof_subpractice, regex("Monoculture", ignore_case = TRUE)) ~ "Log Partial LER",
      TRUE~effect_size_type))%>%
  mutate(
    effect_size_type=case_when(
      out_subpillar=="Yield"&
        is.na(effect_size_type) ~ "Log Response Ratio",
      TRUE~effect_size_type))
  
names(fomd10.effectsize.type)
sort(unique(fomd10.effectsize.type$effect_size_type))
length(unique(fomd10.effectsize.type$effect_size_type)) #4

sort(unique(fomd10.effectsize.type$T_subpractice))
sort(unique(fomd10.effectsize.type$T_agrof_subpractice))
sort(unique(fomd10.effectsize.type$out_subindicator))

#==========================================================
# Calculate effect size
#==========================================================
sort(unique(fomd10.effectsize.type$effect_size_type))
compute_effect_size <- function(dat) {
  
  # initialize output columns
  dat$effect_size_yi <- NA_real_
  dat$effect_size_vi  <- NA_real_

  needed <- c("T_out_mean","C_out_mean",
              "T_out_sd","C_out_sd",
              "T_out_sample_size","C_out_sample_size")
  
  valid_rows <- complete.cases(dat[, needed])

  # ---- Log Response Ratio 
  idx <- dat$effect_size_type %in% c("Log Response Ratio","Log Partial LER") & valid_rows
  if (any(idx)) {
    esc <- escalc(
      measure = "ROM",
      m1i  = dat$T_out_mean[idx],
      m2i  = dat$C_out_mean[idx],
      sd1i = dat$T_out_sd[idx],
      sd2i = dat$C_out_sd[idx],
      n1i  = dat$T_out_sample_size[idx],
      n2i  = dat$C_out_sample_size[idx],
      vtype="LS",
      digits=4
    )
    dat$effect_size_yi[idx] <- esc$yi
    dat$effect_size_vi[idx]  <- esc$vi
  }
  
  # ---- Standardized Mean Difference (Hedges g) ----
  idx <- dat$effect_size_type %in% c("Standardized Mean Difference","SMD") & valid_rows
  if (any(idx)) {
    esc <- escalc(
      measure = "SMD",
      m1i  = dat$T_out_mean[idx],
      m2i  = dat$C_out_mean[idx],
      sd1i = dat$T_out_sd[idx],
      sd2i = dat$C_out_sd[idx],
      n1i  = dat$T_out_sample_size[idx],
      n2i  = dat$C_out_sample_size[idx],
      vtype="LS",
      digits=4
    )
    dat$effect_size_yi[idx] <- esc$yi
    dat$effect_size_vi[idx]  <- esc$vi

  }
  
  # ---- Mean Difference ----
  idx <- dat$effect_size_type %in% c("Mean difference","MD") & valid_rows
  if (any(idx)) {
    esc <- escalc(
      measure = "MD",
      m1i  = dat$T_out_mean[idx],
      m2i  = dat$C_out_mean[idx],
      sd1i = dat$T_out_sd[idx],
      sd2i = dat$C_out_sd[idx],
      n1i  = dat$T_out_sample_size[idx],
      n2i  = dat$C_out_sample_size[idx]
    )
    dat$effect_size_yi[idx] <- esc$yi
    dat$effect_size_vi[idx]  <- esc$vi
  }
  
  return(dat)
}

compute_log_total_ler <- function(dat) {
  
  dat$total_ler <- NA_real_
  dat$log_total_ler <- NA_real_
  dat$log_total_ler_var  <- NA_real_
  

  for (i in seq_len(nrow(dat))) {
    # apply only to relevant rows
    if (dat$effect_size_type[i] != "Log Total LER") next
    
    partial_ler <- c()
    partial_var <- c()
    
    for (j in 1:5) {
      
      # treatment column names
      t_mean <- paste0("T_out_mean_product_component0", j)
      t_sd   <- paste0("T_out_sd_product_component0", j)
      
      # control column names
      if (j == 1) {
        c_mean <- "C_out_mean_product_component01"
        c_sd   <- "C_out_sd_product_component01"
      } else {
        c_mean <- paste0("C", j, "_out_mean_product_component0", j)
        c_sd   <- paste0("C", j, "_out_sd_product_component0", j)
      }
      
      # skip if columns don't exist
      if (!all(c(t_mean, t_sd, c_mean, c_sd) %in% names(dat))) next
      
      Yd <- dat[[t_mean]][i]
      Sd <- dat[[t_sd]][i]
      
      Ym <- dat[[c_mean]][i]
      Sm <- dat[[c_sd]][i]
      
      n_d <- dat$T_out_sample_size[i]
      n_m <- dat$C_out_sample_size[i]
      
      if (any(is.na(c(Yd, Ym, Sd, Sm, n_d, n_m)))) next
      if (Yd <= 0 | Ym <= 0) next
      
      # partial LER
      pler <- Yd / Ym
      
      # variance of partial LER
      var_pler <- pler^2 * (
        (Sd^2) / (n_d * Yd^2) +
          (Sm^2) / (n_m * Ym^2)
      )
      
      partial_ler <- c(partial_ler, pler)
      partial_var <- c(partial_var, var_pler)
    }
    
    if (length(partial_ler) > 0) {
      
      LER <- sum(partial_ler)
      var_LER <- sum(partial_var)
      
      dat$total_ler[i] <- LER
      
      if (LER > 0) {
        dat$log_total_ler[i] <- log(LER) #Natural Logarithm
        dat$log_total_ler_var[i] <- var_LER / (LER^2)
      }
    }
  }
  
  return(dat)
}

class(fomd10.effectsize.type$T_out_sd)
class(fomd10.effectsize.type$T_out_mean)
class(fomd10.effectsize.type$T_out_mean)
class(fomd10.effectsize.type$C_out_sample_size)
class(fomd10.effectsize.type$T_out_mean_product_component01)
class(fomd10.effectsize.type$C_out_mean_product_component01)
class(fomd10.effectsize.type$T_out_sd_product_component01)



num_cols <- c("C_out_mean","C_out_sd","C_out_sample_size",
              "T_out_mean","T_out_sd","T_out_sample_size",
              "T_out_mean_product_component01","T_out_sd_product_component01", 
              "T_out_mean_product_component02","T_out_sd_product_component02",
              "T_out_mean_product_component03","T_out_sd_product_component03",
              "T_out_mean_product_component04","T_out_sd_product_component04",
              "T_out_mean_product_component05","T_out_sd_product_component05",
              "C_out_mean_product_component01","C_out_sd_product_component01",
              "C2_out_mean_product_component02","C2_out_sd_product_component02"
              
              #"C3_out_mean_product_component03","C3_out_sd_product_component03"
              )



fomd10.effectsize <- fomd10.effectsize.type %>%
  mutate(across(all_of(num_cols), ~ readr::parse_number(as.character(.x)))) %>%
  compute_effect_size()%>%
  compute_log_total_ler()%>%
  mutate(effect_size_yi=case_when(
    effect_size_type=="Log Total LER"~log_total_ler,
    TRUE~effect_size_yi))%>%
  mutate(effect_size_vi=case_when(
    effect_size_type=="Log Total LER"~log_total_ler_var,
    TRUE~effect_size_vi))%>%
  mutate(effect_size_se=   sqrt(effect_size_vi))


sort(unique(fomd10.effectsize$out_subpillar))
sort(unique(fomd10.effectsize$out_subindicator))
sort(unique(fomd10.effectsize$study_id))

#==========================================================
# Put effect_size_id
#==========================================================
fomd10.effectsize<-fomd10.effectsize%>%
  group_by(study_id)%>%
  mutate(row_number = row_number()) %>%
  ungroup()%>%
  mutate(effect_size_id= paste0(study_id,"_",row_number) )

sort(unique(fomd10.effectsize$effect_size_id))
#==========================================================
# Unselect unnecessary columns
#==========================================================
fomd10.names <- c(unique(fomd10.names))
common_cols <- intersect(fomd10.names, names(fomd10.effectsize))
common_cols

fomd10.effectsize.clean <- fomd10.effectsize[, unique(common_cols)]

any(duplicated(fomd10.effectsize.clean$comparison_id))
any(duplicated(fomd10.effectsize.clean$effect_size_id))

dup_ids <- fomd10.effectsize.clean$comparison_id[
  duplicated(fomd10.effectsize.clean$comparison_id)
]

dup_ids
fomd10.effectsize.clean %>%
  filter(comparison_id %in% dup_ids) %>%
  distinct(study_id, comparison_id) %>%
  arrange(study_id)


list(
  only_in_fomd10.effectsize.clean = setdiff(names(fomd10.effectsize.clean), fomd10.names),
  only_in_fomd10.names = setdiff(fomd10.names, names(fomd10.effectsize.clean))
)
sort(unique(fomd10.effectsize.clean$effect_size_type))
sort(unique(fomd10.effectsize.clean$effect_size_id))

readr::write_csv(fomd10.effectsize.clean, paste0(path.metadata.effectsize, "/fomd10_effect_size.csv"))


sort(unique(fomd10.effectsize.clean$practice_subtype))




