Using `set_attributes()`
================
Amy Heather
2025-06-04

- [Original model](#original-model)
- [Model with record of allocation to a nurse
  resource](#model-with-record-of-allocation-to-a-nurse-resource)
- [Model with length of time sampled to spend with a nurse
  resource](#model-with-length-of-time-sampled-to-spend-with-a-nurse-resource)

In `model.R`, we use the `simmer` functions `set_attributes()` and
`get_attributes()` to record additional information on each patient from
the model run - specifically:

1.  When the are allocated a nurse resource (ie. after any queueing).
2.  The length time sampled to spend with the nurse resource.

This is important, as otherwise the result returned by
`get_mon_arrivals()` only includes information on the start time
(arrival) and end time (finished with resource) for each patient, and
those who are with a resource but do not finish before simulation end
are excluded.

This document explains how the first attribute has no change on the
model results, but how the second attribute does impact them. This isn’t
bad! It is just important if you are transitioning between not recording
this attribute and to then recording this attribute, that it will have
altered the order of random number generation, so the exact results now
differ from before.

``` r
# nolint start: undesirable_function_linter.
library(simmer)
# nolint end
```

## Original model

``` r
param <- list(
  patient_inter = 6L,
  mean_n_consult_time = 8L,
  number_of_nurses = 1L,
  warm_up_period = 0L,
  data_collection_period = 20L
)

run_number <- 0L
verbose <- TRUE
```

``` r
set.seed(run_number)

env <- simmer("simulation", verbose = verbose)

patient <- trajectory("appointment") %>%
  seize("nurse", 1L) %>%
  timeout(function() {
    rexp(n = 1L, rate = 1L / param[["mean_n_consult_time"]])
  }) %>%
  release("nurse", 1L)

env <- env %>%
  add_resource("nurse", param[["number_of_nurses"]]) %>%
  add_generator("patient", patient, function() {
    rexp(n = 1L, rate = 1L / param[["patient_inter"]])
  }) %>%
  simmer::run(param[["warm_up_period"]] + param[["data_collection_period"]])
```

    ##          0 |    source: patient          |       new: patient0         | 1.10422
    ##    1.10422 |   arrival: patient0         |  activity: Seize            | nurse, 1, 0 paths
    ##    1.10422 |  resource: nurse            |   arrival: patient0         | SERVE
    ##    1.10422 |    source: patient          |       new: patient1         | 1.97846
    ##    1.10422 |   arrival: patient0         |  activity: Timeout          | function()
    ##    1.97846 |   arrival: patient1         |  activity: Seize            | nurse, 1, 0 paths
    ##    1.97846 |  resource: nurse            |   arrival: patient1         | ENQUEUE
    ##    1.97846 |    source: patient          |       new: patient2         | 4.59487
    ##    2.22258 |   arrival: patient0         |  activity: Release          | nurse, 1
    ##    2.22258 |  resource: nurse            |   arrival: patient0         | DEPART
    ##    2.22258 |      task: Post-Release     |          :                  | 
    ##    2.22258 |  resource: nurse            |   arrival: patient1         | SERVE
    ##    2.22258 |   arrival: patient1         |  activity: Timeout          | function()
    ##    4.59487 |   arrival: patient2         |  activity: Seize            | nurse, 1, 0 paths
    ##    4.59487 |  resource: nurse            |   arrival: patient2         | ENQUEUE
    ##    4.59487 |    source: patient          |       new: patient3         | 11.9722
    ##    11.9722 |   arrival: patient3         |  activity: Seize            | nurse, 1, 0 paths
    ##    11.9722 |  resource: nurse            |   arrival: patient3         | ENQUEUE
    ##    11.9722 |    source: patient          |       new: patient4         | 15.2103
    ##    15.2103 |   arrival: patient4         |  activity: Seize            | nurse, 1, 0 paths
    ##    15.2103 |  resource: nurse            |   arrival: patient4         | ENQUEUE
    ##    15.2103 |    source: patient          |       new: patient5         | 20.9497

## Model with record of allocation to a nurse resource

Exactly the same results…

``` r
set.seed(run_number)

env <- simmer("simulation", verbose = verbose)

patient <- trajectory("appointment") %>%
  seize("nurse", 1L) %>%
  # NEW LINE:
  # --------------------------------------------------------------
  set_attribute("nurse_serve_start", function() now(env)) %>%
  # --------------------------------------------------------------
  timeout(function() {
    rexp(n = 1L, rate = 1L / param[["mean_n_consult_time"]])
  }) %>%
  release("nurse", 1L)

env <- env %>%
  add_resource("nurse", param[["number_of_nurses"]]) %>%
  add_generator("patient", patient, function() {
    rexp(n = 1L, rate = 1L / param[["patient_inter"]])
  }) %>%
  simmer::run(param[["warm_up_period"]] + param[["data_collection_period"]])
```

    ##          0 |    source: patient          |       new: patient0         | 1.10422
    ##    1.10422 |   arrival: patient0         |  activity: Seize            | nurse, 1, 0 paths
    ##    1.10422 |  resource: nurse            |   arrival: patient0         | SERVE
    ##    1.10422 |   arrival: patient0         |  activity: SetAttribute     | [nurse_serve_start], function(), 0, N, 0
    ##    1.10422 |    source: patient          |       new: patient1         | 1.97846
    ##    1.10422 |   arrival: patient0         |  activity: Timeout          | function()
    ##    1.97846 |   arrival: patient1         |  activity: Seize            | nurse, 1, 0 paths
    ##    1.97846 |  resource: nurse            |   arrival: patient1         | ENQUEUE
    ##    1.97846 |    source: patient          |       new: patient2         | 4.59487
    ##    2.22258 |   arrival: patient0         |  activity: Release          | nurse, 1
    ##    2.22258 |  resource: nurse            |   arrival: patient0         | DEPART
    ##    2.22258 |      task: Post-Release     |          :                  | 
    ##    2.22258 |  resource: nurse            |   arrival: patient1         | SERVE
    ##    2.22258 |   arrival: patient1         |  activity: SetAttribute     | [nurse_serve_start], function(), 0, N, 0
    ##    2.22258 |   arrival: patient1         |  activity: Timeout          | function()
    ##    4.59487 |   arrival: patient2         |  activity: Seize            | nurse, 1, 0 paths
    ##    4.59487 |  resource: nurse            |   arrival: patient2         | ENQUEUE
    ##    4.59487 |    source: patient          |       new: patient3         | 11.9722
    ##    11.9722 |   arrival: patient3         |  activity: Seize            | nurse, 1, 0 paths
    ##    11.9722 |  resource: nurse            |   arrival: patient3         | ENQUEUE
    ##    11.9722 |    source: patient          |       new: patient4         | 15.2103
    ##    15.2103 |   arrival: patient4         |  activity: Seize            | nurse, 1, 0 paths
    ##    15.2103 |  resource: nurse            |   arrival: patient4         | ENQUEUE
    ##    15.2103 |    source: patient          |       new: patient5         | 20.9497

## Model with length of time sampled to spend with a nurse resource

Same time for first arrival, but subsequently different sampling
results…

``` r
set.seed(run_number)

env <- simmer("simulation", verbose = verbose)

patient <- trajectory("appointment") %>%
  seize("nurse", 1L) %>%
  # NEW LINES:
  # --------------------------------------------------------------
  set_attribute("nurse_serve_length", function() {
    rexp(n = 1L, rate = 1L / param[["mean_n_consult_time"]])
  }) %>%
  timeout(function() get_attribute(env, "nurse_serve_length")) %>%
  # --------------------------------------------------------------
  release("nurse", 1L)

env <- env %>%
  add_resource("nurse", param[["number_of_nurses"]]) %>%
  add_generator("patient", patient, function() {
    rexp(n = 1L, rate = 1L / param[["patient_inter"]])
  }) %>%
  simmer::run(param[["warm_up_period"]] + param[["data_collection_period"]])
```

    ##          0 |    source: patient          |       new: patient0         | 1.10422
    ##    1.10422 |   arrival: patient0         |  activity: Seize            | nurse, 1, 0 paths
    ##    1.10422 |  resource: nurse            |   arrival: patient0         | SERVE
    ##    1.10422 |   arrival: patient0         |  activity: SetAttribute     | [nurse_serve_length], function(), 0, N, 0
    ##    1.10422 |    source: patient          |       new: patient1         | 1.94299
    ##    1.10422 |   arrival: patient0         |  activity: Timeout          | function()
    ##    1.94299 |   arrival: patient1         |  activity: Seize            | nurse, 1, 0 paths
    ##    1.94299 |  resource: nurse            |   arrival: patient1         | ENQUEUE
    ##    1.94299 |    source: patient          |       new: patient2         | 4.5594
    ##    2.26987 |   arrival: patient0         |  activity: Release          | nurse, 1
    ##    2.26987 |  resource: nurse            |   arrival: patient0         | DEPART
    ##    2.26987 |      task: Post-Release     |          :                  | 
    ##    2.26987 |  resource: nurse            |   arrival: patient1         | SERVE
    ##    2.26987 |   arrival: patient1         |  activity: SetAttribute     | [nurse_serve_length], function(), 0, N, 0
    ##    2.26987 |   arrival: patient1         |  activity: Timeout          | function()
    ##     4.5594 |   arrival: patient2         |  activity: Seize            | nurse, 1, 0 paths
    ##     4.5594 |  resource: nurse            |   arrival: patient2         | ENQUEUE
    ##     4.5594 |    source: patient          |       new: patient3         | 11.9368
    ##    11.9368 |   arrival: patient3         |  activity: Seize            | nurse, 1, 0 paths
    ##    11.9368 |  resource: nurse            |   arrival: patient3         | ENQUEUE
    ##    11.9368 |    source: patient          |       new: patient4         | 15.1749
    ##    15.1749 |   arrival: patient4         |  activity: Seize            | nurse, 1, 0 paths
    ##    15.1749 |  resource: nurse            |   arrival: patient4         | ENQUEUE
    ##    15.1749 |    source: patient          |       new: patient5         | 20.9143
