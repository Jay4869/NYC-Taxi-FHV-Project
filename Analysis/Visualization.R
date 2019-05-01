#==================================================================================================
# Load Library
#==================================================================================================
library(tibble) # data wrangling
library(reshape2) # data wrangling
library(tidyr) # data wrangling
library(dplyr) # data manipulation
library(purrr) # data manipulation
library(data.table) # data manipulation
library(ggplot2) # visualisation
library(plotly) # visualisation
library(rgdal) # import GeoJSON

#==================================================================================================
#Edit Taxi zone map data for drawing interactive map
#==================================================================================================
#Load NYC taxi zone map data
json = readOGR("../Data/original/NYC Taxi Zones.geojson", "OGRGeoJSON") 

#Match marketshare of FHV types at each pick-up location id
df = fread("../Data/tables/location weight.csv") %>% select(-V1) %>% mutate(weight = round(weight,2)) %>% dcast(.,PUlocationID~type,value.var = "weight") 
json.id = as.tibble(as.numeric(json$location_id))
colnames(json.id)="PUlocationID"
joint.json = left_join(json.id,df,by="PUlocationID")

#Add corresponding marketshare for each type into map data
json$Lyft = joint.json$Lyft
json$Uber = joint.json$Uber
json$via = joint.json$Via
names(json)[7:9] = c("Lyft Marketshare","Uber Marketshare","Via Marketshare")

#Store to local and create map through Carto, the map Link is #https://zxf71699.carto.com/builder/62d8c815-2839-41fe-95e0-84ac6e4eccb6/embed
writeOGR(json, "./data/NYC fhv marketshare map.geojson", layer="NYC fhv marketshare map", driver="GeoJSON")

#==================================================================================================
#Heapmap for trips with unusual duration
#==================================================================================================
#Load data of trips whose duration is less than 2 min or 4 hours
df1 = read.csv("../Data/tables/less_than_2.csv")
df2 = read.csv("../Data/tables/large_than_240.csv")
pick = read.csv("../Data/tables/dictionary_pickup.csv") %>% as.tibble()
drop = read.csv("../Data/tables/dictionary_dropoff.csv") %>% as.tibble()

#Match borough to location id
match_zone = function(df,dictionary_pickup,dictionary_dropoff){
  
  matched.df = df %>% 
    left_join(dictionary_pickup,by="PUlocationID") %>% 
    mutate(pick_borough = borough) %>% 
    select(-borough)%>%
    left_join(dictionary_dropoff,by="DOlocationID") %>% 
    mutate(drop_borough = borough) %>%  
    select(-borough) %>% 
    filter(!is.na(drop_borough)) %>% 
    filter(!is.na(pick_borough)) %>% 
    group_by(pick_borough,drop_borough) 
  
  return(matched.df)
}

df1 = match_zone(df1,pick,drop) %>% count()
df2 = match_zone(df2,pick,drop) %>% count()

#Set color scale
vals = unique(scales::rescale(df1$n))
o = order(vals, decreasing = FALSE)
cols = scales::col_numeric("Reds", domain = NULL)(vals)
colz = setNames(data.frame(vals[o], cols[o]), NULL)

#Plot Heatmap for trips whose duration less than 2 min
plot_ly(data=df1, x=~pick_borough,y=~drop_borough,z=~n, colorscale = colz, type = "heatmap")

#Set color scale
vals = unique(scales::rescale(df2$n))
o = order(vals, decreasing = FALSE)
cols = scales::col_numeric("Reds", domain = NULL)(vals)
colz = setNames(data.frame(vals[o], cols[o]), NULL)

#Plot Heatmap for trips whose duration larger than 4 hours
plot_ly(data=df2, x=~pick_borough,y=~drop_borough,z=~n, colorscale = colz, type = "heatmap")


#==================================================================================================
#Hourly, Weekly, Monthly median duration for overall taxi
#==================================================================================================
#Plot hourly median duration for overall taxi
p1 = read.csv("../Data/tables/hourly duration.csv") %>%
  plot_ly(., x = ~ hour, y = ~ d.med, type ="scatter", mode = 'lines+markers',
          line = list(color="#2E86C1", width = 4), 
          marker = list(size = 8, color = 'rgba(255, 182, 193, .9)', 
                        line = list(color = 'rgba(152, 0, 0, .8)', width = 2,simplyfy = F)), 
          text = ~ paste("Hour: ", hour, '<br>Average duration:', round(d.med,2))) %>%
  layout(title = 'Hourly Median Trip Duration', 
         yaxis = list(title = 'Duration (min)',range=c(15,25), zeroline = FALSE),
         xaxis = list(title = 'Hour',zeroline = FALSE))

#Set level order of weekday for overall taxi
lvl = c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")

