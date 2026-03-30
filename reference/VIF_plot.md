# Permutation Importance Bar Plot

Creates a horizontal bar chart showing the average permutation
importance (delta Net Benefit) for each predictor across the evaluated
models.

## Usage

``` r
VIF_plot(all_models, filter = NULL, color = "#2A6EBB")
```

## Arguments

- all_models:

  Data frame returned in the `all_models` element of
  [`nb_varsel()`](https://lasaibarrenada.github.io/NB_varsel/reference/nb_varsel.md).
  Must include `VIF_*` columns (generated when `permutation = TRUE`).

- filter:

  Integer or `NULL`. If specified, only the top `filter` models (by
  `Avg_Net_Benefit`) are used to compute average importance. Defaults to
  `NULL` (use all models).

- color:

  Character string. Fill color for the bars. Defaults to `"#2A6EBB"`.

## Value

A [ggplot2::ggplot](https://ggplot2.tidyverse.org/reference/ggplot.html)
object.

## Examples

``` r
if (FALSE) { # \dontrun{
result <- nb_varsel(
  data = df, outcome_var = "Y", costs = harms,
  mode = "exhaustive", permutation = TRUE,
  splines = FALSE, allow_parallel = FALSE
)
VIF_plot(result$all_models)
} # }
```
