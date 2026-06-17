# baby_names.R
# ---------------------------------------------------------------------------
# Analysis functions for Question 2 (US baby names, 1910-2014).
#
# The raw data has one row per (Name, Year, Gender, State). For national trends
# I first sum Count over states, so "n" below always means the US-wide count of
# a name in a given year.
# ---------------------------------------------------------------------------

library(tidyverse)

#' Collapse the state-level rows to national counts per name / year / gender.
National_Counts <- function(b) {
  b %>%
    group_by(Name, Year, Gender) %>%
    summarise(n = sum(Count), .groups = "drop")
}

#' Within each year and gender, rank names by national count (rank 1 = top name).
Add_Rank <- function(nat) {
  nat %>%
    group_by(Year, Gender) %>%
    mutate(rank = min_rank(desc(n))) %>%
    ungroup()
}

#' Persistence of popularity. For each year I take the top-`top` names per gender
#' and Spearman-correlate their ranks with the same names' ranks `lag` years on.
#' A high rho means this year's popular names are still ranked similarly later;
#' a falling rho over time would mean names churn faster than they used to.
Persistence_Series <- function(nat, top = 25, lag = 3) {
  r <- Add_Rank(nat)
  years <- sort(unique(r$Year))
  years <- years[years + lag <= max(years)]
  map_dfr(years, function(y) {
    map_dfr(c("F", "M"), function(g) {
      base   <- r %>% filter(Year == y,       Gender == g, rank <= top) %>%
                select(Name, base_rank = rank)
      future <- r %>% filter(Year == y + lag, Gender == g) %>%
                select(Name, future_rank = rank)
      m <- inner_join(base, future, by = "Name")
      if (nrow(m) < 5) return(tibble())
      tibble(Year = y, Gender = g,
             rho = suppressWarnings(cor(m$base_rank, m$future_rank,
                                        method = "spearman")))
    })
  })
}

#' The `n` most popular names across the whole period (used for the bubble plot).
Top_Names_Overall <- function(nat, n = 12) {
  nat %>%
    group_by(Name) %>%
    summarise(total = sum(n), .groups = "drop") %>%
    arrange(desc(total)) %>%
    slice_head(n = n) %>%
    pull(Name)
}

#' Bubble-plot data: total count per decade for a chosen set of names.
Bubble_Data <- function(nat, names) {
  nat %>%
    filter(Name %in% names) %>%
    mutate(Decade = (Year %/% 10) * 10) %>%
    group_by(Name, Decade) %>%
    summarise(n = sum(n), .groups = "drop")
}

#' Year-on-year surges: names whose national count at least tripled in a single
#' year off a non-trivial base. These sudden spikes are the ones that often line
#' up with a film, song or TV character.
Name_Surges <- function(nat, min_base = 500, factor = 3, n = 15) {
  nat %>%
    group_by(Name, Gender) %>%
    arrange(Year, .by_group = TRUE) %>%
    mutate(prev = lag(n), growth = n / prev) %>%
    ungroup() %>%
    filter(!is.na(prev), prev >= min_base, growth >= factor) %>%
    transmute(Name, Gender, Year, prev_count = prev, count = n,
              growth = round(growth, 1)) %>%
    arrange(desc(growth)) %>%
    slice_head(n = n)
}

# --- Cultural cross-reference (added for the brief's TV/music angle) ----------

#' First names that show up as HBO series character names. Used to highlight,
#' in the bubble plot, which popular names also belong to TV characters.
HBO_Character_Firstnames <- function(hbo_credits) {
  hbo_credits %>%
    filter(!is.na(character), character != "") %>%
    transmute(first = str_to_title(word(character, 1))) %>%
    distinct(first) %>%
    pull(first)
}

#' Annotate each surge with a plausible cultural cause: a Billboard artist whose
#' first name matches the surging baby name and who charted in the two years up
#' to the surge (e.g. the Mariah spike following Mariah Carey's chart debut).
Annotate_Surges <- function(surges, charts) {
  bb <- charts %>%
    mutate(chart_year = as.integer(format(date, "%Y")),
           name = str_to_lower(word(artist, 1))) %>%
    distinct(name, chart_year, artist)
  s <- surges %>% mutate(name = str_to_lower(Name))
  matches <- s %>%
    inner_join(bb, by = "name", relationship = "many-to-many") %>%
    filter(chart_year >= Year - 2, chart_year <= Year) %>%
    group_by(Name, Year) %>%
    summarise(billboard_artist = first(artist), .groups = "drop")
  s %>%
    left_join(matches, by = c("Name", "Year")) %>%
    select(-name) %>%
    arrange(desc(growth))
}
