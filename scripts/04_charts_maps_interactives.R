# Create separate review charts and maps for each Polish measure.

source("scripts/00_config.R")
source("R/helpers.R")

states <- read_clean(
  paste0("data_clean/states_acs_", acs_year, ".csv")
)

metros <- read_clean(
  paste0("data_clean/us_msas_acs_", acs_year, ".csv")
)

georgia <- states %>%
  filter(GEOID == "13")

measure_colors <- c(
  polish_ancestry = "#D4213D",
  poland_born = "#286DAD",
  polish_at_home = "#7857A3"
)

make_state_chart <- function(measure) {
  chart_data <- georgia %>%
    transmute(
      NAME,
      estimate = .data[[measure]],
      moe = .data[[paste0(measure, "_moe")]]
    )

  chart <- chart_data %>%
    ggplot(aes(x = NAME, y = estimate)) +
    geom_col(fill = unname(measure_colors[measure])) +
    geom_errorbar(
      aes(
        ymin = pmax(0, estimate - moe),
        ymax = estimate + moe
      ),
      width = 0.2
    ) +
    scale_y_continuous(labels = scales::comma) +
    labs(
      title = unname(measure_labels[measure]),
      subtitle = "Georgia estimate with 90% margin of error",
      x = NULL,
      y = "Estimated residents",
      caption = paste(
        "Source:",
        acs_product_label,
        unname(measure_variables[measure])
      )
    ) +
    peeblestoolbox::theme_peebles_chart(angle_x_labels = 0) +
    peeblestoolbox::add_peebles_watermark(watermark_label)

  print(chart)

  peeblestoolbox::save_peebles_plot(
    chart,
    paste0("georgia_", measure, ".png"),
    folder = "exports",
    width = 11,
    height = 5
  )

  top_metros <- metros %>%
    filter(!is.na(.data[[measure]])) %>%
    slice_max(
      order_by = .data[[measure]],
      n = 15,
      with_ties = FALSE
    )

  top_metros %>%
    write_csv(
      paste0("outputs/msa_", measure, "_ranking.csv")
    )

  chart
}

charts <- primary_measures %>%
  set_names() %>%
  map(make_state_chart)

chart_georgia_polish_ancestry <- charts$polish_ancestry
chart_georgia_poland_born <- charts$poland_born
chart_georgia_polish_at_home <- charts$polish_at_home

map_settings <- tribble(
  ~geography, ~population_floor,
  "counties", 0,
  "places", minimum_place_population,
  "tracts", minimum_tract_population,
  "pumas", 0
)

map_requests <- map_settings %>%
  mutate(
    measure = map(geography, ~ primary_measures)
  ) %>%
  unnest(measure)

make_map <- function(geography, population_floor, measure) {
  spatial_data <- readr::read_rds(
    paste0(
      "data_clean/georgia_",
      geography,
      "_acs_",
      acs_year,
      "_sf.rds"
    )
  )

  eligible_for_map <- reliable_estimate(spatial_data, measure) &
    spatial_data$total_population >= population_floor

  spatial_data <- spatial_data %>%
    mutate(
      eligible = eligible_for_map,
      percent_for_map = if_else(
        eligible,
        .data[[paste0(measure, "_pct")]],
        NA_real_
      )
    )

  exclusion_summary <- tibble(
    geography = geography,
    measure = measure,
    received = nrow(spatial_data),
    retained = sum(spatial_data$eligible),
    excluded = sum(!spatial_data$eligible),
    population_floor = population_floor,
    empty_geometry = sum(st_is_empty(spatial_data))
  )

  drawable_data <- spatial_data %>%
    filter(!st_is_empty(.))

  if (!any(drawable_data$eligible)) {
    log_message(
      "Skipping unavailable map: ",
      geography,
      " / ",
      measure
    )

    return(
      list(
        name = paste(geography, measure, sep = "_"),
        plot = NULL,
        exclusion = exclusion_summary
      )
    )
  }

  web_mercator_data <- drawable_data %>%
    st_transform(3857)

  map_plot <- web_mercator_data %>%
    ggplot() +
    geom_sf(
      aes(fill = percent_for_map),
      color = "white",
      linewidth = 0.1
    ) +
    scale_fill_viridis_c(
      name = "% of relevant\npopulation",
      na.value = "#dddddd"
    ) +
    labs(
      title = paste(
        unname(measure_labels[measure]),
        "by Georgia",
        geography
      ),
      subtitle = paste(
        "Gray means unavailable, below the population floor",
        "or too uncertain; it does not mean zero"
      ),
      caption = paste(
        "Source:",
        acs_product_label,
        unname(measure_variables[measure]),
        "| Web Mercator EPSG:3857"
      )
    ) +
    peeblestoolbox::theme_peebles_map() +
    peeblestoolbox::add_peebles_watermark(watermark_label)

  print(map_plot)

  peeblestoolbox::save_peebles_plot(
    map_plot,
    paste0(
      "georgia_",
      geography,
      "_",
      measure,
      "_map.png"
    ),
    folder = "exports",
    width = 12,
    height = 8,
    bg = "white"
  )

  peeblestoolbox::export_geojson(
    drawable_data,
    paste0(
      "polish_population_georgia_",
      geography,
      "_",
      measure
    ),
    folder = "exports/geojson",
    overwrite = TRUE
  )

  list(
    name = paste(geography, measure, sep = "_"),
    plot = map_plot,
    exclusion = exclusion_summary
  )
}

map_results <- map_requests %>%
  pmap(make_map)

maps <- map_results %>%
  set_names(map_chr(map_results, "name")) %>%
  map("plot") %>%
  compact()

map_georgia_counties_polish_ancestry <- maps$counties_polish_ancestry
map_georgia_counties_poland_born <- maps$counties_poland_born
map_georgia_places_polish_ancestry <- maps$places_polish_ancestry
map_georgia_tracts_polish_ancestry <- maps$tracts_polish_ancestry
map_georgia_pumas_polish_ancestry <- maps$pumas_polish_ancestry

map_results %>%
  map("exclusion") %>%
  list_rbind() %>%
  write_csv("outputs/map_exclusions.csv")

log_message(
  "Created ",
  length(charts),
  " named charts and ",
  length(maps),
  " named Web Mercator maps."
)