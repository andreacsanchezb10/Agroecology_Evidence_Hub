# library(ggplot2)
library(dplyr)
library(tidyr)
library(ggh4x)
library(ggplot2)
library(sf)
library(rnaturalearth)
library(rnaturalearthdata)
library(dplyr)
library(rnaturalearthhires)
library(ggnewscale)
library(treemapify)
library(forcats)
path.metaanalysis<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/05.meta_analysis/idrc-cfra_analysis"

#============================================================
#  Africa Map with ADM1 (provinces/states) + Custom Points
#  Dependencies: install once, then re-run freely
# ============================================================
#--- 1. Report n_rows and n_studies per country -----
country.studies<-fomd10.cfra %>%
  group_by(country) %>%#,out_pillar) %>%
  summarise(
    n_effect_sizes     = n(),
    n_studies  = n_distinct(study_id)
  ) %>%
  arrange(desc(n_effect_sizes))%>%
  mutate(country=if_else(country=="Tanzania","United Republic of Tanzania",country))

# ---- 2. Helper: parse "a..b..c" coordinate strings into a list of values -------
parse_coords <- function(coord_str) {
  str_split(coord_str, fixed(".."))[[1]] %>% as.numeric()
}

# ---- 3. Expand multi-coordinate rows into one row per point --------------------
expand_sites <- function(df, country_col, lat_col, lon_col, out_pillar,effect_size_direction) {
  df %>%
    select(country = {{ country_col }},
           lat_str = {{ lat_col }},
           lon_str = {{ lon_col }},
           out_pillar=out_pillar,
           #effect_size_direction=effect_size_direction
           ) %>%
    mutate(out_pillar = out_pillar,
           #effect_size_direction=effect_size_direction,
           row_id = row_number()) %>%
    rowwise() %>%
    mutate(
      lats = list(parse_coords(lat_str)),
      lons = list(parse_coords(lon_str))
    ) %>%
    ungroup() %>%
    mutate(coords = map2(lats, lons, ~ tibble(lat = .x, lon = .y))) %>%
    select(row_id, country, out_pillar,
           #effect_size_direction, 
           coords) %>%
    unnest(coords)
}

# ---- 4. Build the unified points table -----------------------------------------
x <- fomd10.cfra %>%
  select(C_country, C_site_latitude, C_site_longitude,out_pillar
         #,effect_size_direction
         )%>%
  distinct(C_country,
           C_site_latitude,
           C_site_longitude,
           out_pillar#,effect_size_direction
           ) 

control_pts  <- expand_sites(x, C_country, C_site_latitude, C_site_longitude, out_pillar#,effect_size_direction
                             )

cfra.sites <- control_pts %>%
  filter(!is.na(lat), !is.na(lon))

# Find rows where parsing produces NAs
error<-x %>%
  mutate(row_id = row_number()) %>%
  rowwise() %>%
  mutate(
    lats = list(parse_coords(C_site_latitude)),
    lons = list(parse_coords(C_site_longitude)),
    has_na = any(is.na(lats)) | any(is.na(lons))
  ) %>%
  ungroup() %>%
  filter(has_na) %>%
  select(row_id, C_country, C_site_latitude, C_site_longitude)

# --- 5. Load the data and  (EDIT THIS PATH) ---

# Your CSV must have at minimum:
#   - a longitude column  (decimal degrees, e.g. 15.3)
#   - a latitude  column  (decimal degrees, e.g. -4.2)
# Optional: any extra columns (name, value, category…) for labels/colour

#csv_path <- "your_data.csv"        # <-- change to your file path
lon_col  <- "lon"            # <-- change to your longitude column name
lat_col  <- "lat"             # <-- change to your latitude  column name

#points_df <- read.csv(csv_path, stringsAsFactors = FALSE)

# Convert to sf object (WGS84)
points_sf <- st_as_sf(cfra.sites,
                      coords = c(lon_col, lat_col),
                      crs    = 4326,
                      remove = FALSE)

# --- List of countries to highlight ---
cfra_country_names <- c("Angola",
                         "Burundi",
                         "Malawi",
                         "Rwanda",
                         "United Republic of Tanzania",
                         "Uganda")

deepdive_country_names<-c(
  "Ethiopia",
  "Kenya",
  "Zambia")

# Country borders (ADM0)
africa_countries <- ne_countries(
  continent = "Africa",
  scale     = "medium",       # "large" for more detail (slower)
  returnclass = "sf"
)
  

cfra_countries<-africa_countries%>%
  filter(admin %in% c(cfra_country_names, deepdive_country_names))%>%
  mutate(highlight = ifelse(admin %in% cfra_country_names, "CFRA-country", "CFRA-deepdive"))%>%
  left_join(country.studies,by=c("admin"="country"))%>%
  mutate(n_effect_sizes=if_else(is.na(n_effect_sizes),0,n_effect_sizes),
         n_studies=if_else(is.na(n_studies),0,n_studies))
  
  
# ADM1 – provinces / states
africa_adm1 <- ne_states(
  country     = africa_countries$admin,   # all African countries
  returnclass = "sf"
) %>%
  filter(!is.na(geometry))               # drop any empty rows

# ---- 5. PLOT CFRA countries ----
# Optional: colour points by a column in your CSV, e.g. "category"
# Set colour_col <- NULL to use a single colour for all points.
colour_col <- "out_pillar"    # e.g. colour_col <- "category"

plot.cfra.countries<-
  ggplot() +
    # Country borders (darker, thicker)
    geom_sf(data  = africa_countries,
            fill  = "grey95",
            colour = "grey60",
            linewidth = 0.7) +
    
    # CFRA country borders (darker, thicker)
    geom_sf(data  = cfra_countries,
            aes(fill = n_studies, linewidth = highlight,
                colour=highlight)) +
  scale_fill_viridis_c(option = "mako", direction = -1, 
                       name = "Studies (N)")+
    
    
    scale_linewidth_manual(values = c("CFRA-country" = 0.7,
                                      "CFRA-deepdive"    = 2))+
      scale_colour_manual(values = c("CFRA-country" = "darkorange",
                                     "CFRA-deepdive"="darkorange"))+
  
    new_scale_colour() +
    geom_sf(data = points_sf,
            shape = 21,            # shape 21 = circle with separate fill + outline
                fill = "white",
                colour = "grey30",
                size = 2,
                stroke = 0.5,
                alpha = 0.6)+
  # Coordinate limits (full Africa bounding box)
  coord_sf(xlim = c(-20, 55), ylim = c(-36, 38), expand = FALSE,
           label_graticule = "") +
  
  # Theme
  theme_minimal(base_size = 12) +
  theme(
    panel.background = element_rect(fill = "White", colour = NA), # ocean
    panel.grid       = element_line(colour = "White", linewidth = 0.2),
    axis.title       = element_blank(),
    legend.position  = "right"
  ) 

print(plot.cfra.countries)

# ---- 6. Save to file ----
output_file <- paste0(path.metaanalysis,"/plot.cfra.countries.pdf")   # change extension to .pdf / .svg if needed

ggsave(paste0(path.metaanalysis,"/plot.cfra.countries.pdf"), plot = plot.cfra.countries,
       width = 10, height = 11, dpi = 300, bg = "white")

message("Map saved to: ", normalizePath(output_file))

names(africa_countries)

