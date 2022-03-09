###---This script will demonstrate the use of Tidycensus in R----#
###---Created by C. Tulley, SPC for PA Geo Dev 2022--------------#

#Set & check the working directory
setwd("C:\\Users\\cathy\\Desktop\\GeoDev\\") #local dir
setwd("L:\\your\\network\\folder\\project\\") #network dir
getwd()

#Install the necessary libraries
install.packages("censusapi")
install.packages("data.table")
install.packages("dplyr")
install.packages("openxlsx")
install.packages("readr")
install.packages("rgdal")
install.packages("sf")
install.packages("tigris")
install.packages("tidycensus")

#Load the necessary libraries
library(censusapi) #explain why we are using this, too :)
library(data.table)
library(dplyr)
library(openxlsx)
library(readr)
library(rgdal)
library(sf)
library(tigris)
library(tidycensus)
options(tigris_use_cache = TRUE)

###Preliminary bits###

# Add API key to .Renviron
Sys.setenv(CENSUS_KEY="YOUR_CENSUS_KEY")

# Reload .Renviron
readRenviron("~/.Renviron")

# Check to see that the expected key is output in your R console
Sys.getenv("CENSUS_KEY")

#set API key for tidycensus
census_api_key("CENSUS_KEY", install = TRUE)

#Provides list of APIs - using 'censusapi'
apis <- listCensusApis()

#check ACS geography names in the API - using 'censusapi'
acs_geo <- listCensusMetadata(name = "acs/acs5", vintage = 2019, type = "geography")
head(acs_geo)

#check ACS vars from API - using 'tidycensus'
api_vars <- load_variables(2019,"acs5",cache=TRUE)

####Data bits####

#Create a list of variables to send to the API
vars <- c('B28002_001E','B28002_002E','B28002_003E', 'B28002_004E', 'B28002_005E', 'B28002_006E', 'B28002_007E','B28002_008E','B28002_009E',
          'B28002_010E','B28002_011E','B28002_012E')

#Download tidy ACS data for tracts
#
#Census tracts "generally have a population size between 1,200 and 8,000 people, 
#with an optimum size of 4,000 people." - US Census Bureau
#
data <- get_acs(
  geography = "tract", 
  variables = vars, 
  year = 2019,
  survey = "acs5",
  summary_var = NULL, 
  state = "PA", 
  #county = "Allegheny County",
  geometry = FALSE, #we just want the data right now - do not include the spatial version
  output = "wide") 

#check output
dim(data)
head(data)

##Write the output to a CSV
write.csv(data, "acsdata_pa_tracts.csv", row.names = FALSE)

#write the files to Excel
write.xlsx(data, file = "acsdata_pa_tracts.xlsx")

####GIS bits####

#load the 2019 Census TIGER tracts shapefile
pa_tracts <- readOGR(dsn=".", layer="tl_2019_42_tract", stringsAsFactors = FALSE)
#Tip: Factors are data structures that store categorical data as levels.

#Join the data frame to the shp
pa_tracts_join <- geo_join(pa_tracts, data, "GEOID", "GEOID", how = "left") 
#using the 'geo_join' function from the 'tigris' package
#join data TO tracts, not vice versa

#Write the output to a shapefile
writeOGR(pa_tracts_join, dsn=".",layer="pa_tracts_join", driver="ESRI Shapefile")

####Advanced GIS bits####

datageo <- get_acs(
  geography = "tract", 
  variables = "B28002_001", 
  year = 2019,
  survey = "acs5",
  summary_var = NULL, 
  state = "PA", 
  geometry = TRUE)#get the spatial data version

#Plot a quick map to check your data
plot(datageo["estimate"])
