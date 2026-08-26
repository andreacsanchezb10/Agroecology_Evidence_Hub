# fomd_fun/fun_pairing_CT.R

#==========================================================
# Read datasets
#==========================================================

#---10_FOMD_metadata_synthesis_long
fomd10.cols<-read_xlsx(
  file.path(path.metadata.structure,"10_FOMD_metadata_synthesis_short.xlsx"),
  sheet = "10_FOMD_metadata_synthesis")%>%
  select(-c(
    "country","country_ISO",
    "C_product_type",      "C_product_subtype",   "C_product_simple",   
    "T_product_type",      "T_product_subtype",   "T_product_simple",
    "C_out_mean",                "T_out_mean",               
    "C_out_sd",                  "T_out_sd" ,                 "C_out_sample_size_imputed",
    "T_out_sample_size_imputed", "C_out_cv_group_avg",        "T_out_cv_group_avg"  ,     
    "C_out_cv_final",            "T_out_cv_final" ,           "out_cv_grouping_method" ,  
    "out_effect_size_type",      "out_effect_size_yi",        "out_effect_size_vi"  ,     
    "pler_value_calc",           "pler_var_value_calc",       "ler_value_total_calc",     
    "ler_var_value_total_calc"))
fomd10.cols<-names(fomd10.cols)

#==========================================================
# Define pairing columns
#==========================================================
# Columns every branch matches Control against Treatment on: study identity,
# location, outcome type, timing.
pairing_base_cols <- c(
  #--- practice
  "practice_id",
  #--- bibliographic
  "ss_id","study_id","authors","title","year","journal","doi",
  #--- location
  "country",
  #-- experiment_details
  "exp_design","exp_duration",
  #--- experiment_time
  "time_raw","time_year_start","time_year_end","time_season",
  
  #---product_outcome----
  "bio_func_group","bio_ground_ref" ,
  #--- outcome
  "out_subindicator", "out_indicator","out_subpillar" , "out_pillar",
  "out_soil_depth_l","out_soil_depth_u",
  "out_npv_discount_rate",	"out_npv_econ_period",
  "out_wg_start", "out_wg_start_unit","out_wg_days",
  #---outcome_time
  "out_agg_stat","out_year","out_year_start","out_year_end",
  "out_season_start","out_season_end"
)

# One row per outcome type (subpillar) + matching strategy (branch).
# extra_cols = columns THAT subpillar also needs to match on, on top of
# pairing_base_cols. Add a row here to add/change a subpillar's matching
# key without touching any function below.
pairing_spec_cols <- tribble(
  ~subpillar,     ~branch,        ~extra_cols,
  #--------------------------------------
  #--- out_subpillar =="Biodiversity"----
  #--------------------------------------
  "Biodiversity", "context",      list(c(
    #--- outcome_experimental_design
    "out_exp_design", "out_exp_plot_size",
    #---product_outcome----
    "product",
    #---outcome----
    "out_subindicator_unit"
    )),

  #--------------------------------------
  #--- out_subpillar =="Economics"----
  #--------------------------------------
  "Economics",    "context",      list(c(
    #--- location
    "site_type","site_id","site_admin", "site_agg" ,"site_latlong_type",                    
    "site_latitude","site_longitude","site_buffer","site_key",
    #--- outcome_experimental_design
    #"out_exp_design", "out_exp_plot_size",
    #---outcome----
    "out_subindicator_unit"
  )),
  
  #--------------------------------------
  #--- out_subpillar =="Efficiency"----
  #--------------------------------------
  "Efficiency",    "context",      list(c(
    #--- location
    "site_type","site_id","site_admin", "site_agg" ,"site_latlong_type",                    
    "site_latitude","site_longitude","site_buffer","site_key",
    #--- outcome_experimental_design
   #"out_exp_design", "out_exp_plot_size",
    #---outcome----
    "out_subindicator_unit"
  )),
  
  #--------------------------------------
  #--- out_subpillar =="Physical"----
  #--------------------------------------
  "Physical",    "context",      list(c(
    #--- location
    "site_type","site_id","site_admin", "site_agg" ,"site_latlong_type",                    
    "site_latitude","site_longitude","site_buffer","site_key",
    #--- outcome_experimental_design
    #"out_exp_design", "out_exp_plot_size",
    #---outcome----
    "out_subindicator_unit"
  )),
  
  #--------------------------------------
  #--- out_subpillar =="Yield" ----
  #--- For Pairing focal yield ----
  #--------------------------------------
  "Yield",        "focal",        list(c(
    #--- location
    "site_type","site_id","site_admin", "site_agg" ,"site_latlong_type",                    
    "site_latitude","site_longitude","site_buffer","site_key",
    #---product_outcome----
    "product",
    #---outcome----
    "out_subindicator_unit"
  )),
  #--------------------------------------
  #--- out_subpillar =="Yield"----
  #--- For Pairing partial ler yield ----
  #--------------------------------------
  "Yield",        "partial_ler",  list(c(
    #--- location
    "site_type","site_id","site_admin", "site_agg" ,"site_latlong_type",                    
    "site_latitude","site_longitude","site_buffer","site_key",
    #---product_outcome----
    "product"
  )),
  
  "Yield",        "total_ler",    list(character(0))
)

