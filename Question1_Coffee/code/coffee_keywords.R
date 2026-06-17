# coffee_keywords.R
# ---------------------------------------------------------------------------
# Survey-keyword indicators for Question 1.
#
# The brief gives a word cloud of descriptors that Stellenbosch students used
# for their favourite local coffees. We treat those words as a proxy for "what
# locals like" and score each coffee by how many of them appear in its three
# expert review descriptions. A coffee / region / roaster that scores high on
# these AND rates well at a sensible price is what we recommend to the
# entrepreneur.
# ---------------------------------------------------------------------------

library(tidyverse)

# Descriptors read from the survey word cloud (Q1 brief, p.2). This is the one
# genuinely subjective input — tweak the list freely; you should be able to
# justify the choice in the deck.
survey_keywords <- c(
  "sweet", "chocolate", "cocoa", "aroma", "mouthfeel", "structure", "finish",
  "toned", "savory", "velvety", "syrupy", "tart", "zest", "balanced",
  "resonant", "rich", "crisp", "floral", "sandalwood", "frankincense",
  "delicate", "juicy", "bright", "spice", "fruit", "citrus", "honey", "plush"
)

#' Score each coffee by how many distinct survey keywords appear in its reviews.
#'
#' @param df       coffee tibble from Load_Coffee()
#' @param keywords character vector of descriptors to look for
#' @return df with two new columns:
#'   kw_hits    : number of *distinct* survey keywords found across desc_1..3
#'   kw_density : kw_hits / number of keywords (0..1)
Score_Keywords <- function(df, keywords = survey_keywords) {
  # one lowercased text blob per coffee from the three description columns
  blob <- str_to_lower(str_c(
    coalesce(df$desc_1, ""), " ",
    coalesce(df$desc_2, ""), " ",
    coalesce(df$desc_3, "")
  ))
  # whole-word match each keyword across all coffees, then sum the hits
  hit_matrix <- map(keywords, ~ str_detect(blob, str_c("\\b", .x, "\\b")))
  df %>% mutate(
    kw_hits    = reduce(hit_matrix, `+`),
    kw_density = kw_hits / length(keywords)
  )
}
