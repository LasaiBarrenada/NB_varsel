# Variable Selection via Cross-Validated Net Benefit

Performs exhaustive or groupwise (backward elimination) variable
selection for binary outcome prediction models. Models are evaluated
using cross-validated Net Benefit, optionally adjusted for predictor
costs.

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

  A data frame containing predictors and the outcome variable.

- outcome_var:

  Character string naming the binary outcome column (coded 0/1 or as a
  two-level factor).

- costs:

  Predictor costs. Can be:

  - `NULL` (default): no costs.

  - A named numeric vector: per-predictor costs (e.g.,
    `c(X1 = 0.1, X2 = 0.05)`).

  - An unnamed scalar: same cost applied to every predictor.

  - A list of groups, each with elements `vars` (character vector) and
    `cost` (numeric). The group cost is added once if *any* of its
    variables are included.

- thresholds:

  Numeric vector of decision thresholds at which to compute Net Benefit.
  Defaults to `seq(0.05, 0.3, by = 0.01)`.

- include_interactions:

  Logical. If `TRUE`, models with interaction terms
  (`(X1 + X2 + ...)^2`) are also evaluated (exhaustive mode only).
  Defaults to `FALSE`.

- mode:

  Either `"exhaustive"` (evaluate all predictor combinations) or
  `"groupwise"` (backward elimination removing `group_size` variables at
  a time). Defaults to `"exhaustive"`.

- group_size:

  Integer. Number of variables to consider removing in each step of
  groupwise mode. Defaults to 2.

- cv_folds:

  Integer. Number of cross-validation folds. Defaults to 5.

- seed:

  Integer. Random seed for reproducibility. Defaults to 123.

- verbose:

  Logical. Print progress messages. Defaults to `TRUE`.

- allow_parallel:

  Logical. Use parallel computing via
  [`foreach::foreach()`](https://rdrr.io/pkg/foreach/man/foreach.html)
  and
  [`doParallel::registerDoParallel()`](https://rdrr.io/pkg/doParallel/man/registerDoParallel.html).
  Defaults to `TRUE`.

- permutation:

  Logical. Compute permutation importance scores for each predictor.
  Defaults to `FALSE`.

- splines:

  Logical. Apply restricted cubic splines (via
  [`rms::rcs()`](https://rdrr.io/pkg/rms/man/rms.trans.html)) to
  continuous predictors. Defaults to `TRUE`.

- n_knots:

  Integer. Number of knots for restricted cubic splines. Defaults to 3.

## Value

A list with two elements:

- best_model_stats:

  A one-row data frame describing the top-performing model.

- all_models:

  A data frame with one row per evaluated model, containing columns
  `Model`, `n_Preds`, `AUC`, `Brier`, `Total_Cost`,
  `Avg_Adj_Net_Benefit`, `Avg_Net_Benefit`, and (if
  `permutation = TRUE`) `VIF_*` columns for each predictor.

## Examples

``` r
if (FALSE) { # \dontrun{
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
result$best_model_stats
} # }
```
