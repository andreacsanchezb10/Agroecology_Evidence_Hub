library(metafor)
library(rlang)

# Shared logic lives here
calc_effectsize <- function(data, m1i, m2i, sd1i, sd2i, n1i, n2i,
                            measure, var_names, digits = 4) {
  m1i  <- eval_tidy(enquo(m1i), data)
  m2i  <- eval_tidy(enquo(m2i), data)
  sd1i <- eval_tidy(enquo(sd1i), data)
  sd2i <- eval_tidy(enquo(sd2i), data)
  n1i  <- eval_tidy(enquo(n1i), data)
  n2i  <- eval_tidy(enquo(n2i), data)
  
  escalc(measure = measure,
         m1i = m1i, m2i = m2i,
         sd1i = sd1i, sd2i = sd2i,
         n1i = n1i, n2i = n2i,
         data = data,
         var.names = var_names,
         vtype = "LS",
         digits = digits)
}

##########   LOG RESPONSE RATIO
calc_lnRR_effectsize <- function(data, m1i, m2i, sd1i, sd2i, n1i, n2i,
                                 var_names = c("lnRR", "lnRR_var"), digits = 4) {
  calc_effectsize(data, {{ m1i }}, {{ m2i }}, {{ sd1i }}, {{ sd2i }}, {{ n1i }}, {{ n2i }},
                  measure = "ROM", var_names = var_names, digits = digits)
}

##########   STANDARDIZED MEAN DIFFERENCE
calc_SMD_effectsize <- function(data, m1i, m2i, sd1i, sd2i, n1i, n2i,
                                var_names = c("SMD", "SMD_var"), digits = 4) {
  calc_effectsize(data, {{ m1i }}, {{ m2i }}, {{ sd1i }}, {{ sd2i }}, {{ n1i }}, {{ n2i }},
                  measure = "SMD", var_names = var_names, digits = digits)
}
