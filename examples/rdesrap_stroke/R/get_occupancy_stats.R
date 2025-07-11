#' Calculate occupancy statistics
#'
#' For each resource in the data, this function computes how often each
#' occupancy level was observed. It then calculates:
#' \itemize{
#'   \item The frequency of each occupancy level
#'   \item The proportion (percentage) of time at each occupancy
#'   \item The cumulative proportion (cumulative percentage) up to each
#'   occupancy
#'   \item The probability of delay (probability that occupancy is at or above
#'   a given level)
#'   \item The "1 in every n" patients delayed (inverse of probability of delay)
#' }
#'
#'
#' @param occupancy DataFrame with three columns: \code{resource}, \code{time},
#' and \code{occupancy}.
#'
#' @importFrom rlang .data
#'
#' @return A list of data frames, one per resource, each containing occupancy
#' statistics.
#' @export

get_occupancy_stats <- function(occupancy) {

  results <- list()

  # Split by resource
  for (resource_name in unique(occupancy[["resource"]])) {
    occ <- filter(occupancy, .data[["resource"]] == resource_name)

    # Get frequency of each occupancy value
    freq_table <- table(occ[["occupancy"]])

    # Get the full range of occupancy values (fill in gaps)
    min_occ <- min(occ[["occupancy"]])
    max_occ <- max(occ[["occupancy"]])
    all_occupancy <- min_occ:max_occ

    # Create a complete frequency vector (fill missing with 0)
    complete_freq <- vapply(
      all_occupancy,
      function(x) {
        if (x %in% names(freq_table)) freq_table[as.character(x)] else 0L
      },
      FUN.VALUE = integer(1L)
    )

    # Build the summary dataframe
    occ_stats <- data.frame(
      beds = all_occupancy,
      freq = as.integer(complete_freq)
    )

    # Calculate proportion and cumulative proportion (percentage if *100)
    occ_stats[["pct"]] <- occ_stats[["freq"]] / sum(occ_stats[["freq"]])
    occ_stats[["c_pct"]] <- cumsum(occ_stats[["pct"]])

    # Calculate probability of delay using the Erlang loss formula
    occ_stats[["prob_delay"]] <- occ_stats[["pct"]] / occ_stats[["c_pct"]]

    # Calculate 1 in every n patients delayed
    occ_stats[["1_in_n_delay"]] <- round(1L / occ_stats[["prob_delay"]])

    results[[resource_name]] <- occ_stats
  }
  results
}
