# Header ------------------------------------------------------------------

# libraries ---------------------------------------------------------------

library(statZHmatomo) 
library(magrittr)
library(dplyr)

# set paramater ---------------------------------------------------------------

vec_date <- Sys.Date() 
vec_prev_month <- Sys.Date() - 28 # in YYYY-MM-DD Format for functions 
vec_year_month <- paste0(lubridate::year(month), "-", lubridate::month(vec_prev_month)) # in YYYY-MM format for filename

# read data from ZH Web Datenkatalog --------------------------------------

con_zhwebdk <- set_matomo_server(server = "webzh-dk")

zhwebdk <- read_matomo_data(connection = con_zhwebdk,
                            format = "json",
                            period = "month",
                            date = vec_prev_month,
                            apiModule = "CustomDimensions", 
                            apiAction = "getCustomDimension", 
                            idDimension = 9
) %>% 
  as_tibble() %>% 
  # remove 'subtable' list column 
  select(!where(is.list))

# export data -------------------------------------------------------------

readr::write_csv(zhwebdk, str_c(here::here("data/zhwebdk/ZHWeb_Datenkatalog_Datasets_UniqueActions_"),
                                     year_month, 
                                     ".csv"))




