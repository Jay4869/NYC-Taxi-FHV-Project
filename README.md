# NYC Taxi & FHV Project
###### Author: Jay Li, Frances Zhang

This repo provides the end-to-end statistical analysis and machine learning pipeline, including data processing, comprehensive exploratory analysis, hypothesis testing to study the consumer behavior, traffic, weather effect, and provide the most efficient commute plan in New York City by predicting the travel time of taxi and for-hire vehicle (Uber, Lyft, Via), given pick-up, drop-off location and time.

# Data

The [FHV trips data](https://www1.nyc.gov/site/tlc/about/tlc-trip-record-data.page) from the NYC Taxi & Limousine Commission totally contains about 400+ millions of taxi and for-hire vehicle (Uber, Lyft, Via) trips originating in New York City from **2018-01-01** to **2018-12-31**. Note: the taxi trips data is also stored in BigQuery, but FHV data is not completed.

The [NYC Taxi Zones map](https://data.cityofnewyork.us/Transportation/NYC-Taxi-Zones/d3c5-ddgc) is provided by TLC and published to NYC Open Data, which stores the information how Taxi zones are defined.

The [NYC Weather data](https://www.ncdc.noaa.gov/data-access) is provided by National Centers For Environmental Information, which contains hourly weather records such as temperature, precipitation, visibility, wind and snow depth.

Statistics:
  - 112+ million yellow taxi data (18 GB) 
  - 300+ million for-hire vehicle data (16 GB)
  - 365 daily weather records
  
Existing problem:
  - R reads entire data set into RAM all at once. Total 34 GB of raw data would not fit in local memory at once.
  - R Objects live in memory entirely, which cause slowness for data analysis.
  - The TLC publishes base trip record data as submitted by the bases, and we cannot guarantee or confirm their accuracy or completeness.

## Instructions

##### 1. Download FHV data

`./Import/download data.sh`

Using shell script to download FHV data from TLC website. Each month FHV trip data is about 1.3 GB, so it will take about 50-60 minutes to download the 12-month dataset.

##### 2. Import & Processing

`./Import/data processing.R`

Using high-performance version of base R's data.frame `data.table` and randomly sampling 5% of total data.

##### 3. Visualization

`./Analysis/NYC Taxi & FHV Project - Exploratory.Rmd`

Generate the entire [exploratory data analysis](https://jtr13.github.io/spring19/NYC_Taxi_Project.html) to understand the consumer behavior and market insights.

Also, the pdf version report is provided `./ReportS/NYC Taxi & FHV Project - Exploratory.pdf`

##### 5. Statistical Inference

`./Analysis/NYC Taxi & FHV Project - Inference.Rmd`

Provide the statistical analysis and hypothesis testing (ANOVA, Block tests) on customer behavior, traffic and weather effect. 

`./ReportS/NYC Taxi & FHV Project - Inference.pdf`

##### 6. Machine Learning

Construct a machine learning pipeline in Python to combine multiple datasets, develop feature engineering, build regularized linear model and tree base models (RF, GBDT, XGBoost).

`./ReportS/NYC Taxi & FHV Project - Machine Learning.ipynb`

## Conclusion

* The trip exists a lot of outliers (duration <= 2 mins and >= 5 hours), so we need to investigate on the specific direction and time consumption to identify the possiblity.
* The travel time is heavy positive skew, so **Log** transformation to normal distribution might help for future modeling.
* In general, travel time is highly depended on the travel distance, direction and rush hour. We also found trips with longer duration occurs in May and Oct when a larger number of vistors come to the city.
* Via has significantly longer travel time than other FHV companies because Via only offer poolling strategy in order to increase ETA for each trip. However, Uber usually has lowest travel time might because of different route planning. 
* It is obvious that Uber still dominate the FHV market. Via offer services in limitted areas compared to others. But it is interesting that Lyft shares less market during rush hour and weekdays. We guess that lots of Lyft drivers may be part-time and they may be out of service during weekdays or rush hour.
* Even the distribution of travel time is quite similar for these four weathers, it still shows the seaonality due to the season changes.
* The hypothesis analysis shows that the rush hour(7-10 AM, 4-7 AM) during weekdays is the major effect on travel time, taking 36 minutes to LGA, 56 minutes to JFK, which are 34% longer than traveling during the weekends.
