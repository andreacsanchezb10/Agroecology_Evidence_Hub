library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(readr)

path.metadata.structure<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/02.metadata_structure/"
path.metadata.effectsize<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/04.metadata_effectsize/"

list.files(path.metadata.structure)
list.files(path.metadata.effectsize)

#==========================================================
# Read datasets
#==========================================================
#---01_FOMD_ontologies
fomd01.outcomes<- read_xlsx(file.path(path.metadata.structure,"01_FOMD_ontologies.xlsx"), sheet = "01_outcomes")

#---09_FOMD_clean
fomd09.clean<-read_csv(file.path(path.metadata.effectsize,"fomd09_cleanv2.csv"), show_col_types = FALSE)
#---09_FOMD_verified
#fomd09.clean<- read_xlsx(file.path(path.metadata.structure,"09_FOMD_metadata_extraction_long.xlsx"), sheet = "09_FOMD_metadata_extraction_lon")

#---10_FOMD_metadata_synthesis_long
fomd10.names<-names(read_xlsx(file.path(path.metadata.structure,"10_FOMD_metadata_synthesis_short.xlsx"), sheet = "10_FOMD_metadata_synthesis"))
fomd10.names
# check
sort(unique(fomd09.clean$product))

#==========================================================
# Row id columns: Context columns
#==========================================================
names(fomd09.clean)
sort(unique(fomd09.clean$out_subpillar))
table(fomd09.clean$out_subpillar)
sort(unique(fomd09.clean$bio_ground_ref))
sort(unique(fomd09.clean$country))
sort(unique(fomd09.clean$country_ISO))

context.row.id.cols<-c(
  #---practice
  "practice_id",
  #---bibliographic----
  "study_id","authors","title","year","journal","doi",
  #---location----
  "country", "country_ISO" , 
  #"site_type","site_id","site_admin","site_agg","site_latlong_type",
  #"site_latitude","site_longitude","site_buffer","site_key",
  #---experiment_details----
  #"exp_design",	"exp_plot_size"	,"exp_field_size",	"exp_duration",
  
  #---experiment_time----
  #"time_raw",	"time_year_start",	"time_year_end",	"time_season",
  #---product_outcome----
  "bio_func_group","bio_ground_ref" ,
  #---outcome----
  "out_subindicator","out_indicator","out_subpillar" , "out_pillar","out_subindicator_unit","effect_size_type", 
  "out_soil_depth_l",	"out_soil_depth_u",
  #---outcome_time---
  "out_year",	"out_year_start",	"out_year_end",
  "out_season_start",	"out_season_end")


##########################################
#---- BIODIVERSITY DATASET
##########################################
bio.data<- fomd09.clean%>%
  filter(out_subpillar=="Biodiversity")

# Quick checks
length(unique(bio.data$study_id)) #6
bio.data %>% distinct(practice_id) %>% arrange(practice_id)
bio.data %>% distinct(country) %>% arrange(country)
bio.data %>% distinct(country_ISO) %>% arrange(country_ISO)
bio.data %>%group_by(country) %>% summarise(n_studies = n_distinct(study_id), .groups = "drop") %>% arrange(desc(n_studies))
bio.data %>% distinct(out_subpillar)
bio.data %>% distinct(product) %>% arrange(product)
bio.data %>%count(out_subindicator, wt = !duplicated(study_id), name = "n_studies")

#-----------------------------
# Columns defining one biodiversity outcome row
#-----------------------------
bio.row.id.cols <- c(
  #-- practice
  "practice_id",
  #-- bibliographic
  "ss_id",
  "study_id","authors","year","journal","doi",
  #-- location
  "country", "country_ISO" , 
  #"site_type","site_id","site_admin","site_agg","site_latlong_type",
  #"site_latitude","site_longitude","site_buffer","site_key",
  #-- experiment_details
  "exp_design",
  #"exp_plot_size"	,"exp_field_size",	"exp_duration",
  #---experiment_time----
  "time_raw",	"time_year_start",	"time_year_end",	"time_season",
  #---product_outcome----
  "bio_func_group","bio_ground_ref" ,
  #---outcome----
  "out_subindicator","out_indicator","out_subpillar" , "out_pillar","out_subindicator_unit", #"effect_size_type", 
  "out_soil_depth_l",	"out_soil_depth_u",
  #---product_outcome----
  "product", #MISSING: "C_product_type",  "C_product_subtype",  "C_product_simple"
  #---outcome_time---
  "out_year",	"out_year_start",	"out_year_end",
  "out_season_start",	"out_season_end"
  )

