# Variable Selection via Cross-Validated Net Benefit

Performs exhaustive or groupwise variable selection for binary-outcome
prediction models. Models are evaluated using cross-validated net
benefit, with optional adjustment for predictor costs.

## Usage

``` r
nb_varsel(
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
)
```

## Arguments

- data:

  A data frame containing the predictor variables and the binary
  outcome.

- outcome_var:

  Character string naming the binary outcome column (coded as 0/1 or as
  a two-level factor).

- costs:

  Predictor costs. Can be:

  - `NULL` (default): no costs.

  - A named numeric vector: per-predictor costs, e.g.
    `c(X1 = 0.1, X2 = 0.05)`.

  - An unnamed scalar: the same cost applied to every predictor.

  - A list of groups, each with elements `vars` (character vector) and
    `cost` (numeric). The group cost is added once if any variable in
    the group is selected.

- thresholds:

  Numeric vector of decision thresholds at which net benefit is
  evaluated. Defaults to `seq(0.05, 0.3, by = 0.01)`.

- include_interactions:

  Logical. If `TRUE`, interaction terms (`(X1 + X2 + ...)^2`) are also
  evaluated in exhaustive mode. Defaults to `FALSE`.

- mode:

  Character string specifying the selection strategy: `"exhaustive"`
  evaluates all predictor subsets, while `"groupwise"` performs backward
  elimination in groups of size `group_size`. Defaults to
  `"exhaustive"`.

- group_size:

  Integer. Number of variables removed at each step in groupwise mode.
  Defaults to 2.

- cv_folds:

  Integer. Number of cross-validation folds. Defaults to 5.

- seed:

  Integer. Random seed for reproducibility. Defaults to 123.

- verbose:

  Logical. If `TRUE`, progress messages are printed. Defaults to `TRUE`.

- allow_parallel:

  Logical. If `TRUE`, use parallel computation through `foreach` and
  `doParallel`. Defaults to `TRUE`.

- permutation:

  Logical. If `TRUE`, compute permutation importance scores for each
  predictor. Defaults to `FALSE`.

- splines:

  Logical. If `TRUE`, apply restricted cubic splines (via
  [`rms::rcs()`](https://rdrr.io/pkg/rms/man/rms.trans.html)) to
  continuous predictors. Defaults to `TRUE`.

- n_knots:

  Integer. Number of knots used for restricted cubic splines. Defaults
  to 3.

## Value

A list with the following elements:

- best_model_stats:

  A one-row data frame describing the top-performing model.

- all_models:

  A data frame with one row per evaluated model, containing columns
  `Model`, `n_Preds`, `AUC`, `Brier`, `Total_Cost`,
  `Avg_Adj_Net_Benefit`, and `Avg_Net_Benefit`. If `permutation = TRUE`,
  additional `VIF_` columns containing permutation importance scores are
  included.

## Examples

``` r
set.seed(42)
n <- 500
df <- data.frame(
  X1 = rnorm(n), X2 = rbinom(n, 1, 0.7),
  X3 = rnorm(n), X4 = rbinom(n, 1, 0.5)
)
df$Y <- rbinom(n, 1, plogis(2 * df$X1 + 1.5 * df$X2))

harms <- c(X1 = 0.1, X2 = 0.05, X3 = 0.1, X4 = 0.0001)

result <- nb_varsel(
  data = df, outcome_var = "Y", costs = harms,
  mode = "exhaustive", splines = FALSE,
  allow_parallel = FALSE
)
#> Starting Exhaustive Search: 15 configurations...
#>   |                                                                              |                                                                      |   0%  |                                                                              |=====                                                                 |   7%  |                                                                              |=========                                                             |  13%  |                                                                              |==============                                                        |  20%  |                                                                              |===================                                                   |  27%  |                                                                              |=======================                                               |  33%  |                                                                              |============================                                          |  40%  |                                                                              |=================================                                     |  47%  |                                                                              |=====================================                                 |  53%  |                                                                              |==========================================                            |  60%  |                                                                              |===============================================                       |  67%  |                                                                              |===================================================                   |  73%  |                                                                              |========================================================              |  80%  |                                                                              |=============================================================         |  87%  |                                                                              |=================================================================     |  93%  |                                                                              |======================================================================| 100%
result$best_model_stats
#>   Model n_Preds       AUC     Brier Total_Cost Avg_Adj_Net_Benefit
#> 1    X4       1 0.5071078 0.2335055      1e-04            0.557431
#>   Avg_Net_Benefit
#> 1        0.557531
```
