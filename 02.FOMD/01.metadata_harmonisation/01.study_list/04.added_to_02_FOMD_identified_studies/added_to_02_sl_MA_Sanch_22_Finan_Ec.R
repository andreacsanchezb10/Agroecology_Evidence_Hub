library(readxl)
library(dplyr)

setwd("C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Knowledge Hub - General/Agroecology_Knolwedge_Hub/03.FOMD_datasets/FOMD_study_list/")

#==========================================================
# Read datasets
#==========================================================
#---Study list dictionary 
sl.dic<-read_xlsx(path = "02.selected/sl_MA_Sanch_22_Finan_Ec.xlsx", sheet ="Data_dictionary")

#---Study list data 
sl.data<-read_xlsx(path = "02.selected/sl_MA_Sanch_22_Finan_Ec.xlsx", sheet="Literature_screened")
         
#==========================================================
# Filter included studies only
#==========================================================
sl.data<-sl.data%>%
  #Filter included studies only
  filter(Inclusion_yes_no %in% c("yes","Yes"))
  
#==========================================================
# Rename relevant columns
#==========================================================
sl.data<-sl.data%>% 
  rename(
    "authors"="Authors",
    "journal"="Source.title",
    "article_number"="Art_No",
    "start_page"="Page_start",
    "end_page"="Page_end",
    "issue"="Issue",
    "title"="Title",
    #"study_type"="",
    "volume"="Volume",
    "year"="Year",
    "doi"="DOI",
    "issn"="ISSN",
    "code_from_ss"="ID"
    #"keywords"=","
    #"abstract"="",
    
      )
#==========================================================
# Complete the source code
#==========================================================
  mutate("ss_id"="MA_Sanch_22_Finan_Ec",
         "booktitle"=NA,
         "url"=NA ,
         "keywords"=NA,
         "abstract"=NA,
         "study_type"="JA"
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

writexl::write_xlsx(sl.data,"02.added_to_04_FOMD_identified_studies/added_to_02_sl_MA_Sanch_22_Finan_Ec.xlsx")

