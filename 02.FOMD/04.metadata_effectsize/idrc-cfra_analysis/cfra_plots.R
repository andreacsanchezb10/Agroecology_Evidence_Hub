# ============================================================
#  Africa Map with ADM1 (provinces/states) + Custom Points
#  Dependencies: install once, then re-run freely
# ============================================================

# --- 1. Install / load packages ---
packages <- c("ggplot2", "sf", "rnaturalearth", "rnaturalearthdata",
              "rnaturalearthhires", "dplyr")

new_pkgs <- packages[!packages %in% installed.packages()[, "Package"]]
if (length(new_pkgs)) {
  # rnaturalearthhires is on GitHub – needs remotes
  if ("rnaturalearthhires" %in% new_pkgs) {
    if (!"remotes" %in% installed.packages()[, "Package"])
      install.packages("remotes")
    remotes::install_github("ropensci/rnaturalearthhires")
    new_pkgs <- setdiff(new_pkgs, "rnaturalearthhires")
  }
  if (length(new_pkgs)) install.packages(new_pkgs)
}

library(ggplot2)
library(sf)
library(rnaturalearth)
library(rnaturalearthdata)
library(dplyr)

# ============================================================
# --- 2. Load your CSV  (EDIT THIS PATH) ---
# ============================================================
# Your CSV must have at minimum:
#   - a longitude column  (decimal degrees, e.g. 15.3)
#   - a latitude  column  (decimal degrees, e.g. -4.2)
# Optional: any extra columns (name, value, category…) for labels/colour

#csv_path <- "your_data.csv"        # <-- change to your file path
lon_col  <- "lon"            # <-- change to your longitude column name
lat_col  <- "lat"             # <-- change to your latitude  column name

#points_df <- read.csv(csv_path, stringsAsFactors = FALSE)

# Convert to sf object (WGS84)
points_sf <- st_as_sf(cfra.sites,
                      coords = c(lon_col, lat_col),
                      crs    = 4326,
                      remove = FALSE)

# ============================================================
# --- CFRA countries ---
# ============================================================
# Country borders (ADM0)
africa_countries <- ne_countries(
  continent = "Africa",
  scale     = "medium",       # "large" for more detail (slower)
  returnclass = "sf"
)

# ADM1 – provinces / states
africa_adm1 <- ne_states(
  country     = africa_countries$admin,   # all African countries
  returnclass = "sf"
) %>%
  filter(!is.na(geometry))               # drop any empty rows

# ============================================================
# --- 4. Plot ---
# ============================================================

# Optional: colour points by a column in your CSV, e.g. "category"
# Set colour_col <- NULL to use a single colour for all points.
colour_col <- "out_pillar"    # e.g. colour_col <- "category"

cfra.countries<-
  ggplot() +
  
  # ADM1 fill (light grey provinces)
  geom_sf(data  = africa_adm1,
          fill  = "#f5f0e8",
          colour = "#c8bfaf",
          linewidth = 0.25) +
  
  # Country borders (darker, thicker)
  geom_sf(data  = africa_countries,
          fill  = NA,
          colour = "#5a4a3a",
          linewidth = 0.6) +
  
  # Points
  {
    if (!is.null(colour_col)) {
      geom_sf(data  = points_sf,
              aes(colour = .data[[colour_col]]),
              size  = 2.5, alpha = 0.85)
    } else {
      geom_sf(data  = points_sf,
              colour = c("#d62728", "green","blue"),  # red – change as you like
              size   = 2.5, alpha  = 0.85)
    }
  } +
  
  # Coordinate limits (full Africa bounding box)
  coord_sf(xlim = c(-20, 55), ylim = c(-36, 38), expand = FALSE) +
  
  # Theme
  theme_minimal(base_size = 12) +
  theme(
    panel.background = element_rect(fill = "#d0e8f2", colour = NA), # ocean
    panel.grid       = element_line(colour = "#b0cfe0", linewidth = 0.2),
    axis.title       = element_blank(),
    legend.position  = "right"
  ) +
  labs(
    title    = "CFRA countries",
    subtitle = "",
    colour   = colour_col,
    caption  = "Geodata: Natural Earth"
  )

print(cfra.countries)

# --- 5. Save to file ---
output_file <- "cfra_countries.png"   # change extension to .pdf / .svg if needed

ggsave("cfra_countries.png", plot = p,
       width = 10, height = 11, dpi = 300, bg = "white")

message("Map saved to: ", normalizePath(output_file))

