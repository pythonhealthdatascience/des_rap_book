#' Calculate the number of arrivals
#'
#' @param arrivals Dataframe with times for each patient with each resource.
#'
#' @importFrom dplyr n_distinct summarise ungroup
#' @importFrom rlang .data
#'
#' @return Tibble with column containing total number of arrivals.
#' @export

calc_arrivals <- function(arrivals) {
  arrivals |>
    summarise(arrivals = n_distinct(.data[["name"]])) |>
    ungroup()
}


#' Calculate the mean wait time for each resource
#'
#' @param arrivals Dataframe with times for each patient with each resource.
#'
#' @importFrom dplyr group_by summarise ungroup
#' @importFrom rlang .data
#' @importFrom tidyr drop_na pivot_wider
#' @importFrom tidyselect any_of
#'
#' @return Tibble with columns containing result for each resource.
#' @export

calc_mean_wait <- function(arrivals) {

  # Create subset of data that removes patients who were still waiting
  complete_arrivals <- drop_na(arrivals, any_of("wait_time"))

  # Calculate mean wait time for each resource
  complete_arrivals |>
    group_by(.data[["resource"]]) |>
    summarise(mean_wait_time = mean(.data[["wait_time"]])) |>
    pivot_wider(names_from = "resource",
                values_from = "mean_wait_time",
                names_glue = "mean_wait_time_{resource}") |>
    ungroup()
}


#' Calculate the mean length of time patients spent with each resource
#'
#' @param arrivals Dataframe with times for each patient with each resource.
#' @param resources Dataframe with times patients use or queue for resources.
#'
#' @importFrom dplyr group_by summarise ungroup
#' @importFrom rlang .data
#' @importFrom tidyr drop_na pivot_wider
#' @importFrom tidyselect any_of
#'
#' @return Tibble with columns containing result for each resource.
#' @export

calc_mean_serve_length <- function(arrivals, resources) {

  # Create subset of data that removes patients who were still waiting
  complete_arrivals <- drop_na(arrivals, any_of("serve_length"))

  # Calculate mean serve time for each resource
  complete_arrivals |>
    group_by(.data[["resource"]]) |>
    summarise(mean_serve_time = mean(.data[["serve_length"]])) |>
    pivot_wider(names_from = "resource",
                values_from = "mean_serve_time",
                names_glue = "mean_time_with_{resource}") |>
    ungroup()
}


#' Calculate the resource utilisation
#'
#' Utilisation is given by the total effective usage time (`in_use`) over
#' the total time intervals considered (`dt`).
#'
#' Credit: The utilisation calculation is adapted from the
#' `plot.resources.utilization()` function in simmer.plot 0.1.18, which is
#' shared under an MIT Licence (Ucar I, Smeets B (2023). simmer.plot: Plotting
#' Methods for 'simmer'. https://r-simmer.org
#' https://github.com/r-simmer/simmer.plot.).
#'
#' @param resources Dataframe with times patients use or queue for resources.
#' @param groups Optional list of columns to group by for the calculation.#<<
#' @param summarise If TRUE, return overall utilisation. If FALSE, just#<<
#' return the resource dataframe with the additional columns#<<
#' interval_duration, effective_capacity and utilisation.#<<
#'
#' @importFrom dplyr across group_by mutate ungroup#<<
#' @importFrom rlang .data
#' @importFrom tidyr pivot_wider
#' @importFrom tidyselect all_of#<<
#'
#' @return Tibble with columns containing result for each resource.
#' @export

