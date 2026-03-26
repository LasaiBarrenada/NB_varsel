# NBvarsel 0.1.0

* Initial release.
* Added a tutorial vignette (`nb-varsel-tutorial`) demonstrating the full workflow with fabricated clinical data, including comparison with backward elimination and LASSO.
* `nb_varsel()` performs exhaustive or groupwise variable selection for binary outcome models using cross-validated Net Benefit, with support for predictor costs (per-variable or grouped), restricted cubic splines, interaction terms, permutation importance, and parallel computation.
* `all_subset_plot()` creates a two-panel figure showing model performance and predictor inclusion across all evaluated models. Supports customisable colors via `highlight_color` and `tile_color` arguments.
* `VIF_plot()` creates a horizontal bar chart of average permutation importance (delta Net Benefit) per predictor. Supports a customisable `color` argument.
* `fastAUC()` computes AUC using a fast rank-based approach in O(n log n) time.
