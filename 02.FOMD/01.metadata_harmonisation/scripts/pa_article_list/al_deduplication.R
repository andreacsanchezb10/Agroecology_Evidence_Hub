library(readxl)
library(dplyr)

setwd("C:/Users/andreasanchez/OneDrive - CGIAR/Bioversity/meta-analysis/combining_datasets/datasets/pa_article_list/")


# Article list data dictionary
al.dic<-read_xlsx(path = "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Knowledge Hub - General/databases_structure/pa_structure/04_pa_identified_studies.xlsx", sheet ="04_pa_readme")

# Article list
al<-read_xlsx(path = "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Knowledge Hub - General/databases_structure/pa_structure/04_pa_identified_studies.xlsx", sheet="04_pa_identified_studies")
names(al)
any(is.na(al$title))
sum(is.na(al$title))

any(is.na(al$doi))
sum(is.na(al$doi))

#identify duplicate studies by title
al.duplicates.title <- al %>%
  group_by(title,year) %>%
  filter(n() > 1) %>%
  ungroup()

remove.al.duplicates.title<-al%>%
  filter(source_code=="MA_Sanch_22_Finan_Ec")%>% #Ready
  anti_join(al.duplicates.title, by = "title")

deduplicated.al<-remove.al.duplicates.title%>%
  mutate(category=NA,
         status=NA,	
         "type"=NA,	
         "exclusion_reason"=NA,	
         "code"=NA
         )%>%
  select("source_code","category","authors","booktitle","journal",
         "article_number","start_page","end_page","issue" ,"title" ,"volume" ,"year" ,
         "doi","issn" ,"url" , "code_from_source", "keywords","abstract", "status",	"type",	"exclusion_reason",	"code")
       
sapply(deduplicated.al,class)

writexl::write_xlsx(deduplicated.al,"deduplicated_al_MA_Sanch_22_Finan_Ec.xlsx")

