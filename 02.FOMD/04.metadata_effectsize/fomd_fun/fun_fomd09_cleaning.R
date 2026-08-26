# =============================================================================
# fun_cleaning_fomd09.R
# =============================================================================
# Purpose:
#   Reusable cleaning functions for 09_FOMD extraction data (fomd09), applied
#   identically regardless of which verified-papers source produced it.
# =============================================================================

library(dplyr)

#----------------------------------------------------------
#---- Convert to specify class ----
#----------------------------------------------------------
clean_fomd09_classes <- function(fomd09) {
  
  #--- Clean dates
  # Local to this function only — not exposed when this file is source()'d
  clean_date <- function(x) {
    x %>%
      na_if("Unspecified") %>%
      as.numeric() %>%
      as.Date(origin = "1899-12-30") %>%
      format("%d/%m/%Y")
  }
  
  date_cols <- c(
    #--planting_practice
    "planting_date_start", "planting_date_end",
    #--irrigation_practice
    "irrig_date_start", "irrig_date_end",
    #--harvest_practice
    "harvest_date_start", "harvest_date_end",
    #--postharvesting_practice
    "postharvest_date_start", "postharvest_date_end"
  )
  
  #--- Density columns (crop/tree/animal) to character
  density_cols <- names(fomd09)[
    startsWith(names(fomd09), "crop_tree_density") |
      startsWith(names(fomd09), "animal_density")
  ]
  
  fomd09.clean <- fomd09 %>%
    mutate(across(all_of(date_cols), clean_date)) %>%
    mutate(across(all_of(density_cols), as.character))
  
  #--- Quick checks: sort(unique(...)) for every column just transformed
  for (col in c(date_cols, density_cols)) {
    cat("---", col, "---\n")
    print(sort(unique(fomd09.clean[[col]])))
  }
  
  fomd09.clean
}

#----------------------------------------------------------
#---- Add bibliographic information from (04_FOMD_screening) ----
#----------------------------------------------------------
add_fomd09_bibliographic <- function(fomd09.clean, path.metadata.structure, metadata) {
  
  #04_FOMD_screening
  fomd04 <- read_xlsx(file.path(path.metadata.structure, "04_FOMD_screening.xlsx"), sheet = "04_FOMD_screening") %>%
    filter(ss_id == metadata) %>%
    filter(status == "I")
  
  cat("--- fomd04 study_id ---\n"); print(length(unique(fomd04$study_id)))
  
  fomd09.clean <- fomd09.clean %>%
    left_join(fomd04 %>% select(authors, title, year, journal, doi, study_id), by = "study_id")
  
  #--- Quick checks
  cat("--- study_id ---\n"); print(length(unique(fomd09.clean$study_id)))
  cat("--- authors ---\n");  print(length(unique(fomd09.clean$authors)))
  cat("--- title ---\n");    print(length(unique(fomd09.clean$title)))
  cat("--- year ---\n");     print(sort(unique(fomd09.clean$year)))
  cat("--- journal ---\n");  print(sort(unique(fomd09.clean$journal)))
  cat("--- doi ---\n");      print(sort(unique(fomd09.clean$doi)))
  
  fomd09.clean
}

#----------------------------------------------------------
#---- Add location information ----
#----------------------------------------------------------
add_fomd09_location <- function(fomd09.clean) {
  
  fomd09.clean <- fomd09.clean %>%
    rowwise() %>%
    mutate(
      country           = paste(unique(na.omit(c_across(starts_with("country0"))),collapse = "..")),
      site_type         = paste(unique(na.omit(c_across(starts_with("site_type0"))),collapse = "..")),
      site_id           = paste(unique(na.omit(c_across(starts_with("site_id0"))),collapse = "..")),
      site_admin        = paste(unique(na.omit(c_across(starts_with("site_admin0"))),collapse = "..")),
      site_agg          = paste(unique(na.omit(c_across(starts_with("site_agg0"))),collapse = "..")),
      site_latlong_type = paste(unique(na.omit(c_across(starts_with("site_latlong_type0"))),collapse = "..")),
      site_latitude     = paste(unique(na.omit(c_across(starts_with("site_latitude0"))),collapse = "..")),
      site_longitude    = paste(unique(na.omit(c_across(starts_with("site_longitude0"))),collapse = "..")),
      site_buffer       = paste(unique(na.omit(c_across(starts_with("site_buffer0"))),collapse = "..")),
      
      #---location----
      site_key = {
        long <- as.character(unlist(pick(all_of(paste0("site_longitude", sprintf("%02d", 1:5))))))
        lat  <- as.character(unlist(pick(all_of(paste0("site_latitude",  sprintf("%02d", 1:5))))))
        b    <- as.character(unlist(pick(all_of(paste0("site_buffer",    sprintf("%02d", 1:5))))))
        
        vals <- ifelse(
          is.na(lat) | lat == "",
          NA_character_,
          paste0(long, " ", lat, " B", b)
        )
        
        paste0(na.omit(vals), collapse = "..")
      }
    ) %>%
    ungroup()
  
  #--- Quick checks
  cat("--- country (n distinct) ---\n"); print(length(unique(fomd09.clean$country)))
  cat("--- country ---\n");              print(sort(unique(fomd09.clean$country)))
  cat("--- site_type ---\n");            print(sort(unique(fomd09.clean$site_type)))
  cat("--- site_id ---\n");              print(sort(unique(fomd09.clean$site_id)))
  cat("--- site_admin ---\n");           print(sort(unique(fomd09.clean$site_admin)))
  cat("--- site_agg ---\n");             print(sort(unique(fomd09.clean$site_agg)))
  cat("--- site_latlong_type ---\n");    print(sort(unique(fomd09.clean$site_latlong_type)))
  cat("--- site_latitude ---\n");        print(sort(unique(fomd09.clean$site_latitude)))
  cat("--- site_longitude ---\n");       print(sort(unique(fomd09.clean$site_longitude)))
  cat("--- site_buffer ---\n");          print(sort(unique(fomd09.clean$site_buffer)))
  cat("--- site_key ---\n");             print(sort(unique(fomd09.clean$site_key)))
  
  fomd09.clean
}

