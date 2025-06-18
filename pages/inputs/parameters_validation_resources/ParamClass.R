#' @title Returns transfer_prob for validation example.
#'
#' @field transfer_prob Numeric. Transfer probability (0-1).

ParamClass <- R6Class( # nolint: object_name_linter
  public = list(
    transfer_prob = NULL,

    #' @description
    #' Initialises the R6 object.

    initialize = function(transfer_prob = 0.3) {
      self$transfer_prob <- transfer_prob
    }
  )
)
