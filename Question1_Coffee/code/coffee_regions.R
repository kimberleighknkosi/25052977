# coffee_regions.R
# ---------------------------------------------------------------------------
# Origin-region and roaster/supplier summaries for Question 1.
#
# Both summaries use a minimum-reviews guard (min_n): a region or roaster with
# one lucky 95-point review should not outrank one with 40 solid reviews. This
# is a standard "enough evidence to trust the average" filter — adjust min_n if
# the entrepreneur wants to consider niche suppliers.
# ---------------------------------------------------------------------------

library(tidyverse)

#' Average quality / cost / keyword-fit by origin region.
#'
#' @param df    scored coffee tibble (needs kw_density from Score_Keywords())
#' @param min_n minimum reviews for a region to qualify
#' @return one row per region, sorted by average rating (best first)
Region_Summary <- function(df, min_n = 10) {
  df %>%
    filter(!is.na(origin_1), !is.na(Rating)) %>%
    group_by(Region = origin_1) %>%
    summarise(
      n          = n(),
      avg_rating = round(mean(Rating, na.rm = TRUE), 2),
      avg_cost   = round(mean(Cost_Per_100g, na.rm = TRUE), 2),
      avg_kw     = round(mean(kw_density, na.rm = TRUE), 3),
      .groups    = "drop"
    ) %>%
    filter(n >= min_n) %>%
    arrange(desc(avg_rating))
}

#' Average quality / cost by roaster (supplier), same evidence guard.
Roaster_Summary <- function(df, min_n = 5) {
  df %>%
    filter(!is.na(roaster), !is.na(Rating)) %>%
    group_by(Roaster = roaster) %>%
    summarise(
      n          = n(),
      avg_rating = round(mean(Rating, na.rm = TRUE), 2),
      avg_cost   = round(mean(Cost_Per_100g, na.rm = TRUE), 2),
      .groups    = "drop"
    ) %>%
    filter(n >= min_n) %>%
    arrange(desc(avg_rating))
}

#' The "good local" shortlist: coffees that match what locals like (high keyword
#' density) AND give good value, restricted to well-reviewed suppliers.
#'
#' @return a tidy table for the recommendation slide
Good_Local_Picks <- function(df, n = 8) {
  Add_Value(df) %>%                       # from coffee_value.R: value + filters
    filter(kw_hits >= 2) %>%              # mentions at least 2 survey descriptors
    arrange(desc(kw_density), desc(value)) %>%
    transmute(Coffee = name, Roaster = roaster, Country = loc_country,
              Rating, `Cost/100g` = Cost_Per_100g,
              Keywords = kw_hits, Value = round(value, 2)) %>%
    slice_head(n = n)
}

#' Average rating / cost / value by roast strength, ordered light -> dark.
#' Uses Add_Value() from coffee_value.R, so the value column is available.
Roast_Summary <- function(df, min_n = 5) {
  levels_ord <- c("Light", "Medium-Light", "Medium", "Medium-Dark", "Dark")
  Add_Value(df) %>%
    filter(!is.na(roast)) %>%
    group_by(Roast = factor(roast, levels = levels_ord)) %>%
    summarise(n = n(),
              avg_rating = round(mean(Rating, na.rm = TRUE), 2),
              avg_cost   = round(mean(Cost_Per_100g, na.rm = TRUE), 2),
              avg_value  = round(mean(value, na.rm = TRUE), 2),
              .groups = "drop") %>%
    filter(n >= min_n) %>%
    arrange(Roast)
}
