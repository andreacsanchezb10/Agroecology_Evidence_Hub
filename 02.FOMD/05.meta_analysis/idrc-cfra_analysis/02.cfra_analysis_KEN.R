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

#==========================================================
#--- Report DEEP-DIVE COUNTRY: KENYA
#==========================================================
path.metadata.effectsize<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/04.metadata_effectsize/"
path.meta.analysis<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/05.meta_analysis/idrc-cfra_analysis/"
path.archetypes <- paste0(path.meta.analysis, "archetypes/")
path.output        <- paste0(path.meta.analysis,"/02.cfra_analysis")

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

#==========================================================
# Read functions
#==========================================================
source(file.path(path.meta.analysis,"cfra_fun/fun_plot_archetype.R"))
source(file.path(path.meta.analysis, "cfra_fun/fun_archetype_selection.R")) #need to create
source(file.path(path.meta.analysis,"cfra_fun/fun_practices_reclassification.R"))
source(file.path(path.meta.analysis, "cfra_fun/fun_direction_count.R"))
source(file.path(path.meta.analysis, "cfra_fun/fun_food_groups.R"))

#==========================================================
#--- Read datasets
#==========================================================
#--- fomd10.effect.size ----
data <-read_csv(file.path(path.meta.analysis,"01.cfra_data/fomd10_cfra.csv"), show_col_types = FALSE)%>%
  filter(str_detect(country, country_name))%>%
  mutate(food_group = factor(food_group, levels = food_group_order))  # CSV loses the order

nrow(data );length(unique(data $study_id))
#[1] v51 3621; v52 6784; v52.2 6830
#[1] v51 80; v52 98; v52.2 96
sort(unique(data$country))

#--- Agroecological zones----
#agr.zn <- rast(paste0(path.meta.analysis,"/GAEZ/GAEZ_AEZ57_ETH.tif"))
#gaez.lookup <- read.csv(paste0(path.meta.analysis,"/GAEZ/GAEZ_57_lookup.csv"),
 #                       stringsAsFactors = FALSE)
#names(agr.zn) <- "value"     # standardize the layer name

#==========================================================
#--- 1. Paired comparisons in archetype high-priority areas ----
#==========================================================
points <- make_points(data)

arc.data <- pmap_dfr(archetypes, function(code, archetype, file, rule) {
  arc <- st_read(file.path(path.archetypes, country_code, file), quiet = TRUE)
  ids <- select_priority(points, arc, rule)
  data %>% semi_join(ids, by = "effect_size_id") %>% mutate(archetype = archetype)
})

# Paired comparisons per archetype (below the threshold -> expand to agro-ecological zones)
arc.data %>% group_by(archetype) %>%
  summarise(paired_comparisons = n_distinct(effect_size_id),
            studies = n_distinct(study_id), .groups = "drop") %>%
  mutate(below_threshold = paired_comparisons < min_paired_comparisons)

#archetype               paired_comparisons studies below_threshold
#v51   1 2A - Soil restoration                 3342      75 FALSE          
#v51   2 2B - Arid micro-gardens                320      12 FALSE

#v52   1 2A - Soil restoration                 6346      90 FALSE          
#v52   2 2B - Arid micro-gardens                380      15 FALSE

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
#--- 4. Figures: one per archetype ----
#==========================================================
source(file.path(path.meta.analysis, "cfra_fun/fun_plot_count.R"))

legend.grid <- grid_legend(strong_es = strong_es, 
                           cut_positive = cut_positive, cut_negative = cut_negative)

for (i in seq_len(nrow(archetypes))) {
  arc_name <- archetypes$archetype[i]
  
  p <- plot_votes(cells, arc_name, min_es_cell = min_es_cell, strong_es = strong_es,
                  cut_positive = cut_positive, cut_negative = cut_negative) +
    theme(legend.position = "none")
  
  # figure height from the number of rows shown
  n_rows <- nrow(distinct(p$data, block, row_key))
  h_plot   <- max(1.5 + 0.35 * n_rows, 4)   # at least 4 inches, so the legend fits
  
  # legend on the right, at the top
  fig <- p + (plot_spacer() / legend.grid / plot_spacer() + 
                plot_layout(heights = c(0.2, 1, 2))) +
    plot_layout(widths = c(4, 1))
  print(fig)
  
  ggsave(file.path(path.output, paste0(country_code,"_", archetypes$code[i],  "_votes_",".png")),
         fig, width = 16, height = h_plot, dpi = 300)
}

#=============
source(file.path(path.meta.analysis, "cfra_fun/fun_plot_count_grouped.R"))

legend.grid <- grid_legend(strong_es = strong_es, cut_positive = cut_positive, cut_negative = cut_negative)

