#==========================================================
# Function: Calculate Mean & Standard deviation (SD)
#==========================================================


#sort(unique(fomd10.clean$C_out_var_metric))
#[1] "CV (Co-efficient of Variation)"                          
#[2] "Grouped SD (Standard Deviation)"                         
#[3] "Grouped SE (Standard Error)"                             
#[4] "Grouped SED (Standard Error of Difference Between Means)"
#[5] "Grouped SEM (Standard Error of Mean)"   
#[6]"IQR (interquartile)"
#[7] "Mean Squared Error"                                      
#[8] "SD (Standard Deviation)"                                 
#[9] "SE (Standard Error)"                                     
#[10] "SEM (Standard Error of Mean)"                            
#[11] "Unspecified"



calculate_mean_sd <- function(data,
                              prefix_c = "C",
                              prefix_t = "T") {
  
# ---------------------------------------------------------------------------
# --- Helper functions to calculate "Mean" ---
# ---------------------------------------------------------------------------

#--- Median + IQR → Mean: Mean = (Q1 + Median + Q3) / 3 ----
# REFERENCE: Wan, et al. (2014). # https://doi.org/10.1186/1471-2288-14-135  (Scenario 2)
metrics.iqr_mean <- c("IQR (interquartile)")
  
iqr_mean <- function(q1, median, q3) {
    result <- (q1 + median + q3) / 3
    return(result)
  }
  
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

#---  MSE → SD (Hedges et al. 1999): SD = √MSE
# REFERENCE:

metrics.mse_sd     <- c("Mean Squared Error")

mse_sd <- function(var_value) {
  result <- sqrt(var_value)
  return(result)
}

#--- IQR → SD: SD = (Q3 - Q1) / (2 × Φ⁻¹((0.75n - 0.125)/(n + 0.25))) ----
# REFERENCE: Wan et al. (2014). https://doi.org/10.1186/1471-2288-14-135 (Scenario 2)
metrics.iqr_sd <- c("IQR (interquartile)")

iqr_sd <- function(q1, q3, sample_size) {
  result <- (q3 - q1) / (2 * qnorm((0.75 * sample_size - 0.125) / (sample_size + 0.25)))
  return(result)
}

#---  Unspecified → SD: SD = NA
metrics.na         <- c("Unspecified")

# ---------------------------------------------------------------------------
# --- Internal function to compute mean & SD for one prefix ---
# ---------------------------------------------------------------------------

compute <- function(data, prefix) {
  
  out_value_metric      <- paste0(prefix, "_out_value_metric")
  out_value       <- paste0(prefix, "_out_value")
  out_var_metric  <- paste0(prefix, "_out_var_metric")
  out_var_value   <- paste0(prefix, "_out_var_value")
  out_sample_size <- paste0(prefix, "_out_sample_size")
  out_mean        <- paste0(prefix, "_out_mean")
  out_sd          <- paste0(prefix, "_out_sd")
  out_var_value_l <- paste0(prefix, "_out_var_value_l")
  out_var_value_u <- paste0(prefix, "_out_var_value_u")
  
  
  # --- Convert to numeric before calculations ---
  data <- data %>%
    mutate(
      !!out_value       := as.numeric(.data[[out_value]]),
      !!out_var_value   := as.numeric(.data[[out_var_value]]),
      !!out_sample_size := as.numeric(.data[[out_sample_size]]),
      !!out_var_value_l := as.numeric(.data[[out_var_value_l]]),
      !!out_var_value_u := as.numeric(.data[[out_var_value_u]])
    )
  
  data <- data %>%
    mutate(
      
      # --- Mean ---
      !!out_mean := case_when(
        .data[[out_value_metric]] == "Mean" ~ .data[[out_value]],
        
        # Median + IQR → Mean
        # (per your mapping: Q3 = out_var_value_l, Q1 = out_var_value_u)
        .data[[out_value_metric]] == "Median" &
          .data[[out_var_metric]] %in% metrics.iqr_mean
        ~ iqr_mean(q1     = .data[[out_var_value_u]],
                   median = .data[[out_value]],
                   q3     = .data[[out_var_value_l]])
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
        
        # IQR → SD (per your mapping: Q3 = out_var_value_l, Q1 = out_var_value_u)
        .data[[out_var_metric]] %in% metrics.iqr_sd
        ~ iqr_sd(q1          = .data[[out_var_value_u]],
                 q3          = .data[[out_var_value_l]],
                 sample_size = .data[[out_sample_size]]),
        
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

# ---------------------------------------------------------------------------
# --- Replace mean == 0 with 0.0001 for Log Response Ratio ---
# ---------------------------------------------------------------------------
# To calculate LOG RESPONSE RATIO effect size -> zero values have to be
# replaced by 0.0001 (log(0) is undefined)
data <- data %>%
  mutate(
    T_out_mean = if_else(out_effect_size_type == "Log Response Ratio" & T_out_mean == 0, 0.0001, T_out_mean),
    C_out_mean = if_else(out_effect_size_type == "Log Response Ratio" & C_out_mean == 0, 0.0001, C_out_mean)
  )


return(data)

}