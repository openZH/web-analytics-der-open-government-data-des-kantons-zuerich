
# Header ------------------------------------------------------------------

# Description:

# Example for openzh Download  --------------------------------------------

# step by step description
# TODO: Update step by step description
# TODO: For this to work, tokens need to be set in .renviron file
# > see here on how to do that: https://statistikzh.github.io/statZHmatomo/#prerequisites
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

# set paramater ---------------------------------------------------------------

month <- Sys.Date() - 28 # in YYYY-MM-DD Format for functions 
year_month <- paste0(lubridate::year(month), "-", lubridate::month(month)) # in YYYY-MM format for filename

# set matomo token --------------------------------------------------------

# matomo token needed to query the API
token_openzh <- Sys.getenv("token_openzh")

# opendata.swiss analytics ------------------------------------------------

# function that gets the data
OGDanalytics <- getWebAnalytics(
  month = month,
  matomo_token = token_openzh,
  name = "kanton-zuerich"
)

# function that exports the data
file_name <- paste0(
  "L:/STAT/08_DS/06_Diffusion/OGD/Datenproduzenten_ZH/Open-ZH/ZH_Datasets_UniqueActions_",
  year_month, 
  ".csv")

# TODO: Auskommentiert in develop. Im master wieder hinein nehmen.
# writeWebAnalytics(OGDanalytics, file_name)

## TODO: The OGDanalytics file should to be stored version controlled in gitrepo.
## Suggestion below

readr::write_csv(OGDanalytics, str_c(here::here("data/openzh/ZH_Datasets_UniqueActions_"),
                                                year_month, 
                                                ".csv"))





