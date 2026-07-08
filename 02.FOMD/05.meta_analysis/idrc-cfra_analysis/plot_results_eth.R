# =============================================================================
# Cereals sustainable-practice effects: a ministry/NGO-friendly summary
# =============================================================================
# WHAT THIS SCRIPT DOES
# The raw CSV records meta-analysis comparisons where up to four practice
# "themes" (diversification, biomass management, nutrient management, soil
# management) can each be held constant OR changed between a Control (C) and
# Treatment (T) group, for a given outcome (impact). Many rows change more
# than one theme at once (e.g. tillage AND fertiliser AND rotation all
# differ simultaneously) - those rows are CONFOUNDED and cannot be
# attributed to a single practice, so they are excluded from the summary.
# The remaining "clean" rows - where exactly one theme changed - are grouped
# into policy-relevant practice categories, direction-normalised, and
# aggregated (weighted by sample size n) into a practice x outcome matrix.
#
# IMPORTANT ASSUMPTION TO VERIFY AGAINST YOUR CODEBOOK:
# This script assumes `pos` = share of comparisons finding a BENEFICIAL
# effect for that outcome (e.g. pos on Costs = costs went down, pos on
# Yield = yield went up) - i.e. already sign-adjusted by the original
# reviewers. If your source instead defines pos as "the raw metric value
# increased" regardless of desirability, invert the Costs and Labour columns
# before use.
# =============================================================================

library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(forcats)
library(terra)

# ---- 0. Load data -----------------------------------------------------------
path.metadata.effectsize<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/04.metadata_effectsize"
path.metaanalysis<- "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/05.meta_analysis/idrc-cfra_analysis"

raw <- read.csv(file.path(path.metadata.effectsize, "/cereals_effects_eth.csv"), stringsAsFactors = FALSE, check.names = TRUE)

sort(unique(raw$nutrient_management_practice))
sort(unique(raw$impact))

# NB: the "NA" column name in the source CSV is a literal proportion column,
# not a missing-data marker - R will likely rename it to "NA." on import.

theme_cols <- c("nutrient_management_practice",
                "water_management_practice",
                
                "soil_management_theme",
                "diversification_spatial_temporal_theme",
                "biomass_management_practice"
                
)

# ---- 1. Parse "C: x_vs_T: y" strings ----------------------------------------

parse_ct <- function(x) {
  if (is.na(x) || x == "NA" || x == "") return(NULL)
  parts <- str_split(x, ";\\s*")[[1]]
  m <- str_match(parts, "^C:\\s*(.*?)_vs_T:\\s*(.*)$")
  m[!is.na(m[, 1]), 2:3, drop = FALSE]
}

# For each row, find which theme(s) actually changed (C != T, ignoring NA)
find_changed <- function(row) {
  changed <- list()
  for (col in theme_cols) {
    ct <- parse_ct(row[[col]])
    if (is.null(ct)) next
    for (i in seq_len(nrow(ct))) {
      c_val <- ct[i, 1]; t_val <- ct[i, 2]
      if (c_val != t_val) changed[[length(changed) + 1]] <- c(col, c_val, t_val)
    }
  }
  changed
}

raw$row_id <- seq_len(nrow(raw))
changed_list <- lapply(seq_len(nrow(raw)), function(i) find_changed(raw[i, ]))
n_changed <- vapply(changed_list, length, integer(1))

clean_rows <- which(n_changed == 1)
cat(sprintf(
  "Single-practice (clean) comparisons: %d | Confounded (2+ practices changed) excluded: %d\n",
  length(clean_rows), sum(n_changed > 1)
))


#########################################
# Use ALL changed themes per row (not just rows where exactly 1 changed).
# Each theme that changed gets its own row, crediting that row's outcome
# to it independently — i.e. assume practices were implemented separately.
all_changed_rows <- which(n_changed >= 1)

single <- lapply(all_changed_rows, function(i) {
  ch <- changed_list[[i]]
  tibble(
    row_id = raw$row_id[i],
    theme  = vapply(ch, `[`, character(1), 1),
    c_val  = vapply(ch, `[`, character(1), 2),
    t_val  = vapply(ch, `[`, character(1), 3)
  )
}) %>%
  bind_rows() %>%
  left_join(raw %>% select(row_id, impact, n, pos, neg), by = "row_id")


# ---- 2. Map (theme, C, T) -> readable practice label, with direction flip --
# EDIT THIS TABLE to relabel, regroup, or add newly-appearing categories.
# `flip = TRUE` means the row's C/T direction is reversed relative to the
# "adopt the sustainable practice" direction, so pos/neg are swapped.

practice_map <- tribble(
  ~theme, ~c_val, ~t_val, ~practice, ~flip,
  "nutrient_management_practice", "No Fertilizers Applied", "Inorganic Fertilizer", "Inorganic fertilizer", FALSE,
  "nutrient_management_practice", "No Fertilizers Applied", "Inorganic and Organic Fertilizers", "Mixed fertilizer", FALSE,
  "nutrient_management_practice", "No Fertilizers Applied", "Organic Fertilizer + Inorganic Fertilizer", "Mixed fertilizer", FALSE,
  
  "nutrient_management_practice", "No Fertilizers Applied", "Organic Fertilizer", "Organic fertilizer", FALSE,
  "nutrient_management_practice", "No Fertilizers Applied", "Biochar", "Biochar amendment", FALSE,
  "nutrient_management_practice", "No Fertilizers Applied", "Biochar + Inorganic Fertilizer", "Biochar amendment", FALSE,
  "nutrient_management_practice", "No Fertilizers Applied", "Biochar + Inorganic Fertilizer + Organic Fertilizer", "Mixed fertilizer", FALSE,
  "nutrient_management_practice", "No Fertilizers Applied", "Biochar + Organic Fertilizer", "Biochar amendment", FALSE,
  
  #"nutrient_management_practice", "Organic Fertilizer", "Inorganic and Organic Fertilizers", "Mixed fertilizer", FALSE,
  
  "soil_management_theme", "Conventional Tillage", "Reduced Tillage", "Reduced tillage", FALSE,
  "soil_management_theme", "Reduced Tillage", "Conventional Tillage", "Reduced tillage", TRUE,
  "soil_management_theme", "Conventional Tillage", "Zero Tillage", "Zero tillage", FALSE,
  "soil_management_theme", "Zero Tillage", "Conventional Tillage", "Zero tillage", TRUE,
  
  "biomass_management_practice", "Crop residues removed", "Organic mulch (unspecified)", "Mulching", FALSE,
  "biomass_management_practice", "Crop residues removed", "Organic mulch (herbaceus)", "Mulching", FALSE,
  "biomass_management_practice", "Crop residues removed", "Organic mulch (woody/other)", "Mulching", FALSE,
  "biomass_management_practice", "Crop residues removed", "Crop residues incorporated", "Residues incorporated", FALSE,
  "biomass_management_practice", "Crop residues removed", "Crop residues retained", "Residues reteined", FALSE,
  "biomass_management_practice", "Crop residues removed", "Tree pruning incorporated", "Residues incorporated", FALSE,
  "biomass_management_practice", "Crop residues grazed", "Crop residues incorporated", "Residues incorporated", FALSE,
  "biomass_management_practice", "Organic mulch (herbaceus)", "Crop residues removed", "Mulching", TRUE,
  
  "diversification_spatial_temporal_theme", "Monoculture", "Intercropping", "Intercropping", FALSE,
  "diversification_spatial_temporal_theme", "Monoculture", "Intercropping + Green manure", "Intercropping", FALSE,
  "diversification_spatial_temporal_theme", "Monoculture", "Agroforestry", "Agroforestry", FALSE,
  "diversification_spatial_temporal_theme", "Monoculture", "Green manure", "Green manure", FALSE,
  "diversification_spatial_temporal_theme", "Monoculture","Crop rotation","Crop rotation",FALSE,
  
  "water_management_practice","Deficit Irrigation","Full irrigation","Deficit irrigation",TRUE,
  "water_management_practice","Full irrigation","Deficit Irrigation","Deficit irrigation",FALSE,
  "water_management_practice","Full irrigation","Supplemental Irrigation","Supplemental irrigation",FALSE
  
)

