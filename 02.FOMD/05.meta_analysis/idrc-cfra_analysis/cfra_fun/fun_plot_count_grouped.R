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
# Returns a patchwork; attr(result, "n_rows") gives the number of rows, for the figure height.
#==========================================================
plot_votes_grouped <- function(cells, archetype_name,
                               outcome_order = c("Yield", "Profitability", "Soil health", "Inputs efficiency",
                                                 "Resilience to pests", "Labour demand", "Biodiversity", "Climate mitigation"),
                               min_es_cell = 10, strong_es = 100, cut_positive = 65, cut_negative = 35,
                               text_size = 8, show_no_data = FALSE) {
  
  # 0. Check the archetype name
  if (!archetype_name %in% cells$archetype) {
    stop("archetype_name not found. Available: ", paste(unique(cells$archetype), collapse = " | "))
  }
  
  # 1. Food group, heading (domain and control) and row (treatment)
  cells <- cells %>%
    mutate(block   = as.character(food_group),
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
  draw_block <- function(b, letter, first) {
    ro <- row_order %>% filter(block == b)
    
    # y positions, top to bottom: each heading followed by its practices
    y_keys <- unlist(lapply(unique(ro$heading), function(h)
      c(paste0("H||", h), paste0("R||", h, "||", ro$row[ro$heading == h]))))
    y_lab  <- sub("^H[|][|]", "", sub("^R[|][|].*[|][|]", "", y_keys))
    y_face <- ifelse(startsWith(y_keys, "H||"), "bold", "plain")
    
    d <- plot.data %>%
      filter(block == b) %>%
      mutate(y = factor(paste0("R||", heading, "||", row), levels = rev(y_keys)))
    
    ggplot(d, aes(x = outcome_group, y = y)) +
      geom_tile(aes(fill = class), colour = "white", linewidth = 0.6) +
      geom_text(data = filter(d, shown), aes(label = pct_label, colour = text_colour), size = text_size * 0.34, vjust = -0.1) +
      geom_text(data = filter(d, shown), aes(label = n_label, colour = text_colour), size = text_size * 0.27, vjust = 1.3) +
      geom_text(data = filter(d, !shown, effect_sizes > 0), aes(label = n_label, colour = text_colour), size = text_size * 0.27) +
      { if (show_no_data) geom_text(data = filter(d, effect_sizes == 0), aes(label = n_label, colour = text_colour), size = text_size * 0.24) } +
      
      scale_fill_manual(values = class_colours, drop = FALSE, guide = "none") +
      scale_colour_identity() +
      scale_x_discrete(position = "top", drop = FALSE, labels = function(x) str_wrap(x, 9)) +
      scale_y_discrete(drop = FALSE, labels = setNames(y_lab, y_keys)) +    # headings are empty rows
      labs(title = paste0(letter, ") ", b), x = NULL, y = NULL) +
      theme_minimal(base_size = 11) +
      theme_minimal(base_size = text_size) +
      theme(panel.grid = element_blank(),
            plot.title = element_text(face = "bold", size = text_size + 1.5),
            plot.title.position = "plot",
            axis.text.x = if (first) element_text(size = text_size, face = "bold", lineheight = 0.9) else element_blank(),
            axis.text.y = suppressWarnings(element_text(size = text_size, hjust = 1, face = rev(y_face))))
    
  }
  plots  <- Map(draw_block, block_levels, letters[seq_along(block_levels)], seq_along(block_levels) == 1)
  n_rows <- sapply(block_levels, function(b) {
    ro <- row_order[row_order$block == b, ]; nrow(ro) + length(unique(ro$heading)) })
  
  # panel heights: rows and headings, plus room for the food-group title (and outcome names in the first panel)
  extra <- c(1.4, rep(0.6, length(n_rows) - 1))
  out <- wrap_plots(plots, ncol = 1, heights = n_rows + extra)
  attr(out, "n_rows") <- sum(n_rows + extra)
  out
}

