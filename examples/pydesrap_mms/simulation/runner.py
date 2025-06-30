"""
Runner.

Acknowledgements
----------------
This code is adapted from Sammi Rosser and Dan Chalk (2024) HSMA - the
little book of DES (https://github.com/hsma-programme/hsma6_des_book)
(MIT Licence).
"""

from joblib import Parallel, delayed, cpu_count
import pandas as pd
import numpy as np

from .model import Model
from .summary_stats import summary_stats


class Runner:
    """
    Run the simulation.

    Manages simulation runs, either running the model once or multiple times
    (replications).

    Attributes
    ----------
    param : Param
        Simulation parameters.
    patient_results_df : pandas.DataFrame
        DataFrame to store patient-level results.
    run_results_df : pandas.DataFrame
        DataFrame to store results from each run.
    interval_audit_df : pandas.DataFrame
        DataFrame to store interval audit results.
    overall_results_df : pandas.DataFrame
        DataFrame to store average results from across the runs.

    Notes
    -----
    Class adapted from Rosser and Chalk 2024.
    """

    def __init__(self, param):
        """
        Initialise a new instance of the Runner class.

        Parameters
        ----------
        param : Param
            Simulation parameters.
        """
        # Store model parameters
        self.param = param
        # Initialise empty dataframes to store results
        self.patient_results_df = pd.DataFrame()
        self.run_results_df = pd.DataFrame()
        self.interval_audit_df = pd.DataFrame()
        self.overall_results_df = pd.DataFrame()

    def run_single(self, run):
        """
        Executes a single simulation run and records the results.

        Parameters
        ----------
        run : int
            The run number for the simulation.

        Returns
        -------
        dict
            A dictionary containing the patient-level results, results from
            each run, and interval audit results.
        """
        # Run model
        model = Model(param=self.param, run_number=run)
        model.run()

        # PATIENT RESULTS
        # Convert patient-level results to a dataframe and add column with run
        patient_results = pd.DataFrame(model.results_list)
        patient_results["run"] = run
        # If there was at least one patient...
        if len(patient_results) > 0:
            # Add a column with the wait time of patients who remained unseen
            # at the end of the simulation
            patient_results["q_time_unseen_nurse"] = np.where(
                patient_results["time_with_nurse"].isna(),
                model.env.now - patient_results["arrival_time"], np.nan
            )
        else:
            # Set to NaN if no patients
            patient_results["q_time_unseen_nurse"] = np.nan

        # RUN RESULTS
        # The run, scenario and arrivals are handled the same regardless of
        # whether there were any patients
        run_results = {
            "run_number": run,
            "scenario": self.param.scenario_name,
            "arrivals": len(patient_results)
        }
        # If there was at least one patient...
        if len(patient_results) > 0:
            # Create dictionary recording the run results
            # Currently has two alternative methods of measuring utilisation
            run_results = {
                **run_results,
                "mean_q_time_nurse": patient_results["q_time_nurse"].mean(),
                "mean_time_with_nurse": (
                    patient_results["time_with_nurse"].mean()
                ),
                "mean_nurse_utilisation": (
                    model.nurse_time_used / (
                        self.param.number_of_nurses *
                        self.param.data_collection_period
                    )
                ),
                "mean_nurse_utilisation_tw": (
                    sum(model.nurse.area_resource_busy) / (
                        self.param.number_of_nurses *
                        self.param.data_collection_period
                    )
                ),
                "mean_nurse_q_length": (
                    sum(model.nurse.area_n_in_queue) /
                    self.param.data_collection_period
                ),
                "count_nurse_unseen": (
                    patient_results["time_with_nurse"].isna().sum()
                ),
                "mean_q_time_nurse_unseen": (
                    patient_results["q_time_unseen_nurse"].mean()
                )
            }
        else:
            # Set results to NaN if no patients
            run_results = {
                **run_results,
                "mean_q_time_nurse": np.nan,
                "mean_time_with_nurse": np.nan,
                "mean_nurse_utilisation": np.nan,
                "mean_nurse_utilisation_tw": np.nan,
                "mean_nurse_q_length": np.nan,
                "count_nurse_unseen": np.nan,
                "mean_q_time_nurse_unseen": np.nan
            }

        # INTERVAL AUDIT RESULTS
        # Convert interval audit results to a dataframe and add run column
        interval_audit_df = pd.DataFrame(model.audit_list)
        interval_audit_df["run"] = run

        return {
            "patient": patient_results,
            "run": run_results,
            "interval_audit": interval_audit_df
        }

    def run_reps(self):
        """
        Execute a single model configuration for multiple runs/replications.

        These can be run sequentially or in parallel.
        """
        # Sequential execution
        if self.param.cores == 1:
            all_results = [self.run_single(run)
                           for run in range(self.param.number_of_runs)]
        # Parallel execution
        else:

            # Check number of cores is valid - must be -1, or between 1 and
            # total CPUs-1 (saving one for logic control).
            # Done here rather than in model as this is called before model,
            # and only relevant for Runner.
            valid_cores = [-1] + list(range(1, cpu_count()))
            if self.param.cores not in valid_cores:
                raise ValueError(
                    f"Invalid cores: {self.param.cores}. Must be one of: " +
                    f"{valid_cores}."
                )
            # Warn users that logging will not run as it is in parallel
            if (
                self.param.logger.log_to_console or
                self.param.logger.log_to_file
            ):
                self.param.logger.log(
                    "WARNING: Logging is disabled in parallel " +
                    "(multiprocessing mode). Simulation log will not appear." +
                    " If you wish to generate logs, switch to `cores=1`, or " +
                    "just run one replication with `run_single()`."
                )
            # Execute replications
            all_results = Parallel(n_jobs=self.param.cores)(
                delayed(self.run_single)(run)
                for run in range(self.param.number_of_runs)
            )

        # Seperate results from each run into appropriate lists
        patient_results_list = [result["patient"] for result in all_results]
        run_results_list = [result["run"] for result in all_results]
        interval_audit_list = [
            result["interval_audit"] for result in all_results
        ]

        # Convert lists into dataframes
        self.patient_results_df = pd.concat(
            patient_results_list, ignore_index=True
        )
        self.run_results_df = pd.DataFrame(run_results_list)
        self.interval_audit_df = pd.concat(
            interval_audit_list, ignore_index=True
        )

        # Calculate average results and uncertainty from across all runs
        uncertainty_metrics = {}
        run_col = self.run_results_df.columns

        # Loop through the run performance measure columns
        # Calculate mean, standard deviation and 95% confidence interval
        for col in run_col[~run_col.isin(["run_number", "scenario"])]:
            uncertainty_metrics[col] = dict(zip(
                ["mean", "std_dev", "lower_95_ci", "upper_95_ci"],
                summary_stats(self.run_results_df[col])
            ))
        # Convert to dataframe
        self.overall_results_df = pd.DataFrame(uncertainty_metrics)
