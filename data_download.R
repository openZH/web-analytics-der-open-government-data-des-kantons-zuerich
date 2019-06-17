
library(tidyverse)
library(magrittr)
library(ckanr)


# matomo token needed to query the API
matomo_token <- "your Token"


month_1 <- as.Date(paste0(format(as.Date(Sys.Date()), "%Y-%m"), "-01")) - 1



writeWebAnalytics <- function(data, filename){
  
  
  write.table(data, filename, sep="," ,row.names = F,quote = FALSE)
  
  
}




getWebAnalytics <- function(month, matomo_token, name) {

  # convert character-date to date
  if (class(month) == "character") {
    month <- as.Date(month, "%Y-%m-%d")
  }

  # get all organizations of the kanton of Zürich
  organizations <- getOrganizations(name)


  # get the opendata.swiss data for the organizations
  opendata_swiss_data <- organizations %>% purrr::map(~ getOpendataSwissData(.))

  opendata_swiss_data_frame <- do.call(rbind, opendata_swiss_data)

  # get the matomo data for the organizations
  matomo_data <- organizations %>% purrr::map(~ getMatomoData(., month = month, matomo_token = matomo_token))

  matomo_data_frame <- do.call(rbind, matomo_data)

  # join the data by the label
  total_data <- dplyr::left_join(opendata_swiss_data_frame, matomo_data_frame, by = c("name" = "label"))

  # filter the data by the issue date (in case for past months)
  total_data_filtered <- total_data %>% dplyr::filter(issued <= month)

  total_data_sorted <- dplyr::arrange(total_data_filtered, desc(nb_visits))

  return(total_data_sorted)
}





# get organizations on the matomo
getOrganizations <- function(name_org) {

  # api to get the organizations from matomo
  ckanr::ckanr_setup(url = "https://opendata.swiss/")

  
  data_organization <- ckanr::organization_list(as = "table") %>% select(package_count, name)



  # filter the organizations by name
  organizations_zuerich_list <- purrr::map(name_org, ~extractOrganization(., data_organization)  )   
  organizations_zuerich <- unlist(organizations_zuerich_list)


  return(organizations_zuerich)
}

# get the organizations that contain the pattern specified in "name"
extractOrganization <- function(name, data){
  
  
  organization_extract <- data[grep(name, data$name),]
  
  organization_extract_short <- organization_extract[organization_extract$name != name & 
                                                       organization_extract$package_count != 0,"name"]
  
  return(organization_extract_short)
  
}


# function to get the opendata Swiss Data with the ckanr api
getOpendataSwissData <- function(organization) {
  
  #sprache_1 <- quo(!!sym(sprache))
  
  # set default url
  ckanr::ckanr_setup(url = "https://opendata.swiss/")

  # api for opendata-swiss data
  data_all <- ckanr::package_search(fq = paste0("organization:", organization), rows = 1000, as = "table")
  
  themes <- getThemes() %>% select(name)

  data_results <- data_all$results

  # get groups and the other important variables
  data_with_groups <- data_results %>% 
    dplyr::mutate(
    groups = .$groups %>% 
      purrr::map(~ getgroups(.)),
    organization_name = .$organization$name,
    issued = as.Date(gsub("T", " ", data_results$issued), "%Y-%m-%d %H:%M:%S")
  ) 



  # select the wished variables
  data_needed <- data_with_groups %>% 
    dplyr::select(name, issued,  groups, organization_name) %>% 
    mutate(organization_url = paste0("https://opendata.swiss/organization/", organization)) 
  
  
  test <- data_needed %>% 
          pull(groups) %>% 
          map(., ~spreadGroups(.,themes)) %>% 
          bind_rows() %>% 
          bind_cols(data_needed,.) %>% 
          select(-groups)
  
  
}


# function to extract the group names and paste them together in one column
getgroups <- function(x) {
  
  # extract the german name of the groups and in case of multiple groups, paste them together
  group <- x %>%
    select(name) %>%
    dplyr::group_by() %>% as.list()

  return(group)
}



# matomo token needed to query the API

# function to retrieve monthly webstatsdata via matomo Api
getMatomoData <- function(organization, month, matomo_token = token) {

  # api for matomo data
  data <- suppressWarnings(
                          read.csv(paste0("https://piwik.opendata.swiss/index.php?module=API&method=CustomDimensions.getCustomDimension&
                          format=csv&idSite=1&period=month&idDimension=2&
                          reportUniqueId=CustomDimensions_getCustomDimension_idDimension--2&
                          segment=dimension1%253D%253D", organization, "&label=&date=", month, "&
                          filter_limit=false&format_metrics=1&expanded=1&idDimension=2&token_auth=", matomo_token),
    skipNul = TRUE, encoding = "UTF-8", check.names = FALSE
  )
  )

  # rename first column
  names(data)[1] <- "label"

  # add date column
  data$date <- month

  # convert factor to characer
  data$label <- as.character(data$label)

  return(data)
}



getThemes <- function(){
  
  ckanr::ckanr_setup(url = "https://opendata.swiss/")
  
  
  themes <-ckanr::group_list(as = "table", all_fields = TRUE)
  
  
  theme_titles <- themes %>% magrittr::extract2("display_name") 
  
  names <- select(themes, name)
  
  theme_table <- bind_cols(theme_titles,names)
  
  
  
}


spreadGroups <- function(x, themes){
  
  y <- x[[1]]
  
  themes_marked <- themes %>% mutate(anzahl = ifelse(name %in% y, 1, 0))
  
  themes_spread <- spread(themes_marked, name, anzahl)
  
  
}