#----------------------------------------------------------
#---- Add crop/tree and animal commodity information ----
#----------------------------------------------------------
# Requires fun_cleaning_09_FOMD.R to be sourced first (uses count_components_str / check_length_mismatch_div_den)

#--- Generic: builds <name_prefix>_diversity, <variety_prefix>, <name_prefix>_density from numbered slot columns
add_commodity_columns <- function(df, name_prefix, n_slots, variety_prefix,
                                  n_density_slots, apply_gsub = FALSE) {
  
  name_cols        <- paste0(name_prefix, sprintf("%02d", 1:n_slots))
  arrangement_cols <- paste0(name_prefix, "_arrangement", sprintf("%02d", 1:n_slots))
  variety_cols     <- paste0(variety_prefix, sprintf("%02d", 1:n_slots))
  
  density_name_cols <- paste0(name_prefix, sprintf("%02d", 1:n_density_slots))
  density_cols      <- paste0(name_prefix, "_density", sprintf("%02d", 1:n_density_slots))
  density_unit_cols <- paste0(name_prefix, "_density_unit", sprintf("%02d", 1:n_density_slots))
  density_arr_cols  <- paste0(name_prefix, "_arrangement", sprintf("%02d", 1:n_density_slots))
  
  if (apply_gsub) df <- df %>% mutate(across(all_of(name_cols), ~gsub("_", " ", .x)))
  
  df %>%
    rowwise() %>%
    mutate(
      "{name_prefix}_diversity" := {
        d <- c_across(all_of(name_cols))
        a <- c_across(all_of(arrangement_cols))
        paste0(na.omit(ifelse(is.na(d) | d == "", NA_character_, paste0(d, ifelse(is.na(a), "", a)))), collapse = "")
      },
      "{variety_prefix}" := {
        c <- c_across(all_of(name_cols))
        v <- c_across(all_of(variety_cols))
        a <- c_across(all_of(arrangement_cols))
        paste0(na.omit(ifelse(is.na(c) | c == "", NA_character_, paste0(c, "(", v, ")", ifelse(is.na(a), "", a)))), collapse = "")
      },
      "{name_prefix}_density" := {
        c <- c_across(all_of(density_name_cols))
        d <- c_across(all_of(density_cols))
        u <- c_across(all_of(density_unit_cols))
        a <- c_across(all_of(density_arr_cols))
        paste0(na.omit(ifelse(is.na(d) | d == "", NA_character_,
                              paste0(c, "[", d, ifelse(is.na(u) | u == "", "", paste0("(", u, ")]")),
                                     ifelse(is.na(a) | a == "", "", a)))), collapse = "")
      }
    ) %>%
    ungroup()
}

#--- Generic: flags a slot whose crop is present, has a LATER populated slot after it, but no connector
flag_missing_arrangement <- function(df, name_prefix, n_slots) {
  name_cols <- paste0(name_prefix, sprintf("%02d", 1:n_slots))
  arr_cols  <- paste0(name_prefix, "_arrangement", sprintf("%02d", 1:n_slots))
  
  purrr::map_dfr(seq_len(nrow(df)), function(i) {
    names_row <- as.character(unlist(df[i, name_cols]))
    arr_row   <- as.character(unlist(df[i, arr_cols]))
    
    populated <- which(!is.na(names_row) & names_row != "")
    if (length(populated) < 2) return(NULL)  # 0 or 1 crop: nothing needs connecting
    
    last <- max(populated)
    needs_connector <- setdiff(populated, last)          # every populated slot EXCEPT the last one
    missing <- needs_connector[is.na(arr_row[needs_connector]) | arr_row[needs_connector] == ""]
    if (length(missing) == 0) return(NULL)
    
    data.frame(study_id = df$study_id[i], slot = sprintf("%02d", missing), name = names_row[missing])
  })
}