parts <- list(a = "Cereals",
              b = c("Pulses and legumes", "Vegetables", "Roots and tubers", "Nuts and seeds", "Fruits"))

for (i in seq_len(nrow(archetypes))) {
  arc_name <- archetypes$archetype[i]
  for (part in names(parts)) {
    groups <- parts[[part]]                                  # outside filter(), so no clash with columns
    cc <- cells %>% filter(food_group %in% groups)
    if (!any(cc$archetype == arc_name)) next
    
    p <- plot_votes_grouped(cc, arc_name, min_es_cell = min_es_cell, strong_es = strong_es,
                            cut_positive = cut_positive, cut_negative = cut_negative, text_size = 8)
    legend.row <- wrap_plots(plot_spacer(), legend.grid, plot_spacer(), widths = c(1, 1.2, 1))
    fig <- wrap_plots(p, legend.row, ncol = 1, heights = c(attr(p, "n_rows"), 4))
    
    ggsave(file.path(path.output, paste0(country_code,"_", archetypes$code[i],  "_votes_",".png")),
           fig, width = 7.5, height = 0.3 * attr(p, "n_rows") + 1.8, dpi = 300, bg = "white")
  }
}

#==========================================================
#--- 5. Archetype maps (country-specific arguments) ----
#==========================================================
plot_archetype(paste0(path.archetypes, "ken/Archetype_2A_ADM1_Choropleth.gpkg"),
               n_criteria    = 4,
               outline_col   = "Low_Female_Education_Flag",
               outline_label = "Gender Concern (Female Education < 6 yrs)",
               legend_title  = "Yield Stagnation & Soil Restoration\nCriteria Met (0-4)")

plot_archetype(paste0(path.archetypes, "ken/Archetype_2B_ADM1_Choropleth.gpkg"),
               n_criteria   = 5,
               scope_col    = "ASAL_County", scope_value = "Yes",
               legend_title = "Arid Pastoral Micro-Gardens\nCriteria Met (ASAL counties only)")

#==========================================================
#--- 5.1 Study sites included in the analysis: 2A - Soil restoration ----
#==========================================================
arc.2a <- st_read(file.path(path.archetypes, country_code, "Archetype_2A_ADM1_Choropleth.gpkg"), quiet = TRUE)

# paired comparisons of 2A used in the analysis (after reclassification and exclusions)
ids.2a <- arc.long %>%
  filter(archetype == "2A - Soil restoration") %>%
  distinct(effect_size_id, study_id)

# one point per site, with the number of paired comparisons and studies
sites.2a <- points %>%
  mutate(lon = st_coordinates(.)[, 1], lat = st_coordinates(.)[, 2]) %>%
  st_drop_geometry() %>%
  inner_join(ids.2a, by = "effect_size_id") %>%
  group_by(lon, lat) %>%
  summarise(paired_comparisons = n_distinct(effect_size_id),
            studies = n_distinct(study_id), .groups = "drop") %>%
  st_as_sf(coords = c("lon", "lat"), crs = 4326) %>%
  st_transform(st_crs(arc.2a))

# multi-site comparisons: keep only the sites inside the high-priority areas
priority.2a <- arc.2a[arc.2a$Criteria_Met_Count >= 3, ]
sites.2a <- sites.2a[lengths(st_intersects(sites.2a, priority.2a)) > 0, ]

map.2a <- plot_archetype(arc.2a,
                         n_criteria    = 4,
                         outline_col   = "Low_Female_Education_Flag",
                         outline_label = "Gender Concern (Female Education < 6 yrs)",
                         legend_title  = "Yield Stagnation & Soil Restoration\nCriteria Met (0-4)") +
  geom_sf(data = sites.2a, aes(size = paired_comparisons),
          shape = 21, fill = "#1B5E20", colour = "white", stroke = 0.3, alpha = 0.85) +
  scale_size(range = c(1.5, 7), breaks = c(1, 10, 50, 100),
             name = "Paired comparisons\nper site") +
  labs(title = "2A - Soil restoration: study sites included in the analysis",
       subtitle = paste0(n_distinct(ids.2a$study_id), " studies, ",
                         n_distinct(ids.2a$effect_size_id), " paired comparisons, ",
                         nrow(sites.2a), " sites"))
map.2a

ggsave(file.path(Sys.getenv("USERPROFILE"), "Downloads", "ken_sites_2A.png"),
       map.2a, width = 9, height = 8, dpi = 300, bg = "white")

#==========================================================
#--- 6. Detail of practices with strong positive effects ----
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
View(ic.2a.sxc$systems)       # full control and treatment systems
View(ic.2a.sxc$studies)
View(ic.2a.sxc$extra)

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




