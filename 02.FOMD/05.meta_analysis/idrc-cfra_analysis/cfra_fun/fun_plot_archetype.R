library(sf)
library(terra)
library(dplyr)
library(ggplot2)

#==========================================================
# plot_archetype(): map one CFRA policy archetype
#==========================================================
# Works for the three formats the archetype files come in:
#   - ADM choropleth .gpkg with a criteria count   (e.g. KEN 2A/2B: Criteria_Met_Count)
#   - ADM choropleth .gpkg with a ranked tier      (e.g. ETH 3A: tier + tier_label, 1 = highest)
#   - gridded .tif with a criteria score           (e.g. ETH 3B/3C: 0-n per 5km cell)
#
# x              sf / SpatRaster object, or a path to a .gpkg / .tif
# class_col      column holding the class (ignored for rasters)
# n_criteria     total number of criteria -> labels "k of n met"; top class gets "(Core Priority)"
# label_col      column with ready-made labels (use instead of n_criteria, e.g. "tier_label")
# reverse        TRUE when class 1 is the highest priority (e.g. tier)
# scope_col      column flagging counties in scope (e.g. "ASAL_County"); others are drawn grey
# scope_value    value of scope_col that means "in scope"
# outline_col    0/1 flag column drawn as a bold outline (e.g. "Low_Female_Education_Flag")
# outline_label  legend text for the outline
# priority_rule  high-priority areas, as text (e.g. "Criteria_Met_Count >= 3"), drawn as a black outline
#                (vector archetypes only; use the same rule as for the selection of comparisons)
# priority_label legend text for the high-priority outline
# zero_na        rasters: treat 0 (no criteria met) as blank instead of a class
# legend_title   legend title
# sites          optional sf points with a column size_class ("1–9", "10–49", "≥50"):
#                study sites drawn as black points sized by number of comparisons
#
# Returns a ggplot; save it with ggsave() to your own Downloads folder.
#==========================================================