bio.row.id.cols

bio.data<- bio.data%>%
  mutate(row_id = apply(select(., all_of(bio.row.id.cols)), 1, paste, collapse = "/"))

# Quick checks (make sure the numbers are the same)
nrow(bio.data) #197
length(unique(bio.data$row_id)) #197
sort(unique(bio.data$row_id)) #197

#-----------------------------
# Columns defining one biodiversity comparison
#-----------------------------
bio.comparison.id.cols<- c("out_comparison_treatment",setdiff(bio.row.id.cols, "practice_id"))
bio.comparison.id.cols

#-----------------------------
# Control observations
#-----------------------------
bio.data.C<-bio.data%>%
  filter(grepl("C", practice_id))

# Quick checks
nrow(bio.data.C) #74
length(unique(bio.data.C$row_id)) #74
bio.data %>%  filter(grepl("C", practice_id))%>% distinct(practice_id) %>% arrange(practice_id)
unique(bio.data.C$out_comparison_treatment)
bio.data.C%>% filter(grepl("C", practice_id))%>%filter(is.na(practice_id))

bio.data.C<-bio.data.C%>%
  separate_rows(out_comparison_treatment, sep = "\\.\\.")%>%
  mutate(out_comparison_treatment = str_squish(out_comparison_treatment)) %>%
  filter(out_comparison_treatment != "")%>%
  mutate(comparison_id = apply(select(., all_of(bio.comparison.id.cols)), 1, paste, collapse = "/"))
    
# Quick checks
length(unique(bio.data.C$row_id)) #74
sort(unique(bio.data.C$row_id)) #74
sort(unique(bio.data.C$out_comparison_treatment))
length(unique(bio.data.C$comparison_id)) #176 (AHORA ME APARECE 156)
sort(unique(bio.data.C$comparison_id)) #176 (AHORA ME APARECE 156)

#-----------------------------
# Pairing Control and Treatment rows 
#-----------------------------
out.all.row.id.cols <- setdiff(bio.row.id.cols,"practice_id")
out.all.row.id.cols

bio.fomd10<- bio.data.C%>%
  left_join(
    bio.data%>% 
      select(-out.all.row.id.cols), 
    suffix = c(".C", ".T"),
    by = c("comparison_id"="row_id"))%>%
  rename_with(~ paste0("T_", sub("\\.T$", "", .)),.cols = ends_with(".T"))%>%
  rename_with(~ paste0("C_", sub("\\.C$", "", .)),.cols = ends_with(".C"))%>%
  filter(!is.na(T_practice_id))
  mutate(comparison_id=paste0(C_practice_id,"-",comparison_id1))

names(bio.fomd10)
nrow(bio.fomd10) #231 (AHORA ME APARECE 261)
length(unique(bio.fomd10$study_id)) #6
length(unique(bio.fomd10$comparison_id)) #156

sort(unique(fomd10.1$C_crop_diversity))
sort(unique(fomd10.1$T_crop_diversity))


sort(unique(fomd10.1$C_crop_variety))
sort(unique(fomd10.1$T_out_sd))
sort(unique(fomd10.1$comparison_id))

sort(unique(fomd10.1$T_practice_id))


############################################








#-----------------------------
# Row id1 columns: out_subpillar== "Economics" 
#-----------------------------
out.eco.row.id1.cols <- context.row.id.cols

