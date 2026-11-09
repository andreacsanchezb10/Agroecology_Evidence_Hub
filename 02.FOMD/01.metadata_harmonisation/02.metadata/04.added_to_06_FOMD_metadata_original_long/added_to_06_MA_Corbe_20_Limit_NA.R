library(readxl)
library(dplyr)
library(tidyr)
library(openxlsx)

path.metadata<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/01.metadata_harmonisation/02.metadata/"
path.metadata.structure<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/02.metadata_structure/"
list.files(path.metadata)
list.files(paste0(path.metadata,"02.selected/"))

#==========================================================
# Read datasets
#==========================================================
#---04_FOMD_screening
fomd04<-read_xlsx(file.path(path.metadata.structure,"04_FOMD_screening.xlsx"), sheet = "04_FOMD_screening")%>%
  filter(ss_id=="MA_Corbe_20_Limit_NA")%>%
  filter(status%in%c("PI","I","unresolved"))%>%
  select(ss_id,study_id_ss,study_id)
length(unique(fomd04$study_id)) #87

#---09_FOMD_metadata_extraction_long
fomd09.names<-names(read_xlsx(file.path("C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/09_FOMD_metadata_extraction_long_stats4sd_V3.xlsm"), sheet = "09_FOMD_metadata_extraction_lon"))
fomd09.names

#---Metadata
file_md <- file.path(path.metadata, "02.selected", "md_MA_Corbe_20_Limit_NA.xlsx")
getSheetNames(file_md)
md.dic <- read.xlsx(file_md, sheet = "Variables_en")

md.data<-read.xlsx(file_md, sheet = "Donnees_meta-analyse_2020")%>%
  mutate(Id1=as.character(Id1),
         ref=as.character(ref),
         # 9 of the 87 Data_source values carry a trailing space in this file
         # (e.g. "Araya et al. (2016) ") that got trimmed when study_id_ss
         # was typed into 04_FOMD_screening.xlsx - squish so the join below
         # isn't sensitive to that.
         Data_source=str_squish(Data_source))
# NOTE: "ref" (1-87) is the reference's internal row number in THIS file -
# it does NOT line up with code_from_ss/study_id_ss, which comes from a
# separately-numbered PDF reference list. The join key is "Data_source"
# (the author/year string, e.g. "Agbede and Ojeniyi (2009)"), hand-matched
# to study_id_ss via added_to_02/04_sl_MA_Corbe_20_Limit_NA.R.
library(stringr)

names(md.data)
length(unique(md.data$Id1)) #669

#==========================================================
# Convert short version (CT vs CA) to long version (one row per practice)
#==========================================================
# Unlike Sanchez's file, only 3 fields are genuinely paired per arm
# (Applied_N/_P, Grain_yield). Everything else - including CTstdev/CT_SEM/
# CT_SED and the non-suffixed Applied_N/Applied_P - is explicitly reported
# as shared between CT and CA ("(CT=CA)" in the dictionary), so it gets
# copied identically onto both the Control and Treatment row rather than
# split like a _C/_T pair.
shared_cols <- c("ref","Subject","Data_source","Year","Site","Coordinates",
                 "Climat_Koppen","rainfall_type","Study_type","Crop",
                 "Herbicide_on_CA","Altitude","Soil_NRCS","Texture",
                 "Initial_soil_C","Actual_rainfall","Average_rainfall",
                 "Average_Temp","Legume_rotation","Legume_intercropping",
                 "Years_CA","Initial_mulch","Mulch_type","Id","Id1",
                 "n","CTstdev","lsd","cv","CT_SEM","CT_SED",
                 "Applied_N","Applied_P","ordre")

#--- Control (CT) rows
md.data.C<-md.data%>%
  select(all_of(shared_cols),
         subpractice_raw = CT_type,
         out_value_raw    = Grain_yield_CT,
         fert_inorganicN= Applied_N_CT,
         fert_inorganicP       = Applied_P_CT)

#--- Treatment (CA) rows
# TO CHECK: CA_type1 ("Conservation agriculture type") vs CA_type
# ("Treatment on study: conservation agriculture type") read as two
# different things in the dictionary - used CA_type1 here as the raw,
# as-reported practice name (matching CT_type's own "as reported" framing);
# confirm this is the right one, not CA_type.
md.data.T<-md.data%>%
  select(all_of(shared_cols),
         subpractice_description_raw= CA_type1,
         out_value    = Grain_yield_CA,
         fert_inorganicN       = Applied_N_CA,
         fert_inorganicP= Applied_P_CA)

