library(readxl)
library(dplyr)
library(tidyr)

path.studylist<-setwd("C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/01.metadata_harmonisation/01.study_list")
list.files(path.studylist)

#==========================================================
# Read datasets
#==========================================================
#---Study list dictionary 
sl.dic<-read_xlsx(path = "02.selected/sl_MD_Paut,_24_A glo_Sc.xlsx", sheet ="data_dictionary")

#---Study list data 
sl.data<-read_xlsx(path = "02.selected/sl_MD_Paut,_24_A glo_Sc.xlsx", sheet="data")
sl.biblio_info<-read_xlsx(path = "02.selected/sl_MD_Paut,_24_A glo_Sc.xlsx", sheet="biblio_info")

         
#==========================================================
# Filter included studies only
#==========================================================
#sl.data<-sl.data%>%
 # filter(Inclusion_yes_no %in% c("yes","Yes"))
names(sl.data)
#==========================================================
# Match study list with bibliographic information
#==========================================================
sl.data.clean<- sl.data%>%
  select("Id_article" ,	 "Authors","Title" ,"DOI","Year_of_publication")%>%
  distinct()%>%
  left_join(sl.biblio_info, by=c("DOI"))

#==========================================================
# Rename relevant columns
#==========================================================
names(sl.data.clean)
sl.data<-sl.data.clean%>% 
  separate_wider_delim(
    cols = "Pages", 
    delim = "-", 
    names = c("start_page", "end_page"),
    too_many = "merge",        # Combines Mexico and Brazil into 'country3'
    too_few = "align_start")%>%
  #Rename columns to match with our dataset
  rename(
    "authors"="Authors",
    "journal"="Journal Abbreviation",
    #"article_number"="",
    #"start_page"="",
    #"end_page"="",
    "title"="Title.x",
    "study_type"="Item Type" ,
    "year"="Year_of_publication",
    "doi"="DOI",
    "code_from_ss"="Id_article",
    #"keywords"=","
    "abstract"="Abstract Note",
    "url"="Url",
    "issn"= "ISSN",
    "volume"="Volume",
    "issue"="Issue" ,
    "study_type"="Item Type" 
    
      )

#==========================================================
# Complete the source code
#==========================================================
sl.data<-sl.data%>%    
  mutate("ss_id"="MD_Paut,_24_A glo_Sc",
         
         "article_number"=NA,
         "booktitle"=NA,
         
         "keywords"=NA
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

