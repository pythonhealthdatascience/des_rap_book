library(dplyr)
library(future)
library(future.apply)
library(simmer)
library(tidyr)

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
#' @param cores Numeric. Number of CPU cores to use for parallel execution.
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
  cores = 1L,
  verbose = FALSE
) {
  list(
    interarrival_time = interarrival_time,
    consultation_time = consultation_time,
    number_of_doctors = number_of_doctors,
    warm_up_period = warm_up_period,
    data_collection_period = data_collection_period,
    number_of_runs = number_of_runs,
    cores = cores,
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


#' Calculate the mean length of time patients spent with each resource
#'
#' @param arrivals Dataframe with times for each patient with each resource.
#' @param resources Dataframe with times patients use or queue for resources.
#'
#' @importFrom dplyr group_by summarise ungroup
#' @importFrom rlang .data
#' @importFrom tidyr drop_na pivot_wider
#' @importFrom tidyselect any_of
#'
#' @return Tibble with columns containing result for each resource.
#' @export

calc_mean_serve_length <- function(arrivals, resources) {

  # Create subset of data that removes patients who were still waiting
  complete_arrivals <- drop_na(arrivals, any_of("serve_length"))

  # Calculate mean serve time for each resource
  complete_arrivals |>
    group_by(.data[["resource"]]) |>
    summarise(mean_serve_time = mean(.data[["serve_length"]])) |>
    pivot_wider(names_from = "resource",
                values_from = "mean_serve_time",
                names_glue = "mean_time_with_{resource}") |>
    ungroup()
}


#' Calculate the resource utilisation
#'
#' Utilisation is given by the total effective usage time (`in_use`) over
#' the total time intervals considered (`dt`).
#'
#' Credit: The utilisation calculation is adapted from the
#' `plot.resources.utilization()` function in simmer.plot 0.1.18, which is
#' shared under an MIT Licence (Ucar I, Smeets B (2023). simmer.plot: Plotting
#' Methods for 'simmer'. https://r-simmer.org
#' https://github.com/r-simmer/simmer.plot.).
#'
#' @param resources Dataframe with times patients use or queue for resources.
#' @param simulation_end_time Time at end of simulation run.
#' @param groups Optional list of columns to group by for the calculation.
#' @param summarise If TRUE, return overall utilisation. If FALSE, just return
#' the resource dataframe with the additional columns interval_duration,
#' effective_capacity and utilisation.
#'
#' @importFrom dplyr across group_by mutate n row_number summarise ungroup
#' @importFrom rlang .data
#' @importFrom tidyr pivot_wider
#' @importFrom tidyselect all_of
#'
#' @return Tibble with columns containing result for each resource.
#' @export

calc_utilisation <- function(
  resources, simulation_end_time, groups = NULL, summarise = TRUE
) {

  # Create list of grouping variables (always "resource" but can add others)
  group_vars <- c("resource", groups)

  # Calculate utilisation
  util_df <- resources |>
    group_by(across(all_of(group_vars))) |>
    mutate(
      # Calculate time between this row and the next. For final row,
      # lead(time) returns NA, so use simulation_end_time - time
      interval_duration = ifelse(
        row_number() == n(),
        simulation_end_time - .data[["time"]],
        lead(.data[["time"]]) - .data[["time"]]
      ),
      # Ensures effective capacity is never less than number of servers in
      # use (in case of situations where servers may exceed "capacity").
      effective_capacity = pmax(.data[["capacity"]], .data[["server"]]),
      # Divide number of servers in use by effective capacity
      # Set to NA if effective capacity is 0
      utilisation = ifelse(.data[["effective_capacity"]] > 0L,
                           .data[["server"]] / .data[["effective_capacity"]],
                           NA_real_)
    )

  # If summarise = TRUE, find total utilisation
  if (summarise) {
    util_df |>
      summarise(
        # Multiply each utilisation by its own unique duration. The total of
        # those is then divided by the total duration of all intervals.
        # Hence, we are calculated a time-weighted average utilisation.
        utilisation = (sum(.data[["utilisation"]] *
                             .data[["interval_duration"]], na.rm = TRUE) /
                         sum(.data[["interval_duration"]], na.rm = TRUE))
      ) |>
      pivot_wider(names_from = "resource",
                  values_from = "utilisation",
                  names_glue = "utilisation_{resource}") |>
      ungroup()
  } else {
    # If summarise = FALSE, just return the util_df with no further processing
    ungroup(util_df)
  }
}


#' Calculate the time-weighted mean queue length.
#'
#' @param arrivals Dataframe with times for each patient with each resource.
#' @param simulation_end_time Time at end of simulation run.
#'
#' @importFrom dplyr arrange group_by lead mutate n row_number summarise
#' @importFrom dplyr ungroup
#' @importFrom tidyr pivot_wider
#'
#' @return Tibble with column containing mean queue length.
#' @export

calc_mean_queue_length <- function(arrivals, simulation_end_time) {
  arrivals |>
    group_by(.data[["resource"]]) |>
    # Sort by arrival time
    arrange(.data[["start_time"]]) |>
    # Calculate time between this row and the next. For final row,
    # lead(start_time) returns NA, so use simulation_end_time - start_time
    mutate(
      interval_duration = ifelse(
        row_number() == n(),
        simulation_end_time - .data[["start_time"]],
        lead(.data[["start_time"]]) - .data[["start_time"]]
      )
    ) |>
    # Multiply each queue length by its own unique duration. The total of
    # those is then divided by the total duration of all intervals.
    # Hence, we are calculated a time-weighted average queue length.
    summarise(mean_queue_length = (
      sum(.data[["queue_on_arrival"]] *
            .data[["interval_duration"]], na.rm = TRUE) /
        sum(.data[["interval_duration"]], na.rm = TRUE)
    )
    ) |>
    # Reshape dataframe
    pivot_wider(names_from = "resource",
                values_from = "mean_queue_length",
                names_glue = "mean_queue_length_{resource}") |>
    ungroup()
}


#' Calculate the mean time in the system for finished patients.
#'
#' @param arrivals Dataframe with times for each patient with each resource.
#'
#' @importFrom dplyr summarise ungroup
#'
#' @return Tibble with column containing the mean time in the system.
#' @export

calc_mean_time_in_system <- function(arrivals) {
  arrivals |>
    summarise(
      mean_time_in_system = mean(.data[["time_in_system"]], na.rm = TRUE)
    ) |>
    ungroup()
}


#' Calculate the time-weighted mean number of patients in the system.
#'
#' @param patient_count Dataframe with patient counts over time.
#' @param simulation_end_time Time at end of simulation run.
#'
#' @importFrom dplyr arrange lead mutate n row_number summarise ungroup
#'
#' @return Tibble with column containing mean number of patients in the system.
#' @export

calc_mean_patients_in_system <- function(patient_count, simulation_end_time) {
  patient_count |>
    # Sort by time
    arrange(.data[["time"]]) |>
    # Calculate time between this row and the next. For final row,
    # lead(time) returns NA, so use simulation_end_time - time
    mutate(
      interval_duration = ifelse(
        row_number() == n(),
        simulation_end_time - .data[["time"]],
        lead(.data[["time"]]) - .data[["time"]]
      )
    ) |>
    # Multiply each patient count by its own unique duration. The total of
    # those is then divided by the total duration of all intervals.
    # Hence, we are calculated a time-weighted average patient count.
    summarise(
      mean_patients_in_system = (
        sum(.data[["count"]] * .data[["interval_duration"]], na.rm = TRUE) /
          sum(.data[["interval_duration"]], na.rm = TRUE)
      )
    ) |>
    ungroup()
}


#' Get average results for the provided single run.
#'
#' @param results Named list with `arrivals` from `get_mon_arrivals()` and
#'   `resources` from `get_mon_resources()`
#'   (`per_resource = TRUE` and `ongoing = TRUE`).
#' @param run_number Integer index of current simulation run.
#' @param simulation_end_time Time at end of simulation run.
#'
#' @importFrom dplyr bind_cols
#' @importFrom tibble tibble
#'
#' @return Tibble with processed results from replication.
#' @export

get_run_results <- function(results, run_number, simulation_end_time) {
  metrics <- list(
    calc_arrivals(results[["arrivals"]]),
    calc_mean_wait(results[["arrivals"]]),
    calc_mean_serve_length(results[["arrivals"]]),
    calc_utilisation(results[["resources"]], simulation_end_time),
    calc_mean_queue_length(results[["arrivals"]], simulation_end_time),
    calc_mean_time_in_system(results[["arrivals"]]),
    calc_mean_patients_in_system(results[["patients_in_system"]],
                                 simulation_end_time)
  )
  dplyr::bind_cols(tibble(replication = run_number), metrics)
}


#' Run simulation.
#'
#' @param param List. Model parameters.
#' @param run_number Numeric. Run number for random seed generation.
#' @param set_seed Boolean. Whether to set seed within the model function.
#'
#' @importFrom dplyr arrange bind_rows desc left_join mutate transmute
#' @importFrom rlang .data
#' @importFrom simmer add_generator add_resource get_mon_arrivals
#' @importFrom simmer get_attribute get_mon_resources now release run seize
#' @importFrom simmer set_attribute simmer timeout trajectory
#' @importFrom tidyr drop_na pivot_wider
#' @importFrom tidyselect all_of
#'
#' @return Named list with tables `arrivals`, `resources` and `run_results`.
#' @export

model <- function(param, run_number, set_seed = TRUE) {

  # Set random seed based on run number
  if (set_seed) {
    set.seed(run_number)
  }

  # Create simmer environment
  env <- simmer("simulation", verbose = param[["verbose"]])

  # Calculate full run length
  full_run_length <- (param[["warm_up_period"]] +
                        param[["data_collection_period"]])

  # Define the patient trajectory
  patient <- trajectory("consultation") |>
    # Record queue length on arrival
    set_attribute("doctor_queue_on_arrival",
                  function() get_queue_count(env, "doctor")) |>
    seize("doctor", 1L) |>
    # Record time resource is obtained
    set_attribute("doctor_serve_start", function() now(env)) |>
    # Record sampled length of consultation
    set_attribute("doctor_serve_length", function() {
      rexp(n = 1L, rate = 1L / param[["consultation_time"]])
    }) |>
    timeout(function() get_attribute(env, "doctor_serve_length")) |>
    release("doctor", 1L)

  env <- env |>
    # Add doctor resource
    add_resource("doctor", param[["number_of_doctors"]]) |>
    # Add patient generator (mon=2 so can get manual attributes)
    add_generator("patient", patient, function() {
      rexp(n = 1L, rate = 1L / param[["interarrival_time"]])
    }, mon = 2L) |>
    # Run the simulation
    simmer::run(until = full_run_length)

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

  # Add time in system (unfinished patients will set to NaN)
  result[["arrivals"]][["time_in_system"]] <- (
    result[["arrivals"]][["end_time"]] - result[["arrivals"]][["start_time"]]
  )

  # Filter to remove results from the warm-up period
  result <- filter_warmup(result, param[["warm_up_period"]])

  # Gather all start and end times, with a row for each, marked +1 or -1
  # Drop NA for end time, as those are patients who haven't left system
  # at the end of the simulation
  arrivals_start <- transmute(
    result[["arrivals"]], time = .data[["start_time"]], change = 1L
  )
  arrivals_end <- result[["arrivals"]] |>
    drop_na(all_of("end_time")) |>
    transmute(time = .data[["end_time"]], change = -1L)
  events <- bind_rows(arrivals_start, arrivals_end)

  # Determine the count of patients in the service with each entry/exit
  result[["patients_in_system"]] <- events |>
    # Sort events by time
    arrange(.data[["time"]], desc(.data[["change"]])) |>
    # Use cumulative sum to find number of patients in system at each time
    mutate(count = cumsum(.data[["change"]])) |>
    dplyr::select(c("time", "count"))

  # Replace "replication" value with appropriate run number
  result[["arrivals"]] <- mutate(result[["arrivals"]],
                                 replication = run_number)
  result[["resources"]] <- mutate(result[["resources"]],
                                  replication = run_number)
  result[["patients_in_system"]] <- mutate(result[["patients_in_system"]],
                                           replication = run_number)

  # Calculate wait time for each patient
  result[["arrivals"]] <- mutate(
    result[["arrivals"]],
    wait_time = .data[["serve_start"]] - .data[["start_time"]]
  )

  # Calculate the average results for that run
  result[["run_results"]] <- get_run_results(
    result, run_number, simulation_end_time = full_run_length
  )

  result
}


#' Run simulation for multiple replications.
#'
#' @param param Named list of model parameters.
#' @param use_future_seeding Logical. If TRUE, uses the recommended future
#' seeding (`future.seed = seed`), though results will not match `model()`.
#' If FALSE, seeds each run with its run number (like `model()`), though this
#' is discourage by future_lapply documentation.
#'
#' @importFrom future plan multisession sequential
#' @importFrom future.apply future_lapply
#' @importFrom dplyr bind_rows
#'
#' @return List with three tables: arrivals, resources and run_results.
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
    # Recommended option. Base seed used when making others by future.seed
    custom_seed <- 123456L
  } else {
    # Not recommended (but will allow match to model())
    # Generates list of pre-generated seeds set to the run numbers (+ offset)
    create_seeds <- function(seed) {
      set.seed(seed)
      .Random.seed
    }
    custom_seed <- lapply(
      1L:param[["number_of_runs"]] + param[["seed_offset"]],
      create_seeds
    )
  }

  # Run simulations (sequentially or in parallel)
  # Mark set_seed as FALSE as we handle this using future.seed(), rather than
  # within the function, and we don't want to override future.seed
  results <- future_lapply(
    1L:param[["number_of_runs"]],
    function(i) {
      model(run_number = i,
            param = param,
            set_seed = FALSE)
    },
    future.seed = custom_seed
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

  all_patients_in_system <- dplyr::bind_rows(
    lapply(results, function(x) x[["patients_in_system"]])
  )

  # Return a list containing the combined tables
  list(
    arrivals = all_arrivals,
    resources = all_resources,
    run_results = all_run_results,
    patients_in_system = all_patients_in_system
  )
}
