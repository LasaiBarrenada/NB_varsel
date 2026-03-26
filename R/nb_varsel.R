#' Variable Selection via Cross-Validated Net Benefit
#'
#' Performs exhaustive or groupwise (backward elimination) variable selection
#' for binary outcome prediction models. Models are evaluated using
#' cross-validated Net Benefit, optionally adjusted for predictor costs.
#'
#' @param data A data frame containing predictors and the outcome variable.
#' @param outcome_var Character string naming the binary outcome column
#'   (coded 0/1 or as a two-level factor).
#' @param costs Predictor costs. Can be:
#'   - `NULL` (default): no costs.
#'   - A named numeric vector: per-predictor costs (e.g.,
#'     `c(X1 = 0.1, X2 = 0.05)`).
#'   - An unnamed scalar: same cost applied to every predictor.
#'   - A list of groups, each with elements `vars` (character vector) and
#'     `cost` (numeric). The group cost is added once if *any* of its
#'     variables are included.
#' @param thresholds Numeric vector of decision thresholds at which to
#'   compute Net Benefit. Defaults to `seq(0.05, 0.3, by = 0.01)`.
#' @param include_interactions Logical. If `TRUE`, models with interaction
#'   terms (`(X1 + X2 + ...)^2`) are also evaluated (exhaustive mode only).
#'   Defaults to `FALSE`.
#' @param mode Either `"exhaustive"` (evaluate all predictor combinations)
#'   or `"groupwise"` (backward elimination removing `group_size` variables
#'   at a time). Defaults to `"exhaustive"`.
#' @param group_size Integer. Number of variables to consider removing in
#'   each step of groupwise mode. Defaults to 2.
#' @param cv_folds Integer. Number of cross-validation folds. Defaults to 5.
#' @param seed Integer. Random seed for reproducibility. Defaults to 123.
#' @param verbose Logical. Print progress messages. Defaults to `TRUE`.
#' @param allow_parallel Logical. Use parallel computing via
#'   [foreach::foreach()] and [doParallel::registerDoParallel()]. Defaults
#'   to `TRUE`.
#' @param permutation Logical. Compute permutation importance scores for
#'   each predictor. Defaults to `FALSE`.
#' @param splines Logical. Apply restricted cubic splines (via
#'   [rms::rcs()]) to continuous predictors. Defaults to `TRUE`.
#' @param n_knots Integer. Number of knots for restricted cubic splines.
#'   Defaults to 3.
#'
#' @return A list with two elements:
#' \describe{
#'   \item{best_model_stats}{A one-row data frame describing the
#'     top-performing model.}
#'   \item{all_models}{A data frame with one row per evaluated model,
#'     containing columns `Model`, `n_Preds`, `AUC`, `Brier`,
#'     `Total_Cost`, `Avg_Adj_Net_Benefit`, `Avg_Net_Benefit`, and
#'     (if `permutation = TRUE`) `VIF_*` columns for each predictor.}
#' }
#'
#' @examples
#' \dontrun{
#' set.seed(42)
#' n <- 500
#' df <- data.frame(
#'   X1 = rnorm(n), X2 = rbinom(n, 1, 0.7),
#'   X3 = rnorm(n), X4 = rbinom(n, 1, 0.5)
#' )
#' df$Y <- rbinom(n, 1, plogis(2 * df$X1 + 1.5 * df$X2))
#'
#' harms <- c(X1 = 0.1, X2 = 0.05, X3 = 0.1, X4 = 0.0001)
#'
#' result <- nb_varsel(
#'   data = df, outcome_var = "Y", costs = harms,
#'   mode = "exhaustive", splines = FALSE,
#'   allow_parallel = FALSE
#' )
#' result$best_model_stats
#' }
#'
#' @export
nb_varsel <- function(
    data,
    outcome_var,
    costs = NULL,
    thresholds = seq(0.05, 0.3, by = 0.01),
    include_interactions = FALSE,
    mode = c("exhaustive", "groupwise"),
    group_size = 2,
    cv_folds = 5,
    seed = 123,
    verbose = TRUE,
    allow_parallel = TRUE,
    permutation = FALSE,
    splines = TRUE,
    n_knots = 3
) {
  mode <- match.arg(mode)

  # --- 1. Data Prep ---
  if (is.factor(data[[outcome_var]])) {
    y_numeric <- as.numeric(data[[outcome_var]]) - 1
  } else {
    y_numeric <- data[[outcome_var]]
  }

  if (!all(unique(y_numeric) %in% c(0, 1))) {
    stop("Outcome must be binary (0/1).")
  }

  data[[outcome_var]] <- y_numeric
  all_predictors <- setdiff(names(data), outcome_var)

  # --- 2. Core CV Engine (closure over shared state) ---
  run_model_cv <- function(vars, explicit_formula = NULL, label_suffix = "") {
    if (length(vars) == 0) return(NULL)

    if (!is.null(explicit_formula)) {
      fmla <- stats::as.formula(explicit_formula)
    } else if (splines) {
      term_labels <- get_term_labels(vars, data, n_knots)
      fmla <- stats::reformulate(termlabels = term_labels, response = outcome_var)
    } else {
      fmla <- paste(outcome_var, "~", paste(vars, collapse = " + "))
    }

    total_cost <- calculate_model_cost(vars, costs)

    set.seed(seed)
    fold_ids <- caret::createFolds(y_numeric, k = cv_folds, returnTrain = FALSE)

    fold_results <- matrix(NA, nrow = cv_folds, ncol = length(thresholds))
    if (permutation) {
      fold_results_perm <- replicate(
        length(vars),
        matrix(NA, nrow = cv_folds, ncol = length(thresholds)),
        simplify = FALSE
      )
      names(fold_results_perm) <- vars
    }
    aucs <- numeric(cv_folds)
    briers <- numeric(cv_folds)

    for (i in seq_along(fold_ids)) {
      val_idx <- fold_ids[[i]]
      train_data <- data[-val_idx, ]
      val_data <- data[val_idx, ]
      val_y <- y_numeric[val_idx]

      model <- suppressWarnings(
        stats::glm(fmla, data = train_data, family = stats::binomial)
      )
      val_probs <- suppressWarnings(
        stats::predict(model, newdata = val_data, type = "response")
      )

      fold_results[i, ] <- compute_fold_metrics(
        val_probs, val_y, thresholds, total_cost
      )

      if (length(unique(val_y)) > 1) {
        aucs[i] <- suppressMessages(
          as.numeric(pROC::auc(val_y, val_probs))
        )
      } else {
        aucs[i] <- NA
      }
      briers[i] <- DescTools::BrierScore(val_y, val_probs)

      if (permutation) {
        for (predictor in vars) {
          val_data_perm <- val_data
          val_data_perm[[predictor]] <- sample(val_data_perm[[predictor]])
          val_probs_perm <- suppressWarnings(
            stats::predict(model, newdata = val_data_perm, type = "response")
          )
          fold_results_perm[[predictor]][i, ] <- compute_fold_metrics(
            val_probs_perm, val_y, thresholds, total_cost
          )
        }
      }
    }

    mean_nb_per_threshold <- colMeans(fold_results)
    avg_nb_scalar <- mean(mean_nb_per_threshold)

    importance_df <- NULL
    if (permutation) {
      perm_importance <- vapply(vars, function(predictor) {
        mean_nb_perm <- colMeans(fold_results_perm[[predictor]])
        avg_nb_perm_scalar <- mean(mean_nb_perm)
        avg_nb_scalar - avg_nb_perm_scalar
      }, numeric(1))
      importance_df <- data.frame(
        Predictor = vars,
        Importance = perm_importance
      )
      importance_df <- importance_df[order(-importance_df$Importance), ]
    }

    list(
      predictors = vars,
      model_name = paste0(paste(vars, collapse = ", "), label_suffix),
      avg_nb = avg_nb_scalar,
      total_cost = total_cost,
      auc = mean(aucs),
      brier = mean(briers),
      importance = importance_df
    )
  }

  # --- 3. Execution Logic ---
  results_list <- list()

  if (mode == "exhaustive") {
    all_combos <- unlist(
      lapply(
        seq_along(all_predictors),
        function(m) utils::combn(all_predictors, m, simplify = FALSE)
      ),
      recursive = FALSE
    )

    total_ops <- length(all_combos)
    if (include_interactions) {
      total_ops <- total_ops + sum(vapply(all_combos, length, integer(1)) > 1)
    }

    if (verbose) {
      message(
        sprintf("Starting Exhaustive Search: %d configurations...", total_ops)
      )
    }

    process_combo <- function(vars) {
      batch_results <- list()
      if (splines) {
        fmla_add <- NULL
      } else {
        fmla_add <- paste(outcome_var, "~", paste(vars, collapse = " + "))
      }

      batch_results[[1]] <- run_model_cv(vars, explicit_formula = fmla_add)

      if (include_interactions && length(vars) > 1) {
        fmla_int <- paste(outcome_var, "~ (", paste(vars, collapse = " + "), ")^2")
        batch_results[[2]] <- run_model_cv(
          vars,
          explicit_formula = fmla_int,
          label_suffix = " (+ Interactions)"
        )
      }
      batch_results
    }

    if (allow_parallel) {
      cores <- get_cores()
      cl <- parallel::makeCluster(cores)
      doParallel::registerDoParallel(cl)
      on.exit(parallel::stopCluster(cl), add = TRUE)

      combo <- NULL # avoid R CMD check NOTE about undefined global
      nested_results <- foreach::foreach(
        combo = all_combos,
        .packages = c("caret", "pROC", "DescTools", "rms"),
        .export = c("calculate_model_cost", "compute_fold_metrics")
      ) %dopar% {
        # Worker-local helper for spline terms
        get_term_labels_worker <- function(vars_subset) {
          vapply(vars_subset, function(v) {
            if (is.numeric(data[[v]]) && length(unique(data[[v]])) > 5) {
              paste0("rms::rcs(", v, ", ", n_knots, ")")
            } else {
              v
            }
          }, character(1))
        }

        terms <- get_term_labels_worker(combo)
        fmla_add_str <- paste(outcome_var, "~", paste(terms, collapse = " + "))

        res1 <- run_model_cv(combo, explicit_formula = fmla_add_str)
        res_list <- list(res1)

        if (include_interactions && length(combo) > 1) {
          fmla_int_str <- paste(
            outcome_var, "~ (", paste(terms, collapse = " + "), ")^2"
          )
          res2 <- run_model_cv(
            combo,
            explicit_formula = fmla_int_str,
            label_suffix = " (+ Interactions)"
          )
          res_list[[2]] <- res2
        }
        res_list
      }
      results_list <- unlist(nested_results, recursive = FALSE)
    } else {
      if (verbose) pb <- utils::txtProgressBar(min = 0, max = length(all_combos), style = 3)
      for (i in seq_along(all_combos)) {
        batch <- process_combo(all_combos[[i]])
        results_list <- c(results_list, batch)
        if (verbose) utils::setTxtProgressBar(pb, i)
      }
      if (verbose) close(pb)
    }
  } else if (mode == "groupwise") {
    if (include_interactions) {
      warning("Interactions not supported in groupwise mode.")
    }
    if (verbose) message("Starting Groupwise Search...")

    current_vars <- all_predictors
    fmla <- NULL
    if (!splines) {
      fmla <- paste(outcome_var, "~", paste(current_vars, collapse = " + "))
    }
    best_result <- run_model_cv(current_vars, fmla)
    results_list[[1]] <- best_result
    improved <- TRUE

    while (improved && length(current_vars) > group_size) {
      combos <- utils::combn(current_vars, group_size, simplify = FALSE)
      candidate_vars <- current_vars

      if (allow_parallel) {
        cores <- get_cores()
        cl <- parallel::makeCluster(cores)
        doParallel::registerDoParallel(cl)

        params <- NULL # avoid R CMD check NOTE
        candidates <- foreach::foreach(
          params = combos,
          .packages = c("caret", "pROC", "DescTools"),
          .export = c("calculate_model_cost", "compute_fold_metrics")
        ) %dopar% {
          test_vars <- setdiff(current_vars, params)
          run_model_cv(test_vars)
        }
        parallel::stopCluster(cl)
      } else {
        candidates <- lapply(combos, function(params) {
          test_vars <- setdiff(current_vars, params)
          run_model_cv(test_vars)
        })
      }

      round_best_idx <- which.max(
        vapply(candidates, \(x) x$avg_nb, numeric(1))
      )
      round_best_model <- candidates[[round_best_idx]]

      if (round_best_model$avg_nb > best_result$avg_nb) {
        best_result <- round_best_model
        current_vars <- best_result$predictors
        results_list <- append(results_list, candidates)
        improved <- TRUE
        if (verbose) {
          message(
            "-> Improvement! Removed: ",
            paste(setdiff(candidate_vars, current_vars), collapse = ", ")
          )
        }
      } else {
        results_list <- append(results_list, candidates)
        improved <- FALSE
        if (verbose) message("-> No improvement found. Stopping.")
      }
    }
  }

  # --- 4. Compile Summary ---
  summary_df <- do.call(dplyr::bind_rows, lapply(results_list, function(res) {
    if (is.null(res)) return(NULL)
    metrics <- data.frame(
      Model = res$model_name,
      n_Preds = length(res$predictors),
      AUC = res$auc,
      Brier = res$brier,
      Total_Cost = res$total_cost,
      Avg_Adj_Net_Benefit = res$avg_nb,
      Avg_Net_Benefit = res$avg_nb + res$total_cost
    )
    if (!is.null(res$importance)) {
      importance_wide <- res$importance |>
        tidyr::pivot_wider(
          names_from = "Predictor",
          values_from = "Importance",
          values_fill = 0,
          names_prefix = "VIF_"
        )
      dplyr::bind_cols(metrics, importance_wide)
    } else {
      metrics
    }
  }))

  summary_df <- summary_df[order(-summary_df$Avg_Adj_Net_Benefit), ]
  rownames(summary_df) <- NULL

  list(
    best_model_stats = summary_df[1, ],
    all_models = summary_df
  )
}