names(africa_countries)
# ============================================================
# --- DEEP-DIVE: Ethiopia ---
# ============================================================
# Optional: colour points by a column in your CSV, e.g. "category"
# Set colour_col <- NULL to use a single colour for all points.
colour_col <- "out_pillar"    # e.g. colour_col <- "category"

cfra.ethiopia
  ggplot() +
  
  # ADM1 fill (light grey provinces)
  geom_sf(data  = africa_adm1%>%
            filter(admin=="Ethiopia"),
          fill  = "#f5f0e8",
          colour = "#c8bfaf",
          linewidth = 0.25) +
  
  # Country borders (darker, thicker)
  geom_sf(data  = africa_countries%>%
            filter(sovereignt=="Ethiopia"),
          fill  = NA,
          colour = "#5a4a3a",
          linewidth = 0.6) +
  
  # Points
  {
    if (!is.null(colour_col)) {
      geom_sf(data  = points_sf%>%
                filter(country=="Ethiopia"),
              aes(colour = .data[[colour_col]]),
              size  = 2.5, alpha = 0.85)
    } else {
      geom_sf(data  = points_sf%>%
                filter(country=="Ethiopia"),
              colour = c("#d62728", "green","blue"),  # red – change as you like
              size   = 2.5, alpha  = 0.85)
    }
  } +
  
  # Coordinate limits (full Africa bounding box)
  #coord_sf(xlim = c(-20, 55), ylim = c(-36, 38), expand = FALSE) +
  
  # Theme
  theme_minimal(base_size = 12) +
  theme(
    panel.background = element_rect(fill = "#d0e8f2", colour = NA), # ocean
    panel.grid       = element_line(colour = "#b0cfe0", linewidth = 0.2),
    axis.title       = element_blank(),
    legend.position  = "right"
  ) +
  labs(
    title    = "Ethiopia",
    subtitle = "",
    colour   = colour_col,
    caption  = "Geodata: Natural Earth"
  )

print(cfra.countries)

# --- 5. Save to file ---
output_file <- "cfra_countries.png"   # change extension to .pdf / .svg if needed

ggsave("cfra_countries.png", plot = p,
       width = 10, height = 11, dpi = 300, bg = "white")

message("Map saved to: ", normalizePath(output_file))

#######################################################################
# ============================================================
# Donut-chart matrix: Agricultural practices × Impact areas
# ============================================================

library(ggplot2)
library(dplyr)
library(tidyr)

# ------------------------------------------------------------------
# 1. DATA
# Each cell has a number (total studies) and a colour profile.
# The donuts show proportions of: positive (green), negative (red),
# neutral/mixed (yellow), and no-effect/unknown (grey).
# These proportions are estimated visually from the original figure.
# Replace the p_pos / p_neg / p_neu / p_none columns with real data
# if you have the underlying dataset.
# ------------------------------------------------------------------

practices <- c("Plant\nprotection",
               "Landscape\nfeatures\nmanagement",
               "Organic\nfarming",
               "Water\nmanagement",
               "Manure\nmanagement",
               "Animal\nhusbandry",
               "Crop rotation\nand\ndiversification",
               "Fertilisation\nand soil\namendments",
               "Grassland\nand grazing",
               "Soil\nmanagement")

impacts <- c("Pollution",
             "Sustainable\nuse of\nresources",
             "Biodiversity",
             "Carbon\nsequestration",
             "Agricultural\nproduction",
             "Soil health",
             "GHG\nemissions")

