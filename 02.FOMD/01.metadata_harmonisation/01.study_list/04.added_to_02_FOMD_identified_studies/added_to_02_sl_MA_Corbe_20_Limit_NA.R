library(readxl)
library(dplyr)
library(writexl)

path.study.list<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/01.metadata_harmonisation/01.study_list"

#==========================================================
# Read datasets
#==========================================================
#---Study list data
# Reference list transcribed from the paper's own Supplementary Table 1
# (MA_Corbe_20_Limit_Na_supp_info.pdf) - no RIS/EndNote export exists for
# this source, so this file IS the primary transcription.
# code_from_ss 1-79 = studies used in the meta-analysis; 80-87 = retrieved
# but excluded ("studied crop species had few observations in total,
# resulting in confounding effects").
sl.data <- read_xlsx(
  file.path(path.study.list, "02.selected", "sl_MA_Corbe_20_Limit_Na.xlsx"),
  sheet = "Corbeels_2020_references"
)

#==========================================================
# Build 02_FOMD_identified_studies structure
# (target schema from added_to_02_sl_MD_Rosen_24_Effec_Sc.R lines 57-59)
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
    code_from_ss   = as.character(code_from_ss)
  ) %>%
  select(ss_id, authors, journal, booktitle, article_number,
         start_page, end_page, issue, title, volume, year, doi,
         issn, url, code_from_ss, keywords, abstract, study_type)

writexl::write_xlsx(sl.data.completed,
                    paste0(path.study.list,"/04.added_to_02_FOMD_identified_studies/added_to_02_sl_MA_Corbe_20_Limit_NA.xlsx"))
