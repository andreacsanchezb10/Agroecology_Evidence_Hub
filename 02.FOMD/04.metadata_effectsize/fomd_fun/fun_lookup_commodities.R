#===================================================
# Reclassify Crops as FAO.Group

local({
  
 
  source(file.path(path.metadata.effectsize, "/fomd_fun/fun_load_data_ontologies.R"),
         local = environment())


fomd01.crops.trees<-plants<-rbind(
(
  fomd01.product.new%>%
  
  distinct(Product.Simple,SPAM.Food.Group,FAO.Food.SubGroup,FAO.Food.Group)%>%
  rename("plants"="Product.Simple")%>%
  filter(!is.na(FAO.Food.SubGroup))%>%
    filter(!is.na(plants))
  ),
(fomd01.vars.crops%>%
  distinct(V.Product,SPAM.Food.Group,FAO.Food.SubGroup,FAO.Food.Group)%>%
  rename("plants"="V.Product")%>%
  filter(!is.na(FAO.Food.SubGroup))),
(fomd01.trees%>%select(tree.latin.name,Tree.Nfix,Tree.Legume)%>%
   rename("plants"="tree.latin.name",
          "FAO.Food.SubGroup"= "Tree.Legume",
          "FAO.Food.Group"="Tree.Nfix"
   )%>%
   mutate(FAO.Food.SubGroup=case_when( FAO.Food.SubGroup=="Yes"~"Legume Tree",TRUE~"No Legume Tree"),
          FAO.Food.Group=case_when(FAO.Food.Group=="Yes"~"No N Fix Tree",TRUE~"No N Fix Tree"),
          SPAM.Food.Group= "Trees")%>%
   distinct(plants,FAO.Food.SubGroup,FAO.Food.Group,SPAM.Food.Group)
 )
)%>%
  distinct(plants,SPAM.Food.Group,FAO.Food.SubGroup,FAO.Food.Group)%>%
  arrange(plants)



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


apply_lookup_commodity_group <- function(df, ref, key_col, value_col,
                                   src_col, new_col,
                                   sep = "[-/]") {
  lookup <- ref %>%
    transmute(
      .key   = str_squish(.data[[key_col]]),
      .value = str_squish(.data[[value_col]])
    ) %>%
    distinct() %>%
    deframe()
  
  df %>%
    mutate(
      !!new_col := map_chr(
        str_split(str_squish(.data[[src_col]]), sep),
        \(x) {
          tokens <- str_squish(x)
          out    <- unname(lookup[tokens])
          if (all(is.na(out))) return(NA_character_)
          paste(sort(unique(out[!is.na(out)])), collapse = "..")
        }
      )
    )
}


# ============================================================
# Get only the Commodities groups that are equal in C and T
# ============================================================
apply_CT_commodity_group_intersection <- function(df, col_C, col_T, new_col, sep = "\\.\\.") {
  df %>%
    mutate(
      !!new_col := map2_chr(
        .data[[col_C]],
        .data[[col_T]],
        \(c, t) {
          if (is.na(c) | is.na(t)) return(NA_character_)
          c_vals <- str_squish(str_split(c, sep)[[1]])
          t_vals <- str_squish(str_split(t, sep)[[1]])
          common <- sort(intersect(c_vals, t_vals))
          if (length(common) == 0) return(NA_character_)
          paste(common, collapse = "..")
        }
      )
    )
}

# ── Only these two names are pushed to the global environment ──────────────
assign("fomd01.crops.trees",              fomd01.crops.trees,              envir = .GlobalEnv)

assign("apply_lookup_commodity_group",        apply_lookup_commodity_group,        envir = .GlobalEnv)
assign("apply_CT_commodity_group_intersection", apply_CT_commodity_group_intersection, envir = .GlobalEnv)
})
