# =============================================================================
# run_all.R — Master script
# Run every step of the Gloger's Rule analysis in sequence.
# =============================================================================
# Usage: Rscript R/run_all.R
# Note: Step 1 requires internet access and ~200 MB disk for WorldClim rasters.
#       Steps 3–5 run on the pre-computed processed CSVs and work offline.
# =============================================================================

steps <- list(
  "01 — Data acquisition (WorldClim download)"  = "R/01_data_acquisition.R",
  "02 — Spatial analysis (raster extraction)"   = "R/02_spatial_analysis.R",
  "03 — Colorimetry (HSL summary)"              = "R/03_colorimetry.R",
  "04 — Statistical analysis (t-test)"          = "R/04_statistical_analysis.R",
  "05 — Visualization (ggplot2 + leaflet)"      = "R/05_visualization.R"
)

for (label in names(steps)) {
  script <- steps[[label]]
  message("\n", strrep("=", 60))
  message("STEP: ", label)
  message(strrep("=", 60))
  tryCatch(
    source(script, local = FALSE),
    error = function(e) {
      message("ERROR in ", script, ": ", conditionMessage(e))
      message("Continuing with remaining steps...")
    }
  )
}

message("\nAll steps complete. Results in results/")
