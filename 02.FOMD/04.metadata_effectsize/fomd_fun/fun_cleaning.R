

## Function to replace paterns in multiple columns
apply_replace_in_cols <- function(df, cols, pattern, replacement, fixed = TRUE) {
  df[cols] <- lapply(df[cols], \(x) gsub(pattern, replacement, x, fixed = fixed))
  df
}
