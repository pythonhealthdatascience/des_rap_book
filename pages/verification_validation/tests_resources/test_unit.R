library(patrick)
library(R.utils)
library(testthat)

with_parameters_test_that("Check that model fails with zero inputs", {
  # Create parameter object with value set to zero
  param <- create_params()
  param[[param_name]] <- 0
  
  # Verify that initialising the model raises an error
  expect_error(
    withTimeout(
      model(param = param, run_number = 0),
      timeout = 3,
      onTimeout = "error"
    ),
    "must be greater than 0"
  )
}, param_name = c("number_of_doctors", "interarrival_time"))