#==========================================================
#--- Pairing context function ---
## Used for out_subpillar: "Biodiversity", "Economics","Efficiency","Physical"
## Matching mechanism: Control row matches Treatment row when 
#pairing_base_cols + that subpillar's extra_cols are identical
#==========================================================
#--- small helpers fun_pair_context() depends on----

# Pastes a row's values across `cols` into one string — the "fingerprint"
# used to detect whether two rows describe the same comparison.
build_row_id <- function(df, cols, sep = "/") {
  cols <- intersect(cols, names(df))
  do.call(paste, c(as.list(df[cols]), sep = sep))
}

# A Control row can list several treatments in out_comparison_treatment,
# joined by "..". This explodes that into one row per treatment name.
split_ct <- function(df, sep = "\\.\\.") {
  df %>%
    tidyr::separate_rows(out_comparison_treatment, sep = sep) %>%
    dplyr::mutate(out_comparison_treatment = stringr::str_squish(out_comparison_treatment)) %>%
    dplyr::filter(out_comparison_treatment != "")
}

# builds row_id (or out_comparison_id) for whichever subpillars are listed in
# `spec`, dispatching each subpillar's own extra_cols via id_col_fn — so
# adding a row to pairing_spec_cols (e.g. the missing "Yield"/"context" row)
# is picked up automatically, no code change needed here.
# For each subpillar in spec: compute its fingerprint for every row, but
# only keep it where out_subpillar actually matches that subpillar; then
# coalesce across subpillars into one column. Rows whose subpillar isn't
# in spec end up NA (e.g. Yield rows are NA here, since spec only has
# Biodiversity/Economics for the "context" branch).
build_dispatch_id <- function(data, spec, id_col_fn) {
  ids <- lapply(seq_len(nrow(spec)), function(i) {
    matches <- data$out_subpillar == spec$subpillar[i]
    cols    <- id_col_fn(unlist(spec$extra_cols[[i]]))
    ifelse(matches, build_row_id(data, cols), NA_character_)
  })
  do.call(dplyr::coalesce, ids)
}

# Pairs Control with Treatment for the "Biodiversity" subpillar and "context" branch 
#( Biodiversity + Economics +"Efficiency"+"Physical") — a direct one-to-one match, no pivoting.
fun_pair_bio_context <- function(df) {
  
  spec <- pairing_spec_cols %>% dplyr::filter(subpillar == "Biodiversity",branch == "context")
  
  purrr::map_dfr(seq_len(nrow(spec)), function(i) {
    sp      <- spec$subpillar[i]
    extra   <- unlist(spec$extra_cols[[i]])
    id_cols <- c(pairing_base_cols, extra)
    
    sub_df <- df %>% dplyr::filter(out_subpillar == sp)
    sub_df$row_id <- build_row_id(sub_df, id_cols)
    
    df.C <- sub_df %>%
      dplyr::filter(grepl("C", practice_id)) %>%
      split_ct()
    
    df.C$out_comparison_id <- build_row_id(
      df.C, c("out_comparison_treatment", setdiff(id_cols, "practice_id"))
    )
    
    df.C %>%
      dplyr::filter(!is.na(row_id)) %>%
      dplyr::select(-row_id) %>%
      dplyr::left_join(
        # "product" is never dropped, even when it's part of id_cols (e.g.
        # Biodiversity) — matching on it doesn't mean only one copy survives
        sub_df %>% dplyr::select(
          -dplyr::any_of(setdiff(id_cols, c("practice_id", 
                                            "country",extra)))),
        by = c("out_comparison_id" = "row_id"),
        suffix = c(".C", ".T")
      ) %>%
      dplyr::rename_with(~ paste0("T_", sub("\\.T$", "", .)), dplyr::ends_with(".T")) %>%
      dplyr::rename_with(~ paste0("C_", sub("\\.C$", "", .)), dplyr::ends_with(".C")) %>%
      dplyr::filter(!is.na(T_practice_id)) %>%
      dplyr::mutate(out_comparison_id = paste0(C_practice_id, "-", out_comparison_id))
  })
}