# ============================================================
# --- OUTCOMES PILLAR AND SUBINDICATOR ---
# ============================================================
# ---- 1. Summarize: count effect sizes per indicator, within each pillar ----
cfra.indicator <- fomd10.cfra %>%
  filter(!is.na(out_pillar), !is.na(out_indicator)) %>%
  count(out_pillar, out_indicator, name = "n_comparisons") %>%
  rename(group = out_pillar, indicator = out_indicator)%>%
  mutate(label = paste0( " (", n_comparisons, ")"))

# Order pillars left to right
cfra.indicator$group <- factor(cfra.indicator$group, levels = c("Productivity","Resilience", "Mitigation"))

# ---- 2. Set stacking order within each bar ----
# Order categories within each pillar by n_comparisons (largest segments first)
# Replace this block with an explicit factor(levels = c(...)) per pillar
# if you want a specific manual stacking order instead.
cfra.indicator <- cfra.indicator %>%
  group_by(group) %>%
  mutate(indicator = fct_reorder(indicator, n_comparisons)) %>%
  ungroup()

# ---- 3. Totals for the labels above each bar ----
totals <- cfra.indicator %>%
  group_by(group) %>%
  summarise(total = sum(n_comparisons))

# ---- 4. Legend labels with counts ----
legend_df <- cfra.indicator %>%
  arrange(group, desc(n_comparisons)) 

legend_order <- unique(as.character(legend_df$indicator))
legend_labels <- setNames(legend_df$label, legend_df$indicator)

# ---- 5. Colors: assign a palette per pillar (tan/cream, red, brown) ----
n_prod <- length(unique(cfra.indicator$indicator[cfra.indicator$group == "Productivity"]))
n_res  <- length(unique(cfra.indicator$indicator[cfra.indicator$group == "Resilience"]))
n_mit  <- length(unique(cfra.indicator$indicator[cfra.indicator$group == "Mitigation"]))

pal_prod <- colorRampPalette(c("#FCEFC7", "#E8D9A0", "#C2B280", "#9C8A4E", "#6E5F2A"))(n_prod)
pal_res  <- colorRampPalette(c("#FBD7C4", "#F2A488", "#E2542A", "#A8331A", "#5C0A0A"))(n_res)
pal_mit  <- colorRampPalette(c("#F2C078", "#C8821E", "#9C5E1A", "#7A4A1E", "#4A2C0F"))(n_mit)

cats_prod <- unique(as.character(cfra.indicator$indicator[cfra.indicator$group == "Productivity"]))
cats_res  <- unique(as.character(cfra.indicator$indicator[cfra.indicator$group == "Resilience"]))
cats_mit  <- unique(as.character(cfra.indicator$indicator[cfra.indicator$group == "Mitigation"]))

colors <- setNames(
  c(pal_prod, pal_res, pal_mit),
  c(cats_prod, cats_res, cats_mit)
)

# ---- 6. Plot ----
base_theme <- theme_minimal(base_family = "sans", base_size = 11) +
  theme(
    plot.background  = element_rect(fill = "white", colour = NA),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    axis.text        = element_text(colour = "#374151"),
    axis.title       = element_blank(),
    plot.title       = element_text(face = "bold", colour = "#1A1A2E", size = 12),
    plot.subtitle    = element_text(colour = "#6B7280", size = 9),
    legend.position  = "none"
  )

plot.cfra.indicators<-
ggplot(cfra.indicator, aes(x = group, y = n_comparisons, fill = indicator)) +
  geom_col(width = 0.7, color = NA) +
  geom_text(data = totals, aes(x = group, y = total, label = total),
            inherit.aes = FALSE, vjust = -0.5, size = 5, fontface = "bold") +
  scale_fill_manual(
    values = colors,
    breaks = legend_order,
    labels = legend_labels,
    name = NULL
  ) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.08))) +
  #labs(x = NULL, y = NULL, tag = "d)") +
  theme_minimal(base_size = 14) +
  theme(
    axis.text.x = element_text(size = 14, face = "bold", color = "black"),
    axis.text.y = element_blank(),
    axis.ticks = element_blank(),
    panel.grid = element_blank(),
    legend.position = "right",
    legend.justification = "right",
    legend.text = element_text(size = 11),
    legend.key.size = unit(0.5, "cm"),
    plot.tag = element_text(face = "bold", size = 16),
    plot.tag.position = c(0.02, 0.98)
  ) +
  guides(fill = guide_legend(ncol = 1))

print(plot.cfra.indicators)

plot.cfra.indicators<-ggplot(cfra.indicator, 
                              aes(x = n_comparisons, 
                                  y = reorder (indicator, n_comparisons),
                                  fill = indicator)) +
  geom_col(width = 0.7)+
  geom_text(aes(label = label), hjust = -0.1, size = 3.2, colour = "#374151") +
  scale_fill_manual(values = colors) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.25))) +
  base_theme 
  theme(axis.text.x = element_blank())+
print(plot.cfra.indicators)



# ---- 7. Save to file ----

ggsave(paste0(path.metaanalysis,"/plot.cfra.indicators2.pdf"), plot = plot.cfra.indicators,
       width = 6, height = 9, dpi = 300, bg = "white")

# ============================================================
# --- CROP COMMODITY DISTRIBUTION ---
# ============================================================
FAO_Food_Group_labels <- c(
  #"Fruit and nuts"                                     
  #"Grasses and other fodder crops"                     
  "Leguminous crops"="Legumes" ,                                  
  #"Medicinal, pesticidal or similar crops"             
  "No N Fix Tree"  ="Trees (non-N-fixing)",  
  "N Fix Tree"="Trees (N-fixing)",
  "Oilseed crops and oleaginous fruits" =  "Oilseeds",              
  "Root tuber crops with high starch or inulin content"= "Root tubers",
  "Vegetables and melons"   =  "Vegetables"      )
  
#---- 1. Split composite categories and count each row once per individual category ----
FAO_Food_Group_counts <- fomd10.cfra %>%
    #filter(country=="Ethiopia")%>%
    #filter(country=="Kenya")%>%
    filter(country=="Zambia")%>%
  select(CT_crop_FAO_Food_Group_clean) %>%
  filter(!is.na(CT_crop_FAO_Food_Group_clean)) %>%
  mutate(row_id = row_number()) %>%
  separate_rows(CT_crop_FAO_Food_Group_clean, sep = "\\.\\.") %>%
  distinct(row_id, CT_crop_FAO_Food_Group_clean) %>%  # avoid double-counting if a category repeats within one row
  count(CT_crop_FAO_Food_Group_clean, name = "n_comparisons", sort = TRUE) %>%
  rename(FAO_Food_Group = CT_crop_FAO_Food_Group_clean)%>%
  mutate(FAO_Food_Group = recode(FAO_Food_Group, !!!FAO_Food_Group_labels),
         label=paste0("(",n_comparisons,")" ))%>%
  filter(!(FAO_Food_Group%in%c(
    "Trees (non-N-fixing)", 
    "Trees (N-fixing)",
    "Grasses and other fodder crops",
    "Medicinal, pesticidal or similar crops" ,
    "Fibre crops"
  )))
 
sort(unique(FAO_Food_Group_counts$FAO_Food_Group))
print(FAO_Food_Group_counts)

sort(unique(fomd10.cfra$T_crop_tree_diversity))

