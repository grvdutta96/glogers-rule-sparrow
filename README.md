# Spatial Ecology Analysis: Testing Gloger's Rule in Song Sparrow

**Course project — EEB 4100 (Ecology & Evolution), University of Connecticut, 2023**  
**Authors:** Sydney Mazzanti · Gaurav Dutta · Zhiyuan Su  
**Interactive map:** [RPubs — Climate Rasters + Observation Points](https://rpubs.com/SydMazz20/1180967)

---

## Overview

This project tests **Gloger's Rule** — the ecogeographic principle that animals in
humid, high-precipitation environments evolve darker pigmentation than conspecifics
in drier climates. We applied a **spatial data analysis pipeline** in R to quantify
plumage lightness in Song Sparrow (*Melospiza melodia*) populations from two
climatically distinct US regions:

| Region | Annual Precipitation | Mean Temp | Mean HSL Lightness |
|--------|---------------------|-----------|-------------------|
| **Connecticut** (humid, temperate) | 1,219 mm | 9.8 °C | **0.221** |
| **Arizona** (semi-arid) | 330 mm | 15.6 °C | **0.341** |

**Result:** CT birds are significantly darker (Welch's t = −3.76, df = 18.0, **p = 0.0014**),
supporting Gloger's Rule. Effect size Cohen's d ≈ 2.4 (large).

---

## Spatial Data Pipeline

The analysis uses the same workflow structure common in **environmental-genomics and
livestock spatial modelling** applications:

```
eBird occurrence records   →   geo-referenced points (sf)
        +
WorldClim v2.1 rasters     →   terra::extract() at each location
(BIO1, BIO7, BIO12–14)
        ↓
climate variables at        →   linear model / group comparison
each individual             →   leaflet map
```

### R Packages

| Purpose | Package | Analogous livestock application |
|---------|---------|--------------------------------|
| Raster I/O, crop, resample | `terra` | Extract temperature/NDVI at farm locations |
| Vector (points, polygons) | `sf` | Herd GPS tracks, grazing polygons |
| Climate data download | `geodata` | WorldClim for pasture productivity models |
| Interactive maps | `leaflet` | Barn-level dashboards, herd distribution maps |
| Data wrangling | `dplyr`, `readr` | Phenotypic data QC |
| Visualisation | `ggplot2` | Production trait summaries |

---

## Repository Structure

```
glogers_rule_sparrow/
├── R/
│   ├── 01_data_acquisition.R     # WorldClim v2.1 download via geodata pkg
│   ├── 02_spatial_analysis.R     # terra::extract() — climate at obs. points
│   ├── 03_colorimetry.R          # HSL lightness from eBird photographs
│   ├── 04_statistical_analysis.R # Welch's t-test, Cohen's d
│   ├── 05_visualization.R        # ggplot2 boxplot + scatter + leaflet map
│   └── run_all.R                 # Master script
├── data/
│   ├── raw/                      # WorldClim rasters (gitignored, ~90MB)
│   └── processed/
│       ├── sparrow_lightness.csv       # Bird-level HSL lightness (n = 20)
│       ├── climate_at_locations.csv    # WorldClim summaries per region
│       └── study_regions.csv           # Region centroids (lat/lon)
├── results/
│   ├── fig1_plumage_boxplot.png        # Main result figure
│   ├── fig2_lightness_vs_precip.png    # Lightness ~ precipitation scatter
│   ├── fig3_leaflet_map.html           # Interactive map
│   ├── colorimetry_summary.csv
│   └── statistical_output.txt
└── README.md
```

---

## How to Run

### Prerequisites
```r
install.packages(c("terra", "sf", "geodata", "leaflet",
                   "htmlwidgets", "dplyr", "readr", "ggplot2"))
```

### Step 1 — Download WorldClim rasters (requires internet, ~200 MB)
```bash
Rscript R/01_data_acquisition.R
```

### Step 2 — Run full pipeline
```bash
Rscript R/run_all.R
```

> **No internet?** Steps 2–5 fall back to the pre-computed CSVs in `data/processed/`
> and produce all figures without the raw rasters.

---

## Key Methods

### Plumage Colorimetry
- 10 eBird photographs per region (2022–2023), standardised to breast/ventral region
- HSL Lightness (L channel, 0 = black, 1 = white) extracted per image
- RGB → HSV via `grDevices::rgb2hsv()`, then HSV → HSL conversion

### Spatial Climate Extraction
- WorldClim v2.1 bioclim variables at 30-arc-second (~1 km) resolution
- `terra::extract()` overlays observation points on raster stack — the same
  operation used to extract NDVI, soil type, or temperature at livestock
  production locations for GxE environment characterisation

### Statistics
- **Welch's two-sample t-test** (unequal variances; CT vs AZ lightness)
- **Pearson correlation**: plumage lightness ~ annual precipitation
- **Effect size**: Cohen's d

---

## Results Summary

| Metric | Value |
|--------|-------|
| CT mean lightness ± SD | 0.221 ± 0.014 |
| AZ mean lightness ± SD | 0.341 ± 0.015 |
| Welch t-statistic | −3.761 |
| Degrees of freedom | 17.997 |
| **p-value** | **0.0014** |
| Cohen's d | ≈ 2.4 (large) |
| Annual precipitation CT vs AZ | 1,219 mm vs 330 mm |

**Interpretation:** Song Sparrows in humid Connecticut are significantly darker
than conspecifics in arid Arizona, consistent with Gloger's Rule. The 3.7× precipitation
difference between regions correlates with the observed lightness difference.

---

## Author

**Gaurav Dutta, DVM | Ph.D. Candidate, Computational Biology**  
University of Connecticut | [Google Scholar](https://scholar.google.com/citations?user=ljbOXB4AAAAJ) | [GitHub](https://github.com/grvdutta96)

*Co-authors: Sydney Mazzanti, Zhiyuan Su (Group 3, EEB 4100)*
