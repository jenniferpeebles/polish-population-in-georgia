# Verify the Census variables before downloading the actual estimates.

source("scripts/00_config.R")
source("R/helpers.R")

available_variables <- tidycensus::load_variables(
  year = acs_year,
  dataset = acs_survey,
  cache = TRUE
)

verified_variables <- available_variables %>%
  filter(name %in% acs_variables) %>%
  left_join(
    acs_variable_dictionary,
    by = c("name" = "variable")
  )

if (nrow(verified_variables) != length(acs_variables)) {
  stop("At least one configured ACS variable is missing.")
}

expected_labels <- tribble(
  ~variable, ~expected_text,
  "B01001_001", "Total:",
  "B16001_001", "Total:",
  "B04006_061", "Polish",
  "B05006_040", "Poland",
  "B16001_030", "Polish",
  "B16001_031", "Polish.*Very well",
  "B16001_032", "Polish.*less than.*very well"
)

expected_labels %>%
  pwalk(function(variable, expected_text) {
    observed_label <- verified_variables %>%
      filter(name == variable) %>%
      pull(label)

    label_is_correct <- length(observed_label) == 1 &&
      str_detect(observed_label, regex(expected_text, ignore_case = TRUE))

    if (!label_is_correct) {
      stop(
        "Unexpected label for ",
        variable,
        ": ",
        paste(observed_label, collapse = " | ")
      )
    }
  })

polish_variable_matches <- available_variables %>%
  filter(
    str_detect(name, "^B04006_|^B05006_|^B16001_"),
    str_detect(label, regex("Polish|Poland", ignore_case = TRUE))
  )

polish_variable_matches %>%
  write_csv("outputs/polish_variable_search.csv")

verified_variables %>%
  write_csv("outputs/variable_reconnaissance.csv")

acs_variable_dictionary %>%
  write_csv("outputs/data_dictionary.csv")

print(verified_variables)

log_message(
  "Verified all ",
  nrow(verified_variables),
  " configured ACS variables."
)