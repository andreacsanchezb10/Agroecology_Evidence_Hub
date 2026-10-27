library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(readr)
library(tibble)
library(purrr)

path.metadata.effectsize<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/04.metadata_effectsize/"
path.meta.analysis<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/05.meta_analysis/idrc-cfra_analysis/"

#==========================================================
# Read functions
#==========================================================
source(file.path(path.metadata.effectsize, "fomd_fun/fun_load_data_ontologies.R"))
source(file.path(path.meta.analysis, "cfra_fun/fun_outcome_reclassification.R"))
source(file.path(path.meta.analysis, "cfra_fun/fun_food_groups.R"))

#==========================================================
# Read datasets
#==========================================================
#--- fomd10.effect.size -----
fomd10<-read_csv(file.path(path.metadata.effectsize,"04.fomd10_effect_size/fomd10_effect_size.csv"), show_col_types = FALSE)
nrow(fomd10) #v51: 167802;v52: 167797; 168436; 168434; 168595
length(unique(fomd10$study_id)) #1844; 1854; 1860

sort(unique(fomd10$country)) #60

#==========================================================
#--- 1. Select only relevant effect sizes-----
#==========================================================
#--- 1.1 Effect size within the nine CFRA countries ----
# CFRA countries list
cfra.country.names<-c(
  "Angola",
  "Burundi",
  "Ethiopia",
  "Kenya",
  "Malawi",
  "Rwanda",
  "Tanzania",
  "Uganda",
  "Zambia")

# One regex matching any CFRA country name anywhere in the string —
# catches both single-country rows ("Kenya") and multi-country rows
# ("Ethiopia..Ghana", "Tanzania..Malawi..Nigeria..Kenya", etc.)
cfra_pattern <- paste(cfra.country.names, collapse = "|")

fomd10.cfra <- fomd10 %>%
  filter(str_detect(country, cfra_pattern))

sort(unique(fomd10.cfra$country)) #15
sort(unique(fomd10.cfra$C_site_latitude))
sort(unique(fomd10.cfra$T_site_latitude))
length(unique(fomd10.cfra$study_id));nrow(fomd10.cfra) 
#[1] v51 637; v52 637; 646; 651
#[1] v51 42892; v52 42892; 43373; 43492

#--- 1.2 Remove Animal related effect sizes ----
removed.subindicators<-c("Animal Survival" ,
                         "Animal Mortality" ,
                         "Daily Average Weight Gain",
                         "Egg Yield",
                         "Feed Conversion Ratio (In Out)",
                         "Feed Conversion Ratio (Out In)",
                         "Feed Intake"  ,
                         "Fixed Cost-Animals Purchase",
                         "Final Body Weight",
                         "Final Body Weight Meat Yield",
                         "Fuel Use",
                         "Meat Yield",
                         "Meat Yield-Empty Carcass Meat Yield",
                         "Meat Yield-Final Body Weight",
                         "Meat Yield-Hot Carcass" ,                    
                         "Meat Yield-Slaughter Body", 
                         "Milk Yield",
                         "Nitrogen (Apparent Efficiency Animals Feed)",
                         "Protein Conversion Ratio (In Out)",
                         "Protein Conversion Ratio (Out In)" ,
                         "Reproductive Yield",
                         "Total Weight Gain",
                         "Variable Costs-Animal Feed",
                         "Variable Costs-Veterinary",
                         "Weight Gain" )

fomd10.cfra <- fomd10.cfra %>%
  filter(!tolower(out_subindicator) %in% tolower(removed.subindicators))

sort(unique(fomd10.cfra$out_subindicator)) #62 ; 65
#sort(unique(fomd10.cfra$out_subindicator[is.na(fomd10.cfra$out_pillar)])) 
sort(unique(fomd10.cfra$out_pillar)) #3 
#[1] "Mitigation"   "Productivity" "Resilience"

sort(unique(fomd10.cfra$out_subindicator[fomd10.cfra$out_pillar== "Mitigation"])) 
sort(unique(fomd10.cfra$out_subindicator[fomd10.cfra$out_pillar== "Productivity"])) 
sort(unique(fomd10.cfra$out_subindicator[fomd10.cfra$out_pillar== "Resilience"])) 

fomd10.cfra <- fomd10.cfra %>%
  filter(!is.na(C_crop_tree_density))

nrow(fomd10.cfra); length(unique(fomd10.cfra$study_id)) 
#[1] v51 32026; v52 32026; 32483; 32602
#[1] v51 467; v52 467; 476; 481

#--- 1.3 Remove effect sizes that do not report mean for control and treatment ----
fomd10.cfra <- fomd10.cfra %>% filter(!is.na(C_out_mean), !is.na(T_out_mean))

nrow(fomd10.cfra); length(unique(fomd10.cfra$study_id))
#[1] v51 32008; v52 32008; 32441; 32528
#[1] v51 466; v52 466; 474; 479

