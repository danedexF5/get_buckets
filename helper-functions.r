# helpers.R - Helper functions for the NBA Stats App

#' Format the results table for display
#'
#' @param data Data frame of player stats
#' @return Formatted data frame with adjusted column names and formatting
#' @export
format_results_table <- function(data) {
  require(dplyr)
  
  # Check if we're using balldontlie API format or NBA Stats API format
  if ("pts" %in% names(data)) {
    # balldontlie API format
    formatted_data <- data %>%
      mutate(
        PPG = round(pts, 1),
        `Games Played` = games_played,
        `Minutes Per Game` = round(as.numeric(min), 1)
      ) %>%
      select(Rank = row_number, Player = player_name, Team = team, PPG, `Games Played`, `Minutes Per Game`)
  } else {
    # NBA Stats API format
    formatted_data <- data %>%
      mutate(
        PPG = round(as.numeric(PPG), 1),
        `Games Played` = as.integer(GP),
        `Minutes Per Game` = round(as.numeric(MIN), 1)
      ) %>%
      select(Rank = row_number, Player = PLAYER, Team = TEAM, PPG, `Games Played`, `Minutes Per Game`)
  }
  
  # Add rank numbers
  formatted_data <- formatted_data %>%
    mutate(Rank = row_number()) %>%
    select(Rank, everything())
  
  return(formatted_data)
}

#' Validate the year input
#'
#' @param year The year to validate
#' @return TRUE if valid, otherwise an error message
#' @export
validate_year <- function(year) {
  # Convert to integer if possible
  year_int <- suppressWarnings(as.integer(year))
  
  # Current year for upper bound
  current_year <- as.integer(format(Sys.Date(), "%Y"))
  
  # Validate
  if (is.na(year_int)) {
    return("Please enter a valid year (numbers only)")
  } else if (year_int < 1946) {
    return("Please enter a year from 1946 onwards (first NBA season)")
  } else if (year_int > current_year) {
    return(paste0("Please enter a year up to ", current_year))
  }
  
  return(TRUE)
}

#' Generate a title for the results
#'
#' @param year The season end year
#' @return A formatted title string
#' @export
generate_title <- function(year) {
  year_int <- as.integer(year)
  season_start <- year_int - 1
  season_end <- substr(year_int, 3, 4)
  season <- paste0(season_start, "-", season_end)
  
  return(paste0("Top 25 NBA Scoring Leaders (PPG) - ", season, " Season"))
}

#' Generate CSV download data
#'
#' @param data The formatted data to download
#' @param year The season year
#' @return A list with filename and content
#' @export
prepare_download_data <- function(data, year) {
  year_int <- as.integer(year)
  season_start <- year_int - 1
  season_end <- substr(year_int, 3, 4)
  season <- paste0(season_start, "-", season_end)
  
  filename <- paste0("NBA_Top_Scorers_", season, ".csv")
  
  return(list(
    filename = filename,
    data = data
  ))
}