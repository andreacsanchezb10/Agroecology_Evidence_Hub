# ============================================================
# load_data.R
# Run this file to load all datasets into your environment.
# Make sure path.metadata.structure is defined before sourcing
# this file, or define it here directly.
# ============================================================

library(readxl)
library(dplyr)

path.metadata.structure<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/02.metadata_structure"

#--------------------------------------------------------------
# -- FOMD Ontologies ------------------------------------------
#--------------------------------------------------------------
fomd01.countries <- read_xlsx(
  file.path(path.metadata.structure, "01_FOMD_ontologies.xlsx"),
  sheet = "01_countries")

fomd01.sites <- read_xlsx(
  file.path(path.metadata.structure, "01_FOMD_ontologies.xlsx"),
  sheet = "01_sites")

fomd01.trees <- read_xlsx(
  file.path(path.metadata.structure, "01_FOMD_ontologies.xlsx"),
  sheet = "01_trees")

fomd01.product.new <- read_xlsx(
  file.path(path.metadata.structure, "01_FOMD_ontologies.xlsx"),
  sheet = "01_product_new")

fomd01.outcomes <- read_xlsx(
  file.path(path.metadata.structure, "01_FOMD_ontologies.xlsx"),
  sheet = "01_outcomes") %>%
  filter(!is.na(subindicator))

fomd01.practices <- read_xlsx(
  file.path(path.metadata.structure, "01_FOMD_ontologies.xlsx"),
  sheet = "01_practices")

# ── Quick checks ─────────────────────────────────────────────
sort(unique(fomd01.practices$subpractice))

message("✔ All FOMD ontology datasets loaded successfully.")