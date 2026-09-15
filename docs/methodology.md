# Methodology

This project uses the 2024 ACS five-year detailed tables and keeps three overlapping measures separate.

- B04006_061 reports Polish ancestry; its percentage denominator is total population.
- B05006_040 reports foreign-born residents born in Poland; its displayed population-share denominator is total population.
- B16001_030 reports Polish spoken at home among people age 5 and older; its denominator is the population age 5 and older.

Each estimate retains its published 90% margin of error. Percentage MOEs use the Census ratio approximation and its addition-formula fallback. A CV of 30% or more and an MOE larger than the estimate are review flags. They do not cause source rows to be deleted.

B16001_031 and B16001_032 are English-ability components of the Polish-at-home total. The pipeline verifies that their estimates sum to B16001_030 and uses the published total rather than reconstructing it.

The pipeline retrieves states and D.C., national metro areas, and Georgia counties, places and tracts through tidycensus. Static maps use Web Mercator (EPSG:3857); spatial data and GeoJSON use WGS84 (EPSG:4326). Country facts and the flag provide context only.
