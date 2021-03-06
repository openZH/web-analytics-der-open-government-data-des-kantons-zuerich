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

library(dplyr)
library(purrr)
library(ckanr)
library(tidyr)

source("data_download.R") # without "geoinformation-kanton-zuerich" due to insufficient metadata (see row 111)

# source("token.R")

# matomo token needed to query the API

matomo_token <- Sys.getenv("TOKEN_OPENZH")

ymd <- Sys.Date()

ym <- format(ymd, "%Y-%m")

y <- format(ymd, "%Y")

if(!file.exists("data/ZH_Datasets_UniqueActions_", ym ,".csv")) {

# function that gets the data
OGDanalytics <- getWebAnalytics(
  month = ymd,
  matomo_token = matomo_token,
  name = "kanton-zuerich",
  verbose=TRUE
) %>% 
  mutate(issued=format(issued,format="%d.%m.%Y"))

# function that exports the data
writeWebAnalytics(OGDanalytics, paste0("data/ZH_Datasets_UniqueActions_", ym ,".csv"))

}
