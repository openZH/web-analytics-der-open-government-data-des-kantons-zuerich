library(ckanr)
library(tidyverse)



# matomo token needed to query the API
token <- "your token"


month <- as.Date(paste0(format(as.Date(Sys.Date()), "%Y-%m"),"-01"))-1


getOrganizationsZH <- function(token){
  
  data_organization <- read.csv(paste0("https://piwik.opendata.swiss/index.php?date=2019-04-30&expanded=1&filter_limit=-1&
                                     format=CSV&idDimension=1&idSite=1&language=en&method=CustomDimensions.getCustomDimension&
                                       module=API&period=month&reportUniqueId=CustomDimensions_getCustomDimension_idDimension--1&
                                       token_auth=",token,"&translateColumnNames=1"),
                                skipNul = TRUE,encoding = "UTF-8", check.names = FALSE )
  
  
  names(data_organization)[1] <- "label"
  
  data_organization$label <- as.character(data_organization$label)
  
  organizations_zuerich <- data_organization[grep("kanton-zuerich", data_organization$label),"label"]
  
  
  return(organizations_zuerich)
  
}






organizations <- getOrganizationsZH(token)





getOpendataSwissData <- function(organization){
  
  ckanr_setup(url = "https://opendata.swiss/")
  
  data_all <- package_search(fq = paste0('organization:',organization), rows= 1000, as='table')
  
  data_results <- data_all$results
  
  
  data_with_groups <- data_results %>% mutate(groups_de = .$groups %>%  map(~getgroups(.) ) %>% as_vector,
                                              title = .$title$de,
                                              organization_url = .$organization$image_display_url,
                                              organization_name = .$organization$name)
  
  
  data_needed <- data_with_groups %>% select(name, title, organization_url, groups_de, organization_name)

  
  
}



getgroups <- function(x){
  
  
  
  group <- x %>% extract2("display_name")  %>% group_by() %>% summarise_each(funs(paste(., collapse = " / "))) %$% de
  
  
  return(group)
  
}



test <- getOpendataSwissData(organizations[1])








# matomo token needed to query the API

# function to retrieve monthly webstatsdata via matomo Api
get_matomo_data <- function(month,organization,matomo_token=token){
  data <- read.csv(paste0("https://piwik.opendata.swiss/index.php?module=API&method=CustomDimensions.getCustomDimension&
                          format=csv&idSite=1&period=month&idDimension=2&
                          reportUniqueId=CustomDimensions_getCustomDimension_idDimension--2&
                          segment=dimension1%253D%253D",organization,"&label=&date=",month,"&
                          filter_limit=false&format_metrics=1&expanded=1&idDimension=2&token_auth=",matomo_token),
                   skipNul = TRUE,encoding = "UTF-8", check.names = FALSE )
  
  names(data)[1]<- "label"
  
  data$date <- month
  
  return(data)
}
# retrieve data for the different data publishers affiliated with the canton of Zurich
stats_time_data <- get_matomo_data(month,organization=organizations[1], matomo_token =  token)


stats_time_data$label <- as.character(stats_time_data$label)


test_total <- left_join(test, stats_time_data, by = c("name"="label"))