#Plot weekly median duration for overall taxi
p2 = read.csv("../Data/tables/wday duration.csv") %>%
  mutate(wday = ordered(wday, levels = lvl)) %>%
  arrange(wday) %>%
  plot_ly(., x = ~ wday, y = ~ d.med, type ="scatter", mode = 'lines+markers',
          line = list(width=4,simplyfy = F, color='rgb(114, 186, 59)'),
          marker = list(size = 8, color = '#8E44AD', line = list(color = '#3498DB', width = 2)),
          text = ~paste("Weekday: ", wday, '<br>Median duration:', round(d.med,2))) %>%
  layout(title = 'Weekday Median Trip Duration',
         yaxis = list(title = 'Duration (min)', range=c(15,25), zeroline = FALSE),
         xaxis = list(title = 'Weekday', zeroline = FALSE))

#Plot monthly median duration for overall taxi
p3 = read.csv("../Data/tables/month duration.csv") %>%
  mutate(month = ordered(month, levels = month.abb)) %>%
  arrange(month) %>%
  plot_ly(., x = ~ month, y = ~ d.med, 
          type ="scatter",mode = 'lines+markers', line=list(color="#FF5733",width = 4),
          marker = list(size = 8, color = '#FFFF00', line = list(color = '#E67E22', width = 2)),
          text = ~paste("Month: ",month, '<br>Average duration:', round(d.med,2))) %>%
  layout(title = 'Median Trip Duration(min)', showlegend = F,
         yaxis = list(title = 'Duration',range=c(15,25), zeroline = FALSE),
         xaxis = list(title = 'Month', zeroline = FALSE))

#Plot mix plots in one graph
subplot(p1, p2, p3, nrows = 3)

#==================================================================================================
#Hourly, Weekly, Monthly median duration of trips for three FHV types(Uber, Lyft, Via)
#==================================================================================================
#Frames is added to the keys that figure allows. 
#Frames key points to a list of figures, each of which will be cycled through upon instantiation of the plot.
#This function is for animation.
accumulate_by = function(dat, var)
{
  var = lazyeval::f_eval(var, dat)
  lvls = plotly:::getLevels(var)
  dats = lapply(seq_along(lvls), function(x) {cbind(dat[var %in% lvls[seq(1, x)], ], frame = lvls[[x]])})
  dplyr::bind_rows(dats)
}

#Plot hourly trip median durations for three FHV types with animations.
read.csv("../Data/tables/hourly type duration.csv") %>% select(hour,type,d.med) %>%  accumulate_by(~ hour) %>%
  plot_ly(., x = ~ hour, y = ~ d.med, frame = ~ frame, colors= c("hotpink","black","steelblue"),
          color = ~ type, type ="scatter", mode = 'lines+markers',
          line = list(width=4,simplyfy = F), marker = list(size=10),
          text = ~paste("Hour: ",hour, '<br>Average duration:', round(d.med,2))) %>%
  layout(title = 'Hourly Median Trip Duration',
          yaxis = list(title = 'Duration (Min)', zeroline = FALSE),
          xaxis = list(title = 'Hour', zeroline = FALSE)) %>% 
  animation_opts(frame = 300, transition = 200, redraw = F) %>%
  animation_slider(hide = T) %>%
  animation_button(x = 1, xanchor = "right", y = 0, yanchor = "bottom")

#Plot weekly trip median durations for three FHV types with animations.
read.csv("../Data/tables/wday type duration.csv") %>%
  select(-X) %>%
  mutate(wday = ordered(wday,levels = lvl)) %>%
  accumulate_by(~ wday) %>%
  arrange(wday) %>%
  plot_ly(., x = ~ wday, y = ~ d.med,  colors= c("hotpink","black","steelblue"), color = ~ type,
          type ="scatter", mode = 'lines+markers',line = list(width=4,simplyfy = F), marker = list(size=10),
          text = ~paste("WeekdayHour: ",wday, '<br>Median duration:', round(d.med,2))) %>%
  layout(title = 'Weekday Median Trip Duration',
         yaxis = list(title = 'Duration (Min)',zeroline = FALSE),
         xaxis = list(title = 'Weekday', zeroline = FALSE))

#Plot monthly trip median durations for three FHV types with animations.
read.csv("../Data/tables/month type duration.csv") %>%
  select(-X) %>%
  mutate(month = match(month,month.abb)) %>%
  accumulate_by(~ month) %>%
  arrange(month) %>%
  plot_ly(., x = ~ month, y = ~ d.med, colors= c("hotpink","black","steelblue"),
          frame = ~ frame, color = ~ type, type ="scatter", mode = 'lines+markers',
          line = list(width=4,simplyfy = F), marker = list(size=10),
          text = ~paste("Month: ",month, '<br>Median duration:', round(d.med,2))) %>%
  layout(title = 'Monthly Median Trip Duration',
         yaxis = list(title = 'Duration (Min)',zeroline = FALSE),
         xaxis = list(title = 'Month', zeroline = FALSE))%>% 
  animation_opts(frame = 300, transition = 200, redraw = F) %>%
  animation_slider(hide = T) %>%
  animation_button(x = 1, xanchor = "right", y = 0, yanchor = "bottom")

