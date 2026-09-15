# Generate reporter-facing statewide findings from current outputs.
source("scripts/00_config.R"); source("R/helpers.R")
states <- read_clean(paste0("data_clean/states_acs_",acs_year,".csv"))
qa <- read_csv("outputs/qa_summary.csv",show_col_types=FALSE)
ga <- filter(states,GEOID=="13"); stopifnot(nrow(ga)==1,all(qa$impossible==0))
fmt <- function(x) scales::comma(x,accuracy=1)
lines <- map_chr(primary_measures,function(m) {
 e<-ga[[m]]; z<-ga[[paste0(m,"_moe")]]; verdict<-if(reliable_estimate(ga,m)) "passes" else "fails"
 paste0("- **",unname(measure_labels[m]),": ",fmt(e),"** (90% MOE: +/-",fmt(z),
  "; interval: ",fmt(max(0,e-z)),"-",fmt(e+z),"). This ",verdict," the reliability screen.")
})
social <- paste0("October is Polish-American Heritage Month! The ",acs_product_label,
 " estimate ",fmt(ga$polish_ancestry)," Georgia residents reporting Polish ancestry, ",
 fmt(ga$poland_born)," foreign-born residents born in Poland, and ",fmt(ga$polish_at_home),
 " people age 5+ who speak Polish at home. These estimates overlap and should not be added together; see the repo for margins of error and methods.")
writeLines(social,"outputs/social_post_draft.txt")
brief <- c("# Reporter brief","",paste0("Source: **",acs_product_label,
 "**. These measures overlap and must not be added."),"","## Georgia statewide estimates","",lines,"",
 "## Language note","",paste0("The Polish-at-home total is ",fmt(ga$polish_at_home),
 ". Of that total, ",fmt(ga$polish_english_less_than_very_well),
 " are estimated to speak English less than very well. The pipeline uses the published total rather than adding it to its components."),"",
 "## Suggested social post (review before posting)","",social,"","## Do not overstate","",
 "Ancestry, birthplace and language are different concepts. Language covers people age 5+. Birthplace excludes U.S.-born descendants. Keep each 90% MOE with its estimate.")
writeLines(brief,"outputs/reporter_brief.md")
summary <- ga %>% mutate(acs_year=acs_year,collection_period=acs_product_label,generated=as.character(Sys.Date()))
write_csv(summary,"outputs/georgia_summary.csv")
writeLines(capture.output(sessionInfo()),"outputs/session_info.txt")
log_message("Reporter brief and Georgia summary generated.")