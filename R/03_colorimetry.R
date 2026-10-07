# =============================================================================
# 03_colorimetry.R
# Gloger's Rule in Song Sparrow (Melospiza melodia)
# EEB 4100 — University of Connecticut, 2023
#
# PURPOSE: Extract HSL (Hue-Saturation-Lightness) colorimetric values from
#          standardised Song Sparrow photographs downloaded from eBird.
#          Lightness (L channel, 0–1 scale) serves as the quantitative
#          proxy for plumage darkness as predicted by Gloger's Rule.
#
# NOTES ON METHODOLOGY:
#   - 10 eBird photographs selected per region (CT and AZ), 2022–2023.
#   - Photos standardised to the breast/ventral plumage region by cropping
#     a consistent ROI (region of interest) in ImageJ before R analysis.
#   - HSL conversion: RGB → HSL via grDevices::rgb2hsv() and custom formula.
#   - Mean L per photo taken as the bird-level observation.
# =============================================================================

library(dplyr)
library(readr)
library(ggplot2)

# ---- Function: RGB to HSL conversion ----------------------------------------
# R's rgb2hsv() returns HSV; we convert HSV → HSL for consistency with CSS/
# perceptual lightness literature used in avian colorimetry studies.
#
hsv_to_hsl <- function(h, s, v) {
  # L = V * (1 - S/2)
  # S_hsl = if L in (0,1): (V - L) / min(L, 1-L) else 0
  L <- v * (1 - s / 2)
  S_hsl <- ifelse(
    L > 0 & L < 1,
    (v - L) / pmin(L, 1 - L),
    0
  )
  list(H = h, S = S_hsl, L = L)
}

# ---- Load pre-extracted lightness data --------------------------------------
# If working with raw images, replace this block with:
#   library(magick)
#   img   <- image_read("path/to/bird_photo.jpg")
#   px    <- as.integer(image_data(img, channels = "rgb"))
#   ...then apply hsv_to_hsl() per pixel and aggregate
lightness <- read_csv("data/processed/sparrow_lightness.csv")

# ---- Summary ----------------------------------------------------------------
summary_tbl <- lightness %>%
  group_by(region) %>%
  summarise(
    n        = n(),
    mean_L   = mean(HSL_lightness),
    sd_L     = sd(HSL_lightness),
    se_L     = sd_L / sqrt(n),
    ci95_lo  = mean_L - qt(0.975, n - 1) * se_L,
    ci95_hi  = mean_L + qt(0.975, n - 1) * se_L,
    .groups  = "drop"
  )
print(summary_tbl)

# ---- Export -----------------------------------------------------------------
write_csv(summary_tbl, "results/colorimetry_summary.csv")
message("Colorimetry summary saved to results/colorimetry_summary.csv")
