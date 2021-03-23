library(magrittr)
library(ckanr)
library(dplyr)
library(tidyr)


#' function to write the webanalytics-data
#'
#' @param data dataset
#' @param filename filename
#'
#' @return
#' @export
#'
#' @examples

writeWebAnalytics <- function(data, filename) {
  write.table(data, filename, sep = ",", row.names = F, quote = FALSE)
}


#' function to get the webanalytics-data from matomo instance
#'
#' @param month period (month) for which the webanalytics should be retrieved
#' @param matomo_token access token to access the matomo instance
#' @param name name (approximate string pattern) that matches the organizations for which the data should be loaded
#'
#' @return data.frame
#' @export
#'
#' @examples  
#' \donttest{ getWebAnalytics(month = "2020-03-31",matomo_token, name="kanton_zuerich")}

getWebAnalytics <- function(month, matomo_token, name, verbose=FALSE) {
  
  # convert character-date to date
  if (class(month) == "character") {
    month <- as.Date(month, "%Y-%m-%d")
  }
  
  safelyORG <- safely(getOrganizations)
  
  # get all organizations of the kanton of Zürich
  organizations <- getOrganizations(name, month)
  
  # get the opendata.swiss data for the organizations
  opendata_swiss_data <-
    organizations %>%
    purrr::map(~ getOpendataSwissData(.))
  
  opendata_swiss_data_frame <- do.call(rbind, opendata_swiss_data)
  
  # get the matomo data for the organizations
  safematomo <- safely(getMatomoData)
  
  matomo_data <-
    organizations %>%
    purrr::map(~ safematomo(., month = month, matomo_token = matomo_token,verbose=verbose))
  
  matomo_data_frame  <- map_dfr(matomo_data,"result", .null=data_frame())
  
  # hello <- getMatomoData("awel-kanton-zuerich",month = month, matomo_token = matomo_token)
  
  total_data <- dplyr::left_join(opendata_swiss_data_frame,
                                 matomo_data_frame,
                                 by = c("name" = "label")
  )
  
  
  # filter the data by the issue date (in case for past months)
  total_data_filtered <-
    total_data %>%
    dplyr::filter(issued <= month)
  
  total_data_sorted <- dplyr::arrange(total_data_filtered, desc(nb_visits))
  
  return(total_data_sorted)
}


#' function to find organization on opendata.swiss 
#'
#' @param name_org string pattern that partially matches the organization name
#' @param month argument to filter for the month of existence
#'
#' @return string vector
#' @export
#'
#' @examples
#' \donttest{ 
#' #get all organizations that contain 'kanton-zuerich' in their name and already existed on opendata.swiss in dec. 2018
#' getOrganizations(name_org="kanton-zuerich", month = "2018-12-31")}

getOrganizations <- function(name_org, month) {
  name_org = "kanton-zuerich"
  
  if (class(month) == "character") {
    month <- as.Date(month, "%Y-%m-%d")
  }


  # api to get the organizations from matomo
  ckanr::ckanr_setup(url = "https://opendata.swiss/")


  data_organization <- ckanr::organization_list(limit = 1000, as = "table")

  data_organization_date <-
    data_organization %>%
    mutate(created = as.Date(
      gsub("T", " ", data_organization$created),
      format("%Y-%m-%d")
    )) %>%
    mutate(created = format(created, "%Y-%m")) %>%
    filter(created < format(month, "%Y-%m"),
           # filter to remove "geoinformation-kanton-zuerich"
           name != "geoinformation-kanton-zuerich") %>%
    select(package_count, name)

  # filter the organizations by name
  organizations_list <- purrr::map(
    name_org,
    ~ extractOrganization(
      .,
      data_organization_date
    )
  )
  organizations <- unlist(organizations_list)

  # hack to filter the fachstelle-ogd-kanton-zuerich since there is no data
  # in matomo before 2019-06-30
  if (month < as.Date("2019-06-30", "%Y-%m-%d") & month > as.Date("2019-01-01", "%Y-%m-%d")) {
    organizations <- organizations[
      -(organizations == "fachstelle-ogd-kanton-zuerich")]
  } else {organizations <- organizations}


  return(organizations)
}

# get the organizations that contain the pattern specified in "name"
extractOrganization <- function(name, data) {
  organization_extract <- data[grep(name, data$name), ]

  organization_extract_short <- organization_extract[
    organization_extract$name != name &
    organization_extract$package_count != 0, "name"]

  return(organization_extract_short)
}


