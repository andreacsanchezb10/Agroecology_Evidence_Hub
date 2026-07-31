############################################
# Functions to create densities in 10_FOMD
############################################
#-----------------------------------------------------------------------------------------------------
# Reusable function to combine crop_diversity + crop_density columns separated by "/" or "-"
#-----------------------------------------------------------------------------------------------------
create_density_crop <- function(diversity, density) {
  if (is.na(diversity) || diversity == "" || diversity == "NULL") return("")
  
  # Helper to clean individual density values
  clean_density <- function(d) {
    if (is.na(d) || d == "" || d == "NULL" || d == "NA") return("Unspecified(Unspecified)")
    return(d)
  }
  
  # Split on / or - outside parentheses
  # Strategy: track parenthesis depth character by character
  split_outside_parens <- function(x, delimiters = c("/", "-")) {
    if (is.na(x) || x == "") return(character(0))
    chars <- strsplit(x, "")[[1]]
    depth <- 0
    positions <- c()
    for (i in seq_along(chars)) {
      if (chars[i] == "(") depth <- depth + 1
      else if (chars[i] == ")") depth <- depth - 1
      else if (chars[i] %in% delimiters && depth == 0) positions <- c(positions, i)
    }
    if (length(positions) == 0) return(trimws(x))
    
    # Extract parts and separators
    starts <- c(1, positions + 1)
    ends   <- c(positions - 1, nchar(x))
    parts  <- trimws(substring(x, starts, ends))
    parts
  }
  
  get_seps_outside_parens <- function(x, delimiters = c("/", "-")) {
    if (is.na(x) || x == "") return(character(0))
    chars <- strsplit(x, "")[[1]]
    depth <- 0
    seps  <- c()
    for (i in seq_along(chars)) {
      if (chars[i] == "(") depth <- depth + 1
      else if (chars[i] == ")") depth <- depth - 1
      else if (chars[i] %in% delimiters && depth == 0) seps <- c(seps, chars[i])
    }
    seps
  }
  
  div_crops <- split_outside_parens(diversity)
  den_crops <- split_outside_parens(density)
  div_seps  <- get_seps_outside_parens(diversity)
  
  if (length(den_crops) == 1) den_crops <- rep(den_crops, length(div_crops))
  
  if (length(div_crops) == 0) return("")
  
  paired <- mapply(function(crop, dens) {
    paste0(crop, "[", clean_density(dens), "]")
  }, div_crops, den_crops)
  
  result <- paired[1]
  if (length(div_seps) > 0) {
    for (i in seq_along(div_seps)) {
      result <- paste0(result, div_seps[i], paired[i + 1])
    }
  }
  
  return(as.character(result))
}






#------------------------------------------------------------------------------
# Reusable function to combine ph material + amount + unit separated by ".."
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
        au_clean <- gsub("/ha|/m2|/plant", "", au)
        paste0(a, "[", au_clean, "]")
      }
    }, applied_parts, amount_unit_parts)
  } else {
    # NA guard here too
    au <- amount_unit_parts[1]
    if (is.na(au) || grepl("^NA$|^NA\\(|\\(NA\\)", au)) {
      pairs <- paste0(applied_parts, "[Unspecified(Unspecified)]")
    } else {
      au_clean <- gsub("/ha|/m2|/plant", "", au)
      pairs <- paste0(applied_parts, "[", au_clean, "]")
    }
  }
  
  paste(pairs, collapse = "..")
}

#------------------------------------------------------------------------------
# Function to sort items within a string alphabetically
#------------------------------------------------------------------------------

sort_econ_inputs <- function(x) {
  # Handle empty strings
  if (is.na(x) || x == "") return(x)
  
  # Split by "..", sort, and rejoin
  items <- strsplit(x, "\\.\\.")[[1]]
  paste(sort(trimws(items)), collapse = "..")
}



