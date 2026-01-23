# Verification and validation checklist

This checklist is from: Heather, A., Monks, T., Mustafee, N., Harper, A., Alidoost, F., Challen, R., & Slater, T. (2025). DES RAP Book: Reproducible Discrete-Event Simulation in Python and R. https://github.com/pythonhealthdatascience/des_rap_book. https://doi.org/10.5281/zenodo.17094155.

## Verification

Desk checking

* [ ] Systematically check code.
* [ ] Keep documentation complete and up-to-date.
* [ ] Maintain an environment with all required packages.
* [ ] Lint code.
* [ ] Get code review.

Debugging

* [ ] Write tests - they'll help for spotting bugs.
* [ ] During model development, monitor the model using logs - they'll help with spotting bugs.
* [ ] Use GitHub issues to record bugs as they arise, so they aren't forgotten and are recorded for future reference.

Assertion checking

* [ ] Add checks in the model which cause errors if something doesn't look right.
* [ ] Write tests which check that assertions hold true.

Special input testing

* [ ] If there are input variables with explicit limits, design boundary value tests to check the behaviour at, just inside, and just outside each boundary.
* [ ] Write stress tests which simulate worst-case load and ensure model is robust under heavy demand.
* [ ] Write tests with little or no activity/waits/service.

Bottom-up testing

* [ ] Write unit tests for each individual component of the model.
* [ ] Once individual parts work correctly, combine them and test how they interact - this can be via integration testing or functional testing.

Regression testing

* [ ] Write tests early.
* [ ] Run tests regularly (locally or automatically via. GitHub actions).

Mathematical proof of correctness

* [ ] For parts of the model where theoretical results exist (like an M/M/s queue), compare simulation outputs with results from mathematical formulas.

## Validation

Face validation

* [ ] Present key simulation outputs and model behaviour to people such as: project team members; intended users of the model (e.g., healthcare analysts, managers); people familiar with the real system (e.g., clinicians, frontline staff, patient representatives). Ask for their subjective feedback on whether the model and results "look right". Discuss specific areas, such as whether performance measures (e.g., patient flow, wait times) match expectations under similar conditions.

Turing test

* [ ] Collect matching sets of model output and real system, remove identifying labels, and present them to a panel of experts. Record whether experts can distinguish simulation outputs from real data. Use their feedback on distinguishing features to further improve the simulation.

Predictive validation

* [ ] Use historical arrival data, staffing schedules, treatment times, or other inputs from a specific time period to drive your simulation. Compare the simulation's predictions for that period (e.g., waiting times, bed occupancy) against the real outcomes for the same period.
* [ ] Consider varying the periods you validate on—year-by-year, season-by-season, or even for particular policy changes or events—to detect strengths or weaknesses in the model across different scenarios.
* [ ] Use graphical comparisons (e.g., time series plots) or statistical measures (e.g., goodness-of-fit, mean errors, confidence intervals) to assess how closely the model matches reality - see below.

Graphical comparison

* [ ] Create time-series plots of key metrics (e.g., daily patient arrivals, resource utilisation) for both the model and system. Create distributions of waiting times, service times, and other performance measures. Compare the model and system graphs.

Statistical comparison

* [ ] Collect real system data on key performance measures (e.g., wait times, lengths of stay, throughput) and compare with model outputs statistically using appropriate tests.

Animation visualisation

* [ ] Create an animation to help with validation (as well as communicaton and reuse).

Comparison testing

* [ ] If you have multiple models of the same system, compare them!

Input data validation

* [ ] Check the datasets used - screen for outliers, determine if they are correct, and if the reason for them occurring should be incorporated into the simulation.
* [ ] Ensure you have performed appropriate input modelling steps when choosing your distributions.

Conceptual model validation

* [ ] Document and justify all modeling assumptions.
* [ ] Review the conceptual model with people familiar with the real system to assess completeness and accuracy.

Experimentation validation

* [ ] Use a warm-up period.
* [ ] Use statistical methods to determine sufficient run length and number of replications.
* [ ] Perform sensitivity analysis to test how changes in input parameters affect outputs.

Cross validation

* [ ] Search for similar simulation studies and compare the key assumptions, methods and results. Discuss discrepancies and explain reasons for different findings or approaches. Use insights from other studies to improve or validate your own model.
