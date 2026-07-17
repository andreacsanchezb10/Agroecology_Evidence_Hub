#==========================================================
# Function: Calculate Mean & Standard deviation (SD)
#==========================================================

calculate_mean_sd <- function(data,
                              prefix_c = "C",
                              prefix_t = "T") {
  
# ---------------------------------------------------------------------------
# --- Helper functions to calculate "SD (Standard Deviation)" ---
# ---------------------------------------------------------------------------
#--- SD → SD: SD = SD ----
metrics.direct_sd  <- c("Grouped SD (Standard Deviation)",
                        "SD (Standard Deviation)")

#--- SE → SD: SD = SE × √n ----
# REFERENCE: https://www.cochrane.org/authors/handbooks-and-manuals/handbook/current/chapter-06#section-6-5-2-2

metrics.se_sd<- c("Grouped SE (Standard Error)",
                  "SE (Standard Error)",
                  "Grouped SEM (Standard Error of Mean)",
                  "SEM (Standard Error of Mean)")

se_sd <- function(var_value, sample_size) {
  result <- var_value * sqrt(sample_size)
  return(result)
}

#--- SED → SD (balanced groups approximation): SD = SED × √(n/2) ---
# REFERENCE: 

metrics.sed_sd<- c("Grouped SED (Standard Error of Difference Between Means)")

sed_sd <- function(var_value, sample_size) {
  result <- var_value * sqrt(sample_size / 2)
  return(result)
}

#---  CV → SD: SD = (CV% / 100) × mean ---
# REFERENCE: https://en.wikipedia.org/wiki/Coefficient_of_variation

metrics.cv_sd<- c("CV (Co-efficient of Variation)")

cv_sd <- function(var_value, out_mean) {
  result <- (var_value / 100) * out_mean
  return(result)
}

# MSE → SD (Hedges et al. 1999): SD = √MSE
# REFERENCE:

metrics.mse_sd     <- c("Mean Squared Error")

mse_sd <- function(var_value) {
  result <- sqrt(var_value)
  return(result)
}

# Unspecified → SD: SD = NA
metrics.na         <- c("Unspecified")

# ---------------------------------------------------------------------------
# --- Internal function to compute mean & SD for one prefix ---
# ---------------------------------------------------------------------------

compute <- function(data, prefix) {
  
  out_metric      <- paste0(prefix, "_out_metric")
  out_value       <- paste0(prefix, "_out_value")
  out_var_metric  <- paste0(prefix, "_out_var_metric")
  out_var_value   <- paste0(prefix, "_out_var_value")
  out_sample_size <- paste0(prefix, "_out_sample_size")
  out_mean        <- paste0(prefix, "_out_mean")
  out_sd          <- paste0(prefix, "_out_sd")
  
  
  # --- Convert to numeric before calculations ---
  data <- data %>%
    mutate(
      !!out_value       := as.numeric(.data[[out_value]]),
      !!out_var_value   := as.numeric(.data[[out_var_value]]),
      !!out_sample_size := as.numeric(.data[[out_sample_size]])
    )
  
  
  data <- data %>%
    mutate(
      
      # --- Mean ---
      !!out_mean := case_when(
        .data[[out_metric]] == "Mean" ~ .data[[out_value]]
      ),
      
      # --- SD ---
      !!out_sd := case_when(
        
        # Direct SD — no conversion needed
        .data[[out_var_metric]] %in% metrics.direct_sd
        ~ .data[[out_var_value]],
        
        # SE / SEM → SD: SD = SE × √n
        .data[[out_var_metric]] %in% metrics.se_sd
        ~ se_sd(var_value   = .data[[out_var_value]],
                sample_size = .data[[out_sample_size]]),
        
        # SED → SD: SD = SED × √(n/2)
        .data[[out_var_metric]] %in% metrics.sed_sd
        ~ sed_sd(var_value   = .data[[out_var_value]],
                 sample_size = .data[[out_sample_size]]),
        
        # CV → SD: SD = (CV% / 100) × mean
        .data[[out_var_metric]] %in% metrics.cv_sd
        ~ cv_sd(var_value = .data[[out_var_value]],
                out_mean  = .data[[out_mean]]),
        
        # MSE → SD: SD = √MSE
        .data[[out_var_metric]] %in% metrics.mse_sd
        ~ mse_sd(var_value = .data[[out_var_value]]),
        
        # Unresolvable — set to NA
        .data[[out_var_metric]] %in% metrics.na
        ~ NA_real_
        
      )
    )
  
  return(data)
}

# ---------------------------------------------------------------------------
# --- Apply for Control and Treatment ---
# ---------------------------------------------------------------------------

data <- compute(data, prefix_c)
data <- compute(data, prefix_t)

return(data)

}