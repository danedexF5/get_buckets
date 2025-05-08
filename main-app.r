# app.R - Main Shiny application for NBA Stats

# Load required libraries
library(shiny)
library(shinydashboard)
library(DT)
library(dplyr)
library(plotly)
library(httr)
library(jsonlite)

# Source helper files
source("R/api_functions.R")
source("R/helpers.R")

# UI Definition
ui <- dashboardPage(
  # Header
  dashboardHeader(
    title = "NBA Top Scorers"
  ),
  
  # Sidebar
  dashboardSidebar(
    sidebarMenu(
      menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("About", tabName = "about", icon = icon("info-circle"))
    ),
    
    # Year input
    div(
      style = "padding: 20px;",
      numericInput(
        "year",
        "Enter NBA Season Year:",
        value = format(Sys.Date(), "%Y"),  # Default to current year
        min = 1946,
        max = as.integer(format(Sys.Date(), "%Y")),
        step = 1
      ),
      helpText("Enter the year when the season ended (e.g., 2023 for 2022-23 season)"),
      
      # Action button
      actionButton("submit", "Get Top Scorers", 
                  class = "btn-primary", 
                  style = "margin-top: 10px; width: 100%;")
    )
  ),
  
  # Body
  dashboardBody(
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")
    ),
    
    tabItems(
      # Dashboard tab
      tabItem(
        tabName = "dashboard",
        
        # Information box
        fluidRow(
          box(
            width = 12,
            title = "NBA Scoring Leaders",
            status = "primary",
            solidHeader = TRUE,
            p("This application shows the top 25 NBA scorers by points per game (PPG) for any season since 1946."),
            p("Enter a year and click 'Get Top Scorers' to see the data.")
          )
        ),
        
        # Results section (initially hidden)
        conditionalPanel(
          condition = "output.dataAvailable",
          fluidRow(
            box(
              width = 12,
              title = textOutput("resultsTitle"),
              status = "info",
              solidHeader = TRUE,
              
              # Download button
              downloadButton("downloadData", "Download CSV", 
                            class = "btn-success",
                            style = "margin-bottom: 10px;"),
              
              # Results table
              DTOutput("resultsTable"),
              
              # Loading message
              conditionalPanel(
                condition = "output.isLoading",
                div(
                  class = "loading-container",
                  img(src = "spinner.gif", class = "loading-spinner"),
                  p("Loading data, please wait...")
                )
              )
            )
          ),
          
          # Visualization
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
      ),
      
      # About tab
      tabItem(
        tabName = "about",
        fluidRow(
          box(
            width = 12,
            title = "About This App",
            status = "info",
            solidHeader = TRUE,
            
            h4("NBA Top Scorers App"),
            p("This application provides information about the top NBA scorers in points per game (PPG) for any season since the NBA began in 1946."),
            
            h4("Data Source"),
            p("The data is retrieved using the balldontlie.io API or the NBA Stats API."),
            p("Results are cached locally for faster retrieval on subsequent requests for the same season."),
            
            h4("App Features"),
            tags$ul(
              tags$li("View the top 25 NBA scorers by PPG for any season"),
              tags$li("Visualize the scoring distribution"),
              tags$li("Download results as CSV"),
              tags$li("Easy-to-use interface with real-time validation")
            ),
            
            h4("Developer Information"),
            p("This application was built with R and Shiny."),
            p("Code repository: ", a(href = "https://github.com/yourusername/nba-stats-app", "GitHub")),
            
            hr(),
            
            p(class = "text-muted", "Data is cached for performance reasons. To clear the cache, restart the application.")
          )
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
    loading = FALSE,
    error = NULL
  )
  
  # Validate year input
  observe({
    result <- validate_year(input$year)
    if (is.character(result)) {
      updateNumericInput(session, "year", value = format(Sys.Date(), "%Y"))
      showNotification(result, type = "error")
    }
  })
  
  # Flag for conditional panels
  output$dataAvailable <- reactive({
    return(!is.null(values$data))
  })
  outputOptions(output, "dataAvailable", suspendWhenHidden = FALSE)
  
  # Loading indicator
  output$isLoading <- reactive({
    return(values$loading)
  })
  outputOptions(output, "isLoading", suspendWhenHidden = FALSE)
  
  # Handle submit button click
  observeEvent(input$submit, {
    # Validate input
    validation <- validate_year(input$year)
    if (is.character(validation)) {
      showNotification(validation, type = "error")
      return()
    }
    
    # Set loading state
    values$loading <- TRUE
    values$error <- NULL
    
    # Try to get data
    tryCatch({
      # First try with balldontlie API
      data <- get_top_scorers_ppg(input$year)
      
      # If successful, format data
      values$data <- format_results_table(data)
      values$loading <- FALSE
    }, error = function(e) {
      # If first API fails, try NBA Stats API
      tryCatch({
        data <- get_top_scorers_nba_api(input$year)
        values$data <- format_results_table(data)
        values$loading <- FALSE
      }, error = function(e2) {
        # Both APIs failed
        values$loading <- FALSE
        values$error <- paste("Error retrieving data:", e2$message)
        showNotification(values$error, type = "error", duration = 10)
      })
    })
  })
  
  # Display results title
  output$resultsTitle <- renderText({
    if (!is.null(values$data)) {
      return(generate_title(input$year))
    }
    return("")
  })
  
  # Display results table
  output$resultsTable <- renderDT({
    req(values$data)
    
    datatable(
      values$data,
      options = list(
        pageLength = 25,
        lengthChange = FALSE,
        dom = 'tip',
        searching = FALSE,
        columnDefs = list(
          list(className = 'dt-center', targets = "_all")
        )
      ),
      rownames = FALSE,
      class = 'cell-border stripe'
    )
  })
  
  # Create visualization
  output$ppgPlot <- renderPlotly({
    req(values$data)
    
    # Get top 25 players for the plot
    plot_data <- values$data %>%
      arrange(desc(PPG)) %>%
      head(25)
    
    # Create bar plot
    p <- plot_ly(
      data = plot_data,
      x = ~reorder(Player, PPG),
      y = ~PPG,
      type = "bar",
      marker = list(
        color = 'rgba(58, 71, 80, 0.6)',
        line = list(color = 'rgba(58, 71, 80, 1.0)', width = 1)
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
    
    return(p)
  })
  
  # Download handler
  output$downloadData <- downloadHandler(
    filename = function() {
      dl_data <- prepare_download_data(values$data, input$year)
      return(dl_data$filename)
    },
    content = function(file) {
      dl_data <- prepare_download_data(values$data, input$year)
      write.csv(dl_data$data, file, row.names = FALSE)
    }
  )
}

# Run the application
shinyApp(ui = ui, server = server)