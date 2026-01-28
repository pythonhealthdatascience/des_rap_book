#' Run simulation.
#'
#' @param param List. Model parameters.
#' @param run_number Numeric. Run number for random seed generation.
#'
#' @return Named list with tables `arrivals`, `resources` and `run_results`. #<<
#' @export

model <- function(param, run_number) {

  # Set random seed based on run number
  set.seed(run_number)

  # Create simmer environment
  env <- simmer("simulation", verbose = param[["verbose"]])

  # Define the patient trajectory
  patient <- trajectory("consultation") |>
    seize("doctor", 1L) |>
    timeout(function() {
      rexp(n = 1L, rate = 1L / param[["consultation_time"]])
    }) |>
    release("doctor", 1L)

  env <- env |>
    # Add doctor resource
    add_resource("doctor", param[["number_of_doctors"]]) |>
    # Add patient generator
    add_generator("patient", patient, function() {
      rexp(n = 1L, rate = 1L / param[["interarrival_time"]])
    }) |>
    # Run the simulation
    simmer::run(until = (param[["warm_up_period"]] +
                           param[["data_collection_period"]]))

  # Extract information on arrivals and resources from simmer environment
  result <- list(
    arrivals = get_mon_arrivals(env, per_resource = TRUE, ongoing = TRUE),
    resources = get_mon_resources(env)
  )

  # Filter to remove results from the warm-up period #<<
  result <- filter_warmup(result, param[["warm_up_period"]]) #<<

  # Replace "replication" value with appropriate run number#<<
  result[["arrivals"]] <- mutate(result[["arrivals"]], #<<
                                 replication = run_number) #<<
  result[["resources"]] <- mutate(result[["resources"]], #<<
                                  replication = run_number) #<<

  # Calculate the average results for that run #<<
  result[["run_results"]] <- get_run_results(result, run_number) #<<

  result
}
