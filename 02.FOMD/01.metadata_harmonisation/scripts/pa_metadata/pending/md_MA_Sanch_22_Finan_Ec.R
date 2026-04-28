library(openxlsx)
library(dplyr)
library(tidyr)


setwd("C:/Users/andreasanchez/OneDrive - CGIAR/Bioversity/meta-analysis/combining_datasets/datasets/pa_metadata/pending/")

#Article list
al.data<-read.xlsx("C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Knowledge Hub - General/databases_structure/pa_structure/06_pa_screening.xlsx", sheet = "06_pa_screening")%>%
  filter(source_code=="MA_Sanch_22_Finan_Ec",
         status=="P"
         )%>%
  select(source_code,code_from_source,code)
names(al.data)


# Metadata dictionary
md.dic <- read.xlsx("md_short_MA_Sanch_22_Finan_Ec.xlsx", sheet = "Data_dictionary")

# Meta data
md.data<-read.xlsx("md_short_MA_Sanch_22_Finan_Ec.xlsx", sheet = "Data")%>%
  mutate(ID = as.character(ID)) %>%
  left_join(al.data,by=c("ID"="code_from_source"))%>%
  filter(!is.na(code))
names(md.data)

#select only necessary columns
md.data<-md.data%>%
  select(ID,
         Experiment_stage,
         Comparison_ID_C,
         Comparison_class_C,
         Crops_all_C,
         crops_all_scientific_C,
         Main_crop_C,
         Main_Crop_scientific_C,
         -Crop_FAO_C,
         -Crop_duration_C,
         -Crop_woodiness_C,
         System_raw_C,
         System_details_C,
         System_C,
         Crop_species_richness_C,
         Crop_variety_richness_C,
         Year_assessment_C,
         Financial_outcome,
         Financial_outcome_type,
         Which_input_C,
         Which_output_C,
         How_many_inputs_C,
         How_many_outputs_C,
         Financial_metric_raw,
         Financial_value_raw_C,
         Financial_error_measure_C,
         Financial_error_value_raw_C,
         Financial_error_range_l_raw_C,
         Financial_error_range_u_raw_C,
         Financial_SD_raw_C,
         Financial_N_C,
         Financial_Sampling_unit_C,
         Financial_Sampling_method_C,
         Labor_measure_C,
         Labor_input_C,
         Fuel_measure_C,
         Fuel_input_C,
         Electricity_measure_C,
         Electricity_input_C,
         Repair_measure_C,
         Repair_input_C,
         Seed_measure_C,
         Seed_input_C,
         Fertiliser_chem_C,
         Fertiliser_org_C,
         Fertiliser_chem_quant_C,
         Fertiliser_org_quant_C,
         Pesticide_C,
         Pesticide_names_C,
         Pesticide_quantity_C,
         Input_type_C,
         Soil_type_C,
         Soil_management_C,
         Irrigation_C,
        # Time_state_C, #it doesn't exist
         -Yield_metric_C,
         -Yield_value_C,
         -Yield_SD_C,
         -Yield_N_C,
         -Yield_all_availability_C,
         -Yield_sampling_unit_C,
         -Yield_sampling_method_C,
         Field_size_C,
         Farm_context_C,
         Lat_C,
         Long_C,
         Landscape_context_C,
         Location_C,
         Notes_C,
         Comparison_ID_T,
         Comparison_class_T,
         Crops_all_T,
         crops_all_scientific_T,
         Main_crop_T,
         Main_Crop_scientific_T,
         -Crop_FAO_T,
         -Crop_duration_T,
         -Crop_woodiness_T,
         System_raw_T,
         System_details_T,
         System_T,
         Crop_species_richness_T,
         Crop_variety_richness_T,
         Year_assessment_T,
         Which_input_T,
         Which_output_T,
         How_many_inputs_T,
         How_many_outputs_T,
         Financial_value_raw_T,
         Financial_error_measure_T,
         Financial_error_value_raw_T,
         Financial_error_range_l_raw_T,
         Financial_error_range_u_raw_T,
         Financial_SD_raw_T,
         Financial_N_T,
         Financial_Sampling_unit_T,
         Financial_Sampling_method_T,
         Labor_measure_T,
         Labor_input_T,
         Fuel_measure_T,
         Fuel_input_T,
         Electricity_measure_T,
         Electricity_input_T,
         Repair_measure_T,
         Repair_input_T,
         Seed_measure_T,
         Seed_input_T,
         Fertiliser_chem_T,
         Fertiliser_org_T,
         Fertiliser_chem_quant_T,
         Fertiliser_org_quant_T,
         Pesticide_T,
         Pesticide_names_T,
         Pesticide_quantity_T,
         Input_type_T,
         Soil_type_T,
         Soil_management_T,
         Irrigation_T,
         -Yield_metric_T,
         -Yield_value_T,
         -Yield_SD_T,
         -Yield_N_T,
         -Yield_all_availability_T,
         -Yield_sampling_unit_T,
         -Yield_sampling_method_T,
         Field_size_T,
         Farm_context_T,
         Lat_T,
         Long_T,
         Landscape_context_T,
         Location_T,
         Notes_T,
         Country,
         -Continent,
         -UN_subregion,
         -UN_Development_status,
         -Year_assessment,
         -Year_assessment_range,
         -labour_difference_TC,
         -FAO_group_T_recla,
         -Crop_woodiness_T_recla,
         -Fertiliser_chem_CT,
         -Pesticide_CT,
         -Input_type_CT,
         -Irrigation_CT,
         -Soil_management_CT,
         -Diversified_system,
         -Validity_Financial_N_C,
         -Validity_Financial_N_T,
         -Validity_inputs_outputs_C,
         -Validity_inputs_outputs_T,
         -Validity_year_assessment,
         -Validity_Fertiliser_chem_CT,
         -Validity_Pesticide_CT,
         -Validity_Irrigation_CT,
         -Validity_Soil_management_CT,
         -Validity_overall,
         ES_ID,
         -Financial_mean,
         -Financial_var,
         -Financial_se,
         -Financial_precision,
         -effect_size,
         -Financial_mean_percentage,
        - Financial_var_percentage,
         -Reference,
        source_code,
        code)

