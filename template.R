
# Header ------------------------------------------------------------------

# Description:

# libraries ---------------------------------------------------------------

library(statZHmatomo)


# Example for openzh Download  --------------------------------------------

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

# set paramater ---------------------------------------------------------------

month <- Sys.Date() - 15 # in YYYY-MM-DD Format for functions 
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

# writeWebAnalytics(OGDanalytics, file_name)

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

con_zhwebdk <- set_matomo_server(server = "webzh-dk")

zhwebdk <- read_matomo_data(connection = con_zhwebdk,
                            format = "json",
                            period = "month",
                            apiModule = "CustomDimensions", 
                            apiAction = "getCustomDimension", 
                            idDimension = 9
) %>% 
  as_tibble() 

## prepare for zhweb-dk data for join with openzh data 

zhwebdk_bind <- zhwebdk %>% 
  left_join(identifier_openzh, by = c("label" = "identifier")) %>% 
  relocate(name, .after = label) %>% 
  
  ## NAs in name can be filtered. These are data sets that are not published as 
  ## OGD on opendata.swiss
  
  filter(!is.na(name)) %>% 
  select(!where(is.list)) %>% 
  
  ## is segment needed? 
  rename(metadata_segment = segment) %>% 
  
  ## does it needed the date column?
  mutate(date = month) %>% 
  
  ## add variable to that identifies data as zhweb-dk Analytics
  mutate(analytics = "zhweb-dk") %>% 
  
  ## remove label and idsubdatatable variables as they are not available in openzh analytics
  select(-label, -idsubdatatable)


## implement join of openzh data with openzh data

OGD_openzh_zhweb_joined <- OGDanalytics %>% 
  as_tibble() %>% 
  
  ## two variables need to be transformed from character type to numeric type 
  ## in order to bind the data frames by rows
  
  separate(avg_time_on_dimension, into = c("del1", "del2", "avg_time_on_dimension"), sep = ":") %>% 
  select(-del1, -del2) %>% 
  mutate(avg_time_on_dimension = as.double(avg_time_on_dimension)) %>% 
  mutate(avg_time_generation = as.double(parse_number(avg_time_generation))) %>%
  
  ## add variable that identified data as openzh Analytics
  
  mutate(analytics = "openzh") %>% 
  
  ## bind ZHWeb Datenkatalog 
  
  bind_rows(
    zhwebdk_bind 
  ) 

# tidy data to fill variables with themes and org names -------------------

OGD_analytics_combined <- OGD_openzh_zhweb_joined %>% 
  arrange(name) %>%
  fill(issued:work)

OGD_analytics_combined %>% 
  arrange(desc(nb_hits), name) %>% 
  filter(str_detect(name, "covid")) %>% 
  slice_head(n = 60) %>% 
  
  ggplot(aes(x = nb_hits, y = name, fill = analytics)) +
  geom_col() +
  labs(
    title = "Number of view (nb_hits) for COVID datasets"
  )

OGD_analytics_combined %>% 
  group_by(name) %>% 
  mutate(prop = nb_hits / sum(nb_hits) * 100) %>% 
  filter(str_detect(name, "covid")) %>% 
  
  ggplot(aes(x = prop, y = name, fill = analytics)) +
  geom_col()  +
  labs(
    title = "Proportion of views (nb_hits) for COVID datasets"
  )


OGD_analytics_combined %>% 
  arrange(desc(nb_hits), name) %>% 
  filter(!str_detect(name, "covid")) %>% 
  slice_head(n = 36) %>%
  
  ggplot(aes(x = nb_hits, y = reorder(name, nb_hits), fill = analytics)) +
  geom_col() +
  labs(
    title = "Number of views (nb_hits) for top 30 non-COVID datasets"
  )

OGD_analytics_combined %>% 
  group_by(name) %>% 
  mutate(prop = nb_hits / sum(nb_hits) * 100) %>%  
  ungroup() %>% 
  filter(!str_detect(name, "covid")) %>%  
  arrange(desc(nb_hits), name) %>% 
  slice_head(n = 36) %>%
  
  ggplot(aes(x = prop, y = name, fill = analytics)) +
  geom_col()  +
  labs(
    title = "Proportion of views (nb_hits) for top 30 non-COVID datasets"
  )

# one resource several times ----------------------------------------------

read.csv(file = "https://www.web.statistik.zh.ch/ogd/data/openzh/ZH_Datasets_UniqueActions_2020-09.csv", sep = ";") %>% 
    as_tibble() %>% 
    arrange(name) %>% 
    View()
 
