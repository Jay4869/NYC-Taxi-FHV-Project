# NYC Taxi & FHV Project

This repo provides the entire statistical analysis and machine learning pipeline, including data processing, comprehensive exploratory analysis, hypothesis testing to study the consumer behavior, traffic issue, weather effect, and predict the travel time of taxi and for-hire vehicle (Uber, Lyft, Via) trips between two points in New York City.

# Data

The [FHV trips data](https://www1.nyc.gov/site/tlc/about/tlc-trip-record-data.page) from the NYC Taxi & Limousine Commission totally contains about 400+ millions of taxi and for-hire vehicle (Uber, Lyft, Via) trips originating in New York City from **2018-01-01** to **2018-12-31**. Note: the taxi trips data is also stored in BigQuery, but FHV data is not completed.

The [NYC Taxi Zones map](https://data.cityofnewyork.us/Transportation/NYC-Taxi-Zones/d3c5-ddgc) is provided by TLC and published to NYC Open Data, which stores the information how Taxi zones are defined.

The [NYC Weather data](https://www.ncdc.noaa.gov/data-access) is provided by National Centers For Environmental Information, which contains hourly weather records such as temperature, precipitation, visibility, and wind.

Statistics:
  - 112+ million yellow taxi data (18.2 GB) 
  - 300+ million for-hire vehicle data (17.2 GB)
  - 365 daily weather records
  
Existing problem:
  - R reads entire data set into RAM all at once. Total 17.2 GB of raw data would not fit in local memory at once.
  - R Objects live in memory entirely, which cause slowness for data analysis.
  - The TLC publishes base trip record data as submitted by the bases, and we cannot guarantee or confirm their accuracy or completeness.

## Instructions

##### 1. Download FHV data

`./Import/download data.sh`

Using shell script to download FHV data from TLC website. Each month FHV trip data is about 1.3 GB, so it will take about 50-60 minutes to download.

##### 2. Import & Processing

`./Import/data processing.R`

Using R `data.table` to do ETL process takes about 20 minutes to do so.

##### 3. Create aggregation tables

`./Aggregation/aggregation.R`

Aggregate different time lines to understand the travel time pattern, which store in `./Data/tables` folder. 

##### 4. Visualization

`./Analysis/Visualization.R`

Generate the entire exploratory data analysis to understand the insight behind data.

`./ReportS/NYC Taxi & FHV Project - Exploratory.html`

The interactive map is made by CARTO, which show the taxi zones and market shares
https://zxf71699.carto.com/builder/62d8c815-2839-41fe-95e0-84ac6e4eccb6/embed (expired)

##### 5. Statistical Inference

`./Analysis/GR5291_Final_Project.Rmd`

Provide the statistical analysis and hypothesis testing on customer behavior, traffic and weather effect. 

`./ReportS/NYC Taxi & FHV Project - Inference .pdf`

##### 6. Machine Learning

Construct a machine learning pipeline in Python to combine multiple datasets, develop feature engineering, build regularized linear model and tree base models (RF, GBDT, XGBoost).

`./ReportS/NYC Taxi & FHV Project - Machine Learning.ipynb`

## Conclusion

* FHV data has about 90k missing value. Since we have very large dataset, removing missing value will be better idea.
* The trip exists a lot of outliers (duration <= 2 mins and >= 4 hours), so we need to investigate on the specific direction and time consumption to identify the possiblity.
* The duration is heavy skew, so we require **log** transformation to normal distribution for future modeling.
* In general, trip durations fluctuate all day and long trips happen at rush hour which makes sense. Interesting point is that longer trips happen in Thursday, it may be worth further investigation though. We also found trips with longer duration occurs in May and Oct when a larger number of vistors come to the city.
* Overall, Via ususally have longer duration because they offer a large number of shared ride and Uber seems has lowest trip durations. But in weekly base, Lyft generally takes more time for trips except weekend.
* It is obvious that Uber still dominate the FHV market. Via offer services in limitted areas compared to others. But it is interesting that Lyft shares less market during rush hour and weekdays. We guess that lots of Lyft drivers may be part-time and they may be out of service during weekdays or rush hour.
* Although distribution of trip durations is quite similar for these four weathers. The interesting point is that median of trip durations in sunny days are slightly larger than others.