#--- 1.4 Remove effect sizes without usable site coordinates ----
# Pooled multi-site effect sizes store coordinates as "lat1..lat2..": keep if at least one pair is valid
has_coords <- mapply(function(la, lo) {
  la <- suppressWarnings(as.numeric(str_split(la, fixed(".."))[[1]]))
  lo <- suppressWarnings(as.numeric(str_split(lo, fixed(".."))[[1]]))
  length(la) == length(lo) && any(!is.na(la) & !is.na(lo))
}, fomd10.cfra$C_site_latitude, fomd10.cfra$C_site_longitude)

# TO CHECK: Effect sizes without usable coordinates, by study
no.coords <- fomd10.cfra[!has_coords, ] %>%
  group_by(country, study_id) %>%
  summarise(authors = first(authors), year = first(year), title = first(title),
            n_rows = n(),
            C_site_latitude  = paste(unique(C_site_latitude),  collapse = " | "),
            C_site_longitude = paste(unique(C_site_longitude), collapse = " | "),
            .groups = "drop")
#View(no.coords)

fomd10.cfra <- fomd10.cfra[has_coords, ]
rm(has_coords)
nrow(fomd10.cfra); length(unique(fomd10.cfra$study_id))
#[1] v51 31966; v52 31966; 32399; 32441; 32528
#[1] v51 466; v52 466; 474;479

#--- 1.5 Contrast screening: C and T must differ, and every practice reported in both ----
# All paired C_/T_ practice descriptors (every *_subpractice), plus crop, variety, density and weeding method
ct_cols <- sub("^C_", "", grep("^C_.*(_subpractice|crop_tree_diversity|crop_tree_variety|crop_tree_density)$",
                               names(fomd10.cfra), value = TRUE))
ct_cols <- c(ct_cols, "weed_method")
ct_cols <- ct_cols[paste0("C_", ct_cols) %in% names(fomd10.cfra) & paste0("T_", ct_cols) %in% names(fomd10.cfra)]

ct_differs <- sapply(ct_cols, function(p) {
  c <- tolower(str_trim(fomd10.cfra[[paste0("C_", p)]]))
  t <- tolower(str_trim(fomd10.cfra[[paste0("T_", p)]]))
  !(is.na(c) & is.na(t)) & (is.na(c) | is.na(t) | c != t)
})
ct_one_arm <- sapply(ct_cols, function(p) {
  is.na(fomd10.cfra[[paste0("C_", p)]]) != is.na(fomd10.cfra[[paste0("T_", p)]])
})

fomd10.cfra$ct_varies <- rowSums(ct_differs) > 0
fomd10.cfra$ct_one_arm_empty <- apply(ct_one_arm, 1, function(r) {
  w <- names(r)[r]
  if (length(w) == 0) NA_character_ else paste(w, collapse = "..")
})
rm(ct_differs, ct_one_arm)

# TO CHECK: Studies to check against the source papers
cfra.check <- fomd10.cfra %>%
  group_by(country, study_id) %>%
  summarise(authors = first(authors), year = first(year), title = first(title),
            n_rows = n(),
            n_rows_identical_CT  = sum(!ct_varies),
            n_rows_one_arm_empty = sum(!is.na(ct_one_arm_empty)),
            one_arm_empty_practices = paste(sort(unique(unlist(str_split(na.omit(ct_one_arm_empty), fixed(".."))))),
                                            collapse = "; "),
            .groups = "drop") %>%
  filter(n_rows_identical_CT > 0 | n_rows_one_arm_empty > 0)
#write_csv(cfra.check, file.path(Sys.getenv("USERPROFILE"), "Downloads", "cfra_studies_to_check.csv"))

table(identical = !fomd10.cfra$ct_varies, one_arm = !is.na(fomd10.cfra$ct_one_arm_empty))

fomd10.cfra <- fomd10.cfra %>% filter(ct_varies, is.na(ct_one_arm_empty))
nrow(fomd10.cfra); length(unique(fomd10.cfra$study_id))
#[1] v51 17811; v52 26026; v52.2 25609; 26021; 26053; 26118;25599
#[1] v51 339; v52 423; v52.2 413; 420; 424

#--- 1.5b Remove postharvest practices (not AE/RA production practices) ----
fomd10.cfra <- fomd10.cfra %>%
  filter(is.na(postharvest_practice))

nrow(fomd10.cfra); length(unique(fomd10.cfra$study_id))
#[1] v51 17303; v52 25518; v52.2 25101; 25513; 25545; 25610
#[1] v51 334; v52 418; v52.2 408; 415; 419

#--- 1.6 Outcomes: outcome group and direction of each paired comparison (criterion iv) ----
fomd10.cfra <- add_outcome_direction(fomd10.cfra)

#sort(unique(fomd10$study_id[fomd10$out_subindicator=="Total Factor Productivity"])) 

