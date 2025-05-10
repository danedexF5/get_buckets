# deploy_nba_api_reticulate.R - Using NBA_API through reticulate

# Create the app directory
app_dir <- file.path(path.expand("~"), "nba_api_reticulate")
if (dir.exists(app_dir)) {
  unlink(app_dir, recursive = TRUE)
}
dir.create(app_dir, recursive = TRUE)
dir.create(file.path(app_dir, "www"), recursive = TRUE)
dir.create(file.path(app_dir, "data", "cache"), recursive = TRUE)

# Create app.R file with NBA_API implementation
cat('
# NBA Top Scorers App - Using NBA_API through reticulate

# Load required packages
library(shiny)
library(shinydashboard)
library(DT)
library(dplyr)
library(plotly)
library(reticulate)

# Set up Python environment and install necessary packages
# This will run when the app starts up
tryCatch({
  # Initialize Python
  # Use the default Python installation
  use_python(Sys.which("python"), required = FALSE)
  
  # Install NBA API if not already installed
  if (!py_module_available("nba_api")) {
    py_install("nba_api", pip = TRUE)
  }
  
  # Import required Python modules
  nba_api <- import("nba_api.stats.endpoints")
  pd <- import("pandas")
}, error = function(e) {
  # If there\'s an error setting up Python, provide a fallback
  message("Error setting up Python: ", e$message)
})

# Function to get NBA top scorers using NBA_API
get_nba_top_scorers <- function(year, num_players = 25) {
  # Validate year
  year <- as.integer(year)
  current_year <- as.integer(format(Sys.Date(), "%Y"))
  if (is.na(year) || year < 1996 || year > current_year) {
    stop(paste0("Please provide a valid NBA season year between 1996 and ", current_year))
  }
  
  # Create season string in format used by NBA_API (e.g., "2022-23")
  season_start <- year - 1
  season_end <- substr(year, 3, 4)
  season <- paste0(season_start, "-", season_end)
  
  # Check cache first
  cache_dir <- "data/cache"
  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE)
  }
  
  cache_file <- file.path(cache_dir, paste0("top_scorers_", year, ".rds"))
  if (file.exists(cache_file)) {
    message("Loading cached data for season ", season)
    return(readRDS(cache_file))
  }
  
  withProgress(message = paste("Fetching data for", season, "season..."), {
    # Get league leaders data using NBA_API
    tryCatch({
      # Use reticulate to call Python NBA_API
      league_leaders <- nba_api$LeagueLeaders(
        season = season,
        stat_category_abbreviation = "PTS",
        per_mode48 = "PerGame",
        season_type_all_star = "Regular Season"
      )
      
      # Convert Python DataFrame to R data frame
      leaders_df <- py_to_r(league_leaders$get_data_frames()[[1]])
      
      if (nrow(leaders_df) == 0) {
        stop(paste("No data available for the", season, "season."))
      }
      
      # Process the data
      top_scorers <- leaders_df %>%
        filter(GP >= 20) %>%  # Minimum games for qualification
        mutate(
          player_name = PLAYER,
          team = TEAM,
          ppg = PTS,
          games_played = GP,
          mpg = MIN
        ) %>%
        select(player_name, team, ppg, games_played, mpg) %>%
        arrange(desc(ppg)) %>%
        head(num_players)
      
      # Save to cache
      saveRDS(top_scorers, cache_file)
      
      return(top_scorers)
    }, error = function(e) {
      stop(paste("Error fetching data:", e$message))
    })
  })
}

# Format results table
format_results_table <- function(data) {
  # Format the data
  formatted_data <- data %>%
    mutate(
      PPG = round(as.numeric(ppg), 1),
      `Games Played` = as.integer(games_played),
      `Minutes Per Game` = round(as.numeric(mpg), 1)
    ) %>%
    select(Player = player_name, Team = team, PPG, `Games Played`, `Minutes Per Game`)
  
  # Add rank numbers
  formatted_data <- formatted_data %>%
    mutate(Rank = row_number()) %>%
    select(Rank, everything())
  
  return(formatted_data)
}

# Generate a title for the results
generate_title <- function(year) {
  year_int <- as.integer(year)
  season_start <- year_int - 1
  season_end <- substr(year_int, 3, 4)
  season <- paste0(season_start, "-", season_end)
  
  return(paste0("Top 25 NBA Scoring Leaders (PPG) - ", season, " Season"))
}