# Assign each practice to a broader theme group, for the facet strips
practice_group <- tribble(
  ~practice, ~group,
  "Inorganic fertilizer",           "Fertility management",
  "Organic fertilizer",             "Fertility management",
  "Mixed fertilizer",          "Fertility management",
  "Biochar amendment",              "Fertility management",
  "Reduced tillage",                "Tillage",
  "Zero tillage",                   "Tillage",
  
  "Agroforestry",                   "Diversification",
  "Crop rotation",  "Diversification",
  "Green manure",                   "Diversification",
  "Intercropping",                  "Diversification",
  
  "Mulching",               "Residue management",
  "Residues incorporated","Residue management",
  "Residues reteined",   "Residue management",
  
  "Deficit irrigation","Water management",
  "Supplemental irrigation","Water management"
)

# ---- 3. Map outcome (impact) -> standardised metric -------------------------
# EDIT to add/rename outcomes. Outcomes not listed here are dropped from the
# summary (e.g. rare categories like Pest & Pathogen, Emissions, Biodiversity
# with very few observations for this crop group) - add them back in if your
# audience wants them and there's enough data to support a claim.
metric_map <- tribble(
  ~impact,                ~metric,          ~invert_good,
  "Product Yield",        "Yield",          FALSE,
  "Efficiency",           "Efficiency",     FALSE,
  "Labour",               "Labour",         FALSE,  # <- check this: less labour is usually the goal
  
  "Costs",                "Costs",          TRUE,   # lower cost = good
  "Income",                "Income",         FALSE,
  "Economic Performance", "Profitability",  FALSE,
  
  "Soil Quality",         "Soil health",    FALSE,
  #"Carbon stocks",       "Carbon stocks",  FALSE,  # <- probably TRUE if you re-enable it
  "Emissions",            "GHG emissions",  TRUE   # lower emissions = good
  #"Biodiversity",        "Biodiversity",   FALSE
)

# ---- 4. Join, flip direction, aggregate (n-weighted) -------------------------
agg <- single %>%
  inner_join(practice_map, by = c("theme", "c_val", "t_val")) %>%
  inner_join(practice_group, by = "practice") %>%
  inner_join(metric_map, by = "impact") %>%
  mutate(
    control_display   = if_else(flip, t_val, c_val),
    treatment_display = if_else(flip, c_val, t_val),
    pos_adj           = if_else(flip, neg, pos),
    # NEW: for metrics where an increase is undesirable (Costs, GHG
    # emissions, etc.), flip pos_adj so it always means "% of comparisons
    # in the DESIRABLE direction" — consistent with Yield/Income/etc.
    pos_adj           = if_else(invert_good, 1 - pos_adj, pos_adj),
    control_display   = recode(control_display,"Crop residues grazed" = "Residues removed"),
    control_display   = recode(control_display,"Crop residues removed" = "Residues removed")
  ) %>%
  group_by(group, control_display, practice, metric)%>%
  summarise(
    weighted_pos = sum(pos_adj * n) / sum(n),
    total_n      = sum(n),
    k_studies    = n(),
    .groups = "drop"
  )

# ---- 5. Classify into interpretable bands -----------------------------------
# Thresholds are a judgement call - tune for your audience/context.

agg <- agg %>%
  mutate(
    category = case_when(
      weighted_pos >= 0.65 & total_n >= 100 ~ "Strong positive",  # >=65% positive, n>=100
      weighted_pos >= 0.65                  ~ "Positive",         # >=65% positive, n<100
      weighted_pos > 0.35 & total_n >= 100 ~ "Strong neutral",   # 46-64% positive, n>=100
      weighted_pos > 0.35                  ~ "Neutral",          # 46-64% positive, n<100
      weighted_pos <= 0.35 & total_n >= 100 ~ "Strong negative",  # >=65% negative, n>=100
      weighted_pos <= 0.35                  ~ "Negative",         # >=65% negative, n<100
      
      
      total_n >= 100                        ~ "Strong neutral",   # 36-45% positive, n>=100 -> falls back to neutral
      TRUE                                  ~ "Neutral"           # 36-45% positive, n<100  -> falls back to neutral
    ),
    pct_shown = if_else(category %in% c("Strong negative", "Negative"),
                        (1 - weighted_pos) * 100,
                        weighted_pos * 100),
    label = paste0(round(pct_shown), "%")
  )

# ---- 6. Order rows/columns for a clean layout --------------------------------
practice_order <- c(
  "Deficit irrigation","Supplemental irrigation",
  "Mulching",    "Residues incorporated","Residues reteined",   
  "Inorganic fertilizer", "Organic fertilizer", "Mixed fertilizer", 
  "Reduced tillage", "Zero tillage","Biochar amendment",
  "Agroforestry", "Green manure","Intercropping","Crop rotation"
  
)
metric_order <- c("Yield","Efficiency" , "Labour","Costs", "Income", "Profitability",
                  "Soil health")#, "Carbon stocks")

agg <- agg %>%
  mutate(practice_ct= paste0(practice," vs. " , control_display))%>%
  mutate(
    practice = factor(practice, levels = rev(practice_order)),
    metric   = factor(metric, levels = metric_order)
  )

# ---- 6b. Expose evidence gaps: complete the practice x metric grid ---------
# Every (group, practice_ct) combo should show a cell for every metric,
# even if there's no data for it. Without this, missing combos are just
# blank background - indistinguishable from a neutral/mixed result.

all_combos <- agg %>%
  distinct(group, practice, practice_ct) %>%
  tidyr::crossing(metric = factor(metric_order, levels = metric_order))

agg <- all_combos %>%
  left_join(agg, by = c("group", "practice", "practice_ct", "metric")) %>%
  mutate(
    category = if_else(is.na(category), "No data", category),
    label    = if_else(is.na(label), "No data", label),
    n_label  = case_when(
      is.na(total_n)          ~ "",
      total_n == 1            ~ paste0("n= ", total_n),
      TRUE                    ~ paste0("n= ", total_n)
    )
  )

category_order <- c("Strong negative", "Negative", "Neutral", "Strong neutral",
                    "Positive", "Strong positive", "No data")

agg <- agg %>%
  mutate(category = factor(category, levels = category_order))

# ---- 6c. Confidence rating: how much evidence sits behind each %  ----------
# Banded on total_n (not k_studies) so the rating agrees with the sample-size
# text printed under each cell. Stored as an integer (0-3), not a glyph
# string - the dots themselves get drawn with geom_point() in Step 7, which
# is font-independent and won't silently fail on Windows like embedded
# unicode circle characters can.

agg <- agg %>%
  mutate(
    confidence_n = case_when(
      is.na(total_n) ~ 0L,
      total_n >= 300  ~ 3L,
      total_n >= 100   ~ 2L,
      TRUE            ~ 1L
    )
  )

agg <- agg %>%
  mutate(
    low_n = !is.na(total_n) & total_n <= 2,
    label = if_else(low_n & category != "No data", paste0(label, "*"), label)
  )

