# Retrieve Poland context and a real flag. These do not supply Census estimates.
source("scripts/00_config.R"); source("R/helpers.R")
country_url <- "https://api.worldbank.org/v2/country/PL?format=json"
country_path <- "data_raw/poland_world_bank.json"
tryCatch({
 if(!file.exists(country_path)||refresh_downloads) {
  response <- jsonlite::fromJSON(country_url)
  stopifnot(response[[2]]$iso2Code=="PL",response[[2]]$name=="Poland")
  jsonlite::write_json(response,country_path,pretty=TRUE,auto_unbox=TRUE)
  writeLines(as.character(Sys.Date()),paste0(country_path,".retrieved.txt"))
 }
 profile <- jsonlite::fromJSON(country_path)[[2]]
 facts <- tibble(country=profile$name,capital=profile$capitalCity,
  capital_longitude=as.numeric(profile$longitude),capital_latitude=as.numeric(profile$latitude),
  source=country_url,retrieved=readLines(paste0(country_path,".retrieved.txt")))
 write_csv(facts,"outputs/country_facts.csv")
},error=function(e) warning("Optional country profile unavailable: ",conditionMessage(e)))
flag_url <- "https://flagcdn.com/w320/pl.png"
tryCatch({
 if(!file.exists("assets/poland_flag.png")||refresh_downloads) {
  download.file(flag_url,"assets/poland_flag.png",mode="wb",quiet=TRUE)
  writeLines(c(paste("Source:",flag_url),paste("Retrieved:",Sys.Date())),"assets/flag_source.txt")
 }
},error=function(e) warning("Optional flag download failed: ",conditionMessage(e)))