# Define year range - focus on more recent seasons first
current_year <- as.integer(format(Sys.Date(), "%Y"))
recent_years <- (current_year-10):current_year  # Last 10 years
older_years <- 1996:(current_year-11)  # Earlier years

# UI Definition
ui <- dashboardPage(
  dashboardHeader(title = "NBA Top Scorers"),
  
  dashboardSidebar(
    # Use a select input with year groups for better UX
    selectInput("year", "Select Season Year:", 
                choices = list(
                  "Recent Seasons" = recent_years,
                  "Earlier Seasons" = older_years
                ),
                selected = 2022),
    helpText("Select the year when the season ended (e.g., 2022 for 2021-22 season)"),
    actionButton("submit", "Get Top Scorers", class = "btn-primary"),
    br(), br(),
    downloadButton("downloadData", "Download CSV", class = "btn-success"),
    br(), br(),
    actionButton("clearCache", "Clear Cache", class = "btn-warning"),
    
    # Add a note about data sources
    div(style = "padding: 15px;",
        h4("Data Source:"),
        p("This app fetches NBA scoring data directly from the official NBA.com Stats API."),
        p("Data is available for NBA seasons from 1996-97 onwards."),
        p(strong("Note:"), "Only real, accurate NBA data is displayed - no estimated data.")
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .box {box-shadow: 0 2px 5px rgba(0,0,0,0.1);}
        .skin-blue .main-header .logo {background-color: #2c3e50;}
        .skin-blue .main-header .navbar {background-color: #2c3e50;}
        .skin-blue .main-sidebar {background-color: #2c3e50;}
        .btn-primary {background-color: #e74c3c; border-color: #c0392b;}
        .btn-primary:hover {background-color: #c0392b; border-color: #962d22;}
        .btn-success {background-color: #18bc9c; border-color: #18bc9c;}
        .btn-success:hover {background-color: #128f76; border-color: #128f76;}
        .loading-spinner {margin: 20px auto; text-align: center;}
      "))
    ),
    
    fluidRow(
      box(
        width = 12,
        title = "NBA Scoring Leaders",
        status = "primary",
        solidHeader = TRUE,
        p("This application shows the top 25 NBA scorers by points per game (PPG) for any season since 1996-97."),
        p("Select a season from the dropdown and click \'Get Top Scorers\' to see the data."),
        p(strong("Data Policy:"), "This app uses only real NBA data from the official NBA.com Stats API.",
          "No estimated or fake data is ever shown.")
      )
    ),
    
    # Loading indicator
    conditionalPanel(
      condition = "input.submit > 0 && !output.dataLoaded",
      div(class = "loading-spinner",
          tags$img(src = "spinner.svg", width = "50px", height = "50px"),
          p("Loading data, please wait...")
      )
    ),
    
    # Results
    conditionalPanel(
      condition = "output.dataLoaded",
      fluidRow(
        box(
          width = 12,
          title = textOutput("resultsTitle"),
          status = "info",
          solidHeader = TRUE,
          DTOutput("resultsTable")
        )
      ),
      
      fluidRow(
        box(
          width = 12,
          title = "PPG Visualization",
          status = "primary",
          solidHeader = TRUE,
          plotlyOutput("ppgPlot", height = "500px")
        )
      )
    )
  )
)

# Server logic
server <- function(input, output, session) {
  # Reactive values
  values <- reactiveValues(
    data = NULL,
    formatted_data = NULL,
    loading = FALSE
  )
  
  # Flag for conditional panels
  output$dataLoaded <- reactive({
    return(!is.null(values$formatted_data))
  })
  outputOptions(output, "dataLoaded", suspendWhenHidden = FALSE)
  
  # Handle submit button
  observeEvent(input$submit, {
    values$loading <- TRUE
    values$data <- NULL
    values$formatted_data <- NULL
    
    withProgress(message = "Fetching data...", {
      tryCatch({
        # Get data from API - will error if data not available
        data <- get_nba_top_scorers(input$year)
        
        # Format data
        values$data <- data
        values$formatted_data <- format_results_table(data)
        values$loading <- FALSE
        
        # Show success message
        showNotification(paste("Successfully loaded data for the", input$year, "season."), 
                        type = "message")
      }, error = function(e) {
        # Clear loading state
        values$loading <- FALSE
        
        # Show detailed error message
        showNotification(paste("Error:", e$message), type = "error", duration = 15)
      })
    })
  })
  
  # Clear cache
  observeEvent(input$clearCache, {
    cache_dir <- "data/cache"
    if (dir.exists(cache_dir)) {
      cache_files <- list.files(cache_dir, full.names = TRUE)
      if (length(cache_files) > 0) {
        file.remove(cache_files)
        showNotification("Cache cleared successfully", type = "message")
      } else {
        showNotification("No cached data to clear", type = "message")
      }
    }
  })
  
  # Display results title
  output$resultsTitle <- renderText({
    req(values$formatted_data)
    generate_title(input$year)
  })
  
  # Display results table
  output$resultsTable <- renderDT({
    req(values$formatted_data)
    
    datatable(
      values$formatted_data,
      options = list(
        pageLength = 25,
        lengthChange = FALSE,
        searching = TRUE,
        columnDefs = list(
          list(className = "dt-center", targets = "_all")
        )
      ),
      rownames = FALSE,
      class = "cell-border stripe"
    )
  })
  
  # Create visualization
  output$ppgPlot <- renderPlotly({
    req(values$formatted_data)
    
    plot_data <- values$formatted_data %>%
      select(-Rank) %>%
      arrange(desc(PPG)) %>%
      head(25)
    
    plot_ly(
      data = plot_data,
      x = ~reorder(Player, PPG),
      y = ~PPG,
      type = "bar",
      marker = list(
        color = "rgba(58, 71, 80, 0.6)",
        line = list(color = "rgba(58, 71, 80, 1.0)", width = 1)
      ),
      hoverinfo = "text",
      text = ~paste(
        Player, "<br>",
        "Team:", Team, "<br>",
        "PPG:", PPG, "<br>",
        "Games:", `Games Played`
      )
    ) %>%
      layout(
        title = paste("Points Per Game -", input$year),
        xaxis = list(
          title = "",
          tickangle = -45
        ),
        yaxis = list(
          title = "Points Per Game (PPG)"
        ),
        margin = list(b = 120)
      )
  })
  
  # Download handler
  output$downloadData <- downloadHandler(
    filename = function() {
      year_int <- as.integer(input$year)
      season_start <- year_int - 1
      season_end <- substr(year_int, 3, 4)
      season <- paste0(season_start, "-", season_end)
      
      paste0("NBA_Top_Scorers_", season, ".csv")
    },
    content = function(file) {
      req(values$formatted_data)
      write.csv(values$formatted_data, file, row.names = FALSE)
    }
  )
}

# Create Shiny app
shinyApp(ui = ui, server = server)
', file = file.path(app_dir, "app.R"))

# Create spinner SVG
cat('<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100">
  <circle cx="50" cy="50" r="40" stroke="#2c3e50" stroke-width="8" fill="none" stroke-linecap="round">
    <animate attributeName="stroke-dasharray" dur="2s" repeatCount="indefinite" from="0 251.2" to="251.2 0" />
    <animate attributeName="stroke-dashoffset" dur="2s" repeatCount="indefinite" from="0" to="251.2" />
  </circle>
  <circle cx="50" cy="50" r="25" stroke="#18bc9c" stroke-width="5" fill="none" stroke-linecap="round">
    <animate attributeName="stroke-dasharray" dur="2s" repeatCount="indefinite" from="0 157" to="157 0" />
    <animate attributeName="stroke-dashoffset" dur="2s" repeatCount="indefinite" from="0" to="157" />
    <animateTransform attributeName="transform" type="rotate" from="0 50 50" to="360 50 50" dur="1s" repeatCount="indefinite" />
  </circle>
</svg>', file = file.path(app_dir, "www", "spinner.svg"))

# Show the app directory
cat("App created at:", app_dir, "\n")
cat("Files in app directory:\n")
print(list.files(app_dir, recursive = TRUE))

# Instructions for deployment
cat("\n\nInstructions for deployment:\n")
cat("1. This app requires Python and the nba_api package to be installed on the server\n")
cat("2. Before deploying, make sure you have Python and reticulate installed in R:\n")
cat("   install.packages('reticulate')\n")
cat("3. Install the nba_api Python package:\n")
cat("   reticulate::py_install('nba_api')\n")
cat("4. Deploy to shinyapps.io with the name 'get_buckets'\n\n")