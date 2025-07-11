#' Add patient generator to Simmer environment.
#'
#' Creates a patient generator using an exponential inter-arrival distribution.
#' The generator name is automatically constructed as \{unit\}_\{patient_type\}.
#'
#' @param env Simmer environment object. The simulation environment where
#' generators will be added.
#' @param trajectory Simmer trajectory object. Defines patient journey logic
#' through the healthcare system.
#' @param unit Character string specifying the care unit. Must be either "asu"
#' (Acute Stroke Unit) or "rehab" (Rehabilitation Unit). Used to access correct
#' parameter set and name the generator.
#' @param patient_type Character string specifying patient category. Must be
#' one of: "stroke", "tia", "neuro", or "other". Determines which arrival rate
#' parameter is used.
#' @param param Nested list containing simulation parameters. Must have
#' structure \code{param$<unit>_arrivals$<patient_type>} containing numeric
#' arrival intervals (e.g., \code{param$asu_arrivals$stroke = 10}).
#'
#' @importFrom simmer add_generator
#' @importFrom stats rexp
#'
#' @return The modified Simmer environment with the new patient generator added.
#' @export

add_patient_generator <- function(env, trajectory, unit, patient_type, param) {
  add_generator(
    .env = env,
    name_prefix = paste0(unit, "_", patient_type),
    trajectory = trajectory,
    distribution = function() {
      rexp(1L, 1L / param[[paste0(unit, "_arrivals")]][[patient_type]])
    }
  )
}
