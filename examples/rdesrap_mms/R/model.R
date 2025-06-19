#' Run simulation.
#'
#' @param run_number Integer representing index of current simulation run.
#' @param param Named list of model parameters.
#' @param set_seed Whether to set seed within the model function (which we
#' may not wish to do if being set elsewhere - such as done in runner()).
#' Default is TRUE.
#'
#' @importFrom simmer trajectory seize timeout release simmer add_resource
#' @importFrom simmer add_generator run wrap get_mon_arrivals set_attribute
#' @importFrom simmer get_attribute get_mon_attributes get_queue_count
#' @importFrom magrittr %>%
#' @importFrom stats rexp
#' @importFrom utils capture.output
#' @importFrom dplyr select left_join transmute desc
#' @importFrom tidyselect all_of
#'
#' @return Named list with three tables: monitored arrivals,
#' monitored resources, and the processed results from the run.
#' @export

model <- function(run_number, param, set_seed = TRUE) {

  # Check all inputs are valid
  valid_inputs(run_number, param)

  # Set random seed based on run number
  if (set_seed) {
    set.seed(run_number)
  }

  # Determine whether to get verbose activity logs
  verbose <- any(c(param[["log_to_console"]], param[["log_to_file"]]))

  # Create simmer environment
  env <- simmer("simulation", verbose = verbose)

  # Define the patient trajectory
  patient <- trajectory("appointment") %>%
    # Record queue length on arrival
    set_attribute("nurse_queue_on_arrival",
                  function() get_queue_count(env, "nurse")) %>%
    seize("nurse", 1L) %>%
    # Manually record the time when the patient is served (i.e. resource
    # becomes available) and the sampled length of the activity.
    set_attribute("nurse_serve_start", function() now(env)) %>%
    set_attribute("nurse_serve_length", function() {
      rexp(n = 1L, rate = 1L / param[["mean_n_consult_time"]])
    }) %>%
    timeout(function() get_attribute(env, "nurse_serve_length")) %>%
    release("nurse", 1L)

  # Add nurse resource and patient generator to the simmer environment and
  # run the simulation. Capture output, which will save a log if verbose=TRUE
  sim_log <- capture.output(
    env <- env %>% # nolint
      add_resource("nurse", param[["number_of_nurses"]]) %>%
      # Set mon=2 to get our manual attributes
      add_generator("patient", patient, function() {
        rexp(n = 1L, rate = 1L / param[["patient_inter"]])
      }, mon = 2L) %>%
      simmer::run(param[["warm_up_period"]] +
                    param[["data_collection_period"]]) %>%
      wrap()
  )

  # Save and/or display the log
  if (isTRUE(verbose)) {
    # Create full log message by adding parameters
    param_string <- paste(names(param), param, sep = "=", collapse = "; ")
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

  # Extract the monitored arrivals and resources information from the simmer
  # environment object
  result <- list(
    arrivals = get_mon_arrivals(env, per_resource = TRUE, ongoing = TRUE),
    resources = get_mon_resources(env)
  )

  if (nrow(result[["arrivals"]]) > 0L) {

    # Get the extra arrivals attributes
    extra_attributes <- get_mon_attributes(env) %>%
      select("name", "key", "value") %>%
      # Add column with resource name, and remove that from key
      mutate(resource = gsub("_.+", "", .data[["key"]]),
             key = gsub("^[^_]+_", "", .data[["key"]])) %>%
      pivot_wider(names_from = "key", values_from = "value")

    # Merge extra attributes with the arrival data
    result[["arrivals"]] <- left_join(
      result[["arrivals"]], extra_attributes, by = c("name", "resource")
    )

    # Filter the output results if a warm-up period was specified...
    if (param[["warm_up_period"]] > 0L) {
      result <- filter_warmup(result, param[["warm_up_period"]])
    }

    # Gather all start and end times, with a row for each, marked with +1 or -1
    # Drop NA for end time, as those are patients who haven't left system
    # at the end of the simulation
    arrivals_start <- transmute(
      result[["arrivals"]], time = .data[["start_time"]], change = 1L
    )
    arrivals_end <- result[["arrivals"]] %>%
      drop_na(all_of("end_time")) %>%
      transmute(time = .data[["end_time"]], change = -1L)
    events <- bind_rows(arrivals_start, arrivals_end)

    # Determine the count of patients in the service with each entry/exit
    result[["patients_in_service"]] <- events %>%
      # Sort events by time
      arrange(.data[["time"]], desc(.data[["change"]])) %>%
      # Use cumulative sum to find number of patients in system at each time
      mutate(count = cumsum(.data[["change"]])) %>%
      dplyr::select(c("time", "count"))

    # Replace replication with appropriate run number (as these functions
    # assume, if not supplied with list of envs, that there was one replication)
    result[["arrivals"]] <- mutate(result[["arrivals"]],
                                   replication = run_number)
    result[["resources"]] <- mutate(result[["resources"]],
                                    replication = run_number)
    result[["patients_in_service"]] <- mutate(result[["patients_in_service"]],
                                              replication = run_number)

    # Calculate the wait time of patients who were seen, and also for those
    # who remained unseen at the end of the simulation
    result[["arrivals"]] <- result[["arrivals"]] %>%
      mutate(
        wait_time = .data[["serve_start"]] - .data[["start_time"]],
        wait_time_unseen = ifelse(
          is.na(.data[["serve_start"]]),
          now(env) - .data[["start_time"]], NA
        )
      )

  } else {
    result[["patients_in_service"]] <- NULL
  }

  # Calculate the average results for that run and add to result list
  result[["run_results"]] <- get_run_results(result, run_number)

  return(result)
}
