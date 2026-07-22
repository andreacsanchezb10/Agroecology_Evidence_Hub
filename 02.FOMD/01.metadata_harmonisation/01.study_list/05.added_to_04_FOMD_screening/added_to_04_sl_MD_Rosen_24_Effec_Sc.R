library(readxl)
library(dplyr)
library(tidyr)

path.study.list<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/01.metadata_harmonisation/01.study_list"
path.study.metadata<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/01.metadata_harmonisation/02.metadata"


list.files(path.study.list)
list.files(path.study.metadata)

#==========================================================
# Read datasets
#==========================================================
#---Study list data 
sl.data<-read.csv(file.path(path.study.list,"/02.selected/sl_MD_Rosen_24_Effec_Sc.csv"),header = TRUE, sep = ",")
sl.data1<-read.csv(file.path(path.study.list,"/02.selected/sl_MD_Rosen_24_Effec_Sc_completed.csv"),header = TRUE, sep = ",")

#---Metadata
keep.list <- read.csv(
  file.path(path.study.metadata, "/04.added_to_06_FOMD_metadata_original_long/added_to_10_MD_Rosen_24_Effec_Sc.csv"),
  header = TRUE, sep = ",")
keep_ids <- unique(keep.list$study_id %>% as.character() %>% trimws())


# ---- Source 1: sl_MD_Rosen_24_Effec_Sc.csv ----
#with complete bibliographic information but not all included papers
sl.data<-sl.data%>%
  separate(
    col="PAGES", into= c("start_page","end_page"), 
    sep="--", remove=TRUE, convert=TRUE)%>%
  mutate(TYPE=case_when(
    TYPE=="Journal Article"~"JA",
    TYPE=="Serial"~"S",
    TRUE~NA
  ))%>%
  rename(
    category       = CATEGORY,
    authors        = AUTHOR,
    booktitle      = BOOKTITLE,
    journal        = JOURNAL,
    article_number = NUMBER,
    title          = TITLE,
    study_type     = TYPE,
    volume         = VOLUME,
    year           = YEAR,
    doi            = DOI,
    issn           = ISSN,
    url            = URL,
    code_from_ss   = ERACODE,
    keywords       = KEYWORDS,
    abstract       = ABSTRACT
  ) %>%
  mutate("ss_id"="MD_Rosen_24_Effec_Sc",
         "issue"=NA_character_)%>%
  
  select(ss_id,	authors,journal, booktitle,		article_number,
         start_page,	end_page,	issue,	title,	volume,	year,	doi,
         issn,url,code_from_ss,keywords,	abstract,study_type)%>%
  mutate(across(everything(), as.character))%>%
  distinct()



# ---- Source 2: sl_MD_Rosen_24_Effec_Sc_completed.csv ----
sl.data1<-sl.data1%>%
  # 1. Rename CSV columns to match the target (xlsx) schema
  #    Verified via join on B.Code == code_from_ss (950 overlapping studies)
  rename(
    "code_from_ss" = "B.Code",
    "authors"      = "B.Author.Last",
    "year"         = "B.Date",
    "journal"      = "B.Journal",
    "doi"          = "B.DOI",
    "url"          = "B.Url"
  )%>%
  select(code_from_ss,authors,year,journal,doi,url)%>%
  mutate("ss_id"="MD_Rosen_24_Effec_Sc",
         "study_type"="JA")

# ---- Merge / update sl.data with completed info ----
# Use code_from_ss as the join key; completed values overwrite base values where present
sl.data.completed<-sl.data1%>%
  left_join(
    sl.data, #%>% select(code_from_ss, authors, year, journal, doi, url),
    by = "code_from_ss",
    suffix = c("", "_completed")
  )%>% 
  mutate(
    authors = coalesce(as.character(authors_completed), as.character(authors)),
    journal = coalesce(as.character(journal_completed), as.character(journal)),
    year    = coalesce(as.character(year_completed), as.character(year)),
    doi     = coalesce(as.character(doi_completed), as.character(doi)),
    url     = coalesce(as.character(url_completed), as.character(url))
  ) %>%
  select(-ends_with("_completed"))%>%
  
  select(ss_id,	authors,journal, booktitle,		article_number,
         start_page,	end_page,	issue,	title,	volume,	year,	doi,
         issn,url,code_from_ss,keywords,	abstract,study_type)%>%
  mutate(status="I",
         exclusion_reason="",
         screen_person="ERA team",
         screen_date= "",
         study_id= "",
         country= "",
         RESPONSIBLE= ""
)

# ---- Filter to only studies in the "added_to" metadata ----
sl.data.completed$code_from_ss <- trimws(as.character(sl.data.completed$code_from_ss))

matched    <- sl.data.completed %>% filter(code_from_ss %in% keep_ids)
unmatched_ids <- setdiff(keep_ids, sl.data.completed$code_from_ss)


writexl::write_xlsx(sl.data.completed,
                    paste0(path.study.list,"/05.added_to_04_FOMD_screening/added_to_04_sl_MD_Rosen_24_Effec_Sc.xlsx"))