names(md.data)
sort(unique(md.data$code))

# Get control rows
md.data.control<-md.data%>%
  select(!ends_with("_T"))%>%
  rename_with(~ gsub("_C$", "", .x), ends_with("_C"))%>%
  distinct(across(-ES_ID), .keep_all = TRUE)

names(md.data.control)
length(sort(unique(md.data.control$ES_ID)))

# Get intervention rows
md.data.intervention<-md.data%>%
  select(!ends_with("_C"))%>%
  rename_with(~ gsub("_T$", "", .x), ends_with("_T"))%>%
  distinct(across(-ES_ID), .keep_all = TRUE)

names(md.data.intervention)
length(sort(unique(md.data.intervention$ES_ID)))

# Get data long version
md.data.long<-rbind(md.data.control,md.data.intervention)
sort(unique(md.data.long$code))
sort(unique(md.data.long$Year_assessment))
names(md.data.long)

#separate multiple countries into multiple columns
md.data.long.clean<-md.data.long%>%
  separate_wider_delim(
    cols = Country, 
    delim = ", ", 
    names = c("country1", "country2", "country3","country4","country5"),
    too_many = "merge",        # Combines Mexico and Brazil into 'country3'
    too_few = "align_start")

#separate sampling_year_start and sampling_year_end 
md.data.long.clean<-md.data.long.clean%>%
  separate_wider_delim(
    cols = Year_assessment, 
    delim = ", ", 
    names = c("sampling_year_start", "sampling_year_end"),
    too_many = "merge",        #
    too_few = "align_start")



length(unique(md.data.long.clean$ID))#115
names(md.data.long.clean)

#Rename columns
md.data.long.clean<-md.data.long.clean%>%
  rename(
    #"code"="",
    "code_from_source"="ID",
    #"country1"="",
    "site_type1"="Farm_context",
    "site_name1"="Location",
    #"location_type1"="",
    "lat1"="Lat",
    "lon1"="Long",
    "outcome_metric_raw"="Financial_outcome",
    "outcome_metric_raw_description"="Financial_outcome_type",
    "outcome_unit_raw"="Financial_metric_raw",
    #"outcome_metric"="",
    #"suboutcome"="",
    #"outcome_unit"="",	
    #"outcome_mean_metric"="",
    "outcome_mean_value"="Financial_value_raw",
    "outcome_variance_metric"="Financial_error_measure",
    "outcome_variance_value_l"="Financial_error_range_l_raw",	
    "outcome_variance_value_u"="Financial_error_range_u_raw",	
    "outcome_variance_value"="Financial_error_value_raw",	
    "outcome_sd_value"="Financial_SD_raw",
    "outcome_sampling_size"	="Financial_N",	
    "data_location"="Notes")
    #"sampling_strategy"="",		
    #"sampling_duration"="",	
    #"sampling_year"="",	
    #"sampling_year_start"="",	
    #"sampling_year_end"="")
    
    

