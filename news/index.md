# Changelog

## NBvarsel 0.1.1

- Improved package documentation and roxygen comments for the main
  selection function and plotting helpers, making the exported API
  clearer and easier to use.
- Refined the documentation for
  [`all_subset_plot()`](https://lasaibarrenada.github.io/NB_varsel/reference/all_subset_plot.md)
  and
  [`VIF_plot()`](https://lasaibarrenada.github.io/NB_varsel/reference/VIF_plot.md)
  to better describe their inputs, outputs, and examples.
- Extended plotting utilities with optional predictor relabelling via
  `data_dict`, making it easier to present clinically meaningful
  variable names in figures.
- Improved the tutorial vignette layout and narrative around the
  fabricated clinical example and case-study sections, with clearer
  descriptions of model comparisons and interpretation.
- Cleaned up the vignette workflow to avoid brittle global-environment
  cleanup during execution.

## NBvarsel 0.1.0

- Initial release.
- Added `adnex_results` dataset: pre-computed exhaustive variable
  selection results from the IOTA/ADNEX ovarian tumour case study (top
  20 models per predictor count from a 65,535-model search). Original
  patient data are not disclosed.
- Added a tutorial vignette (`nb-varsel-tutorial`) demonstrating the
  full workflow with fabricated clinical data, comparison with backward
  elimination and LASSO, and a real-data case study using the shipped
  ADNEX results.
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
