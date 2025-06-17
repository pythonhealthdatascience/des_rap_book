#' Get average results for the provided single run.
#'
#' @param results Named list with `arrivals` containing output from
#' `get_mon_arrivals()` and `resources` containing output from
#' `get_mon_resources()` (`per_resource = TRUE` and `ongoing = TRUE`).
#' @param run_number Integer representing index of current simulation run.
#'
#' @importFrom dplyr group_by summarise n_distinct mutate lead full_join
#' @importFrom dplyr bind_cols across
#' @importFrom purrr reduce
#' @importFrom simmer get_mon_resources get_mon_arrivals now
#' @importFrom tidyr pivot_wider drop_na
#' @importFrom tibble tibble
#' @importFrom rlang .data
#' @importFrom tidyselect all_of any_of
#' @importFrom stats setNames
#'
#' @return Tibble with processed results from replication.
#' @export

get_run_results <- function(results, run_number) {

  # If there were no arrivals, return dataframe row with just the replication
  # number and arrivals column set to 0
  if (nrow(results[["arrivals"]]) == 0L) {
    tibble(replication = run_number, arrivals = 0L)

  } else {

    # Otherwise, if there are some arrivals...
    # Calculate metrics of interest
    metrics <- list(
      calc_arrivals(results[["arrivals"]]),
      calc_mean_patients_in_service(results[["patients_in_service"]]),
      calc_mean_queue(results[["arrivals"]]),
      calc_mean_wait(results[["arrivals"]], results[["resources"]]),
      calc_mean_serve_length(results[["arrivals"]], results[["resources"]]),
      calc_utilisation(results[["resources"]]),
      calc_unseen_n(results[["arrivals"]]),
      calc_unseen_mean(results[["arrivals"]])
    )
    # Combine metrics + replication number in a single dataframe
    dplyr::bind_cols(tibble(replication = run_number), metrics)
  }
}


#' Calculate the number of arrivals
#'
#' @param arrivals Dataframe with times for each patient with each resource.
#' @param groups Optional list of columns to group by for the calculation.
#'
#' @return Tibble with column containing total number of arrivals.
#' @export

calc_arrivals <- function(arrivals, groups = NULL) {
  # If provided, group the dataset
  if (!is.null(groups)) {
    arrivals <- group_by(arrivals, across(all_of(groups)))
  }
  # Calculate number of arrivals
  arrivals %>%
    summarise(arrivals = n_distinct(.data[["name"]])) %>%
    ungroup()
}


#' Calculate the time-weighted mean number of patients in the service.
#'
#' @param patient_count Dataframe with patient counts over time.
#' @param groups Optional list of columns to group by for the calculation.
#'
#' @return Tibble with column containing mean number of patients in the service.
#' @export

calc_mean_patients_in_service <- function(patient_count, groups = NULL) {
  # If provided, group the dataset
  if (!is.null(groups)) {
    patient_count <- group_by(patient_count, across(all_of(groups)))
  }
  # Calculate the time-weighted number of patients in the service
  patient_count %>%
    # Sort by time
    arrange(.data[["time"]]) %>%
    # Calculate time between this row and the next
    mutate(interval_duration = (lead(.data[["time"]]) - .data[["time"]])) %>%
    # Multiply each patient count by its own unique duration. The total of
    # those is then divided by the total duration of all intervals.
    # Hence, we are calculated a time-weighted average patient count.
    summarise(
      mean_patients_in_service = (
        sum(.data[["count"]] * .data[["interval_duration"]], na.rm = TRUE) /
          sum(.data[["interval_duration"]], na.rm = TRUE)
      )
    ) %>%
    ungroup()
}


#' Calculate the time-weighted mean queue length.
#'
#' @param arrivals Dataframe with times for each patient with each resource.
#' @param groups Optional list of columns to group by for the calculation.
#'
#' @return Tibble with column containing mean queue length.
#' @export

calc_mean_queue <- function(arrivals, groups = NULL) {
  # Create list of grouping variables (always "resource", but can add others)
  group_vars <- c("resource", groups)

  # Calculate mean queue length for each resource
  arrivals %>%
    group_by(across(all_of(group_vars))) %>%
    # Sort by arrival time
    arrange(.data[["start_time"]]) %>%
    # Calculate time between this row and the next
    mutate(
      interval_duration = (lead(.data[["start_time"]]) - .data[["start_time"]])
    ) %>%
    # Multiply each queue length by its own unique duration. The total of
    # those is then divided by the total duration of all intervals.
    # Hence, we are calculated a time-weighted average queue length.
    summarise(mean_queue_length = (
      sum(.data[["queue_on_arrival"]] *
            .data[["interval_duration"]], na.rm = TRUE) /
        sum(.data[["interval_duration"]], na.rm = TRUE)
    )
    ) %>%
    # Reshape dataframe
    pivot_wider(names_from = "resource",
                values_from = "mean_queue_length",
                names_glue = "mean_queue_length_{resource}") %>%
    ungroup()
}


#' Calculate the mean wait time for each resource
#'
#' @param arrivals Dataframe with times for each patient with each resource.
#' @param resources Dataframe with times patients use or queue for resources.
#' @param groups Optional list of columns to group by for the calculation.
#'
#' @return Tibble with columns containing result for each resource.
#' @export