names(md.data.long.clean)

md.data.long.clean<-md.data.long.clean%>%
  mutate(
    #source_code=NA,
    #code=NA,
    #code_from_source=NA,
    #country1=NA,
    #site_type1=NA,
    #site_name1=NA,
    location_type1=NA,
    #lat1=NA,
    #lon1=NA,
    location_uncertanty1=NA,
    location_accuracy1=NA,
    country2=NA,	
    site_type2=NA,
    site_name2=NA,
    location_type2=NA,
    lat2=NA,
    lon2=NA,
    location_uncertanty2=NA,	
    location_accuracy2=NA,
    country3=NA,
    site_type3=NA,
    site_name3=NA,
    location_type3=NA,
    lat3=NA,
    lon3=NA,
    location_uncertanty3=NA,
    location_accuracy3=NA,
    country4=NA,
    site_type4=NA,
    site_name4=NA,	
    location_type4=NA,
    lat4=NA,
    lon4=NA,
    location_uncertanty4=NA,
    location_accuracy4=NA,	
    country5=NA,	
    site_type5=NA,
    site_name5=NA,
    location_type5=NA,
    lat5=NA,
    lon5=NA,
    location_uncertanty5=NA,
    location_accuracy5=NA,
    #outcome_metric_raw=NA,
    #outcome_metric_raw_description=NA,
    #outcome_unit_raw=NA,
    outcome_metric=NA,
    suboutcome=NA,
    outcome_unit=NA,
    outcome_mean_metric=NA
    #outcome_mean_value=NA,
    #outcome_variance_metric=NA,
    #outcome_variance_value_l=NA,	
    #outcome_variance_value_u=NA,
    #outcome_variance_value=NA,
    #outcome_sd_value=NA,
    #outcome_sampling_size=NA,
    #data_location=NA
  )
    sampling_strategy=NA,	
    sampling_duration=NA,	
    sampling_year=NA,	
    #sampling_year_start=NA,	
    #sampling_year_end=NA
    )
names(md.data.long.clean)

md.data.long.clean<-md.data.long.clean%>%
  select("source_code", "code","code_from_source",
         "country1","site_type1",	"site_name1",	"location_type1",	"lat1",	"lon1",	"location_uncertanty1",	"location_accuracy1",
         "country2","site_type2",	"site_name2",	"location_type2",	"lat2",	"lon2",	"location_uncertanty2",	"location_accuracy2",
         "country3","site_type3",	"site_name3",	"location_type3",	"lat3",	"lon3",	"location_uncertanty3",	"location_accuracy3",
         "country4","site_type4",	"site_name4",	"location_type4",	"lat4",	"lon4",	"location_uncertanty4",	"location_accuracy4",
         "country5","site_type5",	"site_name5",	"location_type5",	"lat5",	"lon5",	"location_uncertanty5",	"location_accuracy5",
         "outcome_metric_raw","outcome_metric_raw_description","outcome_unit_raw","outcome_metric",
         "suboutcome","outcome_unit",	"outcome_mean_metric","outcome_mean_value","outcome_variance_metric","outcome_variance_value_l",	
         "outcome_variance_value_u","outcome_variance_value",	"outcome_sd_value","outcome_sampling_size",	"data_location"
         
         )

writexl::write_xlsx(md.data.long.clean,"C:/Users/andreasanchez/OneDrive - CGIAR/Bioversity/meta-analysis/combining_datasets/datasets/pa_metadata/ready_md_MA_Sanch_22_Finan_Ec.xlsx")

  
names(md.data.long.clean)  
sort(unique(md.data.long.clean$country4))
  
  
  
  
  mutate(source_code="MA_Sanch_22_Finan_Ec")%>%
  rename()

names(md.data)
sort(unique(md.data$ID))

any(is.na(al$title))
sum(is.na(al$title))
