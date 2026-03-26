# Internal helper functions (not exported)

#' Determine number of parallel workers, respecting R CMD check limits
#' @noRd
get_cores <- function() {
  chk <- tolower(Sys.getenv("_R_CHECK_LIMIT_CORES_", ""))
  if (nzchar(chk) && chk %in% c("true", "warn")) {
    return(2L)
  }
  max(parallel::detectCores() - 1L, 1L)
}

#' Calculate total model cost for a set of predictors
#'
#' Handles both a simple named numeric vector and a grouped list of costs.
#'
#' @param predictors Character vector of predictor names in the model.
#' @param cost_obj Either `NULL`, a named numeric vector, or a list of groups
#'   (each with `vars` and `cost` elements).
#'
#' @return A single numeric value representing the total cost.
#' @noRd
calculate_model_cost <- function(predictors, cost_obj) {
  if (is.null(cost_obj)) return(0)

  # Simple named vector
  if (is.atomic(cost_obj) && !is.list(cost_obj)) {
    if (length(cost_obj) == 1 && is.null(names(cost_obj))) {
      return(length(predictors) * cost_obj)
    }
    matched_costs <- cost_obj[match(predictors, names(cost_obj))]
    return(sum(matched_costs, na.rm = TRUE))
  }

  # Grouped list
  if (is.list(cost_obj)) {
    total <- 0
    for (group in cost_obj) {
      if (any(predictors %in% group$vars)) {
        total <- total + group$cost
      }
    }
    return(total)
  }

  0
}

#' Compute fold-level net benefit metrics (vectorised over thresholds)
#'
#' @param probs Numeric vector of predicted probabilities.
#' @param actual Binary (0/1) vector of true outcomes.
#' @param thresholds Numeric vector of decision thresholds.
#' @param model_cost Single numeric cost to subtract from net benefit.
#'
#' @return Numeric vector of cost-adjusted net benefits (one per threshold).
#' @noRd
compute_fold_metrics <- function(probs, actual, thresholds, model_cost) {
  n <- length(actual)
  pred_mat <- outer(probs, thresholds, ">=")
  TP <- colSums(pred_mat * actual)
  FP <- colSums(pred_mat * (1 - actual))
  exchange_rates <- thresholds / (1 - thresholds)
  NB_vec <- (TP / n) - (FP / n) * exchange_rates
  NB_vec - model_cost
}

#' Build term labels, optionally wrapping continuous variables in rcs()
#'
#' @param vars_subset Character vector of variable names.
#' @param data Data frame used to inspect variable types.
#' @param n_knots Number of knots for restricted cubic splines.
#'
#' @return Character vector of term labels suitable for a formula.
#' @noRd
get_term_labels <- function(vars_subset, data, n_knots) {
  vapply(vars_subset, function(v) {
    if (is.numeric(data[[v]]) && length(unique(data[[v]])) > 20) {
      paste0("rms::rcs(", v, ", ", n_knots, ")")
    } else {
      v
    }
  }, character(1))
}
