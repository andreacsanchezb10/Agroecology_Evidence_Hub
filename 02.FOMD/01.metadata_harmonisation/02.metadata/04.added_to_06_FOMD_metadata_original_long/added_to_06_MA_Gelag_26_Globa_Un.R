library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
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
  filter(ss_id=="MA_Gelag_26_Globa_Un")%>%
  filter(status%in%c("PI","I","unresolved"))%>%
  select(ss_id,study_id_ss,study_id)
length(unique(fomd04$study_id)) #164

#---09_FOMD_metadata_extraction_long (target schema)
fomd09.names<-names(read_xlsx(file.path("C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/09_FOMD_metadata_extraction_long_stats4sd_V3.xlsm"), sheet = "09_FOMD_metadata_extraction_lon"))
fomd09.names

#---Metadata
file_md <- file.path(path.metadata, "02.selected", "md_MA_Gelag_26_Globa_Un.xlsx")
getSheetNames(file_md)

# NOTE: this source's "RÂ²" column header carries the same UTF-8/Latin-1
# double-encoding corruption seen elsewhere in this dataset (e.g. "Î±f" for
# "αf" in Outcome_name) - inherited from the source file, not introduced here.
md.data <- read_xlsx(file_md, sheet = "MasterData")

names(md.data)
nrow(md.data)                      # 1617 comparison-level rows
length(unique(md.data$Study_ID))   # 605

#==========================================================
# Recompute base_study_id (must match added_to_02_sl_MA_Gelag_26_Globa_Un.R
# exactly - this is the join key against study_id_ss below)
#==========================================================
md.data <- md.data %>%
  mutate(
    base_study_id = str_remove(Study_ID, "(-\\d+|_\\d{3}(_[a-z]+)?|(?<=[0-9])[a-z]+)$")
  ) %>%
  mutate(base_study_id=case_when(
    base_study_id%in%c("CanteroMartinez_2026_SV",
                       "CanteroMartinez_2026_AG",
                       "CanteroMartinez_2026_PN",
                       "CanteroMartinez_2026",
                       "Cantero_2026"
    )~"CanteroMartinez_2026",
    base_study_id%in%c("Bartomeus_2014_OSR",
                       "Bartomeus_2014_FieldBean",
                       "Bartomeus_2014_Strawberry",
                       "Bartomeus_2014_Buckwheat" )~"Bartomeus_2014",
    TRUE~base_study_id))

#==========================================================
# Convert wide (with/without) version to long version (one row per arm)
# "with" = the Intervention_type arm, "without" = the Comparator_description
# arm (confirmed against sample rows: Comparator_description = "Conventional
# farming" pairs with Intervention_type = "Organic farming").
#==========================================================
shared_cols <- c("Study_ID","base_study_id","DOI","Study_design","Replication_level",
                 "Scale_study","Quality_score","Study_period","Country","Continent",
                 "Precipitation","Soil","Slope_topography","Altitude",
                 "Agroecological_Zone","Climate_Koppen_Class","Cropping_system",
                 "HLPE_principle","Intervention_duration","Outcome_name",
                 "`Outcome_type(domain)`","MFL_domain","Measurement_method","Unit",
                 "`Extraction Source (Location in PDF)`","Supporting Evidence")

#--- Control (without) rows
md.data.C<-md.data%>%
  select(all_of(gsub("`","",shared_cols)),
         subpractice_description_raw = Comparator_description,
         out_value    = Mean_without,
         out_sample_size = N_without,
         sd_raw  = SD_without,
         se_raw  = SE_without,
         ci_l_raw = CI_lower_without,
         ci_u_raw = CI_upper_without,
         cv_raw  = CV_without)

#--- Treatment (with) rows
md.data.T<-md.data%>%
  select(all_of(gsub("`","",shared_cols)),
         subpractice_description_raw = Intervention_type,
         out_value    = Mean_with,
         out_sample_size = N_with,
         sd_raw  = SD_with,
         se_raw  = SE_with,
         ci_l_raw = CI_lower_with,
         ci_u_raw = CI_upper_with,
         cv_raw  = CV_with)

md.data.long<-bind_rows(md.data.C,md.data.T)
nrow(md.data.long)   # should be 2 x nrow(md.data) = 3234
length(unique(md.data.long$base_study_id)) #179

#==========================================================
# Add study_id (join on base_study_id = study_id_ss, as set by
# added_to_02_sl_MA_Gelag_26_Globa_Un.R)
#==========================================================
md.data.long<-md.data.long%>%
  left_join(fomd04, by=c("base_study_id"="study_id_ss"))

# which base_study_id values don't match anything in 04_FOMD_screening
# (expected: the 14 papers removed as duplicates in added_to_04, plus any
# not yet screened) - for diagnosis, not part of the final output:
md.data.long %>% filter(is.na(study_id)) %>% distinct(base_study_id)

md.data.long<-md.data.long%>%
  filter(!is.na(study_id))

