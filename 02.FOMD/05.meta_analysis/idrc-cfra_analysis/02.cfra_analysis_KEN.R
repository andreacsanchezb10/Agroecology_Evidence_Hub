library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(readr)
library(tibble)
library(purrr)
library(ggplot2)
library(forcats)
library(sf)
library(patchwork)
library(terra)

#==========================================================
#--- Report DEEP-DIVE COUNTRY: KENYA
#==========================================================
path.metadata.effectsize<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/04.metadata_effectsize/"
path.meta.analysis<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/05.meta_analysis/idrc-cfra_analysis/"
path.archetypes <- paste0(path.meta.analysis, "archetypes/")
path.output        <- paste0(path.meta.analysis,"/02.cfra_analysis/Kenya/")

#==========================================================
#--- 0. Country settings (the only part to change per country) ----
#==========================================================
country_name <- "Kenya"
country_code <- "ken"

# One row per archetype: code, name, gpkg file, and rule defining its high-priority areas
archetypes <- tribble(
  ~code, ~archetype,                ~file,                                ~rule,
  "2A",  "2A - Soil restoration",   "Archetype_2A_ADM1_Choropleth.gpkg",  "Criteria_Met_Count >= 3",
  "2B",  "2B - Arid micro-gardens", "Archetype_2B_ADM1_Choropleth.gpkg",  "ASAL_County == 'Yes' & Criteria_Met_Count >= 4"
)

# Thresholds (same for all countries)
min_paired_comparisons <- 100  # below this, expand to agro-ecological zones (2.2.1)
min_es_cell  <- 1             # cells with fewer paired comparisons are not coloured
strong_es    <- 50             # strong evidence
cut_positive <- 65
cut_negative <- 35

# Extension of the evidence by agro-ecological zone (Methods 2.2.1)
neighbour_countries <- c("Ethiopia", "Tanzania", "Uganda")   # bordering project countries
min_share_aez       <- 10                                     # main zones: >= 10% of the high-priority areas
aez_files <- c(Kenya = "GAEZ_AEZ57_KEN.tif", Ethiopia = "GAEZ_AEZ57_ETH.tif",
               Tanzania = "GAEZ_AEZ57_TZA.tif", Uganda = "GAEZ_AEZ57_UGA.tif")   # country first

#==========================================================
# Read functions
#==========================================================
source(file.path(path.meta.analysis, "cfra_fun/fun_archetype_selection.R")) #need to create
source(file.path(path.meta.analysis,"cfra_fun/fun_practices_reclassification.R"))
source(file.path(path.meta.analysis, "cfra_fun/fun_direction_count.R"))
source(file.path(path.meta.analysis, "cfra_fun/fun_food_groups.R"))

#==========================================================
#--- Read datasets
#==========================================================
#--- fomd10.effect.size: the country and its neighbouring project countries ----
data.pool <- read_csv(file.path(path.meta.analysis, "01.cfra_data/fomd10_cfra.csv"), show_col_types = FALSE) %>%
  filter(str_detect(country, paste(c(country_name, neighbour_countries), collapse = "|"))) %>%
  mutate(food_group = factor(food_group, levels = food_group_order))  # CSV loses the order
data <- data.pool %>% filter(str_detect(country, country_name))

nrow(data); length(unique(data$study_id))
#[1] 6830
#[1] 96

#--- Agro-ecological zones (GAEZ v4) ----
aez.found <- aez_files[file.exists(file.path(path.meta.analysis, "GAEZ", aez_files))]
if (length(aez.found) < length(aez_files))
  warning("GAEZ raster missing for: ", paste(setdiff(names(aez_files), names(aez.found)), collapse = ", "))
aez.rasters <- lapply(file.path(path.meta.analysis, "GAEZ", aez.found), rast)
gaez.lookup <- read.csv(file.path(path.meta.analysis, "GAEZ/GAEZ_57_lookup.csv"), stringsAsFactors = FALSE)

#==========================================================
#--- 1. Evidence for each archetype (Methods 2.2.1) ----
#==========================================================
# 1. comparisons located in the high-priority areas
# 2. sufficient: >= 100 comparisons and >= 1 study in each main agro-ecological zone
# 3. otherwise extended with comparisons from the same zones (country, then neighbouring countries)
points      <- make_points(data)
points.pool <- make_points(data.pool)
sites.pool  <- site_aez(points.pool, aez.rasters)
pool.long   <- reclassify_practices(mutate(data.pool, archetype = NA_character_))   # practices of all candidates

