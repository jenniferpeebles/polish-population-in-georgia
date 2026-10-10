# Audit structure, uncertainty, language components and geography.

source("scripts/00_config.R")
source("R/helpers.R")

datasets <- list(
  states = read_clean(paste0("data_clean/states_acs_", acs_year, ".csv")),
  msas = read_clean(paste0("data_clean/us_msas_acs_", acs_year, ".csv")),
  counties = read_clean(paste0("data_clean/georgia_counties_acs_", acs_year, ".csv")),
  places = read_clean(paste0("data_clean/georgia_places_acs_", acs_year, ".csv")),
  tracts = read_clean(paste0("data_clean/georgia_tracts_acs_", acs_year, ".csv")),
  pumas = read_clean(paste0("data_clean/georgia_pumas_acs_", acs_year, ".csv"))
)

# Check every measure in every geography.

qa_summary <- crossing(
  dataset = names(datasets),
  measure = primary_measures
) %>%
  pmap_dfr(function(dataset, measure) {
    data <- datasets[[dataset]]
    denominator <- unname(measure_denominators[measure])

    tibble(
      dataset = dataset,
      measure = measure,
      rows = nrow(data),
      duplicate_geoids = data %>%
        count(GEOID) %>%
        filter(n > 1) %>%
        nrow(),
      missing_estimates = sum(is.na(data[[measure]])),
      missing_moes = sum(is.na(data[[paste0(measure, "_moe")]])),
      impossible = sum(
        data[[measure]] < 0 |
          data[[measure]] > data[[denominator]] |
          data[[paste0(measure, "_moe")]] < 0,
        na.rm = TRUE
      ),
      moe_gt_estimate = sum(
        data[[paste0(measure, "_moe_gt_estimate")]] %in% TRUE
      ),
      high_cv = sum(
        data[[paste0(measure, "_high_cv")]] %in% TRUE
      ),
      reliability_eligible = sum(
        reliable_estimate(data, measure)
      )
    )
  })

qa_summary %>%
  write_csv("outputs/qa_summary.csv")

if (
  any(qa_summary$duplicate_geoids > 0) ||
    any(qa_summary$impossible > 0) ||
    nrow(datasets$states) != 51 ||
    nrow(datasets$counties) != 159
) {
  stop("The structural QA checks failed. Review outputs/qa_summary.csv.")
}

# The two English-ability components should equal the Polish-at-home total.

language_component_check <- datasets %>%
  imap_dfr(function(data, dataset_name) {
    data %>%
      transmute(
        dataset = dataset_name,
        GEOID,
        NAME,
        polish_at_home,
        component_sum = polish_english_very_well +
          polish_english_less_than_very_well,
        difference = component_sum - polish_at_home
      )
  })

language_component_check %>%
  write_csv("outputs/language_component_check.csv")

language_component_failures <- language_component_check %>%
  filter(!is.na(difference), difference != 0)

if (nrow(language_component_failures) > 0) {
  stop("The Polish-language components do not equal the published total.")
}

# County totals should equal the state total when no county estimate is missing.

georgia <- datasets$states %>%
  filter(GEOID == "13")

county_state_reconciliation <- primary_measures %>%
  map_dfr(function(measure) {
    county_values <- datasets$counties[[measure]]
    missing_counties <- sum(is.na(county_values))

    county_sum <- if_else(
      missing_counties == 0,
      sum(county_values),
      NA_real_
    )

    tibble(
      measure = measure,
      state_estimate = georgia[[measure]],
      county_sum = county_sum,
      difference = county_sum - state_estimate,
      missing_counties = missing_counties
    )
  })

county_state_reconciliation %>%
  write_csv("outputs/county_state_reconciliation.csv")

reconciliation_failures <- county_state_reconciliation %>%
  filter(!is.na(difference), difference != 0)

if (nrow(reconciliation_failures) > 0) {
  stop("At least one county sum does not equal the state estimate.")
}

# Confirm that spatial data are valid and stored in WGS84.

spatial_qa <- c(
  "states",
  "georgia_counties",
  "georgia_places",
  "georgia_tracts",
  "georgia_pumas"
) %>%
  map_dfr(function(dataset_name) {
    spatial_data <- readr::read_rds(
      paste0(
        "data_clean/",
        dataset_name,
        "_acs_",
        acs_year,
        "_sf.rds"
      )
    )

    tibble(
      dataset = str_remove(dataset_name, "^georgia_"),
      epsg = st_crs(spatial_data)$epsg,
      invalid = sum(!st_is_valid(spatial_data)),
      empty = sum(st_is_empty(spatial_data))
    )
  })

spatial_qa %>%
  write_csv("outputs/spatial_qa.csv")

if (any(spatial_qa$epsg != 4326) || any(spatial_qa$invalid > 0)) {
  stop("At least one spatial QA check failed.")
}

log_message(
  "Structural, language-component and geographic QA passed."
)