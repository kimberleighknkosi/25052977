# Load_Netflix.R
# ---------------------------------------------------------------------------
# Loader for the Netflix titles data (Question 4). Two columns — genres and
# production_countries — are stored as Python-style string lists, e.g.
# "['crime', 'drama']". The loader parses those into proper R list-columns so
# the rest of the analysis can unnest them cleanly.
# ---------------------------------------------------------------------------

library(tidyverse)

#' Turn a Python-style list string into a character vector.
#' "['a', 'b']" -> c("a","b");  "[]" / "" -> character(0)
Parse_Pylist <- function(x) {
  x %>%
    str_remove_all("[\\[\\]']") %>%
    str_split(",\\s*") %>%
    map(~ str_trim(.x[.x != ""]))
}

#' Load Netflix titles, parse the list columns and tidy runtime.
Load_Netflix <- function(path = "../data/netflix/titles.rds") {
  read_rds(path) %>%
    mutate(
      genres_list    = Parse_Pylist(genres),
      countries_list = Parse_Pylist(production_countries),
      runtime        = as.numeric(runtime)
    )
}

#' One row per (title, genre).
Unnest_Genres <- function(df) {
  df %>% unnest_longer(genres_list, values_to = "genre") %>%
    filter(!is.na(genre), genre != "")
}

#' One row per (title, production country).
Unnest_Countries <- function(df) {
  df %>% unnest_longer(countries_list, values_to = "country") %>%
    filter(!is.na(country), country != "")
}