selection <- pmap(archetypes, function(code, archetype, file, rule) {
  arc  <- st_read(file.path(path.archetypes, country_code, file), quiet = TRUE)
  main <- main_aez(arc, rule, aez.rasters[[1]], gaez.lookup, min_share = min_share_aez)
  ids  <- select_priority(points, arc, rule)$effect_size_id
  select_evidence(ids, pool.long, sites.pool, main, country_name, neighbour_countries,
                  min_comparisons = min_paired_comparisons)
})
names(selection) <- archetypes$archetype

# Sufficiency and main zones per archetype (Table SX)
for (a in names(selection)) {
  cat("\n=====", a, "| sufficient within high-priority areas:", selection[[a]]$sufficient, "\n")
  print(as.data.frame(selection[[a]]$zones), right = FALSE)
  cat("evidence gaps:", if (length(selection[[a]]$gaps)) selection[[a]]$gaps else "none", "\n")
}

#===== 2A - Soil restoration | sufficient within high-priority areas: TRUE 
#aez zone                                                       share studies_priority studies_final comparisons_final
#1  2  Tropics, lowland; semi-arid, with soil/terrain limitations 19.5   8                8           219 
#2 50  Land with severe soil/terrain limitations                  17.2  20               20           446
#3  1  Tropics, lowland; semi-arid, no soil/terrain limitations   10.4   1                1           1
#evidence gaps: none

#===== 2B - Arid micro-gardens | sufficient within high-priority areas: FALSE 
#aez zone                                                       share studies_priority studies_final comparisons_final
#1  2  Tropics, lowland; semi-arid, with soil/terrain limitations 37.2  6                6            86 
#2 53  Desert/Arid climate                                        31.5  0                1            28
#3  1  Tropics, lowland; semi-arid, no soil/terrain limitations   11.0  0                1            1
#evidence gaps: none

# Comparisons used per archetype, with their origin (column `selection`)
arc.ids  <- imap_dfr(selection, ~ mutate(.x$ids, archetype = .y))
arc.long <- pool.long %>% select(-archetype) %>% inner_join(arc.ids, by = "effect_size_id", relationship = "many-to-many")
arc.data <- data.pool %>% inner_join(arc.ids, by = "effect_size_id", relationship = "many-to-many")

arc.long %>% group_by(archetype, selection) %>%
  summarise(studies = n_distinct(study_id), comparisons = n_distinct(effect_size_id), .groups = "drop")

#==========================================================
#--- 2. Practice tested in each paired comparison ----
# A practice is tested when its harmonised C and T labels differ.
#==========================================================
arc.long <- reclassify_practices(arc.data)

# Before -> after reclassification
practices.check <- arc.long %>%
  group_by(practice_group, C_original, T_original, C_practice, T_practice, swapped) %>%
  summarise(studies = n_distinct(study_id),
            paired_comparisons = n_distinct(effect_size_id), .groups = "drop") %>%
  arrange(practice_group, C_practice, T_practice)
#View(practices.check)

# Tested practices (T vs C) per archetype, food group and practice group
practices <- arc.long %>%
  group_by(#archetype,
    #study_id,
    food_group, practice_group, T_practice, C_practice) %>%
  summarise(studies = n_distinct(study_id),
            paired_comparisons = n_distinct(effect_size_id), .groups = "drop") %>%
  arrange(#archetype,
          #study_id,
    food_group, practice_group, desc(paired_comparisons))
View(practices)


arc.long %>% semi_join(exclude_pairs, by = c("C_practice", "T_practice"))

