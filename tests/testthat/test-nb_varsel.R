test_that("exhaustive mode returns expected structure", {
  set.seed(4821)
  n <- 200
  df <- data.frame(
    X1 = rnorm(n),
    X2 = rbinom(n, 1, 0.5),
    Y = rbinom(n, 1, 0.5)
  )

  result <- nb_varsel(
    data = df,
    outcome_var = "Y",
    mode = "exhaustive",
    splines = FALSE,
    allow_parallel = FALSE,
    verbose = FALSE,
    cv_folds = 3
  )

  expect_type(result, "list")
  expect_named(result, c("best_model_stats", "all_models"))
  expect_s3_class(result$all_models, "data.frame")
  expect_true(nrow(result$best_model_stats) == 1)

  expected_cols <- c(
    "Model", "n_Preds", "AUC", "Brier",
    "Total_Cost", "Avg_Adj_Net_Benefit", "Avg_Net_Benefit"
  )
  expect_true(all(expected_cols %in% names(result$all_models)))

  # With 2 predictors: 3 models (X1, X2, X1+X2)
  expect_equal(nrow(result$all_models), 3)
})

test_that("costs are applied correctly", {
  set.seed(6739)
  n <- 200
  df <- data.frame(
    X1 = rnorm(n),
    X2 = rbinom(n, 1, 0.5),
    Y = rbinom(n, 1, 0.5)
  )

  harms <- c(X1 = 0.1, X2 = 0.05)

  result <- nb_varsel(
    data = df,
    outcome_var = "Y",
    costs = harms,
    mode = "exhaustive",
    splines = FALSE,
    allow_parallel = FALSE,
    verbose = FALSE,
    cv_folds = 3
  )

  # Adjusted NB should differ from unadjusted by the cost
  models <- result$all_models
  expect_equal(
    models$Avg_Net_Benefit - models$Total_Cost,
    models$Avg_Adj_Net_Benefit,
    tolerance = 1e-10
  )
})

test_that("permutation importance columns are added", {
  set.seed(2057)
  n <- 200
  df <- data.frame(
    X1 = rnorm(n),
    X2 = rbinom(n, 1, 0.5),
    Y = rbinom(n, 1, 0.5)
  )

  result <- nb_varsel(
    data = df,
    outcome_var = "Y",
    mode = "exhaustive",
    splines = FALSE,
    allow_parallel = FALSE,
    verbose = FALSE,
    cv_folds = 3,
    permutation = TRUE
  )

  vif_cols <- grep("^VIF_", names(result$all_models), value = TRUE)
  expect_true(length(vif_cols) > 0)
})

test_that("groupwise mode runs without error", {
  set.seed(8843)
  n <- 200
  df <- data.frame(
    X1 = rnorm(n),
    X2 = rbinom(n, 1, 0.5),
    X3 = rnorm(n),
    Y = rbinom(n, 1, 0.5)
  )

  result <- nb_varsel(
    data = df,
    outcome_var = "Y",
    mode = "groupwise",
    group_size = 1,
    splines = FALSE,
    allow_parallel = FALSE,
    verbose = FALSE,
    cv_folds = 3
  )

  expect_type(result, "list")
  expect_s3_class(result$all_models, "data.frame")
  expect_true(nrow(result$all_models) >= 1)
})

# --- Splines ---

test_that("splines work in exhaustive mode", {
  set.seed(3291)
  n <- 200
  df <- data.frame(
    X1 = rnorm(n),
    X2 = rbinom(n, 1, 0.5),
    Y = rbinom(n, 1, 0.5)
  )

  result <- nb_varsel(
    data = df,
    outcome_var = "Y",
    mode = "exhaustive",
    splines = TRUE,
    n_knots = 3,
    allow_parallel = FALSE,
    verbose = FALSE,
    cv_folds = 3
  )

  expect_type(result, "list")
  expect_equal(nrow(result$all_models), 3)
})

test_that("splines work in groupwise mode", {
  set.seed(7134)
  n <- 200
  df <- data.frame(
    X1 = rnorm(n),
    X2 = rnorm(n),
    X3 = rbinom(n, 1, 0.5),
    Y = rbinom(n, 1, 0.5)
  )

  result <- nb_varsel(
    data = df,
    outcome_var = "Y",
    mode = "groupwise",
    group_size = 1,
    splines = TRUE,
    n_knots = 3,
    allow_parallel = FALSE,
    verbose = FALSE,
    cv_folds = 3
  )

  expect_type(result, "list")
  expect_true(nrow(result$all_models) >= 1)
})