# ---- 6c-2. Flag cells to emphasize: strong positive AND well-supported ------
agg <- agg %>%
  mutate(
    emphasis = category %in% c("Strong positive", "Positive", "Negative", "Strong negative") &
      confidence_n %in% c(2, 3)  )


# ---- 7. Plot ------------------------------------------------------------------
category_labels <- c(
  "Strong negative" = "Negative (\u226565% negative) \u2013 strong evidence (n\u2265100)",
  "Negative"         = "Negative (\u226565% negative) \u2013 limited evidence (n<100)",
  "Strong neutral"   = "Neutral (36-64% positive) \u2013 strong evidence (n\u2265100)",
  "Neutral"          = "Neutral (36-64% positive) \u2013 limited evidence (n<100)",
  "Strong positive"  = "Positive (\u226565% positive) \u2013 strong evidence (n\u2265100)",
  "Positive"         = "Positive (\u226565% positive) \u2013 limited evidence (n<100)",
  "No data"          = "No data"
)
fill_colors <- c(
  "Strong positive" = "#556B2F",
  "Positive"         = "#66CD00",
  "Strong neutral"   = "grey55",
  "Neutral"          = "grey85",
  "Negative"         = "#ff99a6",
  "Strong negative"  = "#CD0000",
  "No data"          = "#EAE7DC"
)
text_colors <- c(
  "Strong positive" = "white",
  "Positive"         = "#173404",
  "Strong neutral"   = "white",
  "Neutral"          = "#444441",
  "Negative"         = "#444441",
  "Strong negative"  = "white",
  "No data"          = "#A6A08F"
)

eth_cereals <- ggplot(agg, aes(x = metric, y = practice, fill = category)) +
  
  
  geom_tile(aes(linetype = category == "No data", alpha = factor(confidence_n)),
            color = "white", linewidth = 1, width = 0.93, height = 0.85) +
  scale_alpha_manual(values = c(`0` = 1, `1` = 0.5, `2` = 1, `3` = 1), 
                     guide = "none")+
  
  
  # emphasized labels: strong positive + high confidence -> bigger + bold
  geom_text(data = subset(agg, emphasis),
            aes(label = label, color = category),
            vjust = -0.55, size = 5, fontface = "bold") +
  # normal labels: everything else with data, not emphasized
  geom_text(data = subset(agg, category != "No data" & !emphasis),
            aes(label = label, color = category),
            vjust = -0.55, size = 4, fontface = "plain") +
  # "No data" labels - smallest, not bold
  geom_text(data = subset(agg, category == "No data"),
            aes(label = label, color = category),
            vjust = -0.55, size = 3.2, fontface = "plain") +
  geom_text(aes(label = n_label, color = category),
            vjust = 1.1, size = 2.8) +
  
  # FIX 4: small dot cluster (1-3 dots) in the corner of each data cell,
  # giving a second, non-color-dependent read on sample size at a glance -
  # helpful for anyone skimming the grid without reading every n_label.
  geom_text(data = subset(agg, category != "No data"),
            aes(label = strrep("\u25CF", confidence_n)),
            color = "grey40", size = 2.1, hjust = 1, vjust = -1.4,
            nudge_x = 0.42) +
  
  scale_fill_manual(values = fill_colors, name = NULL,
                    breaks = category_order,
                    labels = category_labels[category_order]) +
  scale_color_manual(values = text_colors, guide = "none") +
  
  # FIX 5: suppress the automatic TRUE/FALSE legend that `linetype` creates.
  # This is almost certainly what produced the stray
  # "category == 'No data'  FALSE / TRUE" legend chip in your last version -
  # it's ggplot's default legend for a boolean aesthetic, not a bug in the
  # data. Hiding it removes that debug-looking artifact from the slide.
  guides(linetype = "none",
         fill = guide_legend(nrow = 1, byrow = TRUE)) +
  
  scale_x_discrete(position = "top") +
  facet_grid(group ~ ., scales = "free_y", space = "free_y", switch = "y") +
  
  # FIX 6: title/subtitle/caption re-enabled. For a Ministry/NGO audience,
  # a one-line takeaway matters more than the grid itself - people anchor on
  # the headline. Edit the wording to match your actual top-line finding.
  labs(
    x = NULL, y = NULL
  ) +
  theme_minimal(base_size = 13) +
  theme(
    legend.position = "bottom",
    panel.grid = element_blank(),
    axis.text.x = element_text(face = "bold", size = 11),
    axis.text.y = element_text(size = 11, hjust = 1),
    axis.ticks = element_blank(),
    strip.placement = "outside",
    strip.text.y.left = element_text(angle = 0, face = "bold", size = 10, hjust = 1),
    plot.background = element_rect(fill = "#faf9f6", color = NA),
    panel.background = element_rect(fill = "#faf9f6", color = NA),
    plot.margin = margin(20, 25, 20, 10),
    legend.text = element_text(size = 9)
  )

print(eth_cereals)

ggsave(paste0(path.metaanalysis,"/plot.eth.cereals.heatmap.pdf"), plot = eth_cereals,
       width = 20, height = 15, dpi = 300, bg = "white")

#-----------------------------------------------------
#####-----ANALYSIS PER AGROECOLOGICAL ZONE -----------
#-----------------------------------------------------
eth.cereals <- read.csv(file.path(path.metadata.effectsize, "/cereals_df_eth.csv"), stringsAsFactors = FALSE, check.names = TRUE)

effect_size_expand_sites <- function(df, country_col, lat_col, lon_col, effect_size_id) {
  df %>%
    select(country = {{ country_col }},
           lat_str = {{ lat_col }},
           lon_str = {{ lon_col }},
           effect_size_id=effect_size_id
    ) %>%
    mutate(effect_size_id=effect_size_id,
           row_id = row_number()) %>%
    rowwise() %>%
    mutate(
      lats = list(parse_coords(lat_str)),
      lons = list(parse_coords(lon_str))
    ) %>%
    ungroup() %>%
    mutate(coords = map2(lats, lons, ~ tibble(lat = .x, lon = .y))) %>%
    select(row_id, country, 
           effect_size_id, 
           coords) %>%
    unnest(coords)
}
parse_coords <- function(coord_str) {
  str_split(coord_str, fixed(".."))[[1]] %>% as.numeric()
}
effect_size_x <- eth.cereals %>%
  select(C_country, C_site_latitude, C_site_longitude,effect_size_id)%>%
  distinct(C_country,
           C_site_latitude,
           C_site_longitude,
           effect_size_id  ) 

effect_sizes_control_pts<-effect_size_expand_sites(
  effect_size_x, C_country, C_site_latitude, C_site_longitude, effect_size_id)%>%
  filter(!is.na(lat), !is.na(lon))

# --- Agroecological zones----
eth.agr.zn <- rast(paste0(path.metaanalysis,"/GAEZ/GAEZ_AEZ57_ETH.tif"))
gaez.lookup <- read.csv(paste0(path.metaanalysis,"/GAEZ/GAEZ_57_lookup.csv"),
                        stringsAsFactors = FALSE)
names(eth.agr.zn) <- "value"     # standardize the layer name

# ---- 1. Named list linking each country to its GAEZ raster --------------
gaez_rasters <- list("Ethiopia" = eth.agr.zn)

