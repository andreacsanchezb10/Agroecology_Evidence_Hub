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
# x             sf / SpatRaster object, or a path to a .gpkg / .tif
# class_col     column holding the class (ignored for rasters)
# n_criteria    total number of criteria -> labels "k of n met"; top class gets "(Core Priority)"
# label_col     column with ready-made labels (use instead of n_criteria, e.g. "tier_label")
# reverse       TRUE when class 1 is the highest priority (e.g. tier)
# scope_col     column flagging counties in scope (e.g. "ASAL_County"); others are drawn grey
# scope_value   value of scope_col that means "in scope"
# outline_col   0/1 flag column drawn as a bold outline (e.g. "Low_Female_Education_Flag")
# outline_label legend text for the outline
# zero_na       rasters: treat 0 (no criteria met) as blank instead of a class
# legend_title  legend title
#
# Returns a ggplot; save it with ggsave() to your own Downloads folder.
#==========================================================

plot_archetype <- function(x,
                           class_col     = "Criteria_Met_Count",
                           n_criteria    = NULL,
                           label_col     = NULL,
                           reverse       = FALSE,
                           scope_col     = NULL,
                           scope_value   = "Yes",
                           outline_col   = NULL,
                           outline_label = "Flagged",
                           zero_na       = FALSE,
                           legend_title  = NULL) {

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
    labs <- c(labs, "Out of scope" = paste0("Out of scope (", scope_col, " != ", scope_value, ")"))[cls]
  }
  x$class <- factor(x$class, levels = cls)

  p <- ggplot() +
    geom_sf(data = x, aes(fill = class), colour = "grey40", linewidth = 0.2) +
    scale_fill_manual(values = cols, labels = labs, name = legend_title, drop = TRUE)

  if (!is.null(outline_col)) {
    p <- p +
      geom_sf(data = x[x[[outline_col]] %in% 1, ], aes(colour = "outline"),
              fill = NA, linewidth = 0.9) +
      scale_colour_manual(values = c(outline = "#1565C0"), labels = outline_label, name = NULL) +
      guides(fill = guide_legend(order = 1), colour = guide_legend(order = 2))
  }

  p + theme_void()
}
