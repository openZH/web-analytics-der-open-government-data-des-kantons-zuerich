# function that gets the data
OGDanalytics_2018_12 <- getWebAnalytics(
  month = "2018-12-31",
  matomo_token = matomo_token,
  name = "kanton-zuerich"
)


herro<-getMatomoData("geoinformation-kanton-zuerich",month=month,matomo_token=matomo_token)


gsub("dimension2==","",herro$metadata_segment)


## solution via fuzzyjoin!


library(fuzzyjoin)

opendata <- getOpendataSwissData("geoinformation-kanton-zuerich")

matomodata <-getMatomoData(organization="geoinformation-kanton-zuerich",month = "2018-12-31",matomo_token=matomo_token)

all_data <-matomodata %>% stringdist_inner_join(opendata, by=c(label="name"),max_dist = 1)

check<-all_data %>% select(label,name)

 # statistisches amt - problematische lösung!

opendata_stat <- getOpendataSwissData("statistisches-amt-kanton-zuerich")

matomodata_stat <-getMatomoData(organization="statistisches-amt-kanton-zuerich",month = "2018-12-31",matomo_token=matomo_token)

all_data2 <- matomodata_stat %>% stringdist_inner_join(opendata_stat, by=c(label="name"),max_dist = 1)

check<-all_data2 %>% select(label,name)

