Generate expected results
================
Amy Heather
2025-06-04

- [Set-up](#set-up)
- [Base case](#base-case)
- [Model with a warm-up period](#model-with-a-warm-up-period)
- [Scenario analysis](#scenario-analysis)
- [Running the simulation when attempting to determine an appropriate
  number of
  parameters](#running-the-simulation-when-attempting-to-determine-an-appropriate-number-of-parameters)
- [Calculate run time](#calculate-run-time)

This notebook is used to run a specific version of the model and save
each results dataframe as a csv. These are used in `test-backtest.R` to
verify that the model produces consistent results.

The `.Rmd` file is provided as it is possible that results may change
due to alterations to the model structure and operations. Once it has
been confirmed that changes are intentional and not any introduced
errors, this script can be run to regenerate the `.csv` files used in
the test.

The run time is provided at the end of this notebook.

## Set-up

Install the latest version of the local simulation package. If running
sequentially, `devtools::load_all()` is sufficient. If running in
parallel, you must use `devtools::install()`.

``` r
devtools::load_all()
```

    ## ℹ Loading simulation

Load required packages.

``` r
# nolint start: undesirable_function_linter.
library(simulation)
# nolint end
```

Start timer.

``` r
start_time <- Sys.time()
```

Define path to expected results.

``` r
testdata_dir <- file.path("..", "tests", "testthat", "testdata")
```

## Base case

``` r
# Define model parameters
param <- parameters(
  patient_inter = 4L,
  mean_n_consult_time = 10L,
  number_of_nurses = 5L,
  warm_up_period = 0L,
  data_collection_period = 80L,
  number_of_runs = 10L,
  cores = 1L
)
print(param)
```

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
    ## [1] 10
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

``` r
# Run the replications
results <- runner(param)

# Arrivals
head(results[["arrivals"]])
```

    ##       name start_time  end_time activity_time resource replication
    ## 1 patient0   7.958939  9.339626      1.380687    nurse           1
    ## 2 patient1  14.376952 17.082901      2.705948    nurse           1
    ## 3 patient3  22.423647 24.279227      1.855580    nurse           1
    ## 4 patient2  19.966026 32.789001     12.822975    nurse           1
    ## 5 patient5  28.808098 32.923921      4.115823    nurse           1
    ## 6 patient6  30.048144 37.857589      7.809445    nurse           1
    ##   queue_on_arrival serve_start serve_length wait_time wait_time_unseen
    ## 1                0    7.958939     1.380687         0               NA
    ## 2                0   14.376952     2.705948         0               NA
    ## 3                0   22.423647     1.855580         0               NA
    ## 4                0   19.966026    12.822975         0               NA
    ## 5                0   28.808098     4.115823         0               NA
    ## 6                0   30.048144     7.809445         0               NA

``` r
write.csv(arrange(results[["arrivals"]], replication, start_time),
          file.path(testdata_dir, "base_arrivals.csv"),
          row.names = FALSE)

# Resources
head(results[["resources"]])
```

    ##   resource      time server queue capacity queue_size system limit replication
    ## 1    nurse  7.958939      1     0        5        Inf      1   Inf           1
    ## 2    nurse  9.339626      0     0        5        Inf      0   Inf           1
    ## 3    nurse 14.376952      1     0        5        Inf      1   Inf           1
    ## 4    nurse 17.082901      0     0        5        Inf      0   Inf           1
    ## 5    nurse 19.966026      1     0        5        Inf      1   Inf           1
    ## 6    nurse 22.423647      2     0        5        Inf      2   Inf           1

``` r
write.csv(results[["resources"]],
          file.path(testdata_dir, "base_resources.csv"),
          row.names = FALSE)

# Run results
head(results[["run_results"]])
```

    ## # A tibble: 6 × 9
    ##   replication arrivals mean_patients_in_service mean_queue_length_nurse
    ##         <int>    <int>                    <dbl>                   <dbl>
    ## 1           1       17                     1.62                   0    
    ## 2           2       19                     2.29                   0    
    ## 3           3       28                     3.26                   0    
    ## 4           4       15                     1.76                   0    
    ## 5           5       25                     3.09                   0.349
    ## 6           6       17                     1.81                   0    
    ## # ℹ 5 more variables: mean_waiting_time_nurse <dbl>,
    ## #   mean_serve_time_nurse <dbl>, utilisation_nurse <dbl>,
    ## #   count_unseen_nurse <int>, mean_waiting_time_unseen_nurse <dbl>

``` r
write.csv(results[["run_results"]],
          file.path(testdata_dir, "base_run_results.csv"),
          row.names = FALSE)
```

## Model with a warm-up period

``` r
# Define model parameters
param <- parameters(
  patient_inter = 4L,
  mean_n_consult_time = 10L,
  number_of_nurses = 5L,
  warm_up_period = 40L,
  data_collection_period = 80L,
  number_of_runs = 10L,
  cores = 1L
)

# Run the replications
results <- runner(param)[["run_results"]]

# Preview
head(results)
```

    ## # A tibble: 6 × 9
    ##   replication arrivals mean_patients_in_service mean_queue_length_nurse
    ##         <int>    <int>                    <dbl>                   <dbl>
    ## 1           1       19                     2.34                  0     
    ## 2           2       15                     2.07                  0     
    ## 3           3       26                     2.88                  0     
    ## 4           4       16                     2.02                  0.0634
    ## 5           5       20                     1.72                  0.272 
    ## 6           6       19                     1.50                  0     
    ## # ℹ 5 more variables: mean_waiting_time_nurse <dbl>,
    ## #   mean_serve_time_nurse <dbl>, utilisation_nurse <dbl>,
    ## #   count_unseen_nurse <int>, mean_waiting_time_unseen_nurse <dbl>

``` r
# Save to csv
write.csv(results, file.path(testdata_dir, "warm_up_results.csv"),
          row.names = FALSE)
```

## Scenario analysis

``` r
# Define model parameters
param <- parameters(
  patient_inter = 4L,
  mean_n_consult_time = 10L,
  number_of_nurses = 5L,
  data_collection_period = 80L,
  number_of_runs = 3L,
  cores = 1L
)

# Run scenario analysis
scenarios <- list(
  patient_inter = c(3L, 4L),
  number_of_nurses = c(6L, 7L)
)
scenario_results <- run_scenarios(scenarios, base_list = param)
```

    ## There are 4 scenarios.

    ## Base parameters:

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
    ## [1] 3
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

    ## Scenario: patient_inter = 3, number_of_nurses = 6

    ## Scenario: patient_inter = 4, number_of_nurses = 6

    ## Scenario: patient_inter = 3, number_of_nurses = 7

    ## Scenario: patient_inter = 4, number_of_nurses = 7

``` r
# Preview
head(scenario_results)
```

    ## # A tibble: 6 × 12
    ##   replication arrivals mean_patients_in_service mean_queue_length_nurse
    ##         <int>    <int>                    <dbl>                   <dbl>
    ## 1           1       27                     2.74                  0     
    ## 2           2       29                     4.58                  0.0613
    ## 3           3       39                     4.62                  0.0946
    ## 4           1       17                     1.58                  0     
    ## 5           2       21                     2.91                  0.0793
    ## 6           3       28                     3.26                  0     
    ## # ℹ 8 more variables: mean_waiting_time_nurse <dbl>,
    ## #   mean_serve_time_nurse <dbl>, utilisation_nurse <dbl>,
    ## #   count_unseen_nurse <int>, mean_waiting_time_unseen_nurse <dbl>,
    ## #   scenario <int>, patient_inter <int>, number_of_nurses <int>

``` r
# Save to csv
write.csv(scenario_results, file.path(testdata_dir, "scenario_results.csv"),
          row.names = FALSE)
```

## Running the simulation when attempting to determine an appropriate number of parameters

The `confidence_interval_method` and `ReplicationsAlgorithm` should
return the same results, so we will just run one to use in the back
tests.

``` r
# Specify parameters (so consistent even if defaults change)
param <- parameters(
  patient_inter = 4L,
  mean_n_consult_time = 10L,
  number_of_nurses = 5L,
  warm_up_period = 0L,
  data_collection_period = 80L
)

# Run the confidence_interval_method()
rep_results <- confidence_interval_method(
  replications = 15L,
  desired_precision = 0.1,
  metric = "mean_serve_time_nurse"
)
```

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
    ## [1] 15
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

    ## Warning: Running 15 replications did not reach desired precision (0.1).

``` r
# Preview results
head(rep_results)
```

    ##   replications      data cumulative_mean    stdev lower_ci upper_ci deviation
    ## 1            1 10.808606       10.808606       NA       NA       NA        NA
    ## 2            2  9.319953       10.064280       NA       NA       NA        NA
    ## 3            3 12.141014       10.756525 1.411251 7.250782 14.26227 0.3259178
    ## 4            4  8.889448       10.289755 1.482986 7.929994 12.64952 0.2293312
    ## 5            5  7.603423        9.752489 1.758611 7.568885 11.93609 0.2239022
    ## 6            6  5.009584        8.962005 2.494667 6.344013 11.58000 0.2921212
    ##                  metric
    ## 1 mean_serve_time_nurse
    ## 2 mean_serve_time_nurse
    ## 3 mean_serve_time_nurse
    ## 4 mean_serve_time_nurse
    ## 5 mean_serve_time_nurse
    ## 6 mean_serve_time_nurse

``` r
# Save to csv
write.csv(rep_results, file.path(testdata_dir, "choose_rep_results.csv"),
          row.names = FALSE)
```

## Calculate run time

``` r
# Get run time in seconds
end_time <- Sys.time()
runtime <- as.numeric(end_time - start_time, units = "secs")

# Display converted to minutes and seconds
minutes <- as.integer(runtime / 60L)
seconds <- as.integer(runtime %% 60L)
cat(sprintf("Notebook run time: %dm %ds", minutes, seconds))
```

    ## Notebook run time: 0m 3s