out.eco.row.id1.cols
out.eco.comparison.id1.cols<- c("out_comparison_treatment",setdiff(out.eco.row.id1.cols, "practice_id"))
out.eco.comparison.id1.cols

#-----------------------------
# Row id1 columns: out_subpillar== "Yield" 
# for Log Response Ratio and partial LER when product match
# row id includes product
#-----------------------------
out.yield.row.id1.cols <- out.bio.row.id1.cols

out.yield.row.id1.cols
out.yield.comparison.id1.cols<- c("out_comparison_treatment",setdiff(out.yield.row.id1.cols, "practice_id"))
out.yield.comparison.id1.cols

#-----------------------------
# Row id2 columns: out_subpillar== "Yield" 
# for Log Response Ratio when product don't match but product_focal_yield does
# row id includes product_focal_yield
#-----------------------------
out.yield.row.id2.cols <- c(
  context.row.id.cols,
    "product_focal_yield")

out.yield.row.id2.cols
out.yield.comparison.id2.cols<- c("out_comparison_treatment",setdiff(out.yield.row.id2.cols, "practice_id"))
out.yield.comparison.id2.cols

#-----------------------------
# Row id3 columns: out_subpillar== "Yield" 
# for partial and Total LER
#
#-----------------------------
out.yield.row.id3.cols <- c(context.row.id.cols)

out.yield.row.id3.cols
out.yield.comparison.id3.cols<- c("out_comparison_treatment",setdiff(out.yield.row.id3.cols, "practice_id"))
out.yield.comparison.id3.cols


#-----------------------------
# Create row_id to match intervention (T) vs control (C)
#-----------------------------
head(fomd09.clean%>%
       select(out_subpillar,product_focal_yield, starts_with("out_mean_product0")))

fomd09.comparison<- fomd09.clean%>%
  mutate(row_id1 = case_when(
    
    #---out_subpillar== "Biodiversity"----
    out_subpillar=="Biodiversity"~apply(select(., all_of(out.bio.row.id1.cols)), 1, paste, collapse = "/"),
    
    #---out_subpillar=="Economics"----
    out_subpillar=="Economics"~apply(select(., all_of(out.eco.row.id1.cols)), 1, paste, collapse = "/"),
    
    #---out_subpillar=="Yield" matching product----
    out_subpillar=="Yield"& 
      is.na(product_focal_yield)&
      if_all(starts_with("out_mean_product0"), is.na) ~
      apply(select(., all_of(out.yield.row.id1.cols)), 1, paste, collapse = "/"),
    TRUE ~ NA_character_))%>%
  
  mutate(row_id2 = case_when(
     #---out_subpillar=="Yield" matching product_focal_yield----
    out_subpillar=="Yield" & 
      !is.na(product_focal_yield)&
      if_all(starts_with("out_mean_product0"), is.na)~
      apply(select(., all_of(out.yield.row.id2.cols)), 1, paste, collapse = "/"),
    TRUE ~ NA_character_))%>%
  
  mutate(row_id3 = case_when(
    #---out_subpillar=="Yield" to calculate LER----
    out_subpillar=="Yield" & 
      !if_all(starts_with("out_mean_product0"), is.na) ~
      apply(select(., all_of(out.yield.row.id3.cols)), 1, paste, collapse = "/"),
    TRUE ~ NA_character_))

  

unique(fomd09.comparison$row_id1)
length(unique(fomd09.comparison$row_id1)) #183
unique(fomd09.comparison$row_id2)
length(unique(fomd09.comparison$row_id2)) #9
unique(fomd09.comparison$row_id3)
length(unique(fomd09.comparison$row_id3)) #11

length(unique(fomd09.comparison$study_id))
sort(unique(fomd09.comparison$out_sd))

#==========================================================
# DESCRIPTIVES
#==========================================================
#Number of articles and effect sizes by Financial_measure
fomd09.comparison %>%  group_by(out_subindicator) %>% summarise(n_distinct(study_id)) #Number of articles per financial metric

