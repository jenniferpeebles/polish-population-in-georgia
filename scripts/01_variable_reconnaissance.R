# Verify Census variable identities before downloading observations.
source("scripts/00_config.R"); source("R/helpers.R")
available_variables <- load_variables(acs_year,acs_survey,cache=TRUE)
verified <- available_variables %>% filter(name%in%unname(acs_variables)) %>%
 left_join(acs_variable_dictionary,by=c("name"="variable"))
stopifnot(nrow(verified)==length(acs_variables))
patterns <- c(B01001_001="Total:",B16001_001="Total:",B04006_061="Polish",
 B05006_040="Poland",B16001_030="Polish",B16001_031="Polish.*Very well",
 B16001_032="Polish.*less than.*very well")
iwalk(patterns,function(pattern,variable) {
 observed <- verified$label[verified$name==variable]
 if(length(observed)!=1||!grepl(pattern,observed,ignore.case=TRUE))
  stop("Unexpected label for ",variable,": ",paste(observed,collapse=" | "))
})
matches <- available_variables %>% filter(grepl("^B04006_|^B05006_|^B16001_",name),
 grepl("Polish|Poland",label,ignore.case=TRUE))
write_csv(matches,"outputs/polish_variable_search.csv")
write_csv(verified,"outputs/variable_reconnaissance.csv")
write_csv(acs_variable_dictionary,"outputs/data_dictionary.csv")
print(verified); log_message("Verified all ",nrow(verified)," configured ACS variables.")