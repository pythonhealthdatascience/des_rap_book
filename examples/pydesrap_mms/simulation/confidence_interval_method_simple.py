"""
confidence_interval_method_simple.
"""
# pylint: disable=duplicate-code

import warnings

import pandas as pd

from .param import Param
from .runner import Runner
from .summary_stats import summary_stats


# pylint: disable=too-many-arguments,too-many-positional-arguments
def confidence_interval_method_simple(
    replications,
    metrics,
    param=Param(),
    desired_precision=0.05,
    min_rep=3,
    verbose=False
):
    """
    Simple implementation using the confidence interval method to select the
    number of replications.

    This produces the same results as confidence_interval_method(), but depends
    on summary_stats() instead of ReplicationTabulizer and OnlineStatistics.
    We provide both confidence interval functions to give examples on a few
    ways you could do this analysis.

    Parameters
    ----------
    replications : int
        Number of times to run the model.
    metrics : list of str
        List of performance metrics to assess.
    param : Param, optional
        Instance of the parameter class with parameters to use (will use
        default parameters if not provided).
    desired_precision : float, optional
        The target half width precision (i.e. percentage deviation of the
        confidence interval from the mean).
    min_rep : int, optional
        Minimum number of replications before checking precision.
        Useful when the number of replications returned does not provide a
        stable precision below target.
    verbose : bool, optional
        Whether to print progress updates.

    Returns
    -------
    tuple of (dict, pd.DataFrame)
        - A dictionary with the minimum number of replications required
          to meet the precision for each metric.
        - DataFrame containing cumulative statistics for each
          replication for each metric.

    Warnings
    --------
    Issues a warning if the desired precision is not met within the
    provided replications.
    """
    # Replace runs in param with the specified number of replications
    param.number_of_runs = replications

    # Run the model
    choose_rep = Runner(param)
    choose_rep.run_reps()
    df = choose_rep.run_results_df

    nreps_dict = {}
    summary_table_list = []

    for metric in metrics:
        # Compute cumulative statistics
        cumulative = pd.DataFrame([
            {
                "replications": i + 1,  # Adjusted as counted from zero
                "data": df[metric][i],
                "cumulative_mean": stats[0],
                "stdev": stats[1],
                "lower_ci": stats[2],
                "upper_ci": stats[3],
                "deviation": (stats[3] - stats[0]) / stats[0]
            }
            for i, stats in enumerate(
                (summary_stats(df[metric].iloc[:i])
                 for i in range(1, replications + 1))
            )
        ])

        # Get minimum number of replications where deviation is below target
        try:
            nreps = (
                cumulative
                .loc[cumulative["replications"] >= min_rep]
                .loc[cumulative["deviation"] <= desired_precision]
                .iloc[0]
                .replications
            )
            if verbose:
                print(f"{metric}: Reached desired precision in {nreps} " +
                      "replications.")
        # Return warning if there are no replications with desired precision
        except IndexError:
            warnings.warn(
                f"Running {replications} replications did not reach desired "
                f"precision ({desired_precision}) for metric {metric}."
            )
            nreps = None

        # Add solution to dictionary
        nreps_dict[metric] = nreps

        # Add metric name to table then append to list
        cumulative["metric"] = metric
        summary_table_list.append(cumulative)

    # Combine into a single table
    summary_frame = pd.concat(summary_table_list)

    return nreps_dict, summary_frame
