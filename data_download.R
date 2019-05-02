library(ckanr)
library(tidyverse)
library(jsonlite)


ckanr_setup(url = "https://opendata.swiss/")


test <- package_search(fq = 'organization:statistisches-amt-kanton-zuerich', rows= 1000, as='table')

test_1 <- test$results


test_1_selected <- test_1 %>% select(id, groups)

test_1_list <- split(test_1_selected, seq(nrow(test_1_selected)))

extract_language <- function(x){
  
  
  
  languages <- x$groups[[1]]$display_name
  
  languages_1 <- languages %>% mutate(id = x$id) %>% select(id, de)
  
}


test_4 <-  map(test_1_list, function(x) extract_language(x))

test_5 <- do.call(rbind.data.frame, test_4)


