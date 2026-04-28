library(readxl)
library(dplyr)

setwd("C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Knowledge Hub - General/Agroecology_Knolwedge_Hub/03.FOMD_datasets/FOMD_study_list/")

# Article list data dictionary
#sl.dic<-read_xlsx(path = "datasets/pa_article_list/pending/", sheet ="")

# Article list data dictionary
sl.data<-read.csv("02_selected/sl_MD_Rosen_24_Effec_Sc.csv",header = TRUE, sep = ",")

sl.data<-sl.data%>%
  tidyr::separate(col="PAGES", into= c("start_page","end_page"), sep="--", remove=TRUE, convert=TRUE)%>%
  mutate(CATEGORY=case_when(
    CATEGORY=="ARTICLE"~"article",
    CATEGORY=="INCOLLECTION"~"incollection",
  ))%>%
  
  mutate(TYPE=case_when(
    TYPE=="Journal Article"~"JA",
    TYPE=="Serial"~"S",
    TRUE~NA
  ))%>%
  
  #Rename columns to match with our dataset
  dplyr::rename(
    "category"="CATEGORY",
    "authors"="AUTHOR",
    "booktitle"="BOOKTITLE",
    "journal"="JOURNAL",
    "article_number"="NUMBER",
    #"start_page"="start_page,
    #"end_page"="end_page,
    #"issue"	=,
    "title"="TITLE",
    "study_type"="TYPE",
    "volume"="VOLUME",
    "year"="YEAR",
    "doi"="DOI",
    "issn"="ISSN",
    "url"="URL",
    "code_from_ss"="ERACODE",
    "keywords"="KEYWORDS",
    "abstract"="ABSTRACT"
  )%>%
  #Complete the source code
  mutate("ss_id"="MD_Rosen_24_Effec_Sc",
         "issue"=NA)%>%
  
  select(ss_id,	authors,journal, booktitle,		article_number,
         start_page,	end_page,	issue,	title,	volume,	year,	doi,
         issn,url,code_from_ss,keywords,	abstract,study_type)%>%
  mutate(across(everything(), as.character))

sapply(sl.data,class)
names(sl.data)

writexl::write_xlsx(sl.data,"04_added_to_04_FOMD_identified_studies/added_to_04_sl_MD_Rosen_24_Effec_Sc.xlsx")