#' function to get the opendata Swiss Metadata for a single organization
#'
#' @param organization exact name of the data publisher (organization) for which metadata should be loaded (via CKAN Action API)
#'
#' @return
#' @export
#'
#' @examples
#' \donttest{ 
#' #get all the datasets of a specific publisher with attributes (topics)
#' getOpendataSwissData("statistisches-amt-kanton-zuerich")}

getOpendataSwissData <- function(organization="kanton-zuerich") {

  # sprache_1 <- quo(!!sym(sprache))

  # set default url
  ckanr::ckanr_setup(url = "https://opendata.swiss/")

  # api for opendata-swiss data
  data_all <- ckanr::package_search(fq = paste0("organization:", 
                                                organization), 
                                    rows = 1000, as = "table")

  themes <- getThemes() %>% select(name)

  data_results <- data_all$results

  # get groups and the other important variables
  data_with_groups <- data_results %>%
    dplyr::mutate(
      groups = .$groups %>%
        purrr::map(~ getgroups(.)),
      organization_name = .$organization$name,
      issued = as.Date(issued, "%d.%m.%Y")
    ) %>% 
    bind_rows()

# data_with_groups$name

  
  
  # select the wished variables
  data_needed <- data_with_groups %>%
    dplyr::select(name, issued, groups, organization_name) %>%
    mutate(organization_url = paste0("https://opendata.swiss/organization/", 
                                     organization))


data_needed %>%
    pull(groups) %>%
    map(., ~ spreadGroups(., themes)) %>%
    bind_rows() %>%
    bind_cols(data_needed, .) %>%
    select(-groups)
}


#' function to extract the group names and paste them together in one column
#'
#' @param x group variable
#'
#' @return group list
#'
#' @examples

getgroups <- function(x) {

  # extract the german name of the groups and in case of multiple groups, paste them together
  group <- x %>%
    select(name) %>%
    dplyr::group_by() %>%
    as.list()

  return(group)
}



#' function to retrieve monthly webstatsdata via matomo Api
#'
#' @param organization 
#' @param month 
#' @param matomo_token matomo token needed to query the API
#'
#' @return
#' @export
#'
#' @examples 
#' \donttest{ 
#' #get all the datasets of a specific publisher with attributes (topics)
#' getMatomoData(organization="geoinformation-kanton-zuerich",month = "2018-12-31",matomo_token=matomo_token)}

getMatomoData <- function(organization, month, matomo_token = token, period="month", verbose=TRUE) {

  # api for matomo data
#   data <- suppressWarnings(
#     read.csv(paste0("https://opendata.opsone-analytics.ch/index.php?
# module=API&method=CustomDimensions.getCustomDimension&
# format=csv&idSite=1&period=month&idDimension=2&
# reportUniqueId=CustomDimensions_getCustomDimension_idDimension--2&
# segment=dimension1%253D%253D", organization, "&date=", month, "&
# filter_limit=false&format_metrics=1&expanded=1&idDimension=2&token_auth=", 
#                     matomo_token),
#       skipNul = TRUE, encoding = "UTF-8", check.names = FALSE
#     )
#   )
# 
  
query <- paste0("https://opendata.opsone-analytics.ch/index.php?expanded=1&filter_limit=-1&format=CSV&idDimension=2&idSite=1&method=CustomDimensions.getCustomDimension&module=API&period=day&reportUniqueId=CustomDimensions_getCustomDimension_idDimension--1&segment=dimension1%253D%253D",
                organization,
                "&period=", period,
                "&date=", month,
                "&token_auth=",matomo_token)
  
  
if(verbose==TRUE) {print(query)}

data <- suppressWarnings(
    read.csv(query,
             skipNul = TRUE, encoding = "UTF-8", check.names = FALSE
    )
  )
  
  # rename first column
  names(data)[1] <- "label"

  # add date column
  data$date <- month

  # convert factor to characer
  data$label <- as.character(data$label)
  
  # data$permaurl <- gsub("dimension2==","",data$metadata_segment)

  return(data)
}


#' helper function to extract the groups
#' @return theme table


getThemes <- function() {
  ckanr::ckanr_setup(url = "https://opendata.swiss/")


  themes <- ckanr::group_list(as = "table", all_fields = TRUE)


  theme_titles <- themes %>% magrittr::extract2("display_name")

  names <- select(themes, name)

  theme_table <- bind_cols(theme_titles, names)
}

#' helper function to spread the groups to wide
#' @return theme table

spreadGroups <- function(x, themes) {
  y <- x[[1]]

  themes_marked <- themes %>% mutate(anzahl = ifelse(name %in% y, 1, 0))

  themes_spread <- tidyr::spread(themes_marked, name, anzahl)
}
