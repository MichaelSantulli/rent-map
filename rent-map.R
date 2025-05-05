library(tidyverse)
library(tidycensus)
library(tigris)
library(mapgl)
library(sf)

austin_counties <- c("Travis","Hays", "Williamson", "Bastrop", "Caldwell")
capcog_counties <- c("Bastrop", "Blanco", "Burnet", "Caldwell", "Lee", "Fayette", "Hays", "Llano", "Travis", "Williamson")

median_rent <- get_acs(
  geography = "tract",
  #variables = "DP04_0134",
  variables = "B25064_001",
  year = 2023,
  state = "TX",
  county = capcog_counties,
  geometry = TRUE,
  resolution = "5m",
)

median_rent_county <- get_acs(
  geography = "county",
  variables = "B25064_001",
  year = 2023,
  state = "TX",
  county = capcog_counties,
  geometry = TRUE,
  resolution = "5m",
)

austin <- places(state = "TX")%>%
  filter(str_detect(NAME, "Austin"))

austin_boundary <- st_cast(austin, "MULTILINESTRING")


# Format the popups
tract_popup_content <- glue::glue(
  "<strong>{median_rent$NAME}</strong><br>",
  "Median Gross Rent: {scales::dollar_format()(median_rent$estimate)}"
)

tract_hover_content <- glue::glue(
  "{scales::dollar_format()(median_rent$estimate)}"
)

median_rent$popup <- tract_popup_content
median_rent$hover <- tract_hover_content

county_popup_content <- glue::glue(
  "<strong>{median_rent_county$NAME}</strong><br>",
  "Median Gross Rent: {scales::dollar_format()(median_rent_county$estimate)}"
)

county_hover_content <- glue::glue(
  "{scales::dollar_format()(median_rent_county$estimate)}"
)

median_rent_county$popup <- county_popup_content
median_rent_county$hover <- county_hover_content


rent_map <- maplibre(
  style = carto_style("positron"),
  center = c(-97.72888, 30.27567),
  zoom = 7.5
) |>
  set_projection("globe") |> 
  add_source( 
    id = "us-tracts",
    data = median_rent,
    tolerance = 0
  ) |> 
  add_fill_layer(
    id = "Census Tracts",
    source = median_rent,
    fill_color = interpolate(
      column = "estimate",
      values = c(500, 1500, 2000, 2500, 3000),
      stops = c("#2b83ba", "#abdda4", "#ffffbf", "#fdae61", "#d7191c"),
      na_color = "lightgrey"
    ),
    fill_opacity = 0.7,
    min_zoom = 9,
    tooltip = "hover",
    hover_options = list(
      fill_color = "magenta",
      fill_opacity = 1
    ),
    popup = "popup"
  ) |> 
  add_fill_layer(
    id = "Counties",
    source = median_rent_county,
    fill_color = interpolate(
      column = "estimate",
      values = c(500, 1000, 1500, 2000, 2500),
      stops = c("#2b83ba", "#abdda4", "#ffffbf", "#fdae61", "#d7191c"),
      na_color = "lightgrey"
    ),
    fill_opacity = 0.7,
    max_zoom = 8.99,
    tooltip = "hover",
    hover_options = list(
      fill_color = "magenta",
      fill_opacity = 1
    ),
    popup = "popup"
  ) |>
  add_continuous_legend(
    "Median gross rent (2023)",
    values = c("$500", "$1k", "$1.5k", "2k", "$2.5k"),
    colors = c("#2b83ba", "#abdda4", "#ffffbf", "#fdae61", "#d7191c")
  ) |>
  add_line_layer(
    id = "Austin City Boundary",
    source = austin_boundary,
    line_color = "#2a2a2a",
    line_width = 2
  ) |>
  add_layers_control(
    position = "bottom-left",
    layers = NULL,
    collapsible = TRUE,
    use_icon = TRUE,
    background_color = NULL,
    active_color = NULL,
    hover_color = NULL,
    active_text_color = NULL,
    inactive_text_color = NULL
  )

htmlwidgets::saveWidget(rent_map, "index.html", selfcontained = FALSE)
