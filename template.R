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

source("data_download.R")

# matomo token needed to query the API
matomo_token <- "fdf8fc140d2b204596e6668dec590697"


# function that gets the data
OGDanalytics_2018_12 <- getWebAnalytics(
  month = "2018-12-31",
  matomo_token = matomo_token,
  name = "kanton-zuerich"
)

# function that exports the data
writeWebAnalytics(OGDanalytics_2018_12, "L:/STAT/08_DS/06_Diffusion/OGD/Datenproduzenten_ZH/Open-ZH/ZH_Datasets_UniqueActions_2018-12.csv")

