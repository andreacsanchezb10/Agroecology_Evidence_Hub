library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(patchwork)

#==========================================================
# plot_votes_grouped(): heat map for ONE archetype, one panel per food group
#==========================================================
# Same classes, colours and thresholds as plot_votes(). Layout:
#   - one panel per food group, titled "a) Cereals", "b) Pulses and legumes"...,
#     ordered by the number of positive results supported by strong evidence
#   - within each panel, practices are grouped under a bold heading
#     "<practice domain> (vs. <control>)", and each row shows only the treatment practice
#   - domains, headings and practices ordered by the number of positive strong results
#   - outcome columns keep the fixed outcome_order, shown once at the top
# Size options:
#   text_size          font size in points at print size
#   heading_step       height of a heading, relative to a practice row
#   tile_height        share of the row filled by the tile
#   heading_wrap       characters per line before a heading wraps (60 = one line)
#   vertical_outcomes  TRUE writes the outcome names at 90 degrees (for narrow figures)
# Returns a patchwork; attr(result, "n_rows") gives the height in rows, for the figure height.
#==========================================================
plot_votes_grouped <- function(cells, archetype_name,
                               outcome_order = c("Yield", "Profitability", "Soil health", "Inputs efficiency",
                                                 "Resilience to pests", "Labour demand", "Biodiversity", "Climate mitigation"),
                               min_es_cell = 10, strong_es = 100, cut_positive = 65, cut_negative = 35,
                               text_size = 7, show_no_data = TRUE,
                               heading_step = 0.6, tile_height = 0.85, heading_wrap = 60,
                               vertical_outcomes = FALSE) {
  
  # 0. Check the archetype name
  if (!archetype_name %in% cells$archetype) {
    stop("archetype_name not found. Available: ", paste(unique(cells$archetype), collapse = " | "))
  }
  
  # 1. Food group, heading (domain and control) and row (treatment)
  cells <- cells %>%
    mutate(practice_group = sub("^Diversification (spatial|temporal)$", "Diversification", practice_group),
           block   = as.character(food_group),
           heading = paste0(practice_group, " (vs. ", tolower(C_practice), ")"),
           row     = T_practice)
  
  # 2. Legend classes and colours (as in plot_votes)
  class_levels <- c(
    paste0("Negative (>=", 100 - cut_negative, "% negative) - strong evidence (n>=", strong_es, ")"),
    paste0("Negative (>=", 100 - cut_negative, "% negative) - limited evidence (n<", strong_es, ")"),
    paste0("Neutral (", cut_negative + 1, "-", cut_positive - 1, "% positive) - strong evidence (n>=", strong_es, ")"),
    paste0("Neutral (", cut_negative + 1, "-", cut_positive - 1, "% positive) - limited evidence (n<", strong_es, ")"),
    paste0("Positive (>=", cut_positive, "% positive) - strong evidence (n>=", strong_es, ")"),
    paste0("Positive (>=", cut_positive, "% positive) - limited evidence (n<", strong_es, ")"),
    paste0("Insufficient evidence (n<", min_es_cell, ")"))
  class_colours <- setNames(c("#C00000", "#F4A6AE", "#8A8A8A", "#D9D9D9",
                              "#4E6B2C", "#7ED321", "#EAE7DC"), class_levels)
  text_colours  <- setNames(c("white", "#444441", "white", "#444441",
                              "white", "#444441", "#A6A08F"), class_levels)
  
  # 3. Cells of this archetype, with every practice x outcome combination
  plot.data <- cells %>%
    filter(archetype == archetype_name) %>%
    complete(nesting(block, practice_group, heading, row), outcome_group = outcome_order,
             fill = list(k = 0, effect_sizes = 0)) %>%
    filter(outcome_group %in% outcome_order) %>%
    mutate(pct = round(pct_positive),
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
           n_label = if_else(effect_sizes > 0, paste0("n= ", effect_sizes), "No data"),
           pos_strong = class == class_levels[5]) %>%
    group_by(block, heading, row) %>%
    filter(any(shown)) %>%                                   # drop rows without any reported cell
    ungroup()
  
  # 4. Order by the number of positive results supported by strong evidence
  block_levels <- plot.data %>%
    group_by(block) %>%
    summarise(n_ps = sum(pos_strong), n_es = sum(effect_sizes), .groups = "drop") %>%
    arrange(desc(n_ps), desc(n_es)) %>% pull(block)
  
  # domains first (headings of the same domain stay together), then headings, then practices
  row_order <- plot.data %>%
    group_by(block, practice_group) %>%
    mutate(domain_ps = sum(pos_strong), domain_es = sum(effect_sizes)) %>%
    group_by(block, heading) %>%
    mutate(head_ps = sum(pos_strong), head_es = sum(effect_sizes)) %>%
    group_by(block, practice_group, heading, row, domain_ps, domain_es, head_ps, head_es) %>%
    summarise(row_ps = sum(pos_strong), row_es = sum(effect_sizes), .groups = "drop") %>%
    arrange(desc(domain_ps), desc(domain_es), practice_group,
            desc(head_ps), desc(head_es), heading, desc(row_ps), desc(row_es))
  
  # 5. One panel per food group
  # y positions (top to bottom): a heading takes heading_step of a row, a practice takes one row
  layout_block <- function(b) {
    ro <- row_order %>% filter(block == b)
    keys <- unlist(lapply(unique(ro$heading), function(h)
      c(paste0("H||", h), paste0("R||", h, "||", ro$row[ro$heading == h]))))
    is_head <- startsWith(keys, "H||")
    label   <- sub("^H[|][|]", "", sub("^R[|][|].*[|][|]", "", keys))
    label   <- ifelse(is_head, str_wrap(label, heading_wrap), label)      # long headings on two lines
    n_lines <- str_count(label, "\n") + 1
    step    <- ifelse(is_head, heading_step + 0.35 * (n_lines - 1), 1)
    tibble(key = keys,
           label = label,
           face  = ifelse(is_head, "bold", "plain"),
           ypos  = -(cumsum(step) - step / 2))            # centre of each slot, from the top down
  }
  
  draw_block <- function(b, letter, first) {
    lay <- layout_block(b)
    d <- plot.data %>%
      filter(block == b) %>%
      mutate(key = paste0("R||", heading, "||", row)) %>%
      left_join(lay %>% select(key, ypos), by = "key")
    
    ggplot(d, aes(x = outcome_group, y = ypos)) +
      geom_tile(aes(fill = class), colour = "white", linewidth = 0.6, height = tile_height) +
      geom_text(data = filter(d, shown), aes(label = pct_label, colour = text_colour), size = text_size * 0.34, vjust = -0.1) +
      geom_text(data = filter(d, shown), aes(label = n_label, colour = text_colour), size = text_size * 0.27, vjust = 1.3) +
      geom_text(data = filter(d, !shown, effect_sizes > 0), aes(label = n_label, colour = text_colour), size = text_size * 0.27) +
      { if (show_no_data) geom_text(data = filter(d, effect_sizes == 0), aes(label = n_label, colour = text_colour), size = text_size * 0.24) } +
      scale_fill_manual(values = class_colours, drop = FALSE, guide = "none") +
      scale_colour_identity() +
      scale_x_discrete(position = "top", drop = FALSE,
                       labels = function(x) if (vertical_outcomes) x else str_wrap(x, 10)) +
      scale_y_continuous(breaks = lay$ypos, labels = lay$label,               # headings have no tiles
                         limits = c(min(lay$ypos) - 0.5, 0), expand = c(0, 0)) +
      labs(title = paste0(letter, ") ", b), x = NULL, y = NULL) +
      theme_minimal(base_size = text_size) +
      theme(panel.grid = element_blank(),
            plot.title = element_text(face = "bold", size = text_size + 1.5, margin = margin(b = 2)),
            plot.title.position = "plot",
            plot.margin = margin(if (first) 10 else 2, 2, 2, 2),   # more space above the first panel
            axis.text.x = if (!first) element_blank() else if (vertical_outcomes)
              element_text(size = text_size, face = "bold", angle = 90, hjust = 0, vjust = 0.5) else
                element_text(size = text_size, face = "bold", lineheight = 0.85),
            axis.text.y = suppressWarnings(element_text(size = text_size, hjust = 1, face = lay$face, lineheight = 0.8)))
  }
  plots  <- Map(draw_block, block_levels, letters[seq_along(block_levels)], seq_along(block_levels) == 1)
  n_rows <- sapply(block_levels, function(b) { lay <- layout_block(b); -min(lay$ypos) + 0.5 })
  
  # panel heights = rows only, so every row has the same height in all food groups;
  # the titles and outcome names take their own space, counted only in the figure height
  extra <- c(if (vertical_outcomes) 3.4 else 1.6, rep(0.9, length(n_rows) - 1))
  out <- wrap_plots(plots, ncol = 1, heights = n_rows)
  attr(out, "n_rows") <- sum(n_rows + extra)
  out
}

