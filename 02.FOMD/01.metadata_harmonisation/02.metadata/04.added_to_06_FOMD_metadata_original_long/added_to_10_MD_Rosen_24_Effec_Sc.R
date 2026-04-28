library(readxl)
library(dplyr)
library(readxl)
library(tidyr)
library(openxlsx)

path.metadata<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Knowledge_Hub/02.FOMD/01.metadata_harmonisation/02.metadata"
path.metadata.structure<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Knowledge_Hub/02.FOMD/02.metadata_structure"
list.files(path.metadata)
list.files(path.metadata.structure)
list.files(paste0(path.metadata,"/02.selected"))

#==========================================================
# Read datasets
#==========================================================
#---04_FOMD_screening
fomd04<-read_xlsx(file.path(path.metadata.structure,"/04_FOMD_screening.xlsx"), sheet = "04_FOMD_screening")%>%
  filter(ss_id=="MD_Jones_21_A glo_Sc")%>%
  filter(status%in%c("PI","I","unresolved"))%>%
  select(ss_id,study_id_ss,study_id)
length(unique(fomd04$study_id)) #234

#---10_FOMD_metadata_synthesis_short
fomd10.names<-names(read_xlsx(file.path(path.metadata.structure,"10_FOMD_metadata_synthesis_short.xlsx"), sheet = "10_FOMD_metadata_synthesis_short"))
fomd10.names

#---Metadata dictionary
file_md <- file.path(path.metadata, "02.selected", "md_MD_Rosen_24_Effec_Sc.csv")
getSheetNames(file_md)
md.dic <- read.xlsx(file_md, sheet = "Data_dictionary")  


#---Metadata
md.data.long<-read.csv(file_md)
  mutate(ID=as.character(ID))
  #select(-Year_assessment,
   #      -FAO_group_T_recla,
    #     -Crop_woodiness_T_recla,
     #    -Time_state_T)


#==========================================================
# Add study_id 
#==========================================================
length(unique(fomd04$study_id)) #234
md.data.long.clean<-md.data.long
  left_join(fomd04,
            by=c("ID"="study_id_ss"))%>%
  filter(!is.na(study_id))

length(unique(md.data.long.clean$study_id)) #234
sort(unique(md.data.long.clean$ss_id))

#==========================================================
# Rename columns to match 09_FOMD_metadata_extraction_long names
#==========================================================
md.data.long.clean$Comparison_ID
sort(unique(md.data.long.clean$Exp.Duration))
sort(unique(md.data.long.clean$C.Till.Out__T.Freq))
sort(unique(md.data.long.clean$T.pH.Level.Name))

names(md.data.long.clean)

md.data.long.rename<-md.data.long.clean%>%
  rename(
    ###---location 10
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
    
    ###---experiment_details 4 columns
    "exp_design" ="EX.Design",
    "exp_plot_size" ="EX.Plot.Size",
    #exp_field_size=	Farm_size,
    "exp_duration"= "Exp.Duration",
    
    ###---experiment_time 4 columns
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
    
    ###---animal
    #C_animal_diversity=,
    #C_animal_breed=,
    #C_animal_density=,
    #T_animal_diversity=,
    #T_animal_breed=,
    #T_animal_density=,
    
    ###---soil_management_practice
    "C_tillage_subpractice_raw" ="C.Till.Notes",
    "C_tillage_subpractice"="",
    "C_tillage_method" ="C.Till.Out__T.Method",
    "C_tillage_method_other"="C.Till.Out__Till.Other",
    "C_tillage_depth" = "C.Till.Out__T.Depth",
    "C_tillage_frequency"="C.Till.Out__T.Freq",
    "T_tillage_subpractice_raw"="T.Till.Notes",
    "T_tillage_subpractice"="",
    "T_tillage_method"="T.Till.Out__T.Method",
    "T_tillage_method_other"="T.Till.Out__Till.Other",
    "T_tillage_depth"= "T.Till.Out__T.Depth",
    "T_tillage_frequency"="T.Till.Out__T.Freq",

    ###---agroforestry_practice
    agrof_subpractice_age_years=Time_state,
    
    ###---nutrient_management_fert_moderator
    C_fert_subpractice_raw
    C_fert_subpractice
    C_fert_inorganic_category
    C_fert_inorganic_type
    C_fert_inorganic_unit
    C_fert_inorganic_amount
    "C_fert_inorganicNPK_unit"="C.F.I.Unit",
    "C_fert_inorganicN"= "C.F.NI",
    "C_fert_inorganicP"="C.F.PI",
    "C_fert_inorganicK"="C.F.KI",
    "C_fert_inorganicP2O5"= "C.F.P2O5",
    C_fert_inorganicK2O
    
    T_fert_subpractice_raw
    T_fert_subpractice
    T_fert_inorganic_category
    T_fert_inorganic_type
    T_fert_inorganic_unit
    T_fert_inorganic_amount
    "T_fert_inorganicNPK_unit"="T.F.I.Unit",
    "T_fert_inorganicN"="T.F.NI",
    "T_fert_inorganicP"="T.F.PI",
    "T_fert_inorganicK"="T.F.KI",
    "T_fert_inorganicP2O5"= "T.F.P2O5",
    T_fert_inorganicK2O
    
    ###---nutrient_management_org_moderator	
    C_fert_organic_category
    C_fert_organic_type
    C_fert_organic_unit
    C_fert_organic_amount
    C_fert_organicNPK_unit
    C_fert_organicN
    C_fert_organicP
    C_fert_organicK
    C_fert_organic_source
    
    T_fert_organic_category
    T_fert_organic_type
    T_fert_organic_unit
    T_fert_organic_amount
    T_fert_organicNPK_unit
    T_fert_organicN
    T_fert_organicP
    T_fert_organicK
    T_fert_organic_source
    
    ###---weed_managment
    
    ###---chemical_management_practice
    "C_chem_subpractice"="C.Chems.Out__C.Type",
    "C_chem_name"="C.Chems.Out__C.Name",
    "C_chem_amount_unit"="C.Chems.Out__C.Unit",
    "C_chem_amount"="C.Chems.Out__C.Amount",
    "T_chem_subpractice"="T.Chems.Out__C.Type",
    "T_chem_name"="T.Chems.Out__C.Name",
    "T_chem_amount_unit"="T.Chems.Out__C.Unit",
    "T_chem_amount"="T.Chems.Out__C.Amount",
    
    ###---residues management
    C_residues_subpractice
    C_residues_unit
    "C_residues_N"="C.Res.Comp__M.N",
    "C_residues_P"="C.Res.Comp__M.P",
    "C_residues_K"="C.Res.Comp__M.K",
    "C_residues_tree"="C.Res.Method__M.Tree",
    "C_residues_material"="C.Res.Comp__M.Material",
    "C_residues_processing"="C.Res.Method__M.Process",
    "C_residues_material_source"="C.Res.Method__M.Source",
    C_residues_material_amount_unit=,
    "C_residues_material_amount"="C.Res.Method__M.Amount",
    
    T_residues_subpractice
    T_residues_unit
    "T_residues_N"="T.Res.Comp__M.N",
    "T_residues_P"="T.Res.Comp__M.P",
    "T_residues_K"="T.Res.Comp__M.K",
    "T_residues_tree"= "T.Res.Method__M.Tree",
    "T_residues_material"="T.Res.Comp__M.Material",
    "T_residues_processing"="T.Res.Method__M.Process",
    "T_residues_material_source"="T.Res.Method__M.Source",
    T_residues_material_amount_unit=,
    "T_residues_material_amount"="T.Res.Method__M.Amount",
    
    ###---ph management
    C_ph_subpractice
    "C_ph_material_applied"="C.pH.Method__pH.Material",
    "C_ph_material_amount_unit"="C.pH.Method__pH.Unit",
    "C_ph_material_amount"="C.pH.Method__pH.Amount",
    
    T_ph_subpractice
    "T_ph_material_applied"="T.pH.Method__pH.Material",
    "T_ph_material_amount_unit"="T.pH.Method__pH.Unit",
    "T_ph_material_amount"="T.pH.Method__pH.Amount",
    
    ###---irrigation_practice	

    ###---out_exp_design

    ###---product_outcome

    
    ###---input_outcome
    #econ_inputs=,
    
    ###---outcome
  
    ###---outcome_value
 
    
  )
