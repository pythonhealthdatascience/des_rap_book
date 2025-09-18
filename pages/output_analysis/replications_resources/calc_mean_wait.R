#' Calculate the mean wait time for each resource
#'
#' @param arrivals Dataframe with times for each patient with each resource.
#'
#' @importFrom tidyr drop_na
#' 
#' @return Tibble with columns containing result for each resource.
#' @export

calc_mean_wait <- function(arrivals) {

  # Create subset of data that removes patients who were still waiting
  complete_arrivals <- drop_na(arrivals, any_of("wait_time"))

  # Calculate mean wait time for each resource
  complete_arrivals |>
    group_by(resource) |>
    summarise(mean_wait_time = mean(wait_time)) |>
    pivot_wider(names_from = "resource",
                values_from = "mean_wait_time",
                names_glue = "mean_wait_time_{resource}") |>
    ungroup()
}
