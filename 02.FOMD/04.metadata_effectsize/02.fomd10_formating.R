library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(readr)
library(skimr)

path.metadata.structure<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/02.metadata_structure/"
path.metadata.effectsize<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/04.metadata_effectsize/"

list.files(path.metadata.structure)
list.files(path.metadata.effectsize)

#==========================================================
# Read functions
#==========================================================
source(file.path(path.metadata.effectsize, "fomd_fun/fun_pairing_CT.R"))

#==========================================================
# Read datasets
#==========================================================
metadata<-"MD_Paut,_24_A glo_Sc" #Paut et al. 2024. A global dataset of experimental intercropping and agroforestry studies in horticulture. 10.1038/s41597-023-02831-7

#---09_FOMD_clean
fomd09.clean <- read_csv(
  file.path(path.metadata.effectsize, "01.fomd09_clean", paste0("fomd09_clean_", metadata, ".csv")),
  show_col_types = FALSE)

#==========================================================
# Check content
#==========================================================
names(fomd09.clean)

for (col in c("study_id","out_subindicator", "out_indicator",
              "out_pillar", "out_subpillar",
              "country"
)) {
  cat("---", col, "---\n")
  print(sort(unique(fomd09.clean[[col]])))
}

sort(unique(fomd09.clean$out_subindicator[fomd09.clean$out_subpillar =="Biodiversity"]))
sort(unique(fomd09.clean$out_subindicator[fomd09.clean$out_subpillar =="Economics"]))
sort(unique(fomd09.clean$out_subindicator[fomd09.clean$out_subpillar =="Efficiency"]))
sort(unique(fomd09.clean$out_subindicator[fomd09.clean$out_subpillar =="Physical"]))
sort(unique(fomd09.clean$out_subindicator[fomd09.clean$out_subpillar =="Yield"]))

sort(unique(fomd09.clean$study_id[fomd09.clean$out_subpillar =="Physical" ]))
sort(unique(fomd09.clean$system_type[fomd09.clean$out_subpillar =="Physical"]))
#sort(unique(fomd09.clean$out_subindicator[is.na(fomd09.clean$out_subpillar)]))

#==========================================================
# Apply pair functions
#==========================================================
#-------------------------------------------------------------------------------------
#--- Pairing context function ---
## Used for out_subpillar: "Biodiversity"
## Matching mechanism: Control row matches Treatment row when 
#pairing_base_cols + that subpillar's extra_cols are identical
#-------------------------------------------------------------------------------------
paired_bio_context<-fun_pair_bio_context(fomd09.clean)

#-------------------------------------------------------------------------------------
#--- Pairing context function ---
## Used for out_subpillar: "Economics","Efficiency","Physical"
## Matching mechanism: Control row matches Treatment row when 
#pairing_base_cols + that subpillar's extra_cols are identical
#-------------------------------------------------------------------------------------
paired_context<-fun_pair_context(fomd09.clean)

#-------------------------------------------------------------------------------------
#--- Pairing yield focal function -----
## Used for out_subpillar: "Yield"
## Applies when the study reports yield for a single, focal crop — comparing
## that same crop's yield under a control (e.g. monoculture) against the same
## crop grown under a Treatment system (e.g. intercropping, crop
## rotation, agroforestry, etc.). Only that one crop's yield is tracked, so
## no combined multi-crop calculation (LER) is needed or possible.
## Distinct from Total/Partial LER, which require yield values for *several*
## crops grown together, to compute how their combined land-use efficiency
## compares against separate monocultures.
#-------------------------------------------------------------------------------------
paired_yield_focal<-fun_pair_yield_focal(fomd09.clean)

#-------------------------------------------------------------------------------------
#-- TO DO: PAIRING WHEN C_product and T_product don't match for Crop Yield and Biomass Yield
# these are for cases when yield is provided for the system in Treatment (eg. yield of maize monoculture vs.
#yield of maize+cowpea (together) intercropping)
#-------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------
#--- Pairing yield partial ler function -----
#-------------------------------------------------------------------------------------
paired_yield_pler<-fun_pair_yield_partial_ler(fomd09.clean)