length(unique(md.data.long$study_id)) #166
names(md.data.long)
#==========================================================
# "NR" (Not Reported) placeholders -> NA, across all numeric-ish fields
#==========================================================
num_like_cols <- c("out_value","out_sample_size","sd_raw","se_raw","ci_l_raw","ci_u_raw","cv_raw")
md.data.long <- md.data.long %>%
  mutate(across(all_of(num_like_cols), ~ na_if(str_squish(as.character(.)), "NR"))) %>%
  mutate(across(all_of(num_like_cols), as.numeric))

#==========================================================
# Rename to 09_FOMD_metadata_extraction_long names where the mapping is
# unambiguous. Left UNMAPPED on purpose (needs manual classification against
# the 09 schema's controlled vocabulary - TO CHECK before this is usable for
# analysis):
#   site_type01 (from Replication_level/Scale_study - free text, no fixed
#     on-station/on-farm wording across the ~140 distinct Scale_study values)
#   tillage_subpractice / tillage_method / and every other practice-specific
#     "non-raw" column (Intervention_type/Comparator_description describe
#     agroforestry, intercropping, fertilization, tillage, etc. all mixed
#     together as one free-text field per paper - which 09 practice family
#     each row belongs to has to be hand-coded, not guessed)
#   out_subindicator / MFL-to-09-domain mapping (Outcome_type(domain) and
#     MFL_domain use ~250 and ~50 distinct free-text values respectively,
#     with no clean 1:1 match to the 09 vocabulary)
#   crop_tree01 standardization (Cropping_system is free text, e.g. "winter
#     wheat" - passed through as product_raw/crop_tree01 as-reported, not
#     matched against the 01_vars_crops lookup)
#   out_var_metric / out_var_value - which variance statistic to report when
#     a row has more than one of SD/SE/CI/CV (all are preserved as sd_raw/
#     se_raw/ci_l_raw/ci_u_raw/cv_raw above) is an effect-size decision -
#     ask Andrea before picking one, same situation as Corbe's CTstdev/
#     CT_SEM/CT_SED flag.
md.data.long.rename <- md.data.long %>%
  rename(
    ###---location
    country01 = Country,
    ###---experiment_details
    exp_design=Study_design,
    ###---experiment_time
    time_raw = Study_period,
    
    ###---out_exp_design
    out_exp_design=Measurement_method,
    
    ###---outcome
    out_subindicator_raw = Outcome_name,
    out_subindicator_unit = Unit,
    
    ###---outcome_value
    data_location = `Extraction Source (Location in PDF)`,
    #extraction_obs = `Supporting Evidence`,
    
    exp_duration = Intervention_duration,
  ) %>%
  mutate(
    ###---experiment_time
    
      # time_raw's dash is corrupted to "â€“" in this file (same encoding issue
      # as "Î±f" for "αf" in Outcome_name) - matched alongside a clean "–"/"-"
      # in case some rows aren't corrupted.
      .year_match = str_match(time_raw, "([0-9]{4})[^0-9]{0,10}(?:â€“|–|-)[^0-9]{0,10}([0-9]{4})"),
      time_year_start = suppressWarnings(as.numeric(
        ifelse(!is.na(.year_match[,1]), .year_match[,2], str_extract(time_raw, "[0-9]{4}"))
      )),
      time_year_end = suppressWarnings(as.numeric(
        ifelse(!is.na(.year_match[,1]), .year_match[,3], str_extract(time_raw, "[0-9]{4}"))
      )),
      out_year = time_year_start
    ) %>%
      select(-.year_match)
 

names(md.data.long.rename)