#--- 2.1 Check: variety comparisons dropped by the local vs improved classification ----
variety.dropped <- arc.data %>%
  filter(!is.na(variety_management_practice)) %>%
  mutate(C_original = str_trim(str_remove(str_extract(variety_management_practice, "^C: .*?(?=_vs_T: )"), "^C: ")),
         T_original = str_trim(str_remove(str_extract(variety_management_practice, "_vs_T: .*$"), "^_vs_T: ")),
         C_new = variety_origin(C_original, C_varietal_crop_type, C_varietal_crop_variety),
         T_new = variety_origin(T_original, T_varietal_crop_type, T_varietal_crop_variety),
         reason = case_when(C_original == T_original              ~ "same label in C and T (never tested)",
                            C_new == "Unspecified variety" |
                              T_new == "Unspecified variety"      ~ "unspecified arm (not local, not improved)",
                            C_new == T_new                        ~ "improved vs improved (variety trial)",
                            TRUE                                  ~ "kept")) %>%
  filter(reason != "kept", reason != "same label in C and T (never tested)") %>%
  group_by(archetype, study_id, reason, C_original, T_original,
           C_varietal_crop_type, T_varietal_crop_type,
           C_varietal_crop_trait, T_varietal_crop_trait,
           C_varietal_crop_variety, T_varietal_crop_variety) %>%
  summarise(paired_comparisons = n_distinct(effect_size_id), .groups = "drop") %>%
  arrange(archetype, reason, study_id)
View(variety.dropped)

arc.long %>%
  filter(T_practice == "Local variety") %>%
  distinct(effect_size_id, .keep_all = TRUE) %>%
  count(swapped, T_varietal_crop_type, C_varietal_crop_type, T_varietal_crop_variety)

#==========================================================
#--- 3. Count of positive paired comparisons ----
#==========================================================
cells <- count_effects(arc.long,
                       by = c("archetype", "food_group", "practice_group",
                              "T_practice", "C_practice", "outcome_group"))

#==========================================================
#--- 4. Evidence distribution and gaps ----
#==========================================================
source(file.path(path.meta.analysis,"cfra_fun/fun_plot_archetype.R"))

#--- 4.1 Figure: high-priority areas (a) and main agro-ecological zones with study sites (b) ----
map_settings <- list(
  "2A" = list(n_criteria = 4, scope_col = NULL,          legend_title = "Criteria met (0-4)"),
  "2B" = list(n_criteria = 5, scope_col = "ASAL_County",
              scope_label = "Non-ASAL county (out of scope for this archetype)",
              legend_title = "Criteria met\n(ASAL counties only)"))
map_fig_numbers <- c("2A" = 1, "2B" = 1)   # figure number of each archetype in the report

legend_below <- theme(legend.position = "bottom", legend.direction = "vertical", legend.box = "vertical",
                      legend.justification = c(0, 1), legend.box.just = "left", legend.location = "plot",
                      legend.key.spacing.y = unit(2, "pt"), plot.margin = margin(2, 2, 2, 2))

for (i in seq_len(nrow(archetypes))) {
  code <- archetypes$code[i]
  set  <- map_settings[[code]]
  arc  <- st_read(file.path(path.archetypes, country_code, archetypes$file[i]), quiet = TRUE)
  pr   <- arc[with(arc, eval(str2lang(archetypes$rule[i]))) %in% TRUE, ]
  
  # a) high-priority areas (normal colours, black outline)
  map_a <- plot_archetype(arc, n_criteria = set$n_criteria, scope_col = set$scope_col,
                          scope_label = if (is.null(set$scope_label)) "Out of scope" else set$scope_label,
                          legend_title = set$legend_title) +
    geom_sf(data = st_union(pr), aes(linetype = "priority"), fill = NA, colour = "grey10", linewidth = 0.6) +
    scale_linetype_manual(values = c(priority = "solid"), labels = "High-priority areas", name = NULL) +
    guides(fill = guide_legend(order = 1), linetype = guide_legend(order = 2)) +
    labs(title = "a)") +
    theme(plot.title = element_text(face = "bold", size = 9),
          legend.title = element_text(size = 7, face = "bold"), legend.text = element_text(size = 6.5),
          legend.key.size = unit(0.35, "cm"))
  
  # b) main agro-ecological zones and sites of the comparisons used (within and added)
  points_used <- points.pool %>%
    inner_join(filter(arc.ids, archetype == archetypes$archetype[i]), by = "effect_size_id") %>%
    left_join(distinct(pool.long, effect_size_id, study_id, country), by = "effect_size_id")
  map_b <- plot_aez_evidence(arc, archetypes$rule[i], aez.rasters[[1]], gaez.lookup, points_used,
                             aez_rasters = aez.rasters, min_share = min_share_aez) +
    labs(title = "b)") + theme(plot.title = element_text(face = "bold", size = 9))
  
  map <- patchwork::wrap_plots(map_a + legend_below, map_b + legend_below, nrow = 1)
  print(map)
  ggsave(file.path(path.output, paste0(country_code, "_", code, "_Fig", map_fig_numbers[[code]], ".png")),
         map, width = 6, height = 6, dpi = 300, bg = "white")
}

