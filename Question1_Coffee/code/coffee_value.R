# coffee_value.R
# ---------------------------------------------------------------------------
# Value analysis for Question 1: is a pricier coffee actually rated better, and
# which coffees give the most rating per unit cost?
#
# "Value" here = Rating / Cost_Per_100g  — rating points per unit of cost. It is
# a simple, defensible proxy for quality-for-money: a coffee that rates well AND
# is cheap scores high. This is the one modelling CHOICE in Q1 value — it is easy
# to explain in the deck and easy to swap (e.g. for a rank-based score) if asked.
# ---------------------------------------------------------------------------

library(tidyverse)

#' Add a value score (rating per unit cost) and keep only ratable, priced rows.
#'
#' @param df coffee tibble from Load_Coffee()
#' @return df filtered to rows with a Rating and a positive Cost, with a new
#'   numeric `value` column (Rating / Cost_Per_100g), sorted best-value first.
Add_Value <- function(df) {
  df %>%
    filter(!is.na(Rating), !is.na(Cost_Per_100g), Cost_Per_100g > 0) %>%
    mutate(value = Rating / Cost_Per_100g) %>%
    arrange(desc(value))
}

#' Top-n best-value coffees, as a tidy table ready for a slide.
#'
#' @param df coffee tibble (raw or already value-scored)
#' @param n  how many rows to show
Top_Value <- function(df, n = 10) {
  Add_Value(df) %>%
    transmute(
      Coffee  = name,
      Roaster = roaster,
      Country = loc_country,
      Rating,
      `Cost/100g` = Cost_Per_100g,
      Value   = round(value, 2)
    ) %>%
    slice_head(n = n)
}

#' Does paying more buy a better rating? Spearman correlation (robust to scale).
#'
#' @param df coffee tibble from Load_Coffee()
#' @return a one-row tibble: correlation estimate + p-value.
Price_Quality_Cor <- function(df) {
  d <- Add_Value(df)
  ct <- suppressWarnings(cor.test(d$Cost_Per_100g, d$Rating, method = "spearman"))
  tibble(rho = unname(round(ct$estimate, 3)), p_value = signif(ct$p.value, 3))
}
