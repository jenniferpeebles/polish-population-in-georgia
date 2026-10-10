# Download and prepare ACS estimates.
# The ancestry, birthplace and language measures overlap. Never add them.

source("scripts/00_config.R")
source("R/helpers.R")

fetch_acs <- function(geography, state = NULL, geometry = FALSE) {
  cache_name <- geography %>%
    str_replace_all("[^a-z]", "_") %>%
    paste0("_", acs_year, ".rds")

  cache_path <- file.path("data_raw", cache_name)

  if (file.exists(cache_path) && !refresh_downloads) {
    return(readr::read_rds(cache_path))
  }

  census_request <- list(
    geography = geography,
    variables = acs_variables,
    year = acs_year,
    survey = acs_survey,
    geometry = geometry,
    output = "tidy"
  )

  if (!is.null(state)) {
    census_request$state <- state
  }

  downloaded_data <- rlang::exec(
    tidycensus::get_acs,
    !!!census_request
  )

  downloaded_data %>%
    readr::write_rds(cache_path)

  Sys.time() %>%
    as.character() %>%
    readr::write_lines(paste0(cache_path, ".retrieved.txt"))

  downloaded_data
}

# How does Georgia compare with other states?

state_raw <- fetch_acs(
  geography = "state",
  geometry = TRUE
)

states <- state_raw %>%
  shape_acs() %>%
  filter(NAME != "Puerto Rico")

states_sf <- join_geometry(states, state_raw)

# Which metropolitan areas have the largest estimates and shares?

metro_raw <- fetch_acs(
  geography = "metropolitan statistical area/micropolitan statistical area"
)

metros <- metro_raw %>%
  shape_acs() %>%
  filter(str_detect(NAME, "Metro Area$"))

metros <- primary_measures %>%
  reduce(
    function(data, measure) {
      concentration_is_eligible <- data$total_population >=
        minimum_msa_population_for_concentration &
        reliable_estimate(data, measure)

      data %>%
        mutate(
          "{measure}_count_rank" := min_rank(desc(.data[[measure]])),
          "{measure}_concentration_eligible" := concentration_is_eligible,
          "{measure}_pct_rank_reliable" := min_rank(
            desc(
              if_else(
                concentration_is_eligible,
                .data[[paste0(measure, "_pct")]],
                NA_real_
              )
            )
          )
        )
    },
    .init = metros
  )

# Where do the three populations live within Georgia?

county_raw <- fetch_acs(
  geography = "county",
  state = analysis_state,
  geometry = TRUE
)

counties <- county_raw %>%
  shape_acs() %>%
  mutate(
    county_name = str_remove(NAME, " County, Georgia$")
  )

counties_sf <- join_geometry(counties, county_raw)

place_raw <- fetch_acs(
  geography = "place",
  state = analysis_state,
  geometry = TRUE
)

places <- place_raw %>%
  shape_acs() %>%
  mutate(
    place_name = str_remove(NAME, ", Georgia$"),
    place_type = case_when(
      str_detect(place_name, "consolidated government|unified government") ~
        "consolidated government",
      str_detect(place_name, " CDP$") ~
        "census-designated place",
      TRUE ~
        "incorporated place"
    )
  )

places_sf <- join_geometry(places, place_raw)

tract_raw <- fetch_acs(
  geography = "tract",
  state = analysis_state,
  geometry = TRUE
)

tracts <- tract_raw %>%
  shape_acs()

tracts_sf <- join_geometry(tracts, tract_raw)

puma_raw <- fetch_acs(
  geography = "public use microdata area",
  state = analysis_state,
  geometry = TRUE
)

pumas <- puma_raw %>%
  shape_acs()

pumas_sf <- join_geometry(pumas, puma_raw)

# Confirm that each finished table has one row per geography.

datasets <- list(
  states = states,
  msas = metros,
  counties = counties,
  places = places,
  tracts = tracts,
  pumas = pumas
)

datasets %>%
  iwalk(assert_unique_geoid)

# Save clean tables.

states %>%
  write_csv_clean(paste0("states_acs_", acs_year, ".csv"))

metros %>%
  write_csv_clean(paste0("us_msas_acs_", acs_year, ".csv"))

counties %>%
  write_csv_clean(paste0("georgia_counties_acs_", acs_year, ".csv"))

places %>%
  write_csv_clean(paste0("georgia_places_acs_", acs_year, ".csv"))

tracts %>%
  write_csv_clean(paste0("georgia_tracts_acs_", acs_year, ".csv"))

pumas %>%
  write_csv_clean(paste0("georgia_pumas_acs_", acs_year, ".csv"))

# Save spatial tables for the mapping script.

list(
  states = states_sf,
  georgia_counties = counties_sf,
  georgia_places = places_sf,
  georgia_tracts = tracts_sf,
  georgia_pumas = pumas_sf
) %>%
  iwalk(function(data, filename) {
    data %>%
      readr::write_rds(
        paste0("data_clean/", filename, "_acs_", acs_year, "_sf.rds")
      )
  })

log_message(
  "Prepared state, metro, county, place, tract and PUMA data."
)