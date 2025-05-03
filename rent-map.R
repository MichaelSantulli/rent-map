library(tidyverse)
library(tidycensus)
library(mapgl)
library(sf)

median_rent <- get_acs(
  geography = "tract",
  #variables = "DP04_0134",
  variables = "B25064_001",
  year = 2023,
  state = c(state.abb, "DC", "PR"),
  geometry = TRUE,
  resolution = "5m",
)

median_rent_county <- get_acs(
  geography = "county",
  variables = "B25064_001",
  year = 2023,
  state = c(state.abb, "DC", "PR"),
  geometry = TRUE,
  resolution = "5m",
)

us_income <- get_acs(
  geography = "tract",
  variables = "B19013_001",
  state = c(state.abb, "DC", "PR"),
  year = 2023,
  geometry = TRUE,
  resolution = "5m"
)


# Format the popups
tract_popup_content <- glue::glue(
  "<strong>{median_rent$NAME}</strong><br>",
  "Median Gross Rent: {scales::dollar_format()(median_rent$estimate)}"
)

median_rent$popup <- tract_popup_content

county_popup_content <- glue::glue(
  "<strong>{median_rent_county$NAME}</strong><br>",
  "Median Gross Rent: {scales::dollar_format()(median_rent_county$estimate)}"
)

median_rent_county$popup <- county_popup_content


rent_map <- maplibre(
  style = carto_style("positron"),
  center = c(-98.5795, 39.8283),
  zoom = 3
) |>
  set_projection("globe") |> 
  add_source( 
    id = "us-tracts",
    data = median_rent,
    tolerance = 0
  ) |> 
  add_fill_layer(
    id = "fill-layer",
    source = median_rent,
    fill_color = interpolate(
      column = "estimate",
      values = c(500, 1500, 2000, 2500, 3000),
      stops = c("#2b83ba", "#abdda4", "#ffffbf", "#fdae61", "#d7191c"),
      na_color = "lightgrey"
    ),
    fill_opacity = 0.7,
    min_zoom = 8,
    #tooltip = "estimate",
    hover_options = list(
      fill_color = "magenta",
      fill_opacity = 1
    ),
    popup = "popup"
  ) |> 
  add_fill_layer(
    id = "county-fill-layer",
    source = median_rent_county,
    fill_color = interpolate(
      column = "estimate",
      values = c(500, 1500, 2000, 2500, 3000),
      stops = c("#2b83ba", "#abdda4", "#ffffbf", "#fdae61", "#d7191c"),
      na_color = "lightgrey"
    ),
    fill_opacity = 0.7,
    max_zoom = 7.99,
    #tooltip = "estimate",
    hover_options = list(
      fill_color = "magenta",
      fill_opacity = 1
    ),
    popup = "popup"
  ) |>
  add_continuous_legend(
    "Median household income",
    values = c("$500", "$1.5k", "$2k", "2.5k", "$3k"),
    colors = c("#2b83ba", "#abdda4", "#ffffbf", "#fdae61", "#d7191c")
  )

htmlwidgets::saveWidget(rent_map, "index.html", selfcontained = FALSE)
