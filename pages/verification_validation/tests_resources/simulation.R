library(dplyr)
library(simmer)
library(tidyr)

#' Calculate the number of arrivals
#'
#' @param arrivals Dataframe with times for each patient with each resource.
#'
#' @importFrom dplyr n_distinct summarise ungroup
#' @importFrom rlang .data
#'
#' @return Tibble with column containing total number of arrivals.
#' @export

calc_arrivals <- function(arrivals) {
  arrivals |>
    summarise(arrivals = n_distinct(.data[["name"]])) |>
    ungroup()
}

#' Calculate the mean wait time for each resource
#'
#' @param arrivals Dataframe with times for each patient with each resource.
#'
#' @importFrom dplyr group_by summarise ungroup
#' @importFrom rlang .data
#' @importFrom tidyr drop_na pivot_wider
#' @importFrom tidyselect any_of
#'
#' @return Tibble with columns containing result for each resource.
#' @export

calc_mean_wait <- function(arrivals) {

  # Create subset of data that removes patients who were still waiting
  complete_arrivals <- drop_na(arrivals, any_of("wait_time"))

  # Calculate mean wait time for each resource
  complete_arrivals |>
    group_by(.data[["resource"]]) |>
    summarise(mean_wait_time = mean(.data[["wait_time"]])) |>
    pivot_wider(names_from = "resource",
                values_from = "mean_wait_time",
                names_glue = "mean_wait_time_{resource}") |>
    ungroup()
}

#' Generate parameter list.
#'
#' @param interarrival_time Numeric. Time between arrivals (minutes).
#' @param consultation_time Numeric. Mean length of doctor's
#'   consultation (minutes).
#' @param number_of_doctors Numeric. Number of doctors.
#' @param warm_up_period Numeric. Duration of the warm-up period (minutes).
#' @param data_collection_period Numeric. Duration of the data collection
#'   period (minutes).
#' @param number_of_runs Numeric. The number of runs (i.e., replications).
#' @param verbose Boolean. Whether to print messages as simulation runs.
#'
#' @return A named list of parameters.
#' @export

create_params <- function(
  interarrival_time = 5L,
  consultation_time = 10L,
  number_of_doctors = 3L,
  warm_up_period = 30L,
  data_collection_period = 40L,
  number_of_runs = 5L,
  verbose = FALSE
) {
  list(
    interarrival_time = interarrival_time,
    consultation_time = consultation_time,
    number_of_doctors = number_of_doctors,
    warm_up_period = warm_up_period,
    data_collection_period = data_collection_period,
    number_of_runs = number_of_runs,
    verbose = verbose
  )
}

#' Filters arrivals and resources to remove warm-up results.
#'
#' @param result Named list with two tables: monitored arrivals & resources.
#' @param warm_up_period Length of warm-up period.
#'
#' @importFrom dplyr arrange filter group_by mutate n slice ungroup
#' @importFrom rlang .data
#'
#' @return The named list `result`, but with the tables (`arrivals` and
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
    calc_mean_wait(results[["arrivals"]])
  )
  dplyr::bind_cols(tibble(replication = run_number), metrics)
}

#' Run simulation.
#'
#' @param param List. Model parameters.
#' @param run_number Numeric. Run number for random seed generation.
#'
#' @importFrom dplyr left_join mutate
#' @importFrom rlang .data
#' @importFrom simmer add_generator add_resource get_mon_arrivals
#' @importFrom simmer get_mon_resources now release run seize set_attribute
#' @importFrom simmer simmer timeout trajectory
#' @importFrom tidyr pivot_wider
#'
#' @return Named list with tables `arrivals`, `resources` and `run_results`.
#' @export

model <- function(param, run_number) {

  # Set random seed based on run number
  set.seed(run_number)

  # Create simmer environment
  env <- simmer("simulation", verbose = param[["verbose"]])

  # Define the patient trajectory
  patient <- trajectory("consultation") |>
    seize("doctor", 1L) |>
    # Record time resource is obtained
    set_attribute("doctor_serve_start", function() now(env)) |>
    timeout(function() {
      rexp(n = 1L, rate = 1L / param[["consultation_time"]])
    }) |>
    release("doctor", 1L)

  env <- env |>
    # Add doctor resource
    add_resource("doctor", param[["number_of_doctors"]]) |>
    # Add patient generator (mon=2 so can get manual attributes)
    add_generator("patient", patient, function() {
      rexp(n = 1L, rate = 1L / param[["interarrival_time"]])
    }, mon = 2L) |>
    # Run the simulation
    simmer::run(until = (param[["warm_up_period"]] +
                           param[["data_collection_period"]]))

  # Extract information on arrivals and resources from simmer environment
  result <- list(
    arrivals = get_mon_arrivals(env, per_resource = TRUE, ongoing = TRUE),
    resources = get_mon_resources(env)
  )

  # Get the extra arrivals attributes
  extra_attributes <- get_mon_attributes(env) |>
    dplyr::select("name", "key", "value") |>
    # Add column with resource name, and remove that from key
    mutate(resource = gsub("_.+", "", .data[["key"]]),
           key = gsub("^[^_]+_", "", .data[["key"]])) |>
    pivot_wider(names_from = "key", values_from = "value")

  # Merge extra attributes with the arrival data
  result[["arrivals"]] <- left_join(
    result[["arrivals"]], extra_attributes, by = c("name", "resource")
  )

  # Filter to remove results from the warm-up period
  result <- filter_warmup(result, param[["warm_up_period"]])

  # Replace "replication" value with appropriate run number
  result[["arrivals"]] <- mutate(result[["arrivals"]],
                                 replication = run_number)
  result[["resources"]] <- mutate(result[["resources"]],
                                  replication = run_number)

  # Calculate wait time for each patient
  result[["arrivals"]] <- result[["arrivals"]] |>
    mutate(wait_time = .data[["serve_start"]] - .data[["start_time"]])

  # Calculate the average results for that run
  result[["run_results"]] <- get_run_results(result, run_number)

  result
}

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
