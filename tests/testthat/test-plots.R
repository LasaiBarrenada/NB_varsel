test_that("all_subset_plot returns a patchwork object", {
  set.seed(5513)
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

  p <- all_subset_plot(result$all_models)
  expect_s3_class(p, "patchwork")
})

test_that("VIF_plot returns a ggplot object", {
  set.seed(1742)
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

  p <- VIF_plot(result$all_models)
  expect_s3_class(p, "gg")
})
