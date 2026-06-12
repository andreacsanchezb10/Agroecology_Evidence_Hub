library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(readr)
library(tibble)
library(purrr)

path.metadata.added10<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/01.metadata_harmonisation/02.metadata/04.added_to_06_FOMD_metadata_original_long"


#==========================================================
# Read datasets
#==========================================================
#---added_to_10_MD_Rosen_24_Effec_Sc
fomd10.MD_Rosen_24_Effec_Sc <- read.csv(file.path(path.metadata.added10, "added_to_10_MD_Rosen_24_Effec_Sc.csv"))
nrow(fomd10.MD_Rosen_24_Effec_Sc) #232257
fomd10.MD_Rosen_24_Effec_Sc <-fomd10.MD_Rosen_24_Effec_Sc%>%
  filter(!is.na(C_out_value))%>% #231182
  filter(!is.na(T_out_value)) #231181
nrow(fomd10.MD_Rosen_24_Effec_Sc) #231181

sort(unique(fomd10.MD_Rosen_24_Effec_Sc$C_out_value))
is.na(fomd10.MD_Rosen_24_Effec_Sc$C_out_value)

#---CFRA countries

  

#==========================================================
#--- Filter only relevant rows
#==========================================================
#--- Relevant countries----
sort(unique(fomd10.MD_Rosen_24_Effec_Sc$country))

cfra.countries<-c("Angoloa",
                  "Burundi",
                  "Ethiopia",
                  "Kenya",
                  "Malawi",
                  "Rwanda",
                  "Tanzania",
                  "Uganda",
                  "Zambia")

pattern.countries <- paste(cfra.countries, collapse = "|")

# Filter rows where country contains any of the target countries
fomd10.cfra <- fomd10.MD_Rosen_24_Effec_Sc %>%
  filter(grepl(pattern.countries, country, ignore.case = TRUE))

sort(unique(fomd10.cfra$country))
sort(unique(fomd10.cfra$C_site_latitude))
sort(unique(fomd10.cfra$T_site_latitude))

#--- Relevant out_subindicators----
#Biodiversity, Resilience, 
#resilience, carbon sequestration, soil fertility, productivity
sort(unique(fomd10.cfra$out_subindicator))
sort(unique(fomd10.cfra$out_subindicator[is.na(fomd10.cfra$out_indicator)])) 
sort(unique(fomd10.cfra$out_indicator)) #16 
#[1] "Animal Survival"      "Biodiversity"         "Carbon Stocks"        "Costs"                "Economic Performance"
#[6] "Efficiency"           "Emissions"            "Feed Intake"          "Fuel Efficiency"      "Gender Equity"       
#[11] "Income"               "Labour"               "Non-Product Yield"    "Pest & Pathogen"      "Product Yield"       
#[16] "Soil Quality"

cfra.indicators<-c("Biodiversity",
                   "Carbon Stocks",
                   "Costs"  ,
                   "Economic Performance",
                   "Efficiency" ,
                   "Emissions",
                   "Gender Equity",
                   "Income" ,
                   "Labour",
                   "Pest & Pathogen",
                   "Product Yield" ,
                   "Soil Quality")
 

# Filter rows where out_indicator contains any of the target indicators
fomd10.cfra <- fomd10.cfra %>%
  filter(tolower(out_indicator) %in% tolower(cfra.indicators))

sort(unique(fomd10.cfra$out_indicator)) #12
sort(unique(fomd10.cfra$out_subindicator[fomd10.cfra$out_indicator== "Costs"])) 

#==========================================================
#--- Report n_rows and n_studies
#==========================================================
# Per cfra country
fomd10.cfra %>%
  group_by(country) %>%
  summarise(
    n_rows     = n(),
    n_studies  = n_distinct(study_id)
  ) %>%
  arrange(desc(n_rows))

# Per indicators (Productivity, Resilience, Biodiversity) 
subindicator<-fomd10.cfra %>%
  filter(country=="Ethiopia")%>%
  group_by(out_subindicator) %>%
  summarise(
    n_rows     = n(),
    n_studies  = n_distinct(study_id)
  ) %>%
  arrange(desc(n_rows))


