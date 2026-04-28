library(readxl)
library(dplyr)
library(readxl)
library(tidyr)
library(openxlsx)

path.metadata<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Knowledge Hub - General/Agroecology_Knolwedge_Hub/02.FOMD/01.metadata_harmonisation/02.metadata/"
path.metadata.structure<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Knowledge Hub - General/Agroecology_Knolwedge_Hub/02.FOMD/02.metadata_structure/"
list.files(path.metadata)
list.files(paste0(path.metadata,"02.selected/"))

#==========================================================
# Read datasets
#==========================================================
#---04_FOMD_screening
fomd04<-read_xlsx(file.path(path.metadata.structure,"04_FOMD_screening.xlsx"), sheet = "04_FOMD_screening")%>%
  filter(ss_id=="MA_Sanch_22_Finan_Ec")%>%
  filter(status%in%c("PI","I","unresolved"))%>%
  select(ss_id,study_id_ss,study_id)
length(unique(fomd04$study_id)) #112

#---09_FOMD_metadata_extraction_long
fomd09.names<-names(read_xlsx(file.path(path.metadata.structure,"09_FOMD_metadata_extraction_long.xlsx"), sheet = "09_FOMD_metadata_extraction_lon"))
fomd09.names

#---Metadata dictionary
file_md <- file.path(path.metadata, "02.selected", "md_short_MA_Sanch_22_Finan_Ec.xlsx")
getSheetNames(file_md)
md.dic <- read.xlsx(file_md, sheet = "Data_dictionary")  


#---Metadata
md.data<-read.xlsx(file_md, sheet = "Data")%>%
  mutate(ID=as.character(ID))%>%
  select(-Year_assessment,
         -FAO_group_T_recla,
         -Crop_woodiness_T_recla,
         -Time_state_T)
  
  
#==========================================================
# Convert short version (intervention vs control) to long version (one row per practice)
#==========================================================
#--- Get control rows
md.data.C<-md.data%>%
  select(!ends_with("_T"))%>%
  select(!ends_with("_T_recla"))%>%
  rename_with(~ gsub("_C$", "", .x), ends_with("_C"))%>%
  distinct(across(-ES_ID), .keep_all = TRUE)

names(md.data.C)
length(sort(unique(md.data.C$ES_ID)))

#--- Get intervention rows
md.data.T<-md.data%>%
  select(!ends_with("_C"))%>%
  select(!ends_with("_C_recla"))%>%
  rename_with(~ gsub("_T$", "", .x), ends_with("_T"))%>%
  distinct(across(-ES_ID), .keep_all = TRUE)

names(md.data.T)
length(sort(unique(md.data.T$ES_ID)))


#--- Get data long version (one row per practice)
md.data.long<-rbind(md.data.C,md.data.T)
sort(unique(md.data.long$Year_assessment))
length(sort(unique(md.data.long$ID)))  #119
length(sort(unique(md.data.T$ID)))  #119
length(sort(unique(md.data.C$ID)))  #119

names(md.data.long)



#==========================================================
# Separate columns (country,sampling_year, crops) into multiple columns
#==========================================================
#--- Separate multiple countries into multiple columns
sort(unique(md.data.long$Country)) #35 countries
md.data.long.clean<-md.data.long%>%
  separate_wider_delim(
    cols = Country, 
    delim = ", ", 
    names = c("country01", "country02", "country03","country04","country05"),
    too_many = "merge",        # Combines Mexico and Brazil into 'country3'
    too_few = "align_start")
sort(unique(md.data.long.clean$country01)) #39 countries
sort(unique(md.data.long.clean$country02)) #0 countries

#--- Separate sampling_year_start and sampling_year_end 
sort(unique(md.data.long.clean$Year_assessment))
md.data.long.clean<-md.data.long.clean%>%
  separate_wider_delim(
    cols = Year_assessment, 
    delim = "-", 
    names = c("out_year_start", "out_year_end"),
    too_many = "merge",        #
    too_few = "align_start")
sort(unique(md.data.long.clean$out_year_start)) #44
sort(unique(md.data.long.clean$out_year_end)) #35

#--- Separate multiple crops into multiple columns
sort(unique(md.data.long$Crops_all))
md.data.long.clean<-md.data.long.clean%>%
  separate_wider_delim(
    cols = Crops_all, 
    delim = "- ", 
    names = c("crop01", "crop02", "crop03","crop04","crop05","crop06","crop07","crop08","crop09",
              "crop10","crop11","crop12","crop13","crop14","crop15"),
    too_many = "merge",        
    too_few = "align_start")
sort(unique(md.data.long.clean$crop01))
sort(unique(md.data.long.clean$crop02))
sort(unique(md.data.long.clean$crop03))
sort(unique(md.data.long.clean$crop04))
sort(unique(md.data.long.clean$crop05))
sort(unique(md.data.long.clean$crop06))
sort(unique(md.data.long.clean$crop07))
sort(unique(md.data.long.clean$crop08))
sort(unique(md.data.long.clean$crop09))
sort(unique(md.data.long.clean$crop10))

