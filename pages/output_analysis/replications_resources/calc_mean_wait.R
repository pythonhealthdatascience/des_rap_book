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
