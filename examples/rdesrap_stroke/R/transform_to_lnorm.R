#' Convert LOS mean/sd to lognormal parameters for all patient types.
#'
#' Given a named list of length of stay (LOS) distributions (each with
#' \code{mean} and \code{sd} on the original scale), this function returns a
#' new named list where each entry contains the corresponding \code{meanlog}
#' and \code{sdlog} parameters required by R's \code{rlnorm()} and related
#' functions.
#'
#' @param los_list Named list. Each element should itself be a list with
#' elements \code{mean} and \code{sd} (e.g., as produced by
#' \code{create_asu_los()} or \code{create_rehab_los()}).
#'
#' @return A named list of the same structure, but with elements \code{meanlog}
#' and \code{sdlog} for each patient type.
#' @export

transform_to_lnorm <- function(los_list) {
  lapply(los_list, function(x) {
    variance <- x$sd^2L
    sigma_sq <- log(variance / (x$mean^2L) + 1L)
    sdlog <- sqrt(sigma_sq)
    meanlog <- log(x$mean) - sigma_sq / 2L
    list(meanlog = meanlog, sdlog = sdlog)
  })
}
