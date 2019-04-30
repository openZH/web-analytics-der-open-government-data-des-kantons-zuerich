library(ckanr)
library(tidyverse)
library(jsonlite)


ckanr_setup(url = "https://opendata.swiss/")


test <- package_search(fq = 'organization:statistisches-amt-kanton-zuerich', rows= 1000, as='table')

test_1 <- test$results


urls <- jsonlite::fromJSON("https://opendata.swiss/api/3/action/package_show?id=web-analytics-der-open-government-data-des-kantons-zuerich")