# Pairs Control with Treatment for the !="Biodiversity" subpillar and "context" branch 
#( Biodiversity + Economics) — a direct one-to-one match, no pivoting.
fun_pair_context <- function(df) {
  
  spec <- pairing_spec_cols %>% dplyr::filter(subpillar !="Biodiversity",branch == "context")
  
  purrr::map_dfr(seq_len(nrow(spec)), function(i) {
    sp      <- spec$subpillar[i]
    extra   <- unlist(spec$extra_cols[[i]])
    id_cols <- c(pairing_base_cols, extra)
    
    sub_df <- df %>% dplyr::filter(out_subpillar == sp)
    sub_df$row_id <- build_row_id(sub_df, id_cols)
    
    df.C <- sub_df %>%
      dplyr::filter(grepl("C", practice_id)) %>%
      split_ct()
    
    df.C$out_comparison_id <- build_row_id(
      df.C, c("out_comparison_treatment", setdiff(id_cols, "practice_id"))
    )
    
    df.C %>%
      dplyr::filter(!is.na(row_id)) %>%
      dplyr::select(-row_id) %>%
      dplyr::left_join(
        # "product" is never dropped, even when it's part of id_cols (e.g.
        # Biodiversity) — matching on it doesn't mean only one copy survives
        sub_df %>% dplyr::select(
          -dplyr::any_of(setdiff(id_cols, c("practice_id", 
                                            "country",extra
                                           )))),
        by = c("out_comparison_id" = "row_id"),
        suffix = c(".C", ".T")
      ) %>%
      dplyr::rename_with(~ paste0("T_", sub("\\.T$", "", .)), dplyr::ends_with(".T")) %>%
      dplyr::rename_with(~ paste0("C_", sub("\\.C$", "", .)), dplyr::ends_with(".C")) %>%
      dplyr::filter(!is.na(T_practice_id)) %>%
      dplyr::mutate(out_comparison_id = paste0(C_practice_id, "-", out_comparison_id))
  })
}


#==========================================================
#--- Pairing focal function ---
## Used for out_subpillar: "Yield"
## Applies when the study reports yield for a single, focal crop — comparing
## that same crop's yield under a control (e.g. monoculture) against the same
## crop grown under a Treatment system (e.g. intercropping, crop
## rotation, agroforestry, etc.). Only that one crop's yield is tracked, so
## no combined multi-crop calculation (LER) is needed or possible.
## Distinct from Total/Partial LER, which require yield values for *several*
## crops grown together, to compute how their combined land-use efficiency
## compares against separate monocultures.
#==========================================================
# TRUE for rows that are a plain single-value Yield comparison — i.e. NOT
# an LER row (no out_value_product0X / pler_value_product0X / ler_value_total filled)
all_na_across <- function(data, prefix) {
  cols <- names(data)[startsWith(names(data), prefix)]
  if (length(cols) == 0) return(rep(TRUE, nrow(data)))
  rowSums(!is.na(data[cols])) == 0
}

is_focal_row <- function(data) {
  data$out_subpillar == "Yield" &
    all_na_across(data, "out_value_product0") &
    all_na_across(data, "pler_value_product0") &
    is.na(data$ler_value_total)
}

fun_pair_yield_focal <- function(df) {
  
  spec     <- pairing_spec_cols %>% dplyr::filter(subpillar == "Yield", branch == "focal")
  extra    <- unlist(spec$extra_cols)
  id_cols  <- c(pairing_base_cols, extra)
  
  df$row_id <- ifelse(is_focal_row(df), build_row_id(df, id_cols), NA_character_)
  
  df.C <- df %>%
    dplyr::filter(grepl("C", practice_id)) %>%
    split_ct()
  
  df.C$out_comparison_id <- ifelse(
    is_focal_row(df.C),
    build_row_id(df.C, c("out_comparison_treatment", setdiff(id_cols, "practice_id"))),
    NA_character_
  )
  
  df.C %>%
    dplyr::filter(!is.na(row_id)) %>%
    dplyr::select(-row_id) %>%
    dplyr::left_join(
      df %>% dplyr::select(-dplyr::any_of(setdiff(id_cols, c(
        "practice_id",
        "country", "site_type","site_id","site_admin",
        "site_agg","site_latlong_type","site_latitude",
        "site_longitude","site_buffer", "site_key" ,
        "product",
        "out_subindicator_unit")))),
      by = c("out_comparison_id" = "row_id"),
      suffix = c(".C", ".T")
    ) %>%
    dplyr::rename_with(~ paste0("T_", sub("\\.T$", "", .)), dplyr::ends_with(".T")) %>%
    dplyr::rename_with(~ paste0("C_", sub("\\.C$", "", .)), dplyr::ends_with(".C")) %>%
    dplyr::filter(!is.na(T_practice_id)) %>%
    dplyr::mutate(out_comparison_id = paste0(C_practice_id, "-", out_comparison_id))
}