#--- Separate multiple trees into multiple columns
sort(unique(md.data.long.clean$crops_all_scientific))
sort(unique(md.data.long.clean$System))

md.data.long.clean<-md.data.long.clean%>%
  mutate(
    trees_scientific= if_else(
      System %in% c("Agroforestry", "Diversified other", "Embedded natural", "Simplified other"),
      crops_all_scientific, NA_character_))%>%
  separate_wider_delim(
    cols = trees_scientific, 
    delim = ", ", 
    names = c("tree01", "tree02", "tree03","tree04","tree05","tree06","tree07","tree08","tree09",
              "tree10","tree11","tree12","tree13","tree14","tree15"),
    too_many = "merge",        
    too_few = "align_start")
sort(unique(md.data.long.clean$tree01))
sort(unique(md.data.long.clean$tree11))
sort(unique(md.data.long.clean$tree10))

sort(unique(md.data.long.clean$tree15))


#==========================================================
# Add study_id 
#==========================================================
length(unique(fomd04$study_id)) #112
md.data.long.clean<-md.data.long.clean%>%
  left_join(fomd04,
            by=c("ID"="study_id_ss"))%>%
  filter(!is.na(study_id))

length(unique(md.data.long.clean$study_id)) #112
sort(unique(md.data.long.clean$ss_id))

#==========================================================
# Rename columns to match 09_FOMD_metadata_extraction_long names
#==========================================================

md.data.long.clean.rename<-md.data.long.clean%>%
  rename(
    ###---location
    #country01 =,
    "site_type01"="Farm_context",
    "site_id01" ="Location",
    #"site_admin01" ="",
    #site_agg01=,
    #site_latlong_type01=,
    #"site_location_type01"="",
    site_latitude01= Lat,
    site_longitude01= Long,
    #site_buffer01=,
    
    ###---experiment_details
    #exp_design
    #exp_plot_size
    exp_field_size=	Field_size,
    #exp_duration=,
    
    
    ###---experiment_time
    #time_raw=,
    #time_year_start=,
    #time_year_end=,
    #time_season=,
    
    ###---practice
    subpractice_raw= System_raw,
    subpractice_description_raw=System_details,
    practice_id=Comparison_ID,
    
    ###---soil_management_practice
    tillage_subpractice_raw=Soil_management,
    
    
    ###---nutrient_management_fert_moderator
    fert_inorganic_category=Fertiliser_chem,
    
    ###---nutrient_management_org_moderator	
    fert_organic_category=Fertiliser_org,
    
    
    ###---chemical_management_practice
    chem_subpractice_raw=Pesticide_names,

    
    ###---irrigation_practice	
    irrig_subpractice_raw=Irrigation,
    
    
    
    ###---out_exp_design
    out_exp_design= Financial_Sampling_unit,
    
    
    ###---product_outcome
    product_raw=Which_output,
    
    ###---input_outcome
    econ_inputs=Which_input,
    
    ###---outcome
    out_subindicator_raw= Financial_outcome_type,
    out_subindicator_description_raw=Financial_Sampling_method,
    out_subindicator_unit=Financial_metric_raw,
    
    ###---outcome_value
    #out_value_metric=,
    out_value= Financial_value_raw, 
    out_var_metric=Financial_error_measure,
    out_var_value=Financial_error_value_raw,
    outc_var_value_l=Financial_error_range_l_raw,
    outc_var_value_u=Financial_error_range_u_raw,
    out_sample_size=Financial_N,
    data_location=Notes
    
  )
names(md.data.long.clean.rename)

    
   
#----CREATE MISSING COLUMNS
fomd06<-md.data.long.clean.rename%>%
  mutate(out_value_metric="Mean")


#==========================================================
# Unselect unnecessary columns
#==========================================================  
fomd09.names <- unique(fomd09.names)

# columns missing in fomd06
missing_cols <- setdiff(fomd09.names, names(fomd06))

# add missing columns as NA
fomd06.clean <- fomd06

for (col in missing_cols) {
  fomd06.clean[[col]] <- NA
}

# keep only columns in fomd09.names, in the same order
fomd06.clean <- fomd06.clean[, fomd09.names, drop = FALSE]

# check
list(
  only_in_fomd06.clean = setdiff(names(fomd06.clean), fomd09.names),
  only_in_fomd09.names = setdiff(fomd09.names, names(fomd06.clean))
)
    
  
names(fomd06.clean)
  
#==========================================================
# Remove duplicate columns
#==========================================================  
nrow(fomd06.clean) #5976
nrow(distinct(fomd06.clean)) #1564

fomd06.clean<-fomd06.clean %>%
  distinct()

nrow(fomd06.clean) #1564
nrow(distinct(fomd06.clean)) #1564

readr::write_csv(fomd06.clean, paste0(path.metadata, "04.added_to_06_FOMD_metadata_original_long/added_to_06_MA_Sanch_22_Finan_Ec.csv"))