#==================================================================================================
#Markstshares for three FHV types(Uber, Lyft, Via)
#==================================================================================================
#Hourly marketshare for three types

#Load data of trip counts records for hours, weeks and types.
#Compute trip counts for each hour and types
x = read.csv("../Data/tables/counts by h_wk_type.csv") %>%
  group_by(hour,type) %>%
  summarise(counts = sum(n))

#Compute trip counts for each hour
y = read.csv("../Data/tables/counts by h_wk_type.csv") %>%
  group_by(hour) %>%
  summarise(total = sum(n))

#Aggregate trip counts grouped by hours and types
inner_join(y, x, by = "hour") %>% 
  
  #Compute marketshare
  mutate(weight = round(100*counts/total,2)) %>% 
  select(type, weight, hour) %>%
  dcast(., hour ~ type, value.var = 'weight') %>%

  #Plot the filled chart for hourly marketshare for three types
  plot_ly(., x = ~ hour, y = ~ Uber, type = "scatter", mode = "lines+markers",
          groupnorm = 'percent', fill = 'tozeroy', fillcolor = "black",
          name = 'Uber', line = list(color='black'), marker = list(color = 'black'),
          text = ~ paste("Hour:", hour, "<br>Marketshare for FHV taxi:",Uber,"%")) %>%
  add_trace(y = ~ Lyft, name = 'Lyft', fillcolor = 'hotpink', 
            marker = list(color = 'hotpink'), line = list(color='hotpink'),
            text = ~ paste("Hour:",hour, "<br>Marketshare for FHV taxi:", Lyft,"%")) %>%
  add_trace(y = ~Via, name = 'Via', fillcolor = 'steelblue', marker = list(color = 'steelblue'),
            line = list(color='steelblue'),
            text = ~ paste("Hour:",hour, "<br>Marketshare for FHV taxi:",Via,"%"))%>%
  layout(title = 'Hourly marketshare for FHV types',hovermode = 'compare',
         yaxis = list(title = 'Marketshare', zeroline = FALSE, showgrid = F,ticksuffix = '%'),
         xaxis = list(title = 'Hour', zeroline = FALSE, showgrid = F)) 


#Weekly marketshare for three types

#Load data of trip counts records for hours, weeks and types.
#Compute trip counts for each weekday and types
x = read.csv("../Data/tables/counts by h_wk_type.csv") %>%
  mutate(wday = ordered(wday, levels = lvl[seq(7,1)])) %>%
  group_by(wday,type) %>%
  summarise(counts = sum(n))

#Compute trip counts for each hour
y = read.csv("../Data/tables/counts by h_wk_type.csv") %>%
  mutate(wday = ordered(wday, levels = lvl[seq(7,1)])) %>%
  group_by(wday) %>%
  summarise(total = sum(n))

#Aggregate trip counts grouped by weeks and types
inner_join(y, x, by = "wday") %>% 
  
  #Compute weekly marketshare
  mutate(weight = round(100*counts/total,2))%>% 
  select(type, weight, wday) %>%
  dcast(., wday ~ type, value.var = 'weight') %>%
  
  #Plot abr plot for weekly marketshare for three types
  plot_ly(., x = ~ Lyft, y = ~ wday, type = 'bar', orientation = 'h',
          groupnorm = 'percent', fill = 'tozeroy', name = 'Lyft',
          line = list(color='hotpink'), marker = list(color = 'hotpink'),
          text = ~paste("Weekday:",wday, "<br>Marketshare for FHV taxi:", Lyft,"%")) %>%
  add_trace(x = ~Via, name = 'Via', marker = list(color = 'steelblue'),
            line = list(color='steelblue'),
            text = ~paste("Weekday:", wday, "<br>Marketshare for FHV taxi:",Via,"%")) %>%
  add_trace(x = ~ Uber, name = 'Uber', marker = list(color = 'black',opacity=0.7),
            line = list(color='black'),
            text = ~paste("Weekday:",wday, "<br>Marketshare for FHV taxi:",Uber,"%")) %>%
  layout(hovermode = 'compare',barmode = 'stack',title='Weekly marketshare for FHV types',
         yaxis = list(title = 'Marketshare', zeroline = FALSE),
         xaxis = list(title = 'Weekday', zeroline = FALSE, ticksuffix = '%'))

