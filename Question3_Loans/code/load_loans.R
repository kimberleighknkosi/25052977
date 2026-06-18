# Load_Loans.R
# ---------------------------------------------------------------------------
# Loader for the Lending Club loan data set (Question 3).
#
# The raw file is large (1,000,000 rows x 145 columns). For exploration and
# modelling we only need a focused set of columns, and we have to make one
# important analytical decision up front: what counts as a "default"?
#
# `loan_status` has seven values. Their outcomes:
#   Fully Paid          -> the loan finished, repaid     (default = FALSE)
#   Charged Off         -> the loan finished, written off (default = TRUE)
#   Default             -> formally in default            (default = TRUE)
#   Current             -> still being paid, outcome UNKNOWN
#   In Grace Period     -> just missed, outcome unknown   (early distress)
#   Late (16-30 days)   -> missed, outcome unknown        (early distress)
#   Late (31-120 days)  -> missed, recovery being chased  (partial default)
#
# DECISION (confirm or change with Kim): a clean default model only uses loans
# whose outcome is *settled* — i.e. Fully Paid vs Charged Off/Default. "Current"
# and the late/grace statuses are dropped from the default model because their
# final outcome is not yet known; including them would bias the default rate.
# We keep a separate `partial_default` flag for the "Collections / missed a
# payment" angle the brief mentions, so that can be analysed on its own.
# ---------------------------------------------------------------------------

library(tidyverse)

# Columns we actually use — the belief-relevant ones plus standard risk drivers.
.loan_keep_cols <- c(
  "id", "loan_amnt", "funded_amnt", "term", "int_rate", "installment",
  "grade", "sub_grade", "emp_length", "home_ownership", "annual_inc",
  "verification_status", "issue_d", "loan_status", "purpose", "addr_state",
  "dti", "delinq_2yrs", "fico_range_low", "fico_range_high", "open_acc",
  "pub_rec", "revol_util", "total_acc", "collections_12_mths_ex_med",
  "recoveries", "application_type"
)

#' Load and prepare the Lending Club loan data.
#'
#' @param path path to loan_data.rds.
#' @param sample_n optional integer; if given, draw a reproducible random sample
#'   of this many rows (the full set is 1M rows — sampling keeps exploration fast
#'   while staying representative). NULL = full data.
#' @param seed seed for the sample, so results reproduce.
#' @return a tibble of the kept columns with:
#'   * term_months    : 36 / 60 (numeric)
#'   * emp_10plus     : TRUE for "10+ years"
#'   * is_homeowner   : TRUE for OWN or MORTGAGE (vs RENT)
#'   * settled        : TRUE for Fully Paid / Charged Off / Default
#'   * default        : TRUE for Charged Off / Default, FALSE for Fully Paid,
#'                      NA for unsettled loans
#'   * partial_default: TRUE for the Late / In Grace Period statuses
Load_Loans <- function(path = "../data/Loan_Cred/loan_data.rds",
                       sample_n = NULL, seed = 42) {
  ln <- read_rds(path) %>%
    select(any_of(.loan_keep_cols))

  if (!is.null(sample_n)) {
    set.seed(seed)
    ln <- slice_sample(ln, n = min(sample_n, nrow(ln)))
  }

  ln %>%
    mutate(
      term_months = parse_number(term),
      emp_10plus  = emp_length == "10+ years",
      is_homeowner = home_ownership %in% c("OWN", "MORTGAGE"),
      settled = loan_status %in% c("Fully Paid", "Charged Off", "Default"),
      default = case_when(
        loan_status %in% c("Charged Off", "Default") ~ TRUE,
        loan_status == "Fully Paid"                   ~ FALSE,
        TRUE                                          ~ NA      # outcome unknown
      ),
      partial_default = loan_status %in% c(
        "Late (16-30 days)", "Late (31-120 days)", "In Grace Period"
      )
    )
}
