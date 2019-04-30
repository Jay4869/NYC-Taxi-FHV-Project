# NYC-Taxi-FHV-Project

This repo provides scripts to download, process, analyze and comprehensive Exploratory Data Analysis for 300 millions of for-hire vehicle (Uber, Lyft, Via) trips originating in New York City from **2018-01-01** to **2018-12-31**. we focuse on trip counts and duration in New York competition with tidy R, ggplot2, and plotly. Most of the [raw data](https://www1.nyc.gov/site/tlc/about/tlc-trip-record-data.page) comes from the NYC Taxi & Limousine Commission. The NYC Taxi Zones map provided by TLC and published to NYC Open Data (https://data.cityofnewyork.us/Transportation/NYC-Taxi-Zones/d3c5-ddgc). The NYC Weather data is provided by National Centers For Environmental Information (https://www.ncdc.noaa.gov/data-access).

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

`./Analysis/visualization.R`

##### 5. Final Report

`./Final Project.nb.html`
