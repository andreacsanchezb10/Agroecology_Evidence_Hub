library(readxl)
library(dplyr)
library(readxl)
library(tidyr)
library(openxlsx)

path.metadata<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/01.metadata_harmonisation/02.metadata"
path.metadata.structure<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/02.metadata_structure"
list.files(path.metadata)
list.files(path.metadata.structure)
list.files(paste0(path.metadata,"/02.selected"))

#==========================================================
# Read datasets
#==========================================================
#---04_FOMD_screening
fomd04<-read_xlsx(file.path(path.metadata.structure,"/04_FOMD_screening.xlsx"), sheet = "04_FOMD_screening")%>%
  filter(ss_id=="MD_Paut,_24_A glo_Sc")%>%
  #filter(status%in%c("PI","I","unresolved"))%>%
  select(ss_id,study_id_ss,study_id)
length(unique(fomd04$study_id)) #274

#---09_FOMD_metadata_extraction_long
fomd09.names<-names(read_xlsx(file.path(path.metadata.structure,"09_FOMD_metadata_extraction_long.xlsx"), sheet = "09_FOMD_metadata_extraction_lon"))
fomd09.names

#---Metadata dictionary
file_md <- file.path(path.metadata, "02.selected", "md_MD_Paut,_24_A glo_Sc.xlsx")
getSheetNames(file_md)
md.dic <- read.xlsx(file_md, sheet = "data_dictionary")  


#---Metadata
md.data<-read.xlsx(file_md, sheet = "data")
  #mutate(ID=as.character(ID))
  #select(-Year_assessment,
   #      -FAO_group_T_recla,
    #     -Crop_woodiness_T_recla,
     #    -Time_state_T)


#==========================================================
# Convert short version (intervention vs control) to long version (one row per practice)
#==========================================================
#--- Get control rows
md.data.C1<-md.data%>%
  select(!ends_with("_intercropped"))%>%
  select(!ends_with("_intercrop"))%>%
  #select(!ends_with("_intercropping_calc"))%>%
  rename_with(~ gsub("_sole$", "", .x), ends_with("_sole"))%>%
    mutate(Crop_2_Common_Name=NA,
           Crop_2_Scientific_Name=NA,
           Crop_2_Variety=NA,
           C2_yield=NA,
           LER_crop1=NA,
           LER_crop2=NA,
           LER_tot=NA,
           Yield_total_intercropping_calc=NA)%>%
    filter(!is.na(C1_yield))

names(md.data.C1)
#length(sort(unique(md.data.C$ES_ID)))

md.data.C2<-md.data%>%
  select(!ends_with("_intercropped"))%>%
  select(!ends_with("_intercrop"))%>%
  #select(!ends_with("_intercropping_calc"))%>%
  rename_with(~ gsub("_sole$", "", .x), ends_with("_sole"))%>%
  mutate(Crop_1_Common_Name=NA,
         Crop_1_Scientific_Name=NA,
         Crop_1_Variety=NA,
         C1_yield=NA,
         LER_crop1=NA,
         LER_crop2=NA,
         LER_tot=NA,
         Yield_total_intercropping_calc=NA)%>%
  filter(!is.na(C2_yield))

names(md.data.C2)

#--- Get intervention rows
md.data.T<-md.data%>%
  select(!ends_with("_sole"))%>%
  #select(!ends_with("_C_recla"))%>%
  rename_with(~ gsub("_intercropped$", "", .x), ends_with("_intercropped"))%>%
  rename_with(~ gsub("_intercrop$", "", .x), ends_with("_intercrop"))
  filter(!(is.na(C1_yield)&is.na(C2_yield)))

names(md.data.T)
#length(sort(unique(md.data.T$ES_ID)))


