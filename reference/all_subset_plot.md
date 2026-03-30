# All-Subset Model Comparison Plot

Creates a two-panel figure: the top panel shows a performance metric
across all evaluated models (ordered by number of predictors then by
metric value), and the bottom panel shows a heatmap of which predictors
are included in each model.

## Usage

``` r
all_subset_plot(
  all_models,
  metric = "Avg_Net_Benefit",
  y_axis = "Average Net Benefit",
  filter = 5,
  size_dot = 3,
  highlight_color = "red",
  tile_color = "#2A6EBB",
  p1_theme = NULL,
  p2_theme = NULL
)
```

## Arguments

- all_models:

  Data frame returned in the `all_models` element of
  [`nb_varsel()`](https://lasaibarrenada.github.io/NB_varsel/reference/nb_varsel.md).

- metric:

  Character string. Column name in `all_models` to plot on the y-axis.
  Defaults to `"Avg_Net_Benefit"`.

- y_axis:

  Character string. Label for the y-axis of the top panel. Defaults to
  `"Average Net Benefit"`.

- filter:

  Integer. When there are more than 100 models, keep only the top
  `filter` models per number of predictors. Defaults to 5.

- size_dot:

  Numeric. Point size in the metric plot. Defaults to 3.

- highlight_color:

  Character string. Color for the dashed lines marking the best model.
  Defaults to `"red"`.

- tile_color:

  Character string. Fill color for "present" tiles in the heatmap panel.
  Defaults to `"#2A6EBB"`.

- p1_theme:

  A
  [`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html)
  object to add to the top panel, or `NULL`.

- p2_theme:

  A
  [`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html)
  object to add to the bottom panel, or `NULL`.

## Value

A
[patchwork::patchwork](https://patchwork.data-imaginist.com/reference/patchwork-package.html)
object (two stacked ggplot panels).

## Examples

``` r
if (FALSE) { # \dontrun{
result <- nb_varsel(
  data = df, outcome_var = "Y", costs = harms,
  mode = "exhaustive", splines = FALSE, allow_parallel = FALSE
)
all_subset_plot(result$all_models)
} # }
```
