# Run the complete reproducible analysis from the project root.

pipeline_scripts <- c(
  "01_variable_reconnaissance.R",
  "02_download_and_prepare.R",
  "03_quality_assurance.R",
  "04_charts_maps_interactives.R",
  "05_country_facts.R",
  "06_reporter_brief.R"
)

purrr::walk(pipeline_scripts, function(script) {
  message("RUNNING: ", script)

  source(
    file.path("scripts", script),
    local = new.env(parent = globalenv())
  )
})

message(
  "Complete. Review outputs/reporter_brief.md ",
  "and outputs/qa_summary.csv before publication."
)