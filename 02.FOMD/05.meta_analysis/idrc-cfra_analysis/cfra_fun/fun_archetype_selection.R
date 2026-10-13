library(dplyr)
library(tidyr)
library(stringr)
library(sf)

#==========================================================
# Paired comparisons located in archetype high-priority areas
#==========================================================

#--- 1. Site points ----
# Pooled multi-site comparisons store coordinates as "lat1..lat2..": one point per site
make_points <- function(df) {
  df %>%
    distinct(effect_size_id, C_site_latitude, C_site_longitude) %>%
    mutate(lat = str_split(C_site_latitude, fixed("..")),
           lon = str_split(C_site_longitude, fixed(".."))) %>%
    filter(lengths(lat) == lengths(lon)) %>%
    unnest(c(lat, lon)) %>%
    mutate(lat = suppressWarnings(as.numeric(lat)),
           lon = suppressWarnings(as.numeric(lon))) %>%
    filter(!is.na(lat), !is.na(lon)) %>%
    st_as_sf(coords = c("lon", "lat"), crs = 4326)
}

#--- 2. Paired comparisons in high-priority areas (any of their sites inside) ----
# arc   archetype polygons (gpkg)
# rule  high-priority areas, as text, e.g. "Criteria_Met_Count >= 3"
select_priority <- function(points, arc, rule) {
  keep <- with(arc, eval(str2lang(rule)))
  points %>%
    st_join(arc[keep, ]["NAME_1"], left = FALSE) %>%
    st_drop_geometry() %>%
    distinct(effect_size_id)
}

#==========================================================
# Sufficiency of the evidence and extension by agro-ecological zone (Methods 2.2.1)
#==========================================================

#--- 3. Agro-ecological zone of each site ----
# points       output of make_points()
# aez_rasters  list of GAEZ v4 AEZ57 rasters, one per country (cells outside the country are NA)
# Returns one row per site: effect_size_id, aez (GAEZ class)
site_aez <- function(points, aez_rasters) {
  v <- rep(NA_integer_, nrow(points))
  for (r in aez_rasters) {
    x <- terra::extract(r, terra::vect(st_transform(points, terra::crs(r))))[, 2]
    v <- coalesce(v, as.integer(x))
  }
  points %>% st_drop_geometry() %>% mutate(aez = v) %>% filter(!is.na(aez)) %>% distinct(effect_size_id, aez)
}

#--- 4. Main agro-ecological zones of the high-priority areas ----
# arc, rule    archetype polygons and high-priority rule (as in select_priority())
# aez_raster   GAEZ raster of the archetype's country; lookup: GAEZ_57_lookup.csv (value, label)
# min_share    minimum share (%) of the high-priority areas covered by a zone
main_aez <- function(arc, rule, aez_raster, lookup, min_share = 10) {
  pr <- arc[with(arc, eval(str2lang(rule))) %in% TRUE, ]
  v  <- terra::extract(aez_raster, terra::vect(st_transform(pr, terra::crs(aez_raster))))[, 2]
  tibble(aez = as.integer(v)) %>%
    filter(!is.na(aez)) %>%
    count(aez, name = "cells") %>%
    mutate(share = round(100 * cells / sum(cells), 1)) %>%
    filter(share >= min_share) %>%
    left_join(transmute(lookup, aez = as.integer(value), zone = label), by = "aez") %>%
    arrange(desc(share)) %>%
    select(aez, zone, share)
}

#--- 5. Sufficiency check and extension ----
# ids_priority     effect_size_id of the comparisons located in the high-priority areas
# pool             comparisons that can be used (after reclassification): effect_size_id, study_id, country
# sites            output of site_aez() for the pool
# main             output of main_aez()
# country_name     country of the archetype; neighbours: bordering project countries
# min_comparisons  minimum number of comparisons per archetype
#
# Steps (Methods 2.2.1):
#   sufficient when >= min_comparisons and >= 1 study in each main zone within the high-priority areas;
#   otherwise keep the priority comparisons and
#     - if < min_comparisons: add comparisons from the main zones elsewhere in the country,
#       then from neighbouring countries if still < min_comparisons;
#     - for each main zone with no study: add comparisons from that zone elsewhere in the country,
#       and from neighbouring countries only if the country has none.
# Returns list(ids = effect_size_id + selection, zones = coverage per main zone, sufficient, gaps)
select_evidence <- function(ids_priority, pool, sites, main, country_name, neighbours,
                            min_comparisons = 100) {
  
  pool    <- distinct(pool, effect_size_id, study_id, country)
  home    <- pool$effect_size_id[str_detect(pool$country, country_name)]
  nbr     <- pool$effect_size_id[str_detect(pool$country, paste(neighbours, collapse = "|")) &
                                   !pool$effect_size_id %in% home]
  in_zone <- function(z) unique(sites$effect_size_id[sites$aez %in% z])
  
  sel <- tibble(effect_size_id = intersect(ids_priority, pool$effect_size_id), selection = "High-priority areas")
  add <- function(sel, ids, label) {
    bind_rows(sel, tibble(effect_size_id = setdiff(ids, sel$effect_size_id), selection = label))
  }
  studies_in <- function(sel, z) {
    n_distinct(pool$study_id[pool$effect_size_id %in% intersect(sel$effect_size_id, in_zone(z))])
  }
  
  #--- check within the high-priority areas
  zone_studies <- vapply(main$aez, function(z) studies_in(sel, z), numeric(1))
  sufficient   <- nrow(sel) >= min_comparisons && all(zone_studies > 0)
  
  if (!sufficient) {
    #--- too few comparisons: main zones in the country, then neighbouring countries
    if (nrow(sel) < min_comparisons) {
      sel <- add(sel, intersect(home, in_zone(main$aez)), "Same zones, same country")
      if (nrow(sel) < min_comparisons)
        sel <- add(sel, intersect(nbr, in_zone(main$aez)), "Same zones, neighbouring countries")
    }
    #--- main zones without evidence: that zone in the country, neighbouring countries only if none
    for (z in main$aez) {
      if (studies_in(sel, z) > 0) next
      ids_home <- intersect(home, in_zone(z))
      sel <- if (length(ids_home) > 0) add(sel, ids_home, "Same zones, same country") else
        add(sel, intersect(nbr, in_zone(z)), "Same zones, neighbouring countries")
    }
  }
  
  zones <- main %>%
    mutate(studies_priority  = zone_studies,
           studies_final     = vapply(aez, function(z) studies_in(sel, z), numeric(1)),
           comparisons_final = vapply(aez, function(z) length(intersect(sel$effect_size_id, in_zone(z))), numeric(1)))
  
  list(ids = sel, zones = zones, sufficient = sufficient,
       gaps = zones$zone[zones$studies_final == 0])
}