#-----------------------------
# Meta-data short
#-----------------------------
#---Control systems
fomd09.comparison.C<-fomd09.comparison%>%
  filter(grepl("C", practice_id))

length(unique(fomd09.comparison.C$row_id1))
sort(unique(fomd09.comparison.C$row_id1))
unique(fomd09.comparison.C$out_comparison_treatment)

fomd09.comparison.C<-fomd09.comparison.C%>%
  separate_rows(out_comparison_treatment, sep = "\\.\\.") %>%
  mutate(out_comparison_treatment = str_squish(out_comparison_treatment)) %>%
  filter(out_comparison_treatment != "")%>%
  mutate(comparison_id1 = case_when(
    #---out_subpillar== "Biodiversity"----
    out_subpillar=="Biodiversity"~apply(select(., all_of(out.bio.comparison.id1.cols)), 1, paste, collapse = "/"),
    
    #---out_subpillar=="Economics"----
    out_subpillar=="Economics"~apply(select(., all_of(out.eco.comparison.id1.cols)), 1, paste, collapse = "/"),
    
    #---out_subpillar=="Yield" matching product----
    out_subpillar=="Yield"& 
      is.na(product_focal_yield)&
      if_all(starts_with("out_mean_product0"), is.na) ~
      apply(select(., all_of(out.yield.comparison.id1.cols)), 1, paste, collapse = "/"),
    TRUE ~ NA_character_))%>%
  
  mutate(comparison_id2 = case_when(
    #---out_subpillar=="Yield" matching product_focal_yield----
    out_subpillar=="Yield" & 
      !is.na(product_focal_yield) &
      if_all(starts_with("out_mean_product0"), is.na)~
    
      apply(select(., all_of(out.yield.comparison.id2.cols)), 1, paste, collapse = "/"),
    TRUE ~ NA_character_))

length(unique(fomd09.comparison.C$row_id1)) #65
sort(unique(fomd09.comparison.C$row_id1))
length(unique(fomd09.comparison.C$row_id2)) #5
sort(unique(fomd09.comparison.C$row_id2))
length(unique(fomd09.comparison.C$row_id3)) #3
sort(unique(fomd09.comparison.C$row_id3))
sort(unique(fomd09.comparison.C$out_comparison_treatment))
sort(unique(fomd09.comparison.C$comparison_id1))
sort(unique(fomd09.comparison.C$comparison_id2))

sort(unique(fomd09.comparison.C$out_subpillar))

nrow(fomd09.comparison.C)
names(fomd09.comparison.C)
fomd09.comparison.C$practice_id
fomd09.comparison$practice_id


#==========================================================
# 1) Pairing: row_id
#"Biodiversity", "Economics", "Yield" 
#==========================================================
out.all.row.id.cols <- setdiff(context.row.id.cols,"practice_id")
out.all.row.id.cols

sort(unique(fomd09.comparison$out_mean))

fomd10.1<- fomd09.comparison.C%>%
  filter(!is.na(row_id1))%>%
  filter(is.na(product_focal_yield))%>%
  select(-any_of(c("row_id1","row_id2")))%>%
  left_join(
    fomd09.comparison%>% 
      select(-out.all.row.id.cols), 
    suffix = c(".C", ".T"),
    by = c("comparison_id1"="row_id1"))%>%
  rename_with(~ paste0("T_", sub("\\.T$", "", .)),.cols = ends_with(".T"))%>%
  rename_with(~ paste0("C_", sub("\\.C$", "", .)),.cols = ends_with(".C"))%>%
  filter(!is.na(T_practice_id))%>%
  mutate(comparison_id=paste0(C_practice_id,"-",comparison_id1))

sort(unique(fomd10.1$out_subpillar))
sort(unique(fomd10.1$study_id))

sort(unique(fomd10.1$C_out_sd))
sort(unique(fomd10.1$C_varietal_crop_variety))
sort(unique(fomd10.1$T_out_sd))
sort(unique(fomd10.1$comparison_id))

sort(unique(fomd10.1$T_practice_id))

