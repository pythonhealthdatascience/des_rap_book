#' Get average results for the provided single run.
#'
#' @param results Named list with `arrivals` from `get_mon_arrivals()` and
#'   `resources` from `get_mon_resources()`
#'   (`per_resource = TRUE` and `ongoing = TRUE`).
#' @param run_number Integer index of current simulation run.
#'
#' @importFrom dplyr bind_cols
#' @importFrom tibble tibble
#'
#' @return Tibble with processed results from replication.
#' @export

get_run_results <- function(results, run_number) {
  metrics <- list(
    calc_arrivals(results[["arrivals"]]),
    calc_mean_wait(results[["arrivals"]]),
    calc_mean_serve_length(results[["arrivals"]]),
    calc_utilisation(results[["resources"]]),
    calc_mean_queue_length(results[["arrivals"]]),
    calc_mean_time_in_system(results[["arrivals"]]),
    calc_mean_patients_in_system(results[["patients_in_system"]])
  )
  dplyr::bind_cols(tibble(replication = run_number), metrics)
}
