library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)

#==========================================================
# plot_votes(): heat map for ONE archetype
#==========================================================
# cells           output of count_effects(), counted by
#                 c("archetype", "practice_group", "T_practice", "C_practice", "outcome_group")
# archetype_name  archetype to plot, e.g. "2A - Soil restoration"
# outcome_order   columns of the figure, in order
# min_es_cell     cells with fewer effect sizes are not reported (insufficient evidence)
# strong_es       cells with at least this many effect sizes are "strong evidence"
# cut_positive    % positive at or above which a cell is "positive" (default 65)
# cut_negative    % positive at or below which a cell is "negative" (default 35 = at least 65% negative)
#
# Colour = direction (positive / neutral / negative) x evidence (strong / limited).
# Each cell shows the % of effect sizes with a positive effect (large),
# and below it the number of studies (k) and effect sizes (in brackets).
#==========================================================
plot_votes <- function(cells, archetype_name,
                       outcome_order = c("Yield", "Profitability", "Soil health", "Inputs efficiency",
                                         "Resilience to pests", "Labour demand", "Biodiversity", "Climate mitigation"),
                       min_es_cell = 10, strong_es = 100, cut_positive = 65, cut_negative = 35) {
  
  # 0. Check the archetype name
  if (!archetype_name %in% cells$archetype) {
    stop("archetype_name not found. Available: ", paste(unique(cells$archetype), collapse = " | "))
  }
  
  # 1. Row label: "treatment vs control" when cells were counted by C_practice, otherwise treatment
  if ("C_practice" %in% names(cells)) {
    cells <- cells %>% mutate(row_label = paste0(T_practice, " vs ", C_practice))
  } else {
    cells <- cells %>% mutate(row_label = T_practice)
  }
  
  # 1b. Blocks: food groups when cells were counted by food_group (practice group added to the
  #     row label), otherwise practice groups
  if ("food_group" %in% names(cells)) {
    cells <- cells %>%
      mutate(row_label = paste0(row_label, "  [", practice_group, "]"),
             block = factor(as.character(food_group),
                            levels = if (is.factor(food_group)) levels(food_group) else sort(unique(food_group))))
  } else {
    cells <- cells %>% mutate(block = practice_group)
  }
  
  # 2. Legend classes and colours, in the order shown in the legend
  class_levels <- c(
    paste0("Negative (>=", 100 - cut_negative, "% negative) - strong evidence (n>=", strong_es, ")"),
    paste0("Negative (>=", 100 - cut_negative, "% negative) - limited evidence (n<", strong_es, ")"),
    paste0("Neutral (", cut_negative + 1, "-", cut_positive - 1, "% positive) - strong evidence (n>=", strong_es, ")"),
    paste0("Neutral (", cut_negative + 1, "-", cut_positive - 1, "% positive) - limited evidence (n<", strong_es, ")"),
    paste0("Positive (>=", cut_positive, "% positive) - strong evidence (n>=", strong_es, ")"),
    paste0("Positive (>=", cut_positive, "% positive) - limited evidence (n<", strong_es, ")"),
    paste0("Insufficient evidence (n<", min_es_cell, ")"))
  class_colours <- setNames(c("#C00000", "#F4A6AE",
                              "#8A8A8A", "#D9D9D9",
                              "#4E6B2C", "#7ED321",
                              "#EAE7DC"),
                            class_levels)
  text_colours <- setNames(c("white", "#444441",     # negative: strong, limited
                             "white", "#444441",     # neutral:  strong, limited
                             "white", "#444441",     # positive: strong, limited
                             "#A6A08F"),             # no data
                           class_levels)
  
  # 3. Cells of this archetype, with every practice x outcome combination
  plot.data <- cells %>%
    filter(archetype == archetype_name) %>%
    complete(nesting(block, row_label), outcome_group = outcome_order,
             fill = list(k = 0, effect_sizes = 0)) %>%
    filter(outcome_group %in% outcome_order) %>%
    mutate(pct = round(pct_positive),                      # same value for colour and label
           outcome_group = factor(outcome_group, levels = outcome_order),
           shown  = effect_sizes >= min_es_cell,
           strong = effect_sizes >= strong_es,
           class = case_when(!shown                          ~ class_levels[7],
                             pct <= cut_negative &  strong   ~ class_levels[1],
                             pct <= cut_negative             ~ class_levels[2],
                             pct <  cut_positive &  strong   ~ class_levels[3],
                             pct <  cut_positive             ~ class_levels[4],
                             strong                          ~ class_levels[5],
                             TRUE                            ~ class_levels[6]),
           class = factor(class, levels = class_levels),
           text_colour = unname(text_colours[as.character(class)]),
           pct_label = if_else(shown, paste0(pct, "%"), ""),
           n_label = if_else(effect_sizes > 0, paste0("n= ", effect_sizes), "No data"))
  
  # 3b. Drop rows without any reported cell
  plot.data <- plot.data %>%
    group_by(block, row_label) %>%
    filter(any(shown)) %>%
    ungroup()
  
  # 4. Order by evidence: number of cells with a positive effect supported by strong evidence
  plot.data <- plot.data %>%
    group_by(block, row_label) %>%
    mutate(practice_group = first(na.omit(practice_group))) %>%   # empty cells added by complete()
    ungroup() %>%
    mutate(pos_strong = class == class_levels[5])
  
  # 4a. Food groups (blocks): most positive strong cells first
  block_levels <- plot.data %>%
    group_by(block) %>%
    summarise(n_ps = sum(pos_strong), n_es = sum(effect_sizes), .groups = "drop") %>%
    arrange(desc(n_ps), desc(n_es)) %>%
    pull(block) %>% as.character()
  plot.data$block <- factor(as.character(plot.data$block), levels = block_levels)
  # letters before the food group names, in the order shown: a) Cereals, b) Pulses and legumes...
  levels(plot.data$block) <- paste0(letters[seq_along(block_levels)], ") ", block_levels)
  
  # 4b. Rows within each food group: practice domain with most positive strong cells first,
  #     then the practice with most positive strong outcomes, then the one with most effect sizes.
  #     Rows get a key unique to their food group, so each food group keeps its own order.
  row_order <- plot.data %>%
    group_by(block, practice_group) %>%
    mutate(domain_ps = sum(pos_strong), domain_es = sum(effect_sizes)) %>%
    group_by(block, practice_group, row_label, domain_ps, domain_es) %>%
    summarise(row_ps = sum(pos_strong), row_es = sum(effect_sizes), .groups = "drop") %>%
    arrange(block, desc(domain_ps), desc(domain_es), practice_group, desc(row_ps), desc(row_es)) %>%
    mutate(row_key = paste(block, row_label, sep = "||"))
  plot.data <- plot.data %>%
    mutate(row_key = factor(paste(block, row_label, sep = "||"), levels = rev(row_order$row_key)))  # first on top
  
  
  # 5. Heat map
  ggplot(plot.data, aes(x = outcome_group, y = row_key)) +
    geom_tile(aes(fill = class), colour = "white", linewidth = 1, show.legend = TRUE) +
    # percentage, just above the centre of the cell
    geom_text(data = filter(plot.data, shown),
              aes(label = pct_label, colour = text_colour), size = 3, fontface = "plain", vjust = -0.15) +
    # number of effect sizes, just below the centre of reported cells
    geom_text(data = filter(plot.data, shown),
              aes(label = n_label, colour = text_colour), size = 2.6, vjust = 1.4) +
    # cells with too few effect sizes: n, centred
    geom_text(data = filter(plot.data, !shown, effect_sizes > 0),
              aes(label = n_label, colour = text_colour), size = 2.6) +
    # cells without data: smaller
    geom_text(data = filter(plot.data, effect_sizes == 0),
              aes(label = n_label, colour = text_colour), size = 2.3) +
    scale_fill_manual(values = class_colours, drop = FALSE, name = NULL) +
    scale_colour_identity() +
    guides(fill = guide_legend(ncol = 2, byrow = TRUE)) +
    scale_x_discrete(position = "top", labels = function(x) str_wrap(x, 10)) +
    scale_y_discrete(labels = function(x) sub("^.*[|][|]", "", x)) +   # show the row label only
    facet_grid(block ~ ., scales = "free_y", space = "free_y", switch = "y", drop = TRUE) +
    labs(title = archetype_name, x = NULL, y = NULL,
         caption = paste0("")) +
    theme_minimal(base_size = 11) +
    theme(panel.grid = element_blank(),
          plot.title = element_text(face = "bold", size = 13),
          strip.placement = "outside",
          strip.text.y.left = element_text(angle = 0, hjust = 1, face = "bold", size = 9),
          axis.text.x = element_text(size = 10, face = "bold"),
          panel.spacing.y = unit(0.4, "lines"),
          legend.position = "bottom",
          legend.text = element_text(size = 8),
          plot.title.position = "plot",
          plot.caption.position = "plot",
          plot.caption = element_text(colour = "grey40", hjust = 0))
}