#--- Get data long version (one row per practice)
md.data.long<-bind_rows(md.data.C,md.data.T)
length(unique(md.data.long$Id1))
nrow(md.data.long) # should be 2 x nrow(md.data) #2140

names(md.data.long)

#==========================================================
# Parse coordinates (DMS text -> decimal degrees)
#==========================================================
# Checked the raw cell contents directly in the source xlsx (bypassing R):
# the degree sign is already corrupted INSIDE Corbeels' own file, not by our
# read code - it comes back as the Unicode replacement character (U+FFFD) in
# ~700 rows and as a literal typed "o" in ~300 rows; in some rows the minute
# mark (') is ALSO corrupted, inconsistently, to U+FFFD or "?". The lat/long
# separator is not reliably "," either - 305/1071 rows use ";" instead, which
# a comma-only split leaves whole in site_latitude01 with site_longitude01
# blank (this is what was showing up as "the mess"). The digit groups and
# the N/S/E/W hemisphere letter are intact throughout, so those are parsed
# directly into decimal degrees rather than split on a symbol that isn't
# reliably there.
#
# 19 rows report a RANGE ("16o00' to 16o30' S") instead of a single point -
# per Andrea, these are left as NA with coord_flag = "range" rather than
# guessing a midpoint.

parse_dms <- function(x) {
  x <- str_replace_all(x, "[°�?oO]", " ")
  m <- str_match(x, "([0-9]+)\\s*([0-9]+)?\\s*['\"\\s]*([NSEW])")
  deg <- as.numeric(m[,2])
  min <- suppressWarnings(as.numeric(m[,3])); min[is.na(min)] <- 0
  hemi <- m[,4]
  dec <- deg + min/60
  ifelse(hemi %in% c("S","W"), -dec, dec)
}

coord_split <- str_split_fixed(str_squish(md.data.long$Coordinates), "[,;]", 2)
lat_raw <- str_squish(coord_split[,1])
lon_raw <- str_squish(coord_split[,2])
is_range <- str_detect(lat_raw, " to ") | str_detect(lon_raw, " to ")

md.data.long.clean <- md.data.long %>%
  mutate(
    site_latitude01  = ifelse(is_range, NA_real_, parse_dms(lat_raw)),
    site_longitude01 = ifelse(is_range, NA_real_, parse_dms(lon_raw)),
    coord_flag = case_when(
      is_range ~ "range - needs manual midpoint/selection",
      is.na(site_latitude01) | is.na(site_longitude01) ~ "unparseable - check raw Coordinates",
      TRUE ~ NA_character_
    )
  )

sort(unique(md.data.long.clean$coord_flag))
md.data.long.clean %>% filter(!is.na(coord_flag)) %>% distinct(Coordinates, coord_flag)
sort(unique(md.data.long.clean$site_latitude01))
sort(unique(md.data.long.clean$site_longitude01))

#==========================================================
# Add study_id
#==========================================================
length(unique(fomd04$study_id))#87
length(unique(md.data.long.clean$Data_source)) #88

# Join key is "Data_source" (the author/year string), NOT "ref" or "Id1".
# "ref" is this file's own internal reference number (1-87) and doesn't line
# up with study_id_ss, which comes from a separately-numbered PDF reference
# list; "Id1" is "Concatenation of ref and Id" (e.g. "1-1", "2-3") - a
# per-site-comparison code, never equal to study_id_ss either. Data_source
# is hand-matched to study_id_ss in added_to_02/04_sl_MA_Corbe_20_Limit_NA.R.
md.data.long.clean<-md.data.long.clean%>%
  left_join(fomd04,
            by=c("Data_source"="study_id_ss"))

sort(unique(md.data.long.clean$Data_source))

# to list which Data_source values still fail to match anything in
# 04_FOMD_screening.xlsx (for diagnosing/reporting, not for the final output):
# md.data.long.clean %>% filter(is.na(study_id)) %>% distinct(Data_source)

md.data.long.clean<-md.data.long.clean%>%
  filter(!is.na(study_id))

length(unique(md.data.long.clean$study_id))
sort(unique(md.data.long.clean$ss_id))

