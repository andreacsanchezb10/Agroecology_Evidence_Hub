library(readxl)
library(dplyr)
library(stringr)

setwd("C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Knowledge Hub - General/Agroecology_Knolwedge_Hub/03.FOMD_datasets/FOMD_study_list/")

#-----------------------------
# Helpers
#-----------------------------
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

#-----------------------------
# Read datasets
#-----------------------------
FOMD_identified_studies <- read_xlsx(
  path  = "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Knowledge Hub - General/Agroecology_Knolwedge_Hub/02.FOMD_structure/04_FOMD_identified_studies.xlsx",
  sheet = "04_FOMD_identified_studies")

#-----------------------------
# Build MD_Rosen_24_Effec_Sc
#-----------------------------
MD_Rosen_24_Effec_Sc <- FOMD_identified_studies %>%
  filter(ss_id == "MD_Rosen_24_Effec_Sc") %>%
  mutate(
    status = NA,
    exclusion_reason = NA,
    screen_person = NA,
    screen_date = NA,
    study_id = NA,
    key_ty = make_key_ty(title, authors)
  )

#-----------------------------
# Deduplicate
#-----------------------------
# 1️⃣ First remove duplicates where DOI exists
step1 <- MD_Rosen_24_Effec_Sc %>%
  filter(!is.na(doi)) %>%
  distinct(doi, .keep_all = TRUE)

# 2️⃣ Now handle records without DOI
no_doi <- MD_Rosen_24_Effec_Sc %>%
  filter(is.na(doi))

step2 <- no_doi %>%
  filter(!is.na(key_ty)) %>%
  distinct(key_ty, .keep_all = TRUE)

# 3️⃣ Keep records that have neither DOI nor key
step3 <- no_doi %>%
  filter(is.na(key_ty))

# 4️⃣ Combine all
deduplicated.MD_Rosen_24_Effec_Sc <- bind_rows(step1, step2, step3) %>%
  select(-key_ty)

writexl::write_xlsx(deduplicated.MD_Rosen_24_Effec_Sc,"05_added_to_06_FOMD_screening/added_to_06_sl_MD_Rosen_24_Effec_Sc.xlsx")

