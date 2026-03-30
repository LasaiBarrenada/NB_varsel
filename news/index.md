# Changelog

## NBvarsel 0.1.0

- Initial release.
- Added a tutorial vignette (`nb-varsel-tutorial`) demonstrating the
  full workflow with fabricated clinical data, including comparison with
  backward elimination and LASSO.
- [`nb_varsel()`](https://lasaibarrenada.github.io/NB_varsel/reference/nb_varsel.md)
  performs exhaustive or groupwise variable selection for binary outcome
  models using cross-validated Net Benefit, with support for predictor
  costs (per-variable or grouped), restricted cubic splines, interaction
  terms, permutation importance, and parallel computation.
- [`all_subset_plot()`](https://lasaibarrenada.github.io/NB_varsel/reference/all_subset_plot.md)
  creates a two-panel figure showing model performance and predictor
  inclusion across all evaluated models. Supports customisable colors
  via `highlight_color` and `tile_color` arguments.
- [`VIF_plot()`](https://lasaibarrenada.github.io/NB_varsel/reference/VIF_plot.md)
  creates a horizontal bar chart of average permutation importance
  (delta Net Benefit) per predictor. Supports a customisable `color`
  argument.