#==========================================================
# grid_legend(): legend as a small table
#==========================================================
# Rows = direction (negative / neutral / positive), columns = evidence (strong / limited).
# Use the same thresholds as in plot_votes(). Colours must match class_colours in plot_votes().
#==========================================================
grid_legend <- function(strong_es = 100, cut_positive = 65, cut_negative = 35) {
  
  leg <- tibble::tribble(
    ~direction, ~evidence, ~colour,
    "Negative", "Strong",  "#C00000",
    "Negative", "Limited", "#F4A6AE",
    "Neutral",  "Strong",  "#8A8A8A",
    "Neutral",  "Limited", "#D9D9D9",
    "Positive", "Strong",  "#4E6B2C",
    "Positive", "Limited", "#7ED321") %>%
    mutate(direction = factor(direction, levels = rev(c("Negative", "Neutral", "Positive"))),
           evidence  = factor(evidence,  levels = c("Strong", "Limited")))
  
  row_labels <- c(Negative = paste0("Negative\n(\u2264", cut_negative, "% positive)"),
                  Neutral  = paste0("Neutral\n(", cut_negative + 1, "\u2013", cut_positive - 1, "% positive)"),
                  Positive = paste0("Positive\n(\u2265", cut_positive, "% positive)"))
  col_labels <- c(Strong  = paste0("Strong\nevidence\n(n \u2265 ", strong_es, ")"),
                  Limited = paste0("Limited\nevidence\n(n < ", strong_es, ")"))
  
  ggplot(leg, aes(x = evidence, y = direction)) +
    geom_tile(aes(fill = colour), colour = "white", linewidth = 1.5, width = 0.9, height = 0.9) +
    scale_fill_identity() +
    scale_x_discrete(position = "top", labels = col_labels) +
    scale_y_discrete(labels = row_labels) +
    coord_fixed(ratio = 0.5) +
    labs(x = NULL, y = NULL) +
    theme_minimal(base_size = 9) +
    theme(panel.grid = element_blank(),
          axis.text.x = element_text(face = "bold", size = 8),
          axis.text.y = element_text(size = 8, hjust = 1))
}
