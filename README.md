# NYC Taxi & FHV Project

This repo provides scripts to download, data processing, comprehensive exploratory analysis, hypothesis testing and machine learning pipeline for 300 millions of taxi and for-hire vehicle (Uber, Lyft, Via) trips originating in New York City from **2018-01-01** to **2018-12-31**. We are focusing on the trip counts and duration in the different time windows to find out the data insights and user behavior. Most of the [raw data](https://www1.nyc.gov/site/tlc/about/tlc-trip-record-data.page) comes from the NYC Taxi & Limousine Commission. The [NYC Taxi Zones map](https://data.cityofnewyork.us/Transportation/NYC-Taxi-Zones/d3c5-ddgc) is provided by TLC and published to NYC Open Data . The [NYC Weather data](https://www.ncdc.noaa.gov/data-access) is provided by National Centers For Environmental Information.

The goal of this challenge is to process large data sets and to understand the duration of FHV in NYC based on features: trip location, pick-up, drop-off time, and weather effect. Also, we are interested in the difference betweeen three companies such as market shares, targeted customers, and business strategy. First of all, we analysis and visualize the original data, engineer new features, aggregate time-series variables to understand the data and pattern. Second, we compare three companies (Uber, Lyft, Via) over various time frame on trip amount and duration to analyze the market share and business strategy. Lastly, we add external NYC weather data to study how the weather impact on the trip duration and order requests in order to understand users behavior.

Statistics through December 31, 2018:

- 17.2 GB of raw data
- 200+ million for-hire vehicle total trips
- 365 daily weather records

## Instructions

##### 1. Download raw FHV data

`./Import/download data.sh`

Note: each raw data is about 1.3 GB, so it will take a while to download.

##### 2. Import & Processing

`./Import/data processing.R`

Note: ETL for half-year raw data takes about 20 minutes to do so.

##### 3. Create aggregation tables

`./Aggregation/aggregation.R`

Note: all tables for EDA have been stored in `./Data/tables` folder. 

##### 4. Visualization

`./Analysis/Visualization.R`

Note: all codes of visualizations have been stored `Visualization.R` except interactive map. The interactive map can be found at https://zxf71699.carto.com/builder/62d8c815-2839-41fe-95e0-84ac6e4eccb6/embed.

##### 5. Final Report

`./Final Project.nb.html`

## Conclusion

* FHV data has about 90k missing value. Since we have very large dataset, removing missing value will be better idea.
* The trip exists a lot of outliers (duration <= 2 mins and >= 4 hours), so we need to investigate on the specific direction and time consumption to identify the possiblity.
* The duration is heavy skew, so we require **log** transformation to normal distribution for future modeling.
* In general, trip durations fluctuate all day and long trips happen at rush hour which makes sense. Interesting point is that longer trips happen in Thursday, it may be worth further investigation though. We also found trips with longer duration occurs in May and Oct when a larger number of vistors come to the city.
* Overall, Via ususally have longer duration because they offer a large number of shared ride and Uber seems has lowest trip durations. But in weekly base, Lyft generally takes more time for trips except weekend.
* It is obvious that Uber still dominate the FHV market. Via offer services in limitted areas compared to others. But it is interesting that Lyft shares less market during rush hour and weekdays. We guess that lots of Lyft drivers may be part-time and they may be out of service during weekdays or rush hour.
* Although distribution of trip durations is quite similar for these four weathers. The interesting point is that median of trip durations in sunny days are slightly larger than others.