calc_utilisation <- function(resources, groups = NULL, summarise = TRUE) {#<<

  # Create list of grouping variables (always "resource" but can add others)#<<
  group_vars <- c("resource", groups)#<<

  # Calculate utilisation
  util_df <- resources |>
    group_by(across(all_of(group_vars))) |>#<<
    mutate(
      # Time between this row and the next
      interval_duration = lead(.data[["time"]]) - .data[["time"]],
      # Ensures effective capacity is never less than number of servers in
      # use (in case of situations where servers may exceed "capacity").
      effective_capacity = pmax(.data[["capacity"]], .data[["server"]]),
      # Divide number of servers in use by effective capacity
      # Set to NA if effective capacity is 0
      utilisation = ifelse(.data[["effective_capacity"]] > 0L,
                           .data[["server"]] / .data[["effective_capacity"]],
                           NA_real_)
    )

  # If summarise = TRUE, find total utilisation#<<
  if (summarise) {#<<
    util_df |>
      summarise(
        # Multiply each utilisation by its own unique duration. The total of
        # those is then divided by the total duration of all intervals.
        # Hence, we are calculated a time-weighted average utilisation.
        utilisation = (sum(.data[["utilisation"]] *
                             .data[["interval_duration"]], na.rm = TRUE) /
                         sum(.data[["interval_duration"]], na.rm = TRUE))
      ) |>
      pivot_wider(names_from = "resource",
                  values_from = "utilisation",
                  names_glue = "utilisation_{resource}") |>
      ungroup()
  } else {#<<
    # If summarise = FALSE, just return util_df with no further processing#<<
    ungroup(util_df)#<<
  }#<<
}


#' Calculate the time-weighted mean queue length.
#'
#' @param arrivals Dataframe with times for each patient with each resource.
#'
#' @importFrom dplyr arrange group_by lead mutate summarise ungroup
#' @importFrom tidyr pivot_wider
#'
#' @return Tibble with column containing mean queue length.
#' @export

calc_mean_queue_length <- function(arrivals) {
  arrivals |>
    group_by(.data[["resource"]]) |>
    # Sort by arrival time
    arrange(.data[["start_time"]]) |>
    # Calculate time between this row and the next
    mutate(
      interval_duration = (lead(.data[["start_time"]]) - .data[["start_time"]])
    ) |>
    # Multiply each queue length by its own unique duration. The total of
    # those is then divided by the total duration of all intervals.
    # Hence, we are calculated a time-weighted average queue length.
    summarise(mean_queue_length = (
      sum(.data[["queue_on_arrival"]] *
            .data[["interval_duration"]], na.rm = TRUE) /
        sum(.data[["interval_duration"]], na.rm = TRUE)
    )
    ) |>
    # Reshape dataframe
    pivot_wider(names_from = "resource",
                values_from = "mean_queue_length",
                names_glue = "mean_queue_length_{resource}") |>
    ungroup()
}


#' Calculate the mean time in the system for finished patients.
#'
#' @param arrivals Dataframe with times for each patient with each resource.
#'
#' @importFrom dplyr summarise ungroup
#'
#' @return Tibble with column containing the mean time in the system.
#' @export

calc_mean_time_in_system <- function(arrivals) {
  arrivals |>
    summarise(
      mean_time_in_system = mean(.data[["time_in_system"]], na.rm = TRUE)
    ) |>
    ungroup()
}


#' Calculate the time-weighted mean number of patients in the system.
#'
#' @param patient_count Dataframe with patient counts over time.
#'
#' @importFrom dplyr arrange lead mutate summarise ungroup
#'
#' @return Tibble with column containing mean number of patients in the system.
#' @export

calc_mean_patients_in_system <- function(patient_count) {
  patient_count |>
    # Sort by time
    arrange(.data[["time"]]) |>
    # Calculate time between this row and the next
    mutate(interval_duration = (lead(.data[["time"]]) - .data[["time"]])) |>
    # Multiply each patient count by its own unique duration. The total of
    # those is then divided by the total duration of all intervals.
    # Hence, we are calculated a time-weighted average patient count.
    summarise(
      mean_patients_in_system = (
        sum(.data[["count"]] * .data[["interval_duration"]], na.rm = TRUE) /
          sum(.data[["interval_duration"]], na.rm = TRUE)
      )
    ) |>
    ungroup()
}