#--- Get data long version (one row per practice)
md.data.long<-rbind(md.data.C1,md.data.C2 ,md.data.T)
#sort(unique(md.data.long$Year_assessment))
length(sort(unique(md.data.long$Id_article)))  #266
length(sort(unique(md.data.T$Id_article)))  #292
length(sort(unique(md.data.C1$Id_article)))  #256
length(sort(unique(md.data.C2$Id_article)))  #156

names(md.data.long)

#==========================================================
# Separate columns (country,sampling_year, crops) into multiple columns
#==========================================================
#--- Separate multiple countries into multiple columns
length(unique(md.data.long$Country)) #51 countries
(unique(md.data.long$Country)) #51 countries

md.data.long.clean<-md.data.long%>%
  separate_wider_delim(
    cols = Country, 
    delim = ", ", 
    names = c("country01", "country02", "country03","country04","country05"),
    too_many = "merge",        # Combines Mexico and Brazil into 'country3'
    too_few = "align_start")
sort(unique(md.data.long.clean$country01)) #51 countries
sort(unique(md.data.long.clean$country02)) #0 countries

#--- Separate Experiment_period and time_year_start  time_year_end
sort(unique(md.data.long.clean$Experiment_period))
md.data.long.clean<-md.data.long.clean%>%
  separate_wider_delim(
   cols = Experiment_period, 
   delim = "-", 
   names = c("time_year_start", "time_year_end"),
   too_many = "merge",        #
   too_few = "align_start")
sort(unique(md.data.long.clean$time_year_start)) #44
sort(unique(md.data.long.clean$time_year_end)) #35

#--- Separate Experiment_period and time_year_start  time_year_end
sort(unique(md.data.long.clean$Experiment_year))
md.data.long.clean<-md.data.long.clean%>%
  separate_wider_delim(
    cols = Experiment_year, 
    delim = "-", 
    names = c("out_year_start", "out_year_end"),
    too_many = "merge",        #
    too_few = "align_start")%>%
  mutate(out_year= if_else(is.na(out_year_end),out_year_start,NA ))
sort(unique(md.data.long.clean$out_year)) #44
sort(unique(md.data.long.clean$out_year_start)) #44
sort(unique(md.data.long.clean$out_year_end)) #35

#--- Separate multiple crops into multiple columns
#sort(unique(md.data.long$crops_all_common))
#md.data.long.clean<-md.data.long.clean%>%
#  mutate(
#    crops_all_common = str_replace_all(crops_all_common, ",\\s*", "; ")
#  ) %>%
#  separate_wider_delim(
#    cols = crops_all_common, 
#    delim = "; ", 
#    names = c("crop01", "crop02", "crop03","crop04","crop05","crop06","crop07","crop08","crop09",
#              "crop10","crop11","crop12","crop13","crop14","crop15"),
#    too_many = "merge",        
#    too_few = "align_start")
#sort(unique(md.data.long.clean$crop01))
#sort(unique(md.data.long.clean$crop02))
#sort(unique(md.data.long.clean$crop03))
#sort(unique(md.data.long.clean$crop04))
#sort(unique(md.data.long.clean$crop05))
#sort(unique(md.data.long.clean$crop06))
#sort(unique(md.data.long.clean$crop07))
#sort(unique(md.data.long.clean$crop08))
#sort(unique(md.data.long.clean$crop09))
#sort(unique(md.data.long.clean$crop10))
#sort(unique(md.data.long.clean$crop11))
#sort(unique(md.data.long.clean$crop12))
#sort(unique(md.data.long.clean$crop13))
#sort(unique(md.data.long.clean$crop14))
#sort(unique(md.data.long.clean$crop15))

#--- Separate multiple trees into multiple columns
#sort(unique(md.data.long.clean$crops_all_scientific))
#sort(unique(md.data.long.clean$System))

