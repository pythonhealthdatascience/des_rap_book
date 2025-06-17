#' Time series inspection method for determining length of warm-up.
#'
#' Find the cumulative mean results and plot over time (overall and per run).
#'
#' @param result Named list with `arrivals` containing output from
#' `get_mon_arrivals()` and `resources` containing output from
#' `get_mon_resources()` (`per_resource = TRUE` and `ongoing = TRUE`).
#' @param file_path Path to save figure to.
#' @param warm_up Location on X axis to plot vertical red line indicating the
#' chosen warm-up period. Defaults to NULL, which will not plot a line.
#'
#' @importFrom dplyr rename
#' @importFrom ggplot2 ggplot geom_line aes_string labs theme_minimal geom_vline
#' @importFrom ggplot2 annotate ggsave
#' @importFrom gridExtra marrangeGrob
#'
#' @export

time_series_inspection <- function(result, file_path, warm_up = NULL) {

  plot_list <- list()

  # Collect dataframes with metrics at each timepoint (relabelled "time" for
  # all). If you have multiple resources, would need to run time series
  # inspection on each resource. As this is not the case here, have just
  # selected replication, time and the metric.
  metrics <- list()

  # Wait time of each patient at each time point
  metrics[[1L]] <- result[["arrivals"]] %>%
    rename(time = .data[["serve_start"]]) %>%
    select(.data[["replication"]],
           .data[["time"]],
           .data[["wait_time"]])

  # Service length of each patient at each time point
  metrics[[2L]] <- result[["arrivals"]] %>%
    rename(time = .data[["serve_start"]]) %>%
    select(.data[["replication"]],
           .data[["time"]],
           .data[["serve_length"]])

  # Utilisation at each time point
  metrics[[3L]] <- calc_utilisation(result[["resources"]],
                                    groups = c("resource", "replication"),
                                    summarise = FALSE) %>%
    select(.data[["replication"]],
           .data[["time"]],
           .data[["utilisation"]])

  # Loop through all the dataframes in df_list
  for (i in seq_along(metrics)) {

    # Get name of the metric
    metric <- setdiff(names(metrics[[i]]), c("time", "replication"))

    # Calculate cumulative mean for the current metric
    cumulative <- metrics[[i]] %>%
      arrange(.data[["replication"]], .data[["time"]]) %>%
      group_by(.data[["replication"]]) %>%
      mutate(cumulative_mean = cumsum(.data[[metric]]) /
               seq_along(.data[[metric]])) %>%
      ungroup()

    # Repeat calculation, but including all replications in one
    overall_cumulative <- metrics[[i]] %>%
      arrange(.data[["time"]]) %>%
      mutate(cumulative_mean = cumsum(.data[[metric]]) /
               seq_along(.data[[metric]])) %>%
      ungroup()

    # Create plot
    p <- ggplot() +
      geom_line(data = cumulative,
                aes_string(x = "time", y = "cumulative_mean",
                           group = "replication"),
                color = "lightblue", alpha = 0.8) +
      geom_line(data = overall_cumulative,
                aes_string(x = "time", y = "cumulative_mean"),
                color = "darkblue") +
      labs(x = "Run time (minutes)", y = paste("Cumulative mean", metric)) +
      theme_minimal()

    # Add line to indicate suggested warm-up length if provided
    if (!is.null(warm_up)) {
      p <- p +
        geom_vline(xintercept = warm_up, linetype = "dashed", color = "red") +
        annotate("text", x = warm_up, y = Inf,
                 label = "Suggested warm-up length",
                 color = "red", hjust = -0.1, vjust = 1L)
    }
    # Store the plot
    plot_list[[i]] <- p
  }

  # Arrange plots in a single column
  combined_plot <- marrangeGrob(plot_list, ncol = 1L, nrow = length(plot_list),
                                top = NULL)

  # Save to file
  ggsave(file_path, combined_plot, width = 8L, height = 4L * length(plot_list))
}
