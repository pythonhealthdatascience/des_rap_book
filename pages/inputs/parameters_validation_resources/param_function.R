#' Returns transfer_prob for validation example.
#'
#' @param transfer_prob Numeric. Transfer probability (0-1).
#'
#' @return A named list containing the transfer_prob parameter.

param_function <- function(transfer_prob = 0.3) {
  list(transfer_prob = transfer_prob)
}