#-------------------------------------------------------------------------------------
#--- Yield to cal partial and total ler function -----
#-------------------------------------------------------------------------------------
# studies providing partial and total ler
JA_Phiri_24_Compa_Ag
JA_Kidan_17_Maize_Op
JA_Banti_15_Deter_Ho

#==========================================================
# Code for checking if all specified pairings were done
#==========================================================
#-------------------------------------------------------------------------------------
#--- Pairing bio context function ---
#-------------------------------------------------------------------------------------
# expected: every Control row's treatment name(s), reconstructed the same
# way pair_context() does it internally, before any matching happens
spec <- pairing_spec_cols %>% filter(subpillar == "Biodiversity",branch == "context")

# every Control row's own match key, before joining
expected <- fomd09.clean %>%
  filter(grepl("C", practice_id), out_subpillar %in% c("Biodiversity")) %>%
  split_ct()
expected$comparison_id <- build_dispatch_id(
  expected, spec,
  function(extra) c("out_comparison_treatment", setdiff(c(pairing_base_cols, extra), "practice_id"))
)

# every row's own key, from the Treatment side
all_rows <- fomd09.clean
all_rows$row_id <- build_dispatch_id(all_rows, spec, function(extra) c(pairing_base_cols, extra))

# Control rows whose key never appears among the Treatment rows' keys
missing_bio_context <- expected %>%
  filter(!comparison_id %in% all_rows$row_id) %>%
  select(study_id, practice_id, out_subpillar, out_subindicator, out_comparison_treatment)

missing_bio_context

eco_cols_to_check <- c(pairing_base_cols, "out_npv_discount_rate", "out_npv_econ_period")

rows <- fomd09.clean %>%
  filter(study_id == "JA_ADHIK_91_STUDI_J",
         out_subindicator == "Soil Organic Carbon",
         practice_id %in% c("C1", "T1")) %>%
  select(practice_id, all_of(eco_cols_to_check))

c <- rows %>% filter(practice_id == "C1") %>% select(-practice_id) %>% unlist()
t <- rows %>% filter(practice_id == "T1") %>% select(-practice_id) %>% unlist()

tibble(column = names(c), C1 = c, T3 = t) %>%
  filter(C1 != T3 | is.na(C1) != is.na(T3))


#-------------------------------------------------------------------------------------
#--- Pairing context function ---
#-------------------------------------------------------------------------------------
# expected: every Control row's treatment name(s), reconstructed the same
# way pair_context() does it internally, before any matching happens
spec <- pairing_spec_cols %>% filter(subpillar != "Biodiversity",branch == "context")
spec
# every Control row's own match key, before joining
expected <- fomd09.clean %>%
  filter(grepl("C", practice_id), out_subpillar %in% c("Economics","Efficiency","Physical")) %>%
  split_ct()

expected$comparison_id <- build_dispatch_id(
  expected, spec,
  function(extra) c("out_comparison_treatment", setdiff(c(pairing_base_cols, extra), "practice_id"))
)

# every row's own key, from the Treatment side
all_rows <- fomd09.clean
all_rows$row_id <- build_dispatch_id(all_rows, spec, function(extra) c(pairing_base_cols, extra))

# Control rows whose key never appears among the Treatment rows' keys
missing_context <- expected %>%
  filter(!comparison_id %in% all_rows$row_id) %>%
  select(study_id, practice_id, out_subpillar, out_subindicator, out_comparison_treatment)

missing_context

context_extra <- unlist(pairing_spec_cols %>% 
                          filter(subpillar == "Economics", branch == "context") %>%
                          pull(extra_cols))
cols_to_check <- c(pairing_base_cols, context_extra)
cols_to_check

rows <- fomd09.clean %>%
  filter(study_id == "JA_ADHIK_91_STUDI_J",
         out_subindicator == "Soil Organic Carbon",
         practice_id %in% c("C1", "T1")) %>%
  select(practice_id, all_of(cols_to_check))

c <- rows %>% filter(practice_id == "C1") %>% select(-practice_id) %>% unlist()
t <- rows %>% filter(practice_id == "T1") %>% select(-practice_id) %>% unlist()

tibble(column = names(c), C1 = c, T3 = t) %>%
  filter(C1 != T3 | is.na(C1) != is.na(T3))

