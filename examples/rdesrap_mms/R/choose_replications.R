#' Computes running sample mean and variance using Welford's algorithm.
#'
#' @description
#' They are computed via updates to a stored value, rather than storing lots of
#' data and repeatedly taking the mean after new values have been added.
#'
#' Implements Welford's algorithm for updating mean and variance.
#' See Knuth. D `The Art of Computer Programming` Vol 2. 2nd ed. Page 216.
#'
#' This class is based on the Python class `OnlineStatistics` from Tom Monks
#' (2021) sim-tools: fundamental tools to support the simulation process in
#' python (https://github.com/TomMonks/sim-tools) (MIT Licence).
#'
#' @docType class
#' @importFrom R6 R6Class
#'
#' @return Object of `R6Class` with methods for running mean and variance
#' calculation.
#' @export

WelfordStats <- R6Class("WelfordStats", list( # nolint: object_name_linter

  #' @field n Number of observations.
  n = 0L,

  #' @field latest_data Latest data point.
  latest_data = NA,

  #' @field mean Running mean.
  mean = NA,

  #' @field sq Running sum of squares of differences.
  sq = NA,

  #' @field alpha Significance level for confidence interval calculations.
  #' For example, if alpha is 0.05, then the confidence level is 95\%.
  alpha = NA,

  #' @field observer Observer to notify on updates.
  observer = NULL,

  #' @description Initialise the WelfordStats object.
  #' @param data Initial data sample.
  #' @param alpha Significance level for confidence interval calculations.
  #' @param observer Observer to notify on updates.
  #' @return A new `WelfordStats` object.
  initialize = function(data = NULL, alpha = 0.05, observer = NULL) {
    # Set alpha and observer using the provided values/objects
    self$alpha <- alpha
    self$observer <- observer
    # If an initial data sample is supplied, then run update()
    if (!is.null(data)) {
      for (x in as.matrix(data)) {
        self$update(x)
      }
    }
  },

  #' @description Update running statistics with a new data point.
  #' @param x A new data point.
  update = function(x) {
    # Increment counter and save the latest data point
    self$n <- self$n + 1L
    self$latest_data <- x
    # Calculate the mean and sq
    if (self$n == 1L) {
      self$mean <- x
      self$sq <- 0L
    } else {
      updated_mean <- self$mean + ((x - self$mean) / self$n)
      self$sq <- self$sq + ((x - self$mean) * (x - updated_mean))
      self$mean <- updated_mean
    }
    # Update observer if present
    if (!is.null(self$observer)) {
      self$observer$update(self)
    }
  },

  #' @description Computes the variance of the data points.
  variance = function() {
    self$sq / (self$n - 1L)
  },

  #' @description Computes the standard deviation.
  std = function() {
    if (self$n < 3L) return(NA_real_)
    sqrt(self$variance())
  },

  #' @description Computes the standard error of the mean.
  std_error = function() {
    self$std() / sqrt(self$n)
  },

  #' @description Computes the half-width of the confidence interval.
  half_width = function() {
    if (self$n < 3L) return(NA_real_)
    dof <- self$n - 1L
    t_value <- qt(1L - (self$alpha / 2L), df = dof)
    t_value * self$std_error()
  },

  #' @description Computes the lower confidence interval bound.
  lci = function() {
    self$mean - self$half_width()
  },

  #' @description Computes the upper confidence interval bound.
  uci = function() {
    self$mean + self$half_width()
  },

  #' @description Computes the precision of the confidence interval expressed
  #' as the percentage deviation of the half width from the mean.
  deviation = function() {
    self$half_width() / self$mean
  }
))


#' Observes and records results from WelfordStats.
#'
#' @description
#' Updates each time new data is processed. Can generate a results dataframe.
#'
#' This class is based on the Python class `ReplicationTabulizer` from Tom
#' Monks (2021) sim-tools: fundamental tools to support the simulation process
#' in python (https://github.com/TomMonks/sim-tools) (MIT Licence).
#'
#' @docType class
#' @importFrom R6 R6Class
#'
#' @return Object of `R6Class` with methods for storing and tabulising results.
#' @export

