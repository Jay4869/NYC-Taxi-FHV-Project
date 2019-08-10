library(dplyr)
library(purrr)
library(lubridate)
library(ggplot2)
library(reshape2)
library(data.table)
library(tibble)
library(tidyr)

setwd("E:/Work/Taxi")

base = read.csv("./Data/base_number.csv")$x %>% as.character()

weather = read.csv("./Data/weather.csv") %>%
  mutate(date = as.Date(as.character(DATE))) %>%
  select(-STATION, -TAVG, -DATE)

import_data = function(start, end)
{
  data = c()
  for(i in start:end)
  {
    file = paste("./Data/20180", i, ".csv") %>% gsub(" ", "", .)
    
    # temp = fread(file) %>%
    #   filter(Dispatching_base_number %in% c("B02510", "B02800", base)) %>%
    #   mutate(type = ifelse(Dispatching_base_number == "B02510", "Lyft",
    #                        ifelse(Dispatching_base_number == "B02800", "Via", "Uber")),
    #          pickup_datetime = ymd_hms(Pickup_DateTime),
    #          dropoff_datetime = ymd_hms(DropOff_datetime),
    #          travel_time = as.numeric(dropoff_datetime-pickup_datetime),
    #          date = date(pickup_datetime),
    #          month = month(pickup_datetime),
    #          day = day(pickup_datetime),
    #          pick_hour = hour(pickup_datetime),
    #          pickup_location_id = PUlocationID,
    #          dropoff_location_id = DOlocationID) %>%
    #   select(travel_time, pickup_datetime, dropoff_datetime, date, month, day,
    #          pick_hour, pickup_location_id, dropoff_location_id, type) %>%
    #   as_tibble()
    
    temp = fread(file) %>% data.table() %>%
      .[Dispatching_base_number %in% c("B02510", "B02800", base)] %>%
      .[, type := ifelse(Dispatching_base_number == "B02510", "Lyft",
                         ifelse(Dispatching_base_number == "B02800", "Via", "Uber"))] %>%
      .[, pickup_datetime := ymd_hms(Pickup_DateTime)] %>%
      .[, dropoff_datetime := ymd_hms(DropOff_datetime)] %>%
      .[, travel_time := as.numeric(dropoff_datetime-pickup_datetime)] %>%
      .[, date := date(pickup_datetime)] %>%
      .[, month := month(pickup_datetime)] %>%
      .[, day := day(pickup_datetime)] %>%
      .[, wkday := weekdays(date)] %>%
      .[, pick_hour := hour(pickup_datetime)] %>%
      .[, pickup_location_id := PUlocationID] %>%
      .[, dropoff_location_id := DOlocationID] %>%
      .[, list(travel_time, pickup_datetime, dropoff_datetime, date, month, day, wkday,
               pick_hour, pickup_location_id, dropoff_location_id, type)]
    
    temp = temp[, r := row_number(pickup_datetime), by = .(month, day, pick_hour)][r %in% sample(seq(1, 9999), 20)]
    data = rbindlist(list(data, temp), use.names = FALSE)
  }
  
  remove(temp)
  
  data = data[weather, on = 'date', nomatch = 0][, r:=NULL]
  fwrite(data, paste("./Data/", start, "-", end, "_weather_mini.csv") %>% gsub(" ", "", .))

  return(data)
}

# import_data(1,6) %>% as_tibble() %>%
#   group_by(day, pick_hour) %>%
#   filter(row_number(pickup_datetime) <= 300)%>%
#   fwrite("./Data/sampled_1-2.csv")

data = import_data(1,12)