test_that("fastAUC returns 1 for perfect separation", {
  p <- c(0.1, 0.2, 0.3, 0.8, 0.9, 1.0)
  y <- c(0, 0, 0, 1, 1, 1)
  expect_equal(NBvarsel:::fastAUC(p, y), 1)
})

test_that("fastAUC returns 0.5 for random predictions", {
  set.seed(7412)
  n <- 10000
  y <- rep(c(0, 1), each = n / 2)
  p <- runif(n)
  expect_equal(NBvarsel:::fastAUC(p, y), 0.5, tolerance = 0.05)
})

test_that("fastAUC returns value between 0 and 1", {
  set.seed(3198)
  p <- runif(100)
  y <- sample(c(0, 1), 100, replace = TRUE)
  result <- NBvarsel:::fastAUC(p, y)
  expect_gte(result, 0)
  expect_lte(result, 1)
})