#--- 4.2 Table: agro-ecological zones and evidence per zone, one per archetype ----
aez_table_numbers <- c("2A" = 1, "2B" = 1)   # supplementary table number of each archetype

for (i in seq_len(nrow(archetypes))) {
  code <- archetypes$code[i]
  arc  <- st_read(file.path(path.archetypes, country_code, archetypes$file[i]), quiet = TRUE)
  
  table.aez <- aez_table(arc, archetypes$rule[i], aez.rasters[[1]], gaez.lookup,
                         selection[[archetypes$archetype[i]]], pool.long, points.pool, aez.rasters,
                         min_share = min_share_aez)
  View(table.aez)
  
  write_csv(table.aez, file.path(path.output, paste0(country_code, "_", code, "_TableS",
                                                     aez_table_numbers[[code]], "_aez.csv")))
}

#--- 4.3 Table: studies and comparisons per high-priority county, one per archetype ----
county_table_numbers <- c("2A" = 8, "2B" = 11)   # supplementary table number of each archetype

for (i in seq_len(nrow(archetypes))) {
  code <- archetypes$code[i]
  arc  <- st_read(file.path(path.archetypes, country_code, archetypes$file[i]), quiet = TRUE)
  
  table.county <- county_table(arc, archetypes$rule[i], selection[[archetypes$archetype[i]]],
                               pool.long, points.pool) %>%
    rename(County = NAME_1, `Criteria met` = Criteria_Met_Count)
  View(table.county)
  
  write_csv(table.county, file.path(path.output, paste0(country_code, "_", code, "_TableS",
                                                        county_table_numbers[[code]], "_counties.csv")))
}
#--- 4.4 Year of publication of the studies included in the analysis (supplementary) ----
figS_years_numbers <- c("2A" = 1, "2B" = 1)   # supplementary figure number of each archetype

for (i in seq_len(nrow(archetypes))) {
  code <- archetypes$code[i]
  
  fig_years <- plot_years(filter(arc.long, archetype == archetypes$archetype[i]))
  print(attr(fig_years, "summary"))   # numbers for the text
  print(fig_years)
  
  ggsave(file.path(path.output, paste0(country_code, "_", code, "_FigS", figS_years_numbers[[code]], "_years.png")),
         fig_years, width = 6.3, height = 2.5, dpi = 300, bg = "white")
}

#--- 4.5 Evidence distribution by food group, practice and outcome, one figure per archetype ----
dist_fig_numbers <- c("2A" = 2, "2B" = 2)   # figure number of each archetype in the report

for (i in seq_len(nrow(archetypes))) {
  code <- archetypes$code[i]
  
  fig_dist <- plot_distribution(filter(arc.long, archetype == archetypes$archetype[i]))
  print(fig_dist)
  
  ggsave(file.path(path.output, paste0(country_code, "_", code, "_Fig", dist_fig_numbers[[code]], ".png")),
         fig_dist, width = 7.5, height = 0.17 * attr(fig_dist, "n_rows") + 0.6, dpi = 300, bg = "white")
}

#==========================================================
#--- 5. Evidence synthesis on the effect of AE/RA practices ----
#==========================================================
#--- 5.1 Figure: Evidence synthesis on the effects of AE/RA practices on eight farm outcomes  ----
source(file.path(path.meta.analysis, "cfra_fun/fun_plot_count_grouped.R"))

legend.grid <- grid_legend_small(strong_es = strong_es, cut_positive = cut_positive,
                                 cut_negative = cut_negative, text_size = 7)
parts <- list(all = c("Cereals", "Pulses and legumes", "Vegetables", "Roots and tubers", "Nuts and seeds", "Fruits"))
row_in <- 0.22                                   # inches per practice row

# figure number of each archetype in the report (only for these heat maps)
fig_numbers <- c("2A" = 3, "2B" = 3)

