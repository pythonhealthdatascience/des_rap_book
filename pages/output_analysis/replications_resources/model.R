#' Run simulation.
#'
#' @param param List. Model parameters.
#' @param run_number Numeric. Run number for random seed generation.
#'
#' @importFrom dplyr mutate
#' @importFrom simmer add_generator get_mon_arrivals get_mon_resources run
#' @importFrom simmer set_attribute simmer timeout trajectory

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
