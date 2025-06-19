Choosing cores
================
Amy Heather
2025-06-04

- [Set up](#set-up)
- [Run time with varying number of CPU
  cores](#run-time-with-varying-number-of-cpu-cores)
- [Run time](#run-time)

This notebook documents the choice of the number of CPU cores.

The generated images are saved and then loaded, so that we view the
image as saved (i.e. with the dimensions set in `ggsave()`). This also
avoids the creation of a `_files/` directory when knitting the document
(which would save all previewed images into that folder also, so they
can be rendered and displayed within the output `.md` file, even if we
had not specifically saved them). These are viewed using
`include_graphics()`, which must be the last command in the cell (or
last in the plotting function).

The run time is provided at the end of the notebook.

## Set up

Install the latest version of the local simulation package. If running
sequentially, `devtools::load_all()` is sufficient. If running in
parallel, you must use `devtools::install()`.

``` r
devtools::install(upgrade = "never")
```

    ## ── R CMD build ──────────────────────────────────────────────────────────
    ##      checking for file ‘/home/amy/Documents/stars/rdesrap_mms/DESCRIPTION’ ...  ✔  checking for file ‘/home/amy/Documents/stars/rdesrap_mms/DESCRIPTION’
    ##   ─  preparing ‘simulation’:
    ##    checking DESCRIPTION meta-information ...  ✔  checking DESCRIPTION meta-information
    ##   ─  checking for LF line-endings in source and make files and shell scripts
    ##   ─  checking for empty or unneeded directories
    ##    Omitted ‘LazyData’ from DESCRIPTION
    ##   ─  building ‘simulation_0.1.0.tar.gz’
    ##      
    ## Running /opt/R/4.4.1/lib/R/bin/R CMD INSTALL \
    ##   /tmp/RtmphBXRjL/simulation_0.1.0.tar.gz --install-tests 
    ## * installing to library ‘/home/amy/.cache/R/renv/library/rdesrap_mms-cd7d6844/linux-ubuntu-noble/R-4.4/x86_64-pc-linux-gnu’
    ## * installing *source* package ‘simulation’ ...
    ## ** using staged installation
    ## ** R
    ## ** inst
    ## ** tests
    ## ** byte-compile and prepare package for lazy loading
    ## ** help
    ## *** installing help indices
    ## ** building package indices
    ## ** testing if installed package can be loaded from temporary location
    ## ** testing if installed package can be loaded from final location
    ## ** testing if installed package keeps a record of temporary installation path
    ## * DONE (simulation)

Load required packages.

``` r
# nolint start: undesirable_function_linter.
library(data.table)
library(dplyr)
```

    ## 
    ## Attaching package: 'dplyr'

    ## The following objects are masked from 'package:data.table':
    ## 
    ##     between, first, last

    ## The following objects are masked from 'package:stats':
    ## 
    ##     filter, lag

    ## The following objects are masked from 'package:base':
    ## 
    ##     intersect, setdiff, setequal, union

``` r
library(ggplot2)
library(knitr)
library(simulation)

options(data.table.summarise.inform = FALSE)
options(dplyr.summarise.inform = FALSE)
# nolint end
```

Start timer.

``` r
start_time <- Sys.time()
```

Define path to outputs folder.

``` r
output_dir <- file.path("..", "outputs")
```

## Run time with varying number of CPU cores

``` r
#' Run model with varying number of CPU cores and examine run times
#'
#' @param n_cores Number of cores to test up to
#' @param file Filename to save figure to.
#' @param model_param List of parameters for the model.

run_cores <- function(n_cores, file, model_param = NULL) {
  # Run model with 1 to 8 cores
  speed <- list()
  for (i in 1L:n_cores){
    message("Running with cores:", i)
    cores_start <- Sys.time()

    # Run model with specified number of cores
    # If specified, also set to provided model parameters
    if (!is.null(model_param)) {
      param <- do.call(parameters, model_param)
    } else {
      param <- parameters()
    }

    # Set number of cores
    param[["cores"]] <- i

    # Print model parameter on first run through (1 core)
    if (i == 1L) {
      print("Parameters from run with 1 core:")  # nolint: print_linter
      print("(will be same for others, just more cores)")  # nolint: print_linter
      print(param)
    }

    # Run model
    invisible(runner(param))

    # Record time taken, rounded to nearest .5 dp by running round(x*2)/2
    cores_time <- round(
      as.numeric(Sys.time() - cores_start, units = "secs") * 2L
    ) / 2L
    speed[[i]] <- list(cores = i, run_time = round(cores_time, 3L))
  }

  # Convert to dataframe
  speed_df <- rbindlist(speed)

  # Generate plot
  p <- ggplot(speed_df, aes(x = .data[["cores"]], y = .data[["run_time"]])) +
    geom_line() +
    labs(x = "Cores", y = "Run time (rounded to nearest .5 seconds)") +
    theme_minimal()

  # Save plot
  full_path <- file.path(output_dir, file)
  ggsave(filename = full_path, plot = p,
         width = 6.5, height = 4L, bg = "white")

  # View the plot
  include_graphics(full_path)
}
```

Setting up and managing a parallel cluster takes extra time. For small
tasks or few iterations, this extra time can be more than the time saved
by running in parallel.

``` r
run_cores(5L, "cores1.png")
```

    ## Running with cores:1

    ## [1] "Parameters from run with 1 core:"
    ## [1] "(will be same for others, just more cores)"
    ## $patient_inter
    ## [1] 4
    ## 
    ## $mean_n_consult_time
    ## [1] 10
    ## 
    ## $number_of_nurses
    ## [1] 5
    ## 
    ## $warm_up_period
    ## [1] 0
    ## 
    ## $data_collection_period
    ## [1] 80
    ## 
    ## $number_of_runs
    ## [1] 100
    ## 
    ## $scenario_name
    ## NULL
    ## 
    ## $cores
    ## [1] 1
    ## 
    ## $log_to_console
    ## [1] FALSE
    ## 
    ## $log_to_file
    ## [1] FALSE
    ## 
    ## $file_path
    ## NULL

    ## Running with cores:2

    ## Running with cores:3

    ## Running with cores:4

    ## Running with cores:5

![](../outputs/cores1.png)<!-- -->

Having increased the simulation length, we now see that parallelisation
is decreasing the model run time.

However, when you use more cores, the data needs to be divided and sent
to more workers. For small tasks, this extra work is small, but as the
number of workers increases, the time spent managing and communicating
with them can grow too much. At some point, this overhead becomes larger
than the time saved by using more cores.

The optimal number of cores will vary depending on your model parameters
and machine.

``` r
run_cores(5L, "cores2.png", list(data_collection_period = 10000L))
```

    ## Running with cores:1

    ## [1] "Parameters from run with 1 core:"
    ## [1] "(will be same for others, just more cores)"
    ## $patient_inter
    ## [1] 4
    ## 
    ## $mean_n_consult_time
    ## [1] 10
    ## 
    ## $number_of_nurses
    ## [1] 5
    ## 
    ## $warm_up_period
    ## [1] 0
    ## 
    ## $data_collection_period
    ## [1] 10000
    ## 
    ## $number_of_runs
    ## [1] 100
    ## 
    ## $scenario_name
    ## NULL
    ## 
    ## $cores
    ## [1] 1
    ## 
    ## $log_to_console
    ## [1] FALSE
    ## 
    ## $log_to_file
    ## [1] FALSE
    ## 
    ## $file_path
    ## NULL

    ## Running with cores:2

    ## Running with cores:3

    ## Running with cores:4

    ## Running with cores:5

![](../outputs/cores2.png)<!-- -->

## Run time

``` r
# Get run time in seconds
end_time <- Sys.time()
runtime <- as.numeric(end_time - start_time, units = "secs")

# Display converted to minutes and seconds
minutes <- as.integer(runtime / 60L)
seconds <- as.integer(runtime %% 60L)
cat(sprintf("Notebook run time: %dm %ds", minutes, seconds))
```

    ## Notebook run time: 1m 2s