ReplicationTabuliser <- R6Class("ReplicationTabuliser", list( # nolint: object_name_linter

  #' @field data_points List containing each data point.
  data_points = NULL,

  #' @field cumulative_mean List of the running mean.
  cumulative_mean = NULL,

  #' @field std List of the standard deviation.
  std = NULL,

  #' @field lci List of the lower confidence interval bound.
  lci = NULL,

  #' @field uci List of the upper confidence interval bound.
  uci = NULL,

  #' @field deviation List of the percentage deviation of the confidence
  #' interval half width from the mean.
  deviation = NULL,

  #' @description Add new results from WelfordStats to the appropriate lists.
  #' @param stats An instance of WelfordStats containing updated statistical
  #' measures like the mean, standard deviation and confidence intervals.
  update = function(stats) {
    self$data_points <- c(self$data_points, stats$latest_data)
    self$cumulative_mean <- c(self$cumulative_mean, stats$mean)
    self$std <- c(self$std, stats$std())
    self$lci <- c(self$lci, stats$lci())
    self$uci <- c(self$uci, stats$uci())
    self$deviation <- c(self$deviation, stats$deviation())
  },

  #' @description Creates a results table from the stored lists.
  #' @return Stored results compiled into a dataframe.
  summary_table = function() {
    data.frame(
      replications = seq_len(length(self$data_points)),
      data = self$data_points,
      cumulative_mean = self$cumulative_mean,
      stdev = self$std,
      lower_ci = self$lci,
      upper_ci = self$uci,
      deviation = self$deviation
    )
  }
))


#' Replication algorithm to automatically select number of replications.
#'
#' @description
#' Implements an adaptive replication algorithm for selecting the
#' appropriate number of simulation replications based on statistical
#' precision.
#'
#' Uses the "Replications Algorithm" from Hoad, Robinson, & Davies (2010).
#' Automated selection of the number of replications for a discrete-event
#' simulation. Journal of the Operational Research Society.
#' https://www.jstor.org/stable/40926090.
#'
#' Given a model's performance measure and a user-set confidence interval
#' half width prevision, automatically select the number of replications.
#' Combines the "confidence intervals" method with a sequential look-ahead
#' procedure to determine if a desired precision in the confidence interval
#' is maintained.
#'
#' This class is based on the Python class `ReplicationsAlgorithm` from Tom
#' Monks (2021) sim-tools: fundamental tools to support the simulation process
#' in python (https://github.com/TomMonks/sim-tools) (MIT Licence).
#'
#' @docType class
#' @importFrom R6 R6Class
#'
#' @return Object of `ReplicationsAlgorithm` with methods for determining the
#' appropriate number of replications to use.
#' @export

