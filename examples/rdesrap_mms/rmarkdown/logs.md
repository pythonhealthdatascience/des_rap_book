Logs
================
Amy Heather
2025-06-04

- [Set up](#set-up)
- [Simulation run with logs printed to the
  console](#simulation-run-with-logs-printed-to-the-console)
  - [Interpreting the simmer log
    messages](#interpreting-the-simmer-log-messages)
  - [Compare with recorded results](#compare-with-recorded-results)
- [Customising the log messages](#customising-the-log-messages)
- [Calculate run time](#calculate-run-time)

Logs will describe events during the simulation. Simmer has built-in
functionality to generate logs, which can be activated by setting
`verbose` as TRUE.

Logs will output lots of information, so they are best used when running
the simulation for a short time with few patients. For example, to
illustrate how a simulation work, or to support debugging.

## Set up

Install the latest version of the local simulation package. If running
sequentially, `devtools::load_all()` is sufficient. If running in
parallel, you must use `devtools::install()`.

``` r
devtools::load_all()
```

    ## ℹ Loading simulation

Start timer.

``` r
start_time <- Sys.time()
```

## Simulation run with logs printed to the console

We use the built-in simmer logging functionality. Within our `model`
function, we accept the parameters:

- `log_to_console` - whether to print the activity log to the console.
- `log_to_file` - whether to save the activity log to a file.
- `file_path` - path to save log to file.

Here, we will print to console and save to file:

``` r
log_file <- file.path("..", "outputs", "logs", "log_example.log")

param <- parameters(
  patient_inter = 6L,
  mean_n_consult_time = 8L,
  number_of_nurses = 1L,
  data_collection_period = 30L,
  number_of_runs = 1L,
  cores = 1L,
  log_to_console = TRUE,
  log_to_file = TRUE,
  file_path = log_file
)

verbose_run <- model(run_number = 0L, param = param)
```

    ##  [1] "Parameters:"                                                                                                                                                                                                                             
    ##  [2] "patient_inter=6; mean_n_consult_time=8; number_of_nurses=1; warm_up_period=0; data_collection_period=30; number_of_runs=1; scenario_name=NULL; cores=1; log_to_console=TRUE; log_to_file=TRUE; file_path=../outputs/logs/log_example.log"
    ##  [3] "Log:"                                                                                                                                                                                                                                    
    ##  [4] "         0 |    source: patient          |       new: patient0         | 1.10422"                                                                                                                                                        
    ##  [5] "   1.10422 |   arrival: patient0         |  activity: SetAttribute     | [nurse_queue_on_arrival], function(), 0, N, 0"                                                                                                                  
    ##  [6] "   1.10422 |   arrival: patient0         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                                                              
    ##  [7] "   1.10422 |  resource: nurse            |   arrival: patient0         | SERVE"                                                                                                                                                          
    ##  [8] "   1.10422 |   arrival: patient0         |  activity: SetAttribute     | [nurse_serve_start], function(), 0, N, 0"                                                                                                                       
    ##  [9] "   1.10422 |   arrival: patient0         |  activity: SetAttribute     | [nurse_serve_length], function(), 0, N, 0"                                                                                                                      
    ## [10] "   1.10422 |    source: patient          |       new: patient1         | 1.94299"                                                                                                                                                        
    ## [11] "   1.10422 |   arrival: patient0         |  activity: Timeout          | function()"                                                                                                                                                     
    ## [12] "   1.94299 |   arrival: patient1         |  activity: SetAttribute     | [nurse_queue_on_arrival], function(), 0, N, 0"                                                                                                                  
    ## [13] "   1.94299 |   arrival: patient1         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                                                              
    ## [14] "   1.94299 |  resource: nurse            |   arrival: patient1         | ENQUEUE"                                                                                                                                                        
    ## [15] "   1.94299 |    source: patient          |       new: patient2         | 4.5594"                                                                                                                                                         
    ## [16] "   2.26987 |   arrival: patient0         |  activity: Release          | nurse, 1"                                                                                                                                                       
    ## [17] "   2.26987 |  resource: nurse            |   arrival: patient0         | DEPART"                                                                                                                                                         
    ## [18] "   2.26987 |      task: Post-Release     |          :                  | "                                                                                                                                                               
    ## [19] "   2.26987 |  resource: nurse            |   arrival: patient1         | SERVE"                                                                                                                                                          
    ## [20] "   2.26987 |   arrival: patient1         |  activity: SetAttribute     | [nurse_serve_start], function(), 0, N, 0"                                                                                                                       
    ## [21] "   2.26987 |   arrival: patient1         |  activity: SetAttribute     | [nurse_serve_length], function(), 0, N, 0"                                                                                                                      
    ## [22] "   2.26987 |   arrival: patient1         |  activity: Timeout          | function()"                                                                                                                                                     
    ## [23] "    4.5594 |   arrival: patient2         |  activity: SetAttribute     | [nurse_queue_on_arrival], function(), 0, N, 0"                                                                                                                  
    ## [24] "    4.5594 |   arrival: patient2         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                                                              
    ## [25] "    4.5594 |  resource: nurse            |   arrival: patient2         | ENQUEUE"                                                                                                                                                        
    ## [26] "    4.5594 |    source: patient          |       new: patient3         | 11.9368"                                                                                                                                                        
    ## [27] "   11.9368 |   arrival: patient3         |  activity: SetAttribute     | [nurse_queue_on_arrival], function(), 0, N, 0"                                                                                                                  
    ## [28] "   11.9368 |   arrival: patient3         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                                                              
    ## [29] "   11.9368 |  resource: nurse            |   arrival: patient3         | ENQUEUE"                                                                                                                                                        
    ## [30] "   11.9368 |    source: patient          |       new: patient4         | 15.1749"                                                                                                                                                        
    ## [31] "   15.1749 |   arrival: patient4         |  activity: SetAttribute     | [nurse_queue_on_arrival], function(), 0, N, 0"                                                                                                                  
    ## [32] "   15.1749 |   arrival: patient4         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                                                              
    ## [33] "   15.1749 |  resource: nurse            |   arrival: patient4         | ENQUEUE"                                                                                                                                                        
    ## [34] "   15.1749 |    source: patient          |       new: patient5         | 20.9143"                                                                                                                                                        
    ## [35] "   20.9143 |   arrival: patient5         |  activity: SetAttribute     | [nurse_queue_on_arrival], function(), 0, N, 0"                                                                                                                  
    ## [36] "   20.9143 |   arrival: patient5         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                                                              
    ## [37] "   20.9143 |  resource: nurse            |   arrival: patient5         | ENQUEUE"                                                                                                                                                        
    ## [38] "   20.9143 |    source: patient          |       new: patient6         | 21.7966"                                                                                                                                                        
    ## [39] "   21.7966 |   arrival: patient6         |  activity: SetAttribute     | [nurse_queue_on_arrival], function(), 0, N, 0"                                                                                                                  
    ## [40] "   21.7966 |   arrival: patient6         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                                                              
    ## [41] "   21.7966 |  resource: nurse            |   arrival: patient6         | ENQUEUE"                                                                                                                                                        
    ## [42] "   21.7966 |    source: patient          |       new: patient7         | 30.141"                                                                                                                                                         
    ## [43] "   25.4296 |   arrival: patient1         |  activity: Release          | nurse, 1"                                                                                                                                                       
    ## [44] "   25.4296 |  resource: nurse            |   arrival: patient1         | DEPART"                                                                                                                                                         
    ## [45] "   25.4296 |      task: Post-Release     |          :                  | "                                                                                                                                                               
    ## [46] "   25.4296 |  resource: nurse            |   arrival: patient2         | SERVE"                                                                                                                                                          
    ## [47] "   25.4296 |   arrival: patient2         |  activity: SetAttribute     | [nurse_serve_start], function(), 0, N, 0"                                                                                                                       
    ## [48] "   25.4296 |   arrival: patient2         |  activity: SetAttribute     | [nurse_serve_length], function(), 0, N, 0"                                                                                                                      
    ## [49] "   25.4296 |   arrival: patient2         |  activity: Timeout          | function()"

If we import the log file, we’ll see it contains the same output:

``` r
log_contents <- readLines(log_file)
print(log_contents, sep = "\n")
```

    ##  [1] "Parameters:"                                                                                                                                                                                                                             
    ##  [2] "patient_inter=6; mean_n_consult_time=8; number_of_nurses=1; warm_up_period=0; data_collection_period=30; number_of_runs=1; scenario_name=NULL; cores=1; log_to_console=TRUE; log_to_file=TRUE; file_path=../outputs/logs/log_example.log"
    ##  [3] "Log:"                                                                                                                                                                                                                                    
    ##  [4] "         0 |    source: patient          |       new: patient0         | 1.10422"                                                                                                                                                        
    ##  [5] "   1.10422 |   arrival: patient0         |  activity: SetAttribute     | [nurse_queue_on_arrival], function(), 0, N, 0"                                                                                                                  
    ##  [6] "   1.10422 |   arrival: patient0         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                                                              
    ##  [7] "   1.10422 |  resource: nurse            |   arrival: patient0         | SERVE"                                                                                                                                                          
    ##  [8] "   1.10422 |   arrival: patient0         |  activity: SetAttribute     | [nurse_serve_start], function(), 0, N, 0"                                                                                                                       
    ##  [9] "   1.10422 |   arrival: patient0         |  activity: SetAttribute     | [nurse_serve_length], function(), 0, N, 0"                                                                                                                      
    ## [10] "   1.10422 |    source: patient          |       new: patient1         | 1.94299"                                                                                                                                                        
    ## [11] "   1.10422 |   arrival: patient0         |  activity: Timeout          | function()"                                                                                                                                                     
    ## [12] "   1.94299 |   arrival: patient1         |  activity: SetAttribute     | [nurse_queue_on_arrival], function(), 0, N, 0"                                                                                                                  
    ## [13] "   1.94299 |   arrival: patient1         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                                                              
    ## [14] "   1.94299 |  resource: nurse            |   arrival: patient1         | ENQUEUE"                                                                                                                                                        
    ## [15] "   1.94299 |    source: patient          |       new: patient2         | 4.5594"                                                                                                                                                         
    ## [16] "   2.26987 |   arrival: patient0         |  activity: Release          | nurse, 1"                                                                                                                                                       
    ## [17] "   2.26987 |  resource: nurse            |   arrival: patient0         | DEPART"                                                                                                                                                         
    ## [18] "   2.26987 |      task: Post-Release     |          :                  | "                                                                                                                                                               
    ## [19] "   2.26987 |  resource: nurse            |   arrival: patient1         | SERVE"                                                                                                                                                          
    ## [20] "   2.26987 |   arrival: patient1         |  activity: SetAttribute     | [nurse_serve_start], function(), 0, N, 0"                                                                                                                       
    ## [21] "   2.26987 |   arrival: patient1         |  activity: SetAttribute     | [nurse_serve_length], function(), 0, N, 0"                                                                                                                      
    ## [22] "   2.26987 |   arrival: patient1         |  activity: Timeout          | function()"                                                                                                                                                     
    ## [23] "    4.5594 |   arrival: patient2         |  activity: SetAttribute     | [nurse_queue_on_arrival], function(), 0, N, 0"                                                                                                                  
    ## [24] "    4.5594 |   arrival: patient2         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                                                              
    ## [25] "    4.5594 |  resource: nurse            |   arrival: patient2         | ENQUEUE"                                                                                                                                                        
    ## [26] "    4.5594 |    source: patient          |       new: patient3         | 11.9368"                                                                                                                                                        
    ## [27] "   11.9368 |   arrival: patient3         |  activity: SetAttribute     | [nurse_queue_on_arrival], function(), 0, N, 0"                                                                                                                  
    ## [28] "   11.9368 |   arrival: patient3         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                                                              
    ## [29] "   11.9368 |  resource: nurse            |   arrival: patient3         | ENQUEUE"                                                                                                                                                        
    ## [30] "   11.9368 |    source: patient          |       new: patient4         | 15.1749"                                                                                                                                                        
    ## [31] "   15.1749 |   arrival: patient4         |  activity: SetAttribute     | [nurse_queue_on_arrival], function(), 0, N, 0"                                                                                                                  
    ## [32] "   15.1749 |   arrival: patient4         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                                                              
    ## [33] "   15.1749 |  resource: nurse            |   arrival: patient4         | ENQUEUE"                                                                                                                                                        
    ## [34] "   15.1749 |    source: patient          |       new: patient5         | 20.9143"                                                                                                                                                        
    ## [35] "   20.9143 |   arrival: patient5         |  activity: SetAttribute     | [nurse_queue_on_arrival], function(), 0, N, 0"                                                                                                                  
    ## [36] "   20.9143 |   arrival: patient5         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                                                              
    ## [37] "   20.9143 |  resource: nurse            |   arrival: patient5         | ENQUEUE"                                                                                                                                                        
    ## [38] "   20.9143 |    source: patient          |       new: patient6         | 21.7966"                                                                                                                                                        
    ## [39] "   21.7966 |   arrival: patient6         |  activity: SetAttribute     | [nurse_queue_on_arrival], function(), 0, N, 0"                                                                                                                  
    ## [40] "   21.7966 |   arrival: patient6         |  activity: Seize            | nurse, 1, 0 paths"                                                                                                                                              
    ## [41] "   21.7966 |  resource: nurse            |   arrival: patient6         | ENQUEUE"                                                                                                                                                        
    ## [42] "   21.7966 |    source: patient          |       new: patient7         | 30.141"                                                                                                                                                         
    ## [43] "   25.4296 |   arrival: patient1         |  activity: Release          | nurse, 1"                                                                                                                                                       
    ## [44] "   25.4296 |  resource: nurse            |   arrival: patient1         | DEPART"                                                                                                                                                         
    ## [45] "   25.4296 |      task: Post-Release     |          :                  | "                                                                                                                                                               
    ## [46] "   25.4296 |  resource: nurse            |   arrival: patient2         | SERVE"                                                                                                                                                          
    ## [47] "   25.4296 |   arrival: patient2         |  activity: SetAttribute     | [nurse_serve_start], function(), 0, N, 0"                                                                                                                       
    ## [48] "   25.4296 |   arrival: patient2         |  activity: SetAttribute     | [nurse_serve_length], function(), 0, N, 0"                                                                                                                      
    ## [49] "   25.4296 |   arrival: patient2         |  activity: Timeout          | function()"

### Interpreting the simmer log messages

#### Example A: `patient0`

The patient arrives at 1.10422 and requests a nurse. There is one
available (`SERVE`) so the consultation begins (`Timeout`).

    [5] "  1.10422 |   arrival: patient0         |  activity: Seize            | nurse, 1, 0 paths"
    [6] "  1.10422 |  resource: nurse            |   arrival: patient0         | SERVE"
    ...
    [10] " 1.10422 |   arrival: patient0         |  activity: Timeout          | function()"  

The consultation finishes at 2.26987, and the patient leaves:

    [14] "   2.26987 |   arrival: patient0         |  activity: Release          | nurse, 1"
    [15] "   2.26987 |  resource: nurse            |   arrival: patient0         | DEPART"
    [16] "   2.26987 |      task: Post-Release     |          :                  | "

#### Example B: `patient2`

The patient arrives at 4.5594, requests a nurse and enters a queue
(`ENQUEUE`).

    [13] "   1.94299 |    source: patient          |       new: patient2         | 4.5594"             
    ...
    [21] "    4.5594 |   arrival: patient2         |  activity: Seize            | nurse, 1, 0 paths"
    [22] "    4.5594 |  resource: nurse            |   arrival: patient2         | ENQUEUE"

A nurse becomes available at 25.3823 (`SERVE`) so consultation begins
(`Timeout`).

    [39] "   25.4296 |  resource: nurse            |   arrival: patient2         | SERVE"
    ...                                                                                          
    [42] "   25.4296 |   arrival: patient2         |  activity: Timeout          | function()"

However, there are no further entries for that patient as the simulation
ends before the consultation ends.

### Compare with recorded results

The logs will align with the recorded results of each patient.

``` r
arrange(verbose_run[["arrivals"]], start_time)
```

    ##       name start_time  end_time activity_time resource replication
    ## 1 patient0   1.104219  2.269873      1.165654    nurse           0
    ## 2 patient1   1.942991 25.429622     23.159748    nurse           0
    ## 3 patient2   4.559403        NA            NA    nurse           0
    ## 4 patient3  11.936775        NA            NA    nurse           0
    ## 5 patient4  15.174872        NA            NA    nurse           0
    ## 6 patient5  20.914277        NA            NA    nurse           0
    ## 7 patient6  21.796553        NA            NA    nurse           0
    ##   queue_on_arrival serve_start serve_length  wait_time wait_time_unseen
    ## 1                0    1.104219     1.165654  0.0000000               NA
    ## 2                0    2.269873    23.159748  0.3268822               NA
    ## 3                0   25.429622     6.096239 20.8702188               NA
    ## 4                1          NA           NA         NA        18.063225
    ## 5                2          NA           NA         NA        14.825128
    ## 6                3          NA           NA         NA         9.085723
    ## 7                4          NA           NA         NA         8.203447

## Customising the log messages

The `simmer` package allows us to add additional log messages using the
`_log()` function.

Here, we take our simmer code from `model.R` but set `verbose = TRUE`.
We can then add additional `_log()` messages within the patient
trajectory.

You may find this helpful for interpreting the log messages (for
example, with the addition of emojis to make different activities more
distinct).

``` r
# Set the seed
set.seed(0L)

env <- simmer("simulation", verbose = FALSE)

# Define the patient trajectory
patient <- trajectory("appointment") %>%
  simmer::log_("🚶 Arrives.") %>%
  seize("nurse", 1L) %>%
  set_attribute("nurse_serve_start", function() now(env)) %>%
  set_attribute("nurse_serve_length", function() {
    rexp(n = 1L, rate = 1L / param[["mean_n_consult_time"]])
  }) %>%
  simmer::log_(function() {
    paste0("🩺 Nurse consultation begins (length: ",
           round(get_attribute(env, "nurse_serve_length"), 5L), ")")
  }) %>%
  timeout(function() get_attribute(env, "nurse_serve_length")) %>%
  release("nurse", 1L) %>%
  simmer::log_("🚪 Leaves.")

env <- env %>%
  add_resource("nurse", param[["number_of_nurses"]]) %>%
  add_generator("patient", patient, function() {
    rexp(n = 1L, rate = 1L / param[["patient_inter"]])
  }) %>%
  simmer::run(param[["data_collection_period"]])
```

    ## 1.10422: patient0: 🚶 Arrives.
    ## 1.10422: patient0: 🩺 Nurse consultation begins (length: 1.16565)
    ## 1.94299: patient1: 🚶 Arrives.
    ## 2.26987: patient0: 🚪 Leaves.
    ## 2.26987: patient1: 🩺 Nurse consultation begins (length: 23.15975)
    ## 4.5594: patient2: 🚶 Arrives.
    ## 11.9368: patient3: 🚶 Arrives.
    ## 15.1749: patient4: 🚶 Arrives.
    ## 20.9143: patient5: 🚶 Arrives.
    ## 21.7966: patient6: 🚶 Arrives.
    ## 25.4296: patient1: 🚪 Leaves.
    ## 25.4296: patient2: 🩺 Nurse consultation begins (length: 6.09624)

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

    ## Notebook run time: 0m 0s