plot_archetype <- function(x,
                           class_col      = "Criteria_Met_Count",
                           n_criteria     = NULL,
                           label_col      = NULL,
                           reverse        = FALSE,
                           scope_col      = NULL,
                           scope_value    = "Yes",
                           scope_label    = "Out of scope",
                           outline_col    = NULL,
                           outline_label  = "Flagged",
                           priority_rule  = NULL,
                           priority_label = "High-priority areas",
                           sites          = NULL,
                           zero_na        = FALSE,
                           legend_title   = NULL) {
  
  #--- read from path if needed
  if (is.character(x)) {
    x <- if (grepl("\\.tif$", x, ignore.case = TRUE)) rast(x) else st_read(x, quiet = TRUE)
  }
  
  ramp <- colorRampPalette(c("#FEEC9F", "#FBAF4C", "#EE3E23", "#B30025"))
  grey_zero  <- "#EDEDED"
  grey_scope <- "#D3D3D3"
  
  make_labels <- function(cls) {
    if (is.null(n_criteria)) return(setNames(cls, cls))
    lab <- paste0(cls, " of ", n_criteria, " met")
    lab[cls == as.character(n_criteria)] <- paste0(n_criteria, " of ", n_criteria, " met (Core Priority)")
    setNames(lab, cls)
  }
  
  make_colours <- function(cls) {
    pos <- cls[cls != "0"]
    cols <- ramp(length(pos))
    if (reverse) cols <- rev(cols)
    out <- setNames(cols, pos)
    if ("0" %in% cls) out <- c("0" = grey_zero, out)
    out[cls]
  }
  
  #==========================================================
  #--- Raster archetypes
  #==========================================================
  if (inherits(x, "SpatRaster")) {
    df <- as.data.frame(x[[1]], xy = TRUE, na.rm = TRUE)
    names(df)[3] <- "class"
    if (zero_na) df <- filter(df, class != 0)
    df$class <- factor(df$class, levels = sort(unique(df$class)))
    cls <- levels(df$class)
    
    return(
      ggplot(df) +
        geom_raster(aes(x = x, y = y, fill = class)) +
        scale_fill_manual(values = make_colours(cls), labels = make_labels(cls), name = legend_title) +
        coord_sf(crs = st_crs(crs(x))) +
        theme_void()
    )
  }
  
  #==========================================================
  #--- Vector (choropleth) archetypes
  #==========================================================
  x$class <- as.character(x[[class_col]])
  cls <- as.character(sort(unique(x[[class_col]])))
  
  labs <- if (!is.null(label_col)) {
    lk <- distinct(st_drop_geometry(x), .data[[class_col]], .data[[label_col]])
    setNames(as.character(lk[[label_col]]), as.character(lk[[class_col]]))[cls]
  } else {
    make_labels(cls)
  }
  cols <- make_colours(cls)
  
  if (!is.null(scope_col)) {
    x$class[x[[scope_col]] != scope_value | is.na(x[[scope_col]])] <- "Out of scope"
    cls  <- c(cls[cls %in% x$class], "Out of scope")
    cols <- c(cols, "Out of scope" = grey_scope)[cls]
    labs <- c(labs, "Out of scope" = scope_label)[cls]
    }
  #--- fade the colours of classes outside the high-priority areas (map and legend match)
  if (!is.null(priority_rule)) {
    keep      <- with(x, eval(str2lang(priority_rule))) %in% TRUE
    prio_cls  <- unique(as.character(x$class[keep]))
    fade      <- function(col) colorRampPalette(c(col, "white"))(3)[2]      # halfway to white
    other_cls <- setdiff(names(cols), c(prio_cls, "Out of scope"))
    cols[other_cls] <- vapply(cols[other_cls], fade, character(1))
  }
  
  x$class <- factor(x$class, levels = cls)
  
  p <- ggplot() +
    geom_sf(data = x, aes(fill = class), colour = "grey40", linewidth = 0.2) +
    scale_fill_manual(values = cols, labels = labs, name = legend_title, drop = TRUE)
  
  if (!is.null(outline_col)) {
    p <- p +
      geom_sf(data = x[x[[outline_col]] %in% 1, ], aes(colour = "outline"),
              fill = NA, linewidth = 1) +
      scale_colour_manual(values = c(outline = "#1565C0"), labels = outline_label, name = NULL)
  }
  
  #--- high-priority areas: one black outline around all of them
  if (!is.null(priority_rule)) {
    priority <- x[keep, ]
    p <- p +
      geom_sf(data = st_union(priority), aes(linetype = "priority"),
              fill = NA, colour = "grey10", linewidth = 0.6) +
      scale_linetype_manual(values = c(priority = "solid"), labels = priority_label, name = NULL)
  }
  
  #--- study sites (optional), sized by number of comparisons
  size_labels <- c("1\u20139", "10\u201349", "\u226550")
  size_values <- c(1.3, 2.6, 4.5)
  if (!is.null(sites)) {
    p <- p +
      geom_sf(data = sites, aes(size = size_class), inherit.aes = FALSE,
              shape = 21, fill = "#08519C", colour = "white", stroke = 0.3, alpha = 0.9,
              show.legend = c(size = TRUE)) +
      scale_size_manual(values = size_values, limits = size_labels, drop = FALSE,
                        name = "Comparisons per site")
  }
  
  p +
    guides(fill = guide_legend(order = 1, override.aes = list(size = 0, shape = NA)),
           colour = guide_legend(order = 2),
           linetype = guide_legend(order = 3, override.aes = list(shape = NA)),
           size = guide_legend(order = 4, override.aes = list(size = size_values))) +
    theme_void() +
    theme(legend.title = element_text(size = 7,face = "bold"), 
          legend.text = element_text(size = 6.5),
          legend.key.size = unit(0.35, "cm"))
}


