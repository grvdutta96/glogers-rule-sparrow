# =============================================================================
# 05_visualization.R
# Gloger's Rule in Song Sparrow (Melospiza melodia)
# EEB 4100 — University of Connecticut, 2023
#
# PURPOSE: Produce all figures:
#   Fig 1 — Boxplot of plumage lightness by region (ggplot2)
#   Fig 2 — Scatter: lightness vs annual precipitation
#   Fig 3 — Interactive leaflet map (WorldClim precip raster + obs points)
# =============================================================================

library(dplyr)
library(readr)
library(ggplot2)
library(leaflet)
library(htmlwidgets)

dir.create("results", showWarnings = FALSE)

# ---- Load data --------------------------------------------------------------
lightness <- read_csv("data/processed/sparrow_lightness.csv")
clim      <- read_csv("data/processed/climate_at_locations.csv")

lightness_clim <- lightness %>%
  left_join(clim, by = c("region", "state"))

# ============================================================
# FIGURE 1: Plumage lightness boxplot (CT vs AZ)
# ============================================================
# Replicate/refine the EEB 4100 primary figure
p1 <- ggplot(lightness, aes(x = region, y = HSL_lightness, fill = region)) +
  geom_boxplot(width = 0.5, outlier.shape = 21,
               outlier.fill = "white", outlier.size = 2) +
  geom_jitter(width = 0.08, size = 2, alpha = 0.7) +
  scale_fill_manual(
    values = c("Connecticut" = "#4575b4", "Arizona" = "#d73027"),
    guide  = "none"
  ) +
  labs(
    title    = "Song Sparrow Plumage Lightness — CT vs AZ",
    subtitle = "Testing Gloger's Rule: humid (CT) vs arid (AZ) populations",
    x        = "Region",
    y        = "HSL Lightness (0 = darkest, 1 = lightest)",
    caption  = paste0(
      "n = 10 per region (eBird photographs, 2022–2023)\n",
      "Welch's t = −3.761, df = 18.0, p = 0.0014"
    )
  ) +
  annotate("text", x = 1.5, y = 0.36,
           label = "p = 0.0014 *",
           size = 4, fontface = "bold", color = "black") +
  theme_bw(base_size = 13) +
  theme(plot.caption = element_text(size = 8, color = "grey40"))

ggsave("results/fig1_plumage_boxplot.png", p1,
       width = 6, height = 5, dpi = 150)
message("Fig 1 saved: results/fig1_plumage_boxplot.png")

# ============================================================
# FIGURE 2: Lightness vs Annual Precipitation scatter
# ============================================================
p2 <- ggplot(lightness_clim,
             aes(x = annual_precip_mm, y = HSL_lightness,
                 color = region, label = bird_id)) +
  geom_point(size = 3, alpha = 0.85) +
  geom_smooth(method = "lm", se = TRUE,
              color = "black", linetype = "dashed", linewidth = 0.8) +
  scale_color_manual(
    values = c("Connecticut" = "#4575b4", "Arizona" = "#d73027")
  ) +
  labs(
    title   = "Plumage Lightness vs Annual Precipitation",
    subtitle = "Each point = one Song Sparrow individual",
    x       = "Annual Precipitation (mm, WorldClim BIO12)",
    y       = "HSL Lightness",
    color   = "Region",
    caption = "WorldClim v2.1, 30-arc-second resolution"
  ) +
  theme_bw(base_size = 13)

ggsave("results/fig2_lightness_vs_precip.png", p2,
       width = 7, height = 5, dpi = 150)
message("Fig 2 saved: results/fig2_lightness_vs_precip.png")

# ============================================================
# FIGURE 3: Interactive Leaflet Map
# ============================================================
# Colour palette for precipitation raster (WorldClim BIO12)
# Note: if raster file present, load and add as tile layer.
# Here we draw circle markers for the two study region centroids,
# matching the RPubs map from the original project.
#   https://rpubs.com/SydMazz20/1180967

region_coords <- tibble(
  region = c("Connecticut", "Arizona"),
  lat    = c(41.6032, 34.0489),
  lon    = c(-72.6851, -111.0937),
  precip = c(1219.4, 330.2),
  mean_L = c(mean(lightness$HSL_lightness[lightness$state == "CT"]),
             mean(lightness$HSL_lightness[lightness$state == "AZ"]))
)

# Per-bird jittered positions for individual markers
set.seed(42)
bird_coords <- lightness %>%
  left_join(region_coords, by = "region") %>%
  mutate(
    lat_j = lat + rnorm(n(), 0, 0.4),
    lon_j = lon + rnorm(n(), 0, 0.4)
  )

pal <- colorNumeric("RdYlBu", domain = bird_coords$HSL_lightness, reverse = TRUE)

m <- leaflet(bird_coords) %>%
  addProviderTiles("Esri.WorldShadedRelief",
                   options = providerTileOptions(opacity = 0.6)) %>%
  addProviderTiles("Stadia.StamenTerrainLines",
                   options = providerTileOptions(opacity = 0.4)) %>%
  addCircleMarkers(
    lng    = ~lon_j, lat = ~lat_j,
    color  = ~pal(HSL_lightness),
    radius = 7,
    stroke = TRUE, weight = 1, opacity = 1,
    fillOpacity = 0.9,
    popup = ~paste0(
      "<b>", bird_id, "</b><br/>",
      "Region: ", region, "<br/>",
      "Lightness: ", round(HSL_lightness, 3), "<br/>",
      notes
    )
  ) %>%
  addLegend(
    pal      = pal,
    values   = ~HSL_lightness,
    title    = "HSL Lightness",
    position = "bottomright"
  ) %>%
  addScaleBar(position = "bottomleft") %>%
  setView(lng = -95, lat = 38, zoom = 4)

saveWidget(m, "results/fig3_leaflet_map.html", selfcontained = TRUE)
message("Fig 3 saved: results/fig3_leaflet_map.html")
message("All figures complete. Open results/ to review.")
