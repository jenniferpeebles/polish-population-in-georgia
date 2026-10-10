# Shared settings for the Polish population project.

acs_year <- 2024L
acs_survey <- "acs5"
acs_product_label <- paste0(acs_year - 4L, "-", acs_year, " ACS five-year estimates")

analysis_state <- "GA"

cv_review_threshold <- 30
minimum_place_population <- 1000
minimum_tract_population <- 500
minimum_msa_population_for_concentration <- 100000

watermark_label <- "NOT FOR PUBLICATION"
refresh_downloads <- FALSE

project_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)

if (!file.exists("polish_population_in_georgia.Rproj")) {
  stop("Open the Polish population R project and run from its root directory.")
}

project_directories <- c(
  "data_raw",
  "data_clean",
  "outputs",
  "exports/geojson",
  "docs",
  "logs",
  "assets"
)

purrr::walk(
  file.path(project_root, project_directories),
  dir.create,
  recursive = TRUE,
  showWarnings = FALSE
)

options(
  tigris_use_cache = TRUE,
  timeout = 300,
  scipen = 999
)

required_packages <- c(
  "tidyverse",
  "janitor",
  "tidycensus",
  "tigris",
  "sf",
  "peeblestoolbox",
  "jsonlite",
  "leaflet",
  "plotly",
  "htmlwidgets",
  "beepr"
)

missing_packages <- purrr::keep(required_packages, ~ !requireNamespace(.x, quietly = TRUE))

if (length(missing_packages) > 0) {
  stop("Install required packages: ", paste(missing_packages, collapse = ", "))
}

suppressPackageStartupMessages(
  purrr::walk(required_packages, library, character.only = TRUE)
)

if (!nzchar(Sys.getenv("CENSUS_API_KEY")) && nzchar(Sys.getenv("CENSUS_KEY"))) {
  Sys.setenv(CENSUS_API_KEY = Sys.getenv("CENSUS_KEY"))
}

if (!nzchar(Sys.getenv("CENSUS_API_KEY"))) {
  stop("Set CENSUS_API_KEY in your user-level .Renviron and restart R. Never commit an API key to your Git/GitHub or other version control system.")
}

acs_variables <- c(
  total_population = "B01001_001",
  population_age_5_plus = "B16001_001",
  polish_ancestry = "B04006_061",
  poland_born = "B05006_040",
  polish_at_home = "B16001_030",
  polish_english_very_well = "B16001_031",
  polish_english_less_than_very_well = "B16001_032"
)

primary_measures <- c(
  "polish_ancestry",
  "poland_born",
  "polish_at_home"
)

measure_labels <- c(
  polish_ancestry = "People reporting Polish ancestry",
  poland_born = "Foreign-born residents born in Poland",
  polish_at_home = "People age 5+ who speak Polish at home"
)

measure_denominators <- c(
  polish_ancestry = "total_population",
  poland_born = "total_population",
  polish_at_home = "population_age_5_plus"
)

measure_variables <- acs_variables[primary_measures]

acs_variable_dictionary <- tribble(
  ~machine_name, ~variable, ~table, ~human_label, ~universe,
  "total_population", "B01001_001", "B01001", "Total population", "Total population",
  "population_age_5_plus", "B16001_001", "B16001", "Population age 5 and older", "Population 5 years and over",
  "polish_ancestry", "B04006_061", "B04006", "People reporting Polish ancestry", "Total population",
  "poland_born", "B05006_040", "B05006", "Foreign-born residents born in Poland", "Foreign-born population excluding born at sea",
  "polish_at_home", "B16001_030", "B16001", "People who speak Polish at home", "Population 5 years and over",
  "polish_english_very_well", "B16001_031", "B16001", "Polish at home; speaks English very well", "Polish speakers age 5+",
  "polish_english_less_than_very_well", "B16001_032", "B16001", "Polish at home; speaks English less than very well", "Polish speakers age 5+"
)

message("ACS product: ", acs_product_label)