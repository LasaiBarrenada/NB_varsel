# NBvarsel

<!-- badges: start -->
[![R-CMD-check](https://github.com/LasaiBarrenada/NB_varsel/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/LasaiBarrenada/NB_varsel/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

Variable selection for binary outcome prediction models using cross-validated
**Net Benefit** as the optimization criterion.

## Overview

`NBvarsel` evaluates predictor subsets by their contribution to clinical
decision-making (Net Benefit), rather than purely statistical performance
metrics like AUC. It supports:

- **Exhaustive** and **groupwise** (backward elimination) search strategies
- Predictor costs (per-variable or grouped)
- Restricted cubic splines for continuous predictors
- Interaction terms
- Permutation importance scores
- Parallel computation

## Installation

You can install the development version of NBvarsel from GitHub:

```r
# install.packages("pak")
pak::pak("LasaiBarrenada/NB_varsel")
```

## Quick Start

```r
library(NBvarsel)

# Simulate data
set.seed(42)
n <- 500
df <- data.frame(
  X1 = rnorm(n), X2 = rbinom(n, 1, 0.7),
  X3 = rnorm(n), X4 = rbinom(n, 1, 0.5)
)
df$Y <- rbinom(n, 1, plogis(2 * df$X1 + 1.5 * df$X2 + 0.2 * df$X3))

# Define predictor costs
harms <- c(X1 = 0.1, X2 = 0.05, X3 = 0.1, X4 = 0.0001)

# Run exhaustive variable selection
result <- nb_varsel(
  data = df,
  outcome_var = "Y",
  costs = harms,
  mode = "exhaustive",
  splines = FALSE,
  permutation = TRUE,
  allow_parallel = FALSE
)

# Best model (highest cost-adjusted Net Benefit)
result$best_model_stats

# All evaluated models, sorted by Avg_Adj_Net_Benefit
result$all_models
```

### Visualisation

```r
# Two-panel plot: metric overview + predictor inclusion heatmap
all_subset_plot(result$all_models)

# Customise colors
all_subset_plot(
  result$all_models,
  highlight_color = "steelblue",
  tile_color = "#E64B35"
)

# Permutation importance bar chart
VIF_plot(result$all_models, color = "darkgreen")
```

## Functions

| Function | Description |
|---|---|
| `nb_varsel()` | Variable selection via cross-validated Net Benefit |
| `all_subset_plot()` | Two-panel model comparison visualisation |
| `VIF_plot()` | Permutation importance bar chart |
| `fastAUC()` | Fast rank-based AUC computation |
