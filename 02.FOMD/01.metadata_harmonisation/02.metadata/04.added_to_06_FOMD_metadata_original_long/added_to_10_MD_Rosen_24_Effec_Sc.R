library(readxl)
library(dplyr)
library(readxl)
library(tidyr)
library(openxlsx)

path.metadata<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/01.metadata_harmonisation/02.metadata"
path.metadata.structure<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/02.metadata_structure"
path.era<-"C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/ERA/data"
list.files(path.metadata)
list.files(path.metadata.structure)
list.files(paste0(path.metadata,"/02.selected"))

#==========================================================
# Read datasets
#==========================================================
#---04_FOMD_screening
fomd04<-read_xlsx(file.path(path.metadata.structure,"/04_FOMD_screening.xlsx"), sheet = "04_FOMD_screening")%>%
  filter(ss_id=="MD_Rosen_24_Effec_Sc")%>%
  filter(status%in%c("PI","I","unresolved"))%>%
  select(ss_id,study_id_ss,study_id,doi)
length(unique(fomd04$study_id)) #2106
length(unique(fomd04$doi)) #2106
sort(unique(fomd04$status))

#---10_FOMD_metadata_synthesis_short
fomd10.names<-names(read_xlsx(file.path(path.metadata.structure,"10_FOMD_metadata_synthesis_short.xlsx"), sheet = "10_FOMD_metadata_synthesis"))
fomd10.names<-unique(fomd10.names)

#---Metadata 
md.data.short <- read.csv(file.path(path.era, "ERA_complete_data_short_v3.csv"))

length(unique(md.data.short$study_id)) #1811
length(unique(md.data.short$doi)) #1592
sort(unique(md.data.short$country))

#---Metadata field match
#md.data.columns <- read.csv(file.path(path.era, "ERA_to_FOMD_field_map.csv"))

#rename_vector <- setNames(md.data.columns$fomd_field,
#                          md.data.columns$era_source)


#==========================================================
# Add study_id 
#==========================================================
length(unique(fomd04$study_id)) #2106
md.data.short.clean<-md.data.short%>%
  rename("study_id_ss"="study_id")%>%
  left_join(fomd04%>%
              select(-doi,-ss_id),by=c("study_id_ss"="study_id_ss"))%>%
  left_join(fomd04%>%filter(!is.na(doi))%>%
              select(-ss_id,-study_id_ss),by="doi")%>%
  #select(1:10,230:233)%>%
  mutate(study_id=study_id.x)%>%
  mutate(study_id=case_when(is.na(study_id)~study_id.y,TRUE~study_id))%>%
  select(-study_id.x,-study_id.y)
  

length(unique(md.data.short.clean$study_id)) #969
sort(unique(md.data.short.clean$ss_id))

#==========================================================
# Rename columns to match 10_FOMD_metadata_synthesis_short names
#==========================================================
names(md.data.short.clean)
sort(unique(md.data.short.rename$C_product_type))

md.data.short.rename <- md.data.short.clean%>%
  select(C_product_component,C_product_type,
         C_product_subtype,
         C_product_simple
  )


#md.data.short.clean$Comparison_ID
length(unique(md.data.short.clean$B.Code))
sort(unique(md.data.short.clean$Exp.Duration))
sort(unique(md.data.short.clean$C.Till.Out__T.Freq))
sort(unique(md.data.short.clean$T.pH.Level.Name))