for (i in seq_len(nrow(archetypes))) {
  arc_name <- archetypes$archetype[i]
  arc_code <- archetypes$code[i]
  for (part in names(parts)) {
    groups <- parts[[part]]
    cc <- cells %>% filter(food_group %in% groups)
    if (!any(cc$archetype == arc_name)) next
    
    p <- plot_votes_grouped(cc, arc_name, min_es_cell = min_es_cell, strong_es = strong_es,
                            cut_positive = cut_positive, cut_negative = cut_negative, text_size = 7)
    
    # legend below the figure, centred
    legend.row <- wrap_plots(plot_spacer(), legend.grid, plot_spacer(), widths = c(0.3, 3.4, 0.3))
    fig <- wrap_plots(p, legend.row, ncol = 1, heights = c(attr(p, "n_rows"), 2))
    
    # file name: <country>_<archetype>_fig<number><part>.png, e.g. ken_2A_fig3a.png
    fig_name <- paste0(country_code, "_", arc_code, "_Fig", fig_numbers[[arc_code]],
                       if (length(parts) > 1) part else "", ".png")
    
    ggsave(file.path(path.output, fig_name),
           fig, width = 7.5, height = row_in * (attr(p, "n_rows") + 2) + 0.4, dpi = 300, bg = "white")
    
    # same figure as PDF (vector: sharp at any zoom, best for the report)
    ggsave(file.path(path.output, sub("[.]png$", ".pdf", fig_name)),
           fig, width = 7.5, height = row_in * (attr(p, "n_rows") + 2) + 0.4,
           device = cairo_pdf, bg = "white")
  }
}

#==========================================================
#--- 6. Evidence synthesis interpretation in detail ----
#==========================================================
source(file.path(path.meta.analysis, "cfra_fun/fun_practice_detail_analysis.R"))

#--- Archetype 2A: Table S4 Effect of Organic fertilizer on cereals yield, soil health, biodiversity ----
# Cereals, Organic fertilizer, Yield
ic.2a.sxa <- practice_detail(arc.long, "2A - Soil restoration", "Organic fertilizer", "No fertilizer applied",
                             food = "Cereals", outcome = "Yield", data = arc.data,
                             extra = "T_fert_subpractice")

View(ic.2a.sxa$companions)    # cereal measured + species it was intercropped with

table.2a.sxa <- ic.2a.sxa$companions %>%
  rename(`Organic input` = T_fert_subpractice)%>%
  mutate(`Outcome measured` = "Yield")%>%
  select(1:3,10,4:9)%>%
  mutate(`Companion species`=if_else(is.na(`Companion species`),"-",`Companion species`))%>%
  arrange(`Measured crop`,       # 1st: A to Z
          `Organic input`,
          desc(`% positive comparisons`))     # 3rd: largest to smallest within each outcome

View(table.2a.sxa)

# Cereals, Organic fertilizer, Soil health
ic.2a.sxb <- practice_detail(arc.long, "2A - Soil restoration", "Organic fertilizer", "No fertilizer applied",
                             food = "Cereals", outcome = "Soil health", data = arc.data,
                             extra = c("T_fert_subpractice", "out_subindicator"))

View(ic.2a.sxb$companions)    # cereal measured + species it was intercropped with

table.2a.sxb <- ic.2a.sxb$companions %>%
  rename(`Organic input` = T_fert_subpractice,
         `Main crop` = `Measured crop`, 
         `Outcome measured` = out_subindicator)%>%
  mutate(`Companion species`=if_else(is.na(`Companion species`),"-",`Companion species`))%>%
  arrange(`Main crop`,       # 1st: A to Z
          `Organic input`,
          `Outcome measured`,
          desc(`% positive comparisons`))     # 3rd: largest to smallest within each outcome

View(table.2a.sxb)

# Cereals, Organic fertilizer, Biodiversity
ic.2a.sxc <- practice_detail(arc.long, "2A - Soil restoration", "Organic fertilizer", "No fertilizer applied",
                             food = "Cereals", outcome = "Biodiversity", data = arc.data,
                             extra = c("T_fert_subpractice", "out_subindicator"))

View(ic.2a.sxc$companions)    # cereal measured + species it was intercropped with

