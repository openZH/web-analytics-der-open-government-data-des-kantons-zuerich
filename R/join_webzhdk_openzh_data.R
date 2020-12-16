# Header ------------------------------------------------------------------

# libraries ---------------------------------------------------------------

library(magrittr)
library(dplyr)
library(lubridate)
library(stringr)

# source functions --------------------------------------------------------

source(here::here("R/getOrganizations.R"))
source(here::here("R/extractOrganization.R"))

# set paramater ---------------------------------------------------------------

vec_date <- Sys.Date() 
vec_prev_month <- Sys.Date() - 28 # in YYYY-MM-DD Format for functions 
vec_year_month <- paste0(lubridate::year(month), "-", lubridate::month(vec_prev_month)) # in YYYY-MM format for filename

# Extract identifier list of opendata swiss --------------------------

## get organisations for current month
organizations_vec <- getOrganizations(month = vec_prev_month)

## helper function to extract name and identifier of dataset
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

# load data --------------------------------------------------------

## Load CSV from repo not from L
openzh <- readr::read_csv(
  str_c(here::here("data/openzh/ZH_Datasets_UniqueActions_"),
        year_month, 
        ".csv"))

## ZH Web Datenkatalog as published
zhwebdk <- read_csv(
  str_c(here::here("data/zhwebdk/ZHWeb_Datenkatalog_Datasets_UniqueActions_"),
        year_month,
        ".csv"))

# data wrangling --------------------------------------------------------

## prepare for zhweb-dk data for join with openzh data 

### ZH Web DK
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
  mutate(date = vec_date) %>% 
  ## remove label and idsubdatatable variables as they are not available in openzh analytics
  select(-label, -idsubdatatable) %>% 
  ## add variable to that identifies data as zhweb-dk Analytics
  mutate(analytics = "zhweb-dk")


### Open ZH
#TODO: The openzh ressource has several rows per dataset. These should be
#summarised. This does not make sense for all variables.

openzh_bind <- openzh %>% 
  
  ## two variables need to be transformed from character type to numeric type 
  ## in order to bind the data frames by rows
  
  separate(avg_time_on_dimension, into = c("del1", "del2", "avg_time_on_dimension"), sep = ":") %>% 
  select(-del1, -del2) %>% 
  mutate(avg_time_on_dimension = as.double(avg_time_on_dimension)) %>% 
  mutate(avg_time_generation = as.double(parse_number(avg_time_generation))) %>%
  
  ## add variable that identified data as openzh Analytics
  
  mutate(analytics = "openzh") 

# join data ---------------------------------------------------------------

openzh_zhwebdk <- openzh_bind %>% 
  
  ## bind ZHWeb Datenkatalog 
  
  bind_rows(
    zhwebdk_bind 
  ) %>% 
  arrange(name) %>%
  # tidy data to fill variables with themes and org names 
  fill(issued:work)


# Data exploration --------------------------------------------------------

openzh_zhwebdk %>% 
  arrange(desc(nb_hits), name) %>% 
  filter(str_detect(name, "covid")) %>% 
  slice_head(n = 60) %>% 
  
  ggplot(aes(x = nb_hits, y = name, fill = analytics)) +
  geom_col() +
  labs(
    title = "Number of view (nb_hits) for COVID datasets"
  )

openzh_zhwebdk %>% 
  group_by(name) %>% 
  mutate(prop = nb_hits / sum(nb_hits) * 100) %>% 
  filter(str_detect(name, "covid")) %>% 
  
  ggplot(aes(x = prop, y = name, fill = analytics)) +
  geom_col()  +
  labs(
    title = "Proportion of views (nb_hits) for COVID datasets"
  )


openzh_zhwebdk %>% 
  arrange(desc(nb_hits), name) %>% 
  filter(!str_detect(name, "covid")) %>% 
  slice_head(n = 36) %>%
  
  ggplot(aes(x = nb_hits, y = reorder(name, nb_hits), fill = analytics)) +
  geom_col() +
  labs(
    title = "Number of views (nb_hits) for top 30 non-COVID datasets"
  )

openzh_zhwebdk %>% 
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

