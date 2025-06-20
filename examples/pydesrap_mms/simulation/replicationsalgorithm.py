"""
ReplicationsAlgorithm.

Acknowledgements
----------------
This code is adapted from Tom Monks (2021) sim-tools: fundamental tools to
support the simulation process in python
(https://github.com/TomMonks/sim-tools) (MIT Licence). In sim-tools, they cite
that their implementation is of the "replications algorithm" from: Hoad,
Robinson, & Davies (2010). Automated selection of the number of replications
for a discrete-event simulation. Journal of the Operational Research Society.
https://www.jstor.org/stable/40926090.
"""

import warnings
import numpy as np
import pandas as pd

from .onlinestatistics import OnlineStatistics
from .replicationtabulizer import ReplicationTabulizer


class ReplicationsAlgorithm:
    """
    Implements an adaptive replication algorithm for selecting the
    appropriate number of simulation replications based on statistical
    precision.

    Attributes
    ----------
    alpha : float
        Significance level for confidence interval calculations.
    half_width_precision : float
        The target half width precision for the algorithm (i.e. percentage
        deviation of the confidence interval from the mean).
    initial_replications : int
        Number of initial replications to perform.
    look_ahead : int
        Minimum additional replications to look ahead to assess stability
        of precision. When the number of replications is <= 100, the value
        of look_ahead is used. When they are > 100, then
        look_ahead / 100 * max(n, 100) is used.
    replication_budget : int
        Maximum allowed replications.
    n : int
        Current number of replications performed.

    Notes
    -----
    Class adapted from Monks 2021.
    Implements algorithm from Hoad et al. 2010.
    """
    # pylint: disable=too-many-arguments,too-many-positional-arguments
    def __init__(
        self,
        alpha=0.05,
        half_width_precision=0.05,
        initial_replications=3,
        look_ahead=5,
        replication_budget=1000
    ):
        """
        Initialise an instance of the ReplicationsAlgorithm.

        Parameters
        ----------
        alpha : float, optional
            Significance level for confidence interval calculations.
        half_width_precision : float, optional
            The target half width precision for the algorithm.
        initial_replications : int, optional
            Number of initial replications to perform.
        look_ahead : int, optional
            Minimum additional replications to look ahead to assess stability.
        replication_budget : int, optional
            Maximum allowed replications.
        """
        self.alpha = alpha
        self.half_width_precision = half_width_precision
        self.initial_replications = initial_replications
        self.look_ahead = look_ahead
        self.replication_budget = replication_budget

        # Initially set n to number of initial replications
        self.n = self.initial_replications

        # Check validity of provided parameters
        self.valid_inputs()

    def valid_inputs(self):
        """
        Checks validity of provided parameters.
        """
        for param_name in ["initial_replications", "look_ahead"]:
            param_value = getattr(self, param_name)
            if not isinstance(param_value, int) or param_value < 0:
                raise ValueError(
                    f"{param_name} must be a non-negative integer, but ",
                    "provided {param_value}."
                )

        if self.half_width_precision <= 0:
            raise ValueError("half_width_precision must be greater than 0.")

        if self.replication_budget < self.initial_replications:
            raise ValueError(
                "replication_budget must be less than initial_replications."
            )

    def _klimit(self):
        """
        Determines the number of additional replications to check after
        precision is reached, scaling with total replications if they are
        greater than 100. Rounded down to nearest integer.

        Returns
        -------
        int
            Number of additional replications to verify stability.
        """
        return int((self.look_ahead / 100) * max(self.n, 100))

    def find_position(self, lst):
        """
        Find the first position where element is below deviation, and this is
        maintained through the lookahead period.

        This is used to correct the ReplicationsAlgorithm, which cannot return
        a solution below the initial_replications.

        Parameters
        ----------
        lst : list of float
            List of deviations.

        Returns
        -------
        int or None
            Minimum replications required to meet and maintain precision,
            or None if not found.
        """
        # Check if the list is empty or if no value is below the threshold
        if not lst or all(
            x is None or x >= self.half_width_precision for x in lst
        ):
            return None

        # Find the first non-None value in the list
        start_index = pd.Series(lst).first_valid_index()

        # Iterate through the list, stopping when at last point where we still
        # have enough elements to look ahead
        if start_index is not None:
            for i in range(start_index, len(lst) - self.look_ahead):
                # Create slice of list with current value + lookahead
                # Check if all fall below the desired deviation
                if all(
                    value < self.half_width_precision
                    for value in lst[i:i+self.look_ahead+1]
                ):
                    # Add one, so it is the number of reps, as is zero-indexed
                    return i + 1
        return None

    # pylint: disable=too-many-branches
    def select(self, runner, metrics):
        """
        Executes the replication algorithm, determining the necessary number
        of replications to achieve and maintain the desired precision.

        Parameters
        ----------
        runner : Runner
            An instance of Runner which executes the model replications.
        metrics : list
            List of performance measures to track.

        Returns
        -------
        tuple of (dict, pd.DataFrame)
            - A dictionary with the minimum number of replications required
              to meet the precision for each metric.
            - DataFrame containing cumulative statistics for each
              replication for each metric.

        Warnings
        --------
        Issues a warning if the desired precision is not met for any
        metrics before the replication limit is met.
        """
        # Create instances of observers for each metric
        observers = {metric: ReplicationTabulizer() for metric in metrics}

        # Create dictionary to store record for each metric of:
        # - nreps (the solution - replications required for precision)
        # - target_met (record of how many times in a row the target has
        #   has been met, used to check if lookahead period has been passed)
        # - solved (whether it has maintained precision for lookahead)
        solutions = {
            metric: {"nreps": None, "target_met": 0, "solved": False}
            for metric in metrics
        }
        # If there are no initial replications, create empty instances of stats
        # for each metric...
        if self.initial_replications == 0:
            stats = {
                metric: OnlineStatistics(
                    alpha=self.alpha, observer=observers[metric])
                for metric in metrics
            }
        # If there are, run the replications, then create instances of stats
        # pre-loaded with data from the initial replications...
        # (we use run_reps() which allows for parallel processing if desired)
        else:
            stats = {}
            runner.param.number_of_runs = self.initial_replications
            runner.run_reps()
            for metric in metrics:
                stats[metric] = OnlineStatistics(
                    alpha=self.alpha,
                    observer=observers[metric],
                    data=np.array(runner.run_results_df[metric])
                )

        # After completing all replications, check if any have met precision,
        # add solution and update count
        for metric in metrics:
            if stats[metric].deviation <= self.half_width_precision:
                solutions[metric]["nreps"] = self.n
                solutions[metric]["target_met"] = 1
                # If there is no lookahead, mark as solved
                if self._klimit() == 0:
                    solutions[metric]["solved"] = True

        # Whilst have not yet got all metrics marked as solved = TRUE, and
        # still under replication budget + lookahead...
        while (
            sum(1 for v in solutions.values() if v["solved"]) < len(metrics)
            and self.n < self.replication_budget + self._klimit()
        ):
            # Run another replication
            results = runner.run_single(self.n)["run"]
            # Increment counter
            self.n += 1

            # Loop through the metrics...
            for metric in metrics:

                # If it is not yet solved...
                if not solutions[metric]["solved"]:

                    # Update the running statistics for that metric
                    stats[metric].update(results[metric])

                    # If precision has been achieved...
                    if stats[metric].deviation <= self.half_width_precision:
                        # Check if target met the time prior - if not, record
                        # the solution.
                        if solutions[metric]["target_met"] == 0:
                            solutions[metric]["nreps"] = self.n
                        # Update how many times precision has been met in a row
                        solutions[metric]["target_met"] += 1
                        # Mark as solved if have finished lookahead period
                        if solutions[metric]["target_met"] > self._klimit():
                            solutions[metric]["solved"] = True
                    # If precision was not achieved, ensure nreps is None
                    # (e.g. in cases where precision is lost after a success)
                    else:
                        solutions[metric]["target_met"] = 0
                        solutions[metric]["nreps"] = None
        # Correction to result...
        for metric, dictionary in solutions.items():
            # Use find_position() to check for solution in initial replications
            adj_nreps = self.find_position(observers[metric].dev)
            # If there was a maintained solution, replace in solutions
            if adj_nreps is not None and dictionary["nreps"] is not None:
                if adj_nreps < dictionary["nreps"]:
                    solutions[metric]["nreps"] = adj_nreps
        # Extract minimum replications for each metric
        nreps = {metric: value["nreps"] for metric, value in solutions.items()}
        # Combine observer summary frames into a single table
        summary_frame = pd.concat(
            [observer.summary_table().assign(metric=metric)
             for metric, observer in observers.items()]
        ).reset_index(drop=True)

        # Extract any metrics that were not solved and return warning
        if None in nreps.values():
            unsolved = [k for k, v in nreps.items() if v is None]
            warnings.warn(
                "WARNING: the replications did not reach the desired " +
                f"precision for the following metrics: {unsolved}.")
        return nreps, summary_frame
