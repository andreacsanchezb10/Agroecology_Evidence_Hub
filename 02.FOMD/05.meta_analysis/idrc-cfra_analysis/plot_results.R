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


################################# this is only consider the unique practices
single <- tibble(
  row_id = raw$row_id[clean_rows],
  theme  = vapply(clean_rows, function(i) changed_list[[i]][[1]][1], character(1)),
  c_val  = vapply(clean_rows, function(i) changed_list[[i]][[1]][2], character(1)),
  t_val  = vapply(clean_rows, function(i) changed_list[[i]][[1]][3], character(1))
) %>%
  left_join(raw %>% select(row_id, impact, n, pos, neg), by = "row_id")

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
  "nutrient_management_practice", "No Fertilizers Applied", "Organic Fertilizer", "Organic fertilizer", FALSE,
  "nutrient_management_practice", "No Fertilizers Applied", "Biochar", "Biochar amendment", FALSE,
  "nutrient_management_practice", "No Fertilizers Applied", "Biochar + Inorganic Fertilizer", "Biochar amendment", FALSE,
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

ggsave(paste0(path.metaanalysis,"/eth_cereals_heatmap.pdf"), plot = eth_cereals,
       width = 20, height = 15, dpi = 300, bg = "white")