#==========================================================
# plot_aez_evidence(): main agro-ecological zones of the high-priority areas and study sites
#==========================================================
# arc, rule      archetype polygons and high-priority rule (as in plot_archetype() / select_priority())
# aez_raster     GAEZ v4 AEZ57 raster of the archetype's country
# lookup         GAEZ_57_lookup.csv (value, color, label): zone names and colours, as in the zone table
# points_used    site points of the comparisons used: make_points() joined with effect_size_id,
#                study_id, country and selection (output of select_evidence()$ids)
# min_share      share (%) of the high-priority areas defining the main zones
# zone_cols      colours by GAEZ class (default: the GAEZ legend colours in lookup$color);
#                other zones are drawn in white
# text_size      font size in points at print size
#
# Comparisons within the high-priority areas are drawn as filled circles, comparisons added from the
# same main zones elsewhere as open circles. Added comparisons outside the map (e.g. in neighbouring
# countries) are not drawn and are summarised in a note under the map.
# Legend: each main zone with its share of the high-priority areas and the number of studies located
# in it within these areas, and the other zones together with their number of studies.
# Returns a ggplot.
#==========================================================
plot_aez_evidence <- function(arc, rule, aez_raster, lookup, points_used,
                              aez_rasters = list(aez_raster),   # all rasters (country + neighbours), to name zones abroad
                              min_share = 10,
                              zone_cols = setNames(lookup$color, lookup$value),   # GAEZ legend colours
                              text_size = 7) {
  
  pr  <- arc[with(arc, eval(str2lang(rule))) %in% TRUE, ]
  prv <- terra::vect(st_transform(pr, terra::crs(aez_raster)))
  gm  <- terra::mask(terra::crop(aez_raster, prv), prv)
  names(gm) <- "value"
  
  #--- main zones: share of the high-priority areas
  share <- as.data.frame(terra::freq(gm)) %>%
    transmute(aez = as.integer(value), share = 100 * count / sum(count))
  main <- share %>% filter(share >= min_share) %>% arrange(desc(share)) %>%
    left_join(transmute(lookup, aez = as.integer(value), label), by = "aez")
  
  #--- sites used: inside the high-priority areas, or added (in the map or outside it)
  pts <- st_transform(points_used, st_crs(arc))
  in_hpa <- lengths(st_intersects(pts, pr)) > 0
  in_map <- lengths(st_intersects(pts, arc)) > 0
  pts$origin <- case_when(pts$selection == "High-priority areas" & in_hpa ~ "Within high-priority areas",
                          pts$selection != "High-priority areas" & in_map ~ "Added from the same zones",
                          pts$selection != "High-priority areas"          ~ "outside",
                          TRUE                                            ~ NA_character_)
  pts <- pts[!is.na(pts$origin), ]
  pts$aez <- NA_integer_
  for (r in aez_rasters)                                   # zone of each site, in the country or a neighbour
    pts$aez <- coalesce(pts$aez, as.integer(terra::extract(r, terra::vect(st_transform(pts, terra::crs(r))))[, 2]))
  # added comparisons: only their sites in the main zones (the zones they were added for)
  pts <- pts[pts$origin == "Within high-priority areas" | pts$aez %in% main$aez, ]
  
  sites <- pts %>%
    filter(origin != "outside") %>%
    mutate(site = st_as_text(geometry)) %>%
    group_by(site, origin) %>%
    summarise(comparisons = n_distinct(effect_size_id), aez = first(aez), .groups = "drop") %>%
    mutate(size_class = cut(comparisons, c(0, 9, 49, Inf), labels = c("1\u20139", "10\u201349", "\u226550")),
           zone_fill  = unname(zone_cols[as.character(aez)]),                 # colour of the site's zone
           origin = factor(origin, levels = c("Within high-priority areas", "Added from the same zones")))
  
  #--- note on added comparisons outside the map
  study_word <- function(n) paste0(n, if_else(n == 1, " study", " studies"))
  out <- pts %>% st_drop_geometry() %>% filter(origin == "outside") %>%
    left_join(transmute(lookup, aez = as.integer(value), zone = label), by = "aez") %>%
    group_by(country, zone) %>%
    summarise(s = n_distinct(study_id), n = n_distinct(effect_size_id), .groups = "drop")
  note <- if (nrow(out) == 0) NULL else
    paste0("Not shown: ", paste0(study_word(out$s), " (", out$n, " comparisons) added from the ", out$zone,
                                 " zone in ", out$country, collapse = "; "), ".") %>% str_wrap(60)   # wrapped to the panel width
  
  #--- legend labels: zone name (as in the zone table), share and studies within the high-priority areas
  hpa <- pts[pts$origin == "Within high-priority areas", ]
  main$studies <- vapply(main$aez, function(z) n_distinct(hpa$study_id[hpa$aez %in% z]), numeric(1))
  other_n <- n_distinct(hpa$study_id[!is.na(hpa$aez) & !hpa$aez %in% main$aez])
  zone_lab <- c(setNames(paste0(sub("; ", ";\n", main$label, fixed = TRUE), " (", round(main$share), "%; ",
                                study_word(main$studies), ")"), main$aez),
                other = paste0("Other zones (<", min_share, "% each; ", study_word(other_n), ")"))
  cols <- c(zone_cols[as.character(main$aez)], other = "#E3F2E0")
  
  df <- as.data.frame(gm, xy = TRUE, na.rm = TRUE) %>%
    mutate(zone = factor(if_else(value %in% main$aez, as.character(value), "other"), levels = names(zone_lab)))
  
  shown <- seq_along(levels(droplevels(sites$origin)))   # point types present in this map
  
  ggplot() +
    geom_sf(data = arc, fill = "white", colour = "grey80", linewidth = 0.15) +
    geom_raster(data = df, aes(x = x, y = y, fill = zone), key_glyph = draw_key_polygon) +
    geom_sf(data = st_union(pr), fill = NA, colour = "grey10", linewidth = 0.6) +
    # within high-priority areas: blue with white outline; added: white with blue outline
    geom_sf(data = filter(sites, origin == "Within high-priority areas"), aes(size = size_class, shape = origin),
            fill = "#08519C", colour = "white", stroke = 0.3, alpha = 0.9, key_glyph = draw_key_point,
            show.legend = c(size = TRUE, shape = TRUE)) +
    { if (any(sites$origin == "Added from the same zones"))      # drawn only when comparisons were added
      geom_sf(data = filter(sites, origin == "Added from the same zones"), aes(size = size_class, shape = origin),
              fill = filter(sites, origin == "Added from the same zones")$zone_fill,   # filled with its zone colour
              colour = "#08519C", stroke = 0.45, key_glyph = draw_key_point,
              show.legend = c(size = TRUE, shape = TRUE)) } +
    scale_fill_manual(values = cols, labels = zone_lab, name = "Main agroecological zones in high-priority areas") +
    scale_size_manual(values = c(1.3, 2.6, 4.5), limits = c("1\u20139", "10\u201349", "\u226550"), drop = FALSE,
                      name = "Number of comparisons per site") +
    scale_shape_manual(values = c("Within high-priority areas" = 21, "Added from the same zones" = 21),
                       labels = c("Within high-priority areas" = "Within high-priority areas",
                                  "Added from the same zones" = "Added from the same zones (filled with the zone colour)"),
                       drop = TRUE, name = "Location of comparisons") +
    
    guides(fill  = guide_legend(order = 1, ncol = 1,                     # grey outline: white key visible
                                override.aes = list(size = 0, shape = NA, colour = "grey50", linewidth = 0.2)),
           shape = guide_legend(order = 2, override.aes = list(size = 2,
                                                               fill   = c("#08519C", "white")[shown],
                                                               colour = c("white", "#08519C")[shown],
                                                               stroke = c(0.3, 0.45)[shown])),
           size  = guide_legend(order = 3, override.aes = list(size = c(1.3, 2.6, 4.5), shape = 21,
                                                               fill = "grey60", colour = "white", stroke = 0.3))) +
    coord_sf(crs = st_crs(arc)) +
    labs(x = NULL, y = NULL, caption = note) +
    theme_void() +
    theme(legend.title = element_text(size = text_size, face = "bold"),
          legend.text = element_text(size = text_size - 0.5),
          legend.key.size = unit(0.35, "cm"),
          plot.caption = element_text(size = text_size - 0.5, hjust = 0, margin = margin(t = 4)))
}