crops_counts <- fomd10.cfra %>%
  #filter(country=="Ethiopia")%>%
  #filter(country=="Kenya")%>%
  filter(country=="Zambia")%>%
  
  
  select(T_crop_tree_diversity) %>%
  mutate(row_id = row_number()) %>%
  separate_rows(T_crop_tree_diversity, sep = "[/\\-]") %>%
  distinct(row_id, T_crop_tree_diversity) %>%  # avoid double-counting if a category repeats within one row
  count(T_crop_tree_diversity, name = "n_comparisons", sort = TRUE)%>%
  left_join(
    fomd01.crops.trees %>% select(crop_tree_diversity, FAO.Food.Group),
    by = c("T_crop_tree_diversity" = "crop_tree_diversity")
  ) 
  filter(is.na(FAO.Food.Group)) %>%
  arrange(crop)
  rename(FAO_Food_Group = CT_crop_FAO_Food_Group_clean)

#---- 2. Plots ----
# Number of comparisons per crop FAO group 
plot.cfra.commodities<-
ggplot(FAO_Food_Group_counts, aes(area = n_comparisons, fill = FAO_Food_Group, label = paste0(FAO_Food_Group, "\n(", n, ")"))) +
  geom_treemap(color = "white", size = 2) +
  geom_treemap_text(
    fontface = "bold",
    colour = "black",
    place = "centre",
    grow = FALSE,
    reflow = TRUE,
    size = 12
  ) +
  scale_fill_brewer(palette = "Greens") +
  theme(legend.position = "none") 

print(plot.cfra.commodities)



###### bar chart
comm_palette <- c(
  "Cereals"                = "#F4C430", # golden yellow
  "Legumes"                = "#E87722",  # orange
  "Vegetables"             = "#3A86FF",  # bright blue
  "Root tubers"     = "#B5179E",  # magenta
  "Oilseeds"          =  "#2C5F2D",  # dark green
  "Trees (non-N-fixing)"   = "#028090",  # teal
  "Fruits"                 = "#E63946",  # red
  "Spice and aromatic crops" = "#7B2D8B",  # purple
  "Stimulant crops"        = "#A0522D",  # brown
  "Fibre crops"            = "#4CC9F0"   # light blue
)

plot.cfra.commodities<-ggplot(FAO_Food_Group_counts, 
       aes(x = n_comparisons, 
           y = reorder (FAO_Food_Group, n_comparisons),
           fill = FAO_Food_Group)) +
  geom_col(width = 0.55)+ 
  geom_text(aes(label = label), hjust = -0.1, size = 3.2, colour = "#374151") +
scale_fill_manual(values = comm_palette) +
  scale_x_continuous(limits = c(0, 15500), expand = expansion(mult = c(0, 0.25)))+

  base_theme +
  theme(axis.text.x = element_blank())
print(plot.cfra.commodities)

# ---- 3. Save to file ----
ggsave(paste0(path.metaanalysis,"/plot.zam.commodities2.pdf"), plot = plot.cfra.commodities,
       width = 6, height = 9, dpi = 300, bg = "white")

# ============================================================
# --- PRACTICE DISTRIBUTION ---
# ============================================================
practice_themes_labels <- c(
  "biomass_management"="Biomass management",
  "soil_management"="Soil management",
  "water_management" ="Water management",
  "variety_management"  = "Crop genetic improvement",
  "nutrient_management"="Nutrient management",
  "pest_management"= "Pest management",
  "diversification_temporal"="Temporal diversification",
  "planting_management"="Planting methods",
  "diversification_spatial"="Agroforestry & Crop spatial diversification")
  
practice_themes_counts <- fomd10.cfra %>%
  #filter(country=="Ethiopia")%>%
  #filter(country=="Kenya")%>%
  filter(country == "Zambia") %>%
  
    select(practice_groups) %>%
  filter(!is.na(practice_groups)) %>%
  mutate(row_id = row_number()) %>%
  separate_rows(practice_groups, sep = "\\.\\.") %>%
  distinct(row_id, practice_groups) %>%  # avoid double-counting if a category repeats within one row
  count(practice_groups, name = "n_comparisons", sort = TRUE) %>%
  rename(practice_themes = practice_groups)%>%
  mutate(practice_themes = recode(practice_themes, !!!practice_themes_labels))%>%
  arrange(desc(n_comparisons))%>%
  mutate(practice_themes = factor(practice_themes, levels = rev(practice_themes)),
         label=paste0("(",n_comparisons,")" ))

# Map each subpractice column to its parent practice theme
practice_sub_to_theme <- c(
  variety_management_subpractice       = "Crop genetic improvement",
  #breed_animal_subpractice             = "Crop genetic improvement",
  planting_management_subpractice      = "Planting methods",
  diversification_spatial_subpractice  = "Agroforestry & Crop spatial diversification",
  diversification_temporal_subpractice = "Temporal diversification",
  soil_management_subpractice          = "Soil management",
  nutrient_management_subpractice      = "Nutrient management",
  pest_management_subpractice          = "Pest management",
  water_management_subpractice         = "Water management",
  biomass_management_subpractice       = "Biomass management"
)

# Count subpractices within each column, tag with its parent theme, combine
practice_subpractice_counts <- purrr::map_dfr(
  practice_sub_cols,
  function(col) {
    fomd10.cfra %>%
      #filter(country == "Ethiopia") %>%
      #filter(country == "Kenya") %>%
      filter(country == "Zambia") %>%
      
      select(subpractice = all_of(col)) %>%
      filter(!is.na(subpractice)) %>%
      mutate(row_id = row_number()) %>%
      separate_rows(subpractice, sep = "\\.\\.") %>%
      distinct(row_id, subpractice) %>%   # avoid double-counting within one row
      count(subpractice, name = "n_comparisons", sort = TRUE) %>%
      mutate(
        subpractice_col = col,
        practice_theme  = practice_sub_to_theme[[col]]
      )
  }
) %>%
  relocate(practice_theme, subpractice_col, subpractice, n_comparisons) %>%
  arrange(practice_theme, desc(n_comparisons)) %>%
  group_by(practice_theme) %>%
  mutate(
    subpractice = factor(subpractice, levels = rev(subpractice)),
    label = paste0("(", n_comparisons, ")")
  ) %>%
  ungroup()

# Optional: split into one tibble per theme (handy for small-multiple charts)
practice_subpractice_list <- practice_subpractice_counts %>%
  group_by(practice_theme) %>%
  group_split() %>%
  setNames(sort(unique(practice_subpractice_counts$practice_theme)))

# Optional sanity check: totals here should roughly match practice_themes_counts
subpractice_counts<-practice_subpractice_counts 
  group_by(practice_theme) %>%
  summarise(total_subpractice_n = sum(n_comparisons), .groups = "drop")


# ---- 4. Legend labels with counts ----
legend_practice_themes <- practice_themes_counts %>%
  arrange(desc(n_comparisons)) %>%
  mutate(label = paste0(practice_themes, " (", n_comparisons, ")"))

legend_practice_order <- as.character(legend_practice_themes$practice_themes)
legend_practice_labels <- setNames(legend_practice_themes$label, legend_practice_themes$practice_themes)

# ---- 6. Plot ----
pract_palette <- c(
  "Crop genetic improvement"                = "#4A3AA7", # golden yellow
  "Nutrient management"                = "#EDA100",  # orange
  "Water management"             = "#2A78D6",  # bright blue
  "Soil management"     = "#8A5A2B",  # magenta
  "Temporal diversification"          =  "#1BAF7A",  # dark green
  "Agroforestry & crop spatial diversification"   = "#008300",  # teal
  "Biomass management"                 = "#6B7A1F",  # red
  "Planting methods" = "#EB6834",  # purple
  "Pest management"        = "#E34948"  # brown
)

