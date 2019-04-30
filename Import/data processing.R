library(dplyr)
library(purrr)
library(lubridate)
library(ggplot2)
library(reshape2)
library(data.table)
library(tibble)
library(tidyr)

base = read.csv("../Data/original/base_number.csv")$x %>% as.character()

load = function(i)
{
  # set file path 
  x = paste("../Data/original/20180", i, ".csv") %>% gsub(" ", "", .)
  
  # load orginal data
  # identify type
  # remove useless columns
  temp = fread(x) %>%
    filter(Dispatching_base_number %in% c("B02510", "B02800", base)) %>%
    mutate(type = ifelse(Dispatching_base_number == "B02510", "Lyft",
                         ifelse(Dispatching_base_number == "B02800", "Via", "Uber"))) %>%
    select(-SR_Flag, -Dispatching_base_number, -Dispatching_base_num) %>%
    as.tibble()
  
  # export subset monthly data as back-up
  a = paste("../Data/tables/", i, ".csv") %>% gsub(" ", "", .)
  write.csv(temp, a)
  
  return(data)
}

data = c()
for(i in 1:12)
{
  # load original monthly data
  temp = load(i)
  
  # combine data
  data = bind_rows(data, temp)
  
  # optimize memory usage
  remove(temp)
}

# re-format data types
data = data %>%
  mutate(pick = ymd_hms(Pickup_DateTime), drop = ymd_hms(DropOff_datetime), duration = as.numeric(drop - pick)/60) %>%
  select(-V1, -Pickup_DateTime, -DropOff_datetime)

# only for Dec due to different time format
data2 = as.tibble(fread("./Data/tables/12.csv")) %>%
  mutate(pick = mdy_hm(Pickup_DateTime), drop = mdy_hm(DropOff_datetime), duration = as.numeric(drop - pick)/60) %>%
  select(-V1, -Pickup_DateTime, -DropOff_datetime)

# load weather dataset
weather = read.csv("./Data/original/weather.csv") %>%
  mutate(DATE = as.Date(as.character(DATE))) %>%
  select(-STATION, -TAVG, -TMAX, -TMIN, -AWND) %>%
  as.tibble()

# Combining weather and trips
data %>%
  mutate(DATE = as.Date(pick)) %>%
  group_by(DATE) %>%
  summarise(m.d = median(duration)) %>%
  inner_join(. , weather, by = "DATE")