#--- 1.6.1 # Check: subindicators in the data that are not in outcome_lookup ----
# They will be dropped; add them to outcome_lookup (cfra_fun/fun_outcomes.R) if they should be kept.
setdiff(unique(fomd10.cfra$out_subindicator), outcome_lookup$out_subindicator)

fomd10.cfra %>% filter(pest_count) %>%
  group_by(bio_func_group, T_product, outcome_group, lower_is_better) %>%
  summarise(paired_comparisons = n_distinct(effect_size_id), .groups = "drop")

nrow(fomd10.cfra); length(unique(fomd10.cfra$study_id))
#[1] v51 17291; v52 25480; v52.2 25063; 25513; 25545; 25605; 25091
#[1] v51 334; v52 418; v52.2 408; 415; 419

#--- 1.7 Food groups relevant to school meals (criterion iii) ----
# crop -> food group lookup from the ontology (read only)
product_lookup <- fomd01.product.new %>%
  filter(!is.na(Product)) %>%
  distinct(product = Product, g = FAO.Food.Group, s = FAO.Food.SubGroup) %>%
  mutate(food_group = fao_to_school(g, s)) %>%
  group_by(product) %>% slice(1) %>% ungroup() %>%
  select(product, food_group)%>%
  mutate(food_group= case_when(
    product=="Calabash Seed"~"Nuts and seeds",
    product=="Watermelon Seed Ground"~"Nuts and seeds",
    TRUE~food_group))

write_csv(product_lookup, paste0(path.meta.analysis,"01.cfra_data/product_lookup.csv"))

fomd10.cfra <- assign_food_group(fomd10.cfra, product_lookup)   # one row per food group
fomd10.cfra <- add_nfix_trees(fomd10.cfra)

# TO CHECK always:paired comparisons without a school-meal food group (fodder, stimulant, spice, fibre crops)
# TO CHECK: if the pepper papers in ERA are vegetables or what
food_tocheck<-fomd10.cfra %>%
  filter(is.na(food_group)) %>%
  count(study_id,country,#title,
    T_crop_tree_diversity,
    T_crop_tree_FAO_Food_Group, T_product,#T_data_location,
        T_product_simple, out_subindicator,sort = TRUE)

fomd10.cfra <- fomd10.cfra %>% filter(!is.na(food_group))

nrow(fomd10.cfra); length(unique(fomd10.cfra$study_id))
#[1] v51 16935; v52 25151; v52.2 24769; 25436;25387; 25419; 25528;25031
#[1] v51 317; v52 398; v52.2 389; 397;396; 401;393

#--- 1.8 Check: variety management types and traits (all CFRA countries) ----
source(file.path(path.meta.analysis, "cfra_fun/fun_practices_reclassification.R"))

variety <- reclassify_practices(fomd10.cfra) %>%
  filter(practice_group == "Variety management") %>%
  mutate(across(c(C_varietal_crop_type, T_varietal_crop_type, C_varietal_crop_trait, T_varietal_crop_trait),
                ~ na_if(.x, "") %>% str_replace_all(fixed("..NA"), "") %>% coalesce("(none)")))

# a. Types (local, hybrid, OPV, cultivar...) in control vs treatment
variety.types <- variety %>%
  group_by(C_varietal_crop_subpractice,T_varietal_crop_subpractice,
    C_practice, T_practice, C_varietal_crop_type, T_varietal_crop_type) %>%
  summarise(countries = paste(sort(unique(country)), collapse = "; "),
            studies = n_distinct(study_id),
            paired_comparisons = n_distinct(effect_size_id), .groups = "drop") %>%
  arrange(C_practice, T_practice, desc(paired_comparisons))
View(variety.types)

# b. Traits in control vs treatment
variety.traits <- variety %>%
  group_by(C_practice, T_practice, C_varietal_crop_trait, T_varietal_crop_trait) %>%
  summarise(countries = paste(sort(unique(country)), collapse = "; "),
            studies = n_distinct(study_id),
            paired_comparisons = n_distinct(effect_size_id), .groups = "drop") %>%
  arrange(C_practice, T_practice, desc(paired_comparisons))
View(variety.traits)

# c. Full detail per study: variety names, types and traits
variety.studies <- variety %>%
  distinct(country, study_id, effect_size_id, C_practice, T_practice,
           C_varietal_crop_variety, T_varietal_crop_variety,
           C_varietal_crop_type, T_varietal_crop_type,
           C_varietal_crop_trait, T_varietal_crop_trait) %>%
  group_by(across(-effect_size_id)) %>%
  summarise(paired_comparisons = n(), .groups = "drop") %>%
  arrange(country, study_id, C_practice, T_practice)
View(variety.studies)

# write_csv(variety.studies, file.path(Sys.getenv("USERPROFILE"), "Downloads", "cfra_variety_check.csv"))


write_csv(fomd10.cfra, paste0(path.meta.analysis,"01.cfra_data/fomd10_cfra.csv"))

