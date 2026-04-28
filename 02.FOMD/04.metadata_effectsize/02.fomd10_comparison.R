library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(readr)

path.metadata.structure<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Knowledge Hub - General/Agroecology_Knolwedge_Hub/02.FOMD/02.metadata_structure/"
path.metadata.effectsize<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Knowledge Hub - General/Agroecology_Knolwedge_Hub/02.FOMD/04.metadata_effectsize/"

list.files(path.metadata.structure)
list.files(path.metadata.effectsize)

#==========================================================
# Read datasets
#==========================================================
#---01_FOMD_ontologies
fomd01.outcomes<- read_xlsx(file.path(path.metadata.structure,"01_FOMD_ontologies.xlsx"), sheet = "01_outcomes")

#---09_FOMD_clean
fomd09.clean<-read_csv(file.path(path.metadata.effectsize,"fomd09_clean.csv"), show_col_types = FALSE)

#---10_FOMD_metadata_synthesis_long
fomd10.names<-names(read_xlsx(file.path(path.metadata.structure,"10_FOMD_metadata_synthesis_short.xlsx"), sheet = "10_FOMD_metadata_synthesis"))
fomd10.names
# check
sort(unique(fomd09.clean$product_component))
sort(unique(fomd09.clean$product_component_focal_yield))

#==========================================================
# Row id columns: Context columns
#==========================================================
names(fomd09.clean)
sort(unique(fomd09.clean$out_subpillar))
sort(unique(fomd09.clean$bio_ground_ref))
sort(unique(fomd09.clean$subpractice))

context.row.id.cols<-c(
  #---practice
  "practice_id",
  #---bibliographic----
  "study_id","authors","year","journal","doi",
  #---location----
  "country", "country_ISO" , 
  "site_type","site_id","site_admin","site_agg","site_latlong_type",
  "site_latitude","site_longitude","site_buffer","site_key",
  #---experiment_details----
  "exp_design",	"exp_plot_size"	,"exp_field_size",	"exp_duration",
  #---experiment_time----
  "time_raw",	"time_year_start",	"time_year_end",	"time_season",
  #---product_outcome----
  "bio_func_group","bio_ground_ref" ,
  #---outcome----
  "out_subindicator","out_indicator","out_subpillar" , "out_pillar","out_subindicator_unit","effect_size_type", 
  "out_soil_depth_l",	"out_soil_depth_u",
  #---outcome_time---
  "out_year",	"out_year_start",	"out_year_end",
  "out_season_start",	"out_season_end")

#-----------------------------
# Row id1 columns: out_subpillar== "Biodiversity" 
# row id includes product_component
#-----------------------------
out.bio.row.id1.cols <- c(
  context.row.id.cols,
  #---product_outcome----
  "product_component" #MISSING: "C_product_type",  "C_product_subtype",  "C_product_simple"
  )

out.bio.row.id1.cols
out.bio.comparison.id1.cols<- c("out_comparison_treatment",setdiff(out.bio.row.id1.cols, "practice_id"))
out.bio.comparison.id1.cols

#-----------------------------
# Row id1 columns: out_subpillar== "Economics" 
#-----------------------------
out.eco.row.id1.cols <- context.row.id.cols

out.eco.row.id1.cols
out.eco.comparison.id1.cols<- c("out_comparison_treatment",setdiff(out.eco.row.id1.cols, "practice_id"))
out.eco.comparison.id1.cols

#-----------------------------
# Row id1 columns: out_subpillar== "Yield" 
# for Log Response Ratio and partial LER when product_component match
# row id includes product_component
#-----------------------------
out.yield.row.id1.cols <- out.bio.row.id1.cols

out.yield.row.id1.cols
out.yield.comparison.id1.cols<- c("out_comparison_treatment",setdiff(out.yield.row.id1.cols, "practice_id"))
out.yield.comparison.id1.cols

