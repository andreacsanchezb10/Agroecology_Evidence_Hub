library(readxl)
library(dplyr)
library(stringr)
library(writexl)

path.study.list<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/01.metadata_harmonisation/01.study_list"

#==========================================================
# Read datasets
#==========================================================
#---Study list data
# Unlike Corbeels, this file has ONE ROW PER COMPARISON (e.g.
# "Abate_2024-01".."-11" are 11 rows from the same paper), not one row per
# paper, and columns C/D look like A/B shifted down one row (a copy-paste
# artifact) - both are ignored below. Column B (DOI) also has its own data
# entry errors (checked: "Hamzei_2015" is repeated 8x with DOI incrementing
# 10/11/12.../17 instead of staying constant - a drag-fill error), so the
# real DOI is parsed out of the "Reference" column's own doi.org link
# instead of trusting column B directly.
sl.raw <- read_xlsx(
  file.path(path.study.list, "02.selected", "sl_MA_Gelag_26_Globa_Un.xlsx"),
  sheet = "MasterData"
) %>%
  select(Study_ID,DOI, Title, Reference) %>%
  filter(!is.na(Study_ID))

nrow(sl.raw)                       # 1617 comparison-level rows
length(unique(sl.raw$Study_ID))    # 605 unique Study_IDs
length(unique(sl.raw$DOI))    # 181 unique DOI
length(unique(sl.raw$Title))    # 164 unique DOI

#==========================================================
# Collapse to one row per PAPER (what 02_FOMD_identified_studies expects -
# a bibliographic register, not a comparison-level table)
#==========================================================
sl.raw <- sl.raw %>%
  mutate(
    real_doi = str_extract(Reference, "(?<=doi\\.org/)\\S+$"),
    # base_study_id strips the per-comparison suffix ("-01", "_001_a") so
    # all comparisons from the same paper group together even where
    # real_doi is missing (the 24 Study_IDs still awaiting a title/DOI
    # from Habtamu/Gelagay - Reference is blank for those, real_doi is NA).
    base_study_id = str_remove(Study_ID, "(-\\d+|_\\d{3}(_[a-z]+)?|(?<=[0-9])[a-z]+)$"),
    paper_key = coalesce(real_doi, base_study_id)
  )%>%
  mutate(base_study_id=case_when(
    base_study_id%in%c("CanteroMartinez_2026_SV",
                       "CanteroMartinez_2026_AG",
                       "CanteroMartinez_2026_PN",
                       "CanteroMartinez_2026",
                       "Cantero_2026"
                        )~"CanteroMartinez_2026",
    base_study_id%in%c("Bartomeus_2014_OSR",
                       "Bartomeus_2014_FieldBean",
                       "Bartomeus_2014_Strawberry",
                       "Bartomeus_2014_Buckwheat" )~"Bartomeus_2014",
    TRUE~base_study_id))
                       
  
length(unique(sl.raw$base_study_id)) #228

# sanity check: does any single paper_key cover more than one base_study_id,
# or vice versa? (would mean the DOI/suffix logic is grouping wrong papers
# together - inspect before trusting the collapse below if this is >0)
check <- sl.raw %>% group_by(paper_key) %>% summarise(n_base_ids = n_distinct(base_study_id), .groups = "drop") %>% filter(n_base_ids > 1)
nrow(check)   # should be 0 - if not, inspect `check` before continuing
sort(unique(check$paper_key))

sl.papers <- sl.raw %>%
  group_by(paper_key) %>%
  slice(1) %>%   # Title/Reference are identical across a paper's comparison rows (checked)
  ungroup()

nrow(sl.papers)   # should be ~181 (with DOI) + up to 24 (still pending, Title/Reference blank)