plot.cfra.practices<-
  ggplot(practice_themes_counts, aes(x = n_comparisons, y = practice_themes, fill = practice_themes)) +
  geom_col(width = 0.7, color = NA) +
  geom_text(data = practice_themes_counts, aes(x = n_comparisons+1000, y = practice_themes, label = label),
            inherit.aes = FALSE, vjust = 0.5, size = 5, fontface = "bold") +
  scale_fill_manual(values = pract_palette) +
  
  scale_x_continuous(limits = c(0, 15500), expand = expansion(mult = c(0, 0.2)))+
  
  #scale_y_continuous(expand = expansion(mult = c(0, 0.08))) +
  #labs(x = NULL, y = NULL, tag = "d)") +
  base_theme +
  theme(axis.text.x = element_blank())

print(plot.cfra.practices)


ggsave(paste0(path.metaanalysis,"/plot.zam.practices.pdf"), plot = plot.cfra.practices,
       width = 10, height = 9, dpi = 300, bg = "white")

# ============================================================
# --- DEEP-DIVE: Ethiopia, Kenya, Zambia ---
# ============================================================
# ------------------------------------------------------------
# Donut-chart matrix: Agricultural practices × Impact areas
#
# DATA
# Each cell has a number (total results) and a colour profile.
# The donuts show proportions of: positive (green), negative (red),
# (not for now: neutral/mixed (yellow), and no-effect/unknown (grey))
# These proportions are estimated visually from the original figure.
# Replace the p_pos / p_neg / p_neu / p_none columns with real data
# if you have the underlying dataset.
# ------------------------------------------------------------------
#CT_crop_FAO_Food_Group<- c("Cereals")

# --- 1. TIDY: pivot proportions to long format, deduplicate ---

impacts<- c("Costs",
            "Income",
            "Efficiency",
            "Yield", 
            "Soil Quality")

df <- raw_diversification %>%
  distinct(CT_crop_FAO_Food_Group_label ,
           practice,
           #nutrient_management,
           #water_management,
           
           impact, .keep_all = TRUE) %>%
  pivot_longer(cols = c(pos, neg#, neu, none
  ),
  names_to  = "outcome",
  values_to = "proportion") %>%
  #filter(CT_crop_FAO_Food_Group_label=="Cereals")
  mutate(
    impact = factor(impact, levels = impacts))

# --- 2. BUILD DONUTS via polar coordinates ----
#Each donut is drawn as a stacked bar in polar coords, faceted.

colours <- c(pos  = "#4CAF50",   # green
             #neu  = "#FFC107",   # amber
             neg  = "#E53935"#,   # red
             #none = "#BDBDBD"
)   # grey

ggplot(df, aes(x = 2, y = proportion, fill = outcome)) +
  geom_col(width = 0.9, colour = "white", linewidth = 0.3) +
  coord_polar(theta = "y", start = -pi / 2, direction = 1, clip = "on") +
  #xlim(0.5, 2.5) +                          # 0.5 = hole size.
  scale_x_continuous(limits = c(0.5, 2.5), expand = c(0, 0))+
  scale_y_continuous(expand = c(0, 0))+
  
  #facet_grid( CT_crop_FAO_Food_Group~diversification_spatial~impact ,
  #          switch = "both") +             # labels on left & bottom
  facet_grid2(
    rows = vars(CT_crop_FAO_Food_Group_label,
                practice#,
                #nutrient_management
    ),
    cols = vars(impact),   # two variables on columns side
    switch = "both",
    drop   = TRUE,                   # skip empty combos → no gaps
    independent = "none"             # or "all" if you want free scales
  ) +
  
  scale_fill_manual(
    values = colours,
    labels = c(pos = "Positive",# neu = "Neutral / mixed",
               neg = "Negative"#, none = "No effect / unknown"
    ),
    name   = NULL
  ) +
  # study-count label in the centre of each donut
  geom_text(
    data = distinct(df, 
                    CT_crop_FAO_Food_Group_label,
                    practice, #nutrient_management,
                    impact, n),
    aes(x = 0.5, y = 0, label = n),
    inherit.aes = FALSE,
    size = 5, fontface = "bold", colour = "#333333"
  ) +
  theme_void(base_size = 9) +
  theme(
    strip.text.x    = element_text(size = 12,  angle = 0, hjust = 0,
                                   vjust = 1,  margin = margin(b = 4)),
    strip.text.y    = element_text(size = 12,  angle = 0,  hjust = 1,
                                   margin = margin(r = 6)),
    strip.placement = "outside",
    legend.position = "bottom",
    legend.text     = element_text(size = 10),
    legend.key.size = unit(0.45, "cm"),
    plot.margin     = margin(t = 5, r = 5, b = 5, l = 5),
    panel.spacing   = unit(0.15, "cm"),
    plot.title      = element_text(size = 10, face = "bold", hjust = 0.5,
                                   margin = margin(b = 6))
  ) 
#labs(title = "Number of studies and their outcomes by agricultural practice and impact area")
#p

# ============================================================
# --- DEEP-DIVE: Ethiopia ---
# ============================================================
# Optional: colour points by a column in your CSV, e.g. "category"
# Set colour_col <- NULL to use a single colour for all points.
colour_col <- "out_pillar"    # e.g. colour_col <- "category"

cfra.ethiopia
ggplot() +
  
  # ADM1 fill (light grey provinces)
  geom_sf(data  = africa_adm1%>%
            filter(admin=="Ethiopia"),
          fill  = "#f5f0e8",
          colour = "#c8bfaf",
          linewidth = 0.25) +
  
  # Country borders (darker, thicker)
  geom_sf(data  = africa_countries%>%
            filter(sovereignt=="Ethiopia"),
          fill  = NA,
          colour = "#5a4a3a",
          linewidth = 0.6) +
  
  # Points
  {
    if (!is.null(colour_col)) {
      geom_sf(data  = points_sf%>%
                filter(country=="Ethiopia"),
              aes(colour = .data[[colour_col]]),
              size  = 2.5, alpha = 0.85)
    } else {
      geom_sf(data  = points_sf%>%
                filter(country=="Ethiopia"),
              colour = c("#d62728", "green","blue"),  # red – change as you like
              size   = 2.5, alpha  = 0.85)
    }
  } +
  
  # Coordinate limits (full Africa bounding box)
  #coord_sf(xlim = c(-20, 55), ylim = c(-36, 38), expand = FALSE) +
  
  # Theme
  theme_minimal(base_size = 12) +
  theme(
    panel.background = element_rect(fill = "#d0e8f2", colour = NA), # ocean
    panel.grid       = element_line(colour = "#b0cfe0", linewidth = 0.2),
    axis.title       = element_blank(),
    legend.position  = "right"
  ) +
  labs(
    title    = "Ethiopia",
    subtitle = "",
    colour   = colour_col,
    caption  = "Geodata: Natural Earth"
  )

print(cfra.countries)

# --- 5. Save to file ---
output_file <- "cfra_countries.png"   # change extension to .pdf / .svg if needed

ggsave("cfra_countries.png", plot = p,
       width = 10, height = 11, dpi = 300, bg = "white")

message("Map saved to: ", normalizePath(output_file))



# ============================================================
# --- DEEP-DIVE: Ethiopia ---
# ============================================================

# ------------------------------------------------------------
# Donut-chart matrix: Agricultural practices × Impact areas
#
# DATA
# Each cell has a number (total results) and a colour profile.
# The donuts show proportions of: positive (green), negative (red),
# (not for now: neutral/mixed (yellow), and no-effect/unknown (grey))
# These proportions are estimated visually from the original figure.
# Replace the p_pos / p_neg / p_neu / p_none columns with real data
# if you have the underlying dataset.
# ------------------------------------------------------------------
#CT_crop_FAO_Food_Group<- c("Cereals")