#-----------------------------
# Row id2 columns: out_subpillar== "Yield" 
# for Log Response Ratio when product_component don't match but product_component_focal_yield does
# row id includes product_component_focal_yield
#-----------------------------
out.yield.row.id2.cols <- c(
  context.row.id.cols,
    "product_component_focal_yield")

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
       select(out_subpillar,product_component_focal_yield, starts_with("out_mean_product_component0")))

fomd09.comparison<- fomd09.clean%>%
  mutate(row_id1 = case_when(
    
    #---out_subpillar== "Biodiversity"----
    out_subpillar=="Biodiversity"~apply(select(., all_of(out.bio.row.id1.cols)), 1, paste, collapse = "/"),
    
    #---out_subpillar=="Economics"----
    out_subpillar=="Economics"~apply(select(., all_of(out.eco.row.id1.cols)), 1, paste, collapse = "/"),
    
    #---out_subpillar=="Yield" matching product_component----
    out_subpillar=="Yield"& 
      is.na(product_component_focal_yield)&
      if_all(starts_with("out_mean_product_component0"), is.na) ~
      apply(select(., all_of(out.yield.row.id1.cols)), 1, paste, collapse = "/"),
    TRUE ~ NA_character_))%>%
  
  mutate(row_id2 = case_when(
     #---out_subpillar=="Yield" matching product_component_focal_yield----
    out_subpillar=="Yield" & 
      !is.na(product_component_focal_yield)&
      if_all(starts_with("out_mean_product_component0"), is.na)~
      apply(select(., all_of(out.yield.row.id2.cols)), 1, paste, collapse = "/"),
    TRUE ~ NA_character_))%>%
  
  mutate(row_id3 = case_when(
    #---out_subpillar=="Yield" to calculate LER----
    out_subpillar=="Yield" & 
      !if_all(starts_with("out_mean_product_component0"), is.na) ~
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
    
    #---out_subpillar=="Yield" matching product_component----
    out_subpillar=="Yield"& 
      is.na(product_component_focal_yield)&
      if_all(starts_with("out_mean_product_component0"), is.na) ~
      apply(select(., all_of(out.yield.comparison.id1.cols)), 1, paste, collapse = "/"),
    TRUE ~ NA_character_))%>%
  
  mutate(comparison_id2 = case_when(
    #---out_subpillar=="Yield" matching product_component_focal_yield----
    out_subpillar=="Yield" & 
      !is.na(product_component_focal_yield) &
      if_all(starts_with("out_mean_product_component0"), is.na)~
    
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
  filter(is.na(product_component_focal_yield))%>%
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
      is.na(product_component_focal_yield)&
      !if_all(starts_with("out_mean_product_component0"), is.na) ~
      apply(select(., all_of(out.yield.comparison.id3.cols)), 1, paste, collapse = "/"),
    TRUE ~ NA_character_))%>%
  filter(!is.na(comparison_id3))%>%
  mutate(
    component_slot = case_when(
      !is.na(out_mean_product_component01) ~ "C",
      !is.na(out_mean_product_component02) ~ "C2",
      !is.na(out_mean_product_component03) ~ "C3",
      !is.na(out_mean_product_component04) ~ "C4",
      !is.na(out_mean_product_component05) ~ "C5",
      TRUE ~ NA_character_
    ))
  
#check
sort(unique(fomd10.3.C$practice_id))
  
sort(unique(fomd10.3.C$component_slot))
sort(unique(fomd10.3.C$out_mean_product_component01))
sort(unique(fomd10.3.C$out_mean_product_component02))

