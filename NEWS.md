# NBvarsel 0.1.2

* Fixed a bug in `nb_varsel()` where parallel exhaustive mode ignored `splines = FALSE` and used a different continuous-variable threshold (`> 5` instead of `> 20` unique values).
* Fixed a bug in `nb_varsel()` where parallel groupwise mode failed when `splines = TRUE` due to missing worker exports (`get_term_labels`, `rms`), and ensured parallel clusters are registered once with `on.exit()` cleanup.
* Fixed class stratification in `nb_varsel()` cross-validation by passing `factor(y_numeric)` to `caret::createFolds()`, and switched fold AUC calculation to the internal `fastAUC()` helper.
* Added input validation in `nb_varsel()` for missing `outcome_var` columns, `NA` outcome values, single-class outcomes, and `groupwise` searches when `n_predictors <= group_size`.
* Fixed `all_subset_plot()` predictor name parsing for models containing `" (+ Interactions)"`, allowed `filter` to apply whenever any predictor-count group exceeds `filter` models, updated the bottom panel x-axis label to `"Predictor combination"`, and hid x-axis tick marks and labels on both panels to prevent overlap.
* Fixed bar ordering in `VIF_plot()` so the most important predictor appears at the top of the plot, added validation for `VIF_` columns, and added a `metric` argument (defaulting to `"Avg_Adj_Net_Benefit"`).
* Added `@examples` to `all_subset_plot()` and aligned the `adnex_results` documentation and tutorial vignette text.

# NBvarsel 0.1.1

* Improved package documentation and roxygen comments for the main selection function and plotting helpers, making the exported API clearer and easier to use.
* Refined the documentation for `all_subset_plot()` and `VIF_plot()` to better describe their inputs, outputs, and examples.
* Extended plotting utilities with optional predictor relabelling via `data_dict`, making it easier to present clinically meaningful variable names in figures.
* Improved the tutorial vignette layout and narrative around the fabricated clinical example and case-study sections, with clearer descriptions of model comparisons and interpretation.
* Cleaned up the vignette workflow to avoid brittle global-environment cleanup during execution.

# NBvarsel 0.1.0

* Initial release.
* Added `adnex_results` dataset: pre-computed exhaustive variable selection results from the IOTA/ADNEX ovarian tumour case study (top 20 models per predictor count from a 65,535-model search). Original patient data are not disclosed.
* Added a tutorial vignette (`nb-varsel-tutorial`) demonstrating the full workflow with fabricated clinical data, comparison with backward elimination and LASSO, and a real-data case study using the shipped ADNEX results.
* `nb_varsel()` performs exhaustive or groupwise variable selection for binary outcome models using cross-validated Net Benefit, with support for predictor costs (per-variable or grouped), restricted cubic splines, interaction terms, permutation importance, and parallel computation.
* `all_subset_plot()` creates a two-panel figure showing model performance and predictor inclusion across all evaluated models. Supports customisable colors via `highlight_color` and `tile_color` arguments.
* `VIF_plot()` creates a horizontal bar chart of average permutation importance (delta Net Benefit) per predictor. Supports a customisable `color` argument.