table.2a.sxc <- ic.2a.sxc$companions %>%
  rename(`Organic input` = T_fert_subpractice, `Outcome measured` = out_subindicator,
         `Cropping system` = `Companion species`,
         `Measured taxa` =`Measured crop`)%>%
  mutate(`Cropping system`=if_else(is.na(`Cropping system`),"-",`Cropping system`))%>%
  arrange(`Measured taxa`,       # 1st: A to Z
          `Organic input`,
          `Outcome measured`,
          desc(`% positive comparisons`))     # 3rd: largest to smallest within each outcome

View(table.2a.sxc)

table.2a.sx <- do.call(rbind, Map(with_header,
                                  list(table.2a.sxa, table.2a.sxb, table.2a.sxc),
                                  c("a) Cereal yields, by measured crop, companion species and type of organic input.",
                                    "b) Soil health in cereal systems, by main crop, companion species and type of organic input.",
                                    "c) Biodiversity in cereal systems, by measured taxa, cropping system and type of organic input.")))
View(table.2a.sx)

write_csv(table.2a.sx, file.path(path.output, "ken_2A_TableSX_cereals_organic.csv"))

#--- Archetype 2A: Table S5 Effect of Mixed fertilizer on cereals yield, and soil health ----
# Cereals, Mixed fertilizer, Yield
ic.2a.sxa <- practice_detail(arc.long, "2A - Soil restoration", "Mixed fertilizer", "No fertilizer applied",
                             food = "Cereals", outcome = "Yield", data = arc.data,
                             extra = "T_fert_subpractice")

View(ic.2a.sxa$companions)    # cereal measured + species it was intercropped with


table.2a.sxa <- ic.2a.sxa$companions %>%
  rename(`Mixed input` = T_fert_subpractice)%>%
  mutate(`Outcome measured` = "Yield")%>%
  select(1:3,10,4:9)%>%
  mutate(`Companion species`=if_else(is.na(`Companion species`),"-",`Companion species`),
         `Mixed input`=str_replace_all(`Mixed input`, "\\.{2,}", " + "))%>%
  arrange(`Measured crop`,       # 1st: A to Z
          `Mixed input`,
          desc(`% positive comparisons`))     # 3rd: largest to smallest within each outcome

View(table.2a.sxa)

# Cereals, Organic fertilizer, Soil health
ic.2a.sxb <- practice_detail(arc.long, "2A - Soil restoration", "Mixed fertilizer", "No fertilizer applied",
                             food = "Cereals", outcome = "Soil health", data = arc.data,
                             extra = c("T_fert_subpractice", "out_subindicator"))

View(ic.2a.sxb$companions)    # cereal measured + species it was intercropped with

table.2a.sxb <- ic.2a.sxb$companions %>%
  rename(`Mixed input` = T_fert_subpractice,
         `Main crop` = `Measured crop`, 
         `Outcome measured` = out_subindicator)%>%
  mutate(`Companion species`=if_else(is.na(`Companion species`),"-",`Companion species`),
         `Mixed input`=str_replace_all(`Mixed input`, "\\.{2,}", " + "))%>%
  arrange(`Main crop`,       # 1st: A to Z
          `Mixed input`,
          `Outcome measured`,
          desc(`% positive comparisons`))     # 3rd: largest to smallest within each outcome

View(table.2a.sxb)

table.2a.sx <- do.call(rbind, Map(with_header,
                                  list(table.2a.sxa, table.2a.sxb),
                                  c("a) Cereal yields, by measured crop, companion species and type of mixed input.",
                                    "b) Soil health in cereal systems, by main crop, companion species and type of mixed input."
                                    )))
View(table.2a.sx)

write_csv(table.2a.sx, file.path(path.output, "ken_2A_TableSX_cereals_mixed_fertilizer.csv"))

#--- Archetype 2A: Table S6 Effect of Residues incorporation on cereals soil health ----
# Cereals, Residues incorporation, Soil health
ic.2a.sx <- practice_detail(arc.long, "2A - Soil restoration", "Residues incorporation", "Residues removed",
                             food = "Cereals", outcome = "Soil health", data = arc.data,
                             extra = c("T_residues_subpractice", "out_subindicator"))
View(ic.2a.sx$companions)    # cereal measured + species it was intercropped with

