#' Filters arrivals and resources to remove warm-up results.
#'
#' @param result Named list with two tables: monitored arrivals & resources.
#' @param warm_up_period Length of warm-up period.
#'
#' @importFrom dplyr ungroup arrange slice n filter
#'
#' @return The name list `result`, but with the tables (`arrivals` and
#' `resources`) filtered to remove warm-up results.
#' @export

filter_warmup <- function(result, warm_up_period) {
  # Skip filtering if the warm-up period is zero
  if (warm_up_period == 0L) return(result)

  # Arrivals: Keep only patients who came during the data collection period
  result[["arrivals"]] <- result[["arrivals"]] |>
    group_by(.data[["name"]]) |>
    filter(all(.data[["start_time"]] >= warm_up_period)) |>
    ungroup()

  # Resources: Filter to resource events in the data collection period
  dc_resources <- filter(result[["resources"]],
                         .data[["time"]] >= warm_up_period)

  if (nrow(dc_resources) > 0L) {

    # For each resource, get the last even during warm-up, and replace time
    # for that event with the start time of the data collection period
    last_usage <- result[["resources"]] |>
      filter(.data[["time"]] < warm_up_period) |>
      arrange(.data[["time"]]) |>
      group_by(.data[["resource"]]) |>
      slice(n()) |>
      mutate(time = warm_up_period) |>
      ungroup()

    # Set that last event of the resource/s as the first row of the dataframe
    # else calculations would assume all resources were idle at the start of
    # the data collection period
    result[["resources"]] <- rbind(last_usage, dc_resources)

  } else {
    # No events after warm-up; use filtered resource table as is
    result[["resources"]] <- dc_resources
  }

  result
}
