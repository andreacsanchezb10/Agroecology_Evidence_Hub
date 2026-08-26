# =============================================================================
# combine_09FOMD_verfied sheets
# =============================================================================
# Purpose:
#   Reads the verified extracted data from primary studies included in
#   selected meta-datasets (e.g. Paut et al. and Jones et al.), where each
#   primary study's extraction lives in its own .xlsm file within a folder,
#   under a common sheet name. This function reads that sheet from every
#   file in the folder and stacks (row-binds) them into a single combined
#   data frame, ready for downstream cleaning and effect size calculation.

# What it does, step by step:
#   1. Lists all files in `folder_path` matching the given `pattern`
#      (by default, all files ending in .xlsm).
#   2. For each file, reads the sheet named `sheet_name`, skipping the first
#      row of the sheet (e.g. an instructions/title row above the real
#      column headers), and reads all columns as text to avoid type
#      mismatches (e.g. one file having a column as numeric and another
#      having it as character).
#   3. If `safe = TRUE`, any file that fails to read (e.g. because it does
#      not contain a sheet with that name) is skipped instead of stopping
#      the whole function, and a warning lists which files were skipped.
#   4. Combines all successfully-read sheets into one data frame, adding a
#      `source_file` column that records which original file each row
#      came from.
#   5. Removes any rows where `ss_id` is NA (safety filter).
#
# Arguments:
#   folder_path  - path to the folder containing the .xlsm files
#   sheet_name   - name of the sheet to read from each file
#   pattern      - regex pattern to match files (default: "\\.xlsm$")
#   safe         - if TRUE, skip unreadable files instead of erroring out
#
# Returns:
#   A single combined data frame (tibble) with all rows from all files,
#   plus a source_file column.
#
# Usage example:
#   fomd_data <- combine_xlsm_sheets(
#     folder_path = "path/to/folder_1",
#     sheet_name  = "09_FOMD_metadata_extraction_lon"
#   )
# =============================================================================

library(readxl)
library(dplyr)
library(purrr)

combine_09FOMD_verified <- function(subfolder,
                                    verified_papers_path = "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/03.extraction/02.09_FOMD_extraction/01_verified_papers/",
                                    sheet_name = "09_FOMD_metadata_extraction_lon",
                                    pattern = "\\.xlsm$",
                                    safe = TRUE) {
  
  folder_path <- paste0(verified_papers_path, subfolder)
  
  xlsm_files <- list.files(folder_path, pattern = pattern, full.names = TRUE)
  n_available <- length(xlsm_files)
  
  if (n_available == 0) {
    warning("No files matching '", pattern, "' found in ", folder_path)
    return(NULL)
  }
  
  read_fun <- function(f) {
    df <- read_excel(f, sheet = sheet_name, col_types = "text")  # header = row 1
    df <- df %>% slice(-1)  # drop first data row of THIS file

    
    # Harmonize column names from older versions of the extraction sheet
    # (names = old/legacy name, values = current/canonical name)
    legacy_renames <- c(residues_unit_K = "residues_K_unit",
                        ler_var_value_product_component02="ler_var_value_product02" ,
                        outc_var_value_l= "out_var_value_l",
                        outc_var_value_u= "out_var_value_u",
                        ler_value_product01="pler_value_product01",
                        ler_var_value_product01="pler_var_value_product01",
                        ler_value_product02="pler_value_product02",
                        ler_var_value_product02="pler_var_value_product02",
                        ler_value_product03="pler_value_product03",
                        ler_var_value_product03="pler_var_value_product03",
                        ler_var_total="ler_var_value_total"
                        
                        )
    for (old_name in names(legacy_renames)) {
      if (old_name %in% names(df)) {
        names(df)[names(df) == old_name] <- legacy_renames[[old_name]]
      }
    }
    

    df
  }
  
  if (safe) {
    read_fun_safe <- possibly(read_fun, otherwise = NULL, quiet = FALSE)
  } else {
    read_fun_safe <- read_fun
  }
  
  result <- xlsm_files %>%
    set_names(basename(.)) %>%
    map(read_fun_safe)
  
  failed_files <- names(result)[map_lgl(result, is.null)]
  n_failed <- length(failed_files)
  n_read   <- n_available - n_failed
  
  if (n_failed > 0) {
    warning("Skipped ", n_failed, " file(s) (sheet not found or read error): ",
            paste(failed_files, collapse = ", "))
  }
  
  combined <- result %>%
    compact() %>%
    bind_rows(.id = "source_file") %>%
    filter(!is.na(ss_id))
  
  n_files_in_combined <- n_distinct(combined$source_file)
  
  # --- Summary ---
  summary_msg <- paste0(
    "\n--- combine_09FOMD_verified() summary ---\n",
    "Folder:                ", folder_path, "\n",
    "Files available:        ", n_available, "\n",
    "Files successfully read/combined: ", n_read,
    " (", n_files_in_combined, " distinct in final data)\n",
    "Files skipped:          ", n_failed,
    if (n_failed > 0) paste0(" (", paste(failed_files, collapse = ", "), ")") else "",
    "\nTotal rows in combined data: ", nrow(combined), "\n",
    "--------------------------------------\n"
  )
  
  message(summary_msg)
  
  attr(combined, "summary") <- list(
    folder_path      = folder_path,
    n_available      = n_available,
    n_read           = n_read,
    n_failed         = n_failed,
    failed_files     = failed_files,
    n_rows_combined  = nrow(combined)
  )
  
  combined
}

