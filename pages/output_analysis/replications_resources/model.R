#' Run simulation.
#'
#' @param param List. Model parameters.
#' @param run_number Numeric. Run number for random seed generation.
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

model <- function(param, run_number) {

  # Set random seed based on run number
  set.seed(run_number)

  # Create simmer environment
  env <- simmer("simulation", verbose = param[["verbose"]])

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
  result[["arrivals"]] <- result[["arrivals"]] |>
    mutate(wait_time = .data[["serve_start"]] - .data[["start_time"]])

  # Calculate the average results for that run
  result[["run_results"]] <- get_run_results(result, run_number)

  result
}