#--- Main entry point: crop_tree + animal, using the generic helpers above
add_fomd09_commodity <- function(fomd09.clean) {
  
  fomd09.clean <- add_commodity_columns(fomd09.clean, name_prefix = "crop_tree", n_slots = 15,
                                        variety_prefix = "crop_tree_variety", n_density_slots = 15, apply_gsub = TRUE)
  fomd09.clean <- add_commodity_columns(fomd09.clean, name_prefix = "animal", n_slots = 5,
                                        variety_prefix = "animal_breed", n_density_slots = 2, apply_gsub = FALSE)
  
  #--- Quick checks
  for (col in c("crop_tree_diversity", "crop_tree_variety", "crop_tree_density",
                "animal_diversity", "animal_breed", "animal_density")) {
    cat("---", col, "---\n")
    print(sort(unique(fomd09.clean[[col]])))
  }
  
  #--- Flag: variety/density component-count mismatches vs diversity
  cat("--- crop_tree variety mismatches ---\n"); print(check_length_mismatch_div_den(fomd09.clean, "crop_tree_diversity", "crop_tree_variety"))
  cat("--- crop_tree density mismatches ---\n"); print(check_length_mismatch_div_den(fomd09.clean, "crop_tree_diversity", "crop_tree_density"))
  cat("--- animal breed mismatches ---\n");       print(check_length_mismatch_div_den(fomd09.clean, "animal_diversity", "animal_breed"))
  cat("--- animal density mismatches ---\n");     print(check_length_mismatch_div_den(fomd09.clean, "animal_diversity", "animal_density"))
  
  #--- Flag: missing arrangement connector for slot >=2
  cat("--- crop_tree missing arrangement (slot >=2) ---\n"); print(flag_missing_arrangement(fomd09.clean, "crop_tree", 15))
  cat("--- animal missing arrangement (slot >=2) ---\n");    print(flag_missing_arrangement(fomd09.clean, "animal", 5))
  
  fomd09.clean
}

#----------------------------------------------------------
#---- Add varietal (improved variety/breed) information ----
#----------------------------------------------------------
add_fomd09_varietal <- function(fomd09.clean, prefix, variety_suffix = "variety") {
  
  name_col    <- paste0(prefix, "_name")
  variety_col <- paste0(prefix, "_", variety_suffix)
  
  fomd09.clean <- fomd09.clean %>%
    mutate("{name_col}" := gsub("_", " ", .data[[name_col]])) %>%
    mutate("{variety_col}" := ifelse(
      is.na(.data[[name_col]]) | .data[[name_col]] == "",
      NA_character_,
      paste0(.data[[name_col]], "(", .data[[variety_col]], ")")
    ))
  
  #--- Quick checks
  for (col in c(paste0(prefix, "_subpractice_raw"), name_col, variety_col,
                paste0(prefix, "_subpractice"), paste0(prefix, "_type"), paste0(prefix, "_trait"))) {
    cat("---", col, "---\n")
    print(sort(unique(fomd09.clean[[col]])))
  }
  
  fomd09.clean
}

#--------------------------------------------------------
#---- Collapse numbered subpractice/product columns into one ----
#--------------------------------------------------------
collapse_fomd09_columns <- function(fomd09.clean, prefix = NULL, cols = NULL,
                                    new_col = NULL, sep = "..", dedupe = FALSE) {
  
  if (is.null(cols)) {
    cols <- names(fomd09.clean)[startsWith(names(fomd09.clean), prefix)]
    if (is.null(new_col)) new_col <- sub("0$", "", prefix)
  } else {
    cols <- intersect(cols, names(fomd09.clean))  # tolerate cols that don't exist, like any_of() did
  }
  if (is.null(new_col)) stop("new_col must be provided when using `cols` directly")
  
  fomd09.clean <- fomd09.clean %>%
    rowwise() %>%
    mutate("{new_col}" := {
      vals <- na.omit(c_across(all_of(cols)))
      if (dedupe) vals <- base::unique(vals)
      paste(vals, collapse = sep)
    }) %>%
    ungroup()
  
  #--- Quick check
  cat("---", new_col, "---\n")
  print(sort(unique(fomd09.clean[[new_col]])))
  
  fomd09.clean
}

#------------------------------------------------------------------------------
#---- Collapse mean/min/max triplets into one string ----
#------------------------------------------------------------------------------
add_fomd09_mean_min_max <- function(fomd09.clean, prefix) {
  
  mean_col <- paste0(prefix, "_mean")
  min_col  <- paste0(prefix, "_min")
  max_col  <- paste0(prefix, "_max")
  new_col  <- paste0(prefix, "_mean_min_max")
  
  fomd09.clean <- fomd09.clean %>%
    rowwise() %>%
    mutate("{new_col}" := ifelse(
      is.na(.data[[mean_col]]) & is.na(.data[[min_col]]) & is.na(.data[[max_col]]),
      "",
      paste0(.data[[mean_col]], "(", .data[[min_col]], "-", .data[[max_col]], ")")
    )) %>%
    ungroup()
  
  #--- Quick check
  cat("---", new_col, "---\n")
  print(sort(unique(fomd09.clean[[new_col]])))
  
  fomd09.clean
}