# --- 1. TIDY: pivot proportions to long format, deduplicate ---

impacts<- c("Costs",
            "Income",
            "Efficiency",
            "Yield", 
                  "Soil Quality")

df <- raw_diversification %>%
  distinct(CT_crop_FAO_Food_Group_label ,
           practice,
           #nutrient_management,
           #water_management,
           
           impact, .keep_all = TRUE) %>%
  pivot_longer(cols = c(pos, neg#, neu, none
  ),
  names_to  = "outcome",
  values_to = "proportion") %>%
#filter(CT_crop_FAO_Food_Group_label=="Cereals")
  mutate(
    impact = factor(impact, levels = impacts))

    impact   = factor(impact,   levels = rev(impacts))   # rev so top row = first level
    
practice = factor(practice, levels = practices),
CT_crop_FAO_Food_Group = factor(CT_crop_FAO_Food_Group, levels = CT_crop_FAO_Food_Group))

outcome  = factor(outcome,  levels = c("pos",#"neu",
                                       "neg"#,"none"
))
)

# --- 2. BUILD DONUTS via polar coordinates ----
#Each donut is drawn as a stacked bar in polar coords, faceted.

colours <- c(pos  = "#4CAF50",   # green
             #neu  = "#FFC107",   # amber
             neg  = "#E53935"#,   # red
             #none = "#BDBDBD"
)   # grey

ggplot(df, aes(x = 2, y = proportion, fill = outcome)) +
  geom_col(width = 0.9, colour = "white", linewidth = 0.3) +
  coord_polar(theta = "y", start = -pi / 2, direction = 1, clip = "on") +
  #xlim(0.5, 2.5) +                          # 0.5 = hole size.
  scale_x_continuous(limits = c(0.5, 2.5), expand = c(0, 0))+
  scale_y_continuous(expand = c(0, 0))+
  
  #facet_grid( CT_crop_FAO_Food_Group~diversification_spatial~impact ,
  #          switch = "both") +             # labels on left & bottom
  facet_grid2(
    rows = vars(CT_crop_FAO_Food_Group_label,
                practice#,
                #nutrient_management
                ),
    cols = vars(impact),   # two variables on columns side
    switch = "both",
    drop   = TRUE,                   # skip empty combos → no gaps
    independent = "none"             # or "all" if you want free scales
  ) +
  
  scale_fill_manual(
    values = colours,
    labels = c(pos = "Positive",# neu = "Neutral / mixed",
               neg = "Negative"#, none = "No effect / unknown"
    ),
    name   = NULL
  ) +
  # study-count label in the centre of each donut
  geom_text(
    data = distinct(df, 
                    CT_crop_FAO_Food_Group_label,
                    practice, #nutrient_management,
                    impact, n),
    aes(x = 0.5, y = 0, label = n),
    inherit.aes = FALSE,
    size = 5, fontface = "bold", colour = "#333333"
  ) +
  theme_void(base_size = 9) +
  theme(
    strip.text.x    = element_text(size = 12,  angle = 0, hjust = 0,
                                   vjust = 1,  margin = margin(b = 4)),
    strip.text.y    = element_text(size = 12,  angle = 0,  hjust = 1,
                                   margin = margin(r = 6)),
    strip.placement = "outside",
    legend.position = "bottom",
    legend.text     = element_text(size = 10),
    legend.key.size = unit(0.45, "cm"),
    plot.margin     = margin(t = 5, r = 5, b = 5, l = 5),
    panel.spacing   = unit(0.15, "cm"),
    plot.title      = element_text(size = 10, face = "bold", hjust = 0.5,
                                   margin = margin(b = 6))
  ) 
#labs(title = "Number of studies and their outcomes by agricultural practice and impact area")
#p

#============================================================
#  Map with ADM1 (provinces/states) + Custom Points
#  Dependencies: install once, then re-run freely
# ============================================================
#--- 1. Report n_rows and n_studies per country=="Ethiopia" -----
country.outpillar<-fomd10.cfra.eth %>%
  group_by(country,out_pillar) %>%
  summarise(
    n_effect_sizes     = n(),
    n_studies  = n_distinct(study_id)
  ) %>%
  arrange(desc(n_effect_sizes))

# --- 2. Helper: parse "a..b..c" coordinate strings into a list of values -------
parse_coords <- function(coord_str) {
  str_split(coord_str, fixed(".."))[[1]] %>% as.numeric()
}

# --- 3. Expand multi-coordinate rows into one row per point --------------------
expand_sites <- function(df, country_col, lat_col, lon_col, out_pillar,effect_size_direction) {
  df %>%
    select(country = {{ country_col }},
           lat_str = {{ lat_col }},
           lon_str = {{ lon_col }},
           out_pillar=out_pillar,
           effect_size_direction=effect_size_direction) %>%
    mutate(out_pillar = out_pillar,
           effect_size_direction=effect_size_direction,
           row_id = row_number()) %>%
    rowwise() %>%
    mutate(
      lats = list(parse_coords(lat_str)),
      lons = list(parse_coords(lon_str))
    ) %>%
    ungroup() %>%
    mutate(coords = map2(lats, lons, ~ tibble(lat = .x, lon = .y))) %>%
    select(row_id, country, out_pillar,effect_size_direction, coords) %>%
    unnest(coords)
}

# --- 4. Build the unified points table -----------------------------------------
x <- fomd10.cfra.eth %>%
  
  select(C_country, C_site_latitude, C_site_longitude,out_pillar,effect_size_direction)%>%

  distinct(C_country,
           C_site_latitude,
           C_site_longitude,
           out_pillar,
           effect_size_direction) 

control_pts  <- expand_sites(x, C_country, C_site_latitude, C_site_longitude, out_pillar,effect_size_direction)

cfra.sites <- control_pts %>%
  filter(!is.na(lat), !is.na(lon))

# Find rows where parsing produces NAs
error<-x %>%
  mutate(row_id = row_number()) %>%
  rowwise() %>%
  mutate(
    lats = list(parse_coords(C_site_latitude)),
    lons = list(parse_coords(C_site_longitude)),
    has_na = any(is.na(lats)) | any(is.na(lons))
  ) %>%
  ungroup() %>%
  filter(has_na) %>%
  select(row_id, C_country, C_site_latitude, C_site_longitude)

# --- 5. Load the data and  (EDIT THIS PATH) ---

# Your CSV must have at minimum:
#   - a longitude column  (decimal degrees, e.g. 15.3)
#   - a latitude  column  (decimal degrees, e.g. -4.2)
# Optional: any extra columns (name, value, category…) for labels/colour

#csv_path <- "your_data.csv"        # <-- change to your file path
lon_col  <- "lon"            # <-- change to your longitude column name
lat_col  <- "lat"             # <-- change to your latitude  column name

#points_df <- read.csv(csv_path, stringsAsFactors = FALSE)

# Convert to sf object (WGS84)
points_sf <- st_as_sf(cfra.sites,
                      coords = c(lon_col, lat_col),
                      crs    = 4326,
                      remove = FALSE)

# --- 6. Load country borders and ADMIN1- provinces / states ---
# Country borders (ADM0)
africa_countries <- ne_countries(
  continent = "Africa",
  scale     = "medium",       # "large" for more detail (slower)
  returnclass = "sf"
)

# ADM1 – provinces / states
africa_adm1 <- ne_states(
  country     = africa_countries$admin,   # all African countries
  returnclass = "sf"
) %>%
  filter(!is.na(geometry))               # drop any empty rows

