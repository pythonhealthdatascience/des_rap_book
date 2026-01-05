#' Generate parameter list.
#'
#' @param interarrival_time Numeric. Time between arrivals (minutes).
#' @param consultation_time Numeric. Mean length of doctor's
#'   consultation (minutes).
#' @param number_of_doctors Numeric. Number of doctors.
#' @param warm_up_period Numeric. Duration of the warm-up period (minutes).
#' @param data_collection_period Numeric. Duration of the data collection
#'   period (minutes).
#' @param number_of_runs Numeric. The number of runs (i.e., replications).
#' @param verbose Boolean. Whether to print messages as simulation runs.
#'
#' @return A named list of parameters.
#' @export

create_params <- function(
  interarrival_time = 5L,
  consultation_time = 10L,
  number_of_doctors = 3L,
  warm_up_period = 30L,
  data_collection_period = 40L,
  number_of_runs = 5L,
  verbose = FALSE
) {
  list(
    interarrival_time = interarrival_time,
    consultation_time = consultation_time,
    number_of_doctors = number_of_doctors,
    warm_up_period = warm_up_period,
    data_collection_period = data_collection_period,
    number_of_runs = number_of_runs,
    verbose = verbose
  )
}
