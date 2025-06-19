#' Create a named list of default model parameters (which can be altered).
#'
#' When input to model(), valid_inputs() will fetch the inputs to this
#' function and compare them against the provided list, to ensure no
#' new keys have been add to the list.
#'
#' @param patient_inter Mean inter-arrival time between patients in minutes.
#' @param mean_n_consult_time Mean nurse consultation time in minutes.
#' @param number_of_nurses Number of available nurses (int).
#' @param warm_up_period Duration of warm-up period in minutes.
#' @param data_collection_period Duration of data collection period in
#' minutes.
#' @param number_of_runs Number of simulation runs (int).
#' @param scenario_name Label for the scenario (int|float|string).
#' @param cores Number of cores to use for parallel execution (int).
#' @param log_to_console Whether to print activity log to console.
#' @param log_to_file Whether to save activity log to file.
#' @param file_path Path to save log to file.
#'
#' @return A named list containing the parameters for the model.
#' @export

parameters <- function(
  patient_inter = 4L,
  mean_n_consult_time = 10L,
  number_of_nurses = 5L,
  warm_up_period = 0L,
  data_collection_period = 80L,
  number_of_runs = 100L,
  scenario_name = NULL,
  cores = 1L,
  log_to_console = FALSE,
  log_to_file = FALSE,
  file_path = NULL
) {
  return(as.list(environment()))
}
