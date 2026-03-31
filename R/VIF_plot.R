#' Permutation Importance Bar Plot
#'
#' Creates a horizontal bar chart showing the average permutation importance
#' (delta Net Benefit) for each predictor across the evaluated models.
#'
#' @param all_models Data frame returned in the `all_models` element of
#'   [nb_varsel()]. Must include `VIF_*` columns
#'   (generated when `permutation = TRUE`).
#' @param filter Integer or `NULL`. If specified, only the top `filter`
#'   models (by `Avg_Net_Benefit`) are used to compute average importance.
#'   Defaults to `NULL` (use all models).
#' @param color Character string. Fill color for the bars. Defaults to
#'   `"#2A6EBB"`.
#'
#' @return A [ggplot2::ggplot] object.
#'
#' @examples
#' \dontrun{
#' result <- nb_varsel(
#'   data = df, outcome_var = "Y", costs = harms,
#'   mode = "exhaustive", permutation = TRUE,
#'   splines = FALSE, allow_parallel = FALSE
#' )
#' VIF_plot(result$all_models)
#' }
#'
#' @export
VIF_plot <- function(all_models, filter = NULL, color = "#2A6EBB") {
  if (!is.null(filter)) {
    all_models <- all_models |>
      dplyr::slice_max(order_by = .data$Avg_Net_Benefit, n = filter) |>
      dplyr::ungroup()
  }

  vif_means <- all_models |>
    dplyr::select(dplyr::starts_with("VIF")) |>
    colMeans(na.rm = TRUE) |>
    sort(decreasing = TRUE)

  names(vif_means) <- gsub("VIF_", "", names(vif_means))

  plot_df <- data.frame(
    Variable = names(vif_means),
    Average_Delta_NB = unname(vif_means)
  )

  ggplot2::ggplot(
    plot_df,
    ggplot2::aes(
      x = stats::reorder(.data$Variable, -.data$Average_Delta_NB),
      y = .data$Average_Delta_NB
    )
  ) +
    ggplot2::geom_bar(stat = "identity", fill = color) +
    ggplot2::xlab("Predictors") +
    ggplot2::ylab(expression("Average" ~ Delta ~ "NB")) +
    ggplot2::theme_classic() +
    ggplot2::coord_flip()
}