#-------------------------------------------------------------------------------------
#--- Pairing yield focal function -----
#-------------------------------------------------------------------------------------
extra   <- unlist(pairing_spec_cols %>% dplyr::filter(subpillar == "Yield", branch == "focal") %>% dplyr::pull(extra_cols))
id_cols <- c(pairing_base_cols, extra)

# restrict to the focal universe once — same gate pair_yield_focal() uses
fomd09_focal <- fomd09.clean %>% dplyr::filter(is_focal_row(fomd09.clean))

# expected: every focal Control row's own match key, before joining
expected <- fomd09_focal %>%
  dplyr::filter(grepl("C", practice_id)) %>%
  split_ct()
expected$comparison_id <- build_row_id(expected, c("out_comparison_treatment", setdiff(id_cols, "practice_id")))

# every focal row's own key, from the Treatment side
all_rows <- fomd09_focal
all_rows$row_id <- build_row_id(all_rows, id_cols)

# expected Control rows whose key never appears among the Treatment rows' keys
missing_yield_focal <- expected %>%
  dplyr::filter(!comparison_id %in% all_rows$row_id) %>%
  dplyr::select(study_id, practice_id, out_subpillar, out_subindicator, out_comparison_treatment)

nrow(expected)  # how many focal pairs you specified
nrow(missing_yield_focal)   # how many never found their Treatment
missing_yield_focal

rows <- fomd09_focal %>%
  filter(study_id == "JA_ADHIK_91_STUDI_J", practice_id %in% c("C6", "T5")) %>%
  select(practice_id, all_of(id_cols))

c <- rows %>% filter(practice_id == "C6") %>% select(-practice_id) %>% slice(1) %>% unlist()
t <- rows %>% filter(practice_id == "T5") %>% select(-practice_id) %>% slice(1) %>% unlist()

tibble(column = names(c), C = c, T = t) %>%
  filter(C != T | is.na(C) != is.na(T))

#-------------------------------------------------------------------------------------
#--- Pairing yield partial ler function -----
#-------------------------------------------------------------------------------------
spec    <- pairing_spec_cols %>% dplyr::filter(subpillar == "Yield", branch == "partial_ler")
extra   <- unlist(spec$extra_cols)

exploded_all <- explode_ler_components(fomd09.clean)
id_cols <- c(pairing_base_cols, extra)

expected <- exploded_all %>%
  dplyr::filter(grepl("C", practice_id)) %>%
  split_ct()
expected$comparison_id <- build_row_id(expected, c("out_comparison_treatment", setdiff(id_cols, "practice_id")))

all_rows <- exploded_all
all_rows$row_id <- build_row_id(all_rows, id_cols)

missing_yield_pler <- expected %>%
  dplyr::filter(!comparison_id %in% all_rows$row_id) %>%
  dplyr::select(study_id, practice_id, out_subpillar, product, out_comparison_treatment)

nrow(expected)
nrow(missing_yield_pler)
missing_yield_pler

rows <- exploded_all %>%
  filter(study_id == "JA_Dua, _17_Effec_LR", practice_id %in% c("C8", "T6")) %>%
  select(practice_id, all_of(id_cols))

c <- rows %>% filter(practice_id == "C8") %>% select(-practice_id) %>% slice(1) %>% unlist()
t <- rows %>% filter(practice_id == "T6") %>% select(-practice_id) %>% slice(1) %>% unlist()

tibble(column = names(c), C = c, T = t) %>%
  filter(C != T | is.na(C) != is.na(T))

#==========================================================
# Check for missing columns
#==========================================================
list(
  only_in_pairing_outputs = setdiff(names(paired_bio_context), fomd10.cols),   # produced by a branch, but not in the 10_ schema — will get silently dropped by select(any_of(fomd10.cols))
  only_in_fomd10_schema   = setdiff(fomd10.cols, names(paired_bio_context))    # expected by the schema, but no branch currently produces it — will end up entirely missing/empty in the final output
)