#==========================================================
# Parse "Reference" (a full APA-style citation string) into its parts.
# Format confirmed consistent across every populated row:
#   "Authors (Year). Title. Journal, Volume(Issue), Pages. https://doi.org/DOI"
# Rows where Reference is blank (title/DOI not yet received) are left NA -
# those still need Habtamu/Gelagay's reply, not a fabricated citation.
#==========================================================
parse_reference <- function(ref, title) {
  if (is.na(ref) || ref == "") {
    return(list(authors = NA_character_, year = NA_character_, journal = NA_character_,
                volume = NA_character_, issue = NA_character_,
                start_page = NA_character_, end_page = NA_character_, article_number = NA_character_))
  }
  head <- str_extract(ref, "^.*?\\(\\d{4}\\)\\.")
  if (is.na(head)) {
    return(list(authors = NA_character_, year = NA_character_, journal = NA_character_,
                volume = NA_character_, issue = NA_character_,
                start_page = NA_character_, end_page = NA_character_, article_number = NA_character_))
  }
  year <- str_extract(head, "\\d{4}")
  authors <- str_squish(str_remove(head, "\\s*\\(\\d{4}\\)\\.$"))

  after_head <- str_squish(str_sub(ref, nchar(head) + 1))
  after_title <- str_squish(str_remove(after_head, fixed(title)))
  after_title <- str_remove(after_title, "^\\.\\s*")
  tail_only <- str_remove(after_title, "\\s*https?://doi\\.org/.*$")
  tail_only <- str_squish(str_remove(tail_only, "\\.$"))

  m <- str_match(tail_only, "^(.*?),\\s*([0-9]+)(?:\\(([0-9]+)\\))?,\\s*([\\w–-]+)$")
  if (is.na(m[1, 1])) {
    return(list(authors = authors, year = year, journal = NA_character_,
                volume = NA_character_, issue = NA_character_,
                start_page = NA_character_, end_page = NA_character_, article_number = tail_only))
  }
  journal <- m[1, 2]; volume <- m[1, 3]; issue <- m[1, 4]; pages <- m[1, 5]
  if (str_detect(pages, "[–-]")) {
    pp <- str_split_fixed(pages, "[–-]", 2)
    list(authors = authors, year = year, journal = journal, volume = volume, issue = issue,
         start_page = pp[1, 1], end_page = pp[1, 2], article_number = NA_character_)
  } else {
    list(authors = authors, year = year, journal = journal, volume = volume, issue = issue,
         start_page = NA_character_, end_page = NA_character_, article_number = pages)
  }
}

parsed <- purrr::map2(sl.papers$Reference, sl.papers$Title, parse_reference)
parsed.df <- purrr::map_dfr(parsed, as_tibble)

sl.papers <- bind_cols(sl.papers, parsed.df)

# how many populated references failed to parse into journal/volume/pages -
# inspect and fix these by hand rather than trusting a guess
sl.papers %>% filter(!is.na(Reference) & Reference != "" & is.na(journal)) %>%
  select(Study_ID, Reference)

#==========================================================
# Build 02_FOMD_identified_studies structure
# (target schema from added_to_02_sl_MA_Corbe_20_Limit_Na.R)
#==========================================================
sl.data.completed <- sl.papers %>%
  mutate(
    ss_id          = "MA_Gelag_26_Globa_Un",
    booktitle      = NA_character_,
    issn           = NA_character_,
    url            = NA_character_,
    keywords       = NA_character_,
    abstract       = NA_character_,
    # TO CHECK: all set to "JA" (journal article) by default, matching the
    # bulk of this source - but at least one entry is a Master's thesis
    # (Study_ID with DOI placeholder "NR (Master's thesis)") and others may
    # be preprints/reports once Habtamu/Gelagay's reply fills in the 24
    # pending titles. Confirm/correct study_type per row before finalizing.
    study_type     = "JA",
    code_from_ss   = base_study_id,
    title          = Title,
    doi            = real_doi
  ) %>%
  select(ss_id, authors, journal, booktitle, article_number,
         start_page, end_page, issue, title, volume, year, doi,
         issn, url, code_from_ss, keywords, abstract, study_type)

nrow(sl.data.completed)#180

writexl::write_xlsx(sl.data.completed,
                    paste0(path.study.list,"/04.added_to_02_FOMD_identified_studies/added_to_02_sl_MA_Gelag_26_Globa_Un.xlsx"))
