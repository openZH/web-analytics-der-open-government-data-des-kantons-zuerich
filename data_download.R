
library(tidyverse)
library(magrittr)
library(ckanr)


# matomo token needed to query the API
matomo_token  <- "your Token"


month_1 <- as.Date(paste0(format(as.Date(Sys.Date()), "%Y-%m"),"-01"))-1




getWebAnalytigs <- function(month, matomo_token, name){
  
  # convert character-date to date
  if(class(month)=="character"){month <- as.Date(month, "%Y-%m-%d" )}
  
  # get all organizations of the kanton of Zürich
  organizations <- getOrganizationsZH(month, matomo_token, name)
  
  
  # get the opendata.swiss data for the organizations
  opendata_swiss_data <- organizations %>% purrr::map(~getOpendataSwissData(.))
  
  opendata_swiss_data_frame <- do.call(rbind, opendata_swiss_data)
  
  # get the matomo data for the organizations
  matomo_data <- organizations %>% purrr::map(~getMatomoData(., month=month, matomo_token=matomo_token ))
  
  matomo_data_frame <- do.call(rbind, matomo_data)
  
  # join the data by the label
  total_data <- dplyr::left_join(opendata_swiss_data_frame, matomo_data_frame, by = c("name"="label"))
  
  # filter the data by the issue date (in case for past months)
  total_data_filtered <- total_data %>% dplyr::filter(issued <= month)
  
  
  return(total_data_filtered)
}






getOrganizations <- function(month, matomo_token, name){
  
  # api to get the organizations from matomo
  data_organization <- read.csv(paste0("https://piwik.opendata.swiss/index.php?date=",month,"&expanded=1&filter_limit=-1&
                                     format=CSV&idDimension=1&idSite=1&language=en&method=CustomDimensions.getCustomDimension&
                                       module=API&period=month&reportUniqueId=CustomDimensions_getCustomDimension_idDimension--1&
                                       token_auth=",matomo_token,"&translateColumnNames=1"),
                                skipNul = TRUE,encoding = "UTF-8", check.names = FALSE )
  
  # rename first column
  names(data_organization)[1] <- "label"
  
  # convert factor to character
  data_organization$label <- as.character(data_organization$label)
  
  # filter the organizations by name
  organizations_zuerich <- data_organization[grep(name, data_organization$label),"label"]
  
  
  return(organizations_zuerich)
  
}






getOpendataSwissData <- function(organization){
  
  # set default url
  ckanr::ckanr_setup(url = "https://opendata.swiss/")
  
  # api for opendata-swiss data
  data_all <- ckanr::package_search(fq = paste0('organization:',organization), rows= 1000, as='table')
  
  data_results <- data_all$results
  
  # get groups and the other important variables
  data_with_groups <- data_results %>% dplyr::mutate(groups_de = .$groups %>%  purrr::map(~getgroups(.) ) %>% purrr::as_vector,
                                              title = .$title$de,
                                              organization_url = .$organization$image_display_url,
                                              organization_name = .$organization$name,
                                              issued = as.Date(gsub("T", " ", data_results$issued)), "%Y-%m-%d %H:%M:%S")
  
  
  
  # select the wished variables
  data_needed <- data_with_groups %>% dplyr::select(name, title, issued, organization_url, groups_de, organization_name)

  
  
}



getgroups <- function(x){
  
  
  # extract the german name of the groups and in case of multiple groups, paste them together
  group <- x %>% magrittr::extract2("display_name")  %>% dplyr::group_by() %>% dplyr::summarise_each(dplyr::funs(paste(., collapse = " / "))) %$% de
  
  
  return(group)
  
}



# matomo token needed to query the API

# function to retrieve monthly webstatsdata via matomo Api
getMatomoData <- function(organization, month,matomo_token=token){
  
  # api for matomo data
  data <- read.csv(paste0("https://piwik.opendata.swiss/index.php?module=API&method=CustomDimensions.getCustomDimension&
                          format=csv&idSite=1&period=month&idDimension=2&
                          reportUniqueId=CustomDimensions_getCustomDimension_idDimension--2&
                          segment=dimension1%253D%253D",organization,"&label=&date=",month,"&
                          filter_limit=false&format_metrics=1&expanded=1&idDimension=2&token_auth=",matomo_token),
                   skipNul = TRUE,encoding = "UTF-8", check.names = FALSE )
  
  # rename first column
  names(data)[1]<- "label"
  
  # add date column
  data$date <- month
  
  # convert factor to characer
  data$label <- as.character(data$label)
  
  return(data)
}