list(
  only_in_pairing_outputs = setdiff(names(paired_context), fomd10.cols),   # produced by a branch, but not in the 10_ schema — will get silently dropped by select(any_of(fomd10.cols))
  only_in_fomd10_schema   = setdiff(fomd10.cols, names(paired_context))    # expected by the schema, but no branch currently produces it — will end up entirely missing/empty in the final output
)

list(
  only_in_pairing_outputs = setdiff(names(paired_yield_focal), fomd10.cols),   # produced by a branch, but not in the 10_ schema — will get silently dropped by select(any_of(fomd10.cols))
  only_in_fomd10_schema   = setdiff(fomd10.cols, names(paired_yield_focal))    # expected by the schema, but no branch currently produces it — will end up entirely missing/empty in the final output
)

list(
  only_in_pairing_outputs = setdiff(names(paired_yield_pler), fomd10.cols),   # produced by a branch, but not in the 10_ schema — will get silently dropped by select(any_of(fomd10.cols))
  only_in_fomd10_schema   = setdiff(fomd10.cols, names(paired_yield_pler))    # expected by the schema, but no branch currently produces it — will end up entirely missing/empty in the final output
)

all_pairing_cols <- union(union(names(paired_context), names(paired_yield_focal)), names(paired_yield_pler))

col_presence <- tibble::tibble(
  column     = all_pairing_cols,
  in_context = all_pairing_cols %in% names(paired_context),
  in_focal   = all_pairing_cols %in% names(paired_yield_focal),
  in_pler    = all_pairing_cols %in% names(paired_yield_pler)
) %>%
  dplyr::filter(!(in_context & in_focal & in_pler))  # keep only columns NOT common to all three


#==========================================================
# Combine paired files and unselect unnecesary columns
#==========================================================
fomd10_formated <- dplyr::bind_rows(
  paired_bio_context,
  paired_context,
  paired_yield_focal,
  paired_yield_pler
) %>%
  mutate(effect_size_id = paste0(metadata, "_", dplyr::row_number()))  %>%
  select(any_of(fomd10.cols))

skim(fomd10_formated)

readr::write_csv(fomd10_formated, 
                 paste0(path.metadata.effectsize, "02.fomd10_formated/fomd10_formated_",metadata,".csv"))





#-----------------------------------------------
#---- Match with 01_FOMD_ontologies ----
#-----------------------------------------------
library(tibble)
library(purrr)

#--- Location: Reclassifying country as ISO_3166_1_Alpha_3----
fomd09.clean <- apply_lookup_ontologies(
  fomd09.clean, 
  path.metadata.structure,
  sheet_name = "01_countries",
  key_col = "Country",
  value_col = "ISO_3166_1_Alpha_3",
  src_col = "country",
  new_col = "country_ISO",
  sep = ".."
)

#-----------------------------------------------
#---- Match with 01_FOMD_ontologies ----
#-----------------------------------------------
library(tibble)
library(purrr)

#--- Location: Reclassifying country as ISO_3166_1_Alpha_3----
fomd09.clean <- apply_lookup_ontologies(
  fomd09.clean, 
  path.metadata.structure,
  sheet_name = "01_countries",
  key_col = "Country",
  value_col = "ISO_3166_1_Alpha_3",
  src_col = "country",
  new_col = "country_ISO",
  sep = ".."
)

#Remove duplicate country and country_ISO
md.era.short.clean <- md.era.short.clean %>%
  mutate(
    country = map_chr(str_split(str_squish(country), "\\.\\."), \(x) paste(unique(str_squish(x)), collapse = "..")),
    country_ISO1 = map_chr(str_split(str_squish(country_ISO1), "\\.\\."), \(x) paste(unique(str_squish(x)), collapse = ".."))
  )


# Quick checks
# All the studied countries are in fomd01.countries
unique_countries <-data.frame(
  country = md.era.short.clean %>%
    pull(country) %>%
    str_split("\\.\\.") %>%
    unlist() %>%
    str_trim())%>%
  distinct(country) %>%
  arrange(country)%>%
  left_join(fomd01.countries%>%
              filter(!is.na(Country))%>%
              distinct(Country,ISO_3166_1_Alpha_3),
            by=c("country"="Country"))
#filter(is.na(Product.Type))

sort(unique(md.era.short.clean$country))
sort(unique(md.era.short.clean$country_ISO))



