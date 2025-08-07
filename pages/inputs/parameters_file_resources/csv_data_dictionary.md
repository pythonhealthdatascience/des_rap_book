---
title: "Data Dictionary: `example_parameters` CSV"
format:
  pdf:
    geometry:
      - left=1cm
      - right=1cm
      - top=1cm
      - bottom=1cm
---

\vspace*{-2cm}

| Column | Data type | Description | Possible values |
| - | - | - | --- |
| patient | str | Patient type | `adult`, `child` or `elderly` |
| metric | str | Metric | `interarrival`: Inter-arrival time (time between patient admissions)<br>`consultation`: Length of consultation<br>`transfer`: Transfer probability |
| value | float | Value of the metric | Times or probabilities |