library(patrick)
library(testthat)

with_parameters_test_that("Confirm that the number is positive", {
  expect_true(number > 0)  
}, number = c(1, 2, 3, -1))