#------------------------------------------------------------------------------
# Reusable function to combine amount + unit columns separated by ".."
#------------------------------------------------------------------------------
combine_amount_unit <- function(amount, unit, sep = "..") {
  mapply(function(amt, unt) {
    if (is.na(amt) || amt == "") return(amt)
    
    amounts <- strsplit(amt, "\\.\\.") [[1]]
    units   <- strsplit(unt, "\\.\\.") [[1]]
    
    # Single unit: recycle across all amounts (not a problem)
    if (length(units) == 1) {
      units <- rep(units, length(amounts))
    }
    
    units <- ifelse(is.na(units) | units == "", "Unspecified", units)
    
    # Only warn when MULTIPLE units exist but count doesn't match amounts
    if (length(units) > 1 && length(amounts) != length(units)) {
      warning(paste("Length mismatch: amounts =", length(amounts),
                    "units =", length(units), "— recycling units."))
      units <- rep_len(units, length(amounts))
    }
    
    paste(paste0(amounts, "(", units, ")"), collapse = sep)
    
  }, amount, unit, USE.NAMES = FALSE)
}

#------------------------------------------------------------------------------
# Reusable function to combine INORGANIC fertilizer type + amount + unit separated by ".."
#------------------------------------------------------------------------------
combine_fert_inor_type_amount_unit <- function(applied, amount_unit) {
  if (applied == "" || is.na(applied)) return("")
  
  applied_parts     <- strsplit(applied,     "\\.\\.")[[1]]
  amount_unit_parts <- strsplit(amount_unit, "\\.\\.")[[1]]
  
  # If one unit provided, broadcast it across all amounts
  if (length(amount_unit_parts) == 1) {
    au <- amount_unit_parts[1]
    if (is.na(au) || grepl("^NA$|^NA\\(|\\(NA\\)", au)) {
      pairs <- paste0(applied_parts, "[Unspecified(Unspecified)]")
    } else {
      pairs <- paste0(applied_parts, "[", au, "]")
    }
  } else if (length(applied_parts) == length(amount_unit_parts)) {
    # One unit per amount — zip them together
    pairs <- mapply(function(a, au) {
      if (is.na(au) || grepl("^NA$|^NA\\(|\\(NA\\)", au)) {
        paste0(a, "[Unspecified(Unspecified)]")
      } else {
        paste0(a, "[", au, "]")
      }
    }, applied_parts, amount_unit_parts)
  } else {
    # Mismatch — fallback to first unit
    au <- amount_unit_parts[1]
    if (is.na(au) || grepl("^NA$|^NA\\(|\\(NA\\)", au)) {
      pairs <- paste0(applied_parts, "[Unspecified(Unspecified)]")
    } else {
      pairs <- paste0(applied_parts, "[", au, "]")
    }
  }
  
  paste(pairs, collapse = "..")
}

#--------------------------------------------------------
#---- Add nutrient management (inorganic fertilizer) information ----
#--------------------------------------------------------
# Requires fun_cleaning_09_FOMD.R sourced first (uses combine_amount_unit / combine_fert_inor_type_amount_unit)
add_fomd09_fert_inorganic <- function(fomd09.clean) {
  
  fomd09.clean <- fomd09.clean %>%
    mutate(
      fert_inorganic_amount_unit      = combine_amount_unit(fert_inorganic_amount, fert_inorganic_unit),
      fert_inorganic_type_amount_unit = purrr::map2_chr(fert_inorganic_type, fert_inorganic_amount_unit, combine_fert_inor_type_amount_unit),
      fert_inorganicN_amount_unit    = combine_amount_unit(fert_inorganicN,    fert_inorganicNPK_unit),
      fert_inorganicP_amount_unit    = combine_amount_unit(fert_inorganicP,    fert_inorganicNPK_unit),
      fert_inorganicK_amount_unit   = combine_amount_unit(fert_inorganicK,    fert_inorganicNPK_unit),
      fert_inorganicP2O5_amount_unit = combine_amount_unit(fert_inorganicP2O5, fert_inorganicNPK_unit),
      fert_inorganicK2O_amount_unit  = combine_amount_unit(fert_inorganicK2O,  fert_inorganicNPK_unit)
    )
  
  #--- Quick checks
  cat("--- fert_subpractice_raw ---\n");           print(sort(unique(fomd09.clean$fert_subpractice_raw)))
  cat("--- fert_subpractice ---\n");                print(sort(unique(fomd09.clean$fert_subpractice)))
  cat("--- fert_inorganic_category ---\n");          print(sort(unique(fomd09.clean$fert_inorganic_category)))
  cat("--- fert_inorganic_type_amount_unit ---\n");  print(sort(unique(fomd09.clean$fert_inorganic_type_amount_unit)))
  cat("--- fert_inorganicN_amount_unit ---\n");                  print(sort(unique(fomd09.clean$fert_inorganicN_amount_unit)))
  cat("--- fert_inorganicP_amount_unit ---\n");                  print(sort(unique(fomd09.clean$fert_inorganicP_amount_unit)))
  cat("--- fert_inorganicK_amount_unit ---\n");                  print(sort(unique(fomd09.clean$fert_inorganicK_amount_unit)))
  cat("--- fert_inorganicP2O5_amount_unit ---\n");                print(sort(unique(fomd09.clean$fert_inorganicP2O5_amount_unit)))
  cat("--- fert_inorganicK2O_amount_unit ---\n");                 print(sort(unique(fomd09.clean$fert_inorganicK2O_amount_unit)))
  
  fomd09.clean
}