#==========================================================
# 2) Pairing: row_id2
# "Yield"
#==========================================================
fomd10.2 <- fomd09.comparison.C %>%
  filter(out_subpillar == "Yield") %>%
  filter(!is.na(row_id2))%>%
  select(-any_of(c("row_id1", "row_id2","row_id3"))) %>%
  left_join(
    fomd09.comparison %>%
      filter(out_subpillar == "Yield") %>%
      select(-any_of(out.all.row.id.cols)),
    by = c("comparison_id2" = "row_id2"),
    suffix = c(".C", ".T")
  ) %>%
  rename_with(~ paste0("T_", sub("\\.T$", "", .)), .cols = ends_with(".T")) %>%
  rename_with(~ paste0("C_", sub("\\.C$", "", .)), .cols = ends_with(".C")) %>%
  filter(!is.na(T_practice_id))%>%
  mutate(comparison_id=paste0(C_practice_id,"-",comparison_id2))

sort(unique(fomd10.2$study_id))
  
sort(unique(fomd10.2$T_out_mean))

names(fomd10.2)

#==========================================================
# 3) Pairing: row_id3
# Yield rows for TOTAL LER
# one row = monoculture crop 1 + monoculture crop 2 + intercrop
#==========================================================
#---Controls used for LER
fomd10.3.C <- fomd09.comparison %>%
  filter(grepl("C", practice_id))%>%

  filter(out_subpillar == "Yield") %>%
  separate_rows(out_comparison_treatment, sep = "\\.\\.") %>%
  mutate(out_comparison_treatment = str_squish(out_comparison_treatment)) %>%

    mutate(comparison_id3 = case_when(
    #---out_subpillar=="Yield" to calculate LER
    out_subpillar=="Yield" & 
      is.na(product_focal_yield)&
      !if_all(starts_with("out_mean_product0"), is.na) ~
      apply(select(., all_of(out.yield.comparison.id3.cols)), 1, paste, collapse = "/"),
    TRUE ~ NA_character_))%>%
  filter(!is.na(comparison_id3))%>%
  mutate(
    component_slot = case_when(
      !is.na(out_mean_product01) ~ "C",
      !is.na(out_mean_product02) ~ "C2",
      !is.na(out_mean_product03) ~ "C3",
      !is.na(out_mean_product04) ~ "C4",
      !is.na(out_mean_product05) ~ "C5",
      TRUE ~ NA_character_
    ))
  
#check
sort(unique(fomd10.3.C$practice_id))
  
sort(unique(fomd10.3.C$component_slot))
sort(unique(fomd10.3.C$out_mean_product01))
sort(unique(fomd10.3.C$out_mean_product02))

# each monoculture row should usually map to only one component slot
fomd10.3.C %>%
  mutate(
    n_non_missing_components = rowSums(
      !is.na(select(., starts_with("out_mean_product0")))
    )
  ) %>%
  count(n_non_missing_components) 

#==========================================================
# 3.1 Put monocultures in one row
# one row per comparison_id3 + treatment
#==========================================================
names(fomd10.3.C)
exclude_cols <- c("component_slot", "comparison_id3", "out_comparison_treatment", context.row.id.cols)
exclude_cols <- setdiff(exclude_cols, "practice_id")
C.values <- setdiff(names(fomd10.3.C), exclude_cols)
C.values

fomd10.3.C.wide <- fomd10.3.C %>%
  pivot_wider(
    id_cols = c(comparison_id3, out_comparison_treatment),
    names_from = component_slot,
    values_from = C.values,
    names_glue = "{component_slot}_{.value}",
    values_fn = dplyr::first
  )  
names(fomd10.3.C.wide)
head(fomd10.3.C.wide)
sort(unique(fomd10.3.C.wide$C2_practice_id))


sort(unique(fomd10.3.C$out_comparison_treatment))

sort(unique(fomd10.3.C$out_comparison_treatment))