################################
# FUNCTIONS to remove agroforestry practices from intercropping section
##################################
# Terms that belong in agrof (detected by pattern, not exact match)
agrof_pattern <- "Multistrata Agroforestry|Alleycropping|Other Agroforestry"
# Helper: for one row's intercrop string, return list(intercrop=..., agrof=...)
split_and_route <- function(intercrop_val, agrof_val) {
  parts <- strsplit(intercrop_val, "\\.\\.")[[1]]
  
  is_agrof <- grepl(agrof_pattern, parts)
  
  agrof_parts    <- parts[is_agrof]
  intercrop_parts <- parts[!is_agrof]
  
  
  
  # Combine with existing agrof value (avoid duplicates)
  new_agrof <- unique(c(agrof_val[agrof_val != ""], agrof_parts))
  
  list(
    intercrop = paste(intercrop_parts, collapse = ".."),
    agrof     = paste(new_agrof, collapse = "..")
  )
}

# Apply for one prefix
move_to_agrof <- function(df, prefix) {
  ic_col <- paste0(prefix, "_intercrop_subpractice")
  af_col <- paste0(prefix, "_agrof_subpractice")
  
  results <- Map(split_and_route, df[[ic_col]], df[[af_col]])
  
  df[[ic_col]] <- vapply(results, `[[`, character(1), "intercrop")
  df[[af_col]] <- vapply(results, `[[`, character(1), "agrof")
  df
}

################################
# FUNCTIONS FOR CLEANING NAMES
##################################
crop_name_fixes <- c(
  "\\bBalanites aegyptica\\b"              = "Balanites aegyptiaca",
  "\\bBlack [Oo]ats?\\b"                  = "Black Oats",   # catches "Black oat", "Black oats"
  "\\bCommon [Vv]etch\\b"                 = "Common Vetch",
  "\\bCongo Gra\\b"                       = "Congo Grass",
  "\\bCrotalaria spectabili\\b"           = "Crotalaria spectabilis",
  "\\bDesho Gra\\b"                       = "Desho Grass",
  # FIX 1: Use a lookahead so the hyphen is NOT consumed / treated as separator
  "\\bFicus vallis-choudae\\b"            = "Ficus vallis choudae",  # keep as-is (no-op anchor)
  "\\bFicus vallis\\b(?!-choudae)"        = "Ficus vallis choudae",  # only fix incomplete form
  
  "\\bFinger [Mm]illet\\b"               = "Finger Millet",
  "\\bGuinea Gra\\b"                     = "Guinea Grass",
  "\\bHibiscu\\b"                        = "Hibiscus",
  "\\bJute [Mm]allow\\b"                 = "Jute Mallow",   # catches "Jute mallow"
  "\\bKikuyu Gra\\b"                     = "Kikuyu Grass",
  "\\bNapier Gra\\b"                     = "Napier Grass",
  "\\bOat\\b"                            = "Oats",
  "\\bPalisade Gra\\b"                   = "Palisade Grass",
  "\\bPearl [Mm]illet\\b"               = "Pearl Millet",   # catches "Pearl millet" in compounds
  "\\bpersea americana\\b"              = "Persea americana",
  "\\bPiliostigma reticulata\\b"        = "Piliostigma reticulatum",
  "\\b[Pp]urple [Vv]etch\\b"           = "Purple Vetch",
  "\\bRuzigra\\b"                       = "Ruzigrass",
  "\\bSudan [Gg]ra\\b"                 = "Sudan Grass",    # standardise capitalisation
  "\\bSmutsfinger Gra\\b"              = "Smutsfinger Grass",
  "\\bTurkey [Bb]erry\\b"             = "Turkey Berry",    # NEW
  "\\bUnspecified Fodder Gra\\b"       = "Unspecified Fodder Grass",
  "\\b[Uu]nspecified [Ll]egume\\b"    = "Unspecified Legume",
  "\\bVetiver Gra\\b"                  = "Vetiver Grass"
)

apply_crop_fixes <- function(x, fixes) {
  for (pattern in names(fixes)) {
    x <- str_replace_all(x, regex(pattern), fixes[[pattern]])
  }
  x
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
    # Skip if density has only 1 component (broadcast case)
    if (ndn == 1) return(NULL)
    if (nd != ndn) data.frame(
      row           = i,
      doi           = doi,
      study_id      = study_id,
      diversity_col = diversity_col,
      density_col   = density_col,
      n_diversity   = nd,
      n_density     = ndn,
      diversity     = d,
      density       = dn
    )
  }, div, den, seq_along(div), df$doi, df$study_id, SIMPLIFY = FALSE)
  
  do.call(rbind, Filter(Negate(is.null), mismatches))
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

