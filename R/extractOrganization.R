# get the organizations that contain the pattern specified in "name"
#' Title
#'
#' @param name 
#' @param data 
#'
#' @return
#' @export
#'
#' @examples

extractOrganization <- function(name, data) {
  organization_extract <- data[grep(name, data$name), ]
  
  organization_extract_short <- organization_extract[
    organization_extract$name != name &
      organization_extract$package_count != 0, "name"]
  
  return(organization_extract_short)
}
