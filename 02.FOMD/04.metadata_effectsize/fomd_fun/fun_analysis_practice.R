# =============================================================================
# build_analytical_columns.R
# =============================================================================
# Builds thematic analytical columns for meta-regression.
# 
# HOW TO USE IN YOUR EXISTING PIPELINE
# ─────────────────────────────────────────────────────────────────────────────
# This script is sourced at the end of your main script, after the CT_ columns
# have already been built by your existing functions. Add these two lines after
# your apply_CT_practice_theme() call:
#
#   source(file.path(path.metadata.effectsize, "/fomd_fun/build_analytical_columns.R"))
#   fomd10.clean <- build_analytical_columns(fomd10.clean)
#
# That is all. The function takes your existing fomd10.clean data frame and
# returns it with the new columns appended. Nothing else in your pipeline changes.
#
# OUTPUT COLUMNS ADDED
# ─────────────────────────────────────────────────────────────────────────────
# BLOCK 1 — Thematic analytical columns (one triplet per group)
#   diversification_spatial_subpractice / _practice / _theme
#   diversification_temporal_subpractice / _practice / _theme
#   soil_management_subpractice / _practice / _theme
#   nutrient_management_subpractice / _practice / _theme
#   pest_management_subpractice / _practice / _theme
#   water_management_subpractice / _practice / _theme
#   variety_management_subpractice / _practice / _theme
#   biomass_management_subpractice / _practice / _theme  ← pending split decision
#   planting_management_subpractice / _practice / _theme
#
# BLOCK 2 — Diagnostic flags
#   n_focal_groups   number of focal analytical groups active per row
#   is_bundled       TRUE when n_focal_groups > 1
#   has_variety_bg   TRUE when variety_management is active as background
#   is_vet_chem      TRUE when chem is active but unmapped at practice level
#
# LABEL FORMAT (merge_ct rules)
# ─────────────────────────────────────────────────────────────────────────────
# Single domain, no bundle:
#   C: Monoculture_vs_T: Agroforestry
#
# Internal '..' bundle normalised:
#   C: Monoculture_vs_T: Relay Intercropping (N fixing and Non N fixing) + Green Manure (N fixing In Space)
#
# Two domains in same group merged:
#   C: Monoculture + Intercrop (N fixing)_vs_T: Living Fences or Hedgerows + Intercrop (N fixing)
#
# MODERATOR MODEL EXAMPLES
# ─────────────────────────────────────────────────────────────────────────────
#   ~ diversification_spatial_theme + nutrient_management_theme
#   ~ diversification_spatial_practice + nutrient_management_practice
# =============================================================================


# ── Configuration ─────────────────────────────────────────────────────────────

# Domain order within each group determines label order when multiple domains
# are active (first listed = first in the merged label)
.DOMAIN_GROUPS <- list(
  diversification_spatial  = c("agrof", "intercrop"),
  diversification_temporal = c("crop_seq"),
  soil_management          = c("tillage", "ph"),
  nutrient_management      = c("fert"),
  pest_management          = c("chem"),
  water_management         = c("irrig", "watharv"),
  variety_management       = c("varietal_crop"),
  biomass_management       = c("residues"),   # pending split decision
  planting_management      = c("planting")
)

.LEVELS <- c(
  subpractice = "_subpractice",
  practice    = "_practice",
  theme       = "_practicetheme"
)

.FOCAL_GROUPS <- c(
  "diversification_spatial", "diversification_temporal",
  "soil_management", "nutrient_management", "pest_management",
  "water_management", "biomass_management"
)


# ── merge_ct() ────────────────────────────────────────────────────────────────

#' Merge one or more "C: X_vs_T: Y" strings into a single clean label.
#'
#' Handles two levels of bundling present in the raw CT_ columns:
#'
#'   Internal '..' bundles (multiple practices within one CT_ value):
#'     "C: Monoculture_vs_T: Relay Intercropping..Green Manure (N fixing In Space)"
#'     → "C: Monoculture_vs_T: Relay Intercropping + Green Manure (N fixing In Space)"
#'
#'   Cross-domain bundles (multiple domains in the same analytical group):
#'     c("C: Monoculture_vs_T: Living Fences or Hedgerows",
#'       "C: Monoculture_vs_T: Intercrop (N fixing and Non N fixing)")
#'     → "C: Monoculture_vs_T: Living Fences or Hedgerows + Intercrop (N fixing and Non N fixing)"
#'
#' Consecutive duplicate entries on either side are removed automatically
#' (e.g. when two domains share the same control, Monoculture appears once).
#' Single clean values pass through unchanged.
#'
#' @param vals Character vector of raw CT_ values (NAs silently dropped)
#' @return Single merged string, or NA_character_ if all inputs are NA

merge_ct <- function(vals) {
  vals <- vals[!is.na(vals)]
  if (length(vals) == 0L) return(NA_character_)
  
  c_parts <- character(0)
  t_parts <- character(0)
  
  for (v in vals) {
    sides   <- strsplit(v, "_vs_T: ", fixed = TRUE)[[1]]
    c_raw   <- sub("^C: ", "", sides[1])
    t_raw   <- if (length(sides) >= 2L) sides[2] else ""
    c_parts <- c(c_parts, strsplit(c_raw, "..", fixed = TRUE)[[1]])
    t_parts <- c(t_parts, strsplit(t_raw, "..", fixed = TRUE)[[1]])
  }
  
  dedup <- function(x) {
    x <- trimws(x)
    x[c(TRUE, x[-1] != x[-length(x)])]
  }
  
  paste0(
    "C: ", paste(dedup(c_parts), collapse = " + "),
    "_vs_T: ", paste(dedup(t_parts), collapse = " + ")
  )
}