#------------------------------------------------------------------------------
# Reusable function to combine ORGANIC fertilizer type + amount + unit separated by ".."
#------------------------------------------------------------------------------
combine_type_amount_unit <- function(applied, amount_unit) {
  if (applied == "" || is.na(applied)) return("")
  
  applied_parts     <- strsplit(applied,     "\\.\\.")[[1]]
  amount_unit_parts <- strsplit(amount_unit, "\\.\\.")[[1]]
  
  if (length(applied_parts) == length(amount_unit_parts)) {
    pairs <- mapply(function(a, au) {
      if (is.na(au) || grepl("^NA$|^NA\\(|\\(NA\\)", au)) {
        paste0(a, "[Unspecified(Unspecified)]")
      } else {
        paste0(a, "[", au, "]")
      }
    }, applied_parts, amount_unit_parts)
  } else {
    au <- amount_unit_parts[1]
    if (is.na(au) || grepl("^NA$|^NA\\(|\\(NA\\)", au)) {
      pairs <- paste0(applied_parts, "[Unspecified(Unspecified)]")
    } else {
      pairs <- paste0(applied_parts, "[", au, "]")
    }
  }
  
  paste(pairs, collapse = "..")
}

#------------------------------------------------------------------------------
#---- Add nutrient management (organic fertilizer) information ----
#------------------------------------------------------------------------------
add_fomd09_fert_organic <- function(fomd09.clean) {
  
  fomd09.clean <- fomd09.clean %>%
    mutate(
      fert_organic_amount_unit      = combine_amount_unit(fert_organic_amount, fert_organic_unit),
      fert_organic_type_amount_unit = purrr::map2_chr(fert_organic_type, fert_organic_amount_unit, combine_type_amount_unit),
      fert_organicN_amount_unit = combine_amount_unit(fert_organicN, fert_organicNPK_unit),
      fert_organicP_amount_unit = combine_amount_unit(fert_organicP, fert_organicNPK_unit),
      fert_organicK_amount_unit = combine_amount_unit(fert_organicK, fert_organicNPK_unit)
    )
  
  #--- Quick checks
  cat("--- fert_organic_category ---\n");         print(sort(unique(fomd09.clean$fert_organic_category)))
  cat("--- fert_organic_type ---\n");               print(sort(unique(fomd09.clean$fert_organic_type)))
  cat("--- fert_organic_amount ---\n");             print(sort(unique(fomd09.clean$fert_organic_amount)))
  cat("--- fert_organic_type_amount_unit ---\n");   print(sort(unique(fomd09.clean$fert_organic_type_amount_unit)))
  cat("--- fert_organicNPK_unit ---\n");             print(sort(unique(fomd09.clean$fert_organicNPK_unit)))
  cat("--- fert_organicN_amount_unit ---\n");                    print(sort(unique(fomd09.clean$fert_organicN_amount_unit)))
  cat("--- fert_organicP_amount_unit ---\n");                    print(sort(unique(fomd09.clean$fert_organicP_amount_unit)))
  cat("--- fert_organicK_amount_unit ---\n");                    print(sort(unique(fomd09.clean$fert_organicK_amount_unit)))
  cat("--- fert_organic_source ---\n");              print(sort(unique(fomd09.clean$fert_organic_source)))
  
  fomd09.clean
}

#------------------------------------------------------------------------------
#---- Add weeding management moderator information ----
#------------------------------------------------------------------------------
# Requires combine_amount_unit (already in fun_fomd09_cleaning.R)
add_fomd09_weed <- function(fomd09.clean) {
  
  fomd09.clean <- fomd09.clean %>%
    mutate(weed_frequency_unit = combine_amount_unit(weed_frequency, weed_frequency_unit))
  
  #--- Quick checks
  cat("--- weed_method_raw ---\n");     print(sort(unique(fomd09.clean$weed_method_raw)))
  cat("--- weed_method ---\n");          print(sort(unique(fomd09.clean$weed_method)))
  cat("--- weed_frequency_unit ---\n");  print(sort(unique(fomd09.clean$weed_frequency_unit)))
  
  fomd09.clean
}

