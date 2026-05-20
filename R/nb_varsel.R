#' Variable Selection via Cross-Validated Net Benefit
#'
#' Performs exhaustive or groupwise (backward elimination) variable selection
#' for binary outcome prediction models. Models are evaluated using
#' cross-validated Net Benefit, optionally adjusted for predictor costs.
#'
#' @param data A data frame containing predictors and the outcome variable.
#' @param outcome_var Character string naming the binary outcome column
#'   (coded 0/1 or as a two-level factor).
#'   Required if \code{formula} is \code{NULL}.
#' @param formula An object of class \code{formula} (or one that can be coerced
#'   to that class). If provided, \code{outcome_var} is extracted from it, and 
#'   only predictors specified in the formula are considered as candidates.
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
#' @param include_interactions Logical. If `TRUE`, models with all two-way
#'   interaction terms (`(X1 + X2 + ...)^2`) are also evaluated (exhaustive 
#'   mode only). Defaults to `FALSE`.
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
#' @param splines Logical. If `TRUE`, applies restricted cubic splines (via
#'   [rms::rcs()]) to continuous predictors. The selection process will 
#'   hierarchically assess removing spline components while keeping linear 
#'   components. Defaults to `TRUE`.
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
    outcome_var = NULL,
    formula = NULL,
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
  if (inherits(outcome_var, "formula")) {
    if (!is.null(formula)) stop("Formula provided in both 'outcome_var' and 'formula' arguments.")
    formula <- outcome_var
    outcome_var <- NULL
  }

  mode <- match.arg(mode)

  # --- 1. Data Prep ---
  if (!is.null(formula)) {
    fmla <- stats::as.formula(formula)
    if (length(fmla) != 3) {
      stop("Formula must have both a left-hand side (outcome) and right-hand side (predictors).")
    }
    outcome_var <- all.vars(fmla[[2]])
    if (length(outcome_var) != 1) {
      stop("Formula must specify a single outcome variable.")
    }
    
    rhs_vars <- all.vars(fmla[[3]])
    if ("." %in% rhs_vars) {
      all_predictors <- setdiff(names(data), outcome_var)
    } else {
      all_predictors <- intersect(rhs_vars, names(data))
      if (length(all_predictors) == 0) {
        stop("None of the predictors in the formula were found in 'data'.")
      }
    }
  } else {
    if (is.null(outcome_var)) {
      stop("Please provide either 'outcome_var' or 'formula'.")
    }
    all_predictors <- setdiff(names(data), outcome_var)
  }

  if (!outcome_var %in% names(data)) {
    stop(sprintf("Outcome variable '%s' not found in data.", outcome_var))
  }

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

  # --- Helper: Model Definition Builder ---
  build_model_def <- function(states, interactions = FALSE) {
    vars <- names(states)
    if (length(vars) == 0) return(NULL)

    terms <- character(length(vars))
    spline_vars <- character(0)
    for (i in seq_along(vars)) {
      v <- vars[i]
      if (states[[v]] == "spline") {
        terms[i] <- paste0("rms::rcs(", v, ", ", n_knots, ")")
        spline_vars <- c(spline_vars, v)
      } else {
        terms[i] <- v
      }
    }

    base_fmla <- paste(terms, collapse = " + ")
    fmla_str <- if (interactions && length(vars) > 1) {
      paste(outcome_var, "~ (", base_fmla, ")^2")
    } else {
      paste(outcome_var, "~", base_fmla)
    }

    label_parts <- character(0)
    if (length(spline_vars) > 0) {
      label_parts <- c(label_parts, paste0("splines: ", paste(spline_vars, collapse=",")))
    }
    if (interactions && length(vars) > 1) {
      label_parts <- c(label_parts, "interactions")
    }
    
    label_suffix <- if (length(label_parts) > 0) paste0(" (", paste(label_parts, collapse = "; "), ")") else ""
    
    list(
      vars = vars, 
      states = states, 
      interactions = interactions, 
      explicit_formula = fmla_str, 
      label_suffix = label_suffix
    )
  }

  # --- 2. Core CV Engine (closure over shared state) ---
  run_model_cv <- function(mod_def) {
    if (is.null(mod_def)) return(NULL)
    
    fmla <- stats::as.formula(mod_def$explicit_formula)
    vars <- mod_def$vars
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
      model_name = paste0(paste(vars, collapse = ", "), mod_def$label_suffix),
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

    all_mod_defs <- list()
    for (vars in all_combos) {
      # Determine valid states for each selected variable
      state_options <- lapply(vars, function(v) {
        if (isTRUE(splines) && is.numeric(data[[v]]) && length(unique(data[[v]])) > 5) {
          return(c("linear", "spline"))
        } else {
          return("linear")
        }
      })
      names(state_options) <- vars
      
      grid <- expand.grid(state_options, stringsAsFactors = FALSE)
      for (i in seq_len(nrow(grid))) {
        states <- as.list(grid[i, , drop = FALSE])
        all_mod_defs <- append(all_mod_defs, list(build_model_def(states, FALSE)))
        
        if (isTRUE(include_interactions) && length(vars) > 1) {
          all_mod_defs <- append(all_mod_defs, list(build_model_def(states, TRUE)))
        }
      }
    }
    
    if (verbose) {
      message(sprintf("Starting Exhaustive Search: %d configurations...", length(all_mod_defs)))
    }

    if (allow_parallel) {
      cores <- get_cores()
      cl <- parallel::makeCluster(cores)
      doParallel::registerDoParallel(cl)
      on.exit(parallel::stopCluster(cl), add = TRUE)

      mod_def <- NULL
      nested_results <- foreach::foreach(
        mod_def = all_mod_defs,
        .packages = c("caret", "pROC", "DescTools", "rms"),
        .export = c("calculate_model_cost", "compute_fold_metrics")
      ) %dopar% {
        run_model_cv(mod_def)
      }
      results_list <- nested_results
    } else {
      if (verbose) pb <- utils::txtProgressBar(min = 0, max = length(all_mod_defs), style = 3)
      for (i in seq_along(all_mod_defs)) {
        results_list[[i]] <- run_model_cv(all_mod_defs[[i]])
        if (verbose) utils::setTxtProgressBar(pb, i)
      }
      if (verbose) close(pb)
    }
  } else if (mode == "groupwise") {
    if (!isFALSE(include_interactions)) {
      warning("Interactions not supported in groupwise mode. Setting include_interactions = FALSE.")
      include_interactions <- FALSE
    }
    if (verbose) message("Starting Groupwise Search...")

    # Initialize with all predictors, splines added where appropriate
    current_states <- list()
    for (v in all_predictors) {
      if (isTRUE(splines) && is.numeric(data[[v]]) && length(unique(data[[v]])) > 5) {
        current_states[[v]] <- "spline"
      } else {
        current_states[[v]] <- "linear"
      }
    }

    best_result <- run_model_cv(build_model_def(current_states))
    results_list <- list(best_result)
    improved <- TRUE

    # Helper: computes the 1-step states downward. A "step" is either 
    # downgrading a spline to linear, or removing a linear term entirely.
    get_1_step_down <- function(states) {
      cands <- list()
      for (v in names(states)) {
        new_states <- states
        if (states[[v]] == "spline") {
          new_states[[v]] <- "linear"
          cands <- append(cands, list(new_states))
        } else {
          new_states[[v]] <- NULL
          cands <- append(cands, list(new_states))
        }
      }
      cands
    }
    
    serialize_states <- function(states) {
      if (length(states) == 0) return("")
      paste(sort(paste(names(states), unlist(states), sep="=")), collapse="|")
    }

    while (improved && length(current_states) > 0) {
      cands <- list(current_states)
      for (step in seq_len(group_size)) {
        next_cands <- list()
        for (cand in cands) {
          next_cands <- append(next_cands, get_1_step_down(cand))
        }
        if (length(next_cands) == 0) {
          cands <- list()
          break
        }
        serialized <- vapply(next_cands, serialize_states, character(1))
        cands <- next_cands[!duplicated(serialized)]
      }
      
      # Filter out empty model state (cannot evaluate 0 predictors)
      cands <- cands[vapply(cands, length, integer(1)) > 0]
      if (length(cands) == 0) break
      
      candidate_defs <- lapply(cands, build_model_def)
      
      if (allow_parallel) {
        cores <- get_cores()
        cl <- parallel::makeCluster(cores)
        doParallel::registerDoParallel(cl)

        def <- NULL
        round_results <- foreach::foreach(
          def = candidate_defs,
          .packages = c("caret", "pROC", "DescTools", "rms"),
          .export = c("calculate_model_cost", "compute_fold_metrics")
        ) %dopar% {
          run_model_cv(def)
        }
        parallel::stopCluster(cl)
      } else {
        round_results <- lapply(candidate_defs, run_model_cv)
      }

      round_best_idx <- which.max(vapply(round_results, function(x) x$avg_nb, numeric(1)))
      round_best_model <- round_results[[round_best_idx]]

      if (round_best_model$avg_nb > best_result$avg_nb) {
        best_result <- round_best_model
        current_states <- candidate_defs[[round_best_idx]]$states
        results_list <- append(results_list, round_results)
        improved <- TRUE
        if (verbose) {
          message("-> Improvement! New best model: ", round_best_model$model_name)
        }
      } else {
        results_list <- append(results_list, round_results)
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