ReplicationsAlgorithm <- R6Class("ReplicationsAlgorithm", list( # nolint: object_name_linter

  #' @field param Model parameters (from parameters()).
  param = NA,

  #' @field metrics List of performance measure to track (should correspond to
  #' column names from the run results dataframe).
  metrics  = NA,

  #' @field desired_precision The target half width precision for the algorithm
  #' (i.e. percentage deviation of the confidence interval from the mean,
  #' expressed as a proportion, e.g. 0.1 = 10\%). Choice is fairly arbitrary.
  desired_precision = NA,

  #' @field initial_replications Number of initial replications to perform.
  initial_replications = NA,

  #' @field look_ahead Minimum additional replications to look ahead to assess
  #' stability of precision. When the number of replications is <= 100, the
  #' value of look_ahead is used. When they are > 100, then
  #' look_ahead / 100 * max(n, 100) is used.
  look_ahead = NA,

  #' @field replication_budget Maximum allowed replications. Use for larger
  #' models where replication runtime is a constraint.
  replication_budget = NA,

  #' @field reps Number of replications performed.
  reps = NA,

  #' @field nreps The minimum number of replicatons required to achieve
  #' desired precision for each metric.
  nreps = NA,

  #' @field summary_table Dataframe containing cumulative statistics for each
  #' replication for each metric
  summary_table = NA,

  #' @description Initialise the ReplicationsAlgorithm object.
  #' @param param Model parameters.
  #' @param metrics List of performance measure to track.
  #' @param desired_precision Target half width precision for the algorithm.
  #' @param initial_replications Number of initial replications to perform.
  #' @param look_ahead Minimum additional replications to look ahead.
  #' @param replication_budget Maximum allowed replications.
  #' @param verbose Boolean, whether to print messages about parameters.
  initialize = function(
    param,
    metrics = c("mean_waiting_time_nurse",
                "mean_serve_time_nurse",
                "utilisation_nurse"),
    desired_precision = 0.1,
    initial_replications = 3L,
    look_ahead = 5L,
    replication_budget = 1000L,
    verbose = TRUE
  ) {
    self$param <- param
    self$metrics <- metrics
    self$desired_precision <- desired_precision
    self$initial_replications <- initial_replications
    self$look_ahead <- look_ahead
    self$replication_budget <- replication_budget

    # Initially set reps to the number of initial replications
    self$reps <- initial_replications

    # Print the parameters
    if (isTRUE(verbose)) {
      print("Model parameters:")  # nolint: print_linter
      print(self$param)
    }

    # Check validity of provided parameters
    self$valid_inputs()
  },

  #' @description
  #' Checks validity of provided parameters.
  valid_inputs = function() {
    for (p in c("initial_replications", "look_ahead")) {
      if (self[[p]] %% 1L != 0L || self[[p]] < 0L) {
        stop(p, " must be a non-negative integer, but provided ", self[[p]],
             ".", call. = FALSE)
      }
    }
    if (self$desired_precision <= 0L) {
      stop("desired_precision must be greater than 0.", call. = FALSE)
    }
    if (self$replication_budget < self$initial_replications) {
      stop("replication_budget must be less than initial_replications.",
           call. = FALSE)
    }
  },

  #' @description
  #' Calculate the klimit. Determines the number of additional replications to
  #' check after precision is reached, scaling with total replications if they
  #' are greater than 100. Rounded down to nearest integer.
  #' @return Number of additional replications to verify stability (integer).
  klimit = function() {
    as.integer((self$look_ahead / 100L) * max(self$reps, 100L))
  },

  #' @description
  #' Find the first position where element is below deviation, and this is
  #' maintained through the lookahead period.
  #' This is used to correct the ReplicationsAlgorithm, which cannot return
  #' a solution below the initial_replications.
  #' @param lst List of numbers to compare against desired deviation.
  #' @return Integer, minimum replications required to meet and maintain
  #' precision.
  find_position = function(lst) {
    # Ensure that the input is a list
    if (!is.list(lst)) {
      stop("find_position requires a list but was supplied: ", typeof(lst),
           call. = FALSE)
    }

    # Check if list is empty or no values below threshold
    if (length(lst) == 0L || all(is.na(lst)) || !any(unlist(lst) < 0.5)) {
      return(NULL)
    }

    # Find the first non-null value in the list
    start_index <- which(!vapply(lst, is.na, logical(1L)))[1L]

    # Iterate through the list, stopping when at last point where we still
    # have enough elements to look ahead
    max_index <- length(lst) - self$look_ahead
    if (start_index > max_index) {
      return(NULL)
    }
    for (i in start_index:max_index) {
      # Trim to list with current value + lookahead
      # Check if all fall below the desired deviation
      segment <- lst[i:(i + self$look_ahead)]
      if (all(vapply(segment,
                     function(x) x < self$desired_precision, logical(1L)))) {
        return(i)
      }
    }
    return(NULL) # nolint: return_linter
  },

  #' @description
  #' Executes the replication algorithm, determining the necessary number
  #' of replications to achieve and maintain the desired precision.
  select = function() {

    # Create instances of observers for each metric
    observers <- setNames(
      lapply(self$metrics, function(x) ReplicationTabuliser$new()), self$metrics
    )

    # Create nested named list to store record for each metric of:
    # - nreps (the solution - replications required for precision)
    # - target_met (record of how many times in a row the target has been meet,
    # used to check if lookahead period has passed)
    # - solved (whether it has maintained precision for lookahead)
    solutions <- setNames(
      lapply(self$metrics, function(x) {
        list(nreps = NA, target_met = 0L, solved = FALSE)
      }), self$metrics
    )

    # If there are no initial replications, create empty instances of
    # WelfordStats for each metric...
    if (self$initial_replications == 0L) {
      stats <- setNames(
        lapply(
          self$metrics, function(x) WelfordStats$new(observer = observers[[x]])
        ), self$metrics
      )
    } else {
      # If there are, run the replications, then create instances of
      # WelfordStats pre-loaded with data from the initial replications... we
      # use runner so allows for parallel processing if desired...
      self$param[["number_of_runs"]] <- self$initial_replications
      result <- runner(self$param, use_future_seeding = FALSE)[["run_results"]]
      stats <- setNames(
        lapply(self$metrics, function(x) {
          WelfordStats$new(data = result[[x]], observer = observers[[x]])
        }), self$metrics
      )
      # After completing any replications, check if any have met precision, add
      # solution and update count
      for (metric in self$metrics) {
        if (isTRUE(stats[[metric]]$deviation() < self$desired_precision)) {
          solutions[[metric]]$nreps <- self$reps
          solutions[[metric]]$target_met <- 1L
          # If there is no lookahead, mark as solved
          if (self$klimit() == 0L) {
            solutions[[metric]]$solved <- TRUE
          }
        }
      }
    }

    # Whilst have not yet got all metrics marked as solved = TRUE, and still
    # under replication budget + lookahead...
    while (!all(unlist(lapply(solutions, function(x) x$solved))) &&
             self$reps < self$replication_budget + self$klimit()) {

      # Increment counter
      self$reps <- self$reps + 1L

      # Run another replication
      result <- model(run_number = self$reps,
                      param = self$param,
                      set_seed = TRUE)[["run_results"]]

      # Loop through the metrics...
      for (metric in self$metrics) {

        # If it is not yet solved...
        if (!solutions[[metric]]$solved) {

          # Update the running statistics for that metric
          stats[[metric]]$update(result[[metric]])

          # If precision has been achieved...
          if (isTRUE(stats[[metric]]$deviation() < self$desired_precision)) {

            # Check if target met the time prior - if not, record the solution
            if (solutions[[metric]]$target_met == 0L) {
              solutions[[metric]]$nreps <- self$reps
            }

            # Update how many times precision has been met in a row
            solutions[[metric]]$target_met <- (
              solutions[[metric]]$target_met + 1L
            )

            # Mark as solved if have finished lookahead period
            if (solutions[[metric]]$target_met > self$klimit()) {
              solutions[[metric]]$solved <- TRUE
            }

          } else {
            # If precision was not achieved, ensure nreps is None (e.g. in cases
            # where precision is lost after a success)
            solutions[[metric]]$nreps <- NA
          }

        }
      }
    }

    # Correction to result...
    for (metric in names(solutions)){
      # Use find_position() to check for solution in initial replications
      adj_nreps <- self$find_position(as.list(observers[[metric]]$deviation))
      # If there was a maintained solution, replace in solutions
      if (!is.null(adj_nreps) && !is.na(solutions[[metric]]$nreps)) {
        solutions[[metric]]$nreps <- adj_nreps
      }
    }

    # Extract minimum replications for each metric
    self$nreps <- lapply(solutions, function(x) x$nreps)

    # Extract any metrics that were not solved and return warning
    if (anyNA(self$nreps)) {
      unsolved <- names(self$nreps)[vapply(self$nreps, is.na, logical(1L))]
      warning(
        "The replications did not reach the desired precision ",
        "for the following metrics - ", toString(unsolved),
        call. = FALSE
      )
    }

    # Combine observer summary frames into a single table
    summary_tables <- lapply(names(observers), function(name) {
      tab <- observers[[name]]$summary_table()
      tab$metric <- name
      tab
    })
    self$summary_table <- do.call(rbind, summary_tables)
  }
))


