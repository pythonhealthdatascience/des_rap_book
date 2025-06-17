#' Run simulation for multiple replications, sequentially or in parallel.
#'
#' @param param Named list of model parameters.
#' @param use_future_seeding Logical. If TRUE, the function will use the
#' seeding mechanism provided by `future.seed = seed`,  which is generally
#' recommended and ensures reproducibility across parallel executions. However,
#' this will not align exactly with the seeding approach used in `model()`. If
#' FALSE, the function will override future's default seeding and instead
#' generate a list of run numbers to use as seeds,similar to `model()`. Be
#' aware that this approach is not recommended according to `future_lapply`
#' documentation, which states: "Note that as.list(seq_along(x)) is not a valid
#' set of such .Random.seed values."
#'
#' @importFrom future plan multisession sequential
#' @importFrom future.apply future_lapply
#' @importFrom dplyr bind_rows
#'
#' @return Named list with three tables: monitored arrivals, monitored
#' resources, and the processed results from each run.
#' @export

runner <- function(param, use_future_seeding = TRUE) {
  # Determine the parallel execution plan
  if (param[["cores"]] == 1L) {
    plan(sequential)  # Sequential execution
  } else {
    if (param[["cores"]] == -1L) {
      cores <- future::availableCores() - 1L
    } else {
      cores <- param[["cores"]]
    }
    plan(multisession, workers = cores)  # Parallel execution
  }

  # Set seed for future.seed
  if (isTRUE(use_future_seeding)) {
    # Recommended option - base seed used when generating others by future.seed
    custom_seed <- 123456L
  } else {
    # Not recommended (but will allow match to model())
    # Generates list of pre-generated seeds set to the run numbers
    create_seeds <- function(seed) {
      set.seed(seed)
      .Random.seed
    }
    custom_seed <- lapply(1L:param[["number_of_runs"]], create_seeds)
  }

  # Run simulations (sequentially or in parallel)
  # Mark set_seed as FALSE as we handle this using future.seed(), rather than
  # within the function, and we don't want to override future.seed
  results <- future_lapply(
    1L:param[["number_of_runs"]],
    function(i) {
      simulation::model(run_number = i,
                        param = param,
                        set_seed = FALSE)
    },
    future.seed = custom_seed
  )

  # Combine the results from multiple replications into just two dataframes
  if (param[["number_of_runs"]] == 1L) {
    results <- results[[1L]]
  } else {
    all_arrivals <- do.call(
      rbind, lapply(results, function(x) x[["arrivals"]])
    )
    all_resources <- do.call(
      rbind, lapply(results, function(x) x[["resources"]])
    )
    # Bind rows will fill NA - e.g. if some runs have no results columns
    # as had no arrivals, will set those to NA for that row
    all_patients_in_service <- dplyr::bind_rows(
      lapply(results, function(x) x[["patients_in_service"]])
    )
    all_run_results <- dplyr::bind_rows(
      lapply(results, function(x) x[["run_results"]])
    )
    results <- list(arrivals = all_arrivals,
                    resources = all_resources,
                    patients_in_service = all_patients_in_service,
                    run_results = all_run_results)
  }

  return(results) # nolint
}
