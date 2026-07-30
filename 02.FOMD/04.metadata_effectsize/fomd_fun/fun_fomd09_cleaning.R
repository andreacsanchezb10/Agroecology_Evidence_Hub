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

#==========================================================
#---- Add crop/tree and animal commodity information ----
#==========================================================
# Requires fun_cleaning_09_FOMD.R to be sourced first (uses count_components_str / check_length_mismatch_div_den)
add_fomd09_commodity <- function(fomd09.clean) {
  
  #---commodity_crop_tree----
  fomd09.clean <- fomd09.clean %>%
    mutate(across(
      all_of(paste0("crop_tree", sprintf("%02d", 1:15))),
      ~gsub("_", " ", .x))) %>%
    rowwise() %>%
    mutate(
      crop_tree_diversity = {
        d <- c_across(all_of(paste0("crop_tree", sprintf("%02d", 1:15))))
        a <- c_across(all_of(paste0("crop_tree_arrangement", sprintf("%02d", 1:15))))
        paste0(na.omit(ifelse(is.na(d) | d == "", NA_character_, paste0(d, ifelse(is.na(a), "", a)))), collapse = "")
      },
      crop_tree_variety = {
        c <- c_across(all_of(paste0("crop_tree", sprintf("%02d", 1:15))))
        v <- c_across(all_of(paste0("crop_tree_variety", sprintf("%02d", 1:15))))
        a <- c_across(all_of(paste0("crop_tree_arrangement", sprintf("%02d", 1:15))))
        paste0(na.omit(ifelse(is.na(c) | c == "", NA_character_, paste0(c, "(", v, ")", ifelse(is.na(a), "", a)))), collapse = "")
      },
      crop_tree_density = {
        c <- c_across(all_of(paste0("crop_tree", sprintf("%02d", 1:15))))
        d <- c_across(all_of(paste0("crop_tree_density", sprintf("%02d", 1:15))))
        u <- c_across(all_of(paste0("crop_tree_density_unit", sprintf("%02d", 1:15))))
        a <- c_across(all_of(paste0("crop_tree_arrangement", sprintf("%02d", 1:15))))
        paste0(na.omit(ifelse(is.na(d) | d == "", NA_character_,
                              paste0(c, "[", d, ifelse(is.na(u) | u == "", "", paste0("(", u, ")]")),
                                     ifelse(is.na(a) | a == "", "", a)))), collapse = "")
      }
    ) %>%
    ungroup()
  
  #---commodity_animal----
  fomd09.clean <- fomd09.clean %>%
    rowwise() %>%
    mutate(
      animal_diversity = {
        l <- c_across(all_of(paste0("animal", sprintf("%02d", 1:5))))
        a <- c_across(all_of(paste0("animal_arrangement", sprintf("%02d", 1:5))))
        paste0(na.omit(ifelse(is.na(l) | l == "", NA_character_, paste0(l, ifelse(is.na(a), "", a)))), collapse = "")
      },
      animal_breed = {
        l <- c_across(all_of(paste0("animal", sprintf("%02d", 1:5))))
        v <- c_across(all_of(paste0("animal_breed", sprintf("%02d", 1:5))))
        a <- c_across(all_of(paste0("animal_arrangement", sprintf("%02d", 1:5))))
        paste0(na.omit(ifelse(is.na(v) | v == "", NA_character_, paste0(l, "(", v, ")", ifelse(is.na(a), "", a)))), collapse = "")
      },
      animal_density = {
        l <- c_across(all_of(paste0("animal", sprintf("%02d", 1:2))))
        d <- c_across(all_of(paste0("animal_density", sprintf("%02d", 1:2))))
        u <- c_across(all_of(paste0("animal_density_unit", sprintf("%02d", 1:2))))
        a <- c_across(all_of(paste0("animal_arrangement", sprintf("%02d", 1:2))))
        paste0(na.omit(ifelse(is.na(d) | d == "", NA_character_,
                              paste0(l, "[", d, ifelse(is.na(u) | u == "", "", paste0("(", u, ")]")),
                                     ifelse(is.na(a) | a == "", "", a)))), collapse = "")
      }
    ) %>%
    ungroup()
  
  #--- Quick checks
  cat("--- crop_tree_diversity ---\n"); print(sort(unique(fomd09.clean$crop_tree_diversity)))
  cat("--- crop_tree_variety ---\n");   print(sort(unique(fomd09.clean$crop_tree_variety)))
  cat("--- crop_tree_density ---\n");   print(sort(unique(fomd09.clean$crop_tree_density)))
  cat("--- animal_diversity ---\n");    print(sort(unique(fomd09.clean$animal_diversity)))
  cat("--- animal_breed ---\n");        print(sort(unique(fomd09.clean$animal_breed)))
  cat("--- animal_density ---\n");      print(sort(unique(fomd09.clean$animal_density)))
  
  #--- Flag: variety/density component-count mismatches vs diversity (reuses fun_cleaning_09_FOMD.R)
  cat("--- crop_tree variety mismatches ---\n"); print(check_length_mismatch_div_den(fomd09.clean, "crop_tree_diversity", "crop_tree_variety"))
  cat("--- crop_tree density mismatches ---\n"); print(check_length_mismatch_div_den(fomd09.clean, "crop_tree_diversity", "crop_tree_density"))
  cat("--- animal breed mismatches ---\n");       print(check_length_mismatch_div_den(fomd09.clean, "animal_diversity", "animal_breed"))
  cat("--- animal density mismatches ---\n");     print(check_length_mismatch_div_den(fomd09.clean, "animal_diversity", "animal_density"))
  
  #--- Flag: a 2nd+ commodity present with no connector -> would silently concatenate with the previous name
  flag_missing_arrangement <- function(df, name_prefix, n_slots) {
    purrr::map_dfr(2:n_slots, function(i) {
      slot <- sprintf("%02d", i)
      name_col <- paste0(name_prefix, slot)
      arr_col  <- paste0(name_prefix, "_arrangement", slot)
      
      present <- !is.na(df[[name_col]]) & df[[name_col]] != ""
      missing_arrangement <- present & (is.na(df[[arr_col]]) | df[[arr_col]] == "")
      if (!any(missing_arrangement)) return(NULL)
      
      data.frame(study_id = df$study_id[missing_arrangement], slot = slot, name = df[[name_col]][missing_arrangement])
    })
  }
  
  cat("--- crop_tree missing arrangement (slot >=2) ---\n"); print(flag_missing_arrangement(fomd09.clean, "crop_tree", 15))
  cat("--- animal missing arrangement (slot >=2) ---\n");    print(flag_missing_arrangement(fomd09.clean, "animal", 5))
  
  fomd09.clean
}