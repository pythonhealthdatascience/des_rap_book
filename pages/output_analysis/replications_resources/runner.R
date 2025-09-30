#' Run simulation for multiple replications.
#'
#' @param param Named list of model parameters.
#'
#' @return List with three tables: arrivals, resources and run_results.
#' @export

runner <- function(param) {
  # Run simulation for multiple replications
  results <- lapply(
    seq_len(param[["number_of_runs"]]),
    function(i) {
      model(run_number = i, param = param)
    }
  )

  # If only one replication, return without changes
  if (param[["number_of_runs"]] == 1L) {
    return(results[[1L]])
  }

  # Combine results from all replications into unified tables
  all_arrivals <- do.call(
    rbind, lapply(results, function(x) x[["arrivals"]])
  )
  all_resources <- do.call(
    rbind, lapply(results, function(x) x[["resources"]])
  )

  # run_results may have missing data - use bind_rows to fill NAs automatically
  all_run_results <- dplyr::bind_rows(
    lapply(results, function(x) x[["run_results"]])
  )

  # Return a list containing the combined tables
  list(
    arrivals = all_arrivals,
    resources = all_resources,
    run_results = all_run_results
  )
}