# --- 7. Tydy up the data ---
out_pillar_labels<-c("Productivity"="Profitability")

points_sf<-points_sf%>%
  mutate(out_pillar_label = recode(out_pillar, !!!out_pillar_labels))
         
# --- 7. Plot ---
# Optional: colour points by a column in your CSV, e.g. "category"
# Set colour_col <- NULL to use a single colour for all points.

colour_shape <- "out_pillar_label"    # e.g. colour_col <- "category"
colour_col <- "effect_size_direction"    # e.g. colour_col <- "category"
colours <- c(Positive  = "#4CAF50",   # green
             #neu  = "#FFC107",   # amber
             Negative  = "#E53935"#,   # red
             #none = "#BDBDBD"
)
             
cfra.ethiopia
ggplot() +
  
  # ADM1 fill (light grey provinces)
  geom_sf(data  = africa_adm1%>%
            filter(admin=="Ethiopia"),
          fill  = "#f5f0e8",
          colour = "#c8bfaf",
          linewidth = 0.25) +
  
  # Country borders (darker, thicker)
  geom_sf(data  = africa_countries%>%
            filter(sovereignt=="Ethiopia"),
          fill  = NA,
          colour = "#5a4a3a",
          linewidth = 0.6) +
  
  # Points
  {
    if (!is.null(colour_col)) {
      geom_sf(data  = points_sf,
              aes(colour = .data[[colour_col]],
                  shape = .data[[colour_shape]]),

              size  = 4, alpha = 0.85)
    } else {
      geom_sf(data  = points_sf,
              colour = "#888888",  # red – change as you like
              size   = 4, alpha  = 0.85)
    }
  } +
  
  # Coordinate limits (full Africa bounding box)
  #coord_sf(xlim = c(-20, 55), ylim = c(-36, 38), expand = FALSE) +
  
  # Theme
  scale_colour_manual(values = colours) +
  
  theme_minimal(base_size = 12) +
  theme(
    panel.background = element_rect(fill = "#d0e8f2", colour = NA), # ocean
    panel.grid       = element_line(colour = "#b0cfe0", linewidth = 0.2),
    axis.title       = element_blank(),
    legend.position  = "right"
  ) +
  labs(
    title    = "Ethiopia",
    subtitle = "",
    colour   = colour_col,
    caption  = "Geodata: Natural Earth"
  )

print(cfra.countries)


#============================================================
#  Africa Map with ADM1 (provinces/states) + Custom Points
#  Dependencies: install once, then re-run freely
# ============================================================

# --- 1. Install / load packages ---
packages <- c("ggplot2", "sf", "rnaturalearth", "rnaturalearthdata",
              "rnaturalearthhires", "dplyr")

new_pkgs <- packages[!packages %in% installed.packages()[, "Package"]]
if (length(new_pkgs)) {
  # rnaturalearthhires is on GitHub – needs remotes
  if ("rnaturalearthhires" %in% new_pkgs) {
    if (!"remotes" %in% installed.packages()[, "Package"])
      install.packages("remotes")
    remotes::install_github("ropensci/rnaturalearthhires")
    new_pkgs <- setdiff(new_pkgs, "rnaturalearthhires")
  }
  if (length(new_pkgs)) install.packages(new_pkgs)
}

library(ggplot2)
library(sf)
library(rnaturalearth)
library(rnaturalearthdata)
library(dplyr)

# ============================================================
# --- 2. Load your CSV  (EDIT THIS PATH) ---
# ============================================================
# Your CSV must have at minimum:
#   - a longitude column  (decimal degrees, e.g. 15.3)
#   - a latitude  column  (decimal degrees, e.g. -4.2)
# Optional: any extra columns (name, value, category…) for labels/colour

#csv_path <- "your_data.csv"        # <-- change to your file path
lon_col  <- "lon"            # <-- change to your longitude column name
lat_col  <- "lat"             # <-- change to your latitude  column name

#points_df <- read.csv(csv_path, stringsAsFactors = FALSE)

# Convert to sf object (WGS84)
points_sf <- st_as_sf(cfra.sites,
                      coords = c(lon_col, lat_col),
                      crs    = 4326,
                      remove = FALSE)

# ============================================================
# --- CFRA countries ---
# ============================================================
# Country borders (ADM0)
africa_countries <- ne_countries(
  continent = "Africa",
  scale     = "medium",       # "large" for more detail (slower)
  returnclass = "sf"
)

# ADM1 – provinces / states
africa_adm1 <- ne_states(
  country     = africa_countries$admin,   # all African countries
  returnclass = "sf"
) %>%
  filter(!is.na(geometry))               # drop any empty rows

# ============================================================
# --- 4. Plot ---
# ============================================================

# Optional: colour points by a column in your CSV, e.g. "category"
# Set colour_col <- NULL to use a single colour for all points.
colour_col <- "out_pillar"    # e.g. colour_col <- "category"

cfra.countries<-
  ggplot() +
  
  # ADM1 fill (light grey provinces)
  geom_sf(data  = africa_adm1,
          fill  = "#f5f0e8",
          colour = "#c8bfaf",
          linewidth = 0.25) +
  
  # Country borders (darker, thicker)
  geom_sf(data  = africa_countries,
          fill  = NA,
          colour = "#5a4a3a",
          linewidth = 0.6) +
  
  # Points
  {
    if (!is.null(colour_col)) {
      geom_sf(data  = points_sf,
              aes(colour = .data[[colour_col]]),
              size  = 2.5, alpha = 0.85)
    } else {
      geom_sf(data  = points_sf,
              colour = c("#d62728", "green","blue"),  # red – change as you like
              size   = 2.5, alpha  = 0.85)
    }
  } +
  
  # Coordinate limits (full Africa bounding box)
  coord_sf(xlim = c(-20, 55), ylim = c(-36, 38), expand = FALSE) +
  
  # Theme
  theme_minimal(base_size = 12) +
  theme(
    panel.background = element_rect(fill = "#d0e8f2", colour = NA), # ocean
    panel.grid       = element_line(colour = "#b0cfe0", linewidth = 0.2),
    axis.title       = element_blank(),
    legend.position  = "right"
  ) +
  labs(
    title    = "CFRA countries",
    subtitle = "",
    colour   = colour_col,
    caption  = "Geodata: Natural Earth"
  )

print(cfra.countries)

# --- 5. Save to file ---
output_file <- "cfra_countries.png"   # change extension to .pdf / .svg if needed

ggsave("cfra_countries.png", plot = p,
       width = 10, height = 11, dpi = 300, bg = "white")

message("Map saved to: ", normalizePath(output_file))

names(africa_countries)
# ============================================================
# --- DEEP-DIVE: Ethiopia ---
# ============================================================
# Optional: colour points by a column in your CSV, e.g. "category"
# Set colour_col <- NULL to use a single colour for all points.
colour_col <- "out_pillar"    # e.g. colour_col <- "category"