# 2. Helper: extract the raster "value" at each site for one country -
extract_zone_value <- function(country_name, raster, points_df) {
  pts <- points_df %>% filter(country == country_name)
  if (nrow(pts) == 0) return(pts %>% mutate(value = numeric(0)))
  
  pts_vect <- vect(pts, geom = c("lon", "lat"), crs = "EPSG:4326")
  
  # If the raster's CRS isn't EPSG:4326, reproject the points first:
  # pts_vect <- project(pts_vect, crs(raster))
  
  zone_vals <- terra::extract(raster, pts_vect)
  pts %>% mutate(value = zone_vals$value)
}

# ---- 2. Run the extraction for every country and combine -----------------
effect_sizes_with_zone <- imap_dfr(
  gaez_rasters,
  ~ extract_zone_value(.y, .x, effect_sizes_control_pts)
) %>%
  left_join(gaez.lookup, by = "value")

# 4. Flag any sites that fell outside a raster (e.g. masked pixels, ---
#    coastline rounding) instead of silently dropping them
effect_sizes_with_zone <- effect_sizes_with_zone %>%
  mutate(label = if_else(is.na(label), "No zone data (outside raster)", label))

# ---- 3. Count DISTINCT effect sizes per zone ------------------------------
# An effect size with multiple site coordinates that fall in different
# zones will be counted once in each zone it touches. If you'd rather
# assign each effect size to a single zone (e.g. its first site only),
# filter effect_sizes_control_pts down to one row per effect_size_id
# before running the extraction in step 3.
effect_sizes_per_zone <- effect_sizes_with_zone %>%
  group_by(label) %>%
  summarise(n_effect_sizes = n_distinct(effect_size_id)) %>%
  arrange(desc(n_effect_sizes))

eth.cereals1<-eth.cereals%>%
  left_join(effect_sizes_with_zone,by="effect_size_id")
filter(label%in%c(
  #"Tropics, highland; sub-humid, no soil/terrain limitations", # FERTILIZER HAD A POSITIVE SIGNIFICANT EFFECT
  #"Tropics, lowland; semi-arid, no soil/terrain limitations", #AGROFORESTRY HAD A NEGATIVE SIGNIFICANT EFFECT
  "Land with severe soil/terrain limitations",
  "Tropics, lowland; sub-humid, with soil/terrain limitations", # NO DATA ON ANY IMPORTANT PRACTICE
  "Tropics, highland; sub-humid, with soil/terrain limitations", # COULD BE
  "Tropics, highland; humid, with soil/terrain limitations" ,# COULD BE
  "Tropics, highland; semi-arid, with soil/terrain limitations"
))


eth.cereals.agr<-eth.cereals1%>%
  group_by(CT_crop_FAO_Food_Group_clean,
           diversification_spatial_temporal_theme,
           biomass_management_practice,
           nutrient_management_practice,
           soil_management_theme,
           active_groups,
           water_management_practice,
           out_indicator,
           label,
           effect_size_direction)%>%
  summarise(n_direction = n(), .groups = "drop")

sort(unique(eth.cereals.agr$out_indicator))

raw_eth.cereals.agr <- eth.cereals.agr %>%
  group_by(CT_crop_FAO_Food_Group_clean,
           diversification_spatial_temporal_theme,
           biomass_management_practice,
           nutrient_management_practice,
           soil_management_theme,
           active_groups,
           label,
           out_indicator) %>%
  mutate(n = sum(n_direction)) %>%
  ungroup() %>%
  mutate(prop = n_direction / n) %>%
  
  # Drop n_direction BEFORE pivoting so it doesn't prevent row collapse
  select(-n_direction) %>%
  
  pivot_wider(
    names_from  = effect_size_direction,
    values_from = prop,
    values_fill = 0
  ) %>%
  
  rename(
    agr_zone = label,
    impact   = out_indicator,
    pos = Positive,
    neg= Negative
  )


raw_eth.cereals.agr$row_id <- seq_len(nrow(raw_eth.cereals.agr))
changed_list <- lapply(seq_len(nrow(raw_eth.cereals.agr)), function(i) find_changed(raw_eth.cereals.agr[i, ]))
n_changed <- vapply(changed_list, length, integer(1))

clean_rows <- which(n_changed == 1)
cat(sprintf(
  "Single-practice (clean) comparisons: %d | Confounded (2+ practices changed) excluded: %d\n",
  length(clean_rows), sum(n_changed > 1)
))


all_changed_rows <- which(n_changed >= 1)

agr.zn.single <- lapply(all_changed_rows, function(i) {
  ch <- changed_list[[i]]
  tibble(
    row_id = raw_eth.cereals.agr$row_id[i],
    agr_zone = raw_eth.cereals.agr$agr_zone[i],
    theme  = vapply(ch, `[`, character(1), 1),
    c_val  = vapply(ch, `[`, character(1), 2),
    t_val  = vapply(ch, `[`, character(1), 3)
  )
}) %>%
  bind_rows() %>%
  left_join(raw_eth.cereals.agr %>% select(row_id, impact, n, pos, neg), by = "row_id")


# ---- 4. Join, flip direction, aggregate (n-weighted) -------------------------
agr.zn.agg <- agr.zn.single %>%
  inner_join(practice_map, by = c("theme", "c_val", "t_val")) %>%
  inner_join(practice_group, by = "practice") %>%
  inner_join(metric_map, by = "impact") %>%
  mutate(
    control_display   = if_else(flip, t_val, c_val),
    treatment_display = if_else(flip, c_val, t_val),
    pos_adj           = if_else(flip, neg, pos),
    # NEW: for metrics where an increase is undesirable (Costs, GHG
    # emissions, etc.), flip pos_adj so it always means "% of comparisons
    # in the DESIRABLE direction" — consistent with Yield/Income/etc.
    pos_adj           = if_else(invert_good, 1 - pos_adj, pos_adj),
    control_display   = recode(control_display,"Crop residues grazed" = "Residues removed"),
    control_display   = recode(control_display,"Crop residues removed" = "Residues removed")
  ) %>%
  group_by(group, agr_zone,control_display, practice, metric)%>%
  summarise(
    weighted_pos = sum(pos_adj * n) / sum(n),
    total_n      = sum(n),
    k_studies    = n(),
    .groups = "drop"
  )

# ---- 5. Classify into interpretable bands -----------------------------------
# Thresholds are a judgement call - tune for your audience/context.

agr.zn.agg <- agr.zn.agg %>%
  mutate(
    category = case_when(
      weighted_pos >= 0.65 & total_n >= 100 ~ "Strong positive",  # >=65% positive, n>=100
      weighted_pos >= 0.65                  ~ "Positive",         # >=65% positive, n<100
      weighted_pos > 0.35 & total_n >= 100 ~ "Strong neutral",   # 46-64% positive, n>=100
      weighted_pos > 0.35                  ~ "Neutral",          # 46-64% positive, n<100
      weighted_pos <= 0.35 & total_n >= 100 ~ "Strong negative",  # >=65% negative, n>=100
      weighted_pos <= 0.35                  ~ "Negative",         # >=65% negative, n<100
      
      
      total_n >= 100                        ~ "Strong neutral",   # 36-45% positive, n>=100 -> falls back to neutral
      TRUE                                  ~ "Neutral"           # 36-45% positive, n<100  -> falls back to neutral
    ),
    pct_shown = if_else(category %in% c("Strong negative", "Negative"),
                        (1 - weighted_pos) * 100,
                        weighted_pos * 100),
    label = paste0(round(pct_shown), "%")
  )

