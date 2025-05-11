# NBA Top Scorers App

## Overview
This application displays the top 25 NBA scorers by points per game (PPG) for any selected season. The app uses real-time data fetched from the NBA.com Stats API through the NBA_API Python package, integrated with R Shiny via the reticulate package.

![NBA Top Scorers App Screenshot](https://raw.githubusercontent.com/danedexF5/get_buckets/fc1aad99f5eb408abfb5f50e96afeafe927f36df/top_scorers_group.png)

## Features
- View the top 25 NBA scoring leaders by PPG for seasons from 1996-97 onwards
- Interactive visualization of scoring statistics
- Detailed player information including team, games played, and minutes per game
- Modern, responsive UI built with shinydashboard
- Data caching to improve performance and reduce API calls
- Downloadable results in CSV format

## Technical Details

### API Integration
The app integrates with the NBA.com Stats API using the following approach:

**Python NBA_API Package**: We use the `nba_api` Python package to access official NBA statistics directly from NBA.com's Stats API
   
Python code used through reticulate
   nba\_api.stats.endpoints.LeagueLeaders(
       season = "2022-23",`[]()`
       stat\_category\_abbreviation = "PTS",
       per\_mode48 = "PerGame",
       season\_type\_all\_star = "Regular Season"
   )

**Reticulate Integration**: The R package reticulate bridges R and Python, allowing seamless API access

# R code to call Python functions
league\_leaders <- nba_api$LeagueLeaders(
  season = season,
  stat\_category\_abbreviation = "PTS",
  per\_mode48 = "PerGame",
  season\_type\_all\_star = "Regular Season"
)

**Data Processing**: Raw API data is cleaned and formatted in R for display

# Process API response into a clean data frame
top\_scorers <- leaders\_df %>%
  filter(GP >= 20) %>%
  mutate(
    player\_name = PLAYER,
    team = TEAM,
    ppg = PTS,
    games\_played = GP,
    mpg = MIN
  ) %>%
  select(player\_name, team, ppg, games\_played, mpg) %>%
  arrange(desc(ppg)) %>%
  head(num\_players)

**Caching**: Results are cached to improve performance and reduce API calls

**App Structure**
The application is organized into modular components:

* main-app.r: Core Shiny application that defines the UI and server logic
* api-functions.r: Functions for making API calls and processing NBA data
* helper-functions.r: Utility functions for data formatting and visualization
* css-styles.css: Custom styling for the application
* js-scripts.js: Client-side JavaScript for enhanced interactivity
	
### Installation and Deployment
**Prerequisites**

* R 4.0.0 or higher
* Python 3.7 or higher

**Required R packages:**

install.packages(c("shiny", "shinydashboard", "DT", "dplyr", "plotly", "reticulate"))

**Required Python packages:**

pip install nba_api pandas

**Local Development**

- Clone this repository:

git clone https://github.com/yourusername/get\_buckets.git
cd get\_buckets

- Open the project in RStudio or your preferred R environment
- Run the app locally:

shiny::runApp()

###Deployment to shinyapps.io

- Install the rsconnect package if you haven't already:

install.packages("rsconnect")

- Set up your shinyapps.io account:

rsconnect::setAccountInfo(
  name = "YOUR\_ACCOUNT\_NAME",
  token = "YOUR\_TOKEN",
  secret = "YOUR\_SECRET"
)

- Deploy using the deployment script:

source("deploy\_nba\_api\_reticulate.R")

- The script will create an app directory and deploy it to shinyapps.io
- Visit your deployed app at https://yourusername.shinyapps.io/get\_buckets/

### Usage

1. Select a season from the dropdown menu
2. Click the "Get Top Scorers" button
3. View the top 25 scorers and their statistics
4. Explore the interactive visualization
5. Download the data as a CSV if needed

### Testing

Utilized Postman to test different endpoints and parameters. The below example returned a 200. Originally the ActiveFlag parameter was included but kept throwing an error so it was taken out.

**Example of headers used (required by NBA.com):**

Accept:application/json, text/plain, */*
Accept-Language:en-US,en;q=0.9
Host:stats.nba.com
Origin:https://www.nba.com
Referer:https://www.nba.com/
User-Agent:Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36
x-nba-stats-origin:stats
x-nba-stats-token:true

**Example of parameters used:**

LeagueID:00
PerMode:PerGame
Scope:S
Season:2022-23
SeasonType:Regular Season
StatCategory:PTS

### Acknowledgments

* NBA\_API for providing access to NBA.com Stats
* Shiny for the web application framework
* R reticulate for R-Python integration
* Claude for a heavy lift
* Wife for advice on R, Python, industry standards

**License**
This project is licensed under the MIT License - see the LICENSE file for details.

**Contact**

dane.dexheimer@gmail.com

Project Link: https://github.com/danedexF5/get_buckets


