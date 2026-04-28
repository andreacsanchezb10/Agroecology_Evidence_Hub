library(readxl)
library(dplyr)


path.studylist<-setwd("C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/01.metadata_harmonisation/01.study_list")
list.files(path.studylist)

#==========================================================
# Read datasets
#==========================================================
#---Study list dictionary 
sl.dic<-read_xlsx(path = "02.selected/sl_MD_Paut,_24_A glo_Sc.xlsx", sheet ="data_dictionary")

#---Study list data 
sl.data<-read_xlsx(path = "02.selected/sl_MD_Paut,_24_A glo_Sc.xlsx", sheet="data")
         
#==========================================================
# Filter included studies only
#==========================================================
#sl.data<-sl.data%>%
 # filter(Inclusion_yes_no %in% c("yes","Yes"))

#==========================================================
# Rename relevant columns
#==========================================================
sl.data<-sl.data%>%  
  #Rename columns to match with our dataset
  rename(
    "authors"="Authors",
    #"journal"="",
    #"article_number"="",
    #"start_page"="",
    #"end_page"="",
    #"issue"="",
    "title"="Title",
    #"study_type"="",
    #"volume"="",
    "year"="Year_of_publication",
    "doi"="DOI",
    #"issn"="",
    "code_from_ss"="Id_article"
    #"keywords"=","
    #"abstract"="",
    
      )

#==========================================================
# Complete the source code
#==========================================================
sl.data<-sl.data%>%    
  mutate("ss_id"="MD_Paut,_24_A glo_Sc",
         "journal"=NA,
         "article_number"=NA,
         "start_page"=NA,
         "end_page"=NA,
         "issue"=NA,
         "booktitle"=NA,
         "url"=NA ,
         "keywords"=NA,
         "abstract"=NA,
         "volume"=NA,
         "study_type"="JA",
         "issn"=NA,
         )

#==========================================================
# Select only necessary columns
#==========================================================
sl.data<-sl.data%>%    
  select(ss_id,	authors,journal, booktitle,		article_number,
         start_page,	end_page,	issue,	title,	volume,	year,	doi,
         issn,url,code_from_ss,keywords,	abstract,study_type)%>%
  mutate(across(everything(), as.character))

sapply(sl.data,class)
names(sl.data)

writexl::write_xlsx(sl.data,"04.added_to_02_FOMD_identified_studies/added_to_02_sl_MD_Paut,_24_A glo_Sc.xlsx")