#==========================================================
# grid_legend_small(): compact legend for the A4 figures (same colours as plot_votes_grouped)
#==========================================================
# Columns = direction (negative / neutral / positive), rows = evidence (strong / limited).
grid_legend_small <- function(strong_es = 100, cut_positive = 65, cut_negative = 35, text_size = 7) {
  leg <- tibble::tribble(
    ~direction, ~evidence, ~colour,
    "Negative", "Strong",  "#C00000",
    "Negative", "Limited", "#F4A6AE",
    "Neutral",  "Strong",  "#8A8A8A",
    "Neutral",  "Limited", "#D9D9D9",
    "Positive", "Strong",  "#4E6B2C",
    "Positive", "Limited", "#7ED321") %>%
    mutate(direction = factor(direction, levels = c("Negative", "Neutral", "Positive")),
           evidence  = factor(evidence,  levels = c("Limited", "Strong")))      # Strong on top
  col_labels <- c(Negative = paste0("Negative (\u2264", cut_negative, "%)"),
                  Neutral  = paste0("Neutral (", cut_negative + 1, "\u2013", cut_positive - 1, "%)"),
                  Positive = paste0("Positive (\u2265", cut_positive, "%)"))
  row_labels <- c(Strong  = paste0("Strong evidence (n \u2265 ", strong_es, ")"),
                  Limited = paste0("Limited evidence (n < ", strong_es, ")"))
  ggplot(leg, aes(x = direction, y = evidence)) +
    geom_tile(aes(fill = colour), colour = "white", linewidth = 1) +
    scale_fill_identity() +
    scale_x_discrete(position = "top", labels = col_labels) +
    scale_y_discrete(labels = row_labels) +
    labs(x = NULL, y = NULL, title = "% positive comparisons") +
    theme_minimal(base_size = text_size) +
    theme(panel.grid = element_blank(),
          plot.title = element_text(size = text_size, face = "bold", hjust = 0.5),
          plot.title.position = "panel",
          axis.text.x = element_text(size = text_size - 0.5, face = "bold", lineheight = 0.9),
          axis.text.y = element_text(size = text_size - 0.5))
}