names(md.data.long.rename.biodiversity)

#----CREATE MISSING COLUMNS
md.data.long.rename.biodiversity<-md.data.long.rename.biodiversity%>%
  mutate(
    ###---location
    site_latlong_type01= case_when(!is.na(site_latitude01)~"Original",TRUE~NA),
    site_buffer01=case_when(!is.na(site_latitude01)~"Unspecified",TRUE~NA),
    ###---experiment_details
    exp_duration=as.numeric(exp_duration),
    exp_duration=exp_duration/365,
    ###---practice
    system_type=case_when(system_type%in%c("Diversified","Simplified" )~"cropland",TRUE~"natural/seminatural"),
    ###---outcome_value
    out_value_metric="Mean"
         
         )

#==========================================================
# Deal with yield values
#==========================================================  
#--- Get yield columns
names(md.data.long.rename.biodiversity)
md.data.long.rename.yield<-md.data.long.rename.biodiversity%>%
  select(
    ###---product_outcome
    -product_raw,
    -product_component01,
    -bio_func_group,
    -bio_ground_ref,
    ###---outcome
    -out_subindicator_raw,
    ###---outcome_value
    -out_value, 
    -out_var_metric,
    -out_var_value,
    -outc_var_value_l,
    -outc_var_value_u,
    -out_sample_size)%>%
  filter(!is.na(Yield_value))

#--- Rename yield columns
names(md.data.long.rename.yield)

md.data.long.rename.yield<-md.data.long.rename.yield%>%
  rename(
    ###---outcome_value
    #out_value_metric=,
    out_value= Yield_value, 
    out_var_metric=Yield_error_measure,
    out_var_value=Yield_error_value,
    outc_var_value_l=Yield_error_range_l,
    outc_var_value_u=Yield_error_range_u,
    out_sample_size=Yield_N
  )

#----CREATE MISSING COLUMNS
md.data.long.rename.yield<-md.data.long.rename.yield%>%
  mutate(out_subindicator_raw="Crop Yield")
         
#==========================================================
# Unselect unnecessary columns
#==========================================================  
fomd09.names <- unique(fomd09.names)

#--- Clean biodiversity columns
# columns missing in md.data.long.rename.biodiversity
missing_cols <- setdiff(fomd09.names, names(md.data.long.rename.biodiversity))

# add missing columns as NA
fomd06.biodiversity.clean <- md.data.long.rename.biodiversity

for (col in missing_cols) {
  fomd06.biodiversity.clean[[col]] <- NA
}

# keep only columns in fomd09.names, in the same order
fomd06.biodiversity.clean <- fomd06.biodiversity.clean[, fomd09.names, drop = FALSE]

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


