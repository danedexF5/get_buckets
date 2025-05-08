# NBA Top Scorers App: Get Buckets

This is a web application built with R and Shiny that allows users to explore the top NBA scorers (by points per game) for any season since 1946.

![NBA Top Scorers App Screenshot](app_screenshot.jpg)

## Features

- View the top 25 NBA scorers by points per game (PPG) for any season
- Interactive visualization of scoring distribution
- Download results as CSV
- Responsive design that works on desktop and mobile
- Data caching for improved performance

## Requirements

- R 4.0.0 or higher
- The following R packages:
  - shiny
  - shinydashboard
  - DT
  - dplyr
  - plotly
  - httr
  - jsonlite

## Installation

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/nba-stats-app.git
   cd nba-stats-app
   ```

2. Install the required R packages:
   ```R
   install.packages(c("shiny", "shinydashboard", "DT", "dplyr", "plotly", "httr", "jsonlite"))
   ```

3. Run the app:
   ```R
   shiny::runApp()
   ```

## Usage

1. Enter a year in the input field (1946 to present)
2. Click the "Get Top Scorers" button
3. View the results table and visualization
4. Download the data as CSV if needed

## API Information

This app uses the following APIs:
- Primary: balldontlie.io API (free, but with rate limits)
- Backup: NBA Stats API (unofficial)

Data is cached locally to respect API rate limits and improve performance.

## Project Structure

```
nba-stats-app/
│
├── R/
│   ├── app.R                # Main Shiny app
│   ├── api_functions.R      # Functions for API calls
│   └── helpers.R            # Helper functions
│
├── data/
│   └── cache/               # Cache directory for API responses
│
├── www/
│   ├── styles.css           # Custom CSS
│   ├── scripts.js           # Custom JavaScript
│   └── favicon.ico          # App icon
│
├── .gitignore               # Git ignore file
├── README.md                # This file
└── nba-stats-app.Rproj      # RStudio project file
```

## Deployment

This app can be deployed to:

- [shinyapps.io](https://www.shinyapps.io/): The easiest option for hosting Shiny apps
- Your own Shiny Server
- Docker container

### Deploying to shinyapps.io

1. Install the rsconnect package:
   ```R
   install.packages("rsconnect")
   ```

2. Set up your shinyapps.io account:
   ```R
   rsconnect::setAccountInfo(name="YOUR_ACCOUNT", token="YOUR_TOKEN", secret="YOUR_SECRET")
   ```

3. Deploy the app:
   ```R
   rsconnect::deployApp()
   ```

## Customization

- Change the color scheme by modifying `www/styles.css`
- Adjust the number of players displayed by modifying the `num_players` parameter in `R/api_functions.R`
- Add additional visualizations by editing the app.R file

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [balldontlie.io](https://www.balldontlie.io/) for providing the free NBA API
- The R and Shiny communities for their excellent packages