cfra.ethiopia
  ggplot() +
  
  # ADM1 fill (light grey provinces)
  geom_sf(data  = africa_adm1%>%
            filter(admin=="Ethiopia"),
          fill  = "#f5f0e8",
          colour = "#c8bfaf",
          linewidth = 0.25) +
  
  # Country borders (darker, thicker)
  geom_sf(data  = africa_countries%>%
            filter(sovereignt=="Ethiopia"),
          fill  = NA,
          colour = "#5a4a3a",
          linewidth = 0.6) +
  
  # Points
  {
    if (!is.null(colour_col)) {
      geom_sf(data  = points_sf%>%
                filter(country=="Ethiopia"),
              aes(colour = .data[[colour_col]]),
              size  = 2.5, alpha = 0.85)
    } else {
      geom_sf(data  = points_sf%>%
                filter(country=="Ethiopia"),
              colour = c("#d62728", "green","blue"),  # red – change as you like
              size   = 2.5, alpha  = 0.85)
    }
  } +
  
  # Coordinate limits (full Africa bounding box)
  #coord_sf(xlim = c(-20, 55), ylim = c(-36, 38), expand = FALSE) +
  
  # Theme
  theme_minimal(base_size = 12) +
  theme(
    panel.background = element_rect(fill = "#d0e8f2", colour = NA), # ocean
    panel.grid       = element_line(colour = "#b0cfe0", linewidth = 0.2),
    axis.title       = element_blank(),
    legend.position  = "right"
  ) +
  labs(
    title    = "Ethiopia",
    subtitle = "",
    colour   = colour_col,
    caption  = "Geodata: Natural Earth"
  )

print(cfra.countries)

# --- 5. Save to file ---
output_file <- "cfra_countries.png"   # change extension to .pdf / .svg if needed

ggsave("cfra_countries.png", plot = p,
       width = 10, height = 11, dpi = 300, bg = "white")

message("Map saved to: ", normalizePath(output_file))

#######################################################################
# ============================================================
# Donut-chart matrix: Agricultural practices × Impact areas
# ============================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(ggh4x)

# ------------------------------------------------------------------
# 1. DATA
# Each cell has a number (total studies) and a colour profile.
# The donuts show proportions of: positive (green), negative (red),
# neutral/mixed (yellow), and no-effect/unknown (grey).
# These proportions are estimated visually from the original figure.
# Replace the p_pos / p_neg / p_neu / p_none columns with real data
# if you have the underlying dataset.
# ------------------------------------------------------------------
CT_crop_FAO_Food_Group<- c("Cereals")

FAO_Food_Group_labels <- c(
  "Cereals"                                    = "Cereals",
  "Cereals..Leguminous crops"                  = "Cereals-Legumes",
  "Cereals..Oilseed crops and oleaginous fruits" = "Cereals-Oilcrops",
  "Cereals..Root tuber crops with high starch or inulin content" = "Cereals-Root tubers",
  "Fruit and nuts..Root tuber crops with high starch or inulin content..Stimulant, spice and aromatic crops..Sugar crops..Vegetables and melons" = "Mixed crops",
  "Leguminous crops"                           = "Legumes",
  "Oilseed crops and oleaginous fruits"        = "Oilcrops",
  "Root tuber crops with high starch or inulin content" = "Root tubers",
  "Stimulant, spice and aromatic crops"        = "Stimulant and Spice crops", ## ARREGLAR separar
  "Stimulant, spice and aromatic crops..Vegetables and melons" = "Stimulant and Spice crops-Vegetables",
  "Vegetables and melons"                      = "Vegetables"
)


practices <- c("Plant\nprotection",
               "Landscape\nfeatures\nmanagement",
               "Organic\nfarming",
               "Water\nmanagement",
               "Manure\nmanagement",
               "Animal\nhusbandry",
               "Crop rotation\nand\ndiversification",
               "Fertilisation\nand soil\namendments",
               "Grassland\nand grazing",
               "Soil\nmanagement")

impacts <- c("Pollution",
             "Sustainable\nuse of\nresources",
             "Biodiversity",
             "Carbon\nsequestration",
             "Agricultural\nproduction",
             "Soil health",
             "GHG\nemissions")

# Cell data: practice, impact, n, %positive, %negative, %neutral, %none
# Estimated proportions sum to 1; NA = cell is empty in the original
raw <- tribble(
  ~practice,                ~impact,                     ~n,   ~pos,  ~neg,  ~neu,  ~none,
  "Plant\nprotection",       "Pollution",                  4,   0.25,  0.50,  0.25,  0.00,
  "Landscape\nfeatures\nmanagement","Pollution",          125,  0.60,  0.10,  0.20,  0.10,
  "Organic\nfarming",        "Pollution",                 33,   0.55,  0.15,  0.20,  0.10,
  "Water\nmanagement",       "Pollution",                 17,   0.30,  0.30,  0.20,  0.20,
  "Manure\nmanagement",      "Pollution",                 85,   0.20,  0.55,  0.15,  0.10,
  "Animal\nhusbandry",       "Pollution",                 86,   0.25,  0.40,  0.25,  0.10,
  "Crop rotation\nand\ndiversification","Pollution",      25,   0.50,  0.15,  0.25,  0.10,
  "Fertilisation\nand soil\namendments","Pollution",     170,   0.15,  0.60,  0.15,  0.10,
  "Grassland\nand grazing",  "Pollution",                 14,   0.40,  0.30,  0.20,  0.10,
  "Soil\nmanagement",        "Pollution",                 83,   0.45,  0.25,  0.20,  0.10,
  
  "Landscape\nfeatures\nmanagement","Sustainable\nuse of\nresources", 2, 0.50,0.10,0.30,0.10,
  "Organic\nfarming",        "Sustainable\nuse of\nresources",        31, 0.55,0.10,0.25,0.10,
  "Water\nmanagement",       "Sustainable\nuse of\nresources",       352, 0.55,0.10,0.25,0.10,
  "Manure\nmanagement",      "Sustainable\nuse of\nresources",        24, 0.30,0.20,0.30,0.20,
  "Animal\nhusbandry",       "Sustainable\nuse of\nresources",        35, 0.35,0.25,0.25,0.15,
  "Crop rotation\nand\ndiversification","Sustainable\nuse of\nresources",21,0.55,0.10,0.25,0.10,
  "Fertilisation\nand soil\namendments","Sustainable\nuse of\nresources",62,0.30,0.25,0.25,0.20,
  "Grassland\nand grazing",  "Sustainable\nuse of\nresources",         1, 0.50,0.10,0.30,0.10,
  "Soil\nmanagement",        "Sustainable\nuse of\nresources",       102, 0.50,0.15,0.25,0.10,
  
  "Plant\nprotection",       "Biodiversity",              77,   0.30,  0.45,  0.15,  0.10,
  "Landscape\nfeatures\nmanagement","Biodiversity",      203,   0.65,  0.10,  0.15,  0.10,
  "Organic\nfarming",        "Biodiversity",              83,   0.60,  0.10,  0.20,  0.10,
  "Crop rotation\nand\ndiversification","Biodiversity",  40,   0.55,  0.10,  0.25,  0.10,
  "Fertilisation\nand soil\namendments","Biodiversity",   3,   0.20,  0.50,  0.20,  0.10,
  "Grassland\nand grazing",  "Biodiversity",             109,   0.55,  0.15,  0.20,  0.10,
  "Soil\nmanagement",        "Biodiversity",              49,   0.50,  0.15,  0.25,  0.10,
  
  "Landscape\nfeatures\nmanagement","Carbon\nsequestration",112, 0.60,0.10,0.20,0.10,
  "Organic\nfarming",        "Carbon\nsequestration",     32,   0.50,  0.15,  0.25,  0.10,
  "Water\nmanagement",       "Carbon\nsequestration",      2,   0.30,  0.40,  0.20,  0.10,
  "Fertilisation\nand soil\namendments","Carbon\nsequestration",66,0.40,0.25,0.25,0.10,
  "Grassland\nand grazing",  "Carbon\nsequestration",     77,   0.50,  0.20,  0.20,  0.10,
  "Soil\nmanagement",        "Carbon\nsequestration",    167,   0.60,  0.10,  0.20,  0.10,
  "Fertilisation\nand soil\namendments","Carbon\nsequestration",48,0.40,0.25,0.25,0.10,
  
  "Plant\nprotection",       "Agricultural\nproduction",  56,   0.35,  0.30,  0.25,  0.10,
  "Landscape\nfeatures\nmanagement","Agricultural\nproduction",48, 0.40,0.20,0.25,0.15,
  "Organic\nfarming",        "Agricultural\nproduction",  85,   0.35,  0.30,  0.25,  0.10,
  "Water\nmanagement",       "Agricultural\nproduction", 394,   0.65,  0.10,  0.15,  0.10,
  "Crop rotation\nand\ndiversification","Agricultural\nproduction",77,0.60,0.10,0.20,0.10,
  "Fertilisation\nand soil\namendments","Agricultural\nproduction",173,0.55,0.15,0.20,0.10,
  "Grassland\nand grazing",  "Agricultural\nproduction", 119,   0.45,  0.25,  0.20,  0.10,
  "Soil\nmanagement",        "Agricultural\nproduction", 237,   0.55,  0.15,  0.20,  0.10,
  "Fertilisation\nand soil\namendments","Agricultural\nproduction",55,0.35,0.25,0.25,0.15,
  
  "Plant\nprotection",       "Soil health",               28,   0.25,  0.35,  0.25,  0.15,
  "Landscape\nfeatures\nmanagement","Soil health",       178,   0.60,  0.10,  0.20,  0.10,
  "Organic\nfarming",        "Soil health",               16,   0.60,  0.10,  0.20,  0.10,
  "Water\nmanagement",       "Soil health",               24,   0.40,  0.20,  0.25,  0.15,
  "Fertilisation\nand soil\namendments","Soil health",  123,   0.40,  0.25,  0.25,  0.10,
  "Grassland\nand grazing",  "Soil health",              340,   0.55,  0.10,  0.25,  0.10,
  "Soil\nmanagement",        "Soil health",              122,   0.55,  0.15,  0.20,  0.10,
  "Fertilisation\nand soil\namendments","Soil health",  385,   0.50,  0.15,  0.25,  0.10,
  
  "Plant\nprotection",       "GHG\nemissions",             3,   0.20,  0.40,  0.25,  0.15,
  "Landscape\nfeatures\nmanagement","GHG\nemissions",   152,   0.55,  0.10,  0.25,  0.10,
  "Organic\nfarming",        "GHG\nemissions",            36,   0.45,  0.20,  0.25,  0.10,
  "Water\nmanagement",       "GHG\nemissions",            68,   0.30,  0.35,  0.25,  0.10,
  "Manure\nmanagement",      "GHG\nemissions",           109,   0.20,  0.55,  0.15,  0.10,
  "Animal\nhusbandry",       "GHG\nemissions",           145,   0.25,  0.45,  0.20,  0.10,
  "Crop rotation\nand\ndiversification","GHG\nemissions", 15,  0.50,  0.15,  0.25,  0.10,
  "Fertilisation\nand soil\namendments","GHG\nemissions",159,  0.20,  0.50,  0.20,  0.10,
  "Grassland\nand grazing",  "GHG\nemissions",            39,   0.40,  0.25,  0.25,  0.10,
  "Soil\nmanagement",        "GHG\nemissions",           150,   0.50,  0.15,  0.25,  0.10
)

