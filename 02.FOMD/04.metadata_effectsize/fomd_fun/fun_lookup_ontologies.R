# ============================================================
# lookup_helpers.R
# Reusable helpers for building and applying lookup vectors
# from a 01_FOMD_ontologies.
# ============================================================

#' Build a lookup vector and apply it to a data frame column
#'
#' @param df          The data frame to mutate (e.g. md.era.short.clean)
#' @param ref         Reference data frame (e.g. fomd01.outcomes)
#' @param key_col     Name of the key column in `ref`   (string, e.g. "subindicator")
#' @param value_col   Name of the value column in `ref` (string, e.g. "indicator")
#' @param src_col     Name of the source column in `df` to look up from (string)
#' @param new_col     Name of the new column to create in `df` (string)
#' @param sep         Separator used to split compound tokens (default: "..")
#'
#' @return The mutated data frame with `new_col` added/updated.
apply_lookup_ontologies <- function(df, path.metadata.structure,
                                    sheet_name, key_col, value_col,
                                    src_col, new_col, sep = "-") {
  
  ref <- read_xlsx(file.path(path.metadata.structure, "01_FOMD_ontologies.xlsx"), sheet = sheet_name)
  
  lookup <- ref %>%
    transmute(
      .key   = str_squish(.data[[key_col]]),
      .value = str_squish(.data[[value_col]])
    ) %>%
    distinct() %>%
    deframe()
  
  df <- df %>%
    mutate("{new_col}" := map_chr(str_split(str_squish(.data[[src_col]]), fixed(sep)), \(x) {
      out <- unname(lookup[str_squish(x)])
      out[is.na(out)] <- str_squish(x)[is.na(out)]
      paste(out, collapse = sep)
    }))
  
  #--- Quick checks
  cat("---", src_col, "(n distinct) ---\n"); print(length(unique(df[[src_col]])))
  cat("---", src_col, "---\n");              print(sort(unique(df[[src_col]])))
  cat("---", new_col, "(n distinct) ---\n"); print(length(unique(df[[new_col]])))
  cat("---", new_col, "---\n");              print(sort(unique(df[[new_col]])))
  
  df
}


apply_lookup_ontologies_ERA <- function(df, ref, key_col, value_col,
                         src_col, new_col, sep = "\\.\\.") {
  
  # 1. Build the named lookup vector from the reference table
  lookup <- ref %>%
    transmute(
      .key   = str_squish(.data[[key_col]]),
      .value = str_squish(.data[[value_col]])
    ) %>%
    distinct() %>%
    deframe()
  
  # 2. Apply the lookup, handling compound tokens joined by `sep`
  df %>%
    mutate(
      !!new_col := map_chr(
        str_split(str_squish(.data[[src_col]]), sep),
        \(x) {
          tokens <- str_squish(x)
          out    <- unname(lookup[tokens])
          if (any(is.na(out))) return(NA_character_)
          paste(out, collapse = "..")
        }
      )
    )
}