#' Use the confidence interval method to select the number of replications.
#'
#' This could be altered to use WelfordStats and ReplicationTabuliser if
#' desired, but currently is independent.
#'
#' @param replications Number of times to run the model.
#' @param desired_precision Desired mean deviation from confidence interval.
#' @param metric Name of performance metric to assess.
#' @param verbose Boolean, whether to print messages about parameters.
#'
#' @importFrom utils tail
#'
#' @return Dataframe with results from each replication.
#' @export

confidence_interval_method <- function(replications, desired_precision,
                                       metric, verbose = TRUE) {
  # Run model for specified number of replications
  param <- parameters(number_of_runs = replications)
  if (isTRUE(verbose)) {
    print(param)
  }
  results <- runner(param, use_future_seeding = FALSE)[["run_results"]]

  # Initialise list to store the results
  cumulative_list <- list()

  # For each row in the dataframe, filter to rows up to the i-th replication
  # then perform calculations
  for (i in 1L:replications) {

    # Filter rows up to the i-th replication
    subset_data <- results[[metric]][1L:i]

    # Get latest data point
    last_data_point <- tail(subset_data, n = 1L)

    # Calculate mean
    mean_value <- mean(subset_data)

    # Some calculations require a few observations else will error...
    if (i < 3L) {
      # When only one observation, set to NA
      stdev <- NA
      lower_ci <- NA
      upper_ci <- NA
      deviation <- NA
    } else {
      # Else, calculate standard deviation, 95% confidence interval, and
      # percentage deviation
      stdev <- stats::sd(subset_data)
      ci <- stats::t.test(subset_data)[["conf.int"]]
      lower_ci <- ci[[1L]]
      upper_ci <- ci[[2L]]
      deviation <- ((upper_ci - mean_value) / mean_value)
    }

    # Append to the cumulative list
    cumulative_list[[i]] <- data.frame(
      replications = i,
      data = last_data_point,
      cumulative_mean = mean_value,
      stdev = stdev,
      lower_ci = lower_ci,
      upper_ci = upper_ci,
      deviation = deviation
    )
  }

  # Combine the list into a single data frame
  cumulative <- do.call(rbind, cumulative_list)
  cumulative[["metric"]] <- metric

  # Get the minimum number of replications where deviation is less than target
  compare <- dplyr::filter(
    cumulative, .data[["deviation"]] <= desired_precision
  )
  if (nrow(compare) > 0L) {
    # Get minimum number
    n_reps <- compare %>%
      dplyr::slice_head() %>%
      dplyr::select(replications) %>%
      dplyr::pull()
    message("Reached desired precision (", desired_precision, ") in ",
            n_reps, " replications.")
  } else {
    warning("Running ", replications, " replications did not reach ",
            "desired precision (", desired_precision, ").", call. = FALSE)
  }
  cumulative
}


