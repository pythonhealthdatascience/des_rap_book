"""
ReplicationTabulizer.

Acknowledgements
----------------
This code is adapted from Tom Monks (2021) sim-tools: fundamental tools to
support the simulation process in python
(https://github.com/TomMonks/sim-tools) (MIT Licence).
"""

import numpy as np
import pandas as pd


class ReplicationTabulizer:
    """
    Observes and records results from OnlineStatistics, updating each time new
    data is processed.

    Attributes
    ----------
    n : int
        Number of data points processed.
    x_i : list
        List containing each data point.
    cumulative_mean : list
        List of the running mean.
    stdev : list
        List of the standard deviation.
    lower : list
        List of the lower confidence interval bound.
    upper : list
        List of the upper confidence interval bound.
    dev : list
        List of the percentage deviation of the confidence interval
        half width from the mean.

    Notes
    -----
    Class adapted from Monks 2021.
    """

    def __init__(self):
        """
        Initialises empty lists for storing statistics, and n is set to zero.
        """
        self.n = 0
        self.x_i = []
        self.cumulative_mean = []
        self.stdev = []
        self.lower = []
        self.upper = []
        self.dev = []

    def update(self, results):
        """
        Add new results from OnlineStatistics to the appropriate lists.

        Parameters
        ----------
        results : OnlineStatistics
            An instance of OnlineStatistics containing updated statistical
            measures like the mean, standard deviation and confidence
            intervals.
        """
        self.x_i.append(results.x_i)
        self.cumulative_mean.append(results.mean)
        self.stdev.append(results.std)
        self.lower.append(results.lci)
        self.upper.append(results.uci)
        self.dev.append(results.deviation)
        self.n += 1

    def summary_table(self):
        """
        Create a results table from the stored lists.

        Returns
        -------
        pd.DataFrame
            Dataframe summarising the replication statistics.
        """
        results = pd.DataFrame({
            "replications": np.arange(1, self.n + 1),
            "data": self.x_i,
            "cumulative_mean": self.cumulative_mean,
            "stdev": self.stdev,
            "lower_ci": self.lower,
            "upper_ci": self.upper,
            "deviation": self.dev
        })
        return results