# ---- 6. Order rows/columns for a clean layout --------------------------------
practice_order <- c(
  "Deficit irrigation","Supplemental irrigation",
  "Mulching",    "Residues incorporated","Residues reteined",   
  "Inorganic fertilizer", "Organic fertilizer", "Mixed fertilizer", 
  "Reduced tillage", "Zero tillage","Biochar amendment",
  "Agroforestry", "Green manure","Intercropping","Crop rotation"
  
)
metric_order <- c("Yield","Efficiency" , "Labour","Costs", "Income", "Profitability",
                  "Soil health")#, "Carbon stocks")

agr.zn.agg <- agr.zn.agg %>%
  mutate(practice_ct= paste0(practice," vs. " , control_display))%>%
  mutate(
    practice = factor(practice, levels = rev(practice_order)),
    metric   = factor(metric, levels = metric_order)
  )

# ---- 6b. Expose evidence gaps: complete the practice x metric grid ---------
# Every (group, practice_ct) combo should show a cell for every metric,
# even if there's no data for it. Without this, missing combos are just
# blank background - indistinguishable from a neutral/mixed result.

all_combos <- agr.zn.agg %>%
  distinct(group, practice, practice_ct,agr_zone) %>%
  tidyr::crossing(metric = factor(metric_order, levels = metric_order))

agr.zn.agg <- all_combos %>%
  left_join(agr.zn.agg, by = c("group", "practice", "practice_ct", "metric","agr_zone")) %>%
  mutate(
    category = if_else(is.na(category), "No data", category),
    label    = if_else(is.na(label), "No data", label),
    n_label  = case_when(
      is.na(total_n)          ~ "",
      total_n == 1            ~ paste0("n= ", total_n),
      TRUE                    ~ paste0("n= ", total_n)
    )
  )

category_order <- c("Strong negative", "Negative", "Neutral", "Strong neutral",
                    "Positive", "Strong positive", "No data")

agr.zn.agg <- agr.zn.agg %>%
  mutate(category = factor(category, levels = category_order))

# ---- 6c. Confidence rating: how much evidence sits behind each %  ----------
# Banded on total_n (not k_studies) so the rating agrees with the sample-size
# text printed under each cell. Stored as an integer (0-3), not a glyph
# string - the dots themselves get drawn with geom_point() in Step 7, which
# is font-independent and won't silently fail on Windows like embedded
# unicode circle characters can.

agr.zn.agg <- agr.zn.agg %>%
  mutate(
    confidence_n = case_when(
      is.na(total_n) ~ 0L,
      total_n >= 300  ~ 3L,
      total_n >= 100   ~ 2L,
      TRUE            ~ 1L
    )
  )

agr.zn.agg <- agr.zn.agg %>%
  mutate(
    low_n = !is.na(total_n) & total_n <= 2,
    label = if_else(low_n & category != "No data", paste0(label, "*"), label)
  )

# ---- 6c-2. Flag cells to emphasize: strong positive AND well-supported ------
agr.zn.agg <- agr.zn.agg %>%
  mutate(
    emphasis = category %in% c("Strong positive", "Positive", "Negative", "Strong negative") &
      confidence_n %in% c(2, 3)  )

# ---- 7. Plot ------------------------------------------------------------------
eth_cereals_agr_zn<-
  ggplot(agr.zn.agg%>%
           #filter(agr_zone=="Land with severe soil/terrain limitations"),
           #filter(agr_zone=="Tropics, highland; sub-humid, with soil/terrain limitations"),
           filter(agr_zone=="Tropics, highland; humid, with soil/terrain limitations" ),
         
         aes(x = metric, y = practice, fill = category)) +
  
  
  geom_tile(aes(linetype = category == "No data", alpha = factor(confidence_n)),
            color = "white", linewidth = 1, width = 0.93, height = 0.85) +
  scale_alpha_manual(values = c(`0` = 1, `1` = 0.5, `2` = 1, `3` = 1), 
                     guide = "none")+
  # emphasized labels: strong positive + high confidence -> bigger + bold
  geom_text(data = subset(agr.zn.agg%>%
                            #filter(agr_zone=="Land with severe soil/terrain limitations"),
                            #filter(agr_zone=="Tropics, highland; sub-humid, with soil/terrain limitations"),
                            filter(agr_zone=="Tropics, highland; humid, with soil/terrain limitations" ),
                          
                          emphasis),
            aes(label = label, color = category),
            vjust = -0.55, size = 5, fontface = "bold") +
  # normal labels: everything else with data, not emphasized
  geom_text(data = subset(agr.zn.agg%>%
                            #filter(agr_zone=="Land with severe soil/terrain limitations"),
                            # filter(agr_zone=="Tropics, highland; sub-humid, with soil/terrain limitations"),
                            filter(agr_zone=="Tropics, highland; humid, with soil/terrain limitations" ),
                          
                          category != "No data" & !emphasis),
            aes(label = label, color = category),
            vjust = -0.55, size = 4, fontface = "plain") +
  # "No data" labels - smallest, not bold
  geom_text(data = subset(agr.zn.agg%>%
                            #filter(agr_zone=="Land with severe soil/terrain limitations"),
                            #filter(agr_zone=="Tropics, highland; sub-humid, with soil/terrain limitations"),
                            filter(agr_zone=="Tropics, highland; humid, with soil/terrain limitations" ),
                          
                          
                          category == "No data"),
            aes(label = label, color = category),
            vjust = -0.55, size = 3.2, fontface = "plain") +
  geom_text(aes(label = n_label, color = category),
            vjust = 1.1, size = 2.8) +
  geom_text(data = subset(agr.zn.agg%>%
                            #filter(agr_zone=="Land with severe soil/terrain limitations"),
                            #filter(agr_zone=="Tropics, highland; sub-humid, with soil/terrain limitations"),
                            filter(agr_zone=="Tropics, highland; humid, with soil/terrain limitations" ),
                          
                          
                          category != "No data"),
            aes(label = strrep("\u25CF", confidence_n)),
            color = "grey40", size = 2.1, hjust = 1, vjust = -1.4,
            nudge_x = 0.42) +
  
  scale_fill_manual(values = fill_colors, name = NULL,
                    breaks = category_order,
                    labels = category_labels[category_order]) +
  scale_color_manual(values = text_colors, guide = "none") +
  guides(linetype = "none",
         fill = guide_legend(nrow = 1, byrow = TRUE)) +
  
  scale_x_discrete(position = "top") +
  facet_grid(group ~ ., scales = "free_y", space = "free_y", switch = "y") +
  labs(
    x = NULL, y = NULL
  ) +
  theme_minimal(base_size = 13) +
  theme(
    legend.position = "bottom",
    panel.grid = element_blank(),
    axis.text.x = element_text(face = "bold", size = 11),
    axis.text.y = element_text(size = 11, hjust = 1),
    axis.ticks = element_blank(),
    strip.placement = "outside",
    strip.text.y.left = element_text(angle = 0, face = "bold", size = 10, hjust = 1),
    plot.background = element_rect(fill = "#faf9f6", color = NA),
    panel.background = element_rect(fill = "#faf9f6", color = NA),
    plot.margin = margin(20, 25, 20, 10),
    legend.text = element_text(size = 9)
  )

print(eth_cereals_agr_zn)
"Land with severe soil/terrain limitations"
#"Tropics, highland; sub-humid, with soil/terrain limitations"
"Tropics, highland; humid, with soil/terrain limitations" 
ggsave(paste0(path.metaanalysis,
              "/plot.eth.cereals.agr.zn.tropics.highland.humid.soil.limiations.pdf"),
       plot = eth_cereals_agr_zn,
       width = 13, height = 7, dpi = 300, bg = "white")


# =============================================================================
# Cereal  by crop combinations x agroecological zone
# Reproduces the crop x  heatmap from cereals_crop_comb_eth.csv
# =============================================================================
sort(unique(eth.cereals1$out_indicator))