#==========================================================
#--- Reshape LER-eligible rows into one row per crop component ---
## Explodes the product0N / out_value_product0N / pler_value_product0N slot
## columns (up to 5 for product/out_value, up to 3 for pler_value — the
## template doesn't have pler_value_product04/05) into one row per
## populated slot. Each output row then looks exactly like a single-crop
## Yield row, so it can be matched with the same 1:1 mechanism as
## fun_pair_context()/fun_pair_yield_focal().
#==========================================================
explode_ler_components <- function(df) {
  
  ler_eligible <- df %>%
    dplyr::filter(out_subpillar == "Yield", !is_focal_row(df))
  
  slot_cols <- names(ler_eligible)
  
  exploded <- purrr::map_dfr(1:5, function(n) {
    suffix     <- sprintf("0%d", n)
    prod_col   <- paste0("product", suffix)
    val_col    <- paste0("out_value_product", suffix)
    var_col    <- paste0("out_var_value_product", suffix)
    ler_col    <- paste0("pler_value_product", suffix)
    lervar_col <- paste0("pler_var_value_product", suffix)
    
    out <- ler_eligible
    # cast to character regardless of whether the column exists — some
    # slot columns are read in as character (e.g. "Unspecified" text),
    # and missing slots default to NA; mixing character/double across
    # slots is what breaks bind_rows() below
    out$product      <- if (prod_col   %in% slot_cols) as.character(out[[prod_col]])   else NA_character_
    out$out_value     <- if (val_col    %in% slot_cols) as.character(out[[val_col]])    else NA_character_
    out$var_value     <- if (var_col    %in% slot_cols) as.character(out[[var_col]])    else NA_character_
    out$pler_value     <- if (ler_col    %in% slot_cols) as.character(out[[ler_col]])    else NA_character_
    out$pler_var_value <- if (lervar_col %in% slot_cols) as.character(out[[lervar_col]]) else NA_character_
    
    out %>% dplyr::select(-dplyr::any_of(c(
      paste0("product0", 1:5), paste0("out_value_product0", 1:5),
      paste0("out_var_value_product0", 1:5),
      paste0("pler_value_product0", 1:3), paste0("pler_var_value_product0", 1:3)
    )))
  }) %>%
    dplyr::filter(!(is.na(product) & is.na(out_value) & is.na(pler_value)))
  
  # now that every slot combined safely as character, convert the
  # numeric-ish ones back to numeric in one pass
  exploded %>%
    dplyr::mutate(dplyr::across(c(out_value, var_value, pler_value, pler_var_value), as.numeric))
}

#==========================================================
#--- Pairing partial LER function ---
## Used for out_subpillar == "Yield", the LER-eligible rows (excluded from
## fun_pair_yield_focal() by is_focal_row()). Runs the same 1:1 join as
## fun_pair_context()/fun_pair_yield_focal(), but on the exploded (one row per
## single crop) table — component_product is now part of the matching key,
## since each exploded row is single-crop.
#==========================================================
fun_pair_yield_partial_ler <- function(df) {
  
  spec  <- pairing_spec_cols %>% dplyr::filter(subpillar == "Yield", branch == "partial_ler")
  extra <- unlist(spec$extra_cols)
  
  exploded <- explode_ler_components(df)
  id_cols  <- c(pairing_base_cols, extra)   # matching key: context + crop identity
  
  exploded$row_id <- build_row_id(exploded, id_cols)
  
  df.C <- exploded %>%
    dplyr::filter(grepl("C", practice_id)) %>%
    split_ct()
  
  df.C$out_comparison_id <- build_row_id(
    df.C, c("out_comparison_treatment", setdiff(id_cols, "practice_id"))
  )
  
  result <-df.C %>%
    dplyr::filter(!is.na(row_id)) %>%
    dplyr::select(-row_id) %>%
    dplyr::left_join(
      # only pairing_base_cols is dropped from the Treatment side — "product"
      # is kept on both sides so both C_product and T_product survive
      exploded %>% dplyr::select(-dplyr::any_of(setdiff(pairing_base_cols, c("practice_id",
                                                                             "country")))),
      by = c("out_comparison_id" = "row_id"),
      suffix = c(".C", ".T")
    ) %>%
    dplyr::rename_with(~ paste0("T_", sub("\\.T$", "", .)), dplyr::ends_with(".T")) %>%
    dplyr::rename_with(~ paste0("C_", sub("\\.C$", "", .)), dplyr::ends_with(".C")) %>%
    dplyr::filter(!is.na(T_practice_id)) %>%
    dplyr::mutate(out_comparison_id = paste0(C_practice_id, "-", out_comparison_id))
  
  result$ler_comparison_id <- build_row_id(
    result, c("T_practice_id",setdiff(id_cols, c("practice_id", "product")))
  )
  
  result %>%
    dplyr::rename(
      pler_value = T_pler_value,
      pler_var_value = T_pler_var_value,
      ler_value_total = T_ler_value_total,
      ler_var_value_total = T_ler_var_value_total
    )
}


