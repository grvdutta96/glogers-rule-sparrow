# =============================================================================
# 01_data_acquisition.R
# Gloger's Rule in Song Sparrow (Melospiza melodia)
# EEB 4100 — University of Connecticut, 2023
# Authors: Sydney Mazzanti, Gaurav Dutta, Zhiyuan Su
#
# PURPOSE: Download WorldClim v2.1 climate rasters and obtain eBird
#          Song Sparrow occurrence records for Connecticut and Arizona.
#          Outputs are saved to data/raw/ (gitignored due to size).
# =============================================================================

# ---- Dependencies -----------------------------------------------------------
packages <- c("geodata", "terra", "sf", "dplyr", "readr")
new_pkgs  <- packages[!packages %in% installed.packages()[,"Package"]]
if (length(new_pkgs)) install.packages(new_pkgs)

library(geodata)   # WorldClim download (successor to raster::getData)
library(terra)     # SpatRaster operations (raster replacement)
library(sf)        # Simple Features for occurrence point handling
library(dplyr)
library(readr)

dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)
dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)

# =============================================================================
# SECTION 1: WorldClim v2.1 Bioclimatic Variables (30-arc-second resolution)
# =============================================================================
# Variables used (all 19 bioclim layers downloaded; we use BIO1, BIO12, BIO13,
# BIO14, BIO7):
#   BIO1  = Annual Mean Temperature (°C × 10)
#   BIO7  = Temperature Annual Range (BIO5 - BIO6)
#   BIO12 = Annual Precipitation (mm)
#   BIO13 = Precipitation of Wettest Month (mm)
#   BIO14 = Precipitation of Driest Month (mm)

message("Downloading WorldClim v2.1 bioclim rasters (30-arc-sec, ~90MB)...")
wc <- worldclim_global(
  var  = "bio",
  res  = 0.5,          # 30-arc-second resolution
  path = "data/raw/"
)
# wc is a SpatRaster with 19 layers; subset to those we need
wc_sub <- wc[[c(1, 7, 12, 13, 14)]]
names(wc_sub) <- c("mean_temp_C10", "temp_annual_range_C10",
                   "annual_precip_mm", "precip_wettest_mm", "precip_driest_mm")

# Crop to conterminous US bounding box to keep file sizes manageable
us_bbox <- ext(-125, -66, 24, 50)          # xmin, xmax, ymin, ymax
wc_us   <- crop(wc_sub, us_bbox)

# Save cropped rasters
terra::writeRaster(wc_us, "data/raw/worldclim_bio_us.tif",
                   overwrite = TRUE)
message("WorldClim US raster saved: data/raw/worldclim_bio_us.tif")

# =============================================================================
# SECTION 2: Song Sparrow Observation Locations (eBird / manual records)
# =============================================================================
# In the original course project we sampled 10 eBird photographs per region
# (Connecticut and Arizona) from 2022–2023 and recorded the geographic
# coordinates of the observation. These were stored manually.
#
# For reproducibility, observation centroids are provided in:
#   data/processed/sparrow_lightness.csv  — with lat/lon added below
#
# To re-query live eBird data:
#   library(auk)   # auk package wraps the eBird API
#   # requires free eBird API key: https://ebird.org/api/keygen
#   ebd <- auk_ebd("ebd_songsp_2022-2023.txt") %>%
#            auk_species("Song Sparrow") %>%
#            auk_state(c("US-CT", "US-AZ")) %>%
#            auk_filter(file = "data/raw/ebd_filtered.txt") %>%
#            read_ebd()

# Representative centroid coordinates for the two study regions
# (used for WorldClim extraction and leaflet maps)
study_regions <- tribble(
  ~region,       ~state, ~lat,     ~lon,
  "Connecticut", "CT",   41.6032, -72.6851,
  "Arizona",     "AZ",   34.0489, -111.0937
)

write_csv(study_regions, "data/processed/study_regions.csv")
message("Study region coordinates saved.")
message("Done. Run 02_spatial_analysis.R next.")