crop.comb.counts <- eth.cereals1 %>%
  mutate(
    combo_clean = T_crop_tree_diversity %>%
      str_split("[/\\-]") %>%
      map_chr(~ str_trim(.x) %>% sort() %>% paste(collapse = " + "))
  ) %>%
  mutate(combo_clean1=case_when(
    combo_clean%in%c(
      "Acacia nilotica + Cordia africana + Faidherbia albida + Moringa stenopetala + Teff",
      "Faidherbia albida + Teff",
      "Acacia abyssinica + Teff",
      "Acacia decurrens + Teff",
      "Acacia decurrens + Acacia decurrens + Acacia decurrens + Acacia decurrens + Acacia decurrens + Teff + Unspecified Fodder Grass",
      "Teff-Acacia abyssinica")~"Teff + Leguminous tree",
    combo_clean%in%c(
      "Teff-Cordia africana",
      "Teff-Moringa stenopetala",
      "Moringa stenopetala + Teff",
      "Croton macrostachyus + Teff",
      "Cordia africana + Teff")~"Teff + No leguminous tree",
    combo_clean%in%c(
      "Cordia africana + Finger Millet",
      "Croton macrostachyus + Finger Millet",
      "Finger Millet + Grevillea robusta")~"Finger Millet + No leguminous tree",
    combo_clean%in%c(
      "Acacia tortilis + Maize",
      "Crotalaria juncea + Maize",
      "Acacia abyssinica + Maize")~"Maize + Leguminous tree",
    combo_clean%in%c(
      "Cordia africana + Maize",
      "Croton macrostachyus + Maize")~"Maize + No leguminous tree",
    combo_clean%in%c("Lupin + Teff")~"Teff + Lupin",
    combo_clean%in%c("Common Bean + Maize")~"Maize + Common Bean",
    combo_clean%in%c("Lablab + Maize")~"Maize + Lablab",
    
    TRUE~combo_clean))%>%
  group_by(combo_clean1,
           CT_crop_FAO_Food_Group_clean,
           diversification_spatial_temporal_theme,
           biomass_management_practice,
           nutrient_management_practice,
           soil_management_theme,
           water_management_practice,
           out_indicator,
           label,
           effect_size_direction)%>%
  summarise(n_direction = n(), .groups = "drop")



cereal.comb.raw_diversification <- crop.comb.counts %>%
  group_by(combo_clean1,
           CT_crop_FAO_Food_Group_clean,
           diversification_spatial_temporal_theme,
           biomass_management_practice,
           nutrient_management_practice,
           soil_management_theme,
           water_management_practice,
           label,
           out_indicator) %>%
  mutate(n = sum(n_direction)) %>%
  ungroup() %>%
  mutate(prop = n_direction / n) %>%
  
  # Drop n_direction BEFORE pivoting so it doesn't prevent row collapse
  select(-n_direction) %>%
  
  pivot_wider(
    names_from  = effect_size_direction,
    values_from = prop,
    values_fill = 0
  ) %>%
  
  rename(
    # practice = diversification_spatial_temporal_theme,
    #diversification_temporal=diversification_temporal_theme,
    #nutrient_management=nutrient_management_theme,
    #water_management=water_management_practice,
    agr_zone = label,
    
    impact   = out_indicator,
    pos = Positive,
    neg= Negative
  )
readr::write_csv(cereal.comb.raw_diversification, paste0(path.metadata.effectsize, "/cereal.comb.raw_diversification.csv"))



cereal.comb.raw_diversification$row_id <- seq_len(nrow(cereal.comb.raw_diversification))
changed_list <- lapply(seq_len(nrow(cereal.comb.raw_diversification)), function(i) find_changed(cereal.comb.raw_diversification[i, ]))
n_changed <- vapply(changed_list, length, integer(1))

clean_rows <- which(n_changed == 1)
cat(sprintf(
  "Single-practice (clean) comparisons: %d | Confounded (2+ practices changed) excluded: %d\n",
  length(clean_rows), sum(n_changed > 1)
))


#########################################
# Use ALL changed themes per row (not just rows where exactly 1 changed).
# Each theme that changed gets its own row, crediting that row's outcome
# to it independently — i.e. assume practices were implemented separately.
all_changed_rows <- which(n_changed >= 1)

single <- lapply(all_changed_rows, function(i) {
  ch <- changed_list[[i]]
  tibble(
    row_id = cereal.comb.raw_diversification$row_id[i],
    t_crops = cereal.comb.raw_diversification$combo_clean1[i],
    agr_zone = cereal.comb.raw_diversification$agr_zone[i],
    
    theme  = vapply(ch, `[`, character(1), 1),
    c_val  = vapply(ch, `[`, character(1), 2),
    t_val  = vapply(ch, `[`, character(1), 3)
  )
}) %>%
  bind_rows() %>%
  left_join(cereal.comb.raw_diversification %>% select(row_id, impact, n, pos, neg), by = "row_id")


# ---- 4. Join, flip direction, aggregate (n-weighted) -------------------------
agg <- single %>%
  inner_join(practice_map, by = c("theme", "c_val", "t_val")) %>%
  inner_join(practice_group, by = "practice") %>%
  inner_join(metric_map, by = "impact") %>%
  mutate(
    control_display   = if_else(flip, t_val, c_val),
    treatment_display = if_else(flip, c_val, t_val),
    pos_adj           = if_else(flip, neg, pos),
    # NEW: for metrics where an increase is undesirable (Costs, GHG
    # emissions, etc.), flip pos_adj so it always means "% of comparisons
    # in the DESIRABLE direction" — consistent with Yield/Income/etc.
    pos_adj           = if_else(invert_good, 1 - pos_adj, pos_adj),
    control_display   = recode(control_display,"Crop residues grazed" = "Residues removed"),
    control_display   = recode(control_display,"Crop residues removed" = "Residues removed")
  ) %>%
  group_by(group,t_crops,agr_zone, control_display, practice, metric)%>%
  summarise(
    weighted_pos = sum(pos_adj * n) / sum(n),
    total_n      = sum(n),
    k_studies    = n(),
    .groups = "drop"
  )

# ---- 5. Classify into interpretable bands -----------------------------------
# Thresholds are a judgement call - tune for your audience/context.

agg <- agg %>%
  mutate(
    category = case_when(
      weighted_pos >= 0.65 & total_n >= 100 ~ "Strong positive",  # >=65% positive, n>=100
      weighted_pos >= 0.65                  ~ "Positive",         # >=65% positive, n<100
      weighted_pos > 0.35 & total_n >= 100 ~ "Strong neutral",   # 46-64% positive, n>=100
      weighted_pos > 0.35                  ~ "Neutral",          # 46-64% positive, n<100
      weighted_pos <= 0.35 & total_n >= 100 ~ "Strong negative",  # >=65% negative, n>=100
      weighted_pos <= 0.35                  ~ "Negative",         # >=65% negative, n<100
      
      
      total_n >= 100                        ~ "Strong neutral",   # 36-45% positive, n>=100 -> falls back to neutral
      TRUE                                  ~ "Neutral"           # 36-45% positive, n<100  -> falls back to neutral
    ),
    pct_shown = if_else(category %in% c("Strong negative", "Negative"),
                        (1 - weighted_pos) * 100,
                        weighted_pos * 100),
    label = paste0(round(pct_shown), "%")
  )