#' Generate a plot of metric and confidence intervals with increasing
#' simulation replications
#'
#' @param conf_ints A dataframe containing confidence interval statistics,
#' including cumulative mean, upper/lower bounds, and deviations. As returned
#' by ReplicationTabuliser summary_table() method.
#' @param yaxis_title Label for y axis.
#' @param file_path Path and filename to save the plot to.
#' @param min_rep The number of replications required to meet the desired
#' precision.

plot_replication_ci <- function(
  conf_ints, yaxis_title, file_path = NULL, min_rep = NULL
) {
  # Plot the cumulative mean and confidence interval
  p <- ggplot2::ggplot(conf_ints,
                       ggplot2::aes(x = .data[["replications"]],
                                    y = .data[["cumulative_mean"]])) +
    ggplot2::geom_line() +
    ggplot2::geom_ribbon(
      ggplot2::aes(ymin = .data[["lower_ci"]], ymax = .data[["upper_ci"]]),
      alpha = 0.2
    )

  # If specified, plot the minimum suggested number of replications
  if (!is.null(min_rep)) {
    p <- p +
      ggplot2::geom_vline(
        xintercept = min_rep, linetype = "dashed", color = "red"
      )
  }

  # Modify labels and style
  p <- p +
    ggplot2::labs(x = "Replications", y = yaxis_title) +
    ggplot2::theme_minimal()

  # Save the plot
  if (!is.null(file_path)) {
    ggplot2::ggsave(filename = file_path,
                    width = 6.5, height = 4L, bg = "white")
  } else {
    p
  }
}