#==========================================================
# 3.2 Intercrop rows
#==========================================================
fomd10.3.T <- fomd09.comparison %>%
  filter(out_subpillar == "Yield") %>%
  filter(!is.na(row_id3)) %>%
  filter(str_detect(practice_id, "^T"))%>%
  rename_with(
    ~ paste0("T_", .),
    -c(row_id1,row_id2,row_id3, practice_id, all_of(out.yield.row.id3.cols))
  )

sort(unique(fomd10.3.T$row_id3))
sort(unique(fomd10.3.T$practice_id))
sort(unique(fomd10.3.C.wide$comparison_id3))
sort(unique(fomd10.3.C.wide$out_comparison_treatment))

#==========================================================
# 3.3 Join control monocultures + treatment row
#==========================================================
fomd10.3 <- fomd10.3.C.wide %>%
  select(-any_of(c("row_id1", "row_id2","row_id3"))) %>%
  left_join(fomd10.3.T,
            by = c("comparison_id3" = "row_id3"#,
                   #"out_comparison_treatment" = "practice_id"
                   )) %>%
  filter(!is.na(T_product)) %>%
  rowwise() %>%
  mutate(
    comparison_id = paste(
      c_across(any_of(c(
        "C_practice_id", "C2_practice_id", "C3_practice_id",
        "C4_practice_id", "C5_practice_id", "T_practice_id"
      ))) %>%
        as.character() %>%
        .[!is.na(.) & . != ""],
      collapse = "-"
    )
  ) %>%
  ungroup()%>%
  mutate(comparison_id=paste0(comparison_id,"-",comparison_id3))%>%
  mutate(effect_size_type="Log Total LER")%>%
  rename(C2_out_sample_size_product02=C2_out_sample_size)

names(fomd10.3)
sort(unique(fomd10.3$comparison_id3))
sort(unique(fomd10.3$C_practice_id))
sort(unique(fomd10.3$C2_practice_id))
sort(unique(fomd10.3$comparison_id))

#==========================================================
# 4) Pairing: row_id4
# Yield rows for PARTIAL LER
# one row = monoculture crop + intercrop + one product
#==========================================================

fomd09.comparison.4<-fomd09.comparison %>%
  filter(out_subpillar == "Yield")%>%
  mutate(product_full = product) %>%  # keep original
  separate(
    product_full,
    into = paste0("product", sprintf("%02d", 1:5)),
    sep = "\\.\\.|-",
    fill = "right",
    extra = "drop"
  ) %>%
  mutate(across(starts_with("product"), str_trim))%>%
  separate_rows(product, sep = "\\.\\.|-")%>%
  mutate(row_id4 = case_when(
    #---out_subpillar=="Yield" partial LER 
    out_subpillar=="Yield"& 
      is.na(product_focal_yield)&
      !if_all(starts_with("out_mean_product0"), is.na) ~
      apply(select(., all_of(out.yield.row.id1.cols)), 1, paste, collapse = "/"),
    TRUE ~ NA_character_))%>%
  filter(!is.na(row_id4))
 
sort(unique(fomd09.comparison.4$product))
sort(unique(fomd09.comparison.4$product01))
sort(unique(fomd09.comparison.4$product02))
sort(unique(fomd09.comparison.4$product03))
sort(unique(fomd09.comparison.4$product04))
sort(unique(fomd09.comparison.4$product05))
sort(unique(fomd09.comparison.4$study_id))
sort(unique(fomd09.comparison.4$row_id4))

#---Controls used for PARTIAL LER
fomd09.comparison.4.C <- fomd09.comparison.4 %>%
  filter(grepl("C", practice_id))%>%
  separate_rows(out_comparison_treatment, sep = "\\.\\.") %>%
  mutate(out_comparison_treatment = str_squish(out_comparison_treatment)) %>%
  
  mutate(comparison_id4 = case_when(
    #---out_subpillar=="Yield" partial LER 
    out_subpillar=="Yield"& 
      is.na(product_focal_yield)&
      !if_all(starts_with("out_mean_product0"), is.na) ~
      apply(select(., all_of(out.yield.comparison.id1.cols)), 1, paste, collapse = "/"),
    TRUE ~ NA_character_))%>%
  filter(!is.na(comparison_id4))

    