# ---- 6. Order rows/columns for a clean layout --------------------------------
agg <- agg %>%
  mutate(practice_ct= paste0(practice," vs. " , control_display))%>%
  mutate(
    practice = factor(practice, levels = rev(practice_order)),
    metric   = factor(metric, levels = metric_order)
  )

# ---- 6b. Expose evidence gaps: complete the practice x metric grid ---------
# Every (group, practice_ct) combo should show a cell for every metric,
# even if there's no data for it. Without this, missing combos are just
# blank background - indistinguishable from a neutral/mixed result.

all_combos <- agg %>%
  distinct(group, practice, practice_ct) %>%
  tidyr::crossing(metric = factor(metric_order, levels = metric_order))

agg <- all_combos %>%
  left_join(agg, by = c("group", "practice", "practice_ct", "metric")) %>%
  mutate(
    category = if_else(is.na(category), "No data", category),
    label    = if_else(is.na(label), "No data", label),
    n_label  = case_when(
      is.na(total_n)          ~ "",
      total_n == 1            ~ paste0("n= ", total_n),
      TRUE                    ~ paste0("n= ", total_n)
    )
  )

agg <- agg %>%
  mutate(category = factor(category, levels = category_order))

# ---- 6c. Confidence rating: how much evidence sits behind each %  ----------
# Banded on total_n (not k_studies) so the rating agrees with the sample-size
# text printed under each cell. Stored as an integer (0-3), not a glyph
# string - the dots themselves get drawn with geom_point() in Step 7, which
# is font-independent and won't silently fail on Windows like embedded
# unicode circle characters can.

agg <- agg %>%
  mutate(
    confidence_n = case_when(
      is.na(total_n) ~ 0L,
      total_n >= 300  ~ 3L,
      total_n >= 100   ~ 2L,
      TRUE            ~ 1L
    )
  )

agg <- agg %>%
  mutate(
    low_n = !is.na(total_n) & total_n <= 2,
    label = if_else(low_n & category != "No data", paste0(label, "*"), label)
  )

# ---- 6c-2. Flag cells to emphasize: strong positive AND well-supported ------
agg <- agg %>%
  mutate(
    emphasis = category %in% c("Strong positive", "Positive", "Negative", "Strong negative") &
      confidence_n %in% c(2, 3)  )

# ---- 7. Plot ------------------------------------------------------------------

eth_crops_comb_cereals<-
  ggplot(agg%>%
           #filter(agr_zone=="Land with severe soil/terrain limitations"),
         filter(agr_zone=="Tropics, highland; humid, with soil/terrain limitations" ),
         aes(x = metric, y = practice, fill = category)) +
  
  
  geom_tile(aes(linetype = category == "No data", alpha = factor(confidence_n)),
            color = "white", linewidth = 1, width = 0.93, height = 0.85) +
  scale_alpha_manual(values = c(`0` = 1, `1` = 0.5, `2` = 1, `3` = 1), 
                     guide = "none")+
  geom_text(data = subset(agg%>%
                            #filter(agr_zone=="Land with severe soil/terrain limitations"),
                          filter(agr_zone=="Tropics, highland; humid, with soil/terrain limitations" ),
                          emphasis),
            aes(label = label, color = category),
            vjust = -0.55, size = 5, fontface = "bold") +
  
  geom_text(data = subset(agg%>%
                            #filter(agr_zone=="Land with severe soil/terrain limitations"),
                          filter(agr_zone=="Tropics, highland; humid, with soil/terrain limitations" ),
                          category != "No data" & !emphasis),
            aes(label = label, color = category),
            vjust = -0.55, size = 4, fontface = "plain") +
  geom_text(data = subset(agg%>%
                            #filter(agr_zone=="Land with severe soil/terrain limitations"),
                          filter(agr_zone=="Tropics, highland; humid, with soil/terrain limitations" ),
                          category == "No data"),
            aes(label = label, color = category),
            vjust = -0.55, size = 3.2, fontface = "plain") +
  geom_text(aes(label = n_label, color = category),
            vjust = 1.1, size = 2.8) +
  
  
  geom_text(data = subset(agg%>%
                            #filter(agr_zone=="Land with severe soil/terrain limitations"),
                          filter(agr_zone=="Tropics, highland; humid, with soil/terrain limitations" ),
                          category != "No data"),
            aes(label = strrep("\u25CF", confidence_n)),
            color = "grey40", size = 2.1, hjust = 1, vjust = -1.4,
            nudge_x = 0.42) +
  
  scale_fill_manual(values = fill_colors, name = NULL,
                    breaks = category_order,
                    labels = category_labels[category_order]) +
  scale_color_manual(values = text_colors, guide = "none") +
  
  guides(linetype = "none",
         fill = guide_legend(nrow = 1, byrow = TRUE)) +
  
  scale_x_discrete(position = "top") +
  facet_grid(t_crops~ ., scales = "free_y", space = "free_y", switch = "y") +
  
  labs(
    x = NULL, y = NULL
  ) +
  theme_minimal(base_size = 13) +
  theme(
    legend.position = "bottom",
    panel.grid = element_blank(),
    axis.text.x = element_text(face = "bold", size = 11),
    axis.text.y = element_text(size = 11, hjust = 1),
    axis.ticks = element_blank(),
    strip.placement = "outside",
    strip.text.y.left = element_text(angle = 0, face = "bold", size = 10, hjust = 1),
    plot.background = element_rect(fill = "#faf9f6", color = NA),
    panel.background = element_rect(fill = "#faf9f6", color = NA),
    plot.margin = margin(20, 25, 20, 10),
    legend.text = element_text(size = 9)
  )

print(eth_crops_comb_cereals)

ggsave(paste0(path.metaanalysis,
               "/plot.eth.cereals.crops.comb.tropics.highland.humid.soil.limitations.pdf"),
       #"/plot.eth.cereals.crops.comb.land.severe.limitation.pdf"),
       plot = eth_crops_comb_cereals,
       width = 20, height = 25, dpi = 300, bg = "white")


#######################################
crop.comb.counts <- eth.cereals1 %>%
  filter(label == "Land with severe soil/terrain limitations") %>%
  #filter(out_indicator == "Product Yield") %>%
  #filter(out_indicator =="Soil Quality") %>%
  #filter(nutrient_management_practice != "C: Inorganic Fertilizer_vs_T: Inorganic Fertilizer" | 
  #       is.na(nutrient_management_practice)) %>%
  mutate(nutrient_management_practice1=case_when(
    nutrient_management_practice%in%c(
      "C: No Fertilizers Applied_vs_T: Biochar",
      "C: No Fertilizers Applied_vs_T: Biochar + Inorganic Fertilizer",
      "C: No Fertilizers Applied_vs_T: Biochar + Organic Fertilizer")
    ~"C: No Fertilizers Applied_vs_T: Biochar amendment",
    nutrient_management_practice%in%c(
      "C: No Fertilizers Applied_vs_T: Biochar + Inorganic Fertilizer + Organic Fertilizer",
      "C: No Fertilizers Applied_vs_T: Inorganic and Organic Fertilizers",
      "C: No Fertilizers Applied_vs_T: Organic Fertilizer + Inorganic Fertilizer")
    ~"C: No Fertilizers Applied_vs_T: Mixed fertilizer",
    
    TRUE~nutrient_management_practice
  ))%>%
  select(T_crop_tree_diversity,
         nutrient_management_practice1,
         active_groups,
         effect_size_direction) %>%
  mutate(
    combo_clean = T_crop_tree_diversity %>%
      str_split("[/\\-]") %>%
      map_chr(~ str_trim(.x) %>% sort() %>% paste(collapse = " + "))
  ) %>%
  mutate(combo_clean=case_when(
    combo_clean%in%c(
      "Acacia nilotica + Cordia africana + Faidherbia albida + Moringa stenopetala + Teff",
      "Faidherbia albida + Teff",
      "Acacia abyssinica + Teff",
      "Teff-Acacia abyssinica")~"Teff + Leguminous tree",
    combo_clean%in%c(
      "Teff-Cordia africana",
      "Teff-Moringa stenopetala",
      "Moringa stenopetala + Teff",
      "Cordia africana + Teff")~"Teff + No leguminous tree",
    TRUE~combo_clean))%>%
  
  
  count(combo_clean,nutrient_management_practice1,effect_size_direction, name = "n_comparisons", sort = TRUE)

