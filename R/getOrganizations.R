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
