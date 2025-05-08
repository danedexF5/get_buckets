# api_functions.R - Functions for interacting with basketball stats APIs

#' Fetch NBA top scorers by points per game for a specific season
#'
#' @param year Integer. The year of the NBA season end (e.g., 2023 for 2022-23 season)
#' @param num_players Integer. Number of top players to return (default: 25)
#' @return A data frame containing the top scorers ordered by PPG
#' @export
get_top_scorers_ppg <- function(year, num_players = 25) {
  require(httr)
  require(jsonlite)
  require(dplyr)
  
  # Handle input validation
  year <- as.integer(year)
  if (is.na(year) || year < 1946 || year > as.integer(format(Sys.Date(), "%Y"))) {
    stop("Please provide a valid NBA season year between 1946 and the current year")
  }
  
  # Create season string in format used by the API (e.g., "2022-23")
  season_start <- year - 1
  season_end <- substr(year, 3, 4)
  season <- paste0(season_start, "-", season_end)
  
  # Check cache first
  cache_file <- file.path("data", "cache", paste0("top_scorers_", year, ".rds"))
  if (file.exists(cache_file)) {
    message("Loading cached data for season ", season)
    return(readRDS(cache_file))
  }
  
  # API endpoint for NBA stats
  # Using the balldontlie.io API which provides free NBA statistics
  base_url <- "https://www.balldontlie.io/api/v1/season_averages"
  
  # First, we need to get player IDs
  # For this example, we'll get all players and then filter by ppg
  # In a real app, you might need to implement pagination or additional filtering
  
  # Get players
  players_url <- "https://www.balldontlie.io/api/v1/players"
  players_response <- GET(players_url, query = list(per_page = 100))
  
  if (status_code(players_response) != 200) {
    stop("API request failed with status: ", status_code(players_response))
  }
  
  players_data <- fromJSON(content(players_response, "text", encoding = "UTF-8"))
  all_players <- players_data$data
  
  # For each player, get season averages
  all_stats <- data.frame()
  
  # In a real app, you'd need to handle the API rate limits and pagination
  # This is simplified for demonstration purposes
  for (player_id in all_players$id) {
    stats_response <- GET(base_url, query = list(
      season = season_start,
      player_ids[] = player_id
    ))
    
    if (status_code(stats_response) == 200) {
      stats_data <- fromJSON(content(stats_response, "text", encoding = "UTF-8"))
      if (length(stats_data$data) > 0) {
        all_stats <- rbind(all_stats, stats_data$data)
      }
    }
    
    # Add a small delay to respect API rate limits
    Sys.sleep(0.5)
  }
  
  # Process and filter the data
  if (nrow(all_stats) > 0) {
    # Join with player names
    all_stats <- all_stats %>%
      left_join(all_players %>% select(id, first_name, last_name), 
                by = c("player_id" = "id"))
    
    # Create full name column
    all_stats$player_name <- paste(all_stats$first_name, all_stats$last_name)
    
    # Filter by games played to ensure statistical significance
    # Only include players who played at least 58 games (70% of regular season)
    filtered_stats <- all_stats %>%
      filter(games_played >= 58) %>%
      select(player_name, team = team.full_name, pts, games_played, min) %>%
      arrange(desc(pts)) %>%
      head(num_players)
    
    # Save to cache
    if (!dir.exists(file.path("data", "cache"))) {
      dir.create(file.path("data", "cache"), recursive = TRUE)
    }
    saveRDS(filtered_stats, cache_file)
    
    return(filtered_stats)
  } else {
    stop("No data found for the requested season")
  }
}

#' Alternative implementation using the NBA Stats API
#' This is a fallback method if balldontlie.io API doesn't work
#'
#' @param year Integer. The year of the NBA season end (e.g., 2023 for 2022-23 season)
#' @param num_players Integer. Number of top players to return (default: 25)
#' @return A data frame containing the top scorers ordered by PPG
#' @export
get_top_scorers_nba_api <- function(year, num_players = 25) {
  require(httr)
  require(jsonlite)
  require(dplyr)
  
  # Handle input validation
  year <- as.integer(year)
  if (is.na(year) || year < 1946 || year > as.integer(format(Sys.Date(), "%Y"))) {
    stop("Please provide a valid NBA season year between 1946 and the current year")
  }
  
  # Create season string in format used by the API (e.g., "2022-23")
  season_start <- year - 1
  season_end <- substr(year, 3, 4)
  season <- paste0(season_start, "-", season_end)
  
  # Check cache first
  cache_file <- file.path("data", "cache", paste0("top_scorers_", year, ".rds"))
  if (file.exists(cache_file)) {
    message("Loading cached data for season ", season)
    return(readRDS(cache_file))
  }
  
  # NBA Stats API endpoint (this is an unofficial API and may require additional headers)
  url <- "https://stats.nba.com/stats/leagueleaders"
  
  # Headers to mimic a browser request (needed for NBA.com endpoints)
  headers <- c(
    "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
    "Referer" = "https://www.nba.com",
    "Accept-Language" = "en-US,en;q=0.9"
  )
  
  # Parameters for the API request
  params <- list(
    LeagueID = "00",         # 00 is the NBA
    PerMode = "PerGame",     # Stats per game
    Scope = "RS",            # Regular Season
    Season = season,
    SeasonType = "Regular Season",
    StatCategory = "PTS"     # Points
  )
  
  # Make the API request
  response <- RETRY("GET", url, 
                   query = params,
                   add_headers(.headers = headers),
                   times = 3)
  
  if (status_code(response) != 200) {
    stop("API request failed with status: ", status_code(response))
  }
  
  # Parse the response
  data <- fromJSON(content(response, "text", encoding = "UTF-8"))
  
  # Extract column names and data
  col_names <- unlist(data$resultSet$headers)
  player_stats <- as.data.frame(data$resultSet$rowSet)
  
  # Set column names
  names(player_stats) <- col_names
  
  # Process data
  top_scorers <- player_stats %>%
    select(PLAYER = PLAYER_NAME, TEAM = TEAM_ABBREVIATION, PPG = PTS, GP = GP, MIN = MIN) %>%
    head(num_players)
  
  # Save to cache
  if (!dir.exists(file.path("data", "cache"))) {
    dir.create(file.path("data", "cache"), recursive = TRUE)
  }
  saveRDS(top_scorers, cache_file)
  
  return(top_scorers)
}

#' Clear the cache for a specific year or all years
#'
#' @param year Integer or NULL. If provided, clear cache for specific year, otherwise clear all
#' @export
clear_cache <- function(year = NULL) {
  if (is.null(year)) {
    # Clear all cache files
    cache_files <- list.files(file.path("data", "cache"), full.names = TRUE)
    file.remove(cache_files)
    message("Cleared all cached data")
  } else {
    # Clear cache for specific year
    cache_file <- file.path("data", "cache", paste0("top_scorers_", year, ".rds"))
    if (file.exists(cache_file)) {
      file.remove(cache_file)
      message("Cleared cached data for year ", year)
    } else {
      message("No cached data found for year ", year)
    }
  }
}