#==========================================================
# Rename columns to match 09_FOMD_metadata_extraction_long names
#==========================================================
names(md.data.long.clean)
md.data.long.clean.rename<-md.data.long.clean%>%
  # "Asembo. Kenya" is the only Site value in this file using a period
  # instead of a comma before the country - fixed here (rename() can only
  # take an existing column name, not a computed expression) so the
  # country01/site_id01 split below works for it too.
  mutate(Site=if_else(Site=="Asembo. Kenya", "Asembo, Kenya", Site))%>%
  rename(
    ###---location
    site_id01=Site,
    "site_type01"=Study_type,
    #site_admin01=,
    #site_latitude01= (already built above),
    #site_longitude01= (already built above),
    
    ###---climate
    #no direct 09 column confirmed for Climat_Koppen/rainfall_type/Altitude/
    #Soil_NRCS/Texture/Initial_soil_C/Actual_rainfall/Average_rainfall/
    #Average_Temp yet - TO CHECK against 09_FOMD_readme before dropping these
    
    ###---experiment_time
    #time_year_start=
    
    ###---practice
    #subpractice_raw (already built above, per C/T arm)
    
    ###---intercropping_practice
    intercrop_subpractice_raw=Legume_intercropping,
    
    ###--crop_sequence_practice
    crop_seq_subpractice_raw=Legume_rotation,
    
    #fert_P_raw has no direct 09 equivalent confirmed yet - TO CHECK
    
    ###--chemical_management_practice
    chem_subpractice_raw=Herbicide_on_CA,
    
    ###--residues_practice
    residues_subpractice_raw=Mulch_type,
    residues_material_amount=Initial_mulch,

    
    ###---product_outcome
    product_raw=Crop,

    ###---outcome_value
    #out_value=out_value_raw,
    out_sample_size=n,

    ###---experiment_details
    exp_duration=Years_CA,
    ###---outcome_time
        out_year=Year,
    
  )%>%
  # out_subindicator_raw is a literal value, not an existing column to
  # rename from - "Grain yield" doesn't exist in the source data, it's
  # what every row here actually measures (Grain_yield_CT/Grain_yield_CA).
  mutate(out_subindicator_raw="Grain yield")
names(md.data.long.clean.rename)
sort(unique(md.data.long.clean.rename$fert_inorganicP))