# --- Parallel ---

test_that("parallel works in exhaustive mode", {
  skip_on_cran()
  set.seed(5428)
  n <- 200
  df <- data.frame(
    X1 = rnorm(n),
    X2 = rbinom(n, 1, 0.5),
    Y = rbinom(n, 1, 0.5)
  )

  result <- nb_varsel(
    data = df,
    outcome_var = "Y",
    mode = "exhaustive",
    splines = FALSE,
    allow_parallel = TRUE,
    verbose = FALSE,
    cv_folds = 3
  )

  expect_type(result, "list")
  expect_equal(nrow(result$all_models), 3)
})

test_that("parallel works in groupwise mode", {
  skip_on_cran()
  set.seed(9162)
  n <- 200
  df <- data.frame(
    X1 = rnorm(n),
    X2 = rbinom(n, 1, 0.5),
    X3 = rnorm(n),
    Y = rbinom(n, 1, 0.5)
  )

  result <- nb_varsel(
    data = df,
    outcome_var = "Y",
    mode = "groupwise",
    group_size = 1,
    splines = FALSE,
    allow_parallel = TRUE,
    verbose = FALSE,
    cv_folds = 3
  )

  expect_type(result, "list")
  expect_true(nrow(result$all_models) >= 1)
})

test_that("parallel with splines works in exhaustive mode", {
  skip_on_cran()
  set.seed(2847)
  n <- 200
  df <- data.frame(
    X1 = rnorm(n),
    X2 = rbinom(n, 1, 0.5),
    Y = rbinom(n, 1, 0.5)
  )

  result <- nb_varsel(
    data = df,
    outcome_var = "Y",
    mode = "exhaustive",
    splines = TRUE,
    n_knots = 3,
    allow_parallel = TRUE,
    verbose = FALSE,
    cv_folds = 3
  )

  expect_type(result, "list")
  expect_equal(nrow(result$all_models), 3)
})

# --- Interactions ---

test_that("interactions doubles model count for multi-predictor combos", {
  set.seed(6053)
  n <- 200
  df <- data.frame(
    X1 = rnorm(n),
    X2 = rbinom(n, 1, 0.5),
    Y = rbinom(n, 1, 0.5)
  )

  result <- nb_varsel(
    data = df,
    outcome_var = "Y",
    mode = "exhaustive",
    include_interactions = TRUE,
    splines = FALSE,
    allow_parallel = FALSE,
    verbose = FALSE,
    cv_folds = 3
  )

  # 2 predictors: X1, X2, X1+X2, X1+X2 (+ Interactions) = 4 models
  expect_equal(nrow(result$all_models), 4)
  expect_true(
    any(grepl("Interactions", result$all_models$Model))
  )
})

# --- Grouped costs ---

test_that("grouped list costs work", {
  set.seed(4516)
  n <- 200
  df <- data.frame(
    X1 = rnorm(n),
    X2 = rnorm(n),
    X3 = rbinom(n, 1, 0.5),
    Y = rbinom(n, 1, 0.5)
  )

  grouped_costs <- list(
    list(vars = c("X1", "X2"), cost = 0.1),
    list(vars = "X3", cost = 0.05)
  )

  result <- nb_varsel(
    data = df,
    outcome_var = "Y",
    costs = grouped_costs,
    mode = "exhaustive",
    splines = FALSE,
    allow_parallel = FALSE,
    verbose = FALSE,
    cv_folds = 3
  )

  models <- result$all_models

  # X1-only and X2-only should both have cost = 0.1 (same group)
  x1_cost <- models$Total_Cost[models$Model == "X1"]
  x2_cost <- models$Total_Cost[models$Model == "X2"]
  expect_equal(x1_cost, 0.1)
  expect_equal(x2_cost, 0.1)

  # X3-only cost = 0.05
  x3_cost <- models$Total_Cost[models$Model == "X3"]
  expect_equal(x3_cost, 0.05)

  # X1+X2 should still be 0.1 (group cost added once)
  x1x2_row <- models[grepl("^X1, X2$|^X2, X1$", models$Model), ]
  expect_equal(x1x2_row$Total_Cost, 0.1)
})

# --- Factor outcome ---