#------------------------------------------------------------------------------
#---- Add chemical management practice information ----
#------------------------------------------------------------------------------
add_fomd09_chem <- function(fomd09.clean) {
  
  fomd09.clean <- fomd09.clean %>%
    rowwise() %>%
    mutate(
      chem_subpractice = paste(na.omit(c_across(starts_with("chem_subpractice0"))), collapse = ".."),
      
      chem_name_amount_unit = {
        subpractice <- c_across(all_of(paste0("chem_subpractice", sprintf("%02d", 1:3))))
        name   <- c_across(all_of(paste0("chem_name", sprintf("%02d", 1:3))))
        amount <- c_across(all_of(paste0("chem_amount", sprintf("%02d", 1:3))))
        unit   <- c_across(all_of(paste0("chem_unit", sprintf("%02d", 1:3))))
        
        keep <- !(is.na(subpractice) | subpractice == "")
        
        if (!any(keep)) {
          NA_character_
        } else {
          vals <- ifelse(
            is.na(name[keep]) | name[keep] == "",
            "NA[0(NA)]",
            paste0(
              name[keep], "[",
              ifelse(is.na(amount[keep]) | amount[keep] == "", "NA", amount[keep]),
              "(",
              ifelse(is.na(unit[keep]) | unit[keep] == "", "NA", unit[keep]),
              ")]"))
          
          paste(vals, collapse = "..")
        }
      }
    ) %>%
    ungroup()
  
  #--- Quick checks
  cat("--- chem_subpractice_raw ---\n");   print(sort(unique(fomd09.clean$chem_subpractice_raw)))
  cat("--- chem_subpractice ---\n");        print(sort(unique(fomd09.clean$chem_subpractice)))
  cat("--- chem_name01 ---\n");             print(sort(unique(fomd09.clean$chem_name01)))
  cat("--- chem_name_amount_unit ---\n");   print(sort(unique(fomd09.clean$chem_name_amount_unit)))
  
  fomd09.clean
}

#------------------------------------------------------------------------------
#---- Add residues moderator information ----
#------------------------------------------------------------------------------
add_fomd09_residues <- function(fomd09.clean) {
  
  fomd09.clean <- fomd09.clean %>%
    mutate(
      residues_OC_amount_unit       = combine_amount_unit(residues_OC, residues_OC_unit),
      residues_N_amount_unit        = combine_amount_unit(residues_N, residues_N_unit),
      residues_P_amount_unit        = combine_amount_unit(residues_P, residues_P_unit),
      residues_K_amount_unit        = combine_amount_unit(residues_K, residues_K_unit),
      residues_material_amount_unit = combine_amount_unit(residues_material_amount, residues_material_unit)
    )
  
  #--- Quick checks
  cat("--- residues_OC_amount_unit ---\n");       print(sort(unique(fomd09.clean$residues_OC_amount_unit)))
  cat("--- residues_N_amount_unit ---\n");        print(sort(unique(fomd09.clean$residues_N_amount_unit)))
  cat("--- residues_P_amount_unit ---\n");        print(sort(unique(fomd09.clean$residues_P_amount_unit)))
  cat("--- residues_K_amount_unit ---\n");        print(sort(unique(fomd09.clean$residues_K_amount_unit)))
  cat("--- residues_tree ---\n");        print(sort(unique(fomd09.clean$residues_tree)))
  cat("--- residues_material ---\n");        print(sort(unique(fomd09.clean$residues_material)))
  cat("--- residues_material_amount_unit ---\n"); print(sort(unique(fomd09.clean$residues_material_amount_unit)))
  cat("--- residues_material_source ---\n"); print(sort(unique(fomd09.clean$residues_material_source)))
  cat("--- residues_processing ---\n"); print(sort(unique(fomd09.clean$residues_processing)))
  
  fomd09.clean
}


#--------------------------------------------------------
#---- Add pH amendment practice information ----
#------------------------------------------------------------------------------ 
combine_ph_material_amount_unit <- function(applied, amount_unit) {
  if (applied == "" || is.na(applied)) return("")
  
  applied_parts     <- strsplit(applied,     "\\.\\.")[[1]]
  amount_unit_parts <- strsplit(amount_unit, "\\.\\.")[[1]]
  
  if (length(applied_parts) == length(amount_unit_parts)) {
    pairs <- mapply(function(a, au) {
      if (is.na(au) || grepl("^NA$|^NA\\(|\\(NA\\)", au)) {
        paste0(a, "[Unspecified(Unspecified)]")
      } else {
        paste0(a, "[", au, "]")
      }
    }, applied_parts, amount_unit_parts)
  } else {
    au <- amount_unit_parts[1]
    if (is.na(au) || grepl("^NA$|^NA\\(|\\(NA\\)", au)) {
      pairs <- paste0(applied_parts, "[Unspecified(Unspecified)]")
    } else {
      pairs <- paste0(applied_parts, "[", au, "]")
    }
  }
  
  paste(pairs, collapse = "..")
}

################################
# FUNCTIONS FOR CHECKING
##################################
#---commodity_crop_tree ----
extract_variety_names <- function(x) {
  x %>%
    na.omit() %>%
    .[. != ""] %>%
    strsplit("(?<=[)])[/\\-](?=[A-Z])", perl = TRUE) %>%
    unlist() %>%
    trimws() %>%
    regmatches(., regexpr("^[^(]+", .)) %>%
    trimws() %>%
    unique() %>%
    sort()
}

extract_crop_names <- function(x) {
  x %>%
    na.omit() %>%
    .[. != ""] %>%
    # Split on - or / that separate crop entries (i.e., followed by an uppercase letter)
    strsplit("(?<=[)])[/\\-](?=[A-Z])", perl = TRUE) %>%
    unlist() %>%
    trimws() %>%
    # Extract crop name: everything before the first [
    regmatches(., regexpr("^[^\\[]+", .)) %>%
    trimws() %>%
    unique() %>%
    sort()
}