%>%
  rename(
    ###---location
    "country" = "Country",
    "countryISO" ="ISO.3166.1.alpha.3",
    "site_type"="Site.Type",
    "site_id" ="Site.ID",
    "site_admin" ="Site.Admin",
    "site_agg"="Site.Agg",
    #site_latlong_type=,
    "site_latitude"= "Site.LatD",
    "site_longitude"= "Site.LonD",
    "site_buffer"="Buffer.Manual",
    
    ###---experiment_time 
    #time_raw=,
    time_year_start="Time.Start.Year" ,
    time_year_end="Time.End.Year" ,
    #time_season=,
    
    ###---practice
    #subpractice_raw= System_raw,
    #subpractice_description_raw=System_details,
    #practice_id=Comparison_ID,
    #system_type=Comparison_class,
    
    ###---crop
    #C_crop_diversity=,
    #C_crop_variety=,
    #C_crop_density=,
    #T_crop_diversity=,
    #T_crop_variety=,
    #T_crop_density=,
    
    ###---tree
    #C_tree_diversity=,
    #C_tree_density=,
    #T_tree_diversity=,
    #T_tree_density=,
    
    ###---commodity_animal
    #C_animal_diversity=,
    #C_animal_breed=,
    #C_animal_density=,
    #T_animal_diversity=,
    #T_animal_breed=,
    #T_animal_density=,
    
    ###---soil_management_practice
    "C_tillage_subpractice_raw" ="C.Till.Notes",
    #"C_tillage_subpractice"="",
    "C_tillage_method" ="C.Till.Out__T.Method",
    "C_tillage_method_other"="C.Till.Out__Till.Other",
    "C_tillage_depth" = "C.Till.Out__T.Depth",
    "C_tillage_frequency"="C.Till.Out__T.Freq",
    
    "T_tillage_subpractice_raw"="T.Till.Notes",
    #"T_tillage_subpractice"="",
    "T_tillage_method"="T.Till.Out__T.Method",
    "T_tillage_method_other"="T.Till.Out__Till.Other",
    "T_tillage_depth"= "T.Till.Out__T.Depth",
    "T_tillage_frequency"="T.Till.Out__T.Freq",

    ###---planting_practice
    #"C_planting_subpractice_raw"
    #"C_planting_subpractice"
    "C_planting_method"="C.Plant.Method__Plant.Method",
    #"C_planting_date_start_end"
    
    #"T_planting_subpractice_raw"
    #"T_planting_subpractice"
    "T_planting_method"="T.Plant.Method__Plant.Method",
    #"T_planting_date_start_end"
    
    ###---improved crop varieties: practice
    #C_varietal_crop_subpractice_raw
    #C_varietal_crop_name
    #C_varietal_crop_variety
    "C_varietal_crop_subpractice"="C.V.Crop.Practice",
    "C_varietal_crop_type"="C.V.Type",
    #C_varietal_crop_trait
    
    #T_varietal_crop_subpractice_raw
    #T_varietal_crop_name
    #T_varietal_crop_variety
    "T_varietal_crop_subpractice"="T.V.Crop.Practice",
    "T_varietal_crop_type"="T.V.Type",
    #T_varietal_crop_trait
    
    
    ###---intercropping_practice
    C_intercrop_subpractice_raw
    C_intercrop_subpractice
    C_intercrop_design
    C_intercrop_pattern
    "C_intercrop_start_year"="C.IN.Start.Year",
    C_intercrop_start_season
    C_intercrop_residues_fate="C.IN.Residue.Fate",
    
    T_intercrop_subpractice_raw
    T_intercrop_subpractice
    T_intercrop_design
    T_intercrop_pattern
    "T_intercrop_start_year"="T.IN.Start.Year",
    T_intercrop_start_season
    "T_intercrop_residues_fate"="T.IN.Residue.Fate",
    
    ###---crop_sequence_practice
    "C_crop_seq_subpractice_raw"="C.R.Level.Name",
    C_crop_seq_subpractice=
    C_crop_seq_start_year
    C_crop_seq_start_season
    C_crop_seq_residues_fate
    
    "T_crop_seq_subpractice_raw"="T.R.Level.Name",
    T_crop_seq_subpractice
    T_crop_seq_start_year
    T_crop_seq_start_season
    T_crop_seq_residues_fate
    
    
    ###---agroforestry_practice
    

    ###---nutrient_management_fert_moderator
    C_fert_subpractice_raw
    C_fert_subpractice
    C_fert_inorganic_category
    "C_fert_inorganic_type"="C.Fert.Method__F.Type",
    "C_fert_inorganic_unit"="C.Fert.Method__F.Unit",
    "C_fert_inorganic_amount"="C.Fert.Method__F.Amount",
    "C_fert_inorganicNPK_unit"="C.F.I.Unit",
    "C_fert_inorganicN"= "C.F.NI",
    "C_fert_inorganicP"="C.F.PI",
    "C_fert_inorganicK"="C.F.KI",
    "C_fert_inorganicP2O5"= "C.F.P2O5",
    C_fert_inorganicK2O
    
    T_fert_subpractice_raw
    T_fert_subpractice
    T_fert_inorganic_category
    "T_fert_inorganic_type"="T.Fert.Method__F.Type",
    "T_fert_inorganic_unit"="T.Fert.Method__F.Unit",
    "T_fert_inorganic_amount"="T.Fert.Method__F.Amount",
    "T_fert_inorganicNPK_unit"="T.F.I.Unit",
    "T_fert_inorganicN"="T.F.NI",
    "T_fert_inorganicP"="T.F.PI",
    "T_fert_inorganicK"="T.F.KI",
    "T_fert_inorganicP2O5"= "T.F.P2O5",
    T_fert_inorganicK2O
    
    ###---nutrient_management_org_moderator	
    C_fert_organic_category
    C_fert_organic_type
    "C_fert_organic_unit"="C.F.O.Unit",
    C_fert_organic_amount
    C_fert_organicNPK_unit
    C_fert_organicN
    C_fert_organicP
    C_fert_organicK
    "C_fert_organic_source"="C.Fert.Method__F.Source",
    
    T_fert_organic_category
    T_fert_organic_type
    "T_fert_organic_unit"="T.F.O.Unit",
    T_fert_organic_amount
    T_fert_organicNPK_unit
    T_fert_organicN
    T_fert_organicP
    T_fert_organicK
    "T_fert_organic_source"="T.Fert.Method__F.Source",
    
    ###---weed_management
    C_weed_method_raw
    C_weed_method
    C_weed_frequency_unit
    T_weed_method_raw
    T_weed_method
    T_weed_frequency_unit
    
    ###---chemical_management_practice
    C_chem_subpractice_raw
    "C_chem_subpractice"="C.Chems.Out__C.Type",
    "C_chem_name"="C.Chems.Out__C.Name",
    "C_chem_amount_unit"="C.Chems.Out__C.Unit",
    "C_chem_amount"="C.Chems.Out__C.Amount",
    
    T_chem_subpractice_raw
    "T_chem_subpractice"="T.Chems.Out__C.Type",
    "T_chem_name"="T.Chems.Out__C.Name",
    "T_chem_amount_unit"="T.Chems.Out__C.Unit",
    "T_chem_amount"="T.Chems.Out__C.Amount",
    
    ###---residues management
    C_residues_subpractice_raw
    "C_residues_subpractice01"="C.Res.Out__P1",
    C_residues_subpractice02
    
    "C_residues_CO_unit"="C.Res.Comp__M.OC.Unit",
    "C_residues_CO"="C.Res.Comp__M.OC",
    "C_residues_N_unit"="C.Res.Comp__M.N.Unit",
    "C_residues_N"="C.Res.Comp__M.N",
    "C_residues_P_unit"="C.Res.Comp__M.P.Unit",
    "C_residues_P"="C.Res.Comp__M.P",
    "C_residues_K_unit"="C.Res.Comp__M.K.Unit",
    "C_residues_K"="C.Res.Comp__M.K",
    "C_residues_tree"="C.Res.Method__M.Tree",
    "C_residues_material"="C.Res.Comp__M.Material",
    "C_residues_processing"="C.Res.Method__M.Process",
    "C_residues_material_source"="C.Res.Method__M.Source",
    C_residues_material_amount_unit=,
    "C_residues_material_amount"="C.Res.Method__M.Amount",
    
    T_residues_subpractice_raw
    "T_residues_subpractice01"="T.Res.Out__P1",
    "T_residues_subpractice02"="T.Res.Out__P2",
      
    "T_residues_CO_unit"="T.Res.Comp__M.OC.Unit",
    "T_residues_CO"="T.Res.Comp__M.OC",
    "T_residues_N_unit"="T.Res.Comp__M.N.Unit",
    "T_residues_N"="T.Res.Comp__M.N",
    "T_residues_P_unit"="T.Res.Comp__M.P.Unit",
    "T_residues_P"="T.Res.Comp__M.P",
    "T_residues_K_unit"="T.Res.Comp__M.K.Unit",
    "T_residues_K"="T.Res.Comp__M.K",
    "T_residues_tree"= "T.Res.Method__M.Tree",
    "T_residues_material"="T.Res.Comp__M.Material",
    "T_residues_processing"="T.Res.Method__M.Process",
    "T_residues_material_source"="T.Res.Method__M.Source",
    T_residues_material_amount_unit=,
    "T_residues_material_amount"="T.Res.Method__M.Amount",
    
    
    
    
    
    ###---irrigation_practice	
    "C_irrig_subpractice_raw"
    "C_irrig_subpractice"="C.I.Strategy",
    "C_irrig_method"
    
    "C_irrig_date_start"="C.Irrig.Method__I.Date.Start",
    "C_irrig_date_end"="C.Irrig.Method__I.Date.End",
    "C_irrig_water_unit"="T.Irrig.Method__I.Unit",
    "C_irrig_water_amount"="C.Irrig.Method__I.Amount",
    "C_irrig_water_type"="C.Irrig.Method__I.Water.Type",
    
    "T_irrig_subpractice_raw"
    "T_irrig_subpractice"="T.I.Strategy",
    "T_irrig_method"
    
    "T_irrig_date_start"="T.Irrig.Method__I.Date.Start",
    "T_irrig_date_end"="T.Irrig.Method__I.Date.End",
    "T_irrig_water_unit"="C.Irrig.Method__I.Unit",
    "T_irrig_water_amount"="T.Irrig.Method__I.Amount",
    "T_irrig_water_type"="T.Irrig.Method__I.Water.Type",
    
    ###---water_harvesting_practice
    "C_watharv_subpractice_raw"="C.WH.Level.Name",
    "C_watharv_subpractice"="C.WH.Out__P1",
    "T_watharv_subpractice_raw"="T.WH.Level.Name",
    "T_watharv_subpractice"="T.WH.Out__P1",

    ###---harvest_practice
    C_harvest_subpractice_raw
    C_harvest_subpractice
    C_harvest_date_start
    C_harvest_date_end
    C_harvest_days_after_planting
    T_harvest_subpractice_raw
    T_harvest_subpractice
    T_harvest_date_start
    T_harvest_date_end
    T_harvest_days_after_planting
    
    ###---out_exp_design
    "C_out_exp_design"="EX.Notes",
    "C_out_exp_plot_size"="EX.HPlot.Size",
    "T_out_exp_design"="EX.Notes",
    "T_out_exp_plot_size"="EX.HPlot.Size",
    
    ###---outcome
    "out_subindicator"="Out.Subind",
    "out_indicator"="Out.Ind",
    "out_pillar"="Out.Pillar",
    "out_subindicator_unit"="Out.Unit",
    #out_soil_depth_u
    #out_soil_depth_l
    
    ###---outcome_value
    #C_out_value_metric
    "C_out_value"="C.ED.Mean.T",
    "C_out_var_metric"="C.ED.Error.Type",
    "C_out_var_value"="C.ED.Error",
    C_outc_var_value_l
    C_outc_var_value_u
    C_out_sample_size
    "C_data_location"="C.ED.Data.Loc",
    
    #T_out_value_metric
    "T_out_value"="T.ED.Mean.T",
    "T_out_var_metric"="T.ED.Error.Type"
    "T_out_var_value"="T.ED.Error",
    T_outc_var_value_l
    T_outc_var_value_u
    T_out_sample_size
    "T_data_location"="T.ED.Data.Loc",
    
    
    out_agg_stat
    
  )