test_that("factor outcome is handled correctly", {
  set.seed(8371)
  n <- 200
  df <- data.frame(
    X1 = rnorm(n),
    X2 = rbinom(n, 1, 0.5),
    Y = factor(rbinom(n, 1, 0.5), levels = c(0, 1))
  )

  result <- nb_varsel(
    data = df,
    outcome_var = "Y",
    mode = "exhaustive",
    splines = FALSE,
    allow_parallel = FALSE,
    verbose = FALSE,
    cv_folds = 3
  )

  expect_type(result, "list")
  expect_equal(nrow(result$all_models), 3)
})

# --- Input validation ---

test_that("non-binary outcome is rejected", {
  df <- data.frame(X1 = rnorm(50), Y = sample(0:2, 50, replace = TRUE))

  expect_error(
    nb_varsel(
      data = df, outcome_var = "Y",
      splines = FALSE, allow_parallel = FALSE, verbose = FALSE
    ),
    "binary"
  )
})

# --- Reproducibility ---

test_that("results are reproducible with same seed", {
  set.seed(1193)
  n <- 200
  df <- data.frame(
    X1 = rnorm(n),
    X2 = rbinom(n, 1, 0.5),
    Y = rbinom(n, 1, 0.5)
  )

  run <- function() {
    nb_varsel(
      data = df,
      outcome_var = "Y",
      seed = 7742,
      mode = "exhaustive",
      splines = FALSE,
      allow_parallel = FALSE,
      verbose = FALSE,
      cv_folds = 3
    )
  }

  r1 <- run()
  r2 <- run()
  expect_equal(r1$all_models$Avg_Net_Benefit, r2$all_models$Avg_Net_Benefit)
  expect_equal(r1$all_models$AUC, r2$all_models$AUC)
})

# --- Best model selection ---

test_that("best_model_stats is the row with max Avg_Adj_Net_Benefit", {
  set.seed(5627)
  n <- 500
  X1 <- rnorm(n)
  X2 <- rbinom(n, 1, 0.6)
  X3 <- rnorm(n)
  df <- data.frame(
    X1 = X1, X2 = X2, X3 = X3,
    Y = rbinom(n, 1, plogis(2 * X1 + 1.5 * X2 + 0.1 * X3))
  )

  harms <- c(X1 = 0.05, X2 = 0.02, X3 = 0.05)

  result <- nb_varsel(
    data = df,
    outcome_var = "Y",
    costs = harms,
    mode = "exhaustive",
    splines = FALSE,
    allow_parallel = FALSE,
    verbose = FALSE,
    cv_folds = 5
  )

  models <- result$all_models
  best <- result$best_model_stats

  # best_model_stats should match the max of all_models

  expect_equal(best$Avg_Adj_Net_Benefit, max(models$Avg_Adj_Net_Benefit))

  # all_models should be sorted descending by Avg_Adj_Net_Benefit
  expect_equal(
    models$Avg_Adj_Net_Benefit,
    sort(models$Avg_Adj_Net_Benefit, decreasing = TRUE)
  )
})

test_that("costs can shift which model is selected as best", {
  set.seed(3814)
  n <- 500
  X1 <- rnorm(n)
  X2 <- rnorm(n)
  df <- data.frame(
    X1 = X1, X2 = X2,
    Y = rbinom(n, 1, plogis(1.5 * X1 + 0.3 * X2))
  )

  # No costs — best model should be the one with highest NB
  result_no_cost <- nb_varsel(
    data = df,
    outcome_var = "Y",
    costs = NULL,
    mode = "exhaustive",
    splines = FALSE,
    allow_parallel = FALSE,
    verbose = FALSE,
    cv_folds = 5
  )

  # Heavy cost on X2 — may shift best model away from including X2
  result_heavy_cost <- nb_varsel(
    data = df,
    outcome_var = "Y",
    costs = c(X1 = 0, X2 = 10),
    mode = "exhaustive",
    splines = FALSE,
    allow_parallel = FALSE,
    verbose = FALSE,
    cv_folds = 5
  )

  # With no costs, adjusted and unadjusted NB are equal
  expect_equal(
    result_no_cost$all_models$Avg_Adj_Net_Benefit,
    result_no_cost$all_models$Avg_Net_Benefit
  )

  # With heavy cost on X2, best model should not include X2
  expect_false(grepl("X2", result_heavy_cost$best_model_stats$Model))
})
