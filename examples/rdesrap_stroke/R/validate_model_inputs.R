#' Validate input parameters for the simulation.
#'
#' @param run_number Integer representing index of current simulation run.
#' @param param List containing parameters for the simulation.
#'
#' @return Throws an error if any parameter is invalid.
#' @export

valid_inputs <- function(run_number, param) {
  check_run_number(run_number)
  check_all_param_names(param)
  check_param_values(param)
}


#' Checks if the run number is a non-negative integer.
#'
#' @param run_number Integer representing index of current simulation run.
#'
#' @return Throws an error if the run number is invalid.
#' @export

check_run_number <- function(run_number) {
  if (run_number < 0L || run_number %% 1L != 0L) {
    stop("The run number must be a non-negative integer. Provided: ",
         run_number, call. = FALSE)
  }
}


#' Validate parameter names.
#'
#' Ensure that all required parameters are present, and no extra parameters are
#' provided.
#'
#' @param valid_names Character vector of valid argument names.
#' @param input_names Character vector of input parameter names.
#'
#' @return Throws an error if there are missing or extra parameters.
#' @export

check_param_names <- function(valid_names, input_names) {

  # Find missing keys (i.e. are there things in valid_names not in input)
  # and extra keys (i.e. are there things in input not in valid_names)
  missing_keys <- setdiff(valid_names, input_names)
  extra_keys <- setdiff(input_names, valid_names)

  # If there are any missing or extra keys, throw an error
  if (length(missing_keys) > 0L || length(extra_keys) > 0L) {
    error_message <- ""
    if (length(missing_keys) > 0L) {
      error_message <- paste0(
        error_message, "Missing keys: ", toString(missing_keys), ". "
      )
    }
    if (length(extra_keys) > 0L) {
      error_message <- paste0(
        error_message, "Extra keys: ", toString(extra_keys), ". "
      )
    }
    stop(error_message, call. = FALSE)
  }
}


#' Validate all parameter groups in a parameter list.
#'
#' This function checks that the top-level and all nested parameter lists have
#' the correct names.
#'
#' @param param List of parameter groups.
#'
#' @return Throws an error if any group has missing or extra parameters.
#' @export

check_all_param_names <- function(param) {

  # Validate top-level parameter names
  valid_top_names <- names(formals(create_parameters))
  input_top_names <- names(param)
  check_param_names(valid_names = valid_top_names,
                    input_names = input_top_names)

  # List of sub-parameter validation functions and their expected names
  param_validators <- list(
    asu_arrivals = create_asu_arrivals,
    rehab_arrivals = create_rehab_arrivals,
    asu_los = create_asu_los,
    rehab_los = create_rehab_los,
    asu_routing = create_asu_routing,
    rehab_routing = create_rehab_routing
  )

  # Validate each sub-parameter group, if present
  for (param_name in names(param_validators)) {
    valid_names <- names(param_validators[[param_name]]())
    input_names <- names(param[[param_name]])
    check_param_names(valid_names, input_names)
  }
}


#' Validate probability vector
#'
#' Checks that values are between 0 and 1 (inclusive), that they sum to 1
#' (with tolerance of +-0.01).
#'
#' @param vec Numeric vector. The probability vector to be checked.
#' @param name Character string. The name or label for the vector, used in
#' error messages.
#'
#' @return Throws an error if the vector is invalid; otherwise, returns nothing.
#' @export

check_prob_vector <- function(vec, name) {
  if (!is.numeric(vec)) {
    stop('Routing vector "', name, '" must be numeric.', call. = FALSE)
  }
  if (any(vec < 0L | vec > 1L)) {
    stop('All values in routing vector "', name, '" must be between 0 and 1.',
         call. = FALSE)
  }
  if (sum(vec) < 0.99 || sum(vec) > 1.01) {
    stop('Values in routing vector "', name, '" must sum to 1 (+-0.01).',
         call. = FALSE)
  }
}


#' Check if a value is a positive integer
#'
#' Throws an error if the value is not a positive integer (> 0).
#'
#' @param x The value to check.
#' @param name The name of the parameter (for error messages).
#'
#' @return None. Throws an error if the check fails.
#' @export

check_positive_integer <- function(x, name) {
  if (is.null(x) || x <= 0L || x %% 1L != 0L) {
    stop(
      sprintf('The parameter "%s" must be an integer greater than 0.', name),
      call. = FALSE
    )
  }
}

#' Check if all values are positive
#'
#' Throws an error if any value in the input is not positive (> 0).
#'
#' @param x The vector or list of values to check.
#' @param name The name of the parameter (for error messages).
#'
#' @return None. Throws an error if the check fails.
#' @export

check_all_positive <- function(x, name) {
  if (!is.null(x) && any(unlist(x) <= 0L)) {
    stop(
      sprintf('All values in "%s" must be greater than 0.', name),
      call. = FALSE
    )
  }
}

#' Check if a value is a non-negative integer
#'
#' Throws an error if the value is not a non-negative integer (>= 0).
#'
#' @param x The value to check.
#' @param name The name of the parameter (for error messages).
#'
#' @return None. Throws an error if the check fails.
#' @export

check_nonneg_integer <- function(x, name) {
  if (is.null(x) || x < 0L || x %% 1L != 0L) {
    stop(
      sprintf('The parameter "%s" must be an integer >= 0.', name),
      call. = FALSE
    )
  }
}

#' Validate parameter values
#'
#' Ensures that specific parameters are positive numbers, non-negative integers,
#' and that probability vectors are in [0, 1] and sum to 1 (within tolerance).
#'
#' @param param List containing parameters for the simulation.
#'
#' @return None. Throws an error if any specified parameter value is invalid.
#' @export

check_param_values <- function(param) {
  check_positive_integer(param[["number_of_runs"]], "number_of_runs")

  lapply(c("asu_arrivals", "rehab_arrivals", "asu_los", "rehab_los"),
         function(nm) check_all_positive(param[[nm]], nm))

  lapply(c("warm_up_period", "data_collection_period"),
         function(nm) check_nonneg_integer(param[[nm]], nm))

  for (routing in c("asu_routing", "rehab_routing")) {
    if (!is.null(param[[routing]])) {
      lapply(names(param[[routing]]), function(name) {
        vec <- unlist(param[[routing]][[name]], use.names = FALSE)
        check_prob_vector(vec, paste0(routing, "$", name))
      })
    }
  }
}
