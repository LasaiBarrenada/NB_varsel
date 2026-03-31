# NBvarsel

<!-- badges: start -->
[![R-CMD-check](https://github.com/LasaiBarrenada/NB_varsel/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/LasaiBarrenada/NB_varsel/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

Variable selection for binary outcome prediction models using cross-validated
**Net Benefit** as the optimization criterion.

## Overview

`NBvarsel` evaluates predictor subsets by their contribution to clinical
utility (Net Benefit), rather than purely statistical performance
metrics like p-values. It supports:

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

Alternatively, install from a source tarball (`.tar.gz`):

```r
install.packages("NBvarsel_0.1.0.tar.gz", repos = NULL, type = "source")
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

## Documentation

Full documentation and vignettes are available at
**<https://lasaibarrenada.github.io/NB_varsel/>**.

## Functions

| Function | Description |
|---|---|
| `nb_varsel()` | Variable selection via cross-validated Net Benefit |
| `all_subset_plot()` | Two-panel model comparison visualisation |
| `VIF_plot()` | Permutation importance bar chart |

## References

- Barreñada, L., Vickers, A. J., Steyerberg, E. W., Timmerman, D., Wynants, L., & Van Calster, B. (2026). Cost-based variable selection to improve clinical utility of prediction models. *In preparation*.   

- Vickers, A. J., & Elkin, E. B. (2006). Decision curve analysis: a novel method
  for evaluating prediction models. *Medical Decision Making*, 26(6), 565–574.
  <https://doi.org/10.1177/0272989X06295361>

- Van Calster, B., Wynants, L., Verbeek, J. F. M., Verbakel, J. Y.,
  Christodoulou, E., Vickers, A. J., Roobol, M. J., & Steyerberg, E. W.
  (2018). Reporting and Interpreting Decision Curve Analysis: A Guide for
  Investigators. *European Urology*, 74(6), 796–804.
  <https://doi.org/10.1016/j.eururo.2018.08.038>

- Vickers, A. J., Van Calster, B., & Steyerberg, E. W. (2019). A simple,
  step-by-step guide to interpreting decision curve analysis. *Diagnostic and
  Prognostic Research*, 3, 18.
  <https://doi.org/10.1186/s41512-019-0064-7>

- Baker, S. G., Van Calster, B., & Steyerberg, E. W. (2012). Evaluating a New
  Marker for Risk Prediction Using the Test Tradeoff: An Update. *The
  International Journal of Biostatistics*, 8, 1–37.
  <https://doi.org/10.1515/1557-4679.1395>