calc_mean_wait <- function(arrivals, resources, groups = NULL) {

  # Create subset of data that removes patients who were still waiting
  complete_arrivals <- drop_na(arrivals, any_of("wait_time"))

  # If there are any patients who were seen, calculate mean wait times...
  if (nrow(complete_arrivals) > 0L) {

    # Create list of grouping variables (always "resource", but can add others)
    group_vars <- c("resource", groups)

    # Calculate mean wait time for each resource
    complete_arrivals %>%
      group_by(across(all_of(group_vars))) %>%
      summarise(mean_waiting_time = mean(.data[["wait_time"]])) %>%
      pivot_wider(names_from = "resource",
                  values_from = "mean_waiting_time",
                  names_glue = "mean_waiting_time_{resource}") %>%
      ungroup()
  } else {
    # But if no patients are seen, create same tibble with values set to NA
    unique_resources <- unique(resources["resource"])
    tibble::tibble(
      !!!setNames(rep(list(NA_real_), length(unique_resources)),
                  paste0("mean_waiting_time_", unique_resources))
    )
  }
}


#' Calculate the mean length of time patients spent with each resource
#'
#' @param arrivals Dataframe with times for each patient with each resource.
#' @param resources Dataframe with times patients use or queue for resources.
#' @param groups Optional list of columns to group by for the calculation.
#'
#' @return Tibble with columns containing result for each resource.
#' @export

calc_mean_serve_length <- function(arrivals, resources, groups = NULL) {

  # Create subset of data that removes patients who were still waiting
  complete_arrivals <- drop_na(arrivals, any_of("wait_time"))

  # If there are any patients who were seen, calculate mean service length...
  if (nrow(complete_arrivals) > 0L) {

    # Create list of grouping variables (always "resource", but can add others)
    group_vars <- c("resource", groups)

    # Calculate mean serve time for each resource
    complete_arrivals %>%
      group_by(across(all_of(group_vars))) %>%
      summarise(mean_serve_time = mean(.data[["serve_length"]])) %>%
      pivot_wider(names_from = "resource",
                  values_from = "mean_serve_time",
                  names_glue = "mean_serve_time_{resource}") %>%
      ungroup()
  } else {
    # But if no patients are seen, create same tibble with values set to NA
    unique_resources <- unique(resources["resource"])
    tibble::tibble(
      !!!setNames(rep(list(NA_real_), length(unique_resources)),
                  paste0("mean_serve_time_", unique_resources))
    )
  }
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
#' @param groups Optional list of columns to group by for the calculation.
#' @param summarise If TRUE, return overall utilisation. If FALSE, just return
#' the resource dataframe with the additional columns interval_duration,
#' effective_capacity and utilisation.
#'
#' @return Tibble with columns containing result for each resource.
#' @export

calc_utilisation <- function(resources, groups = NULL, summarise = TRUE) {

  # Create list of grouping variables (always "resource", but can add others)
  group_vars <- c("resource", groups)

  # Calculate utilisation
  util_df <- resources %>%
    group_by(across(all_of(group_vars))) %>%
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

  # If summarise = TRUE, find total utilisation
  if (summarise) {
    util_df %>%
      summarise(
        # Multiply each utilisation by its own unique duration. The total of
        # those is then divided by the total duration of all intervals.
        # Hence, we are calculated a time-weighted average utilisation.
        utilisation = (sum(.data[["utilisation"]] *
                             .data[["interval_duration"]], na.rm = TRUE) /
                         sum(.data[["interval_duration"]], na.rm = TRUE))
      ) %>%
      pivot_wider(names_from = "resource",
                  values_from = "utilisation",
                  names_glue = "utilisation_{resource}") %>%
      ungroup()
  } else {
    # If summarise = FALSE, just return the util_df with no further processing
    ungroup(util_df)
  }
}


#' Calculate the number of patients still waiting for resource at end
#'
#' @param arrivals Dataframe with times for each patient with each resource.
#' @param groups Optional list of columns to group by for the calculation.
#'
#' @return Tibble with columns containing result for each resource.
#' @export

calc_unseen_n <- function(arrivals, groups = NULL) {
  # Create list of grouping variables (always "resource", but can add others)
  group_vars <- c("resource", groups)
  # Calculate number of patients waiting
  arrivals %>%
    group_by(across(all_of(group_vars))) %>%
    summarise(value = sum(!is.na(.data[["wait_time_unseen"]]))) %>%
    pivot_wider(names_from = "resource",
                values_from = "value",
                names_glue = "count_unseen_{resource}") %>%
    ungroup()
}


#' Calculate the mean wait time of patients who are still waiting for a
#' resource at the end of the simulation
#'
#' @param arrivals Dataframe with times for each patient with each resource.
#' @param groups Optional list of columns to group by for the calculation.
#'
#' @return Tibble with columns containing result for each resource.
#' @export

calc_unseen_mean <- function(arrivals, groups = NULL) {
  # Create list of grouping variables (always "resource", but can add others)
  group_vars <- c("resource", groups)
  # Calculate wait time of unseen patients
  arrivals %>%
    group_by(across(all_of(group_vars))) %>%
    summarise(value = mean(.data[["wait_time_unseen"]], na.rm = TRUE)) %>%
    pivot_wider(names_from = "resource",
                values_from = "value",
                names_glue = "mean_waiting_time_unseen_{resource}") %>%
    ungroup()
}
