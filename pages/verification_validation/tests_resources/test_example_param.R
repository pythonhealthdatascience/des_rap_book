library(patrick)
library(testthat)

with_parameters_test_that("Confirm that the number is positive", {
  expect_gt(number, 0L)
}, number = c(1L, 2L, 3L, -1L))