table.2a.sx <- ic.2a.sx$companions %>%
  rename(`Residues type` = T_residues_subpractice,
         `Main crop` = `Measured crop`, 
         `Outcome measured` = out_subindicator)%>%
  mutate(`Companion species`=if_else(is.na(`Companion species`),"-",`Companion species`),
         `Residues type`=str_replace_all(`Residues type`, "\\.{2,}", " + "))%>%
  arrange(`Main crop`,       # 1st: A to Z
          `Residues type`,
          `Outcome measured`,
          desc(`% positive comparisons`))     # 3rd: largest to smallest within each outcome

View(table.2a.sx)

write_csv(table.2a.sx, file.path(path.output, "ken_2A_TableSX_cereals_residues_incorporation.csv"))

#--- Archetype 2A: Table S7 Effect of Intercropping on cereals yield ----
# Cereals, Intercropping, Yield
ic.2a.sx <- practice_detail(arc.long, "2A - Soil restoration", "Intercropping", "Monoculture",
                             food = "Cereals", outcome = "Yield", data = arc.data,
                             extra = "T_intercrop_subpractice")

View(ic.2a.sx$companions)    # cereal measured + species it was intercropped with

table.2a.sx <- ic.2a.sx$companions %>%
  mutate(`Outcome measured` = "Yield")%>%
  mutate(T_intercrop_subpractice=case_when(
    T_intercrop_subpractice%in%c("Intercrop (N fixing and Non N fixing)",
                                 "Green Manure (N fixing In Space) + Relay Intercropping (N fixing and Non N fixing)")
    
    ~"With a nitrogen-fixing species",
    T_intercrop_subpractice=="Intercrop (Non N fixing)"~"Without a nitrogen-fixing species",
    T_intercrop_subpractice=="Push pull"~"Push-pull",
    TRUE~T_intercrop_subpractice))%>%
  rename(`Intercrop type` = T_intercrop_subpractice)%>%
  
  select(1:3,10,4:9)%>%
  mutate(`Companion species`=if_else(is.na(`Companion species`),"-",`Companion species`))%>%
  arrange(`Measured crop`,       # 1st: A to Z
          
          `Intercrop type`,
          `Companion species`,
          desc(`% positive comparisons`))     # 3rd: largest to smallest within each outcome

View(table.2a.sx)

write_csv(table.2a.sx, file.path(path.output, "ken_2A_TableSX_cereals_intercropping.csv"))


#--- Archetype 2A: Table S8 Effect of Organic fertilizer on Pulses and legumes yield ----
# a) Pulses and legumes, Organic fertilizer, Yield
ic.2a.sxa <- practice_detail(arc.long, "2A - Soil restoration", "Organic fertilizer", "No fertilizer applied",
                             food = "Pulses and legumes", outcome = "Yield", data = arc.data,
                             extra = "T_fert_subpractice")

View(ic.2a.sxa$companions)    # cereal measured + species it was intercropped with

table.2a.sxa <- ic.2a.sxa$companions %>%
  rename(`Organic input` = T_fert_subpractice)%>%
  mutate(`Outcome measured` = "Yield")%>%
  select(1:3,10,4:9)%>%
  mutate(`Companion species`=if_else(is.na(`Companion species`),"-",`Companion species`))%>%
  arrange(`Measured crop`,       # 1st: A to Z
          `Organic input`,
          desc(`% positive comparisons`))     # 3rd: largest to smallest within each outcome

View(table.2a.sxa)

# b) Pulses and legumes, Intercropping, Yield
ic.2a.sxb <- practice_detail(arc.long, "2A - Soil restoration", "Intercropping", "Monoculture",
                            food = "Pulses and legumes", outcome = "Yield", data = arc.data,
                            extra = "T_intercrop_subpractice")

View(ic.2a.sxb$companions)    

