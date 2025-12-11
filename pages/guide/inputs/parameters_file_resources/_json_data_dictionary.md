---
title: "Data Dictionary: `example_parameters` JSON"
format:
  pdf:
    geometry:
      - left=1cm
      - right=1cm
      - top=1cm
      - bottom=1cm
---

\vspace*{-2cm}

## Top-level key: `simulation_parameters`

**Type:** object

**Description:** Maps parameter names (str) to a specification describing how to sample from a statistical distribution for this metric in the simulation.

## Structure summary

Each item under `simulation_parameters` is itself an object with:

* `class_name`: The name of the distribution class to use.
* `params`: An object containing parameters required by that distribution.

## Parameter specification table

| Field | Data type | Description | Example/Allowed values |
| - | - | -- | -- |
| Parameter name | str (object key) | Description name for the parameter: `<patient>_<metric>` | `adult_interarrival`, `child_consultation`, `elderly_transfer` |
| `class_name` | str | Statistical distribution for the parameter | `Exponential` |
| `params ` | Object | Dictionary of parameters required to instantiate the distribution | See subsequent rows per distribution type |

## Distribution-specific `params` field

| `class_name` | Parameter key(s) | Data type | Description | Example values |
| - | - | - | - | - |
| `Exponential` | mean | float | Mean of exponential distribution | `5.0`, `0.2` |

## Glossary

### Patient

* `child`: age 0 to 15 years.
* `adult`: age 16 to 64 years.
* `elderly`: age 65 years and over.

### Metric

* `interarrival`: Inter-arrival time (minutes between admissions).
* `consultation`: Length of consultation (minutes).
* `transfer`: Probability of transfer.