# Polish people in Georgia

<img src="https://flagcdn.com/w320/pl.png" alt="Flag of Poland" width="320">

October is Polish-American Heritage Month, a cheerful excuse to learn more about Polish history, culture and our Georgia neighbors with ties to Poland.

This R project uses public U.S. Census Bureau data to examine three different ways Georgia residents may have a connection to Poland: reporting Polish ancestry, being born in Poland, or speaking Polish at home. These groups overlap, but they are not interchangeable and **must not be added together**.

## What the latest ACS estimates say about Georgia

The **2020-2024 ACS five-year estimates** provide three different statewide views of Georgia residents with ties to Poland:

- **104,214 people report Polish ancestry** (90 percent margin of error: +/-3,439; approximate interval: 100,775-107,653).
- **3,096 foreign-born Georgia residents were born in Poland** (90 percent margin of error: +/-592; approximate interval: 2,504-3,688).
- **3,361 Georgia residents age 5 and older speak Polish at home** (90 percent margin of error: +/-662; approximate interval: 2,699-4,023).

All three statewide estimates pass this project's reliability screen. They are survey estimates rather than exact counts, and they describe overlapping populations with different definitions. **Do not add them together.**

Of the estimated Polish speakers, **797** are estimated to speak English less than "very well." That estimate is part of the Polish-at-home total, not an additional population.

## What the project measures

| Measure | ACS variable | Universe |
|---|---|---|
| People reporting Polish ancestry | [B04006_061](https://api.census.gov/data/2024/acs/acs5/groups/B04006.html) | Total population |
| Foreign-born residents born in Poland | [B05006_040](https://api.census.gov/data/2024/acs/acs5/groups/B05006.html) | Foreign-born population |
| People who speak Polish at home | [B16001_030](https://api.census.gov/data/2024/acs/acs5/groups/B16001.html) | Population age 5 and older |

The language table also reports Polish speakers who speak English "very well" (B16001_031) and less than "very well" (B16001_032). Those are components of the published Polish-at-home total.

The Census Bureau restricts detailed [B16001](https://censusreporter.org/tables/B16001/) language results to certain larger geographies to protect data privacy. Polish-specific estimates are available for Georgia as a whole, but **not for Georgia counties, places or census tracts**. None of Georgia's 159 county values are available -- not an unusual outcome for a metric where we're talking about very very small percentages -- so there is no partial county sum or county-level lower bound to report. Table [C16001](https://censusreporter.org/tables/C16001/) is available for smaller geographies, but it combines Polish with other languages and cannot provide a Polish-specific count. [Census B16001 geographic note](https://data.census.gov/table/ACSDT5Y2024.B16001?d=ACS+5-Year+Estimates+Detailed+Tables&g=040XX00US13&t=Language+Spoken+at+Home)

## Run it yourself

1. Open **polish_population_in_georgia.Rproj** in RStudio.
2. Install the packages listed in **scripts/00_config.R**. Install `PeeblesToolbox` with `pak::pak("jenniferpeebles/peeblestoolbox@v0.3.0")`.
3. Get a free [Census API key](https://api.census.gov/data/key_signup.html). Put `CENSUS_API_KEY=your_key_here` in your user-level `.Renviron`, restart R, and never commit the key.
4. Run `source("run_all.R")` from the project root.
5. Review the reporter brief, Georgia summary and QA summary in **outputs** before using the findings.

`README.md` is the single source of truth for public documentation. The R pipeline does not overwrite it. After refreshing the data, compare the generated reporter brief with the figures here and update this file after editorial review.

## Project scripts

| Script | What it does |
|---|---|
| 00_config.R | Defines variables, universes, settings, packages and key checks |
| 01_variable_reconnaissance.R | Verifies each Census variable label |
| 02_download_and_prepare.R | Downloads state, metro, Georgia county, place and tract estimates |
| 03_quality_assurance.R | Checks coverage, uncertainty, language components and reconciliation |
| 04_charts_maps_interactives.R | Builds separate charts and Web Mercator maps for each measure |
| 05_country_facts.R | Retrieves a Poland profile and real Polish flag |
| 06_reporter_brief.R | Generates current findings, cautions and a draft social post |

## Please carry the caveats with the numbers

- ACS figures are survey estimates. Keep each 90 percent margin of error with its estimate.
- Polish ancestry may be reported alone or with another ancestry.
- The Poland-born measure excludes U.S.-born descendants and is not a citizenship count.
- Speaking Polish at home describes home-language use among people age 5 and older. It does not count everyone who knows Polish.
- Missing values remain missing. A zero estimate does not prove absence.
- Static maps use Web Mercator (EPSG:3857); GeoJSON uses WGS84 (EPSG:4326). Gray areas show areas where the numbers have been withheld, often due to privacy concerns, by the Census Bureau -- gray areas do not mean zero.
- Rankings are descriptive and do not establish statistically significant differences.

Read [the methodology](docs/methodology.md) and [validation notes](docs/validation.md) before reporting.

## Special thanks

This project uses the [tidyverse](https://tidyverse.tidyverse.org/) created by [Hadley Wickham](https://hadley.nz/) and contributors. It uses [tidycensus](https://walker-data.com/tidycensus/) and [tigris](https://walker-data.com/tigris/), both created by [Kyle Walker](https://walker-data.com/), to access Census data and TIGER/Line geography. Thank you to the people who wrote and maintain these and the project's other open-source packages.

## About this project

Built for Jennifer Peebles' public-data posts and adapted from her Uzbekistan and Iranian population-in-Georgia projects. Running the pipeline does not publish files or post to social media.

> A note from JP: I built this project with help from ChatGPT/Codex, which wrote much of the project code and generated the initial README from the code, outputs and my instructions and my earlier population projects. I have edited some of this text in my own voice, but I want to be transparent about the help I received. I would have used a lot more "y'all"'s.

[Jennifer Peebles](https://www.ajc.com/staff/jennifer-peebles/) / [Atlanta Journal-Constitution](https://www.ajc.com/)

The initial README was generated with help from ChatGPT/Codex and is maintained directly as the public documentation.
