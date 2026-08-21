# All-Subset Model Comparison Plot

Creates a two-panel figure comparing model performance across all
evaluated subsets. The upper panel shows the selected metric for each
model, and the lower panel shows which predictors are included in each
model.

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
  p2_theme = NULL,
  data_dict = NULL
)
```

## Arguments

- all_models:

  Data frame returned in the `all_models` element of
  [`nb_varsel()`](https://lasaibarrenada.github.io/NB_varsel/reference/nb_varsel.md).
  This should contain the model summary output used for plotting.

- metric:

  Character string. Name of the column in `all_models` to plot on the
  y-axis. Defaults to `"Avg_Net_Benefit"`.

- y_axis:

  Character string. Label for the y-axis in the top panel. Defaults to
  `"Average Net Benefit"`.

- filter:

  Integer. Maximum number of models to display per number of predictors.
  Defaults to 5.

- size_dot:

  Numeric. Point size used in the metric plot. Defaults to 3.

- highlight_color:

  Character string. Color for the dashed reference lines marking the
  best model. Defaults to `"red"`.

- tile_color:

  Character string. Fill color used for included predictors in the
  heatmap. Defaults to `"#2A6EBB"`.

- p1_theme:

  A
  [`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html)
  object applied to the top panel, or `NULL`.

- p2_theme:

  A
  [`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html)
  object applied to the bottom panel, or `NULL`.

- data_dict:

  A named character vector used to relabel predictors. Format:
  `c("raw_name" = "Display Label")`. Defaults to `NULL`.

## Value

A
[patchwork](https://patchwork.data-imaginist.com/reference/patchwork-package.html)
object containing two stacked ggplot panels.
