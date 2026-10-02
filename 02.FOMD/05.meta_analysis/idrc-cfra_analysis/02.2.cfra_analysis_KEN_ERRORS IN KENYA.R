#==========================================================
#--- Identify rows where C and T do not vary
#==========================================================
# "C: X_vs_T: Y" -> TRUE if X != Y, FALSE if equal, NA if empty
ct_differs <- function(x) {
  C <- str_trim(str_remove(str_extract(x, "^C: .*?(?=_vs_T: )"), "^C: "))
  T <- str_trim(str_remove(str_extract(x, "_vs_T: .*$"), "^_vs_T: "))
  tolower(C) != tolower(T)
}

# raw C_x / T_x pair differs (one side empty also counts as differing)
raw_differs <- function(df, p) {
  c <- tolower(str_trim(as.character(df[[paste0("C_", p)]])))
  t <- tolower(str_trim(as.character(df[[paste0("T_", p)]])))
  !(is.na(c) & is.na(t)) & (is.na(c) | is.na(t) | c != t)
}

practice_groups <- c("variety_management", "planting_management", "diversification_spatial",
                     "diversification_temporal", "soil_management", "nutrient_management",
                     "pest_management", "water_management", "biomass_management")
harm_cols <- c(paste0(practice_groups, "_practice"), paste0(practice_groups, "_subpractice"))

raw_pairs <- sub("^C_", "", grep("^C_.*(_subpractice|crop_tree_diversity|crop_tree_variety|crop_tree_density)$",
                                 names(arc2a.fomd10), value = TRUE))
raw_pairs <- raw_pairs[paste0("T_", raw_pairs) %in% names(arc2a.fomd10)]

# Level 1: harmonised columns
arc2a.vary <- arc2a.fomd10 %>%
  mutate(across(all_of(harm_cols), ct_differs, .names = "d_{.col}")) %>%
  mutate(vary_harmonised = rowSums(across(starts_with("d_")), na.rm = TRUE) > 0) %>%
  select(-starts_with("d_"))

# Level 2: raw columns, and which ones differ
for (p in raw_pairs) arc2a.vary[[paste0("r_", p)]] <- raw_differs(arc2a.vary, p)
arc2a.vary <- arc2a.vary %>%
  mutate(vary_raw = rowSums(across(starts_with("r_")), na.rm = TRUE) > 0,
         vary_raw_which = apply(across(starts_with("r_")), 1, function(r) {
           w <- sub("^r_", "", names(r)[r %in% TRUE])
           if (length(w) == 0) NA_character_ else paste(w, collapse = "..")
         })) %>%
  select(-starts_with("r_"))

table(vary_harmonised = arc2a.vary$vary_harmonised, vary_raw = arc2a.vary$vary_raw)

# Rows that vary only in raw columns (harmonisation gap)
arc2a.vary %>% filter(!vary_harmonised, vary_raw) %>% count(vary_raw_which, sort = TRUE)

# Rows that vary in nothing -> to exclude
arc2a.novary <- arc2a.vary %>% filter(!vary_harmonised, !vary_raw)
nrow(arc2a.novary)                 #181
length(unique(arc2a.novary$study_id)) #17
arc2a.novary %>% count(study_id, out_subindicator, sort = TRUE)

# Keep only rows where something varies
arc2a.fomd10.contrast <- arc2a.vary %>% filter(vary_harmonised | vary_raw)
nrow(arc2a.fomd10.contrast)        #7954

arc2a.novary %>%
  group_by(study_id) %>%
  summarise(authors = first(authors), year = first(year), title = first(title),
            n_rows = n(),
            outcomes = paste(sort(unique(out_subindicator)), collapse = "; "),
            .groups = "drop") %>%
  arrange(desc(n_rows)) %>%
  View()

arc2a.novary %>%
  #filter(study_id == "CJ0146") %>%
  select(study_id, effect_size_id, out_subindicator,
         matches("^(C|T)_.*_subpractice$"),
         C_crop_tree_diversity, T_crop_tree_diversity) %>%
  View()
