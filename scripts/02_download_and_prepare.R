# Download and prepare ACS estimates. The three measures overlap; never add them.
source("scripts/00_config.R"); source("R/helpers.R")
fetch_acs <- function(geography,state=NULL,geometry=FALSE) {
 args <- list(geography=geography,variables=acs_variables,year=acs_year,survey=acs_survey,
              geometry=geometry,output="tidy")
 if(!is.null(state)) args$state <- state
 path <- file.path("data_raw",paste0(gsub("[^a-z]","_",geography),"_",acs_year,".rds"))
 if(file.exists(path)&&!refresh_downloads) return(readRDS(path))
 x <- do.call(get_acs,args); saveRDS(x,path); writeLines(as.character(Sys.time()),paste0(path,".retrieved.txt")); x
}
state_raw <- fetch_acs("state",geometry=TRUE)
states <- state_raw %>% shape_acs() %>% filter(NAME!="Puerto Rico")
states_sf <- join_geometry(states,state_raw)
msa_raw <- fetch_acs("metropolitan statistical area/micropolitan statistical area")
msas <- msa_raw %>% shape_acs() %>% filter(str_detect(NAME,"Metro Area$"))
for(m in primary_measures) {
 msas[[paste0(m,"_count_rank")]] <- min_rank(desc(msas[[m]]))
 ok <- msas$total_population>=minimum_msa_population_for_concentration & reliable_estimate(msas,m)
 msas[[paste0(m,"_concentration_eligible")]] <- ok
 msas[[paste0(m,"_pct_rank_reliable")]] <- min_rank(desc(if_else(ok,msas[[paste0(m,"_pct")]],NA_real_)))
}
county_raw <- fetch_acs("county",analysis_state,TRUE)
counties <- county_raw %>% shape_acs() %>% mutate(county_name=str_remove(NAME," County, Georgia$"))
counties_sf <- join_geometry(counties,county_raw)
place_raw <- fetch_acs("place",analysis_state,TRUE)
places <- place_raw %>% shape_acs() %>% mutate(place_name=str_remove(NAME,", Georgia$"),
 place_type=case_when(str_detect(place_name,"consolidated government|unified government")~"consolidated government",
 str_detect(place_name," CDP$")~"census-designated place",TRUE~"incorporated place"))
places_sf <- join_geometry(places,place_raw)
tract_raw <- fetch_acs("tract",analysis_state,TRUE)
tracts <- shape_acs(tract_raw); tracts_sf <- join_geometry(tracts,tract_raw)
puma_raw <- fetch_acs("public use microdata area",analysis_state,TRUE)
pumas <- shape_acs(puma_raw); pumas_sf <- join_geometry(pumas,puma_raw)
sets <- list(states=states,msas=msas,counties=counties,places=places,tracts=tracts,pumas=pumas)
iwalk(sets,assert_unique_geoid)
write_csv_clean(states,paste0("states_acs_",acs_year,".csv"))
write_csv_clean(msas,paste0("us_msas_acs_",acs_year,".csv"))
write_csv_clean(counties,paste0("georgia_counties_acs_",acs_year,".csv"))
write_csv_clean(places,paste0("georgia_places_acs_",acs_year,".csv"))
write_csv_clean(tracts,paste0("georgia_tracts_acs_",acs_year,".csv"))
write_csv_clean(pumas,paste0("georgia_pumas_acs_",acs_year,".csv"))
saveRDS(states_sf,paste0("data_clean/states_acs_",acs_year,"_sf.rds"))
saveRDS(counties_sf,paste0("data_clean/georgia_counties_acs_",acs_year,"_sf.rds"))
saveRDS(places_sf,paste0("data_clean/georgia_places_acs_",acs_year,"_sf.rds"))
saveRDS(tracts_sf,paste0("data_clean/georgia_tracts_acs_",acs_year,"_sf.rds"))
saveRDS(pumas_sf,paste0("data_clean/georgia_pumas_acs_",acs_year,"_sf.rds"))
log_message("Prepared state, metro, county, place and tract data.")