#==================================================================================================
#Weather effect
#==================================================================================================
#Load Trip records for different weather, that is rainy, snowy, rainy and snowy and sunny.
df_rain = fread("../Data/tables/df_rain.csv") %>% as.tibble()
df_snow_rain = fread("../Data/tables/df_snow_rain.csv") %>% as.tibble()
df_sunny = fread("../Data/tables/df_sunny.csv") %>% as.tibble()
df_snow = fread("../Data/tables/df_snow.csv") %>% as.tibble()

#Plot boxplot of trip durations for different weathers
plot_ly(type = 'box') %>%
  
  add_boxplot(x = df_rain$duration, name = "Rainy Days", fillcolor = 'rgba(254,231,37,0.4)',
              marker = list(color = 'rgba(219, 64, 82, 1.0)'),
              line = list(color = 'rgba(253,231,37,100)')) %>%
  
  add_boxplot(x = df_snow_rain$duration, name = "Snowy and Rainy Days",fillcolor = 'rgba(93,200,99,0.4)', marker = list(color = 'rgba(219, 64, 82, 1.0)'),
              line = list(color = 'rgba(93,200,99,100)')) %>%
  
  add_boxplot(x = df_sunny$duration, name = "Sunny Days", fillcolor = 'rgba(33,144,140,0.4)',
              marker = list(color = 'rgba(219, 64, 82, 1.0)'),
              line = list(color = 'rgba(33,144,140,100)')) %>%
  
  add_boxplot(x = df_snow$duration, name = "Snowy Days", fillcolor = 'rgba(59,82,39,0.4)',
              marker = list(color = 'rgba(219, 64, 82, 1.0)'),
              line = list(color = 'rgba(59,82,39,100)')) %>%
  
  layout(title = "Weather Effect on Trip Duration", hovermode = 'compare',
         yaxis = list(title = 'Weather',zeroline =T, showgrid = T),
         xaxis = list(title = 'Duration',zeroline = T, showgrid = T))

#Plot bar plot of trip counts for each weather.
plot_ly(type = 'bar') %>%
  add_bars(x = ~ 82545120, y= "Rainy Days",name = "Rainy Days", fillcolor = 'rgba(254,231,37,0.4)',
           marker = list(color = 'rgba(254,231,37,0.4)'),
           line = list(color = 'rgba(253,231,37,100)'),
           text = ~paste("weather:","Rainy Days","<br>Trip counts:",82545120)) %>%
  add_bars(x = ~5111354,   y= "Sleeting Days",
           name = "Sleeting Days", fillcolor ='rgba(93,200,99,0.4)',
           marker = list(color = 'rgba(93,200,99,0.4)'),
           line = list(color = 'rgba(93,200,99,100)'),
           text = ~ paste("weather:","Sleeting Days","<br>Trip counts:",5111354))%>%
  add_bars(x = ~ 111272091, y = "Sunny Days", name = "Sunny Days", fillcolor = 'rgba(33,144,140,0.4)',
           marker = list(color = 'rgba(33,144,140,0.4)'),
           line = list(color = 'rgba(33,144,140,100)'), 
           text = ~paste("weather:","Sunny Days","<br>Trip counts:",111272091)) %>%
  add_bars(x = ~437323, y= "Snowy Days", name = "Snowy Days", fillcolor = 'rgba(59,82,39,0.4)',
           marker = list(color = 'rgba(59,82,39,0.4)'),
           line = list(color = 'rgba(59,82,39,100)'),text = ~paste("weather:","Snowy Days","<br>Trip counts:",437323)) %>%
  layout(title = "Weather Effect on Trip Counts",
         yaxis = list(TITLE="Weather", zeroline = FALSE, showgrid = T),
         xaxis = list(title = 'Trip Counts', zeroline = F, showgrid = T))

#==================================================================================================
#Density plot of Trip Durations
#==================================================================================================
#Load data of sample
df = read.csv("../Data/original/sample duration.csv")

#Plot density plot of durations
density1 = density(df$value)
plot_ly(x = ~ density1$x, y = ~ density1$y, type = 'scatter', mode = 'lines', name = 'Fair cut', fill = 'tozeroy') %>%
  layout(title = "Density Plot for Trip Duration",
         xaxis = list(title = 'Duration'),
         yaxis = list(title = 'Density'))

#Plot density plot of log durations which is close to normal distribution.
density1 = density(log(df$value))
plot_ly(x = ~ density1$x, y = ~ density1$y, type = 'scatter', mode = 'lines', name = 'Fair cut', fill = 'tozeroy') %>%
  layout(title = "Density Plot for Transformated Trip Duration",
         xaxis = list(title = 'Log(Duration)'),
         yaxis = list(title = 'Density'))