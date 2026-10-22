library(dplyr)
library(tibble)
library(stringr)

#==========================================================
# Outcomes: outcome group and direction of each paired comparison
#==========================================================
# 1. outcome_lookup: each subindicator is assigned to one outcome group and flagged
#    when a decrease is the desirable result (lower_is_better = TRUE).
#    Subindicators not listed here are excluded from the analysis.
# 2. add_outcome_direction(): adds outcome_group, lower_is_better and direction
#    (+1 treatment better, -1 worse, 0 equal) and drops subindicators not in the table.
#
# Step 1 is the decision: edit it here. Step 2 does not need to be edited.
#==========================================================

#----------------------------------------------------------
#--- 1. Outcome lookup ----
#----------------------------------------------------------
outcome_lookup <- tribble(
  ~out_subindicator,                    ~outcome_group,         ~lower_is_better,
  "Area Time Equivalent Ratio",         "Productivity",                FALSE,
  "Biomass Yield",                      "Productivity",                FALSE,
  "Crop Residue Yield",                 "Productivity",                FALSE,
  "Crop Yield",                         "Productivity",                FALSE,
  "Total Factor Productivity",          "Productivity",                FALSE,
  
  "Gross Margin",                       "Profitability",        FALSE,
  "Gross Return",                       "Profitability",        FALSE,
  "Net Return",                         "Profitability",        FALSE,
  "Benefit Cost Ratio (GMVC)",          "Profitability",        FALSE,
  "Benefit Cost Ratio (GRVC)",          "Profitability",        FALSE,
  "Benefit Cost Ratio (NRTC)",          "Profitability",        FALSE,
  "Marginal Rate of Return",            "Profitability",        FALSE,
  "Return on Investment",               "Profitability",        FALSE,
  "Return to Labour",                   "Profitability",        FALSE,
  "Labour Cost",                        "Profitability",        TRUE,
  "Net Present Value",                  "Profitability",        FALSE,
  "Variable Cost",                      "Profitability",        TRUE,
  "Variable Cost per Unit Product",     "Profitability",        TRUE,
  "Fixed Cost",                         "Profitability",        TRUE,
  "Total Cost",                         "Profitability",        TRUE,
  
  "Cation Exchange Capacity",           "Soil health",          FALSE,
  "Soil Organic Carbon",                "Soil health",          FALSE,
  "Soil Organic Carbon (Change)",       "Soil health",          FALSE,
  "Soil Organic Matter",                "Soil health",          FALSE,
  "Soil Total Nitrogen",                "Soil health",          FALSE,
  "Soil Available Nitrogen",            "Soil health",          FALSE,
  "Soil Nitrogen",                      "Soil health",          FALSE,
  "Soil NH4",                           "Soil health",          FALSE,
  "Soil NO3",                           "Soil health",          FALSE,
  "Soil Available Phosphorus",          "Soil health",          FALSE,
  "Effective Cation Exchange Capacity", "Soil health",          FALSE,
  "Soil Moisture",                      "Soil health",          FALSE,
  "Infiltration Rate",                  "Soil health",          FALSE,
  "Erosion",                            "Soil health",          TRUE,
  "Runoff",                             "Soil health",          TRUE,
  
  "Aboveground Carbon Biomass",         "Climate mitigation",   FALSE,
  "Carbon Dioxide Emissions",           "Climate mitigation",   TRUE,
  "CO2 Equivalent Emissions",           "Climate mitigation",   TRUE,
  "Emissions Intensity",                "Climate mitigation",   TRUE,
  "Methane Emissions",                  "Climate mitigation",   TRUE,
  "Nitrous Oxide Emissions",            "Climate mitigation",   TRUE,
  "Soil Carbon Stocks",                 "Climate mitigation",   FALSE,
  
  "Damage caused by pest",              "Resilience to pests",  TRUE,
  "Pest & Pathogen (Losses)",           "Resilience to pests",  TRUE,
  "Pest & Pathogen (Numbers)",          "Resilience to pests",  TRUE,
  
  "Nitrogen Agronomic Efficiency",      "Inputs efficiency",    FALSE,
  "Water Use Efficiency",               "Inputs efficiency",    FALSE,
  "Water Use",                          "Inputs efficiency",    TRUE,
  
  "Labour Female",                      "Labour demand",        TRUE,
  "Labour Male",                        "Labour demand",        TRUE,
  "Labour Person Hours",                "Labour demand",        TRUE,
  
  "Abundance",                          "Biodiversity",         FALSE,
  "Berger-Parker dominance (d)",        "Biodiversity",         TRUE,
  "Pielou Index",                       "Biodiversity",         FALSE,
  "Shannon-Wiener Index",               "Biodiversity",         FALSE,
  "Species Evenness",                   "Biodiversity",         FALSE,
  "Species Richness",                   "Biodiversity",         FALSE,
  "Taxonomic Richness",                 "Biodiversity",         FALSE
)

#----------------------------------------------------------
#--- 2. Function ----
#----------------------------------------------------------
# df   paired comparisons with out_subindicator, C_out_mean and T_out_mean
# Prints the subindicators that are not in outcome_lookup (they are dropped).
add_outcome_direction <- function(df, lookup = outcome_lookup) {
  
  dropped <- setdiff(unique(df$out_subindicator), lookup$out_subindicator)
  if (length(dropped) > 0) message("Subindicators not in outcome_lookup (dropped): ",
                                   paste(sort(dropped), collapse = "; "))
  
  df %>%
    inner_join(lookup, by = "out_subindicator") %>%
    # Pest and weed counts measured as "biodiversity" -> Resilience to pests (fewer = better)
    mutate(pest_count      = outcome_group == "Biodiversity" &
             str_detect(coalesce(bio_func_group, ""), "^Pests|^Weeds"),
           outcome_group   = if_else(pest_count, "Resilience to pests", outcome_group),
           lower_is_better = if_else(pest_count, TRUE, lower_is_better)) %>%
    mutate(direction = sign(T_out_mean - C_out_mean),                   # +1 higher, -1 lower, 0 equal
           direction = if_else(lower_is_better, -direction, direction))  # +1 always = improvement
}