#------------------------------------------------------------------------------
# Check that every verified-paper .xlsm in a subfolder shares the same columns
#------------------------------------------------------------------------------
check_09FOMD_column_consistency <- function(subfolder,
                                            verified_papers_path = "C:/Users/andreasanchez/OneDrive - CGIAR/Alliance-Agroecology Evidence Hub - General/Agroecology_Evidence_Hub/02.FOMD/03.extraction/02.09_FOMD_extraction/01_verified_papers/",
                                            sheet_name = "09_FOMD_metadata_extraction_lon",
                                            pattern = "\\.xlsm$") {
  
  folder_path <- paste0(verified_papers_path, subfolder)
  xlsm_files  <- list.files(folder_path, pattern = pattern, full.names = TRUE)
  
  col_names_by_file <- xlsm_files %>%
    set_names(basename(.)) %>%
    map(~ names(read_excel(.x, sheet = sheet_name, n_max = 0)))
  
  n_cols <- map_int(col_names_by_file, length)
  cat("--- Number of columns per file ---\n")
  print(n_cols)
  
  all_cols    <- Reduce(union, col_names_by_file)
  common_cols <- Reduce(intersect, col_names_by_file)
  
  cat("\nTotal distinct columns across all files:", length(all_cols), "\n")
  cat("Columns common to ALL files:            ", length(common_cols), "\n")
  
  if (length(common_cols) < length(all_cols)) {
    cat("\n--- Per-file column differences ---\n")
    for (f in names(col_names_by_file)) {
      missing <- setdiff(all_cols, col_names_by_file[[f]])
      extra   <- setdiff(col_names_by_file[[f]], common_cols)
      if (length(missing) > 0 || length(extra) > 0) {
        cat("\nFile:", f, "\n")
        if (length(missing) > 0) cat("  Missing (present in other files, absent here):\n    ", paste(missing, collapse = ", "), "\n")
        if (length(extra) > 0)   cat("  Extra / not shared by all files:\n    ", paste(extra, collapse = ", "), "\n")
      }
    }
  } else {
    cat("\nAll files share exactly the same columns.\n")
  }
  
  invisible(list(n_cols = n_cols, all_cols = all_cols, common_cols = common_cols, col_names_by_file = col_names_by_file))
}

