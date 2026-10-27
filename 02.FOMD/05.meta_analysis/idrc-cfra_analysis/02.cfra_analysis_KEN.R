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
library(ggrepel)

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
strong_es    <- 50            # strong evidence: at least this many comparisons
strong_studies<-3             # ... and from at least this many studies
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
#[1] 6830;7222; 7291; 6972
#[1] 96;101; 104

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
#1  2  Tropics, lowland; semi-arid, with soil/terrain limitations 19.5   9                9           279 
#2 50  Land with severe soil/terrain limitations                  17.2  22               27           570
#3  1  Tropics, lowland; semi-arid, no soil/terrain limitations   10.4   1                1           1
#evidence gaps: none

#===== 2B - Arid micro-gardens | sufficient within high-priority areas: FALSE 
#aez zone                                                       share studies_priority studies_final comparisons_final
#1  2  Tropics, lowland; semi-arid, with soil/terrain limitations 37.2  6                8            126 
#2 53  Desert/Arid climate                                        31.5  0                1            6
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
View(practices.check)

# Tested practices (T vs C) per archetype, food group and practice group
practices <- arc.long %>%
  group_by(#archetype,
    study_id,
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

#--- 4.1 Figure 1: high-priority areas (a) and main agro-ecological zones with study sites (b) ----
map_settings <- list(
  "2A" = list(n_criteria = 4, scope_col = NULL,          legend_title = "Number of criteria met (out of 4)"),
  "2B" = list(n_criteria = 5, scope_col = "ASAL_County",
              scope_label = "Non-ASAL county (out of scope for this scenario)",
              legend_title = "Number of criteria met (out of 5,\nASAL counties only)"))
map_fig_numbers <- c("2A" = 1, "2B" = 1)   # figure number of each archetype in the report
n_label_top <- 3      # besides the Core Priority counties, label the counties with most comparisons
n_label_all <- 8      # label every high-priority county when there are this many or fewer

# plain names for the agroecological zones in the map legend (Table S2 keeps the GAEZ names)
plain_aez <- function(label) {
  out <- sub("^Tropics, (lowland|highland); ([^,]+), ", "\\2 \\1s, ", label)
  out <- sub("^Desert/Arid climate$", "Desert or arid climate", out)
  out <- sub("^Sub-tropics, ([^;]+); ([^,]+), ", "\\2 subtropics (\\1), ", out)
  out <- sub(", with soil/terrain limitations$", " with soil or terrain limitations", out)
  out <- sub(", no soil/terrain limitations$", " without soil or terrain limitations", out)
  out <- gsub("soil/terrain", "soil or terrain", out)
  paste0(toupper(substr(out, 1, 1)), substr(out, 2, nchar(out)))
}
gaez.lookup.plain <- mutate(gaez.lookup, label = plain_aez(label))

legend_below <- theme(legend.position = "bottom", legend.direction = "vertical", legend.box = "vertical",
                      legend.justification = c(0, 1), legend.box.just = "left", legend.location = "plot",
                      legend.key.spacing.y = unit(2, "pt"), plot.margin = margin(2, 2, 2, 2))

for (i in seq_len(nrow(archetypes))) {
  code <- archetypes$code[i]
  set  <- map_settings[[code]]
  arc  <- st_read(file.path(path.archetypes, country_code, archetypes$file[i]), quiet = TRUE)
  pr   <- arc[with(arc, eval(str2lang(archetypes$rule[i]))) %in% TRUE, ]
  
  # county labels: Core Priority counties and the counties with most comparisons
  by_county <- county_table(arc, archetypes$rule[i], selection[[archetypes$archetype[i]]],
                            pool.long, points.pool) %>% filter(NAME_1 != "Total")
  labelled  <- if (nrow(pr) <= n_label_all) pr$NAME_1 else
    union(pr$NAME_1[pr$Criteria_Met_Count == set$n_criteria],
          head(by_county$NAME_1[order(-by_county$Comparisons)], n_label_top))
  lab_pts   <- suppressWarnings(st_point_on_surface(st_transform(pr[pr$NAME_1 %in% labelled, ], 3857)))
  lab_xy    <- st_coordinates(st_transform(lab_pts, 4326))
  lab_df    <- data.frame(NAME_1 = lab_pts$NAME_1, X = lab_xy[, 1], Y = lab_xy[, 2])
  county_labels <- geom_label_repel(data = lab_df, aes(x = X, y = Y, label = NAME_1), size = 2,
                                    fontface = "bold", colour = "grey10",
                                    fill = alpha("white", 0.85), label.size = 0, label.padding = unit(0.08, "lines"),
                                    min.segment.length = 0, segment.colour = "grey30", segment.size = 0.25,
                                    box.padding = 0.25, seed = 1, inherit.aes = FALSE)
  
  # a) high-priority areas (normal colours, black outline, county labels)
  map_a <- plot_archetype(arc, n_criteria = set$n_criteria, scope_col = set$scope_col,
                          scope_label = if (is.null(set$scope_label)) "Out of scope" else set$scope_label,
                          legend_title = set$legend_title) +
    geom_sf(data = st_union(pr), aes(linetype = "priority"), fill = NA, colour = "grey10", linewidth = 0.6) +
    scale_linetype_manual(values = c(priority = "solid"), labels = "High-priority areas", name = NULL) +
    county_labels +
    guides(fill = guide_legend(order = 1), linetype = guide_legend(order = 2)) +
    labs(title = "a) Criteria met by county", x = NULL, y = NULL) +
    theme(plot.title = element_text(face = "bold", size = 9),
          legend.title = element_text(size = 7, face = "bold"), legend.text = element_text(size = 6.5),
          legend.key.size = unit(0.35, "cm"))
  
  # b) main agro-ecological zones and sites of the comparisons used (within and added)
  points_used <- points.pool %>%
    inner_join(filter(arc.ids, archetype == archetypes$archetype[i]), by = "effect_size_id") %>%
    left_join(distinct(pool.long, effect_size_id, study_id, country), by = "effect_size_id") %>%
    # multi-country studies (e.g. "Ethiopia..Ghana"): keep the project country
    mutate(country = coalesce(str_extract(country, paste(c(country_name, neighbour_countries), collapse = "|")), country))
  added <- any(points_used$selection != "High-priority areas")      # comparisons added from outside?
  map_b <- plot_aez_evidence(arc, archetypes$rule[i], aez.rasters[[1]], gaez.lookup.plain, points_used,
                             aez_rasters = aez.rasters, min_share = min_share_aez) +
    geom_sf(data = st_union(pr), aes(linetype = "priority"), fill = NA, colour = "grey10",
            linewidth = 0.6, inherit.aes = FALSE) +
    scale_linetype_manual(values = c(priority = "solid"), labels = "High-priority areas", name = NULL) +
    guides(linetype = guide_legend(order = 2)) +
    { if (!added) guides(shape = "none") } +        # one type of site only: no "Location of comparisons" legend
    labs(title = "b) Agroecological zones and evidence", x = NULL, y = NULL) +
    theme(plot.title = element_text(face = "bold", size = 9))
  
  # draw the high-priority border (added last, for the legend) below the study sites
  pt_layer <- which(vapply(map_b$layers, function(l) "origin" %in% names(l$data), logical(1)))[1]
  n_lay    <- length(map_b$layers)
  map_b$layers <- append(map_b$layers[-n_lay], map_b$layers[n_lay], after = pt_layer - 1)
  
  map <- patchwork::wrap_plots(map_a + legend_below, map_b + legend_below, nrow = 1)
  print(map)
  ggsave(file.path(path.output, paste0(country_code, "_", code, "_Fig", map_fig_numbers[[code]], ".png")),
         map, width = 6, height = 6, dpi = 300, bg = "white")
}

#--- 4.2. Table S1: studies and comparisons per high-priority county, one per archetype ----
county_table_numbers <- c("2A" = 1, "2B" = 1)   # supplementary table number of each archetype

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

#--- 4.3. Table S2: agro-ecological zones and evidence per zone, one per archetype ----
aez_table_numbers <- c("2A" = 2, "2B" = 2)   # supplementary table number of each archetype

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
#--- 4.5. Figure S1. Year of publication of the studies included in the analysis (supplementary) ----
figS1_years_numbers <- c("2A" = 1, "2B" = 1)   # supplementary figure number of each archetype

for (i in seq_len(nrow(archetypes))) {
  code <- archetypes$code[i]
  
  fig_years <- plot_years(filter(arc.long, archetype == archetypes$archetype[i]))
  print(attr(fig_years, "summary"))   # numbers for the text
  print(fig_years)
  
  ggsave(file.path(path.output, paste0(country_code, "_", code, "_FigS", figS1_years_numbers[[code]], "_years.png")),
         fig_years, width = 6.3, height = 2.5, dpi = 300, bg = "white")
}


#--- 4.4. Figure S2 Evidence distribution by food group, practice and outcome, one figure per archetype ----
figS2_distribution_numbers<- c("2A" = 2, "2B" = 2)   # figure number of each archetype in the report

for (i in seq_len(nrow(archetypes))) {
  code <- archetypes$code[i]
  
  fig_dist <- plot_distribution(filter(arc.long, archetype == archetypes$archetype[i]))
  print(fig_dist)
  
  ggsave(file.path(path.output, paste0(country_code, "_", code, "_FigS", figS2_distribution_numbers[[code]], ".png")),
         fig_dist, width = 7.5, height = 0.17 * attr(fig_dist, "n_rows") + 0.6, dpi = 300, bg = "white")
}


#==========================================================
#--- 5. Evidence synthesis on the effect of AE/RA practices ----
#==========================================================
#--- 5.1. Figure 2: Strong evidence on the effects of AE/RA practices on eight dimensions of farm performance  ----
source(file.path(path.meta.analysis, "cfra_fun/fun_plot_count_grouped.R"))

legend.grid <- grid_legend_small(strong_es = strong_es, strong_studies = strong_studies,
                                 cut_positive = cut_positive,
                                 cut_negative = cut_negative, text_size = 7)
parts <- list(all = c("Cereals", "Pulses and legumes", "Vegetables", "Roots and tubers", "Nuts and seeds", "Fruits"))
row_in <- 0.26                                   # inches per practice row

# figure number of each archetype in the report (only for these heat maps)
fig_numbers <- c("2A" = 2, "2B" = 2)

for (i in seq_len(nrow(archetypes))) {
  arc_name <- archetypes$archetype[i]
  arc_code <- archetypes$code[i]
  for (part in names(parts)) {
    groups <- parts[[part]]
    cc <- cells %>% filter(food_group %in% groups)
    if (!any(cc$archetype == arc_name)) next
    if (!any(cc$archetype == arc_name & cc$effect_sizes >= strong_es & cc$k >= strong_studies)) next   # no strong results (e.g. 2B)
    
    p <- plot_votes_grouped(cc, arc_name, min_es_cell = min_es_cell, strong_es = strong_es,
                            strong_studies = strong_studies, rows = "strong",
                            show_no_data = FALSE, heading_step = 0.5,
                            cut_positive = cut_positive, cut_negative = cut_negative, text_size = 7)
    
    # column group headers above the dimensions (same order as outcome_order in the function)
    groups_hdr <- tibble(lab = c("Farm economy", "Farm functioning", "Environment"),
                         x0  = c(0.55, 3.55, 6.55), x1 = c(3.45, 6.45, 8.45))
    hdr <- ggplot(groups_hdr) +
      geom_segment(aes(x = x0, xend = x1, y = 0, yend = 0), colour = "#5A5A5A", linewidth = 0.4) +
      geom_text(aes(x = (x0 + x1) / 2, y = 0.45, label = lab), size = 7 * 0.36, fontface = "bold", colour = "#3A3A3A") +
      scale_x_continuous(limits = c(0.5, 8.5), expand = c(0, 0)) +
      scale_y_continuous(limits = c(-0.2, 0.9)) +
      theme_void()
    
    # legend below the figure, centred
    legend.row <- wrap_plots(plot_spacer(), legend.grid, plot_spacer(), widths = c(0.05, 3.9, 0.05))
    fig <- wrap_plots(hdr, p, legend.row, ncol = 1, heights = c(0.6, attr(p, "n_rows"), 2.6))
    fig_h <- row_in * (attr(p, "n_rows") + 3.2) + 0.4
    
    # file name: <country>_<archetype>_fig<number><part>.png, e.g. ken_2A_Fig2.png
    fig_name <- paste0(country_code, "_", arc_code, "_Fig", fig_numbers[[arc_code]],
                       if (length(parts) > 1) part else "", ".png")
    
    ggsave(file.path(path.output, fig_name), fig, width = 8, height = fig_h, dpi = 300, bg = "white")
    ggsave(file.path(path.output, sub("[.]png$", ".pdf", fig_name)), fig, width = 8, height = fig_h,
           device = cairo_pdf, bg = "white")
  }
}
path.output
file.exists(file.path(path.output, "ken_2A_Fig2.png"))

#--- 5.2. Figure S3: Limited evidence on the effects of AE/RA practices on eight dimensions of farm performance  ----

# figure number of each archetype in the report (only for these heat maps)
row_in <- 0.26                                   # inches per practice row

fig_numbers <- c("2A" = 3, "2B" = 3)

for (i in seq_len(nrow(archetypes))) {
  arc_name <- archetypes$archetype[i]
  arc_code <- archetypes$code[i]
  for (part in names(parts)) {
    groups <- parts[[part]]
    cc <- cells %>% filter(food_group %in% groups)
    if (!any(cc$archetype == arc_name)) next      # no data at all for this archetype
    
    p <- plot_votes_grouped(cc, arc_name, min_es_cell = min_es_cell, strong_es = strong_es,
                            strong_studies = strong_studies, rows = "all",
                            show_no_data = FALSE, heading_step = 0.5,
                            cut_positive = cut_positive, cut_negative = cut_negative, text_size = 7)
    
    # column group headers above the dimensions (same order as outcome_order in the function)
    groups_hdr <- tibble(lab = c("Farm economy", "Farm functioning", "Environment"),
                         x0  = c(0.55, 3.55, 6.55), x1 = c(3.45, 6.45, 8.45))
    hdr <- ggplot(groups_hdr) +
      geom_segment(aes(x = x0, xend = x1, y = 0, yend = 0), colour = "#5A5A5A", linewidth = 0.4) +
      geom_text(aes(x = (x0 + x1) / 2, y = 0.45, label = lab), size = 7 * 0.36, fontface = "bold", colour = "#3A3A3A") +
      scale_x_continuous(limits = c(0.5, 8.5), expand = c(0, 0)) +
      scale_y_continuous(limits = c(-0.2, 0.9)) +
      theme_void()
    
    # legend below the figure, centred
    legend.row <- wrap_plots(plot_spacer(), legend.grid, plot_spacer(), widths = c(0.05, 3.9, 0.05))
    fig <- wrap_plots(hdr, p, legend.row, ncol = 1, heights = c(0.6, attr(p, "n_rows"), 2.6))
    fig_h <- row_in * (attr(p, "n_rows") + 3.2) + 0.4
    
    # file name: <country>_<archetype>_fig<number><part>.png, e.g. ken_2A_Fig2.png
    fig_name <- paste0(country_code, "_", arc_code, "_FigS", fig_numbers[[arc_code]],
                       if (length(parts) > 1) part else "", ".png")
    
    ggsave(file.path(path.output, fig_name), fig, width = 8, height = fig_h, dpi = 300, bg = "white")
    ggsave(file.path(path.output, sub("[.]png$", ".pdf", fig_name)), fig, width = 8, height = fig_h,
           device = cairo_pdf, bg = "white")
  }
}
path.output

#==========================================================
#--- 6. Evidence synthesis interpretation in detail ----
#==========================================================
source(file.path(path.meta.analysis, "cfra_fun/fun_practice_detail_analysis.R"))
#----------------------------------------------------------------------
#--- 6.1. Archetype 2A: Evidence synthesis interpretation in detail ----
#----------------------------------------------------------------------
#--- Archetype 2A: Table 2A.S3 Effect of Organic mulch on cereals productivity, soil health, inputs efficiency ----
# a) Cereals, Organic mulch, Productivity
ic.2a.s3a <- practice_detail(arc.long, "2A - Soil restoration", "Organic mulch", "No residues or mulch",
                             food = "Cereals", outcome = "Productivity", data = arc.data,
                             extra = c("T_residues_subpractice","out_subindicator"))

#View(ic.2a.s3a$companions)    # cereal measured + species it was intercropped with

table.2a.s3a <- ic.2a.s3a$companions %>%
  rename(`Organic mulch` = T_residues_subpractice,
         `Outcome measured` = out_subindicator)%>%
  mutate(`Companion species`=if_else(is.na(`Companion species`),"-",`Companion species`))%>%
  arrange(`Measured crop`,       # 1st: A to Z
          `Organic mulch`,
          `Outcome measured`,
          desc(Comparisons),
          desc(`% positive comparisons`))     # 3rd: largest to smallest within each outcome

View(table.2a.s3a)

# b) Cereals, Organic mulch, Soil health
ic.2a.s3b <- practice_detail(arc.long, "2A - Soil restoration", "Organic mulch", "No residues or mulch",
                             food = "Cereals", outcome = "Soil health", data = arc.data,
                             extra = c("T_residues_subpractice", "out_subindicator"))

View(ic.2a.s3b$companions)    # cereal measured + species it was intercropped with

table.2a.s3b <- ic.2a.s3b$companions %>%
  rename(`Organic mulch` = T_residues_subpractice,
         `Main crop` = `Measured crop`, 
         `Outcome measured` = out_subindicator)%>%
  mutate(`Companion species`=if_else(is.na(`Companion species`),"-",`Companion species`))%>%
  arrange(`Main crop`,       # 1st: A to Z
          `Organic mulch`,
          `Outcome measured`,
          desc(Comparisons),
          desc(`% positive comparisons`))     # 3rd: largest to smallest within each outcome

View(table.2a.s3b)

# c) Cereals, Organic mulch, Inputs efficiency 
ic.2a.s3c <- practice_detail(arc.long, "2A - Soil restoration", "Organic mulch", "No residues or mulch",
                             food = "Cereals", outcome = "Inputs efficiency", data = arc.data,
                             extra = c("T_residues_subpractice", "out_subindicator"))

View(ic.2a.s3c$companions)    # cereal measured + species it was intercropped with

table.2a.s3c <- ic.2a.s3c$companions %>%
  rename(`Organic mulch` = T_residues_subpractice,
         `Outcome measured` = out_subindicator,
         `Main crop` = `Measured crop`)%>%
  mutate(`Companion species`=if_else(is.na(`Companion species`),"-",`Companion species`))%>%
  
  arrange(`Main crop`,
          `Organic mulch`,
          `Outcome measured`,
          desc(Comparisons),
          desc(`% positive comparisons`))     # 3rd: largest to smallest within each outcome

View(table.2a.s3c)

table.2a.s3 <- do.call(rbind, Map(with_header,
                                  list(table.2a.s3a, table.2a.s3b, table.2a.s3c),
                                  c("a) Cereal productivity, by measured crop, companion species, type of organic mulch, and outcome measured.",
                                    "b) Soil health in cereal systems, by main crop, companion species, type of organic mulch, and outcome measured.",
                                    "c) Inputs efficiency in cereal systems, by main crop, companion species, type of organic mulch, and outcome measured.")))
View(table.2a.s3)

write_csv(table.2a.s3, file.path(path.output, "ken_2A_TableS3_cereals_organic_mulch.csv"))

#--- Archetype 2A: Table 2A.S4 Effect of Residue incorporation on cereals productivity and soil health ----
# a) Cereals, Residues incorporation, Productivity
ic.2a.s4a <- practice_detail(arc.long, "2A - Soil restoration", "Residue incorporation", "No residues or mulch",
                             food = "Cereals", outcome = "Productivity", data = arc.data,
                             extra = c("T_residues_subpractice", "out_subindicator"))

#View(ic.2a.s4a$companions)    # cereal measured + species it was intercropped with

table.2a.s4a <- ic.2a.s4a$companions %>%
  rename(`Residues type` = T_residues_subpractice,
         `Outcome measured` = out_subindicator)%>%
  mutate(`Companion species`=if_else(is.na(`Companion species`),"-",`Companion species`),
         `Residues type`=str_replace_all(`Residues type`, "\\.{2,}", " + "))%>%
  arrange(`Measured crop`,       # 1st: A to Z
          `Residues type`,
          `Outcome measured`,
          desc(Comparisons),
          desc(`% positive comparisons`))     # 3rd: largest to smallest within each outcome

View(table.2a.s4a)

# b) Cereals, Residues incorporation, Soil health
ic.2a.s4b <- practice_detail(arc.long, "2A - Soil restoration", "Residue incorporation", "No residues or mulch",
                            food = "Cereals", outcome = "Soil health", data = arc.data,
                            extra = c("T_residues_subpractice", "out_subindicator"))
View(ic.2a.s4b$companions)    # cereal measured + species it was intercropped with

table.2a.s4b <- ic.2a.s4b$companions %>%
  rename(`Residues type` = T_residues_subpractice,
         `Main crop` = `Measured crop`, 
         `Outcome measured` = out_subindicator)%>%
  mutate(`Companion species`=if_else(is.na(`Companion species`),"-",`Companion species`),
         `Residues type`=str_replace_all(`Residues type`, "\\.{2,}", " + "))%>%
  arrange(`Main crop`,       # 1st: A to Z
          `Residues type`,
          `Outcome measured`,
          desc(Comparisons),
          desc(`% positive comparisons`))     # 3rd: largest to smallest within each outcome

View(table.2a.s4b)

table.2a.s4 <- do.call(rbind, Map(with_header,
                                  list(table.2a.s4a, table.2a.s4b),
                                  c("a) Cereal productivity, by measured crop, companion species, type of residue incorporated, and outcome measured.",
                                    "b) Soil health in cereal systems, by main crop, companion species, type of residue incorporated, and outcome measured."
                                    )))
View(table.2a.s4)

write_csv(table.2a.s4, file.path(path.output, "ken_2A_TableS4_cereals_residues_incorporation.csv"))

#--- Archetype 2A: Table 2A.S5 Effect of Organic fertilizer on cereals productivity and soil health ----
# a) Cereals, Organic fertilizer, Productivity
ic.2a.s5a <- practice_detail(arc.long, "2A - Soil restoration", "Organic fertilizer", "No fertilizer applied",
                             food = "Cereals", outcome = "Productivity", data = arc.data,
                             extra = c("T_fert_subpractice","out_subindicator"))

View(ic.2a.s5a$companions)    # cereal measured + species it was intercropped with

table.2a.s5a <- ic.2a.s5a$companions %>%
  rename(`Organic input` = T_fert_subpractice,
         `Outcome measured` = out_subindicator)%>%
 
  mutate(`Companion species`=if_else(is.na(`Companion species`),"-",`Companion species`))%>%
  arrange(`Measured crop`,       # 1st: A to Z
          `Organic input`,
          `Outcome measured`,
          desc(Comparisons),
          desc(`% positive comparisons`))     # 3rd: largest to smallest within each outcome

View(table.2a.s5a)

# b) Cereals, Organic fertilizer, Soil health
ic.2a.s5b <- practice_detail(arc.long, "2A - Soil restoration", "Organic fertilizer", "No fertilizer applied",
                             food = "Cereals", outcome = "Soil health", data = arc.data,
                             extra = c("T_fert_subpractice", "out_subindicator"))

View(ic.2a.s5b$companions)    # cereal measured + species it was intercropped with

table.2a.s5b <- ic.2a.s5b$companions %>%
  rename(`Organic input` = T_fert_subpractice,
         `Main crop` = `Measured crop`, 
         `Outcome measured` = out_subindicator)%>%
  mutate(`Companion species`=if_else(is.na(`Companion species`),"-",`Companion species`))%>%
  arrange(`Main crop`,       # 1st: A to Z
          `Organic input`,
          `Outcome measured`,
          desc(Comparisons),
          desc(`% positive comparisons`))     # 3rd: largest to smallest within each outcome

View(table.2a.s5b)

table.2a.s5 <- do.call(rbind, Map(with_header,
                                  list(table.2a.s5a, table.2a.s5b),
                                  c("a) Cereal productivity, by measured crop, companion species, type of organic input, and outcome measured.",
                                    "b) Soil health in cereal systems, by main crop, companion species, type of organic input, and outcome measured."
                                    )))
View(table.2a.s5)

write_csv(table.2a.s5, file.path(path.output, "ken_2A_TableS5_cereals_organic_fertilizer.csv"))

#--- Archetype 2A: Table 2A.S6 Effect of Mixed fertilizer on cereals Productivity, and soil health ----
# a) Cereals, Mixed fertilizer, Productivity
ic.2a.s6a <- practice_detail(arc.long, "2A - Soil restoration", "Mixed fertilizer", "No fertilizer applied",
                             food = "Cereals", outcome = "Productivity", data = arc.data,
                             extra = c("T_fert_subpractice", "out_subindicator"))

View(ic.2a.s6a$companions)    # cereal measured + species it was intercropped with

table.2a.s6a <- ic.2a.s6a$companions %>%
  rename(`Mixed input` = T_fert_subpractice,
         `Outcome measured` = out_subindicator)%>%
  
  mutate(`Companion species`=if_else(is.na(`Companion species`),"-",`Companion species`),
         `Mixed input`=str_replace_all(`Mixed input`, "\\.{2,}", " + "))%>%
  arrange(`Measured crop`,       # 1st: A to Z
          `Mixed input`,
          `Outcome measured`,
          desc(Comparisons),
          desc(`% positive comparisons`))     # 3rd: largest to smallest within each outcome

View(table.2a.s6a)

# b) Cereals, Mixed fertilizer, Soil health
ic.2a.s6b <- practice_detail(arc.long, "2A - Soil restoration", "Mixed fertilizer", "No fertilizer applied",
                             food = "Cereals", outcome = "Soil health", data = arc.data,
                             extra = c("T_fert_subpractice", "out_subindicator"))

View(ic.2a.s6b$companions)    # cereal measured + species it was intercropped with

table.2a.s6b <- ic.2a.s6b$companions %>%
  rename(`Mixed input` = T_fert_subpractice,
         `Main crop` = `Measured crop`, 
         `Outcome measured` = out_subindicator)%>%
  mutate(`Companion species`=if_else(is.na(`Companion species`),"-",`Companion species`),
         `Mixed input`=str_replace_all(`Mixed input`, "\\.{2,}", " + "))%>%
  arrange(`Main crop`,       # 1st: A to Z
          `Mixed input`,
          `Outcome measured`,
          desc(Comparisons),
          desc(`% positive comparisons`))     # 3rd: largest to smallest within each outcome

View(table.2a.s6b)

table.2a.s6 <- do.call(rbind, Map(with_header,
                                  list(table.2a.s6a, table.2a.s6b),
                                  c("a) Cereal productivity, by measured crop, companion species, type of mixed input, and outcome measured.",
                                    "b) Soil health in cereal systems, by main crop, companion species, type of mixed input, and outcome measured."
                                    )))
View(table.2a.s6)

write_csv(table.2a.s6, file.path(path.output, "ken_2A_TableS6_cereals_mixed_fertilizer.csv"))

#--- Archetype 2A: Table 2A.S7 Effect of Intercropping on cereals productivity, resilience to pests ----
# a) Cereals, Intercropping, Productivity
arc.long.2a.s7a <- arc.long %>%
  mutate(
    # Desmodium common names and species -> Desmodium spp.; Crotalaria species -> Crotalaria spp.
    T_crop_tree_diversity = str_replace_all(T_crop_tree_diversity,
                                            regex("\\b(Silverleaf|Greenleaf|Tick Clover sp)\\b", ignore_case = TRUE),
                                            "Desmodium spp."),
    T_crop_tree_diversity = str_replace_all(T_crop_tree_diversity,
                                            "\\b(Desmodium|Crotalaria) [a-z]+\\.?", "\\1 spp."),
    T_intercrop_subpractice = case_when(
      str_detect(coalesce(T_crop_tree_diversity, ""), "Desmodium")      ~ "Push-pull",
      str_detect(coalesce(T_intercrop_subpractice, ""), "Push pull")    ~ "Push-pull",
      str_detect(coalesce(T_intercrop_subpractice, ""), "\\(N fixing")  ~ "With a nitrogen-fixing species",
      str_detect(coalesce(T_intercrop_subpractice, ""), "Non N fixing") ~ "Without a nitrogen-fixing species",
      TRUE                                                               ~ T_intercrop_subpractice))
  
ic.2a.s7a <-  practice_detail(arc.long.2a.s7a, "2A - Soil restoration", "Intercropping", "Monoculture",
                             food = "Cereals", outcome = "Productivity", data = arc.data,
                             extra = c("T_intercrop_subpractice","out_subindicator"))


#View(ic.2a.s7a$companions)    # cereal measured + species it was intercropped with

table.2a.s7a <- ic.2a.s7a$companions %>%

  rename(`Intercrop type` = T_intercrop_subpractice,
         `Outcome measured` = out_subindicator)%>%
  mutate(`Companion species`=if_else(is.na(`Companion species`),"-",`Companion species`))%>%
  arrange(`Measured crop`,       # 1st: A to Z
          `Intercrop type`,
          `Companion species`,
          `Outcome measured`,
          desc(Comparisons),
          desc(`% positive comparisons`))     # 3rd: largest to smallest within each outcome
View(table.2a.s7a)

# b) Cereals, Intercropping, Resilience to pests
# pest rows: the pest in its own column, the cereal in T_product_simple
cereals <- c("Maize", "Sorghum", "Finger Millet", "Pearl Millet", "Baby Corn", "Rice", "Wheat", "Teff", "Barley")

arc.long.2a.s7b <- arc.long.2a.s7a %>%
  filter(outcome_group == "Resilience to pests") %>%
  mutate(Pest = case_when(str_detect(T_product, "Striga")              ~ "Weeds (Striga)",
                          str_detect(T_product, "Stemborer")           ~ "Insect pests (stem borers)",
                          str_detect(T_product, "Thrips|Thysanoptera") ~ "Insect pests (thrips)",
                          TRUE                                         ~ coalesce(bio_func_group, T_product)),
         # "Maize..Lepidoptera" -> "Maize"; "Lamiales" -> the cereal(s) in the intercrop
         T_product_simple = if_else(str_detect(T_product_simple, fixed("..")),
                                    str_remove(T_product_simple, "\\.\\..*$"),
                                    vapply(str_split(coalesce(T_crop_tree_diversity, ""), "[-/]"),
                                           function(s) paste(intersect(str_trim(s), cereals), collapse = " + "),
                                           character(1))))

ic.2a.s7b <- practice_detail(arc.long.2a.s7b, "2A - Soil restoration", "Intercropping", "Monoculture",
                             food = "Cereals", outcome = "Resilience to pests", data = arc.data,
                             extra = c("T_intercrop_subpractice", "Pest"))

#View(ic.2a.s7b$companions)

table.2a.s7b <- ic.2a.s7b$companions %>%
  mutate(`Outcome measured` = "Resilience to ") %>%
  rename(`Intercrop type` = T_intercrop_subpractice,
         `Main crop` = `Measured crop`,
         `Pest or weed` = Pest) %>%
  mutate(`Outcome measured` = paste0(`Outcome measured`, str_replace(`Pest or weed`, "^\\w", tolower))) %>%
  select(`Main crop`, `Companion species`, `Intercrop type`,
         `Outcome measured`, everything(), -`Pest or weed`) %>%
  mutate(`Companion species` = if_else(is.na(`Companion species`), "-", `Companion species`)) %>%
  arrange(`Main crop`,# `Pest or weed`, 
          `Intercrop type`, `Companion species`,
          desc(Comparisons),
          desc(`% positive comparisons`))
View(table.2a.s7b)

table.2a.s7 <- do.call(rbind, Map(with_header,
                                  list(table.2a.s7a, table.2a.s7b),
                                  c("a) Cereal productivity, by measured crop, companion species, intercrop type, and outcome measured.",
                                    "b) Resilience to pests and weeds in cereal intercrops, by main crop, companion species, intercrop type, and outcome measured."
                                  )))
View(table.2a.s7)

write_csv(table.2a.s7, file.path(path.output, "ken_2A_TableS7_cereals_intercropping.csv"))


#--- Archetype 2A: Table 2A.S8 Effect of Biochar amendment, Agroforestry, crop rotation, and Reduce tillage on cereals Productivity ----
# a) Cereals, Biochar amendment, Productivity
ic.2a.s8a <- practice_detail(arc.long, "2A - Soil restoration", "Biochar amendment", "No fertilizer applied",
                             food = "Cereals", outcome = "Productivity", data = arc.data,
                             extra = c("T_fert_subpractice", "out_subindicator"))

View(ic.2a.s8a$companions)    # cereal measured + species it was intercropped with

table.2a.s8a <- ic.2a.s8a$companions %>%
  rename(`Biochar amendment` = T_fert_subpractice,
         `Outcome measured` = out_subindicator)%>%
  mutate(`Companion species`=if_else(is.na(`Companion species`),"-",`Companion species`))%>%
  arrange(`Measured crop`,       # 1st: A to Z
          `Biochar amendment`,
          `Outcome measured`,
          desc(Comparisons),
          desc(`% positive comparisons`))     # 3rd: largest to smallest within each outcome

View(table.2a.s8a)

# b) Cereals, Agroforestry, Productivity
ic.2a.s8b <- practice_detail(arc.long, "2A - Soil restoration", "Agroforestry", "Monoculture",
                             food = "Cereals", outcome = "Productivity", data = arc.data,
                             extra = c("T_agrof_subpractice", "out_subindicator"))

View(ic.2a.s8b$companions)    # cereal measured + species it was intercropped with

table.2a.s8b <- ic.2a.s8b$companions %>%
  rename(`Agroforestry type` = T_agrof_subpractice,
         `Outcome measured` = out_subindicator)%>%
  mutate(`Companion species`=if_else(is.na(`Companion species`),"-",`Companion species`))%>%
  arrange(`Measured crop`,       # 1st: A to Z
          `Agroforestry type`,
          `Outcome measured`,
          desc(Comparisons),
          desc(`% positive comparisons`))     # 3rd: largest to smallest within each outcome

View(table.2a.s8b)

# c) Cereals, Crop rotation, Productivity
ic.2a.s8c <- practice_detail(arc.long, "2A - Soil restoration", "Crop rotation", "Monoculture",
                             food = "Cereals", outcome = "Productivity", data = arc.data,
                             extra = c("T_crop_seq_subpractice", "out_subindicator"))

View(ic.2a.s8c$companions)    # cereal measured + species it was intercropped with

table.2a.s8c <- ic.2a.s8c$companions %>%
  rename(`Crop rottation type` = T_crop_seq_subpractice,
         `Outcome measured` = out_subindicator)%>%
  mutate(`Companion species`=if_else(is.na(`Companion species`),"-",`Companion species`))%>%
  arrange(`Measured crop`,       # 1st: A to Z
          `Crop rottation type`,
          `Outcome measured`,
          desc(Comparisons),
          desc(`% positive comparisons`))     # 3rd: largest to smallest within each outcome

View(table.2a.s8c)

# d) Cereals, Crop rotation, Productivity
ic.2a.s8d <- practice_detail(arc.long, "2A - Soil restoration", "Reduced tillage", "Conventional tillage",
                             food = "Cereals", outcome = "Productivity", data = arc.data,
                             extra = c("T_tillage_subpractice", "out_subindicator"))

View(ic.2a.s8d$companions)    # cereal measured + species it was intercropped with

table.2a.s8d <- ic.2a.s8d$companions %>%
  rename(`Tillage practice` = T_tillage_subpractice,
         `Outcome measured` = out_subindicator)%>%
  mutate(`Companion species`=if_else(is.na(`Companion species`),"-",`Companion species`))%>%
  arrange(`Measured crop`,       # 1st: A to Z
          `Tillage practice`,
          `Outcome measured`,
          desc(Comparisons),
          desc(`% positive comparisons`))     # 3rd: largest to smallest within each outcome

View(table.2a.s8d)

# Table 2A.S8: a) to c), each with its own header
table.2a.s8 <- do.call(rbind, Map(with_header,
                                  list(table.2a.s8a, table.2a.s8b, table.2a.s8c,table.2a.s8d),
                                  c(
                                    "a) Biochar amendment compared with no fertilizer, by measured crop, companion species, type of biochar amendment, and outcome measured.",
                                    "b) Agroforestry compared with monoculture, by measured crop, companion species, agroforestry type, and outcome measured.",
                                    "c) Crop rotation compared with monoculture, by measured crop, companion species, crop rotation type, and outcome measured.",
                                    "d) Reduced tillage compared with conventional tillage, by measured crop, companion species, tillage practice, and outcome measured.")))

View(table.2a.s8)

write_csv(table.2a.s8, file.path(path.output, "ken_2A_TableS8_cereals_neutral_results.csv"))


#--- Archetype 2A: Table 2A.S9 Effect of Intercropping, Residues incorporation and Local varieties on Pulses and legumes productivity ----
# a) Pulses and legumes, Intercropping, Productivity
arc.long.2a.s9a <- arc.long %>%
  mutate(
    # Desmodium common names and species -> Desmodium spp.; Crotalaria species -> Crotalaria spp.
    T_crop_tree_diversity = str_replace_all(T_crop_tree_diversity,
                                            regex("\\b(Silverleaf|Greenleaf|Tick Clover sp)\\b", ignore_case = TRUE),
                                            "Desmodium spp."),
    T_crop_tree_diversity = str_replace_all(T_crop_tree_diversity,
                                            "\\b(Desmodium|Crotalaria) [a-z]+\\.?", "\\1 spp."),
    T_intercrop_subpractice = case_when(
      str_detect(coalesce(T_crop_tree_diversity, ""), "Desmodium")      ~ "Push-pull",
      str_detect(coalesce(T_intercrop_subpractice, ""), "Push pull")    ~ "Push-pull",
      str_detect(coalesce(T_intercrop_subpractice, ""), "\\(N fixing")  ~ "With a nitrogen-fixing species",
      str_detect(coalesce(T_intercrop_subpractice, ""), "Non N fixing") ~ "Without a nitrogen-fixing species",
      TRUE                                                               ~ T_intercrop_subpractice))

ic.2a.s9a <-  practice_detail(arc.long.2a.s9a, "2A - Soil restoration", "Intercropping", "Monoculture",
                              food = "Pulses and legumes", outcome = "Productivity", data = arc.data,
                              extra = c("T_intercrop_subpractice","out_subindicator"))


View(ic.2a.s9a$companions)    # cereal measured + species it was intercropped with

table.2a.s9a <- ic.2a.s9a$companions %>%
  
  rename(`Intercrop type` = T_intercrop_subpractice,
         `Outcome measured` = out_subindicator)%>%
  mutate(`Companion species`=if_else(is.na(`Companion species`),"-",`Companion species`))%>%
  
  mutate(
    `Companion species`=case_when(
      `Measured crop`=="Potato..Common Bean"~"Potato",
      `Measured crop`=="Potato..Lablab purpureus"~"Potato",
      TRUE~`Companion species`),
    `Measured crop`=case_when(
      `Measured crop`=="Potato..Common Bean"~"Common Bean",
      `Measured crop`=="Potato..Lablab purpureus"~"Lablab purpureus",
      TRUE~`Measured crop`)
    )%>%
  arrange(`Measured crop`,       # 1st: A to Z
          `Intercrop type`,
          `Companion species`,
          `Outcome measured`,
          desc(Comparisons),
          desc(`% positive comparisons`))     # 3rd: largest to smallest within each outcome
View(table.2a.s9a)

# b) Pulses and legumes, Residue incorporation, Productivity
ic.2a.s9b <- practice_detail(arc.long, "2A - Soil restoration", "Residue incorporation", "No residues or mulch",
                             food = "Pulses and legumes", outcome = "Productivity", data = arc.data,
                             extra = c("T_residues_subpractice","out_subindicator"))

table.2a.s9b <- ic.2a.s9b$companions %>%
  rename(`Type of residue` = T_residues_subpractice,
         `Outcome measured` = out_subindicator)%>%
  
  mutate(`Companion species` = if_else(is.na(`Companion species`), "-", `Companion species`)) %>%
  select(`Measured crop`, `Companion species`, `Type of residue`, `Outcome measured`,
         Studies:`% positive comparisons`) %>%
  arrange(`Measured crop`, `Type of residue`,
          `Outcome measured`,
          desc(Comparisons),
          desc(`% positive comparisons`))
View(table.2a.s9b)

# c) Pulses and legumes, Local variety, Productivity
ic.2a.s9c <- practice_detail(arc.long, "2A - Soil restoration", "Local variety", "Improved variety",
                             food = "Pulses and legumes", outcome = "Productivity", data = arc.data,
                             extra = c("T_varietal_crop_variety","out_subindicator"))

table.2a.s9c <- ic.2a.s9c$companions %>%
  rename(`Local variety` = T_varietal_crop_variety,
         `Outcome measured` = out_subindicator)%>%
  
  mutate(`Companion species` = if_else(is.na(`Companion species`), "-", `Companion species`)) %>%
  arrange(`Measured crop`, `Local variety`, 
          `Outcome measured`,
          desc(Comparisons),
          desc(`% positive comparisons`))
View(table.2a.s9c)

# Table 2A.S9: a) to c), each with its own header
table.2a.s9 <- do.call(rbind, Map(with_header,
                                  list(table.2a.s9a, table.2a.s9b, table.2a.s9c),
                                  c(
                                    "a) Intercropping compared with sole pulse or legume crops, by measured crop, companion species, intercrop type, and outcome measured.",
                                    "b) Crop residue incorporation compared with residue removal, by measured crop, companion species, type of residue, and outcome measured.",
                                    "c) Local compared with improved varieties, by measured crop, companion species, local variety, and outcome measured.")))
View(table.2a.s9)

write_csv(table.2a.s9, file.path(path.output, "ken_2A_TableS9_pulses_legumes.csv"))

#--- Archetype 2A: Table 2A.S10 Effect of Supplemental irrigation on Vegetables yield ----
# Vegetables, Supplemental irrigation, Yield
ic.2a.s10 <- practice_detail(arc.long, "2A - Soil restoration", "Supplemental irrigation", "Rainfed agriculture",
                            food = "Vegetables", outcome = "Productivity", data = arc.data,
                            extra = c("T_irrig_method","out_subindicator"))
#View(ic.2a.s10$companions)    

table.2a.s10 <- ic.2a.s10$companions %>%
  mutate(T_irrig_method=case_when(
    T_irrig_method=="Drip irrigation"~"Supplemental drip irrigation",
    TRUE~T_irrig_method
  ))%>%
  rename(`Irrigation method` = T_irrig_method,
         `Outcome measured` = out_subindicator)%>%
  mutate(`Companion species`=if_else(is.na(`Companion species`),"-",`Companion species`))%>%
  arrange(`Measured crop`,       # 1st: A to Z
          `Irrigation method`,
          `Outcome measured`,
          desc(Comparisons),
          desc(`% positive comparisons`))     # 3rd: largest to smallest within each outcome

View(table.2a.s10)

write_csv(table.2a.s10, file.path(path.output, "ken_2A_TableS10_vegetables_supplementary_irrigation.csv"))


#----------------------------------------------------------------------
#--- 6.2. Archetype 2B: Evidence synthesis interpretation in detail ----
#----------------------------------------------------------------------
#--- Archetype 2B: Table 2B.S3 Effect of Residue incorporation on cereals Productivity and Soil health ----
# a) Cereals, Residue incorporation, Productivity
ic.2b.s3a <- practice_detail(arc.long, "2B - Arid micro-gardens", "Residue incorporation", "No residues or mulch",
                             food = "Cereals", outcome = "Productivity", data = arc.data,
                             extra = c("T_residues_subpractice", "out_subindicator"))

View(ic.2b.s3a$companions)    # cereal measured + species it was intercropped with

table.2b.s3a <- ic.2b.s3a$companions %>%
  rename(`Residues type` = T_residues_subpractice,
         `Outcome measured` = out_subindicator)%>%
  mutate(`Companion species`=if_else(is.na(`Companion species`),"-",`Companion species`),
         `Residues type`=str_replace_all(`Residues type`, "\\.{2,}", " + "))%>%
  arrange(`Measured crop`,       # 1st: A to Z
          `Residues type`,
          `Outcome measured`,
          desc(Comparisons),
          desc(`% positive comparisons`))     # 3rd: largest to smallest within each outcome

View(table.2b.s3a)

# b) Cereals, Residue incorporation, Soil health
ic.2b.s3b <- practice_detail(arc.long, "2B - Arid micro-gardens", "Residue incorporation", "No residues or mulch",
                             food = "Cereals", outcome = "Soil health", data = arc.data,
                             extra = c("T_residues_subpractice", "out_subindicator"))
View(ic.2b.s3b$companions)    # cereal measured + species it was intercropped with

table.2b.s3b <- ic.2b.s3b$companions %>%
  rename(`Residues type` = T_residues_subpractice,
         `Main crop` = `Measured crop`, 
         `Outcome measured` = out_subindicator)%>%
  mutate(`Companion species`=if_else(is.na(`Companion species`),"-",`Companion species`),
         `Residues type`=str_replace_all(`Residues type`, "\\.{2,}", " + "))%>%
  arrange(`Main crop`,       # 1st: A to Z
          `Residues type`,
          `Outcome measured`,
          desc(Comparisons),
          desc(`% positive comparisons`))     # 3rd: largest to smallest within each outcome

View(table.2b.s3b)

table.2b.s3 <- do.call(rbind, Map(with_header,
                                  list(table.2b.s3a, table.2b.s3b),
                                  c("a) Cereal productivity, by measured crop, companion species, type of residue incorporated, and outcome measured.",
                                    "b) Soil health in cereal systems, by main crop, companion species, type of residue incorporated, and outcome measured."
                                  )))
View(table.2b.s3)

write_csv(table.2b.s3, file.path(path.output, "ken_2B_TableS3_cereals_residues_incorporation.csv"))

#--- Archetype 2B: Table 2B.S4 Effect of Organic mulch on cereals Productivity, Soil health ----
# a) Cereals, Organic mulch, Productivity
ic.2b.s4a <- practice_detail(arc.long, "2B - Arid micro-gardens", "Organic mulch", "No residues or mulch",
                             food = "Cereals", outcome = "Productivity", data = arc.data,
                             extra = c("T_residues_subpractice","out_subindicator"))

View(ic.2b.s4a$companions)    # cereal measured + species it was intercropped with

table.2b.s4a <- ic.2b.s4a$companions %>%
  rename(`Organic mulch` = T_residues_subpractice,
         `Outcome measured` = out_subindicator)%>%
  mutate(`Companion species`=if_else(is.na(`Companion species`),"-",`Companion species`))%>%
  arrange(`Measured crop`,       # 1st: A to Z
          `Organic mulch`,
          `Outcome measured`,
          desc(Comparisons),
          desc(`% positive comparisons`))     # 3rd: largest to smallest within each outcome

View(table.2b.s4a)

# b) Cereals, Organic mulch, Soil health
ic.2b.s4b <- practice_detail(arc.long, "2B - Arid micro-gardens", "Organic mulch", "No residues or mulch",
                             food = "Cereals", outcome = "Soil health", data = arc.data,
                             extra = c("T_residues_subpractice", "out_subindicator"))

View(ic.2b.s4b$companions)    # cereal measured + species it was intercropped with

table.2b.s4b <- ic.2b.s4b$companions %>%
  rename(`Organic mulch` = T_residues_subpractice,
         `Main crop` = `Measured crop`, 
         `Outcome measured` = out_subindicator)%>%
  mutate(`Companion species`=if_else(is.na(`Companion species`),"-",`Companion species`))%>%
  arrange(`Main crop`,       # 1st: A to Z
          `Organic mulch`,
          `Outcome measured`,
          desc(Comparisons),
          desc(`% positive comparisons`))     # 3rd: largest to smallest within each outcome

View(table.2b.s4b)

table.2b.s4 <- do.call(rbind, Map(with_header,
                                  list(table.2b.s4a, table.2b.s4b),
                                  c("a) Cereal productivity, by measured crop, companion species, type of organic mulch, and outcome measured.",
                                    "b) Soil health in cereal systems, by main crop, companion species, type of organic mulch, and outcome measured."
                                    )))
View(table.2b.s4)

write_csv(table.2b.s4, file.path(path.output, "ken_2B_TableS4_cereals_organic_mulch.csv"))

#--- Archetype 2B: Table 2A.S5 Effect of Mixed fertilizer on cereals Productivity ----
# a) Cereals, Mixed fertilizer, Productivity
ic.2b.s5 <- practice_detail(arc.long, "2B - Arid micro-gardens", "Mixed fertilizer", "No fertilizer applied",
                             food = "Cereals", outcome = "Productivity", data = arc.data,
                             extra = c("T_fert_subpractice", "out_subindicator"))

View(ic.2b.s5$companions)    # cereal measured + species it was intercropped with

table.2b.s5 <- ic.2b.s5$companions %>%
  rename(`Mixed input` = T_fert_subpractice,
         `Outcome measured` = out_subindicator)%>%
  
  mutate(`Companion species`=if_else(is.na(`Companion species`),"-",`Companion species`),
         `Mixed input`=str_replace_all(`Mixed input`, "\\.{2,}", " + "))%>%
  arrange(`Measured crop`,       # 1st: A to Z
          `Mixed input`,
          `Outcome measured`,
          desc(Comparisons),
          desc(`% positive comparisons`))     # 3rd: largest to smallest within each outcome

View(table.2b.s5)


write_csv(table.2b.s5, file.path(path.output, "ken_2B_TableS5_cereals_mixed_fertilizer.csv"))

#--- Archetype 2B: Table 2B.S6 Effect of Intercropping on Pulses and legumes Productivity, Resilience to pests, Biodiversity ----
# a) Pulses and legumes, Intercropping, Productivity
arc.long.2b.s6a <- arc.long %>%
  mutate(
    # Desmodium common names and species -> Desmodium spp.; Crotalaria species -> Crotalaria spp.
    T_crop_tree_diversity = str_replace_all(T_crop_tree_diversity,
                                            regex("\\b(Silverleaf|Greenleaf|Tick Clover sp)\\b", ignore_case = TRUE),
                                            "Desmodium spp."),
    T_crop_tree_diversity = str_replace_all(T_crop_tree_diversity,
                                            "\\b(Desmodium|Crotalaria) [a-z]+\\.?", "\\1 spp."),
    T_intercrop_subpractice = case_when(
      str_detect(coalesce(T_crop_tree_diversity, ""), "Desmodium")      ~ "Push-pull",
      str_detect(coalesce(T_intercrop_subpractice, ""), "Push pull")    ~ "Push-pull",
      str_detect(coalesce(T_intercrop_subpractice, ""), "\\(N fixing")  ~ "With a nitrogen-fixing species",
      str_detect(coalesce(T_intercrop_subpractice, ""), "Non N fixing") ~ "Without a nitrogen-fixing species",
      TRUE                                                               ~ T_intercrop_subpractice))

ic.2b.s6a <-  practice_detail(arc.long.2b.s6a, "2B - Arid micro-gardens", "Intercropping", "Monoculture",
                              food = "Pulses and legumes", outcome = "Productivity", data = arc.data,
                              extra = c("T_intercrop_subpractice","out_subindicator"))


View(ic.2b.s6a$companions)    # cereal measured + species it was intercropped with

table.2b.s6a <- ic.2b.s6a$companions %>%
  
  rename(`Intercrop type` = T_intercrop_subpractice,
         `Outcome measured` = out_subindicator)%>%
  mutate(`Companion species`=if_else(is.na(`Companion species`),"-",`Companion species`))%>%
  arrange(`Measured crop`,       # 1st: A to Z
          `Intercrop type`,
          `Companion species`,
          `Outcome measured`,
          desc(Comparisons),
          desc(`% positive comparisons`))     # 3rd: largest to smallest within each outcome
View(table.2b.s6a)

# b) Pulses and legumes, Intercropping, Resilience to pests
# pest rows: the pest in its own column, the cereal in T_product_simple
pulses <- c("Common Bean", "Cowpea")

arc.long.2b.s6b <- arc.long.2b.s6a %>%
  filter(outcome_group == "Resilience to pests") %>%
  mutate(Pest = case_when(str_detect(T_product, "Striga")              ~ "Weeds (Striga)",
                          str_detect(T_product, "Stemborer")           ~ "Insect pests (stem borers)",
                          str_detect(T_product, "Thrips|Thysanoptera") ~ "Insect pests (thrips)",
                          TRUE                                         ~ coalesce(bio_func_group, T_product)),
         # "Maize..Lepidoptera" -> "Maize"; "Lamiales" -> the cereal(s) in the intercrop
         T_product_simple = if_else(str_detect(T_product_simple, fixed("..")),
                                    str_remove(T_product_simple, "\\.\\..*$"),
                                    vapply(str_split(coalesce(T_crop_tree_diversity, ""), "[-/]"),
                                           function(s) paste(intersect(str_trim(s), pulses), collapse = " + "),
                                           character(1))))

ic.2b.s6b <- practice_detail(arc.long.2b.s6b, "2B - Arid micro-gardens", "Intercropping", "Monoculture",
                             food = "Pulses and legumes", outcome = "Resilience to pests", data = arc.data,
                             extra = c("T_intercrop_subpractice", "Pest"))

View(ic.2b.s6b$companions)

table.2b.s6b <- ic.2b.s6b$companions %>%
  mutate(`Outcome measured` = "Resilience to ") %>%
  rename(`Intercrop type` = T_intercrop_subpractice,
         `Main crop` = `Measured crop`,
         `Pest or weed` = Pest) %>%
  mutate(`Outcome measured` = paste0(`Outcome measured`, str_replace(`Pest or weed`, "^\\w", tolower))) %>%
  select(`Main crop`, `Companion species`, `Intercrop type`,
         `Outcome measured`, everything(), -`Pest or weed`) %>%
  mutate(`Companion species` = if_else(is.na(`Companion species`), "-", `Companion species`)) %>%
  arrange(`Main crop`,# `Pest or weed`, 
          `Intercrop type`, `Companion species`,
          desc(Comparisons),
          desc(`% positive comparisons`))
View(table.2b.s6b)

# c) Pulses and legumes, Intercropping, Biodiversity
# organism counted in its own column, the pulse(s) of the intercrop in T_product_simple
arc.long.2b.s6c <- arc.long.2b.s6a %>%
  filter(outcome_group == "Biodiversity") %>%
  mutate(Organism = paste0(coalesce(bio_func_group, "Other organisms"), " (", T_product, ")"),
         T_product_simple = vapply(str_split(coalesce(T_crop_tree_diversity, ""), "[-/]"),
                                   function(s) paste(intersect(str_trim(s), pulses), collapse = " + "),
                                   character(1)))

ic.2b.s6c <- practice_detail(arc.long.2b.s6c, "2B - Arid micro-gardens", "Intercropping", "Monoculture",
                             food = "Pulses and legumes", outcome = "Biodiversity", data = arc.data,
                             extra = c("T_intercrop_subpractice", "Organism", "out_subindicator"))

View(ic.2b.s6c$companions)

table.2b.s6c <- ic.2b.s6c$companions %>%
  rename(`Intercrop type` = T_intercrop_subpractice,
         `Main crop` = `Measured crop`) %>%
  mutate(`Outcome measured` = paste0(out_subindicator, " of ", str_replace(Organism, "^\\w", tolower)),
         `Companion species` = if_else(is.na(`Companion species`), "-", `Companion species`)) %>%
  select(`Main crop`, `Companion species`, `Intercrop type`, `Outcome measured`, everything(),
         -Organism, -out_subindicator) %>%
  arrange(`Main crop`, `Intercrop type`, `Companion species`, `Outcome measured`,
          desc(Comparisons), desc(`% positive comparisons`))
View(table.2b.s6c)


table.2b.s6 <- do.call(rbind, Map(with_header,
                                  list(table.2b.s6a, table.2b.s6b, table.2b.s6c),
                                  c("a) Pulse and legume productivity, by measured crop, companion species, intercrop type, and outcome measured.",
                                    "b) Resilience to pests in pulse and legume intercrops, by main crop, companion species, intercrop type, and outcome measured.",
                                    "c) Biodiversity in pulse and legume intercrops, by main crop, companion species, intercrop type, and outcome measured.")))
View(table.2b.s6)

write_csv(table.2b.s6, file.path(path.output, "ken_2B_TableS6_pulses_intercropping.csv"))

#--- Archetype 2B: Table 2B.S7 Effect of Biochar amendment, Mixed fertilizer on Pulses and legumes Productivity ----
# a) Cereals, Biochar amendment, Productivity
ic.2b.s7a <- practice_detail(arc.long, "2B - Arid micro-gardens", "Biochar amendment", "No fertilizer applied",
                             food = "Pulses and legumes", outcome = "Productivity", data = arc.data,
                             extra = c("T_fert_subpractice", "out_subindicator"))

View(ic.2b.s7a$companions)    # cereal measured + species it was intercropped with

table.2b.s7a <- ic.2b.s7a$companions %>%
  rename(`Biochar amendment` = T_fert_subpractice,
         `Outcome measured` = out_subindicator)%>%
  mutate(`Companion species`=if_else(is.na(`Companion species`),"-",`Companion species`))%>%
  arrange(`Measured crop`,       # 1st: A to Z
          `Biochar amendment`,
          `Outcome measured`,
          desc(Comparisons),
          desc(`% positive comparisons`))     # 3rd: largest to smallest within each outcome

View(table.2b.s7a)

# b) Cereals, Mixed fertilizer, Productivity
ic.2b.s7b <- practice_detail(arc.long, "2B - Arid micro-gardens", "Mixed fertilizer", "No fertilizer applied",
                             food = "Pulses and legumes", outcome = "Productivity", data = arc.data,
                             extra = c("T_fert_subpractice", "out_subindicator"))

View(ic.2b.s7b$companions)    # cereal measured + species it was intercropped with

table.2b.s7b <- ic.2b.s7b$companions %>%
  rename(`Mixed input` = T_fert_subpractice,
         `Outcome measured` = out_subindicator)%>%
  
  mutate(`Companion species`=if_else(is.na(`Companion species`),"-",`Companion species`),
         `Mixed input`=str_replace_all(`Mixed input`, "\\.{2,}", " + "))%>%
  arrange(`Measured crop`,       # 1st: A to Z
          `Mixed input`,
          `Outcome measured`,
          desc(Comparisons),
          desc(`% positive comparisons`))     # 3rd: largest to smallest within each outcome

View(table.2b.s7b)


# Table 2B.s7: a) to b), each with its own header
table.2b.s7 <- do.call(rbind, Map(with_header,
                                  list(table.2b.s7a, table.2b.s7b),
                                  c("a) Biochar amendment compared with no fertilizer, by measured crop, companion species, type of biochar amendment, and outcome measured.",
                                    "b) Mixed fertilizers compared with no fertilizer, by measured crop, companion species, type of mixed input, and outcome measured.")))
View(table.2b.s7)

write_csv(table.2b.s7, file.path(path.output, "ken_2B_TableS7_pulses_biochar_mixed_fertilizer.csv"))

#--- Archetype 2B: Table 2A.S8 Effect of Intercropping on Nuts and seeds Resilience to pests, Biodiversity ----
# a) Nuts and seeds, Intercropping, Resilience to pests
arc.long.2b.s8 <- arc.long %>%
  mutate(
    # Desmodium common names and species -> Desmodium spp.; Crotalaria species -> Crotalaria spp.
    T_crop_tree_diversity = str_replace_all(T_crop_tree_diversity,
                                            regex("\\b(Silverleaf|Greenleaf|Tick Clover sp)\\b", ignore_case = TRUE),
                                            "Desmodium spp."),
    T_crop_tree_diversity = str_replace_all(T_crop_tree_diversity,
                                            "\\b(Desmodium|Crotalaria) [a-z]+\\.?", "\\1 spp."),
    T_intercrop_subpractice = case_when(
      str_detect(coalesce(T_crop_tree_diversity, ""), "Desmodium")      ~ "Push-pull",
      str_detect(coalesce(T_intercrop_subpractice, ""), "Push pull")    ~ "Push-pull",
      str_detect(coalesce(T_intercrop_subpractice, ""), "\\(N fixing")  ~ "With a nitrogen-fixing species",
      str_detect(coalesce(T_intercrop_subpractice, ""), "Non N fixing") ~ "Without a nitrogen-fixing species",
      TRUE                                                               ~ T_intercrop_subpractice))

# pest rows: the pest in its own column, the Nuts and seeds crops in T_product_simple
nuts_seeds <- c("Sunflower")

arc.long.2b.s8a <- arc.long.2b.s8 %>%
  filter(outcome_group == "Resilience to pests") %>%
  mutate(Pest = case_when(str_detect(T_product, "Striga")              ~ "Weeds (Striga)",
                          str_detect(T_product, "Stemborer")           ~ "Insect pests (stem borers)",
                          str_detect(T_product, "Thrips|Thysanoptera") ~ "Insect pests (thrips)",
                          TRUE                                         ~ coalesce(bio_func_group, T_product)),
         # "Maize..Lepidoptera" -> "Maize"; "Lamiales" -> the cereal(s) in the intercrop
         T_product_simple = if_else(str_detect(T_product_simple, fixed("..")),
                                    str_remove(T_product_simple, "\\.\\..*$"),
                                    vapply(str_split(coalesce(T_crop_tree_diversity, ""), "[-/]"),
                                           function(s) paste(intersect(str_trim(s), nuts_seeds), collapse = " + "),
                                           character(1))))

ic.2b.s8a <- practice_detail(arc.long.2b.s8a, "2B - Arid micro-gardens", "Intercropping", "Monoculture",
                             food = "Nuts and seeds", outcome = "Resilience to pests", data = arc.data,
                             extra = c("T_intercrop_subpractice", "Pest"))

View(ic.2b.s8a$companions)

table.2b.s8a <- ic.2b.s8a$companions %>%
  mutate(`Outcome measured` = "Resilience to ") %>%
  rename(`Intercrop type` = T_intercrop_subpractice,
         `Main crop` = `Measured crop`,
         `Pest or weed` = Pest) %>%
  mutate(`Outcome measured` = paste0(`Outcome measured`, str_replace(`Pest or weed`, "^\\w", tolower))) %>%
  select(`Main crop`, `Companion species`, `Intercrop type`,
         `Outcome measured`, everything(), -`Pest or weed`) %>%
  mutate(`Companion species` = if_else(is.na(`Companion species`), "-", `Companion species`)) %>%
  arrange(`Main crop`,# `Pest or weed`, 
          `Intercrop type`, `Companion species`,
          desc(Comparisons),
          desc(`% positive comparisons`))
View(table.2b.s8a)

# b) Nuts and seeds, Intercropping, Biodiversity
# organism counted in its own column, the nuts and seeds of the intercrop in T_product_simple
arc.long.2b.s8b <- arc.long.2b.s8 %>%
  filter(outcome_group == "Biodiversity") %>%
  mutate(Organism = paste0(coalesce(bio_func_group, "Other organisms"), " (", T_product, ")"),
         T_product_simple = vapply(str_split(coalesce(T_crop_tree_diversity, ""), "[-/]"),
                                   function(s) paste(intersect(str_trim(s), nuts_seeds), collapse = " + "),
                                   character(1)))

ic.2b.s8b <- practice_detail(arc.long.2b.s8b, "2B - Arid micro-gardens", "Intercropping", "Monoculture",
                             food = "Nuts and seeds", outcome = "Biodiversity", data = arc.data,
                             extra = c("T_intercrop_subpractice", "Organism", "out_subindicator"))

View(ic.2b.s8b$companions)

table.2b.s8b <- ic.2b.s8b$companions %>%
  rename(`Intercrop type` = T_intercrop_subpractice,
         `Main crop` = `Measured crop`) %>%
  mutate(`Outcome measured` = paste0(out_subindicator, " of ", str_replace(Organism, "^\\w", tolower)),
         `Companion species` = if_else(is.na(`Companion species`), "-", `Companion species`)) %>%
  select(`Main crop`, `Companion species`, `Intercrop type`, `Outcome measured`, everything(),
         -Organism, -out_subindicator) %>%
  arrange(`Main crop`, `Intercrop type`, `Companion species`, `Outcome measured`,
          desc(Comparisons), desc(`% positive comparisons`))
View(table.2b.s8b)


table.2b.s8 <- do.call(rbind, Map(with_header,
                                  list(table.2b.s8a, table.2b.s8b),
                                  c(
                                    "a) Resilience to pests in nuts and seeds intercrops, by main crop, companion species, intercrop type, and outcome measured.",
                                    "b) Biodiversity in nuts and seeds intercrops, by main crop, companion species, intercrop type, and outcome measured.")))


View(table.2b.s8)

write_csv(table.2b.s8, file.path(path.output, "ken_2B_TableS8_nuts_seeds_intercropping.csv"))

#--- Archetype 2B: Table 2B.S9 Effect of Supplemental irrigation on Vegetables Productivity and Profitability ----
# Vegetables, Supplemental irrigation, Productivity
ic.2b.s9a <- practice_detail(arc.long, "2B - Arid micro-gardens", "Supplemental irrigation", "Rainfed agriculture",
                             food = "Vegetables", outcome = "Productivity", data = arc.data,
                             extra = c("T_irrig_method","out_subindicator"))
View(ic.2b.s9a$companions)    

table.2b.s9a <- ic.2b.s9a$companions %>%
  mutate(T_irrig_method=case_when(
    T_irrig_method=="Drip Irrigation"~"Supplemental drip irrigation",
    TRUE~T_irrig_method
  ))%>%
  rename(`Irrigation method` = T_irrig_method,
         `Outcome measured` = out_subindicator)%>%
  mutate(`Companion species`=if_else(is.na(`Companion species`),"-",`Companion species`))%>%
  arrange(`Measured crop`,       # 1st: A to Z
          `Irrigation method`,
          `Outcome measured`,
          desc(Comparisons),
          desc(`% positive comparisons`))     # 3rd: largest to smallest within each outcome

View(table.2b.s9a)

# Vegetables, Supplemental irrigation, Profitability
ic.2b.s9b <- practice_detail(arc.long, "2B - Arid micro-gardens", "Supplemental irrigation", "Rainfed agriculture",
                             food = "Vegetables", outcome = "Profitability", data = arc.data,
                             extra = c("T_irrig_method","out_subindicator"))
View(ic.2b.s9b$companions)    

table.2b.s9b <- ic.2b.s9b$companions %>%
  mutate(T_irrig_method=case_when(
    T_irrig_method=="Drip Irrigation"~"Supplemental drip irrigation",
    TRUE~T_irrig_method
  ))%>%
  rename(`Irrigation method` = T_irrig_method,
         `Main crop` = `Measured crop`, 
         `Outcome measured` = out_subindicator)%>%
  mutate(`Companion species`=if_else(is.na(`Companion species`),"-",`Companion species`))%>%
  arrange(`Main crop`,       # 1st: A to Z
          `Irrigation method`,
          `Outcome measured`,
          desc(Comparisons),
          desc(`% positive comparisons`))     # 3rd: largest to smallest within each outcome

View(table.2b.s9b)

table.2b.s9 <- do.call(rbind, Map(with_header,
                                  list(table.2b.s9a, table.2b.s9b),
                                  c("a) Vegetable productivity, by measured crop, companion species, irrigation method, and outcome measured.",
                                    "b) Profitability of vegetable systems, by main crop, companion species, irrigation method, and outcome measured."
                                  )))
View(table.2b.s9)

write_csv(table.2b.s9, file.path(path.output, "ken_2B_Tables9_vegetables_supplementary_irrigation.csv"))


