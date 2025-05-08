# NBA Stats App Structure

Here's how we'll structure our application:

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
├── README.md                # Project documentation
└── nba-stats-app.Rproj      # RStudio project file
```

This structure keeps our code organized with:
- R code separated into logical components
- A data directory for any cached results 
- Static assets for the frontend
- Project documentation and configuration files
