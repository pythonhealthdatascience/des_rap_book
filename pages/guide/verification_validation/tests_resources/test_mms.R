library(patrick)
library(testthat)


with_parameters_test_that(
  "simulation is consistent with theoretical MMs queue calculations.",
  {
    # Create theoretical M/M/s queue model
    lambda <- 1L / interarrival_time
    mu <- 1L / consultation_time
    i_mmc <- queueing::NewInput.MMC(
      lambda = lambda, mu = mu, c = number_of_doctors, n = 0L, method = 0L
    )
    theory <- queueing::QueueingModel(i_mmc)

    # Run simulation
    sim <- run_simulation_model(
      interarrival_time = interarrival_time,
      consultation_time = consultation_time,
      number_of_doctors = number_of_doctors
    )

    # Compare results with appropriate tolerance (round to 3dp + 15% tolerance)
    metrics <- list(
      c("RO", "Utilisation"),
      c("Lq", "Queue length"),
      c("W", "System time"),
      c("Wq", "Wait time")
    )
    for (metric in metrics) {
      key <- metric[1L]
      label <- metric[2L]

      sim_val <- round(sim[[key]], 3L)
      theory_val <- round(theory[[key]], 3L)

      expect_equal(
        sim_val,
        theory_val,
        tolerance = 0.15,  # 15% relative tolerance
        info = sprintf(
          "%s mismatch: sim=%.3f, theory=%.3f", label, sim_val, theory_val
        )
      )
    }
  },
  cases(
    # Test case 1: Low utilisation (ρ ≈ 0.3)
    list(interarrival_time = 10L,
         consultation_time = 3L,
         number_of_doctors = 2L),
    # Test case 2: Medium utilisation (ρ ≈ 0.67)
    list(interarrival_time = 6L,
         consultation_time = 4L,
         number_of_doctors = 2L),
    # Test case 3: M/M/1 (ρ = 0.75)
    list(interarrival_time = 4L,
         consultation_time = 3L,
         number_of_doctors = 1L),
    # Test case 4: Multiple servers, high utilisation (ρ ≈ 0.91)
    list(interarrival_time = 5.5,
         consultation_time = 5L,
         number_of_doctors = 3L),
    # Test case 5: Balanced system (ρ = 0.5)
    list(interarrival_time = 8L,
         consultation_time = 4L,
         number_of_doctors = 1L),
    # Test case 6: Many servers, low individual utilisation (ρ ≈ 0.63)
    list(interarrival_time = 4L,
         consultation_time = 10L,
         number_of_doctors = 4L),
    # Test case 7: Very low utilisation (ρ ≈ 0.167)
    list(interarrival_time = 60L,
         consultation_time = 10L,
         number_of_doctors = 15L)
  )
)
