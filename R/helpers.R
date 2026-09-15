log_message <- function(...) {
 x <- paste0(format(Sys.time(),"%Y-%m-%d %H:%M:%S")," | ",paste0(...,collapse="")); message(x)
 cat(x,"\n",file=file.path(project_root,"logs","pipeline.log"),append=TRUE)
}
safe_divide <- function(n,d,m=1) if_else(is.na(n)|is.na(d)|d<=0,NA_real_,n/d*m)
ratio_moe_90 <- function(n,d,nm,dm,m=1) {
 r <- n/d; a <- nm^2-r^2*dm^2; z <- sqrt(ifelse(a>=0,a,nm^2+r^2*dm^2))/d*m
 z[is.na(n)|is.na(d)|d<=0] <- NA_real_; z
}
add_reliability_fields <- function(x,m) {
 e <- x[[m]]; z <- x[[paste0(m,"_moe")]]
 x[[paste0(m,"_ci90_lower")]] <- ifelse(is.na(e)|is.na(z),NA_real_,pmax(0,e-z))
 x[[paste0(m,"_ci90_upper")]] <- ifelse(is.na(e)|is.na(z),NA_real_,e+z)
 x[[paste0(m,"_cv")]] <- ifelse(is.na(e)|e<=0|is.na(z),NA_real_,(z/1.645)/e*100)
 x[[paste0(m,"_moe_gt_estimate")]] <- ifelse(is.na(e)|is.na(z),NA,z>e)
 x[[paste0(m,"_high_cv")]] <- ifelse(is.na(x[[paste0(m,"_cv")]]),NA,x[[paste0(m,"_cv")]]>=cv_review_threshold)
 x
}
shape_acs <- function(raw) {
 a <- st_drop_geometry(raw)
 if(anyDuplicated(a[c("GEOID","variable")])) stop("Duplicate geography-variable keys.")
 w <- a %>% select(GEOID,NAME,variable,estimate,moe) %>% pivot_wider(names_from=variable,values_from=c(estimate,moe))
 for(v in names(acs_variables)) {
  names(w)[names(w)==paste0("estimate_",v)] <- v
  names(w)[names(w)==paste0("moe_",v)] <- paste0(v,"_moe")
 }
 for(m in primary_measures) {
  d <- unname(measure_denominators[m])
  w[[paste0(m,"_pct")]] <- safe_divide(w[[m]],w[[d]],100)
  w[[paste0(m,"_pct_moe")]] <- ratio_moe_90(w[[m]],w[[d]],w[[paste0(m,"_moe")]],w[[paste0(d,"_moe")]],100)
  w <- add_reliability_fields(w,m)
 }
 w$polish_english_less_than_very_well_pct <- safe_divide(w$polish_english_less_than_very_well,w$polish_at_home,100)
 w
}
reliable_estimate <- function(x,m) !is.na(x[[m]]) & x[[paste0(m,"_high_cv")]]%in%FALSE & x[[paste0(m,"_moe_gt_estimate")]]%in%FALSE
read_clean <- function(path) read_csv(path,show_col_types=FALSE,col_types=cols(GEOID=col_character()))
join_geometry <- function(a,raw) {
 g <- raw %>% filter(variable==names(acs_variables)[1]) %>% select(GEOID,geometry) %>% distinct(GEOID,.keep_all=TRUE)
 a %>% left_join(g,by="GEOID") %>% st_as_sf() %>% st_transform(4326)
}
assert_unique_geoid <- function(x,label) {if(anyDuplicated(x$GEOID)) stop(label," has duplicate GEOIDs."); invisible(TRUE)}
write_csv_clean <- function(x,name) x %>% st_drop_geometry() %>% write_csv(file.path(project_root,"data_clean",name),na="")
save_interactive <- function(x,name) htmlwidgets::saveWidget(x,file.path(project_root,"exports",name),
 selfcontained=requireNamespace("rmarkdown",quietly=TRUE)&&rmarkdown::pandoc_available())