#md.data.long.clean<-md.data.long.clean%>%
#  mutate(
#    crops_all_scientific = str_replace_all(crops_all_scientific, ",\\s*", "; ")
#  ) %>%
#  mutate(
#    trees_scientific= if_else(
#      System %in% c("Abandoned", "Agroforestry", "Associated plant species", "Combined practices",
#                    "Embedded natural" , "Natural"    ),
#      crops_all_scientific, NA_character_))%>%
#  separate_wider_delim(
#   cols = trees_scientific, 
#    delim = "; ", 
#    names = c("tree01", "tree02", "tree03","tree04","tree05","tree06","tree07","tree08","tree09",
#              "tree10","tree11","tree12","tree13","tree14","tree15"),
#    too_many = "merge",        
#    too_few = "align_start")
#sort(unique(md.data.long.clean$tree01))
#sort(unique(md.data.long.clean$tree11))
#sort(unique(md.data.long.clean$tree10))

#sort(unique(md.data.long.clean$tree15))

#==========================================================
# Add study_id 
#==========================================================
length(unique(fomd04$study_id)) #274
md.data.long.clean<-md.data.long.clean%>%
  mutate(Id_article=as.character(Id_article)) %>%
  left_join(fomd04,
            by=c("Id_article"="study_id_ss"))%>%
  filter(!is.na(study_id))

length(unique(md.data.long.clean$Id_article)) #274
sort(unique(md.data.long.clean$ss_id))

#==========================================================
# Rename columns to match 09_FOMD_metadata_extraction_long names
#==========================================================
#md.data.long.clean$Comparison_ID
#sort(unique(md.data.long.clean$Comparison_class))
names(md.data.long.clean)

md.data.long.rename<-md.data.long.clean%>%
  rename(
    ###---location 9 columns
    #country01 =,
    "site_type01"="Greenhouse",
    "site_id01" ="Study_site",
    #"site_admin01" ="",
    #site_agg01=,
    "site_latlong_type01"= "Geocoordinates",
    "site_latitude01"= "Latitude",
    "site_longitude01"= "Longitude",
    #site_buffer01=,
    
    ###---experiment_details 4 columns
    #exp_design
    #exp_plot_size
    #exp_field_size=	Farm_size,
    #exp_duration= Study_length,
    
    ###---experiment_time 4 columns
    #time_raw=,
    #time_year_start=,
    #time_year_end=,
    #time_season=,
    
    ###---crop commodity
    "crop01"="Crop_1_Common_Name",
    "crop_variety01"="Crop_1_Variety",
    "crop02"="Crop_2_Common_Name",
    "crop_variety02"="Crop_2_Variety",
    
    ###---practice
    "subpractice_description_raw"= "Additional_factor",
    #subpractice_description_raw=System_details,
    #practice_id=Comparison_ID,
    #system_type=Comparison_class,
    
    ###---soil_management_practice
    #tillage_subpractice_raw=Soil_management,
    
    ###---intercropping_practice
    "intercrop_subpractice"="Comb_Nf",
    "intercrop_design"="Intercropping_design",
    "intercrop_pattern"="Intercropping_pattern",
    
    ###---agroforestry_practice
    "agrof_subpractice_raw"="AF",
    
    ###---nutrient_management_fert_moderator
    "fert_inorganic_category"="Mineral_ferti",
    "fert_inorganicN"="Nitrogen_rate",
    
    ###---nutrient_management_org_moderator	
    "fert_organic_category"="Organic_ferti",
    
    ###---chemical_management_practice
    "chem_subpractice01"= "Herbicide",
    "chem_subpractice02"= "Insecticide",
    "chem_subpractice03"="Fungicide",
    
    ###---irrigation_practice	
    "irrig_subpractice_raw"="Irrigation",
    
    ###---out_exp_design
    #out_exp_design= Sampling_unit,
    
    ###---product_outcome
    #product_raw=Taxa_details,
    #product_component01=Taxa,
    #bio_func_group=Functional_group,
    #bio_ground_ref=B_ground,
    
    ###---input_outcome
    #econ_inputs=,
    
    ###---outcome
    "out_subindicator_raw"= "Yield_measure",
    #out_subindicator_description_raw=,
    "out_subindicator_unit"= "Yield_unit",
    
    ###---outcome_value
    #out_value_metric=,
    #out_value= B_value, 
    #out_var_metric=B_error_measure,
    #out_var_value=B_error_value,
    #outc_var_value_l=B_error_range_l,
    #outc_var_value_u=B_error_range_u,
    #out_sample_size=B_N,
    "out_value_product_component01"="C1_yield",
    "out_value_product_component02"="C2_yield",
    "ler_value_product_component01"="LER_crop1",
    "ler_value_product_component02"="LER_crop2",
    "ler_value_total"="LER_tot",
    
    
    "data_location"="Data_location"
    
  )%>%
  mutate(
    ###---intercropping_practice
    intercrop_subpractice_raw=subpractice_description_raw,
    
    ###---product_outcome
    product_component01=crop01,
    product_component02=crop02)

