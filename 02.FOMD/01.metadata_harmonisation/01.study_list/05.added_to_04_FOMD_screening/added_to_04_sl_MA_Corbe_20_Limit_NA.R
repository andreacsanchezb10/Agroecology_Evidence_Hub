library(readxl)
library(dplyr)
library(stringr)
library(writexl)

path.study.list<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/01.metadata_harmonisation/01.study_list"
path.metadata.structure<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/02.metadata_structure/"

#==========================================================
# Read datasets
#==========================================================
#---Study list data
# Same source as added_to_02_sl_MA_Corbe_20_Limit_NA.R - reference list
# transcribed from the paper's own Supplementary Table 1. Rows 1-79 (by the
# PDF's own numbering, captured in "used") = used in the meta-analysis;
# 80-87 = retrieved but excluded. code_from_ss below is set to Data_source
# (the author/year string), not the raw 1-87 PDF number - see
# added_to_02_sl_MA_Corbe_20_Limit_NA.R for why.
sl.data <- read_xlsx(
  file.path(path.study.list, "02.selected", "sl_MA_Corbe_20_Limit_Na.xlsx"),
  sheet = "Corbeels_2020_references"
)

#---04_FOMD_screening (master list) - only read to check for duplicate titles,
# never written back to
fomd04.titles <- read_xlsx(
  file.path(path.metadata.structure, "04_FOMD_screening.xlsx"),
  sheet = "04_FOMD_screening"
) %>%
  pull(title) %>%
  str_squish() %>%
  tolower()

#==========================================================
# Remove studies already present in 04_FOMD_screening (matched on title)
#==========================================================
sl.data <- sl.data %>%
  mutate(title_match = tolower(str_squish(title)))

duplicate_titles <- sl.data %>%
  filter(title_match %in% fomd04.titles)

nrow(sl.data)             # before removing duplicates
nrow(duplicate_titles)    # how many already exist in 04_FOMD_screening
duplicate_titles %>% select(code_from_ss, authors, title)

sl.data <- sl.data %>%
  filter(!title_match %in% fomd04.titles) %>%
  select(-title_match)

nrow(sl.data)             # after removing duplicates

#==========================================================
# Build 04_FOMD_screening structure
# (target schema from added_to_04_sl_MD_Rosen_24_Effec_Sc.R lines 98-108;
# status/status_label confirmed against 04_FOMD_screening.xlsx's own
# 04_FOMD_key legend sheet - "I" = Included, data complete; "O" = Excluded
# after full-text screening)
#==========================================================
sl.data.completed <- sl.data %>%
  mutate(
    ss_id          = "MA_Corbe_20_Limit_Na",
    booktitle      = NA_character_,
    article_number = if_else(code_from_ss == 41, "996", NA_character_),  # Front. Plant Sci. article number, not a page range
    issue          = NA_character_,
    doi            = NA_character_,   # not given in the supplementary PDF
    issn           = NA_character_,
    url            = NA_character_,
    keywords       = NA_character_,
    abstract       = NA_character_,
    study_type     = "JA",
    # code_from_ss now holds the Data_source string (e.g. "Agbede and
    # Ojeniyi (2009)"), not the raw 1-87 PDF number - this is what the
    # 06-harmonization script joins against md_MA_Corbe_20_Limit_Na.xlsx's
    # "ref" field on (via Data_source -> study_id_ss, confirmed hand-matched
    # against the supplementary PDF).
    code_from_ss   = Data_source,
    # Corbeels' own Excel dataset already has complete primary-study-level
    # data (yields, SD, n) for every used reference, same situation as
    # Rosen/ERA's blanket status = "I" default.
    status           = if_else(used, "PI", "O"),
    # exclusion_reason is the paper's own stated reason, as free text -
    # it doesn't cleanly match any of the 4 controlled exclusion_criteria_label
    # values in 04_FOMD_key (closest is "Insufficient Outcome Data (sample size)") -
    # confirm with Andrea before treating this as final.
    exclusion_reason = if_else(used, "", exclusion_reason),
    screen_person    = "",
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
                    paste0(path.study.list,"/05.added_to_04_FOMD_screening/added_to_04_sl_MA_Corbe_20_Limit_Na.xlsx"))