#==========================================================
# plot_years(): number of studies by year of publication
#==========================================================
# long        comparisons used in the analysis of one archetype (e.g. arc.long filtered by archetype),
#             with study_id and year
# year_col    column with the year of publication
# fill        bar colour
# text_size   font size in points at print size
#
# Returns a ggplot without title; attr(result, "summary") gives studies, first and last year,
# median year and studies published since 2010, for the text.
#==========================================================
plot_years <- function(long,
                       year_col  = "year",
                       fill      = "#08519C",
                       text_size = 8) {
  
  # one row per study
  studies <- long %>%
    distinct(study_id, year = as.integer(.data[[year_col]]))
  
  summary <- studies %>%
    summarise(studies = n_distinct(study_id), first = min(year, na.rm = TRUE), last = max(year, na.rm = TRUE),
              median = median(year, na.rm = TRUE), since_2010 = sum(year >= 2010, na.rm = TRUE),
              no_year = sum(is.na(year)))
  
  # x axis from the first to the last five-year mark around the data
  lims <- c(floor(min(studies$year, na.rm = TRUE) / 5) * 5, ceiling(max(studies$year, na.rm = TRUE) / 5) * 5)
  
  p <- ggplot(filter(studies, !is.na(year)), aes(x = year)) +
    geom_bar(fill = fill, width = 0.8) +
    scale_x_continuous(breaks = seq(lims[1], lims[2], 5), limits = lims + c(-0.5, 0.5)) +
    scale_y_continuous(breaks = function(l) seq(0, floor(l[2]), by = if (l[2] > 8) 2 else 1),
                       expand = expansion(mult = c(0, 0.05))) +
    labs(x = "Year of publication", y = "Number of studies") +
    theme_minimal(base_size = text_size) +
    theme(panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(),
          axis.line.x = element_line(colour = "grey40"))
  attr(p, "summary") <- summary
  p
}

