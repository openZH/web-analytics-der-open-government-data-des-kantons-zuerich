# Example for the Download

# step by step description

# best is to make a pull before using the functions
# -> right click on the folder -> GitSync -> PULL

#1. curser on line 18 and press ctrl+Enter
#2. insert matomo_token
#3. adjust the month in the object name
#4. adjust the month in the function: month = ....
#5. adjust the name in the function: name = "..."
#6. curser on line 25 and press ctrl+Enter to run the function
#7. have a look at the file -> in global environment klick on the object
#8. adjust the filename in line 32
#9. curser on line 32 and press ctrl+Enter to export the data as a csv-file

source("data_download.R") # without "geoinformation-kanton-zuerich" due to insufficient metadata (see row 111)

# source("token.R")

# set month ---------------------------------------------------------------

month <- "2020-10-01"

# set matomo token --------------------------------------------------------

# matomo token needed to query the API
token_openzh <- Sys.getenv("token_openzh")

# opendata.swiss analytics ------------------------------------------------

# function that gets the data
OGDanalytics_2020_07 <- getWebAnalytics(
  month = month,
  matomo_token = token_openzh,
  name = "kanton-zuerich"
)

# function that exports the data
writeWebAnalytics(OGDanalytics_2020_07, "L:/STAT/08_DS/06_Diffusion/OGD/Datenproduzenten_ZH/Open-ZH/ZH_Datasets_UniqueActions_2020-07.csv")

# ZHweb Daten- und Publikationskatalog analytics --------------------------

## get organisations for current month
organizations_vec <- getOrganizations(month = month)

## helper function to extract name and identifier
read_opendataswiss_data <- function(org = NULL) {
  dat <- package_search(fq = str_c("organization:", org), as = "table", rows = 1000)
  
  dat$results %>% 
    as_tibble() %>% 
    select(name, identifier)
}

## for loop to get identifer and name for all organisations

identifier_openzh_list <- list()

for (name in organizations_vec) {
  identifier_openzh_list[[name]] <- read_opendataswiss_data(org = name)
}

## dataframe of identifier and name to join to join with ZHWeb Datenkatalog Resource
identifier_openzh <- identifier_openzh_list %>% 
  bind_rows()

## read data from ZHweb Datenkatalog

library(statZHmatomo)
library(dplyr)

con_zhwebdk <- set_matomo_server()

zhwebdk <- read_matomo_data(connection = con_zhwebdk,
                            format = "json",
                            period = "month",
                            apiModule = "CustomDimensions", 
                            apiAction = "getCustomDimension", 
                            idDimension = 9
) %>% 
  as_tibble() 

## prepare for Export

zhwebdk %>% 
  left_join(identifier_openzh, by = c("label" = "identifier")) %>% 
  relocate(name, .after = label) %>% 

