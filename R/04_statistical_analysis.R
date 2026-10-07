# =============================================================================
# 04_statistical_analysis.R
# Gloger's Rule in Song Sparrow (Melospiza melodia)
# EEB 4100 — University of Connecticut, 2023
#
# PURPOSE: Hypothesis test for Gloger's Rule.
#   H0: No difference in plumage lightness between humid (CT) and arid (AZ)
#       Song Sparrow populations.
#   H1: AZ birds have significantly higher (lighter) plumage lightness than
#       CT birds, consistent with Gloger's Rule (darker pigmentation in more
#       humid environments).
#
# Test: Two-sample Welch's t-test (unequal variances assumed).
# =============================================================================

library(dplyr)
library(readr)

# ---- Load data --------------------------------------------------------------
lightness <- read_csv("data/processed/sparrow_lightness.csv")
clim      <- read_csv("data/processed/climate_at_locations.csv")

CT <- lightness %>% filter(state == "CT") %>% pull(HSL_lightness)
AZ <- lightness %>% filter(state == "AZ") %>% pull(HSL_lightness)

# ---- Welch two-sample t-test ------------------------------------------------
t_result <- t.test(CT, AZ,
                   alternative = "less",   # CT < AZ (CT darker)
                   var.equal   = FALSE)

cat("\n===== WELCH TWO-SAMPLE t-TEST: HSL Lightness CT vs AZ =====\n")
cat(sprintf("  CT  n = %d  mean = %.4f  sd = %.4f\n",
            length(CT), mean(CT), sd(CT)))
cat(sprintf("  AZ  n = %d  mean = %.4f  sd = %.4f\n",
            length(AZ), mean(AZ), sd(AZ)))
cat(sprintf("  t = %.4f, df = %.3f, p = %.6f\n",
            t_result$statistic, t_result$parameter, t_result$p.value))
cat(sprintf("  95%% CI for mean difference (CT - AZ): [%.4f, %.4f]\n",
            t_result$conf.int[1], t_result$conf.int[2]))
cat(sprintf("  Cohen's d = %.3f\n",
            (mean(CT) - mean(AZ)) / sqrt((sd(CT)^2 + sd(AZ)^2) / 2)))

# ---- Interpretation ---------------------------------------------------------
if (t_result$p.value < 0.05) {
  cat("\nCONCLUSION: Reject H0. CT birds are significantly darker than AZ birds,\n")
  cat("consistent with Gloger's Rule: higher precipitation → darker plumage.\n")
} else {
  cat("\nCONCLUSION: Fail to reject H0 at α = 0.05.\n")
}

# ---- Climate contrast (context for the spatial result) ----------------------
cat("\n===== CLIMATE CONTRAST =====\n")
print(as.data.frame(clim[, c("region","state","annual_precip_mm","mean_temp_C","altitude_m")]))

# ---- Save output ------------------------------------------------------------
sink("results/statistical_output.txt")
cat("===== WELCH TWO-SAMPLE t-TEST: HSL Lightness CT vs AZ =====\n")
cat(sprintf("CT  n=%d  mean=%.4f  sd=%.4f\n", length(CT), mean(CT), sd(CT)))
cat(sprintf("AZ  n=%d  mean=%.4f  sd=%.4f\n", length(AZ), mean(AZ), sd(AZ)))
cat(sprintf("t = %.4f, df = %.3f, p = %.6f\n",
            t_result$statistic, t_result$parameter, t_result$p.value))
cat(sprintf("Cohen's d = %.3f\n",
            (mean(CT) - mean(AZ)) / sqrt((sd(CT)^2 + sd(AZ)^2) / 2)))
cat("\nClimate contrast:\n")
print(as.data.frame(clim))
sink()
message("Results written to results/statistical_output.txt")