#check
sort(unique(fomd09.comparison.4.C$practice_id))
sort(unique(fomd09.comparison.4.C$study_id))
sort(unique(fomd09.comparison.4.C$out_mean_product01))
sort(unique(fomd09.comparison.4.C$out_mean_product02))
sort(unique(fomd09.comparison.4.C$out_mean))
sort(unique(fomd09.comparison.4.C$product))
sort(unique(fomd09.comparison.4$product))

fomd10.4<- fomd09.comparison.4.C%>%
  select(-any_of(starts_with("row_id")))%>%
  left_join(
    fomd09.comparison.4%>% 
      select(-out.all.row.id.cols), 
    suffix = c(".C", ".T"),
    by = c("comparison_id4"="row_id4"))%>%
  rename_with(~ paste0("T_", sub("\\.T$", "", .)),.cols = ends_with(".T"))%>%
  rename_with(~ paste0("C_", sub("\\.C$", "", .)),.cols = ends_with(".C"))%>%
  filter(!is.na(T_practice_id))%>%
  mutate(comparison_id=paste0(C_practice_id,"-",comparison_id4))%>%
  mutate(T_out_mean= case_when(
    T_product==T_product01~T_out_mean_product01,
    T_product==T_product02~T_out_mean_product02,
    #T_product==T_product03~T_out_mean_product03,
    #T_product==T_product04~T_out_mean_product04,
    #T_product==T_product05~T_out_mean_product05,
    TRUE~NA))%>%
  mutate(T_out_sd= case_when(
    T_product==T_product01~T_out_sd_product01,
    T_product==T_product02~T_out_sd_product02,
    #T_product==T_product03~T_out_sd_product03,
    #T_product==T_product04~T_out_sd_product04,
    #T_product==T_product05~T_out_sd_product05,
    TRUE~NA))%>%
  mutate( C_out_mean = coalesce(
    C_out_mean_product01,
    C_out_mean_product02,
    C_out_mean_product03,
    C_out_mean_product04,
    C_out_mean_product05
  ))%>%
  mutate( C_out_sd = coalesce(
    C_out_sd_product01,
    C_out_sd_product02,
    C_out_sd_product03,
    C_out_sd_product04,
    C_out_sd_product05
  ))%>%
  mutate(effect_size_type="Log Partial LER")%>%
  mutate(comparison_id=paste0(C_practice_id,"-",comparison_id4))

  
names(fomd10.4)
sort(unique(fomd10.4$out_subpillar))
sort(unique(fomd10.4$study_id))

sort(unique(fomd10.4$C_out_sd))
sort(unique(fomd10.4$C_varietal_crop_variety))
sort(unique(fomd10.4$T_out_sd))
sort(unique(fomd10.4$T_product01))

#==========================================================
# Unselect unnecessary columns
#==========================================================
fomd10.cols <- c(unique(fomd10.names))

fomd10.1.clean <- fomd10.1[, intersect(fomd10.cols, names(fomd10.1)), drop = FALSE]
fomd10.2.clean <- fomd10.2[, intersect(fomd10.cols, names(fomd10.2)), drop = FALSE]
fomd10.3.clean <- fomd10.3[, intersect(fomd10.cols, names(fomd10.3)), drop = FALSE]
fomd10.4.clean <- fomd10.4[, intersect(fomd10.cols, names(fomd10.4)), drop = FALSE]

fomd10.clean <- bind_rows(fomd10.1.clean, fomd10.2.clean, fomd10.3.clean,fomd10.4.clean)%>%
  select(any_of(fomd10.cols))



dup_ids <- fomd10.clean$comparison_id[
  duplicated(fomd10.clean$comparison_id)
]
dup_ids
fomd10.clean %>%
  filter(comparison_id %in% dup_ids) %>%
  distinct(study_id, comparison_id) %>%
  arrange(study_id)


