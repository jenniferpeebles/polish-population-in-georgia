# Generate reporter-facing statewide findings from current outputs.

source("scripts/00_config.R")
source("R/helpers.R")

states <- read_clean(
  paste0("data_clean/states_acs_", acs_year, ".csv")
)

qa_summary <- read_csv(
  "outputs/qa_summary.csv",
  show_col_types = FALSE
)

georgia <- states %>%
  filter(GEOID == "13")

if (nrow(georgia) != 1 || any(qa_summary$impossible > 0)) {
  stop("The reporter brief cannot run because a QA check failed.")
}

format_number <- function(number) {
  scales::comma(number, accuracy = 1)
}

measure_lines <- primary_measures %>%
  map_chr(function(measure) {
    estimate <- georgia[[measure]]
    margin_of_error <- georgia[[paste0(measure, "_moe")]]

    reliability_result <- if_else(
      reliable_estimate(georgia, measure),
      "passes",
      "fails"
    )

    paste0(
      "- **",
      unname(measure_labels[measure]),
      ": ",
      format_number(estimate),
      "** (90% MOE: +/-",
      format_number(margin_of_error),
      "; interval: ",
      format_number(max(0, estimate - margin_of_error)),
      "-",
      format_number(estimate + margin_of_error),
      "). This ",
      reliability_result,
      " the reliability screen."
    )
  })

social_post <- paste0(
  "October is Polish-American Heritage Month! The ",
  acs_product_label,
  " estimate ",
  format_number(georgia$polish_ancestry),
  " Georgia residents reporting Polish ancestry, ",
  format_number(georgia$poland_born),
  " foreign-born residents born in Poland, and ",
  format_number(georgia$polish_at_home),
  " people age 5+ who speak Polish at home. ",
  "These estimates overlap and should not be added together; ",
  "see the repo for margins of error and methods."
)

social_post %>%
  readr::write_lines("outputs/social_post_draft.txt")

reporter_brief <- c(
  "# Reporter brief",
  "",
  paste0(
    "Source: **",
    acs_product_label,
    "**. These measures overlap and must not be added."
  ),
  "",
  "## Georgia statewide estimates",
  "",
  measure_lines,
  "",
  "## Language note",
  "",
  paste0(
    "The Polish-at-home total is ",
    format_number(georgia$polish_at_home),
    ". Of that total, ",
    format_number(georgia$polish_english_less_than_very_well),
    " are estimated to speak English less than very well. ",
    "The pipeline uses the published total rather than adding it ",
    "to its components."
  ),
  "",
  "## Suggested social post (review before posting)",
  "",
  social_post,
  "",
  "## Do not overstate",
  "",
  paste(
    "Ancestry, birthplace and language are different concepts.",
    "Language covers people age 5+.",
    "Birthplace excludes U.S.-born descendants.",
    "Keep each 90% MOE with its estimate."
  )
)

reporter_brief %>%
  readr::write_lines("outputs/reporter_brief.md")

georgia_summary <- georgia %>%
  mutate(
    acs_year = acs_year,
    collection_period = acs_product_label,
    generated = as.character(Sys.Date())
  )

georgia_summary %>%
  write_csv("outputs/georgia_summary.csv")

capture.output(sessionInfo()) %>%
  readr::write_lines("outputs/session_info.txt")

log_message(
  "Reporter brief and Georgia summary generated."
)

beepr::beep(2)