#-------------------------------------------------------
# Code to check mismatch between crop_tree_diversity and crop_tree_density columns
#-------------------------------------------------------
count_components_str <- function(x) {
  if (is.na(x) || x == "") return(0)
  chars <- strsplit(x, "")[[1]]
  depth <- 0
  n_splits <- 0
  for (i in seq_along(chars)) {
    if (chars[i] == "(") depth <- depth + 1
    else if (chars[i] == ")") depth <- depth - 1
    else if (chars[i] %in% c("/", "-") && depth == 0) n_splits <- n_splits + 1
  }
  return(n_splits + 1)
}

check_length_mismatch_div_den <- function(df, diversity_col, density_col) {
  div <- df[[diversity_col]]
  den <- df[[density_col]]
  
  mismatches <- mapply(function(d, dn, i, doi, study_id) {
    if (is.na(d) || d == "") return(NULL)
    nd  <- count_components_str(d)
    ndn <- count_components_str(dn)
    if (ndn == 1) return(NULL)
    if (nd != ndn) data.frame(
      row = i, doi = doi, study_id = study_id,
      diversity_col = diversity_col, density_col = density_col,
      n_diversity = nd, n_density = ndn, diversity = d, density = dn
    )
  }, div, den, seq_along(div), df$doi, df$study_id, SIMPLIFY = FALSE)
  
  mismatches <- Filter(Negate(is.null), mismatches)
  if (length(mismatches) == 0) return(NULL)
  do.call(rbind, mismatches)
}

# Run for C and T pairs
pairs_div_den <- list(
  c("C_crop_tree_diversity", "C_crop_tree_density"),
  c("T_crop_tree_diversity", "T_crop_tree_density")
)

#-------------------------------------------------------
# Code to check mismatch between amount and unit columns
#-------------------------------------------------------
# Check mismatches for any amount/unit pair
check_length_mismatch_amount_unit <- function(df, amount_col, unit_col) {
  amt <- df[[amount_col]]
  unt <- df[[unit_col]]
  
  mismatches <- mapply(function(a, u, i,doi,study_id) {
    if (is.na(a) || a == "") return(NULL)
    na <- length(strsplit(a, "\\.\\.")[[1]])
    nu <- length(strsplit(u, "\\.\\.")[[1]])
    if (na != nu) data.frame(row = i, 
                             doi=doi,study_id=study_id, amount_col, unit_col,
                             n_amounts = na, n_units = nu,
                             amount = a, unit = u)
  }, amt, unt, seq_along(amt),df$doi,df$study_id, SIMPLIFY = FALSE)
  
  do.call(rbind, Filter(Negate(is.null), mismatches))
}

# Run for all relevant pairs
inorganicNPK_fert_pairs <- list(
  c("T_fert_inorganicN",   "T_fert_inorganicNPK_unit"),
  c("T_fert_inorganicP",   "T_fert_inorganicNPK_unit"),
  c("T_fert_inorganicK",   "T_fert_inorganicNPK_unit"),
  c("T_fert_inorganicP2O5","T_fert_inorganicNPK_unit"),
  c("T_fert_inorganicK2O", "T_fert_inorganicNPK_unit"),
  
  c("C_fert_inorganicN",   "C_fert_inorganicNPK_unit"),
  c("C_fert_inorganicP",   "C_fert_inorganicNPK_unit"),
  c("C_fert_inorganicK",   "C_fert_inorganicNPK_unit"),
  c("C_fert_inorganicP2O5","C_fert_inorganicNPK_unit"),
  c("C_fert_inorganicK2O", "C_fert_inorganicNPK_unit")
)

weed_frequency_unit_pairs<-list(
  c("C_weed_frequency",   "C_weed_frequency_unit"),
  c("T_weed_frequency",   "T_weed_frequency_unit")
)

#-------------------------------------------------------
# Code to check mismatch between type, amount and unit columns
#-------------------------------------------------------
check_length_mismatch_type_amount_unit <- function(df, type_col, amount_col, unit_col) {
  typ <- df[[type_col]]
  amt <- df[[amount_col]]
  unt <- df[[unit_col]]
  
  mismatches <- mapply(function(t, a, u, id,doi#,C_fert_inorganic_type_amount_unit
  ) {
    # Use type as the reference if amount is empty
    if ((is.na(t) || t == "") && (is.na(a) || a == "")) return(NULL)
    
    nt <- if (is.na(t) || t == "") NA else length(strsplit(t, "\\.\\.") [[1]])
    na <- if (is.na(a) || a == "") NA else length(strsplit(a, "\\.\\.") [[1]])
    nu <- if (is.na(u) || u == "") NA else length(strsplit(u, "\\.\\.") [[1]])
    
    # Single unit is fine — not a mismatch
    if (!is.na(nu) && nu == 1) return(NULL)
    
    # Flag if any of the three differ from each other
    counts <- na.omit(c(nt, na, nu))
    if (length(unique(counts)) <= 1) return(NULL)
    
    data.frame(study_id  = id,
               doi=doi,
               #C_fert_inorganic_type_amount_unit=C_fert_inorganic_type_amount_unit,
               type_col  = type_col,
               amount_col = amount_col,
               unit_col  = unit_col,
               n_types   = nt,
               n_amounts = na,
               n_units   = nu,
               type      = t,
               amount    = a,
               unit      = u)
    
  }, typ, amt, unt, df$study_id, df$doi,#df$C_fert_inorganic_type_amount_unit,
  SIMPLIFY = FALSE)
  
  do.call(rbind, Filter(Negate(is.null), mismatches))
}

