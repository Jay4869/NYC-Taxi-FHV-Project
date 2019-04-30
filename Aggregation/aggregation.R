# create aggregation tables for counts group_by hour, weekday, month
# only load by half year and export by csv
count.by.time = function(data, i)
{
  # wday, hourly counts
  x = data %>%
    mutate(hour = hour(pick), wday = weekdays(pick), month = month.abb[month(pick)], type) %>%
    group_by(hour, wday, month, type) %>%
    count
  
  write.csv(x, paste(i, "../Data/tables/counts by times.csv"))
  remove(x)
}
count.by.time(data, 1)

# create aggregation tables for duration group_by hour, day, weekday, month
# only load by half year and export by csv
duration.by.time = function(data, i)
{
  # hourly duration
  x = data %>%
    mutate(hour = hour(pick)) %>%
    group_by(hour) %>%
    summarise(d.total = sum(duration), n = length(duration))
  
  # day duration
  y = data %>%
    mutate(day = as.Date(pick)) %>%
    group_by(day) %>%
    summarise(d.med = median(duration))
  
  # wday duration
  z = data %>%
    mutate(wday = weekdays(pick)) %>%
    group_by(wday) %>%
    summarise(d.total = sum(duration), n = length(duration))
  
  # month duration
  w = data %>%
    mutate(month = month.abb[month(pick)]) %>%
    group_by(month) %>%
    summarise(d.med = median(duration))
  
  write.csv(x, paste(i, "../Data/tables/hourly duration.csv"))
  write.csv(y, paste(i, "../Data/tables/day duration.csv"))
  write.csv(z, paste(i, "../Data/tables/wday duration.csv"))
  write.csv(w, paste(i, "../Data/tables/month duration.csv"))
  
  remove(x,y,z,w)
}
duration.by.time(data, 1)

# create aggregation tables for duration group_by hour, day, weekday, month with types
# only load by half year and export by csv
duration.by.type = function(data, i)
{
  # hourly duration
  x = data %>%
    mutate(hour = hour(pick)) %>%
    group_by(hour, type) %>%
    summarise(d.total = sum(duration), n = length(duration))
  
  # wday duration
  z = data %>%
    mutate(wday = weekdays(pick)) %>%
    group_by(wday, type) %>%
    summarise(d.total = sum(duration), n = length(duration))
  
  # month duration
  w = data %>%
    mutate(month = month.abb[month(pick)]) %>%
    group_by(month, type) %>%
    summarise(d.med = median(duration))
  
  write.csv(x, paste(i, "../Data/tables/hourly type duration.csv"))
  write.csv(z, paste(i, "../Data/tables/wday type duration.csv"))
  write.csv(w, paste(i, "../Data/tables/month type duration.csv"))
  
  remove(x,z,w)
}
duration.by.type(data, 1)