# each monoculture row should usually map to only one component slot
fomd10.3.C %>%
  mutate(
    n_non_missing_components = rowSums(
      !is.na(select(., starts_with("out_mean_product_component0")))
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
  filter(!is.na(T_product_component)) %>%
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
  rename(C2_out_sample_size_product_component02=C2_out_sample_size)

names(fomd10.3)
sort(unique(fomd10.3$comparison_id3))
sort(unique(fomd10.3$C_practice_id))
sort(unique(fomd10.3$C2_practice_id))
sort(unique(fomd10.3$comparison_id))

#==========================================================
# 4) Pairing: row_id4
# Yield rows for PARTIAL LER
# one row = monoculture crop + intercrop + one product_component
#==========================================================

fomd09.comparison.4<-fomd09.comparison %>%
  filter(out_subpillar == "Yield")%>%
  mutate(product_component_full = product_component) %>%  # keep original
  separate(
    product_component_full,
    into = paste0("product_component", sprintf("%02d", 1:5)),
    sep = "\\.\\.|-",
    fill = "right",
    extra = "drop"
  ) %>%
  mutate(across(starts_with("product_component"), str_trim))%>%
  separate_rows(product_component, sep = "\\.\\.|-")%>%
  mutate(row_id4 = case_when(
    #---out_subpillar=="Yield" partial LER 
    out_subpillar=="Yield"& 
      is.na(product_component_focal_yield)&
      !if_all(starts_with("out_mean_product_component0"), is.na) ~
      apply(select(., all_of(out.yield.row.id1.cols)), 1, paste, collapse = "/"),
    TRUE ~ NA_character_))%>%
  filter(!is.na(row_id4))
 
sort(unique(fomd09.comparison.4$product_component))
sort(unique(fomd09.comparison.4$product_component01))
sort(unique(fomd09.comparison.4$product_component02))
sort(unique(fomd09.comparison.4$product_component03))
sort(unique(fomd09.comparison.4$product_component04))
sort(unique(fomd09.comparison.4$product_component05))
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
      is.na(product_component_focal_yield)&
      !if_all(starts_with("out_mean_product_component0"), is.na) ~
      apply(select(., all_of(out.yield.comparison.id1.cols)), 1, paste, collapse = "/"),
    TRUE ~ NA_character_))%>%
  filter(!is.na(comparison_id4))

    

#check
sort(unique(fomd09.comparison.4.C$practice_id))
sort(unique(fomd09.comparison.4.C$study_id))
sort(unique(fomd09.comparison.4.C$out_mean_product_component01))
sort(unique(fomd09.comparison.4.C$out_mean_product_component02))
sort(unique(fomd09.comparison.4.C$out_mean))
sort(unique(fomd09.comparison.4.C$product_component))
sort(unique(fomd09.comparison.4$product_component))

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
    T_product_component==T_product_component01~T_out_mean_product_component01,
    T_product_component==T_product_component02~T_out_mean_product_component02,
    #T_product_component==T_product_component03~T_out_mean_product_component03,
    #T_product_component==T_product_component04~T_out_mean_product_component04,
    #T_product_component==T_product_component05~T_out_mean_product_component05,
    TRUE~NA))%>%
  mutate(T_out_sd= case_when(
    T_product_component==T_product_component01~T_out_sd_product_component01,
    T_product_component==T_product_component02~T_out_sd_product_component02,
    #T_product_component==T_product_component03~T_out_sd_product_component03,
    #T_product_component==T_product_component04~T_out_sd_product_component04,
    #T_product_component==T_product_component05~T_out_sd_product_component05,
    TRUE~NA))%>%
  mutate( C_out_mean = coalesce(
    C_out_mean_product_component01,
    C_out_mean_product_component02,
    C_out_mean_product_component03,
    C_out_mean_product_component04,
    C_out_mean_product_component05
  ))%>%
  mutate( C_out_sd = coalesce(
    C_out_sd_product_component01,
    C_out_sd_product_component02,
    C_out_sd_product_component03,
    C_out_sd_product_component04,
    C_out_sd_product_component05
  ))%>%
  mutate(effect_size_type="Log Partial LER")%>%
  mutate(comparison_id=paste0(C_practice_id,"-",comparison_id4))

  
names(fomd10.4)
sort(unique(fomd10.4$out_subpillar))
sort(unique(fomd10.4$study_id))

sort(unique(fomd10.4$C_out_sd))
sort(unique(fomd10.4$C_varietal_crop_variety))
sort(unique(fomd10.4$T_out_sd))
sort(unique(fomd10.4$T_product_component01))

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