# ------------------------------------------------------------------
# 2. TIDY: pivot proportions to long format, deduplicate
# ------------------------------------------------------------------
df <- raw_diversification %>%
  distinct(CT_crop_FAO_Food_Group_label ,
           practice,
           #nutrient_management,
           #water_management,
           
           impact, .keep_all = TRUE) %>%
  pivot_longer(cols = c(pos, neg#, neu, none
                        ),
               names_to  = "outcome",
               values_to = "proportion") 
  filter(CT_crop_FAO_Food_Group_label=="Cereals")
  mutate(CT_crop_FAO_Food_Group = recode(CT_crop_FAO_Food_Group, !!!FAO_Food_Group_labels))

  mutate(
    CT_crop_FAO_Food_Group = factor(CT_crop_FAO_Food_Group, levels = CT_crop_FAO_Food_Group))
    practice = factor(practice, levels = practices),
    impact   = factor(impact,   levels = rev(impacts)),   # rev so top row = first level
    outcome  = factor(outcome,  levels = c("pos",#"neu",
                                           "neg"#,"none"
                                           ))
  )

# ------------------------------------------------------------------
# 3. BUILD DONUTS via polar coordinates
#    Each donut is drawn as a stacked bar in polar coords, faceted.
# ------------------------------------------------------------------
colours <- c(pos  = "#4CAF50",   # green
             #neu  = "#FFC107",   # amber
             neg  = "#E53935"#,   # red
             #none = "#BDBDBD"
             )   # grey

ggplot(df, aes(x = 2, y = proportion, fill = outcome)) +
  geom_col(width = 0.9, colour = "white", linewidth = 0.3) +
  coord_polar(theta = "y", start = -pi / 2, direction = 1, clip = "on") +
  #xlim(0.5, 2.5) +                          # 0.5 = hole size.
  scale_x_continuous(limits = c(0.5, 2.5), expand = c(0, 0))+
  scale_y_continuous(expand = c(0, 0))+

  #facet_grid( CT_crop_FAO_Food_Group~diversification_spatial~impact ,
   #          switch = "both") +             # labels on left & bottom
  facet_grid2(
    rows = vars(CT_crop_FAO_Food_Group_label,
                practice),
    cols = vars(impact),   # two variables on columns side
    switch = "both",
    drop   = TRUE,                   # skip empty combos → no gaps
    independent = "none"             # or "all" if you want free scales
  ) +
  
  scale_fill_manual(
    values = colours,
    labels = c(pos = "Positive",# neu = "Neutral / mixed",
               neg = "Negative"#, none = "No effect / unknown"
               ),
    name   = NULL
  ) +
  # study-count label in the centre of each donut
  geom_text(
    data = distinct(df, 
                    CT_crop_FAO_Food_Group_label,
                    practice, impact, n),
    aes(x = 0.5, y = 0, label = n),
    inherit.aes = FALSE,
    size = 5, fontface = "bold", colour = "#333333"
  ) +
  theme_void(base_size = 9) +
  theme(
    strip.text.x    = element_text(size = 12,  angle = 0, hjust = 0,
                                   vjust = 1,  margin = margin(b = 4)),
    strip.text.y    = element_text(size = 12,  angle = 0,  hjust = 1,
                                   margin = margin(r = 6)),
    strip.placement = "outside",
    legend.position = "bottom",
    legend.text     = element_text(size = 10),
    legend.key.size = unit(0.45, "cm"),
    plot.margin     = margin(t = 5, r = 5, b = 5, l = 5),
    panel.spacing   = unit(0.15, "cm"),
    plot.title      = element_text(size = 10, face = "bold", hjust = 0.5,
                                   margin = margin(b = 6))
  ) 
  labs(title = "Number of studies and their outcomes by agricultural practice and impact area")
p
# ------------------------------------------------------------------
# 4. SAVE
# ------------------------------------------------------------------
ggsave(
  filename = "/mnt/user-data/outputs/donut_matrix.png",
  plot     = p,
  width    = 14,
  height   = 8,
  dpi      = 180,
  bg       = "white"
)

message("Saved → /mnt/user-data/outputs/donut_matrix.png")