# Run for all relevant triplets
inorganic_fert_pairs <- list(
  c("C_fert_inorganic_type", "C_fert_inorganic_amount", "C_fert_inorganic_unit"),
  c("T_fert_inorganic_type", "T_fert_inorganic_amount", "T_fert_inorganic_unit")
)

chem_pairs <- list(
  c("C_chem_name", "C_chem_amount", "C_chem_amount_unit"),
  c("T_chem_name", "T_chem_amount", "T_chem_amount_unit")
)

residues_pairs <- list(
  c("C_residues_OC",   "C_residues_OC_unit"),
  c("T_residues_OC",   "T_residues_OC_unit"), 
  
  c("C_residues_N",   "C_residues_N_unit"), 
  c("T_residues_N","T_residues_N_unit"), #missing units
  
  c("C_residues_P", "C_residues_P_unit"), 
  c("T_residues_P",   "T_residues_P_unit"), 
  
  c("C_residues_K",   "C_residues_K_unit"),
  c("T_residues_K",   "T_residues_K_unit"),
  
  c("C_residues_material_amount",   "C_residues_material_unit"),
  c("T_residues_material_amount",   "T_residues_material_unit")
)

#--------------------------------------------------------
#---- Find crop/tree names missing from the ontology ----
#--------------------------------------------------------
find_unmatched_crops <- function(fomd09.clean, path.metadata.effectsize) {
  
  # Built entirely inside this function — fomd01.crops.trees never touches the caller's environment
  fomd01.crops.trees <- local({
    source(file.path(path.metadata.effectsize, "fomd_fun/fun_load_data_ontologies.R"), local = environment())
    
    rbind(
      fomd01.product.new %>%
        filter(!is.na(Product.Simple)) %>%
        distinct(Product.Simple, SPAM.Food.Group, FAO.Food.SubGroup, FAO.Food.Group) %>%
        rename("crop_tree_diversity" = "Product.Simple") %>%
        filter(!is.na(FAO.Food.Group), !is.na(crop_tree_diversity)),
      
      fomd01.vars.crops %>%
        distinct(V.Product, SPAM.Food.Group, FAO.Food.SubGroup, FAO.Food.Group) %>%
        rename("crop_tree_diversity" = "V.Product") %>%
        filter(!is.na(FAO.Food.Group)),
      
      fomd01.trees %>%
        select(tree.latin.name, Tree.Nfix, Tree.Legume) %>%
        rename("crop_tree_diversity" = "tree.latin.name",
               "FAO.Food.SubGroup" = "Tree.Legume",
               "FAO.Food.Group" = "Tree.Nfix") %>%
        mutate(FAO.Food.SubGroup = case_when(FAO.Food.SubGroup == "Yes" ~ "Legume Tree", TRUE ~ "No Legume Tree"),
               FAO.Food.Group = case_when(FAO.Food.Group == "Yes" ~ "N Fix Tree", TRUE ~ "No N Fix Tree"),
               SPAM.Food.Group = "Trees") %>%
        distinct(crop_tree_diversity, FAO.Food.SubGroup, FAO.Food.Group, SPAM.Food.Group)
    ) %>%
      distinct(crop_tree_diversity, SPAM.Food.Group, FAO.Food.SubGroup, FAO.Food.Group) %>%
      arrange(crop_tree_diversity)
  })
  
  fomd09.clean %>%
    select(crop = crop_tree_diversity) %>%
    mutate(crop = str_split(crop, "[-/]")) %>%
    unnest(crop) %>%
    mutate(crop = str_squish(crop)) %>%
    filter(!is.na(crop), crop != "NA", crop != "") %>%
    distinct(crop) %>%
    left_join(fomd01.crops.trees %>% select(crop_tree_diversity, FAO.Food.Group),
              by = c("crop" = "crop_tree_diversity")) %>%
    filter(is.na(FAO.Food.Group)) %>%
    arrange(crop)
}

#--------------------------------------------------------
#---- Find product names missing from the ontology ----
#--------------------------------------------------------
find_unmatched_products <- function(fomd09.clean, path.metadata.structure) {
  
  fomd01.product.new <- read_xlsx(
    file.path(path.metadata.structure, "01_FOMD_ontologies.xlsx"),
    sheet = "01_product_new"
  )
  
  fomd09.clean %>%
    select(product) %>%
    mutate(product = str_split(product, "\\.\\.")) %>%
    unnest(product) %>%
    mutate(product = str_squish(product)) %>%
    filter(!is.na(product), product != "NA", product != "") %>%
    distinct(product) %>%
    anti_join(fomd01.product.new, by = c("product" = "Product")) %>%
    arrange(product)
}
