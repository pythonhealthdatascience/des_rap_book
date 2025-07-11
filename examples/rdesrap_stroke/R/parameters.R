#' Acute Stroke Unit (ASU) arrival intervals (days).
#'
#' For example, a value of 1.2 means a new admission every 1.2 days.
#'
#' @param stroke Numeric. Mean days between stroke patient arrivals.
#' @param tia Numeric. Mean days between transient ischaemic attack (TIA)
#' patient arrivals.
#' @param neuro Numeric. Mean days between complex neurological patient
#' arrivals.
#' @param other Numeric. Mean days between other patient arrivals.
#'
#' @return A named list of arrival intervals for ASU.
#' @export

create_asu_arrivals <- function(
  stroke = 1.2, tia = 9.3, neuro = 3.6, other = 3.2
) {
  return(as.list(environment()))
}

#' Rehabilitation unit arrival intervals (days).
#'
#' For example, a value of 21.8 means a new admission every 21.8 days.
#'
#' @param stroke Numeric. Mean days between stroke patient arrivals.
#' @param neuro Numeric. Mean days between complex neurological patient
#' arrivals.
#' @param other Numeric. Mean days between other patient arrivals.
#'
#' @return A named list of arrival intervals for rehabilitation unit.
#' @export

create_rehab_arrivals <- function(
  stroke = 21.8, neuro = 31.7, other = 28.6
) {
  return(as.list(environment()))
}

#' Acute Stroke Unit (ASU) length of stay (LOS) distributions (days).
#'
#' Mean and standard deviation (SD) of LOS in days in the ASU.
#'
#' @param stroke_no_esd_mean Numeric. Mean LOS for stroke patients without early
#' supported discharged (ESD).
#' @param stroke_no_esd_sd Numeric. SD LOS for stroke patients without ESD.
#' @param stroke_esd_mean Numeric. Mean LOS for stroke patients with ESD.
#' @param stroke_esd_sd Numeric. SD LOS for stroke patients with ESD.
#' @param stroke_mortality_mean Numeric. Mean LOS for stroke patients who pass
#' away.
#' @param stroke_mortality_sd Numeric. SD LOS for stroke patients who pass
#' away.
#' @param tia_mean Numeric. Mean LOS for transient ischemic attack (TIA)
#' patients.
#' @param tia_sd Numeric. SD LOS for TIA patients.
#' @param neuro_mean Numeric. Mean LOS for complex neurological patients
#' @param neuro_sd Numeric. SD LOS for complex neurological patients
#' @param other_mean Numeric. Mean LOS for other patients.
#' @param other_sd Numeric. SD LOS for other patients.
#'
#' @return A named list of LOS distributions for ASU.
#' @export

create_asu_los <- function(
  stroke_no_esd_mean = 7.4, stroke_no_esd_sd = 8.61,
  stroke_esd_mean = 4.6, stroke_esd_sd = 4.8,
  stroke_mortality_mean = 7.0, stroke_mortality_sd = 8.7,
  tia_mean = 1.8, tia_sd = 2.3,
  neuro_mean = 4.0, neuro_sd = 5.0,
  other_mean = 3.8, other_sd = 5.2
) {
  list(
    stroke_no_esd = list(mean = stroke_no_esd_mean, sd = stroke_no_esd_sd),
    stroke_esd = list(mean = stroke_esd_mean, sd = stroke_esd_sd),
    stroke_mortality = list(mean = stroke_mortality_mean,
                            sd = stroke_mortality_sd),
    tia = list(mean = tia_mean, sd = tia_sd),
    neuro = list(mean = neuro_mean, sd = neuro_sd),
    other = list(mean = other_mean, sd = other_sd)
  )
}

#' Rehabilitation unit length of stay (LOS) distributions (days).
#'
#' @param stroke_no_esd_mean Numeric. Mean LOS for stroke patients without early
#' supported discharged (ESD).
#' @param stroke_no_esd_sd Numeric. SD LOS for stroke patients without ESD.
#' @param stroke_esd_mean Numeric. Mean LOS for stroke patients with ESD.
#' @param stroke_esd_sd Numeric. SD LOS for stroke patients with ESD.
#' @param tia_mean Numeric. Mean LOS for transient ischemic attack (TIA)
#' patients.
#' @param tia_sd Numeric. SD LOS for TIA patients.
#' @param neuro_mean Numeric. Mean LOS for complex neurological patients
#' @param neuro_sd Numeric. SD LOS for complex neurological patients
#' @param other_mean Numeric. Mean LOS for other patients.
#' @param other_sd Numeric. SD LOS for other patients.
#'
#' @return A named list of LOS distributions for rehabilitation unit.
#' @export

create_rehab_los <- function(
  stroke_no_esd_mean = 28.4, stroke_no_esd_sd = 27.2,
  stroke_esd_mean = 30.3, stroke_esd_sd = 23.1,
  tia_mean = 18.7, tia_sd = 23.5,
  neuro_mean = 27.6, neuro_sd = 28.4,
  other_mean = 16.1, other_sd = 14.1
) {
  list(
    stroke_no_esd = list(mean = stroke_no_esd_mean, sd = stroke_no_esd_sd),
    stroke_esd = list(mean = stroke_esd_mean, sd = stroke_esd_sd),
    tia = list(mean = tia_mean, sd = tia_sd),
    neuro = list(mean = neuro_mean, sd = neuro_sd),
    other = list(mean = other_mean, sd = other_sd)
  )
}

