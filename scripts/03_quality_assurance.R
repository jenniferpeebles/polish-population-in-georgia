# Audit structure, uncertainty, language components and geography.
source("scripts/00_config.R"); source("R/helpers.R")
datasets <- list(states=read_clean(paste0("data_clean/states_acs_",acs_year,".csv")),
 msas=read_clean(paste0("data_clean/us_msas_acs_",acs_year,".csv")),
 counties=read_clean(paste0("data_clean/georgia_counties_acs_",acs_year,".csv")),
 places=read_clean(paste0("data_clean/georgia_places_acs_",acs_year,".csv")),
 tracts=read_clean(paste0("data_clean/georgia_tracts_acs_",acs_year,".csv")),
 pumas=read_clean(paste0("data_clean/georgia_pumas_acs_",acs_year,".csv")))
qa <- crossing(dataset=names(datasets),measure=primary_measures) %>% pmap_dfr(function(dataset,measure) {
 x <- datasets[[dataset]]; d <- unname(measure_denominators[measure])
 tibble(dataset,measure,rows=nrow(x),duplicate_geoids=sum(duplicated(x$GEOID)),
  missing_estimates=sum(is.na(x[[measure]])),missing_moes=sum(is.na(x[[paste0(measure,"_moe")]])),
  impossible=sum(x[[measure]]<0|x[[measure]]>x[[d]]|x[[paste0(measure,"_moe")]]<0,na.rm=TRUE),
  moe_gt_estimate=sum(x[[paste0(measure,"_moe_gt_estimate")]]%in%TRUE),
  high_cv=sum(x[[paste0(measure,"_high_cv")]]%in%TRUE),
  reliability_eligible=sum(reliable_estimate(x,measure)))
})
write_csv(qa,"outputs/qa_summary.csv")
stopifnot(all(qa$duplicate_geoids==0),all(qa$impossible==0),nrow(datasets$states)==51,nrow(datasets$counties)==159)
language_check <- imap_dfr(datasets,function(x,level) x %>% transmute(dataset=level,GEOID,NAME,
 polish_at_home,component_sum=polish_english_very_well+polish_english_less_than_very_well,
 difference=component_sum-polish_at_home))
write_csv(language_check,"outputs/language_component_check.csv")
stopifnot(all(language_check$difference==0,na.rm=TRUE))
ga <- datasets$states %>% filter(GEOID=="13")
reconciliation <- map_dfr(primary_measures,function(m) {
 state_estimate <- ga[[m]]; missing_counties <- sum(is.na(datasets$counties[[m]]))
 county_sum <- if(missing_counties == 0) sum(datasets$counties[[m]]) else NA_real_
 tibble(measure=m,state_estimate,county_sum,difference=county_sum-state_estimate,missing_counties)
})
write_csv(reconciliation,"outputs/county_state_reconciliation.csv")
stopifnot(all(reconciliation$difference[!is.na(reconciliation$difference)]==0))
spatial_qa <- map_dfr(c("states","counties","places","tracts","pumas"),function(level) {
 prefix <- if(level=="states") "states" else paste0("georgia_",level)
 x <- readRDS(paste0("data_clean/",prefix,"_acs_",acs_year,"_sf.rds"))
 tibble(dataset=level,epsg=st_crs(x)$epsg,invalid=sum(!st_is_valid(x)),empty=sum(st_is_empty(x)))
})
write_csv(spatial_qa,"outputs/spatial_qa.csv")
stopifnot(all(spatial_qa$epsg==4326),all(spatial_qa$invalid==0))
log_message("Structural, component and reconciliation QA passed.")