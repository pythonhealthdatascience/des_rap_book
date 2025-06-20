"""
confidence_interval_method.

Acknowledgements
----------------
This code is adapted from Tom Monks (2021) sim-tools: fundamental tools to
support the simulation process in python
(https://github.com/TomMonks/sim-tools) (MIT Licence).
"""
# pylint: disable=duplicate-code

import warnings

import numpy as np
import pandas as pd

from .param import Param
from .runner import Runner
from .replicationtabulizer import ReplicationTabulizer
from .onlinestatistics import OnlineStatistics


# pylint: disable=too-many-arguments,too-many-positional-arguments,too-many-locals
def confidence_interval_method(
    replications,
    metrics,
    param=Param(),
    alpha=0.05,
    desired_precision=0.05,
    min_rep=3,
    verbose=False
):
    """
    The confidence interval method for selecting the number of replications.

    This method runs the model for the specified number of replications,
    calculates the cumulative mean and confidence intervals for each
    replication, and determines when the desired precision is first achieved
    for each metric. It does not check if this precision is maintained.

    Parameters
    ----------
    replications : int
        Number of times to run the model.
    metrics : list of str
        List of performance metrics to assess (should correspond to
        column names from the run results dataframe).
    param : Param, optional
        Instance of the parameter class with parameters to use (will use
        default parameters if not provided).
    alpha : float, optional
        Significance level for confidence interval calculations.
    desired_precision : float, optional
        The target half width precision (i.e. percentage deviation of the
        confidence interval from the mean).
    min_rep : int, optional
        Minimum number of replications before checking precision. Useful
        when the number of replications returned does not provide a stable
        precision below target.
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

    Notes
    -----
    Function adapted from Monks 2021.
    """
    # Replace runs in param with the specified number of replications
    param.number_of_runs = replications

    # Run the model
    choose_rep = Runner(param)
    choose_rep.run_reps()

    nreps_dict = {}
    summary_table_list = []

    for metric in metrics:
        # Extract replication results for the specified metric
        rep_res = choose_rep.run_results_df[metric]

        # Set up method for calculating statistics and saving them as a table
        observer = ReplicationTabulizer()
        stats = OnlineStatistics(
            alpha=alpha, data=np.array(rep_res[:2]), observer=observer
        )

        # Calculate statistics with each replication, and get summary table
        for i in range(2, len(rep_res)):
            stats.update(rep_res[i])

        results = observer.summary_table()

        # Get minimum number of replications where deviation is below target
        try:
            nreps = (
                results
                .loc[results["replications"] >= min_rep]
                .loc[results["deviation"] <= desired_precision]
                .iloc[0]
                .replications
            )
            if verbose:
                print(f"{metric}: Reached desired precision in {nreps} " +
                      "replications.")
        except IndexError:
            message = f"WARNING: {metric} does not reach desired precision."
            warnings.warn(message)
            nreps = None

        # Add solution to dictionary
        nreps_dict[metric] = nreps

        # Add metric name to table then append to list
        results["metric"] = metric
        summary_table_list.append(results)

    # Combine into a single table
    summary_frame = pd.concat(summary_table_list)

    return nreps_dict, summary_frame