names(md.data.short.rename)

#----CREATE MISSING COLUMNS
sort(unique(md.data.short.rename$C_crop_density))
sort(unique(md.data.short.rename$C_crop_density_unit))
sort(unique(md.data.short.rename$T_crop_density))
sort(unique(md.data.short.rename$T_crop_density_unit))

sort(unique(md.data.short.rename$C_intercrop_residues_fate))
sort(unique(md.data.short.rename$C_ph_material))




md.data.short.rename1<-md.data.short.rename%>%
  mutate(
    ###---commodity_crop: It is not correct, only include the main product crop, it should include all crops included in the systems
    #C_crop_density=paste0(C_crop_density,"(",C_crop_density_unit,")"),
    #C_crop_density=case_when(C_crop_density=="NA()"~"Unspecified",TRUE~C_crop_density),
    #T_crop_density=paste0(T_crop_density,"(",T_crop_density_unit,")"),
    #T_crop_density=case_when(T_crop_density=="NA()"~"Unspecified",TRUE~T_crop_density),
    
    ###---soil_management_practice
    #"C_tillage_subpractice_raw" =paste(C.Till.Level.Name, C_tillage_subpractice_raw,sep = " "),
    #"T_tillage_subpractice_raw"=paste(T.Till.Level.Name, T_tillage_subpractice_raw,sep = " "),
    
    
    ###---outcome_value
    C_out_metric="Mean",
    T_out_metric="Mean"
         )