table.2a.sxb <- ic.2a.sxb$companions %>%
  mutate(T_intercrop_subpractice=case_when(
    T_intercrop_subpractice%in%c("Intercrop (N fixing and Non N fixing)",
                                 "Green Manure (N fixing In Space) + Relay Intercropping (N fixing and Non N fixing)")
    
    ~"With a nitrogen-fixing species",
    T_intercrop_subpractice=="Intercrop (Non N fixing)"~"Without a nitrogen-fixing species",
    T_intercrop_subpractice=="Push pull"~"Push-pull",
    TRUE~T_intercrop_subpractice))%>%
  rename(`Intercrop type` = T_intercrop_subpractice)%>%
  mutate(`Outcome measured` = "Yield")%>%
  select(1:3,10,4:9)%>%
  mutate(`Companion species`=if_else(is.na(`Companion species`),"-",`Companion species`))%>%
  arrange(`Measured crop`,       # 1st: A to Z
          `Intercrop type`,
          desc(`% positive comparisons`))     # 3rd: largest to smallest within each outcome

View(table.2a.sxb)

# c) Pulses and legumes, Residues incorporation, Yield
ic.2a.s8c <- practice_detail(arc.long, "2A - Soil restoration", "Residues incorporation", "Residues removed",
                             food = "Pulses and legumes", outcome = "Yield", data = arc.data,
                             extra = "T_residues_subpractice")

table.2a.s8c <- ic.2a.s8c$companions %>%
  rename(`Type of residue` = T_residues_subpractice) %>%
  mutate(`Outcome measured` = "Yield",
         `Companion species` = if_else(is.na(`Companion species`), "-", `Companion species`)) %>%
  select(`Measured crop`, `Companion species`, `Type of residue`, `Outcome measured`,
         Studies:`% positive comparisons`) %>%
  arrange(`Measured crop`, `Type of residue`, desc(`% positive comparisons`))
View(table.2a.s8c)

# d) Pulses and legumes, Local variety, Yield
ic.2a.s8d <- practice_detail(arc.long, "2A - Soil restoration", "Local variety", "Improved variety",
                             food = "Pulses and legumes", outcome = "Yield", data = arc.data,
                             extra = "T_varietal_crop_variety")

table.2a.s8d <- ic.2a.s8d$companions %>%
  rename(`Local variety` = T_varietal_crop_variety) %>%
  mutate(`Outcome measured` = "Yield") %>%
  select(1:3, 10, 4:9) %>%
  mutate(`Companion species` = if_else(is.na(`Companion species`), "-", `Companion species`)) %>%
  arrange(`Measured crop`, `Local variety`, desc(`% positive comparisons`))
View(table.2a.s8d)

# Table S8: a) to d), each with its own header
table.2a.s8 <- do.call(rbind, Map(with_header,
                                  list(table.2a.sxa, table.2a.sxb, table.2a.s8c, table.2a.s8d),
                                  c("a) Organic fertilizers relative to no fertilizer, by measured crop, companion species and type of organic input.",
                                    "b) Intercropping relative to sole legume crops, by measured crop, companion species and intercrop type.",
                                    "c) Crop residue incorporation relative to residue removal, by measured crop, companion species and type of residue.",
                                    "d) Local relative to improved varieties, by measured crop, companion species and local variety.")))
View(table.2a.s8)

write_csv(table.2a.s8, file.path(path.output, "ken_2A_TableS8_pulses.csv"))

#--- Archetype 2A: Table S9 Effect of Supplemental irrigation on Vegetables yield ----
# Vegetables, Supplemental irrigation, Yield
ic.2a.sx <- practice_detail(arc.long, "2A - Soil restoration", "Supplemental irrigation", "Rainfed agriculture",
                            food = "Vegetables", outcome = "Yield", data = arc.data,
                            extra = "T_irrig_method")
data$T_irrig_method
View(ic.2a.sx$companions)    

table.2a.sx <- ic.2a.sx$companions %>%
  mutate(T_irrig_method=case_when(
    T_irrig_method=="Drip irrigation"~"Supplemental drip irrigation",
    TRUE~T_irrig_method
  ))%>%
  rename(`Irrigation method` = T_irrig_method)%>%
  mutate(`Outcome measured` = "Yield")%>%
  select(1:3,10,4:9)%>%
  mutate(`Companion species`=if_else(is.na(`Companion species`),"-",`Companion species`))%>%
  arrange(`Measured crop`,       # 1st: A to Z
          `Irrigation method`,
          desc(`% positive comparisons`))     # 3rd: largest to smallest within each outcome

View(table.2a.sx)

write_csv(table.2a.sx, file.path(path.output, "ken_2A_TableSX_vegetables_supplementary_irrigation.csv"))