#' ASU routing probabilities.
#'
#' Probabilities of each patient type being transferred from the acute
#' stroke unit (ASU) to other destinations.
#'
#' @param stroke_rehab Numeric. Probability stroke patient to rehab.
#' @param stroke_esd Numeric. Probability stroke patient to early supported
#' discharge (ESD) services.
#' @param stroke_other Numeric. Probability stroke patient to other
#' destinations (e.g., own home, care home, mortality).
#' @param tia_rehab Numeric. Probability transient ischemic attack (TIA)
#' patient to rehab.
#' @param tia_esd Numeric. Probability TIA patient to ESD.
#' @param tia_other Numeric. Probability TIA patient to other.
#' @param neuro_rehab Numeric. Probability complex neurological patient to
#' rehab.
#' @param neuro_esd Numeric. Probability complex neurological patient to ESD.
#' @param neuro_other Numeric. Probability complex neurological patient to
#' other.
#' @param other_rehab Numeric. Probability other patient to rehab.
#' @param other_esd Numeric. Probability other patient to ESD.
#' @param other_other Numeric. Probability other patient to other.
#'
#' @return A named list of routing probabilities for ASU.
#' @export

create_asu_routing <- function(
  stroke_rehab = 0.24, stroke_esd = 0.13, stroke_other = 0.63,
  tia_rehab = 0.01, tia_esd = 0.01, tia_other = 0.98,
  neuro_rehab = 0.11, neuro_esd = 0.05, neuro_other = 0.84,
  other_rehab = 0.05, other_esd = 0.10, other_other = 0.85
) {
  list(
    stroke = list(rehab = stroke_rehab, esd = stroke_esd, other = stroke_other),
    tia = list(rehab = tia_rehab, esd = tia_esd, other = tia_other),
    neuro = list(rehab = neuro_rehab, esd = neuro_esd, other = neuro_other),
    other = list(rehab = other_rehab, esd = other_esd, other = other_other)
  )
}

#' Rehabilitation unit routing probabilities.
#'
#' Probabilities of each patient type being transferred from the rehabilitation
#' unit to other destinations.
#'
#' @param stroke_esd Numeric. Probability stroke patient to early supported
#' discharge (ESD) services.
#' @param stroke_other Numeric. Probability stroke patient to other
#' destinations (e.g., own home, care home, mortality).
#' @param tia_esd Numeric. Probability transient ischemic attack (TIA) patient
#' to ESD.
#' @param tia_other Numeric. Probability TIA patient to other.
#' @param neuro_esd Numeric. Probability complex neurological patient to ESD.
#' @param neuro_other Numeric. Probability complex neurological patient to
#' other.
#' @param other_esd Numeric. Probability other patient to ESD.
#' @param other_other Numeric. Probability other patient to other.
#'
#' @return A named list of routing probabilities for rehabilitation unit.
#' @export

create_rehab_routing <- function(
  stroke_esd = 0.40, stroke_other = 0.60,
  tia_esd = 0L, tia_other = 1L,
  neuro_esd = 0.09, neuro_other = 0.91,
  other_esd = 0.13, other_other = 0.88
) {
  list(
    stroke = list(esd = stroke_esd, other = stroke_other),
    tia = list(esd = tia_esd, other = tia_other),
    neuro = list(esd = neuro_esd, other = neuro_other),
    other = list(esd = other_esd, other = other_other)
  )
}

#' Generate complete parameter list for simulation.
#'
#' @param asu_arrivals List. Acute stroke unit (ASU) arrival intervals.
#' @param rehab_arrivals List. Rehabilitation unit arrival intervals.
#' @param asu_los List. ASU length of stay (LOS) distributions.
#' @param rehab_los List. Rehabilitation unit LOS distributions.
#' @param asu_routing List. ASU routing probabilities.
#' @param rehab_routing List. Rehabilitation unit routing probabilities.
#' @param warm_up_period Integer. Length of warm-up period (days).
#' @param data_collection_period Integer. Length of data collection period
#' (days).
#' @param number_of_runs Integer. Number of simulation runs.
#' @param scenario_name Label for scenario (int|float|string).
#' @param cores Integer. Number of CPU cores to use.
#' @param log_to_console Whether to print activity log to console.
#' @param log_to_file Whether to save activity log to file.
#' @param file_path Path to save log to file.
#'
#' @return A named list of all simulation parameters.
#' @export

create_parameters <- function(
  asu_arrivals = create_asu_arrivals(),
  rehab_arrivals = create_rehab_arrivals(),
  asu_los = create_asu_los(),
  rehab_los = create_rehab_los(),
  asu_routing = create_asu_routing(),
  rehab_routing = create_rehab_routing(),
  warm_up_period = 365L * 3L,  # 3 years
  data_collection_period = 365L * 5L,  # 5 years
  number_of_runs = 150L,
  scenario_name = NULL,
  cores = 1L,
  log_to_console = FALSE,
  log_to_file = FALSE,
  file_path = NULL
) {
  return(as.list(environment()))
}
