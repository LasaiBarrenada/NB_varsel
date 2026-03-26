#' All-Subset Model Comparison Plot
#'
#' Creates a two-panel figure: the top panel shows a performance metric
#' across all evaluated models (ordered by number of predictors then by
#' metric value), and the bottom panel shows a heatmap of which predictors
#' are included in each model.
#'
#' @param all_models Data frame returned in the `all_models` element of
#'   [nb_varsel()].
#' @param metric Character string. Column name in `all_models` to plot on
#'   the y-axis. Defaults to `"Avg_Net_Benefit"`.
#' @param y_axis Character string. Label for the y-axis of the top panel.
#'   Defaults to `"Average Net Benefit"`.
#' @param filter Integer. When there are more than 100 models, keep only
#'   the top `filter` models per number of predictors. Defaults to 5.
#' @param size_dot Numeric. Point size in the metric plot. Defaults to 3.
#' @param highlight_color Character string. Color for the dashed lines
#'   marking the best model. Defaults to `"red"`.
#' @param tile_color Character string. Fill color for "present" tiles in
#'   the heatmap panel. Defaults to `"#2A6EBB"`.
#' @param p1_theme A [ggplot2::theme()] object to add to the top panel, or
#'   `NULL`.
#' @param p2_theme A [ggplot2::theme()] object to add to the bottom panel,
#'   or `NULL`.
#'
#' @return A [patchwork] object (two stacked ggplot panels).
#'
#' @examples
#' \dontrun{
#' result <- nb_varsel(
#'   data = df, outcome_var = "Y", costs = harms,
#'   mode = "exhaustive", splines = FALSE, allow_parallel = FALSE
#' )
#' all_subset_plot(result$all_models)
#' }
#'
#' @export
all_subset_plot <- function(
    all_models,
    metric = "Avg_Net_Benefit",
    y_axis = "Average Net Benefit",
    filter = 5,
    size_dot = 3,
    highlight_color = "red",
    tile_color = "#2A6EBB",
    p1_theme = NULL,
    p2_theme = NULL
) {
  # --- 1. Data Preparation ---
  all_vars <- all_models$Model |>
    stringr::str_split(",") |>
    unlist() |>
    stringr::str_trim() |>
    unique()

  df_sorted <- all_models |>
    dplyr::arrange(.data$n_Preds, .data[[metric]]) |>
    dplyr::mutate(model_id = dplyr::row_number())

  # --- 2. Filtering ---
  if (nrow(df_sorted) > 100) {
    message(sprintf("Filtered to best %d per number of predictors.", filter))
    top_models <- df_sorted |>
      dplyr::group_by(.data$n_Preds) |>
      dplyr::slice_max(order_by = .data[[metric]], n = filter) |>
      dplyr::ungroup()
    df_sorted <- df_sorted |>
      dplyr::filter(.data$model_id %in% top_models$model_id) |>
      dplyr::mutate(model_id = dplyr::row_number())
  }

  # --- 3. Expand Data for Heatmap ---
  df_long <- df_sorted |>
    dplyr::select("model_id", "n_Preds", "Model") |>
    tidyr::separate_rows("Model", sep = ",") |>
    dplyr::mutate(predictor = stringr::str_trim(.data$Model)) |>
    dplyr::filter(.data$predictor %in% all_vars) |>
    dplyr::mutate(is_present = 1) |>
    tidyr::complete(
      model_id = .data$model_id,
      predictor = all_vars,
      fill = list(is_present = 0)
    ) |>
    dplyr::group_by(.data$model_id) |>
    tidyr::fill("n_Preds", .direction = "downup") |>
    dplyr::ungroup()

  # --- 4. Identify Best Model ---
  max_nb_value <- max(df_sorted[[metric]])
  best_model_idx <- which.max(df_sorted[[metric]])
  x_at_max <- df_sorted$model_id[best_model_idx]

  best_model_preds <- df_sorted$Model[best_model_idx] |>
    stringr::str_split(",") |>
    unlist() |>
    stringr::str_trim()

  # --- 5. Prepare Bolding Logic ---
  sorted_preds <- sort(unique(df_long$predictor))
  df_long$predictor <- factor(df_long$predictor, levels = sorted_preds)

  markdown_labels <- stats::setNames(
    ifelse(
      sorted_preds %in% best_model_preds,
      paste0("**", sorted_preds, "**"),
      sorted_preds
    ),
    sorted_preds
  )

  x_limits <- range(df_sorted$model_id) + c(-1, 1)
  model_breaks <- df_sorted$model_id

  # --- 6. Top Panel (Metric Plot) ---
  p1 <- ggplot2::ggplot(
    df_sorted,
    ggplot2::aes(x = .data$model_id, y = .data[[metric]])
  ) +
    ggplot2::geom_line(color = "black") +
    ggplot2::geom_point(
      size = size_dot,
      ggplot2::aes(color = .data$n_Preds)
    ) +
    ggplot2::theme_classic() +
    ggplot2::labs(y = y_axis, x = "") +
    ggplot2::scale_x_continuous(
      limits = x_limits, expand = c(0, 0.5), breaks = model_breaks
    ) +
    ggplot2::geom_hline(
      yintercept = max_nb_value, linetype = "dashed", color = highlight_color
    ) +
    ggplot2::scale_color_viridis_c(
      name = "Number of Predictors",
      option = "D",
      guide = ggplot2::guide_colorbar(
        title.position = "top",
        title.hjust = 0.5,
        barwidth = ggplot2::unit(4, "cm"),
        barheight = ggplot2::unit(0.3, "cm")
      )
    ) +
    ggplot2::geom_vline(
      xintercept = x_at_max, linetype = "dashed", color = highlight_color
    ) +
    ggplot2::theme(
      legend.margin = ggplot2::margin(t = -10, b = 0, unit = "pt"),
      legend.box.spacing = ggplot2::unit(0, "cm"),
      axis.text.x = ggplot2::element_blank(),
      axis.title.x = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_line(
        color = "grey90", linewidth = 0.3
      ),
      axis.ticks.x = ggplot2::element_blank(),
      legend.position = "top"
    ) +
    p1_theme

  # --- 7. Bottom Panel (Heatmap) ---
  p2 <- ggplot2::ggplot(
    df_long,
    ggplot2::aes(x = .data$model_id, y = .data$predictor)
  ) +
    ggplot2::geom_tile(
      ggplot2::aes(fill = factor(.data$is_present)),
      color = "white", height = 0.9, width = 0.9
    ) +
    ggplot2::scale_fill_manual(
      values = c("0" = "white", "1" = tile_color)
    ) +
    ggplot2::labs(x = "Number of Predictors", y = NULL) +
    ggplot2::scale_y_discrete(labels = markdown_labels) +
    ggplot2::scale_x_continuous(
      limits = x_limits,
      breaks = df_sorted$model_id,
      labels = df_sorted$n_Preds,
      expand = c(0, 0.5)
    ) +
    ggplot2::theme_classic() +
    ggplot2::theme(
      panel.grid = ggplot2::element_blank(),
      axis.text.y = ggtext::element_markdown(color = "black"),
      legend.position = "none",
      axis.text.x = ggplot2::element_text(size = 4)
    ) +
    p2_theme

  patchwork::wrap_plots(p1, p2, ncol = 1, heights = c(3, 1))
}
