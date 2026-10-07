# =============================================================================
# 02_spatial_analysis.R
# Gloger's Rule in Song Sparrow (Melospiza melodia)
# EEB 4100 — University of Connecticut, 2023
#
# PURPOSE: Extract WorldClim climate variables at Song Sparrow observation
#          points; perform spatial join between occurrence data and rasters.
#          This is the core spatial data pipeline — analogous to extracting
#          environmental covariates at livestock production locations for
#          GxE (genotype-by-environment) interaction modelling.
# =============================================================================

library(terra)
library(sf)
library(dplyr)
library(readr)

# ---- Load data --------------------------------------------------------------
lightness <- read_csv("data/processed/sparrow_lightness.csv")
regions   <- read_csv("data/processed/study_regions.csv")

# Approximate per-bird coordinates by jittering region centroid
# (simulates real georeferenced eBird records)
set.seed(42)
lightness <- lightness %>%
  left_join(regions, by = c("state" = "state", "region" = "region")) %>%
  mutate(
    lat = lat + rnorm(n(), 0, 0.5),
    lon = lon + rnorm(n(), 0, 0.5)
  )

# ---- Convert to sf points ---------------------------------------------------
bird_sf <- st_as_sf(lightness,
                    coords = c("lon", "lat"),
                    crs    = 4326)        # WGS-84

# ---- Load WorldClim raster --------------------------------------------------
# If raw rasters are present (run 01_data_acquisition.R first), use them.
# Otherwise fall back to the pre-extracted processed CSV.
if (file.exists("data/raw/worldclim_bio_us.tif")) {
  wc_us <- rast("data/raw/worldclim_bio_us.tif")

  # ---- Extract climate at each observation point ----------------------------
  # terra::extract: spatial overlay of vector points on raster stack
  # This is the core GIS operation — same pattern used for:
  #   - overlaying livestock GPS collars on land-cover / NDVI rasters
  #   - extracting temperature/humidity at barn sensor locations
  #   - linking MODIS productivity indices to herd performance records
  clim_vals <- terra::extract(wc_us, vect(bird_sf), ID = FALSE)

  bird_clim <- bind_cols(lightness, clim_vals) %>%
    mutate(
      mean_temp_C  = mean_temp_C10 / 10,   # WorldClim stores °C × 10
      temp_range_C = temp_annual_range_C10 / 10
    ) %>%
    select(-mean_temp_C10, -temp_annual_range_C10)

  write_csv(bird_clim, "data/processed/birds_with_climate.csv")
  message("Climate extracted at ", nrow(bird_clim), " observation points.")

  # ---- Regional summary statistics ------------------------------------------
  # Mean climate per region (analogous to herd-environment summaries)
  region_summary <- bird_clim %>%
    group_by(region, state) %>%
    summarise(
      n_birds          = n(),
      mean_lightness   = mean(HSL_lightness),
      sd_lightness     = sd(HSL_lightness),
      mean_precip_mm   = mean(annual_precip_mm, na.rm = TRUE),
      mean_temp_C      = mean(mean_temp_C, na.rm = TRUE),
      mean_altitude_m  = mean(alt, na.rm = TRUE),
      .groups = "drop"
    )

  print(region_summary)
  write_csv(region_summary, "data/processed/region_summary.csv")

} else {
  message("WorldClim rasters not found. Using pre-computed data from:")
  message("  data/processed/climate_at_locations.csv")
  message("Run 01_data_acquisition.R to download rasters for full pipeline.")

  # Load pre-computed climate summaries for each region
  clim_summary <- read_csv("data/processed/climate_at_locations.csv")
  print(clim_summary)
}

# ---- Pearson correlation: lightness ~ precipitation -------------------------
# (across individual birds if climate extracted; across regions if using summary)
if (exists("bird_clim")) {
  cor_result <- cor.test(bird_clim$HSL_lightness,
                         bird_clim$annual_precip_mm,
                         method = "pearson")
  message(sprintf(
    "\nPearson r (lightness ~ annual precip): r = %.3f, p = %.4f",
    cor_result$estimate, cor_result$p.value
  ))
}

message("Done. Run 03_colorimetry.R or 04_statistical_analysis.R next.")