list(
  only_in_fomd10 = setdiff(fomd10.names, names(fomd10.clean)),
  only_in_fomd09 = setdiff(names(fomd10.clean), fomd10.names)
)

sort(unique(fomd10.clean$effect_size_type))


readr::write_csv(fomd10.clean, paste0(path.metadata.effectsize, "/fomd10_comparison.csv"))





#-----------------------------------------------
#---- Match with 01_FOMD_ontologies ----
#-----------------------------------------------
library(tibble)
library(purrr)

#--- Location: Reclassifying country as ISO_3166_1_Alpha_3----
fomd09.clean <- apply_lookup_ontologies(
  fomd09.clean, 
  path.metadata.structure,
  sheet_name = "01_countries",
  key_col = "Country",
  value_col = "ISO_3166_1_Alpha_3",
  src_col = "country",
  new_col = "country_ISO",
  sep = ".."
)

#-----------------------------------------------
#---- Match with 01_FOMD_ontologies ----
#-----------------------------------------------
library(tibble)
library(purrr)

#--- Location: Reclassifying country as ISO_3166_1_Alpha_3----
fomd09.clean <- apply_lookup_ontologies(
  fomd09.clean, 
  path.metadata.structure,
  sheet_name = "01_countries",
  key_col = "Country",
  value_col = "ISO_3166_1_Alpha_3",
  src_col = "country",
  new_col = "country_ISO",
  sep = ".."
)

#Remove duplicate country and country_ISO
md.era.short.clean <- md.era.short.clean %>%
  mutate(
    country = map_chr(str_split(str_squish(country), "\\.\\."), \(x) paste(unique(str_squish(x)), collapse = "..")),
    country_ISO1 = map_chr(str_split(str_squish(country_ISO1), "\\.\\."), \(x) paste(unique(str_squish(x)), collapse = ".."))
  )


# Quick checks
# All the studied countries are in fomd01.countries
unique_countries <-data.frame(
  country = md.era.short.clean %>%
    pull(country) %>%
    str_split("\\.\\.") %>%
    unlist() %>%
    str_trim())%>%
  distinct(country) %>%
  arrange(country)%>%
  left_join(fomd01.countries%>%
              filter(!is.na(Country))%>%
              distinct(Country,ISO_3166_1_Alpha_3),
            by=c("country"="Country"))
#filter(is.na(Product.Type))

sort(unique(md.era.short.clean$country))
sort(unique(md.era.short.clean$country_ISO))




#=========================
#---outcome----
#=========================
#--- Reclassifying out_subindicator as out_indicator
md.era.short.clean <- apply_lookup_ontologies(
  df        = md.era.short.clean,
  ref       = fomd01.outcomes,
  key_col   = "subindicator",
  value_col = "indicator",
  src_col   = "out_subindicator",
  new_col   = "out_indicator"
)

# Quick checks
sort(unique(md.era.short.clean$out_subindicator))
sort(unique(md.era.short.clean$out_indicator))

#--- Reclassifying out_subindicator as out_subpillar
md.era.short.clean <- apply_lookup_ontologies(
  df        = md.era.short.clean,
  ref       = fomd01.outcomes,
  key_col   = "subindicator",
  value_col = "subpillar",
  src_col   = "out_subindicator",
  new_col   = "out_subpillar"
)

# Quick checks
sort(unique(md.era.short.clean$out_subindicator))
sort(unique(md.era.short.clean$out_subpillar))

sort(unique(md.era.short.clean$out_subindicator[md.era.short.clean$out_subpillar==""]))
sort(unique(md.era.short.clean$out_subindicator[is.na(md.era.short.clean$out_subpillar)]))

#--- Reclassifying out_subindicator as out_pillar
md.era.short.clean <- apply_lookup_ontologies(
  df        = md.era.short.clean,
  ref       = fomd01.outcomes,
  key_col   = "subindicator",
  value_col = "pillar",
  src_col   = "out_subindicator",
  new_col   = "out_pillar"
)




