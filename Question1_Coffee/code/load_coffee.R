# Load_Coffee.R
# ---------------------------------------------------------------------------
# Loader for the Coffee reviews data set (Question 1).
#
# Why a custom loader? The raw CSV stores its text with *typographic* (a.k.a.
# "smart") punctuation: curly quotes (" " ' '), en/em dashes (- -) and
# ellipses (...). These are valid UTF-8 but render as mojibake in Excel, which
# is exactly the "strange characters that do not display well" the brief warns
# about. We read the file as explicit UTF-8 and normalise that punctuation to
# plain ASCII, so both our keyword matching and the slide output stay clean.
# ---------------------------------------------------------------------------

library(tidyverse)

#' Normalise typographic punctuation to plain ASCII.
#'
#' @param x a character vector
#' @return the same vector with curly quotes, fancy dashes, ellipses and
#'   non-breaking spaces replaced by their plain-ASCII equivalents.
Normalise_Text <- function(x) {
  x %>%
    str_replace_all("[‘’‚‛′]", "'") %>%  # single quotes / prime
    str_replace_all("[“”„‟″]", '"') %>%  # double quotes / double prime
    str_replace_all("[–—−]", "-") %>%              # en dash, em dash, minus
    str_replace_all("…", "...") %>%                          # horizontal ellipsis
    str_replace_all("[   ]", " ") %>%              # non-breaking spaces
    str_squish()
}

#' Load and clean the Coffee reviews CSV.
#'
#' @param path path to Coffee.csv (default assumes render from the question
#'   folder, i.e. data lives one level up in ../data/).
#' @return a tibble with cleaned character columns, a parsed `review_date`
#'   (Date, from the "Nov-17" month-year strings) and `Cost_Per_100g` / `Rating`
#'   as numerics.
Load_Coffee <- function(path = "../data/Coffee/Coffee.csv") {
  readr::read_csv(
    path,
    show_col_types = FALSE,
    locale = readr::locale(encoding = "UTF-8")
  ) %>%
    # clean every text column in one pass
    mutate(across(where(is.character), Normalise_Text)) %>%
    mutate(
      Cost_Per_100g = as.numeric(Cost_Per_100g),
      Rating        = as.numeric(Rating),
      # "Nov-17" -> 2017-11-01 ; lubridate::my() parses month-year
      review_date   = lubridate::my(review_date)
    )
}
