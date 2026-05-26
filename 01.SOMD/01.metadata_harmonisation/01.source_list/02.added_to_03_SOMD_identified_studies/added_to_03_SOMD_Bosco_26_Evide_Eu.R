library(readxl)
library(stringr)
library(dplyr)
library(tidyr)

path.studylist<-("C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/01.SOMD/01.metadata_harmonisation/01.source_list")
list.files(path.studylist)

#==========================================================
# Read datasets
#==========================================================

#---Study list data 
sl.data <- read.csv(
  file = file.path(path.studylist, "01.searches/SOMD_Bosco_26_Evide_Eu.csv"),
  fileEncoding = "Latin1")
  
#14949 rows

#==========================================================
# Rename relevant columns
#==========================================================
names(sl.data)
sl.data.rename<-sl.data
  #separate_wider_delim(
   # cols = "Pages", 
  #delim = "-", 
  # names = c("start_page", "end_page"),
  # too_many = "merge",        # Combines Mexico and Brazil into 'country3'
  # too_few = "align_start")%>%
  #Rename columns to match with our dataset
  #rename(
    # "authors"="",
    # "journal"=" ",
    #"article_number"="",
    #"start_page"="",
    #"end_page"="",
    #issue=",
    #"title"="",
    #"volume"="" ,
    #"year"="Year_of_publication",
    #"doi"="",
    #"issn"=,
    #"ss_id_source"="",
    #"keywords"=","
    #"abstract"="Abstract Note"
  #)

#==========================================================
# Complete the source code
#==========================================================
sl.data.clean<-sl.data.rename%>%    
  mutate("source_id"="SOMD_Bosco_26_Evide_Eu",
         "issn"=NA,
         "ss_id_source"=doi,
         "keywords"=NA
         
  )%>%
  mutate(
    key_ty = paste0(title,doi,status,sep="/"))
  
names(sl.data.clean)

#==========================================================
# Remove duplicates
#==========================================================
#in the original dataset appears 14949 rows
length(unique(sl.data.clean$key_ty)) #7519

#==========================================================
# Dedup logic:
# - remove if DOI matches (only when DOI exists)
# - else (DOI missing): remove if title-authors matches (only when key_ty exists)
# - if DOI missing AND key_ty missing: KEEP (cannot safely match)
#==========================================================
deduplicated.somd03 <- sl.data.clean %>%
  distinct(key_ty, .keep_all = TRUE)

#==========================================================
# Select only necessary columns
#==========================================================
somd03<-deduplicated.somd03%>%    
  select(source_id,authors,	journal,	article_number,	start_page,	end_page,	
         issue,	title,	volume,	year,	doi,	issn,	ss_id_source,	keywords,	abstract
)%>%
  mutate(across(everything(), as.character))

names(somd03) 


writexl::write_xlsx(somd03, file.path(path.studylist,"02.added_to_03_SOMD_identified_studies/added_to_03_SOMD_Bosco_26_Evide_Eu.xlsx"))