#==========================================================
# crop_tree01:05 - scan Cropping_system (Cropping_system) for every crop name
# it mentions, mapped onto 01_vars_crops' controlled V.Product vocabulary,
# and fill crop_tree01-05 in the order they appear. This is a best-effort
# identification scan, not a certified classification - rows with a token
# this dictionary doesn't recognize will just quietly skip that one crop
# (only rows with ZERO matches are flagged below for review).
#==========================================================
crop_dict <- c(
  "winter wheat"="Wheat","spring wheat"="Wheat","hard red spring wheat"="Wheat",
  "soft white spring wheat"="Wheat","canadian prairie spring wheat"="Wheat",
  "durum wheat"="Durum Wheat","wheat"="Wheat",
  "corn silage"="Maize","sweet corn"="Maize","baby corn"="Baby corn","corn"="Maize","maize"="Maize",
  "barley"="Barley",
  "rice"="Rice",
  "sorghum"="Sorghum",
  "soybean"="Soybean","soya"="Soybean",
  "groundnut"="Groundnut","peanut"="Groundnut",
  "cowpea"="Cowpea",
  "chickpea"="Chickpea",
  "lentil"="Lentil",
  "faba bean"="Fava Bean",
  "pigeon pea"="Pigeon Pea",
  "phaseolus vulgaris"="Common Bean","common bean"="Common Bean","field bean"="Common Bean",
  "green bean"="Green bean",
  "sesame"="Sesame",
  "solanum tuberosum"="Potato","potato"="Potato",
  "sweet potato"="Sweet Potato",
  "cassava"="Cassava",
  "sugar beet"="Sugar Beet","beet"="Beet",
  "oilseed rape"="Rape","brassica napus"="Rape","canola"="Canola",
  "sunflower"="Sunflower",
  "tomato"="Tomato",
  "cabbage"="Cabbage",
  "broccoli"="Broccoli",
  "cauliflower"="Cauliflower",
  "zucchini"="Zucchini",
  "vitis vinifera"="Grape","tempranillo"="Grape","syrah"="Grape",
  "vineyard"="Grape","viticulture"="Grape","grape"="Grape",
  "olive"="Olive",
  "apple"="Malus domestica",
  "coffea arabica"="Coffee arabica","coffee"="Coffee",
  "rubber"="Rubber",
  "vitellaria paradoxa"="Vitellaria paradoxa","shea"="Vitellaria paradoxa",
  "faidherbia albida"="Faidherbia albida",
  "mangifera indica"="Mango","mango"="Mango",
  "oats"="Oats","oat"="Oats",
  "strawberry"="Strawberry",
  "napier"="Napier Grass",
  "urochloa brizantha"="Brachiaria brizantha","brachiaria"="Brachiaria brizantha",
  "triticale"="Triticale",
  "rye"="Rye",
  "vetch"="Hairy Vetch",
  "teff"="Teff",
  "finger millet"="Finger Millet",
  "pearl millet"="Pearl Millet",
  "quinoa"="Quinoa",
  "cotton"="Cotton",
  "sugarcane"="Sugar Cane","sugar cane"="Sugar Cane",
  "flax"="Flax",
  "pumpkin"="Pumpkin",
  "squash"="Squash",
  "lettuce"="Lettuce",
  "spinach"="Spinach",
  "kale"="Kale",
  "turmeric"="Turmeric",
  "garlic"="Garlic",
  "onion"="Onion",
  "carrot"="Carrot",
  "pineapple"="Pineapple",
  "banana"="Banana Sweet",
  "clover"="Subterranean Clover",
  "ryegrass"="Ryegrass Sp.",
  "watermelon"="Watermelon",
  "eggplant"="Eggplant",
  "pepper"="Pepper",
  "fennel"="Fennel",
  "okra"="Okra"
)
crop_dict_keys_sorted <- names(crop_dict)[order(-nchar(names(crop_dict)))]

identify_crops <- function(text) {
  if (is.na(text) || text == "") return(rep(NA_character_, 5))
  t <- str_to_lower(text)
  # corrupted en dash ("â€“", same encoding issue as elsewhere in this file)
  # and a clean dash both just separate crop names - replace with a space so
  # e.g. "maizeâ€“soybean" doesn't glue into one unmatched token
  t <- str_replace_all(t, "â€“|–|-", " ")
  found <- character(0)
  for (key in crop_dict_keys_sorted) {
    if (str_detect(t, fixed(key))) {
      found <- c(found, crop_dict[[key]])
      t <- str_replace(t, fixed(key), " ")  # mask so "pea" doesn't also match inside already-matched "pigeon pea"
    }
  }
  found <- unique(found)
  length(found) <- 5
  found
}

crop_matches <- purrr::map(md.data.long.rename$Cropping_system, identify_crops)
crop_matches_df <- as_tibble(do.call(rbind, crop_matches), .name_repair = "minimal")
names(crop_matches_df) <- paste0("crop_tree0", 1:5)

md.data.long.rename <- md.data.long.rename %>%
  bind_cols(crop_matches_df)

# rows where nothing in crop_dict matched at all - either a genuinely
# non-crop system ("Restoration landscape", "None") or a crop this
# dictionary doesn't know yet. Inspect before trusting the final output.
md.data.long.rename %>% filter(is.na(crop_tree01)) %>% distinct(Cropping_system)

#==========================================================
# Build final structure (pad missing 09-schema columns as NA, matching
# added_to_06_MA_Corbe_20_Limit_Na.R)
#==========================================================
fomd09.names <- unique(fomd09.names)
missing_cols <- setdiff(fomd09.names, names(md.data.long.rename))
fomd06.clean <- md.data.long.rename
for (col in missing_cols) {
  fomd06.clean[[col]] <- NA
}
fomd06.clean <- fomd06.clean[, fomd09.names, drop = FALSE]

list(
  only_in_fomd06.clean = setdiff(names(fomd06.clean), fomd09.names),
  only_in_fomd09.names = setdiff(fomd09.names, names(fomd06.clean))
)

#==========================================================
# Remove duplicate columns
#==========================================================
nrow(fomd06.clean)
nrow(distinct(fomd06.clean))

fomd06.clean<-fomd06.clean %>%
  distinct()

nrow(fomd06.clean)

readr::write_csv(fomd06.clean, paste0(path.metadata, "04.added_to_06_FOMD_metadata_original_long/added_to_06_MA_Gelag_26_Globa_Un.csv"))
