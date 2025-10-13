library(patrick)
library(R.utils)
library(testthat)

with_parameters_test_that("Check that model fails with zero inputs", {
  # Create parameter object with value set to zero
  param <- create_params()
  param[[param_name]] <- 0L

  # Verify that initialising the model raises an error
  expect_error(
    withTimeout(
      model(param = param, run_number = 0L),
      timeout = 3L,
      onTimeout = "error"
    ),
    "must be greater than 0"
  )
}, param_name = c("number_of_doctors", "interarrival_time"))