#----CREATE MISSING COLUMNS
fomd06<-md.data.long.clean.rename%>%
  mutate(
    # site_id01 (from Site) has no colon anywhere in this file - it's
    # comma-separated, e.g. "Domboshawa, Zimbabwe" - so country is the
    # text after the LAST comma, not a colon.
    country01=str_squish(sub(".*,", "", site_id01)),
    # site_id01 itself should not repeat the country - keep only the part
    # before the last comma, e.g. "Domboshawa, Zimbabwe" -> "Domboshawa".
    site_id01=str_squish(sub(",[^,]*$", "", site_id01)),
    # Study_type only ever has these 2 exact values in this file (checked
    # against the live data, no whitespace variants) - anything else would
    # fall through to NA rather than be silently mislabeled.
    site_type01=case_when(
      site_type01=="on-station" ~ "Researcher Managed & Research Facility",
      site_type01=="on-farm" ~ "Researcher Managed & On-farm",
      TRUE ~ NA_character_),
    
    ###---commodity_crop
    crop_tree01= product_raw,
    
    ###---soil_management_practice
    tillage_subpractice_raw=subpractice_description_raw,
    tillage_subpractice=case_when(
      tillage_subpractice_raw=="no-tillage"~"No or Zero Tillage",
      tillage_subpractice_raw=="minimum tillage"~"Reduced or Minimum Tillage",
      tillage_subpractice_raw%in%c("hoe","plow","ridge","Ridge","ridge ")~"Conventional Tillage",
      TRUE ~ NA_character_),
    tillage_method=case_when(
      tillage_subpractice_raw=="plow"~"Ploughed (Unspecified)",
      tillage_subpractice_raw=="hoe"~"Hand Hoe",
      TRUE ~ NA_character_),
    tillage_method_other=case_when(
      tillage_subpractice_raw=="ridge"~"Ridge & Furrow",
      TRUE ~ NA_character_),
    
    ###---intercropping_practice
    intercrop_subpractice=case_when(
      crop_tree01%in%c("cowpea", "soybean", "bean", "grass pea", "pigeon pea")
      & intercrop_subpractice_raw=="Y"~"Intercrop (N fixing)",
      !(crop_tree01%in%c("cowpea", "soybean", "bean", "grass pea", "pigeon pea"))
      & intercrop_subpractice_raw=="Y"~"Intercrop (N fixing and Non N fixing)",
      intercrop_subpractice_raw=="N"~"Monoculture",
      TRUE ~ NA_character_),
    
    ###--crop_sequence_practice
    crop_seq_subpractice=case_when(
      crop_tree01%in%c("cowpea", "soybean", "bean", "grass pea", "pigeon pea")
      & crop_seq_subpractice_raw=="Y"~"Rotation (N fixing)",
      !(crop_tree01%in%c("cowpea", "soybean", "bean", "grass pea", "pigeon pea"))
      & crop_seq_subpractice_raw=="Y"~"Rotation (N fixing and Non N fixing)",
      crop_seq_subpractice_raw=="N"~"Monoculture",
      TRUE ~ NA_character_),
    ###--nutrient_management_practice
    fert_inorganicNPK_unit=case_when(
      !(fert_inorganicN%in%c("?",    "0"))&!(fert_inorganicP%in%c("?",    "0"))~"kg/ha",
      TRUE ~ NA_character_),
    fert_inorganic_category=case_when(
      !(fert_inorganicN%in%c("?",    "0"))&!(fert_inorganicP%in%c("?",    "0"))~"Inorganic",
      TRUE ~ NA_character_),
    fert_subpractice=case_when(
      !(fert_inorganicN%in%c("?",    "0"))&!(fert_inorganicP%in%c("?",    "0"))~"Inorganic Fertilizer",
      TRUE ~ NA_character_),
    
    ###--chemical_management_practice
    chem_subpractice01=case_when(
      chem_subpractice_raw=="N"~"No Herbicide Applied",
      chem_subpractice_raw=="Y"~"Herbicide",
      TRUE ~ NA_character_),
    
    ###--residues_practice
    residues_subpractice01=case_when(
      residues_subpractice_raw=="no mulch"~"No mulch Applied",
      residues_subpractice_raw%in%c("gramineae+legume","gramineae","legume")~"Mulch Herb (N fixing)",
      residues_subpractice_raw=="forest"~"Tree Prunings Mulched (Unspecified)",
      residues_subpractice_raw=="cotton"~"Mulch Herb (Non N fixing)",
      TRUE ~ NA_character_),
    residues_material_unit="kg/ha",
    
    ###--outcome
    out_subindicator="Crop Yield",
    out_subindicator_unit="kg/ha",
    
    
    out_value_metric="Mean",
    # TO CHECK: which of CTstdev / CT_SEM / CT_SED is the right variance to
    # report here - the dictionary's own wording is inconsistent (CT_SEM's
    # label says "standard deviation" despite the SEM name; CT_SED's label
    # also says "standard deviation" despite being named like a standard
    # error of difference). Using CTstdev for now since its label is the
    # least ambiguous ("Yield residual standard deviation"), but this needs
    # confirming before trusting any effect size computed from it.
    #out_var_metric="SD (Standard Deviation)",
    #out_var_value=CTstdev
  )

#==========================================================
# Unselect unnecessary columns
#==========================================================
fomd09.names <- unique(fomd09.names)
missing_cols <- setdiff(fomd09.names, names(fomd06))
fomd06.clean <- fomd06
for (col in missing_cols) {
  fomd06.clean[[col]] <- NA
}
fomd06.clean <- fomd06.clean[, fomd09.names, drop = FALSE]

list(
  only_in_fomd06.clean = setdiff(names(fomd06.clean), fomd09.names),
  only_in_fomd09.names = setdiff(fomd09.names, names(fomd06.clean))
)
names(fomd06.clean)

#==========================================================
# Remove duplicate columns
#==========================================================
nrow(fomd06.clean)
nrow(distinct(fomd06.clean))

fomd06.clean<-fomd06.clean %>%
  distinct()

nrow(fomd06.clean)

readr::write_csv(fomd06.clean, paste0(path.metadata, "04.added_to_06_FOMD_metadata_original_long/added_to_06_MA_Corbe_20_Limit_NA.csv"))