sort(unique(crop.comb.counts$nutrient_management_practice1))
sort(unique(crop.comb.counts$combo_clean))


readr::write_csv(crop.comb.counts, paste0(path.metadata.effectsize, "/cereals_crop_comb_eth.csv"))


#--------- 1. Load and reshape the raw data ---------
# Each row in the source file compares "No Fertilizer Applied" (control) vs.
# a fertilizer treatment, for a given crop/combo, with a count of comparisons
# showing a Positive or Negative effect direction.

df_raw <- crop.comb.counts

df <- df_raw %>%
  mutate(
    fertilizer = str_extract(nutrient_management_practice1, "(?<=vs_T: ).*"),
    fertilizer = recode(fertilizer,
                        "Inorganic Fertilizer" = "Inorganic",
                        "Organic Fertilizer"   = "Organic",
                        "Mixed fertilizer"     = "Mixed",
                        "Biochar amendment"    = "Biochar"
    ),
    fertilizer = case_when(is.na(fertilizer)~"None",TRUE~fertilizer)
    
  )%>% 
  
  group_by(combo_clean, fertilizer, effect_size_direction) %>%
  summarise(n = sum(n_comparisons), .groups = "drop") %>%
  pivot_wider(names_from = effect_size_direction, values_from = n, values_fill = 0) %>%
  mutate(
    total_n = Positive + Negative,
    weighted_pos  = Positive / total_n
  )


#----- 2. Expand to the full crop x fertilizer grid so untested combinations show -----
#   up as explicit "no data" cells rather than being silently dropped-----


crop_order <- df %>%
  group_by(combo_clean) %>%
  summarise(n_total = sum(total_n)) %>%
  arrange(desc(n_total)) %>%
  pull(combo_clean)

fert_order <- c("Inorganic", "Organic", "Mixed", "Biochar","None")

df_complete <- df %>%
  select(combo_clean, fertilizer, weighted_pos, total_n) %>%
  complete(combo_clean = crop_order, fertilizer = fert_order) %>%
  mutate(
    combo_clean  = factor(combo_clean, levels = rev(crop_order)),  # rev: top row = highest n
    fertilizer   = factor(fertilizer, levels = fert_order),
    category = case_when(
      is.na(weighted_pos)                   ~ "No data",          # untested combo (added so these don't fall into "Neutral" below)
      weighted_pos >= 0.65 & total_n >= 100 ~ "Strong positive",  # >=65% positive, n>=100
      weighted_pos >= 0.65                  ~ "Positive",         # >=65% positive, n<100
      weighted_pos > 0.35 & total_n >= 100  ~ "Strong neutral",   # 36-64% positive, n>=100
      weighted_pos > 0.35                   ~ "Neutral",          # 36-64% positive, n<100
      weighted_pos <= 0.35 & total_n >= 100 ~ "Strong negative",  # <=35% positive, n>=100
      weighted_pos <= 0.35                  ~ "Negative",         # <=35% positive, n<100
      total_n >= 100                        ~ "Strong neutral",   # safety net, shouldn't be reachable
      TRUE                                  ~ "Neutral"           # safety net, shouldn't be reachable
    ),
    category = factor(category, levels = c(
      "Strong positive", "Positive", "Strong neutral", "Neutral",
      "Strong negative", "Negative", "No data"
    )),
    pct_shown = if_else(category %in% c("Strong negative", "Negative"),
                        (1 - weighted_pos) * 100,
                        weighted_pos * 100),
    label = if_else(
      category == "No data",
      "No data",
      paste0(round(pct_shown), "%")
    )
  )%>%
  mutate(
    confidence_n = case_when(
      is.na(total_n) ~ 0L,
      total_n >= 300  ~ 3L,
      total_n >= 100   ~ 2L,
      TRUE            ~ 1L
    )
  )%>%
  mutate(
    emphasis = category %in% c("Strong positive", "Positive", "Negative", "Strong negative") &
      confidence_n %in% c(2, 3)  ,
    n_label  = case_when(
      is.na(total_n)          ~ "",
      total_n == 1            ~ paste0("n= ", total_n),
      TRUE                    ~ paste0("n= ", total_n)
    )
  )


# -----------------------------------------------------------------------------
# 3. Plot
# -----------------------------------------------------------------------------
eth_cereals_fert_yield<-
  ggplot(df_complete, aes(x = fertilizer, y = combo_clean, fill = category)) +
  geom_tile(aes(linetype = category == "No data", alpha = factor(confidence_n)),
            color = "white", linewidth = 1, width = 0.93, height = 0.85) +
  scale_alpha_manual(values = c(`0` = 1, `1` = 0.5, `2` = 1, `3` = 1), 
                     guide = "none")+
  geom_text(data = subset(df_complete, emphasis),
            aes(label = label, color = category),
            vjust = -0.55, size = 5, fontface = "bold") +
  geom_text(data = subset(df_complete, category != "No data" & !emphasis),
            aes(label = label, color = category),
            vjust = -0.55, size = 4, fontface = "plain") +
  geom_text(data = subset(df_complete, category == "No data"),
            aes(label = label, color = category),
            vjust = -0.55, size = 3.2, fontface = "plain") +
  geom_text(aes(label = n_label, color = category),
            vjust = 1.1, size = 2.8) +
  geom_text(data = subset(df_complete, category != "No data"),
            aes(label = strrep("\u25CF", confidence_n)),
            color = "grey40", size = 2.1, hjust = 1, vjust = -1.4,
            nudge_x = 0.42) +
  
  scale_fill_manual(values = fill_colors, name = NULL,
                    breaks = category_order,
                    labels = category_labels[category_order]) +
  scale_color_manual(values = text_colors, guide = "none") +
  guides(linetype = "none",
         fill = guide_legend(nrow = 1, byrow = TRUE)) +
  
  scale_x_discrete(position = "top") +
  labs(
    x = NULL, y = NULL
  ) +
  theme_minimal(base_size = 13) +
  theme(
    legend.position = "bottom",
    panel.grid = element_blank(),
    axis.text.x = element_text(face = "bold", size = 11),
    axis.text.y = element_text(size = 11, hjust = 1),
    axis.ticks = element_blank(),
    strip.placement = "outside",
    strip.text.y.left = element_text(angle = 0, face = "bold", size = 10, hjust = 1),
    plot.background = element_rect(fill = "#faf9f6", color = NA),
    panel.background = element_rect(fill = "#faf9f6", color = NA),
    plot.margin = margin(20, 25, 20, 10),
    legend.text = element_text(size = 9)
  )

print(eth_cereals_fert_yield)


#---- 4. Save for the slide deck ----------------

ggsave(paste0(path.metaanalysis,"/plot.eth.cereals.fert.yield.agr.zn_heatmap_terrain_limiations.pdf"), plot = eth_cereals_fert_yield,
       width = 10, height = 7, dpi = 300, bg = "white")