#==========================================================
# plot_distribution(): evidence distribution of one archetype by food group, practice and outcome
#==========================================================
# long        comparisons used in the analysis of one archetype (e.g. arc.long filtered by archetype),
#             with study_id and effect_size_id
# cols        named vector: columns to plot, named by their panel title (a), b), c)...)
# x_title     x-axis title of each panel
# fill        bar colour
# text_size   font size in points at print size
#
# Each bar shows the number of comparisons, with the number of studies in brackets.
# Returns a patchwork; attr(result, "n_rows") gives the rows of the longest panel, to set the height
# when saving (e.g. height = 0.17 * n_rows + 0.6).
#==========================================================
plot_distribution <- function(long,
                              cols      = c("a)" = "food_group",
                                            "b)" = "T_practice",
                                            "c)" = "outcome_group"),
                              fill      = "#08519C",
                              x_title   = "Comparisons (studies)",
                              text_size = 8) {
  
  bar_panel <- function(col, title) {
    d <- long %>%
      group_by(x = as.character(.data[[col]])) %>%
      summarise(studies = n_distinct(study_id), comparisons = n_distinct(effect_size_id), .groups = "drop") %>%
      mutate(x = reorder(x, comparisons))
    
    ggplot(d, aes(x = comparisons, y = x)) +
      geom_col(fill = fill, width = 0.7) +
      geom_text(aes(label = paste0(formatC(comparisons, big.mark = ",", format = "d"), " (", studies, ")")),
                hjust = -0.1, size = (text_size - 1) / .pt) +
      scale_x_continuous(expand = expansion(mult = c(0, 0.55))) +
      coord_cartesian(clip = "off") +                       # labels of the longest bar are not cut
      labs(title = title, x = x_title, y = NULL) +
      theme_minimal(base_size = text_size) +
      theme(panel.grid = element_blank(), axis.text.x = element_blank(),
            axis.title.x = element_text(size = text_size - 0.5),
            axis.text.y = element_text(colour = "black"),
            plot.title = element_text(face = "bold", size = text_size, hjust = 0),
            plot.title.position = "plot")
  }
  
  panels <- Map(bar_panel, cols, names(cols))
  
  p <- patchwork::wrap_plots(panels, nrow = 1)
  attr(p, "n_rows") <- max(vapply(cols, function(col) n_distinct(long[[col]]), numeric(1)))
  p
}

