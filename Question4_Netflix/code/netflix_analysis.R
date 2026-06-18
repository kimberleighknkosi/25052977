# netflix_analysis.R
# ---------------------------------------------------------------------------
# Analysis for Question 4 (Netflix / IMDb). Covers what the brief asks for:
# what content sits on the platform by country and type, what genres dominate,
# how titles rate, how long movies run, and a light textual look at the
# descriptions to see which themes recur.
# ---------------------------------------------------------------------------

library(tidyverse)

#' Movie vs show split.
Type_Split <- function(df) df %>% count(type, name = "titles")

#' Top production countries by number of titles.
Country_Summary <- function(df, n = 10) {
  Unnest_Countries(df) %>% count(country, sort = TRUE, name = "titles") %>%
    slice_head(n = n)
}

#' Most common genres, with how well they rate on IMDb.
Genre_Summary <- function(df, n = 12) {
  Unnest_Genres(df) %>%
    group_by(genre) %>%
    summarise(titles = n(),
              avg_imdb = round(mean(imdb_score, na.rm = TRUE), 2),
              .groups = "drop") %>%
    arrange(desc(titles)) %>%
    slice_head(n = n)
}

#' IMDb rating summary by type (movies vs shows).
Ratings_By_Type <- function(df) {
  df %>% filter(!is.na(imdb_score)) %>%
    group_by(type) %>%
    summarise(n = n(),
              median_imdb = median(imdb_score),
              mean_imdb = round(mean(imdb_score), 2),
              .groups = "drop")
}

#' Movies only, with a sensible runtime, for the length analysis.
Movies_Runtime <- function(df) {
  df %>% filter(type == "MOVIE", !is.na(runtime), runtime >= 20, runtime <= 240)
}

#' Light textual analysis: the words that recur most in title descriptions,
#' after dropping very common English stop-words. A cheap way to see the themes
#' the platform leans on without pulling in extra packages.
Description_Words <- function(df, n = 20) {
  stop <- c("the","and","a","an","of","to","in","is","his","her","their","with",
            "for","on","as","who","when","that","this","from","by","at","he","she",
            "they","it","but","into","after","up","out","are","be","has","have",
            "was","were","will","not","about","over","than","them","its","one","two",
            "while","must","find","finds","get","gets","becomes","become","each")
  df %>%
    transmute(text = str_to_lower(replace_na(description, ""))) %>%
    mutate(word = str_extract_all(text, "[a-z]+")) %>%
    select(word) %>%
    unnest(word) %>%
    filter(!word %in% stop, str_length(word) > 3) %>%
    count(word, sort = TRUE) %>%
    slice_head(n = n)
}