# Cell data: practice, impact, n, %positive, %negative, %neutral, %none
# Estimated proportions sum to 1; NA = cell is empty in the original
raw <- tribble(
  ~practice,                ~impact,                     ~n,   ~pos,  ~neg,  ~neu,  ~none,
  "Plant\nprotection",       "Pollution",                  4,   0.25,  0.50,  0.25,  0.00,
  "Landscape\nfeatures\nmanagement","Pollution",          125,  0.60,  0.10,  0.20,  0.10,
  "Organic\nfarming",        "Pollution",                 33,   0.55,  0.15,  0.20,  0.10,
  "Water\nmanagement",       "Pollution",                 17,   0.30,  0.30,  0.20,  0.20,
  "Manure\nmanagement",      "Pollution",                 85,   0.20,  0.55,  0.15,  0.10,
  "Animal\nhusbandry",       "Pollution",                 86,   0.25,  0.40,  0.25,  0.10,
  "Crop rotation\nand\ndiversification","Pollution",      25,   0.50,  0.15,  0.25,  0.10,
  "Fertilisation\nand soil\namendments","Pollution",     170,   0.15,  0.60,  0.15,  0.10,
  "Grassland\nand grazing",  "Pollution",                 14,   0.40,  0.30,  0.20,  0.10,
  "Soil\nmanagement",        "Pollution",                 83,   0.45,  0.25,  0.20,  0.10,
  
  "Landscape\nfeatures\nmanagement","Sustainable\nuse of\nresources", 2, 0.50,0.10,0.30,0.10,
  "Organic\nfarming",        "Sustainable\nuse of\nresources",        31, 0.55,0.10,0.25,0.10,
  "Water\nmanagement",       "Sustainable\nuse of\nresources",       352, 0.55,0.10,0.25,0.10,
  "Manure\nmanagement",      "Sustainable\nuse of\nresources",        24, 0.30,0.20,0.30,0.20,
  "Animal\nhusbandry",       "Sustainable\nuse of\nresources",        35, 0.35,0.25,0.25,0.15,
  "Crop rotation\nand\ndiversification","Sustainable\nuse of\nresources",21,0.55,0.10,0.25,0.10,
  "Fertilisation\nand soil\namendments","Sustainable\nuse of\nresources",62,0.30,0.25,0.25,0.20,
  "Grassland\nand grazing",  "Sustainable\nuse of\nresources",         1, 0.50,0.10,0.30,0.10,
  "Soil\nmanagement",        "Sustainable\nuse of\nresources",       102, 0.50,0.15,0.25,0.10,
  
  "Plant\nprotection",       "Biodiversity",              77,   0.30,  0.45,  0.15,  0.10,
  "Landscape\nfeatures\nmanagement","Biodiversity",      203,   0.65,  0.10,  0.15,  0.10,
  "Organic\nfarming",        "Biodiversity",              83,   0.60,  0.10,  0.20,  0.10,
  "Crop rotation\nand\ndiversification","Biodiversity",  40,   0.55,  0.10,  0.25,  0.10,
  "Fertilisation\nand soil\namendments","Biodiversity",   3,   0.20,  0.50,  0.20,  0.10,
  "Grassland\nand grazing",  "Biodiversity",             109,   0.55,  0.15,  0.20,  0.10,
  "Soil\nmanagement",        "Biodiversity",              49,   0.50,  0.15,  0.25,  0.10,
  
  "Landscape\nfeatures\nmanagement","Carbon\nsequestration",112, 0.60,0.10,0.20,0.10,
  "Organic\nfarming",        "Carbon\nsequestration",     32,   0.50,  0.15,  0.25,  0.10,
  "Water\nmanagement",       "Carbon\nsequestration",      2,   0.30,  0.40,  0.20,  0.10,
  "Fertilisation\nand soil\namendments","Carbon\nsequestration",66,0.40,0.25,0.25,0.10,
  "Grassland\nand grazing",  "Carbon\nsequestration",     77,   0.50,  0.20,  0.20,  0.10,
  "Soil\nmanagement",        "Carbon\nsequestration",    167,   0.60,  0.10,  0.20,  0.10,
  "Fertilisation\nand soil\namendments","Carbon\nsequestration",48,0.40,0.25,0.25,0.10,
  
  "Plant\nprotection",       "Agricultural\nproduction",  56,   0.35,  0.30,  0.25,  0.10,
  "Landscape\nfeatures\nmanagement","Agricultural\nproduction",48, 0.40,0.20,0.25,0.15,
  "Organic\nfarming",        "Agricultural\nproduction",  85,   0.35,  0.30,  0.25,  0.10,
  "Water\nmanagement",       "Agricultural\nproduction", 394,   0.65,  0.10,  0.15,  0.10,
  "Crop rotation\nand\ndiversification","Agricultural\nproduction",77,0.60,0.10,0.20,0.10,
  "Fertilisation\nand soil\namendments","Agricultural\nproduction",173,0.55,0.15,0.20,0.10,
  "Grassland\nand grazing",  "Agricultural\nproduction", 119,   0.45,  0.25,  0.20,  0.10,
  "Soil\nmanagement",        "Agricultural\nproduction", 237,   0.55,  0.15,  0.20,  0.10,
  "Fertilisation\nand soil\namendments","Agricultural\nproduction",55,0.35,0.25,0.25,0.15,
  
  "Plant\nprotection",       "Soil health",               28,   0.25,  0.35,  0.25,  0.15,
  "Landscape\nfeatures\nmanagement","Soil health",       178,   0.60,  0.10,  0.20,  0.10,
  "Organic\nfarming",        "Soil health",               16,   0.60,  0.10,  0.20,  0.10,
  "Water\nmanagement",       "Soil health",               24,   0.40,  0.20,  0.25,  0.15,
  "Fertilisation\nand soil\namendments","Soil health",  123,   0.40,  0.25,  0.25,  0.10,
  "Grassland\nand grazing",  "Soil health",              340,   0.55,  0.10,  0.25,  0.10,
  "Soil\nmanagement",        "Soil health",              122,   0.55,  0.15,  0.20,  0.10,
  "Fertilisation\nand soil\namendments","Soil health",  385,   0.50,  0.15,  0.25,  0.10,
  
  "Plant\nprotection",       "GHG\nemissions",             3,   0.20,  0.40,  0.25,  0.15,
  "Landscape\nfeatures\nmanagement","GHG\nemissions",   152,   0.55,  0.10,  0.25,  0.10,
  "Organic\nfarming",        "GHG\nemissions",            36,   0.45,  0.20,  0.25,  0.10,
  "Water\nmanagement",       "GHG\nemissions",            68,   0.30,  0.35,  0.25,  0.10,
  "Manure\nmanagement",      "GHG\nemissions",           109,   0.20,  0.55,  0.15,  0.10,
  "Animal\nhusbandry",       "GHG\nemissions",           145,   0.25,  0.45,  0.20,  0.10,
  "Crop rotation\nand\ndiversification","GHG\nemissions", 15,  0.50,  0.15,  0.25,  0.10,
  "Fertilisation\nand soil\namendments","GHG\nemissions",159,  0.20,  0.50,  0.20,  0.10,
  "Grassland\nand grazing",  "GHG\nemissions",            39,   0.40,  0.25,  0.25,  0.10,
  "Soil\nmanagement",        "GHG\nemissions",           150,   0.50,  0.15,  0.25,  0.10
)

