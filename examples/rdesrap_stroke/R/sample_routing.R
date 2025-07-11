#' Sample a destination based on probabilities.
#'
#' Randomly selects a destination from a list, where each destination has an
#' associated probability. The destination is returned as a numeric index, as
#' \code{simmer::set_attribute()} requires a numeric or function.
#'
#' @param prob_list Named list. The names are destination labels (character),
#' and the values are their corresponding probabilities (numeric, non-negative,
#' sum to 1).
#'
#' @return An integer. The index of the selected destination within
#' \code{prob_list}.
#' @export

sample_routing <- function(prob_list) {
  sample(seq_along(prob_list), size = 1L, prob = unlist(prob_list))
}
