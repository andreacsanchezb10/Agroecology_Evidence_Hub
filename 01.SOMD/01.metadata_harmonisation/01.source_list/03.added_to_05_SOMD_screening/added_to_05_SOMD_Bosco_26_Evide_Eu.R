library(readxl)
library(stringr)
library(dplyr)
library(tidyr)

path.studylist<-("C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/01.SOMD/01.metadata_harmonisation/01.source_list")
list.files(path.studylist)

path.metadata.structure<-("C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/01.SOMD/02.metadata_structure")
list.files(path.metadata.structure)

#==========================================================
# Read datasets
#==========================================================

#---Study list data 
sl.data <- read.csv(
  file = file.path(path.studylist, "01.searches/SOMD_Bosco_26_Evide_Eu.csv"),
  fileEncoding = "Latin1")
length(unique(sl.data$title)) #6232

sl.data_ss_type<-read.csv(file = file.path(path.studylist, "01.searches/SOMD_Bosco_26_Evide_Eu_ss_type.csv"))
length(unique(sl.data_ss_type$title))#615

sl.data_ss_metadata<-read.csv(file = file.path(path.studylist, "01.searches/SOMD_Bosco_26_Evide_Eu_metadata.csv"))
length(unique(sl.data_ss_metadata$doi))#615

#---05_SOMD_screening
somd05.names<-names(read_xlsx(file.path(path.metadata.structure,"05_SOMD_screening.xlsx"), sheet = "05_SOMD_screening"))
somd05.names

#==========================================================
# Rename relevant columns
#==========================================================
names(sl.data)
sl.data.rename<-sl.data
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
         "keywords"=NA,

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
sort(unique(sl.data.clean$status))
##--exclude duplicates by doi for included records
somd03.included<-sl.data.clean%>%
  filter(status=="Included") 

nrow(somd03.included) #808 
length(unique(somd03.included$doi)) #618

somd03.included<-somd03.included%>%
  distinct(doi, .keep_all = TRUE)

nrow(somd03.included) #618 
length(unique(somd03.included$doi)) #618

##-- exclude duplicates by title for excluded records
somd03.excluded.title<-sl.data.clean%>%
  filter(status!="Included")%>%
  filter(!is.na(title))

nrow(somd03.excluded.title) #14079 
length(unique(somd03.excluded.title$title)) #6090

somd03.excluded.title<-somd03.excluded.title%>%
  distinct(title, .keep_all = TRUE)

nrow(somd03.excluded.title) #6090 
length(unique(somd03.excluded.title$title)) #6090

##-- exclude duplicates by doi for excluded records
somd03.excluded.doi<-sl.data.clean%>%
  filter(status!="Included")%>%
  filter(is.na(title))

nrow(somd03.excluded.doi) #62 
length(unique(somd03.excluded.doi$doi)) #48

somd03.excluded.doi<-somd03.excluded.doi%>%
  distinct(doi, .keep_all = TRUE)

nrow(somd03.excluded.doi) #48 
length(unique(somd03.excluded.doi$doi)) #48


deduplicated.somd03 <- rbind(somd03.included,
                             somd03.excluded.title,
                             somd03.excluded.doi)
  
  
#==========================================================
# Select only necessary columns
#==========================================================
somd03<-deduplicated.somd03%>%    
  select(source_id,authors,	journal,	article_number,	start_page,	end_page,	
         issue,	title,	volume,	year,	doi,	issn,	ss_id_source,	keywords,	abstract,
         status
)%>%
  mutate(across(everything(), as.character))

#==========================================================
# Match with study type column
#==========================================================
somd05_ss_type<- somd03%>%
  left_join(sl.data_ss_type%>%
              select(doi, type),by="doi")%>%
  rename("ss_type"="type")
  filter(!is.na(ss_type))

names(somd05_ss_type) 
nrow(somd05_ss_type) #6756
length(unique(somd05_ss_type$title)) #6228


#==========================================================
# Add column were it specifies if the ss provide open access meta-data
#==========================================================
names(sl.data_ss_metadata)
somd05_metadata<- somd05_ss_type%>%
  left_join(sl.data_ss_metadata%>%
              distinct(doi, .keep_all = TRUE)%>%
              select(doi, dataset_available),by="doi")%>%
  rename("fomd_metadata_link"="dataset_available")
filter(!is.na(fomd_metadata_link))

names(somd05_metadata) 
length(unique(somd05_metadata$doi)) #6103


#==========================================================
# Add missing columns 
#==========================================================
somd05_metadata<-somd05_metadata%>%
  mutate(screen_person="JRC team"

)
names(somd05_metadata)



#==========================================================
# Unselect unnecessary columns
#==========================================================  
somd05.names <- unique(somd05.names)

#--- Clean biodiversity columns
# columns missing in somd05_metadata
missing_cols <- setdiff(somd05.names, names(somd05_metadata))

# add missing columns as NA
somd05.clean <- somd05_metadata

for (col in missing_cols) {
  somd05.clean[[col]] <- NA
}

# keep only columns in somd05.names, in the same order
somd05.clean <- somd05.clean[, somd05.names, drop = FALSE]

# check
list(
  only_in_fomd06.clean = setdiff(names(somd05.clean), somd05.names),
  only_in_fomd09.names = setdiff(somd05.names, names(somd05.clean))
)


names(somd05.clean)
length(unique(somd05.clean$title)) #6228


writexl::write_xlsx(somd05.clean, file.path(path.studylist,"03.added_to_05_SOMD_screening/added_to_05_SOMD_Bosco_26_Evide_Eu.xlsx"))



