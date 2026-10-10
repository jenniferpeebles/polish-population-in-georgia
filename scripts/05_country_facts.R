# Retrieve Poland context and a real flag.
# These sources do not supply any Census population estimate.

source("scripts/00_config.R")
source("R/helpers.R")

country_url <- "https://api.worldbank.org/v2/country/PL?format=json"
country_path <- "data_raw/poland_world_bank.json"

tryCatch(
  {
    if (!file.exists(country_path) || refresh_downloads) {
      country_response <- jsonlite::fromJSON(country_url)

      country_is_correct <- country_response[[2]]$iso2Code == "PL" &&
        country_response[[2]]$name == "Poland"

      if (!country_is_correct) {
        stop("The World Bank response was not for Poland.")
      }

      country_response %>%
        jsonlite::write_json(
          country_path,
          pretty = TRUE,
          auto_unbox = TRUE
        )

      Sys.Date() %>%
        as.character() %>%
        readr::write_lines(
          paste0(country_path, ".retrieved.txt")
        )
    }

    country_profile <- country_path %>%
      jsonlite::fromJSON() %>%
      pluck(2)

    country_facts <- tibble(
      country = country_profile$name,
      capital = country_profile$capitalCity,
      capital_longitude = as.numeric(country_profile$longitude),
      capital_latitude = as.numeric(country_profile$latitude),
      source = country_url,
      retrieved = readr::read_lines(
        paste0(country_path, ".retrieved.txt")
      )
    )

    country_facts %>%
      write_csv("outputs/country_facts.csv")
  },
  error = function(error) {
    warning(
      "Optional country profile unavailable: ",
      conditionMessage(error)
    )
  }
)

flag_url <- "https://flagcdn.com/w320/pl.png"
flag_path <- "assets/poland_flag.png"

tryCatch(
  {
    if (!file.exists(flag_path) || refresh_downloads) {
      download.file(
        flag_url,
        flag_path,
        mode = "wb",
        quiet = TRUE
      )

      c(
        paste("Source:", flag_url),
        paste("Retrieved:", Sys.Date())
      ) %>%
        readr::write_lines("assets/flag_source.txt")
    }
  },
  error = function(error) {
    warning(
      "Optional flag download failed: ",
      conditionMessage(error)
    )
  }
)