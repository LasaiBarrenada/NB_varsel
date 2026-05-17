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

test_that("all_subset_plot handles varied p1_theme and p2_theme", {
  set.seed(3311)
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

  theme_pairs <- list(
    list(p1 = ggplot2::theme_bw(), p2 = ggplot2::theme_minimal()),
    list(
      p1 = ggplot2::theme(
        panel.grid.major.x = ggplot2::element_blank(),
        legend.position = "bottom"
      ),
      p2 = ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))
    ),
    list(p1 = NULL, p2 = ggplot2::theme_void()),
    list(p1 = ggplot2::theme_classic(), p2 = NULL)
  )

  for (theme_pair in theme_pairs) {
    p <- expect_no_error(
      all_subset_plot(
        result$all_models,
        p1_theme = theme_pair$p1,
        p2_theme = theme_pair$p2
      )
    )
    expect_s3_class(p, "patchwork")
  }
})

test_that("VIF_plot returns plot and numerical results", {
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

  vif_results <- VIF_plot(result$all_models)

  expect_type(vif_results, "list")
  expect_named(vif_results, c("plot", "data"), ignore.order = TRUE)

  p <- vif_results$plot
  d <- vif_results$data

  expect_s3_class(p, "gg")
  expect_s3_class(d, "data.frame")
  expect_true(all(c("Variable", "Average_Delta_NB") %in% names(d)))
  expect_gt(nrow(d), 0)
  expect_true(is.numeric(d$Average_Delta_NB))
})