# ------------------------------------------------------------------
# 2. TIDY: pivot proportions to long format, deduplicate
# ------------------------------------------------------------------
df <- raw %>%
  distinct(practice, impact, .keep_all = TRUE) %>%
  pivot_longer(cols = c(pos, neg, neu, none),
               names_to  = "outcome",
               values_to = "proportion") %>%
  mutate(
    practice = factor(practice, levels = practices),
    impact   = factor(impact,   levels = rev(impacts)),   # rev so top row = first level
    outcome  = factor(outcome,  levels = c("pos","neu","neg","none"))
  )

# ------------------------------------------------------------------
# 3. BUILD DONUTS via polar coordinates
#    Each donut is drawn as a stacked bar in polar coords, faceted.
# ------------------------------------------------------------------
colours <- c(pos  = "#4CAF50",   # green
             neu  = "#FFC107",   # amber
             neg  = "#E53935",   # red
             none = "#BDBDBD")   # grey

p <- ggplot(df, aes(x = 2, y = proportion, fill = outcome)) +
  geom_col(width = 0.9, colour = "white", linewidth = 0.3) +
  coord_polar(theta = "y", start = -pi / 2, direction = 1) +
  xlim(0.5, 2.5) +                          # 0.5 = hole size
  facet_grid(impact ~ practice,
             switch = "both") +             # labels on left & bottom
  scale_fill_manual(
    values = colours,
    labels = c(pos = "Positive", neu = "Neutral / mixed",
               neg = "Negative", none = "No effect / unknown"),
    name   = NULL
  ) +
  # study-count label in the centre of each donut
  geom_text(
    data = distinct(df, practice, impact, n),
    aes(x = 0.5, y = 0, label = n),
    inherit.aes = FALSE,
    size = 2.2, fontface = "bold", colour = "#333333"
  ) +
  theme_void(base_size = 9) +
  theme(
    strip.text.x    = element_text(size = 7,  angle = 60, hjust = 0,
                                   vjust = 0,  margin = margin(b = 4)),
    strip.text.y    = element_text(size = 8,  angle = 0,  hjust = 1,
                                   margin = margin(r = 6)),
    strip.placement = "outside",
    legend.position = "bottom",
    legend.text     = element_text(size = 8),
    legend.key.size = unit(0.45, "cm"),
    plot.margin     = margin(t = 60, r = 10, b = 10, l = 80),
    panel.spacing   = unit(0.15, "cm"),
    plot.title      = element_text(size = 10, face = "bold", hjust = 0.5,
                                   margin = margin(b = 6))
  ) +
  labs(title = "Number of studies and their outcomes by agricultural practice and impact area")
p
# ------------------------------------------------------------------
# 4. SAVE
# ------------------------------------------------------------------
ggsave(
  filename = "/mnt/user-data/outputs/donut_matrix.png",
  plot     = p,
  width    = 14,
  height   = 8,
  dpi      = 180,
  bg       = "white"
)

message("Saved → /mnt/user-data/outputs/donut_matrix.png")