#==================================================================================================
#--- Table of agro-ecological zones and evidence per zone (report table) ----
# arc, rule      archetype polygons and high-priority rule
# aez_raster     GAEZ raster of the archetype's country; lookup: GAEZ_57_lookup.csv (value, label)
# sel            output of select_evidence() for this archetype
# pool           comparisons after reclassification (effect_size_id, study_id)
# points_pool    output of make_points() for the pool (site geometries)
# aez_rasters    list of GAEZ rasters (country and neighbours), as in site_aez()
# min_share      share (%) defining the main zones
#
# One row per agro-ecological zone present in the high-priority areas, ordered by share, with the
# studies and comparisons located within the high-priority areas (before any extension) and those
# added by each extension step (counted in the main zones only). Zones covering less than 0.1% and
# without evidence are dropped. Comparisons with sites in several zones are counted in each zone,
# so the Total row (distinct studies and comparisons) can be lower than the sum of the rows.
#==================================================================================================
aez_table <- function(arc, rule, aez_raster, lookup, sel, pool, points_pool, aez_rasters, min_share = 10) {
  
  pr    <- arc[with(arc, eval(str2lang(rule))) %in% TRUE, ]
  steps <- c("High-priority areas", "Same zones, same country", "Same zones, neighbouring countries")
  cols  <- c(rbind(paste0("Studies (", steps, ")"), paste0("Comparisons (", steps, ")")))
  
  # share of the high-priority areas covered by each zone
  v <- terra::extract(aez_raster, terra::vect(st_transform(pr, terra::crs(aez_raster))))[, 2]
  zones <- tibble(aez = as.integer(v)) %>% filter(!is.na(aez)) %>% count(aez, name = "cells") %>%
    mutate(share = round(100 * cells / sum(cells), 1)) %>% select(-cells)
  
  # zone of each site used: sites inside the high-priority areas for the comparisons selected by
  # location, all sites for the comparisons added by the extension
  pts <- points_pool %>% inner_join(sel$ids, by = "effect_size_id")
  inside <- lengths(st_intersects(st_transform(pts, st_crs(pr)), pr)) > 0
  pts <- pts[pts$selection != "High-priority areas" | inside, ]
  pts$aez <- NA_integer_
  for (r in aez_rasters)                                   # zone of each site, in the country or a neighbour
    pts$aez <- coalesce(pts$aez, as.integer(terra::extract(r, terra::vect(st_transform(pts, terra::crs(r))))[, 2]))
  # added comparisons: only their sites in the main zones (the zones they were added for)
  main <- zones$aez[zones$share >= min_share]
  
  ev <- pts %>% st_drop_geometry() %>% filter(!is.na(aez)) %>%
    filter(selection == "High-priority areas" | aez %in% main) %>%   # added comparisons: sites in the main zones only
    distinct(effect_size_id, selection, aez) %>%
    left_join(distinct(pool, effect_size_id, study_id), by = "effect_size_id") %>%
    mutate(selection = factor(selection, levels = steps))
  
  wide <- function(d, ...) d %>%
    group_by(..., selection, .drop = FALSE) %>%
    summarise(Studies = n_distinct(study_id), Comparisons = n_distinct(effect_size_id), .groups = "drop") %>%
    pivot_longer(c(Studies, Comparisons)) %>%
    mutate(col = paste0(name, " (", selection, ")")) %>%
    select(-selection, -name) %>%
    pivot_wider(names_from = col, values_from = value)
  
  rows <- zones %>%
    full_join(wide(ev, aez), by = "aez") %>%
    left_join(transmute(lookup, aez = as.integer(value), `Agroecological zone` = label), by = "aez") %>%
    mutate(share = coalesce(share, 0), `Main zone` = if_else(share >= min_share, "Yes", "No")) %>%
    filter(share >= 0.1 | rowSums(across(any_of(cols)), na.rm = TRUE) > 0) %>%   # drop slivers without evidence
    arrange(desc(share)) %>%
    select(`Agroecological zone`, `Share of high-priority areas (%)` = share, `Main zone`, any_of(cols))
  
  total <- bind_cols(tibble(`Agroecological zone` = "Total", `Share of high-priority areas (%)` = 100, `Main zone` = ""),
                     wide(ev))
  
  bind_rows(rows, total) %>%
    mutate(across(any_of(cols), ~ coalesce(.x, 0L))) %>%
    select(names(rows))
}
#==================================================================================================
#--- Table of evidence per high-priority area unit (e.g. county; vector archetypes only) ----
# arc, rule     archetype polygons and high-priority rule
# sel           output of select_evidence() for this archetype
# pool          comparisons after reclassification (effect_size_id, study_id)
# points_pool   output of make_points() for the pool (site geometries)
# name_col      column with the unit name (e.g. county)
# class_col     column with the priority class shown in the table (e.g. criteria met)
#
# One row per high-priority unit, including units without evidence, ordered by priority class and
# number of comparisons, with the studies and comparisons located within it (comparisons selected by
# location only). Comparisons with sites in several units are counted in each, so the Total row
# (distinct studies and comparisons) can be lower than the sum of the rows.
#==================================================================================================
county_table <- function(arc, rule, sel, pool, points_pool,
                         name_col = "NAME_1", class_col = "Criteria_Met_Count") {
  
  pr <- arc[with(arc, eval(str2lang(rule))) %in% TRUE, ]
  units <- st_drop_geometry(pr) %>% transmute(unit = .data[[name_col]], class = .data[[class_col]])
  
  ids <- sel$ids$effect_size_id[sel$ids$selection == "High-priority areas"]
  ev  <- points_pool %>%
    filter(effect_size_id %in% ids) %>%
    st_transform(st_crs(pr)) %>%
    st_join(pr[, name_col], left = FALSE) %>%
    st_drop_geometry() %>%
    transmute(effect_size_id, unit = .data[[name_col]]) %>%
    distinct() %>%
    left_join(distinct(pool, effect_size_id, study_id), by = "effect_size_id")
  
  rows <- units %>%
    left_join(ev %>% group_by(unit) %>%
                summarise(Studies = n_distinct(study_id), Comparisons = n_distinct(effect_size_id), .groups = "drop"),
              by = "unit") %>%
    mutate(Studies = coalesce(Studies, 0L), Comparisons = coalesce(Comparisons, 0L)) %>%
    arrange(desc(class), desc(Comparisons), unit)
  
  total <- tibble(unit = "Total", class = NA,
                  Studies = n_distinct(ev$study_id), Comparisons = n_distinct(ev$effect_size_id))
  
  bind_rows(rows, total) %>%
    rename(!!name_col := unit, !!class_col := class)
}
