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