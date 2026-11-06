library(readxl)
library(dplyr)
library(writexl)

path.study.list<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/01.metadata_harmonisation/01.study_list"

#==========================================================
# Read datasets
#==========================================================
#---Study list data
# Same source as added_to_02_sl_MA_Corbe_20_Limit_NA.R - reference list
# transcribed from the paper's own Supplementary Table 1. code_from_ss
# 1-79 = used in the meta-analysis; 80-87 = retrieved but excluded.
sl.data <- read_xlsx(
  file.path(path.study.list, "02.selected", "sl_MA_Corbe_20_Limit_Na.xlsx"),
  sheet = "Corbeels_2020_references"
)

#==========================================================
# Build 04_FOMD_screening structure
# (target schema from added_to_04_sl_MD_Rosen_24_Effec_Sc.R lines 98-108;
# status/status_label confirmed against 04_FOMD_screening.xlsx's own
# 04_FOMD_key legend sheet - "I" = Included, data complete; "O" = Excluded
# after full-text screening)
#==========================================================
sl.data.completed <- sl.data %>%
  mutate(
    ss_id          = "MA_Corbe_20_Limit_NA",
    booktitle      = NA_character_,
    article_number = if_else(code_from_ss == 41, "996", NA_character_),  # Front. Plant Sci. article number, not a page range
    issue          = NA_character_,
    doi            = NA_character_,   # not given in the supplementary PDF
    issn           = NA_character_,
    url            = NA_character_,
    keywords       = NA_character_,
    abstract       = NA_character_,
    study_type     = "JA",
    code_from_ss   = as.character(code_from_ss),
    # Corbeels' own Excel dataset already has complete primary-study-level
    # data (yields, SD, n) for every used reference, same situation as
    # Rosen/ERA's blanket status = "I" default.
    status           = if_else(used, "I", "O"),
    # exclusion_reason is the paper's own stated reason, as free text -
    # it doesn't cleanly match any of the 4 controlled exclusion_criteria_label
    # values in 04_FOMD_key (closest is "Insufficient Outcome Data (sample size)") -
    # confirm with Andrea before treating this as final.
    exclusion_reason = if_else(used, "", exclusion_reason),
    screen_person    = "AS",
    screen_date      = "",
    study_id         = "",
    country          = "",
    RESPONSIBLE      = ""
  ) %>%
  select(ss_id, authors, journal, booktitle, article_number,
         start_page, end_page, issue, title, volume, year, doi,
         issn, url, code_from_ss, keywords, abstract, study_type,
         status, exclusion_reason, screen_person, screen_date,
         study_id, country, RESPONSIBLE)

writexl::write_xlsx(sl.data.completed,
                    paste0(path.study.list,"/05.added_to_04_FOMD_screening/added_to_04_sl_MA_Corbe_20_Limit_NA.xlsx"))
