# Create separate review charts and maps for each measure.
source("scripts/00_config.R"); source("R/helpers.R")

states <- read_clean(paste0("data_clean/states_acs_",acs_year,".csv"))

msas <- read_clean(paste0("data_clean/us_msas_acs_",acs_year,".csv"))

ga <- filter(states,GEOID=="13")

colors <- c(polish_ancestry="#D4213D",poland_born="#286DAD",polish_at_home="#7857A3")

charts <- list()

for(m in primary_measures) {
 d <- ga %>% transmute(NAME,estimate=.data[[m]],moe=.data[[paste0(m,"_moe")]])
 chart <- ggplot(d,aes(NAME,estimate))+geom_col(fill=unname(colors[m]))+
  geom_errorbar(aes(ymin=pmax(0,estimate-moe),ymax=estimate+moe),width=.2)+
  scale_y_continuous(labels=scales::comma)+
  labs(title=unname(measure_labels[m]),subtitle="Georgia estimate with 90% margin of error",
   x=NULL,y="Estimated residents",caption=paste("Source:",acs_product_label,unname(measure_variables[m])))+
  peeblestoolbox::theme_peebles_chart(angle_x_labels=0)+peeblestoolbox::add_peebles_watermark(watermark_label)
 chart_name <- paste0("chart_georgia_",m)
 charts[[m]] <- chart
 assign(chart_name,chart,envir=environment())
 print(chart)
 peeblestoolbox::save_peebles_plot(chart,paste0("georgia_",m,".png"),folder="exports",width=11,height=5)
 top <- msas %>% filter(!is.na(.data[[m]])) %>% slice_max(.data[[m]],n=15,with_ties=FALSE)
 write_csv(top,paste0("outputs/msa_",m,"_ranking.csv"))
}

exclusions <- list()
maps <- list()

for(level in c("counties","places","tracts","pumas")) {
 base <- readRDS(paste0("data_clean/georgia_",level,"_acs_",acs_year,"_sf.rds"))
 floor <- switch(level,places=minimum_place_population,tracts=minimum_tract_population,0)
 for(m in primary_measures) {
  x <- base %>% mutate(eligible=reliable_estimate(.,m)&total_population>=floor,
   percent_for_map=if_else(eligible,.data[[paste0(m,"_pct")]],NA_real_))
  exclusions[[paste(level,m)]] <- tibble(geography=level,measure=m,received=nrow(x),
   retained=sum(x$eligible),excluded=sum(!x$eligible),population_floor=floor,empty_geometry=sum(st_is_empty(x)))
  x <- x %>% filter(!st_is_empty(.))
  if(!any(x$eligible)) { log_message("Skipping unavailable map: ",level," / ",m); next }
  static <- st_transform(x,3857)
  map_plot <- ggplot(static)+geom_sf(aes(fill=percent_for_map),color="white",linewidth=.1)+
   scale_fill_viridis_c(name="% of relevant\npopulation",na.value="#dddddd")+
   labs(title=paste(unname(measure_labels[m]),"by Georgia",level),
    subtitle="Gray means unavailable, below the population floor or too uncertain; it does not mean zero",
    caption=paste("Source:",acs_product_label,unname(measure_variables[m]),"| Web Mercator EPSG:3857"))+
   peeblestoolbox::theme_peebles_map()+peeblestoolbox::add_peebles_watermark(watermark_label)
  map_name <- paste0("map_georgia_",level,"_",m)
  maps[[paste(level,m,sep="_")]] <- map_plot
  assign(map_name,map_plot,envir=environment())
  print(map_plot)
  peeblestoolbox::save_peebles_plot(map_plot,paste0("georgia_",level,"_",m,"_map.png"),
   folder="exports",width=12,height=8,bg="white")
  peeblestoolbox::export_geojson(x,paste0("polish_population_georgia_",level,"_",m),
   folder="exports/geojson",overwrite=TRUE)
 }
}

write_csv(bind_rows(exclusions),"outputs/map_exclusions.csv")

log_message("Created ",length(charts)," named charts and ",length(maps)," named Web Mercator maps.")