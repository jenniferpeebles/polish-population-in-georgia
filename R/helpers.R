# Shared helper functions used by the numbered scripts.

log_message <- function(...) {
  message_text <- paste0(
    format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    " | ",
    paste0(..., collapse = "")
  )

  message(message_text)

  readr::write_lines(
    message_text,
    file.path(project_root, "logs", "pipeline.log"),
    append = TRUE
  )
}

safe_divide <- function(numerator, denominator, multiplier = 1) {
  dplyr::if_else(
    is.na(numerator) | is.na(denominator) | denominator <= 0,
    NA_real_,
    numerator / denominator * multiplier
  )
}

ratio_moe_90 <- function(
  numerator,
  denominator,
  numerator_moe,
  denominator_moe,
  multiplier = 1
) {
  ratio <- numerator / denominator

  subtraction_formula <- numerator_moe^2 - ratio^2 * denominator_moe^2
  addition_formula <- numerator_moe^2 + ratio^2 * denominator_moe^2

  selected_formula <- dplyr::if_else(
    subtraction_formula >= 0,
    subtraction_formula,
    addition_formula
  )

  margin_of_error <- sqrt(selected_formula) / denominator * multiplier

  dplyr::if_else(
    is.na(numerator) | is.na(denominator) | denominator <= 0,
    NA_real_,
    margin_of_error
  )
}

add_reliability_fields <- function(data, measure) {
  estimate <- data[[measure]]
  margin_of_error <- data[[paste0(measure, "_moe")]]

  data %>%
    mutate(
      "{measure}_ci90_lower" := if_else(
        is.na(estimate) | is.na(margin_of_error),
        NA_real_,
        pmax(0, estimate - margin_of_error)
      ),
      "{measure}_ci90_upper" := if_else(
        is.na(estimate) | is.na(margin_of_error),
        NA_real_,
        estimate + margin_of_error
      ),
      "{measure}_cv" := if_else(
        is.na(estimate) | estimate <= 0 | is.na(margin_of_error),
        NA_real_,
        (margin_of_error / 1.645) / estimate * 100
      ),
      "{measure}_moe_gt_estimate" := if_else(
        is.na(estimate) | is.na(margin_of_error),
        NA,
        margin_of_error > estimate
      ),
      "{measure}_high_cv" := if_else(
        is.na(.data[[paste0(measure, "_cv")]]),
        NA,
        .data[[paste0(measure, "_cv")]] >= cv_review_threshold
      )
    )
}

shape_acs <- function(raw_data) {
  duplicate_keys <- raw_data %>%
    st_drop_geometry() %>%
    count(GEOID, variable) %>%
    filter(n > 1)

  if (nrow(duplicate_keys) > 0) {
    stop("The downloaded data contain duplicate geography-variable pairs.")
  }

  wide_data <- raw_data %>%
    st_drop_geometry() %>%
    select(GEOID, NAME, variable, estimate, moe) %>%
    pivot_wider(
      names_from = variable,
      values_from = c(estimate, moe),
      names_glue = "{.value}_{variable}"
    ) %>%
    rename_with(~ str_remove(.x, "^estimate_"), starts_with("estimate_")) %>%
    rename_with(
      ~ str_replace(.x, "^moe_(.*)$", "\\1_moe"),
      starts_with("moe_")
    )

  data_with_percentages <- purrr::reduce(
    primary_measures,
    function(data, measure) {
      denominator <- unname(measure_denominators[measure])

      data %>%
        mutate(
          "{measure}_pct" := safe_divide(
            .data[[measure]],
            .data[[denominator]],
            100
          ),
          "{measure}_pct_moe" := ratio_moe_90(
            .data[[measure]],
            .data[[denominator]],
            .data[[paste0(measure, "_moe")]],
            .data[[paste0(denominator, "_moe")]],
            100
          )
        ) %>%
        add_reliability_fields(measure)
    },
    .init = wide_data
  )

  data_with_percentages %>%
    mutate(
      polish_english_less_than_very_well_pct = safe_divide(
        polish_english_less_than_very_well,
        polish_at_home,
        100
      )
    )
}

reliable_estimate <- function(data, measure) {
  !is.na(data[[measure]]) &
    data[[paste0(measure, "_high_cv")]] %in% FALSE &
    data[[paste0(measure, "_moe_gt_estimate")]] %in% FALSE
}

read_clean <- function(path) {
  readr::read_csv(
    path,
    show_col_types = FALSE,
    col_types = cols(GEOID = col_character())
  )
}

join_geometry <- function(data, raw_spatial_data) {
  geography_shapes <- raw_spatial_data %>%
    filter(variable == names(acs_variables)[1]) %>%
    select(GEOID, geometry) %>%
    distinct(GEOID, .keep_all = TRUE)

  data %>%
    left_join(geography_shapes, by = "GEOID") %>%
    st_as_sf() %>%
    st_transform(4326)
}

assert_unique_geoid <- function(data, label) {
  duplicate_count <- data %>%
    count(GEOID) %>%
    filter(n > 1) %>%
    nrow()

  if (duplicate_count > 0) {
    stop(label, " contains duplicate GEOIDs.")
  }

  invisible(TRUE)
}

write_csv_clean <- function(data, filename) {
  data %>%
    st_drop_geometry() %>%
    write_csv(
      file.path(project_root, "data_clean", filename),
      na = ""
    )
}