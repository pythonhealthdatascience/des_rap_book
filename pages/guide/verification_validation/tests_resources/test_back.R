test_that("results from a new run match those previously generated", {
  # Define model parameters
  param <- create_params(
    interarrival_time = 5L,
    consultation_time = 10L,
    number_of_doctors = 3L,
    warm_up_period = 30L,
    data_collection_period = 40L,
    number_of_runs = 5L, verbose = FALSE
  )

  # Run simulation
  results <- runner(param)

  # Import expected results
  exp_arrivals <- read.csv(test_path("r_arrivals.csv"))
  exp_resources <- read.csv(test_path("r_resources.csv"))
  exp_run_results <- read.csv(test_path("r_run_results.csv"))

  # Compare results
  expect_equal(
    as.data.frame(arrange(results[["arrivals"]], replication, start_time)),
    as.data.frame(arrange(exp_arrivals, replication, start_time))
  )
  expect_equal(as.data.frame(results[["resources"]]), exp_resources)
  expect_equal(as.data.frame(results[["run_results"]]), exp_run_results)
})
