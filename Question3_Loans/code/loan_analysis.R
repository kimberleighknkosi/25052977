# loan_analysis.R
# ---------------------------------------------------------------------------
# Tests the three beliefs in the Q3 brief, on SETTLED loans only — i.e. loans
# whose outcome is known (Fully Paid vs Charged Off/Default). Unsettled loans
# (Current, Late, In Grace) are left out: their final outcome is not yet known,
# so counting them would bias the default rate. See Load_Loans.R for that split.
# ---------------------------------------------------------------------------

library(tidyverse)

#' Keep only settled loans, where `default` is a known TRUE/FALSE.
Settled_Loans <- function(df) df %>% filter(settled, !is.na(default))

#' Belief 1 — home owners and long-tenure (10+ yr) employees default less,
#' especially on short-term (36-month) loans. Default rate by the three splits.
Belief_Home_Tenure <- function(df) {
  Settled_Loans(df) %>%
    mutate(
      Term      = if_else(term_months == 36, "36m (short)", "60m (long)"),
      Homeowner = if_else(is_homeowner, "owner/mortgage", "renter/other"),
      Tenure    = if_else(emp_10plus, "10+ yrs", "<10 yrs / na")
    ) %>%
    group_by(Term, Homeowner, Tenure) %>%
    summarise(n = n(), default_rate = round(mean(default), 3), .groups = "drop") %>%
    arrange(Term, desc(default_rate))
}

#' Belief 2 — states differ in default "culture". Per-state default rate, with a
#' minimum-loans guard so a tiny state cannot top the table on noise.
Belief_State <- function(df, min_n = 200) {
  Settled_Loans(df) %>%
    group_by(State = addr_state) %>%
    summarise(n = n(), default_rate = round(mean(default), 3), .groups = "drop") %>%
    filter(n >= min_n) %>%
    arrange(desc(default_rate))
}

#' Belief 3 — credit grade and interest rate predict default. Default rate and
#' average rate per grade (A = best credit ... G = worst).
Belief_Grade <- function(df) {
  Settled_Loans(df) %>%
    group_by(Grade = grade) %>%
    summarise(
      n            = n(),
      default_rate = round(mean(default), 3),
      avg_int_rate = round(mean(int_rate, na.rm = TRUE), 2),
      .groups      = "drop"
    ) %>%
    arrange(Grade)
}

#' Quantify the drivers with a logistic regression, reported as odds ratios.
#' int_rate already encodes the grade (Lending Club sets the rate from the grade),
#' so we use int_rate as the continuous risk signal and leave grade out to avoid
#' collinearity. An odds ratio > 1 means the driver raises default odds.
Risk_Model <- function(df) {
  d <- Settled_Loans(df)
  m <- glm(default ~ int_rate + term_months + is_homeowner + emp_10plus,
           data = d, family = binomial)
  broom::tidy(m, exponentiate = TRUE, conf.int = TRUE) %>%
    transmute(
      driver     = term,
      odds_ratio = round(estimate, 3),
      ci_low     = round(conf.low, 3),
      ci_high    = round(conf.high, 3),
      p_value    = signif(p.value, 3)
    )
}

# --- Director's Step-2 questions ---------------------------------------------

#' Default rate by debt-to-income band — used to suggest a sensible DTI cap.
#' A cap makes sense where the default rate starts climbing sharply.
DTI_Default <- function(df) {
  Settled_Loans(df) %>%
    filter(!is.na(dti), dti >= 0, dti < 100) %>%
    mutate(dti_band = cut(dti, c(0, 10, 20, 30, 40, Inf), right = FALSE,
                          labels = c("0-10", "10-20", "20-30", "30-40", "40+"))) %>%
    group_by(dti_band) %>%
    summarise(n = n(), default_rate = round(mean(default), 3), .groups = "drop")
}

#' Same DTI-band default rates, but split Texas vs the rest of the US, so the
#' Director can see whether one hard-cap fits both or Texas needs its own.
DTI_Default_Texas <- function(df) {
  Settled_Loans(df) %>%
    filter(!is.na(dti), dti >= 0, dti < 100) %>%
    mutate(region   = if_else(addr_state == "TX", "Texas", "Rest of US"),
           dti_band = cut(dti, c(0, 10, 20, 30, 40, Inf), right = FALSE,
                          labels = c("0-10", "10-20", "20-30", "30-40", "40+"))) %>%
    group_by(region, dti_band) %>%
    summarise(default_rate = round(mean(default), 3), .groups = "drop") %>%
    pivot_wider(names_from = region, values_from = default_rate)
}

#' Is Texas different? Headline comparison of Texas vs the rest of the US.
Texas_Vs_Rest <- function(df) {
  Settled_Loans(df) %>%
    mutate(region = if_else(addr_state == "TX", "Texas", "Rest of US")) %>%
    group_by(region) %>%
    summarise(n = n(),
              default_rate = round(mean(default), 3),
              avg_dti      = round(mean(dti, na.rm = TRUE), 1),
              avg_int_rate = round(mean(int_rate, na.rm = TRUE), 1),
              .groups = "drop")
}
