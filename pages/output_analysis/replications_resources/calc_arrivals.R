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