names(md.data.long.rename)
sort(unique(md.data.long.rename$product_component02))

#----CREATE MISSING COLUMNS
md.data.long.rename<-md.data.long.rename%>%
  mutate(
    ###---location
    #site_latlong_type01= case_when(!is.na(site_latitude01)~"Original",TRUE~NA),
    site_type01= case_when(site_type01=="yes"~"Greennhouse",
                           site_type01=="yes (plastic walk-in tunnels)"~"Greennhouse (plastic walk-in tunnels)",
                           TRUE~NA),
    site_buffer01=case_when(!is.na(site_latitude01)~"Unspecified",TRUE~NA),
    
    ###---experiment_details
    #exp_duration=as.numeric(exp_duration),
    #exp_duration=exp_duration/365,
    ###---practice
    #system_type=case_when(system_type%in%c("Diversified","Simplified" )~"cropland",TRUE~"natural/seminatural"),
    
    ###---intercropping_practice
    intercrop_subpractice=case_when(intercrop_subpractice%in%c("no-yes","yes-no",  "yes-yes")~"N fixing",TRUE~intercrop_subpractice),
    
    ###---agroforestry_practice
    agrof_subpractice_raw=case_when(agrof_subpractice_raw=="yes"&!is.na(subpractice_description_raw)~subpractice_description_raw,
                                    agrof_subpractice_raw=="yes"&!is.na(subpractice_description_raw)~"Agroforestry",TRUE~NA),
    
    ###---nutrient_management_fert_moderator
    "fert_inorganicNPK_unit"=case_when(!is.na(fert_inorganicN)~"kg/ha",TRUE~NA),
    
    ###---chemical_management_practice
    "chem_subpractice01"= case_when(chem_subpractice01=="yes"~"Herbicide",TRUE~NA),
    "chem_subpractice02"= case_when(chem_subpractice02=="yes"~"Insecticide",TRUE~NA),
    "chem_subpractice03"=case_when(chem_subpractice03=="yes"~"Fungicide",TRUE~NA),
      
    ###---outcome_value
    #out_value_metric="Mean"
         
         )

#==========================================================
# Unselect unnecessary columns
#==========================================================  
fomd09.names <- unique(fomd09.names)
fomd09.names

#--- Clean columns
# columns missing in md.data.long.rename
missing_cols <- setdiff(fomd09.names, names(md.data.long.rename))
missing_cols
# add missing columns as NA
fomd06.clean <- md.data.long.rename

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
nrow(fomd06.clean) #4715
nrow(distinct(fomd06.clean)) #4480

fomd06.clean<-fomd06.clean %>%
  distinct()

nrow(fomd06.clean) #4480
nrow(distinct(fomd06.clean)) #4480

readr::write_csv(fomd06.clean, paste0(path.metadata, "/04.added_to_06_FOMD_metadata_original_long/added_to_06_MD_Paut,_24_A glo_Sc.csv"))