# ── build_analytical_columns() ───────────────────────────────────────────────

#' Add thematic analytical columns to an existing fomd data frame.
#'
#' Designed to run after apply_CT_subpractice(), apply_CT_practice(), and
#' apply_CT_practice_theme() have already been called. Uses the CT_ columns
#' those functions produce as inputs.
#'
#' @param df   Your fomd10.clean data frame
#' @param verbose Print progress messages (default TRUE)
#' @return The same data frame with new columns appended

build_analytical_columns <- function(df, verbose = TRUE) {
  
  if (verbose) message("Building analytical columns ...")
  
  # ── Block 1: thematic analytical columns ──────────────────────────────────
  for (grp in names(.DOMAIN_GROUPS)) {
    domains <- .DOMAIN_GROUPS[[grp]]
    
    for (lv in names(.LEVELS)) {
      raw_cols <- intersect(paste0("CT_", domains, .LEVELS[lv]), names(df))
      col_out  <- paste0(grp, "_", lv)
      
      if (length(raw_cols) == 0L) {
        df[[col_out]] <- NA_character_
        next
      }
      
      df[[col_out]] <- apply(df[raw_cols], 1, merge_ct)
      
      if (verbose) {
        n_filled <- sum(!is.na(df[[col_out]]))
        message(sprintf("  %-40s  %s non-NA rows",
                        col_out, formatC(n_filled, format = "d", big.mark = ",")))
      }
    }
  }
  
  # ── Block 2: diagnostic flags ──────────────────────────────────────────────
  focal_sub_cols <- intersect(paste0(.FOCAL_GROUPS, "_subpractice"), names(df))
  
  df <- df |>
    mutate(
      n_focal_groups = rowSums(!is.na(across(all_of(focal_sub_cols)))),
      is_bundled     = n_focal_groups > 1,
      has_variety_bg = !is.na(variety_management_subpractice),
      is_vet_chem    = !is.na(pest_management_subpractice) &
        is.na(pest_management_practice)
    )
  
  if (verbose) {
    message("\n  Diagnostic flags:")
    message(sprintf("    n_focal_groups distribution: %s",
                    paste(names(table(df$n_focal_groups)),
                          table(df$n_focal_groups), sep = "=", collapse = "  ")))
    message(sprintf("    is_bundled     : %s rows (%.1f%%)",
                    formatC(sum(df$is_bundled), format = "d", big.mark = ","),
                    100 * mean(df$is_bundled)))
    message(sprintf("    has_variety_bg : %s rows (%.1f%%)",
                    formatC(sum(df$has_variety_bg), format = "d", big.mark = ","),
                    100 * mean(df$has_variety_bg)))
    message(sprintf("    is_vet_chem    : %s rows (%.1f%%)",
                    formatC(sum(df$is_vet_chem), format = "d", big.mark = ","),
                    100 * mean(df$is_vet_chem)))
    message("Done.")
  }
  
  df
}


# ── Helper functions ──────────────────────────────────────────────────────────

#' Filter rows by a comparison string at a given level.
#'
#' @param df    Your data frame (build_analytical_columns must have run)
#' @param query Substring to search (fixed string, case-sensitive)
#' @param level "subpractice" | "practice" | "theme"
#' @param group One of the analytical group names (e.g. "diversification_spatial"),
#'              or NULL to search across all groups at that level.
#'
#' Examples:
#'   filter_by(fomd10.clean, "Hedgerows")
#'   filter_by(fomd10.clean, "Agroforestry", level = "theme", group = "diversification_spatial")

filter_by <- function(df, query, level = "subpractice", group = NULL) {
  col <- if (!is.null(group)) {
    paste0(group, "_", level)
  } else {
    # search across all group columns at this level and return any match
    cols <- paste0(names(.DOMAIN_GROUPS), "_", level)
    cols <- intersect(cols, names(df))
    matches <- rowSums(
      sapply(cols, function(c) grepl(query, df[[c]], fixed = TRUE) & !is.na(df[[c]]))
    ) > 0
    return(df[matches, ])
  }
  if (!col %in% names(df)) stop("Column '", col, "' not found.")
  df[!is.na(df[[col]]) & grepl(query, df[[col]], fixed = TRUE), ]
}

#' Count observations per unique comparison at a given level.
#'
#' @param df    Your data frame (build_analytical_columns must have run)
#' @param level "subpractice" | "practice" | "theme"
#' @param group One of the analytical group names, or NULL for all groups.
#' @param n     Number of top comparisons to return (default 20)
#'
#' Examples:
#'   top_comparisons(fomd10.clean, "theme")
#'   top_comparisons(fomd10.clean, "practice", group = "diversification_spatial", n = 10)

top_comparisons <- function(df, level = "theme", group = NULL, n = 20) {
  if (!is.null(group)) {
    col <- paste0(group, "_", level)
    if (!col %in% names(df)) stop("Column '", col, "' not found.")
    df |>
      filter(!is.na(.data[[col]])) |>
      count(.data[[col]], name = "n_obs", sort = TRUE) |>
      rename(comparison = 1) |>
      slice_head(n = n)
  } else {
    # combine all group columns at this level
    cols <- intersect(paste0(names(.DOMAIN_GROUPS), "_", level), names(df))
    purrr::map(cols, \(col)
               df |>
                 filter(!is.na(.data[[col]])) |>
                 count(group = sub(paste0("_", level), "", col),
                       comparison = .data[[col]], name = "n_obs")
    ) |>
      bind_rows() |>
      arrange(group, desc(n_obs)) |>
      slice_head(n = n, by = group)
  }
}