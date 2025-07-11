# To avoid package build warning (name in expand.grid())
utils::globalVariables("time")

#' Run simulation.
#'
#' @param run_number Integer representing index of current simulation run.
#' @param param Named list of model parameters.
#' @param set_seed Whether to set seed within the model function (which we
#' may not wish to do if being set elsewhere - such as done in \code{runner()}).
#' Default is TRUE.
#'
#' @importFrom dplyr filter group_by mutate rowwise ungroup
#' @importFrom rlang .data
#' @importFrom simmer add_resource get_mon_arrivals get_mon_resources simmer
#' @importFrom simmer wrap
#' @importFrom utils capture.output
#'
#' @return Named list with two tables: arrivals and occupancy.
#' @export

model <- function(run_number, param, set_seed = TRUE) {

  # Check all inputs are valid
  valid_inputs(run_number, param)

  # Set random seed based on run number
  if (set_seed) {
    set.seed(run_number)
  }

  # Determine whether to get verbose activity logs
  param[["verbose"]] <- any(c(param[["log_to_console"]],
                              param[["log_to_file"]]))

  # Transform LOS parameters to lognormal scale
  param[["asu_los_lnorm"]] <- transform_to_lnorm(param[["asu_los"]])
  param[["rehab_los_lnorm"]] <- transform_to_lnorm(param[["rehab_los"]])

  # Create simmer environment - set verbose to FALSE as using custom logs
  # (but can change to TRUE if want to see default simmer logs as well)
  env <- simmer("simulation", verbose = FALSE,
                log_level = if (param[["verbose"]]) 1L else 0L)

  # Add ASU and rehab direct admission patient generators
  for (unit in c("asu", "rehab")) {

    # Add beds resource with inifinite capacity (required so we can get metrics
    # on occupancy etc. based on count of patients with each resource)
    env <- add_resource(
      .env = env, name = paste0(unit, "_bed"), capacity = Inf
    )

    for (patient_type in names(param[[paste0(unit, "_arrivals")]])) {

      # Create patient trajectory
      traj <- if (unit == "asu") {
        create_asu_trajectory(env, patient_type, param)
      } else {
        create_rehab_trajectory(env, patient_type, param)
      }

      # Add patient generator using the created trajectory
      env <- add_patient_generator(
        env = env,
        trajectory = traj,
        unit = unit,
        patient_type = patient_type,
        param = param
      )
    }
  }

  # Run the model
  sim_length <- param[["data_collection_period"]] + param[["warm_up_period"]]
  sim_log <- capture.output(
    env <- env |> # nolint
      simmer::run(sim_length) |>
      wrap()
  )

  # Save and/or display the log
  if (isTRUE(param[["verbose"]])) {
    # Create full log message by adding parameters
    param_string <- paste(names(param), param, sep = "=", collapse = ";\n ")
    full_log <- append(c("Parameters:", param_string, "Log:"), sim_log)
    # Print to console
    if (isTRUE(param[["log_to_console"]])) {
      print(full_log)
    }
    # Save to file
    if (isTRUE(param[["log_to_file"]])) {
      writeLines(full_log, param[["file_path"]])
    }
  }

  # Extract the monitored arrivals info from the simmer environment object.
  # Remove patients with start time of -1, as they are patients whose arrival
  # was sampled but falls after the end of the simulation.
  arrivals <- get_mon_arrivals(env, per_resource = TRUE, ongoing = TRUE) |>
    filter(.data[["start_time"]] != -1L)

  # Create sequence of days from 0 to end of simulation
  days <- seq(0L, ceiling(sim_length))

  # Calculate occupancy at end of each day (i.e. at time 1, 2, 3, 4...)
  # Make dataframe with one row per resource per day to count patients
  occupancy <- expand.grid(
    resource = unique(arrivals[["resource"]]),
    time = days
  ) |>
    rowwise() |>
    mutate(
      # For each resource and day, count patients who:
      # - Arrived on or before this day (start_time <= time)
      # - Have not yet left by this day (end_time > time), or have NA end_time
      #   (still present at simulation end)
      occupancy = sum(
        arrivals[["resource"]] == .data[["resource"]] &
          arrivals[["start_time"]] <= .data[["time"]] &
          (is.na(arrivals[["end_time"]]) |
             arrivals[["end_time"]] > .data[["time"]])
      )
    ) |>
    ungroup()

  # Set replication
  arrivals <- mutate(arrivals, replication = run_number)
  occupancy <- mutate(occupancy, replication = run_number)

  result <- list(arrivals = arrivals, occupancy = occupancy)

  # Filter the output results if a warm-up period was specified...
  result <- filter_warmup(
    result = result, warm_up_period = param[["warm_up_period"]]
  )

  return(result)
}
