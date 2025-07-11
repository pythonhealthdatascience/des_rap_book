#' Filters arrivals and occupancy to remove warm-up patients.
#'
#' @param result Named list with two tables: arrivals & occupancy.
#' @param warm_up_period Length of warm-up period.
#'
#' @importFrom dplyr filter group_by ungroup
#'
#' @return The name list `result`, but with the tables (`arrivals` and
#' `occupancy`) filtered to remove warm-up patients.
#' @export

filter_warmup <- function(result, warm_up_period) {
  if (warm_up_period > 0L) {
    result[["arrivals"]] <- result[["arrivals"]] |>
      group_by(.data[["name"]]) |>
      filter(all(.data[["start_time"]] >= warm_up_period)) |>
      ungroup()
    result[["occupancy"]] <- filter(result[["occupancy"]],
                                    time >= warm_up_period)
  }
  result
}
