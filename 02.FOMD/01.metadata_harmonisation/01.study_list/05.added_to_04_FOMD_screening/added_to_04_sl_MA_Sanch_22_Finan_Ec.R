library(readxl)
library(dplyr)
library(stringr)

path.studylist<-setwd("C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Knowledge_Hub/02.FOMD/01.metadata_harmonisation/01.study_list")
path.metadata.structure<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Knowledge_Hub/02.FOMD/02.metadata_structure/"
list.files(path.studylist)
list.files(path.metadata.structure)

#==========================================================
# Helpers
#==========================================================
norm_txt <- function(x) {
  x %>%
    as.character() %>%
    str_to_lower() %>%
    str_squish() %>%
    na_if("")  # turn "" into NA
}

make_key_ty <- function(title, authors) {
  t <- norm_txt(title)
  y <- norm_txt(authors)
  ifelse(is.na(t) | is.na(y), NA_character_, paste0(t, " || ", y))
}

#==========================================================
# Read datasets
#==========================================================
#---02_FOMD_identified_studies
fomd02 <- read_xlsx(
  path  = paste0(path.metadata.structure,"02_FOMD_identified_studies.xlsx"),
  sheet = "02_FOMD_identified_studies")

#---04_FOMD_screening
fomd04 <- read_xlsx(
  path  = paste0(path.metadata.structure,"04_FOMD_screening.xlsx"),
  sheet = "04_FOMD_screening") %>%
  mutate(key_ty = make_key_ty(title, authors))

#-----------------------------
# Build MA_Sanch_22_Finan_Ec
#-----------------------------
MA_Sanch_22_Finan_Ec <- fomd02 %>%
  filter(ss_id == "MA_Sanch_22_Finan_Ec") %>%
  mutate(
    status = NA,
    exclusion_reason = NA,
    screen_person = NA,
    screen_date = NA,
    study_id = NA
  ) %>%
  mutate(
    key_ty = make_key_ty(title, authors)
  )

#-----------------------------
# Dedup sets
#-----------------------------
screen_dois <- unique(na.omit(fomd04$doi))
screen_keys <- unique(na.omit(fomd04$key_ty))

#-----------------------------
# Dedup logic:
# - remove if DOI matches (only when DOI exists)
# - else (DOI missing): remove if title-authors matches (only when key_ty exists)
# - if DOI missing AND key_ty missing: KEEP (cannot safely match)
#-----------------------------
deduplicated.MA_Sanch_22_Finan_Ec <- MA_Sanch_22_Finan_Ec %>%
  filter(
    ( !is.na(doi)    & !(doi %in% screen_dois) ) |
      (  is.na(doi)    &  is.na(key_ty) ) |
      (  is.na(doi)    & !is.na(key_ty) & !(key_ty %in% screen_keys) )
  )%>%
  select(-key_ty)


writexl::write_xlsx(deduplicated.MA_Sanch_22_Finan_Ec,"05_added_to_06_FOMD_screening/added_to_06_sl_MA_Sanch_22_Finan_Ec.xlsx")

