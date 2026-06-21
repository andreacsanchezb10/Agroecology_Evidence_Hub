# =============================================================================
# fun_comparison_practice.R
# Source this file to load only:  apply_CT_subpractie | summarise_CT_subpractice
# =============================================================================


# =============================================================================
# Functions to build "Control vs Treatment" comparison columns for each
# agricultural practice, based on paired C_<practice>_subpractice and
# T_<practice>_subpractice columns.
# =============================================================================
local({
  
  library(dplyr)
  
  # ---------------------------------------------------------------------------
  # Constants (local scope only)
  # ---------------------------------------------------------------------------
  
  PRACTICES <- c(
    "tillage",
    "planting",
    "varietal_crop",
    "intercrop",
    "crop_seq",
    "agrof",
    "fert",
    "chem",
    "residues",
    "ph",
    "irrig",
    "watharv"
  )
  
  # -----------------------------------------------------------------------------
  # Helper Functions
  # -----------------------------------------------------------------------------
  #' Build a "Control vs Treatment" label from two subpractice columns
  #'
  #' Returns a formatted string "C: <c_val>_vs_T: <t_val>" when both values are
  #' non-empty, otherwise returns NA_character_.
  #'
  #' @param c_col Character vector — values from the Control subpractice column.
  #' @param t_col Character vector — values from the Treatment subpractice column.
  #'
  #' @return Character vector of CT labels or NA.
  #'
  #' @examples
  #' ct_subpractice("conventional", "no-till")  # "C: conventional_vs_T: no-till"
  #' ct_subpractice("", "no-till")              # NA
  #' ct_subpractice(NA, "no-till")             # NA (treated as empty by case_when)
  
  ct_subpractice <- function(c_col, t_col) {
    dplyr::case_when(
      c_col != "" & t_col != ""
      ~ paste0("C: ", c_col, "_vs_", "T: ", t_col),
      TRUE ~ NA_character_
    )
  }
  
  get_ct_columns <- function(data) {
    grep("^CT_", names(data), value = TRUE)
  }
  
  add_subpractice_ct_columns <- function(data, practices = PRACTICES) {
    c_cols <- paste0("C_", practices, "_subpractice")
    
    missing_cols <- setdiff(c_cols, names(data))
    if (length(missing_cols) > 0) {
      warning(
        "The following expected Control columns are missing and will be skipped:\n  ",
        paste(missing_cols, collapse = "\n  ")
      )
      c_cols <- intersect(c_cols, names(data))
    }
    
    data %>%
      dplyr::mutate(
        dplyr::across(
          .cols  = dplyr::all_of(c_cols),
          .fns   = ~ ct_subpractice(.x, get(sub("^C_", "T_", dplyr::cur_column()))),
          .names = "CT_{sub('C_', '', .col)}"
        )
      )
  }
  
  lookup_side <- function(side_str, lookup) {
    tokens <- stringr::str_squish(stringr::str_split(side_str, "\\.\\.")[[1]])
    out    <- unname(lookup[tokens])
    if (any(is.na(out))) return(NA_character_)
    paste(out, collapse = "..")
  }
  
  apply_lookup_CT_internal <- function(df, ref, key_col, value_col, src_col, new_col) {
    lookup <- ref %>%
      dplyr::transmute(
        .key   = stringr::str_squish(.data[[key_col]]),
        .value = stringr::str_squish(.data[[value_col]])
      ) %>%
      dplyr::distinct() %>%
      tibble::deframe()
    
    df %>%
      dplyr::mutate(
        !!new_col := purrr::map_chr(.data[[src_col]], \(ct) {
          if (is.na(ct)) return(NA_character_)
          parts <- stringr::str_split(ct, "_vs_T: ")[[1]]
          if (length(parts) != 2) return(NA_character_)
          c_side <- stringr::str_remove(parts[1], "^C: ")
          t_side <- parts[2]
          c_out  <- lookup_side(c_side, lookup)
          t_out  <- lookup_side(t_side, lookup)
          if (any(is.na(c(c_out, t_out)))) return(NA_character_)
          paste0("C: ", c_out, "_vs_T: ", t_out)
        })
      )
  }
  
  # ---------------------------------------------------------------------------
  # Public functions — exported to the calling environment
  # ---------------------------------------------------------------------------
  # -----------------------------------------------------------------------------
  # Utility / Inspection Helpers
  # -----------------------------------------------------------------------------
  
  #' List all CT columns present in a data frame
  #'
  #' @param data A data frame (output of \code{\link{add_ct_columns}}).
  #'
  #' @return Character vector of CT_ column names.
  
  
  apply_CT_subpractie <<- function(data) {
    add_subpractice_ct_columns(data, practices = PRACTICES)
  }
  
  summarise_CT_subpractice <<- function(data) {
    ct_cols <- get_ct_columns(data)
    
    if (length(ct_cols) == 0) {
      message("No CT_ columns found. Run apply_CT_subpractie() first.")
      return(tibble::tibble())
    }
    
    data %>%
      dplyr::summarise(
        dplyr::across(
          dplyr::all_of(ct_cols),
          list(
            n_non_na   = ~ sum(!is.na(.x)),
            pct_non_na = ~ round(mean(!is.na(.x)) * 100, 1)
          )
        )
      ) %>%
      tidyr::pivot_longer(
        everything(),
        names_to      = c("ct_column", ".value"),
        names_pattern = "^(.+)_(n_non_na|pct_non_na)$"
      )
  }
  
  

# =============================================================================
# Functions to reclassify "Control vs Treatment" subpractices into practices for each
# agricultural practice, based on paired CT_<practice>_subpractice columns.
# =============================================================================
#' Apply lookup reclassification from subpractice to practice for all practices
#'
#' Iterates over every practice in PRACTICES. For each one, if the column
#' CT_<practice>_subpractice exists in \code{data}, it creates a new column
#' CT_<practice>_practice by mapping subpractice labels to practice labels
#' via \code{ref}.
#'
#' @param data     A data frame (output of apply_CT_subpractie).
#' @param ref      Reference data frame with the lookup table.
#' @param key_col  Column name in \code{ref} holding subpractice values.
#' @param value_col Column name in \code{ref} holding practice values.
#' @param practices Character vector of practice names (default: PRACTICES).
#'
#' @return The data frame with CT_<practice>_practice columns appended.
#'
#' @examples
#' fomd10_analysis <- apply_CT_subpractie(fomd10)
#' fomd10_analysis <- apply_CT_practice(fomd10_analysis, ref = fomd01.practices,
#'                                       key_col = "subpractice", value_col = "practice")
  apply_lookup_CT <<- function(df, ref, key_col, value_col, src_col, new_col) {
    apply_lookup_CT_internal(df, ref, key_col, value_col, src_col, new_col)
  }
  
  apply_CT_practice <<- function(data,
                                 ref       = fomd01.practices,
                                 key_col   = "subpractice",
                                 value_col = "practice",
                                 practices = PRACTICES) {
    for (practice in practices) {
      src_col <- paste0("CT_", practice, "_subpractice")
      new_col <- paste0("CT_", practice, "_practicetheme")
      
      if (!src_col %in% names(data)) {
        message("Skipping '", practice, "': column '", src_col, "' not found.")
        next
      }
      
      data <- apply_lookup_CT_internal(
        df        = data,
        ref       = ref,
        key_col   = key_col,
        value_col = value_col,
        src_col   = src_col,
        new_col   = new_col
      )
    }
    data
  }
  
  # =============================================================================
  # Functions checker helper
  # Show subpractice values that have no matching practice for all practices
  # =============================================================================
  #' Show subpractice values that have no matching practice for all practices
  #'
  #' For each practice, finds rows where CT_<practice>_subpractice is not NA
  #' but CT_<practice>_practice is NA — meaning the lookup failed.
  #' Returns a single tidy data frame with columns: practice, doi, CT_subpractice.
  #'
  #' @param data      A data frame (output of apply_CT_practice).
  #' @param id_col    Name of the row identifier column (default: "doi").
  #' @param practices Character vector of practice names (default: PRACTICES).
  #'
  #' @return A tibble with columns: practice, <id_col>, CT_subpractice.
  #'
  #' @examples
  #' diagnose_CT_missing_practice(fomd10_analysis)
  #' diagnose_CT_missing_practice(fomd10_analysis, id_col = "doi")
  diagnose_CT_missing_practice <<- function(data, id_col = "doi", practices = PRACTICES) {
    purrr::map(practices, \(practice) {
      sub_col  <- paste0("CT_", practice, "_subpractice")
      prac_col <- paste0("CT_", practice, "_practice")
      
      # Skip if either column is absent
      if (!sub_col %in% names(data) || !prac_col %in% names(data)) return(NULL)
      
      rows <- data %>%
        dplyr::filter(!is.na(.data[[sub_col]]) & is.na(.data[[prac_col]])) %>%
        dplyr::select(dplyr::all_of(c(id_col, sub_col))) %>%
        dplyr::rename(CT_subpractice = dplyr::all_of(sub_col)) %>%
        dplyr::mutate(practice = practice, source_col = sub_col, .before = 1)
      
      if (nrow(rows) == 0) return(NULL)
      rows
    }) %>%
      purrr::compact() %>%
      dplyr::bind_rows()
  }
  


# =============================================================================
# Functions checker helper
# Show subpractice values that have no matching practice for all practices
# =============================================================================



apply_CT_practice_theme <<- function(data,
                               ref       = fomd01.practices,
                               key_col   = "subpractice",
                               value_col = "theme",
                               practices = PRACTICES) {
  for (practice_theme in practices) {
    src_col <- paste0("CT_", practice_theme, "_subpractice")
    new_col <- paste0("CT_", practice_theme, "_practicetheme")
    
    if (!src_col %in% names(data)) {
      message("Skipping '", practice_theme, "': column '", src_col, "' not found.")
      next
    }
    
    data <- apply_lookup_CT_internal(
      df        = data,
      ref       = ref,
      key_col   = key_col,
      value_col = value_col,
      src_col   = src_col,
      new_col   = new_col
    )
  }
  data
}
  
})