sort(unique(md.data.short.rename1$C_crop_density))
sort(unique(md.data.short.rename1$C_crop_density_unit))
sort(unique(md.data.short.rename1$T_crop_density))
sort(unique(md.data.short.rename1$T_crop_density_unit))
#==========================================================
# Unselect unnecessary columns
#==========================================================  
fomd10.names
#--- Clean biodiversity columns
# columns missing in md.data.short.rename
missing_cols <- setdiff(fomd10.names, names(md.data.short.rename))
missing_cols
# add missing columns as NA
fomd10.clean <- md.data.short.rename

for (col in missing_cols) {
  fomd10.clean[[col]] <- NA
}

# keep only columns in fomd09.names, in the same order
fomd10.clean <- fomd10.clean[, fomd10.names, drop = FALSE]

# check
list(
  only_in_fomd06.clean = setdiff(names(fomd06.biodiversity.clean), fomd09.names),
  only_in_fomd09.names = setdiff(fomd09.names, names(fomd06.biodiversity.clean))
)


names(fomd06.biodiversity.clean)

#--- Clean yield columns
# columns missing in md.data.long.rename.biodiversity
missing_cols <- setdiff(fomd09.names, names(md.data.long.rename.yield))

# add missing columns as NA
fomd06.yield.clean <- md.data.long.rename.yield

for (col in missing_cols) {
  fomd06.yield.clean[[col]] <- NA
}

# keep only columns in fomd09.names, in the same order
fomd06.yield.clean <- fomd06.yield.clean[, fomd09.names, drop = FALSE]

# check
list(
  only_in_fomd06.clean = setdiff(names(fomd06.yield.clean), fomd09.names),
  only_in_fomd09.names = setdiff(fomd09.names, names(fomd06.yield.clean))
)

#==========================================================
# rbind yield and biodiversity
#========================================================== 
fomd06.clean<-rbind(fomd06.biodiversity.clean,fomd06.yield.clean)

#==========================================================
# Remove duplicate columns
#==========================================================  
nrow(fomd06.clean) #11269
nrow(distinct(fomd06.clean)) #5474

fomd06.clean<-fomd06.clean %>%
  distinct()

nrow(fomd06.clean) #5474
nrow(distinct(fomd06.clean)) #5474

readr::write_csv(fomd06.clean, paste0(path.metadata, "/04.added_to_06_FOMD_metadata_original_long/added_to_06_MD_Jones_21_A glo_Sc.csv"))


