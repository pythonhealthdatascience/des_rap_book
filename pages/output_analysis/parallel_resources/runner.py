class Runner:
    """
    Run the simulation.

    Attributes
    ----------
    param : Parameters
        Simulation parameters.
    """
    def __init__(self, param):
        """
        Initialise a new instance of the Runner class.

        Parameters
        ----------
        param : Parameters
            Simulation parameters.
        """
        self.param = param

    def run_single(self, run):
        """
        Runs the simulation once and performs results calculations.

        Parameters
        ----------
        run : int
            Run number for the simulation.

        Returns
        -------
        dict
            Contains patient-level results and results from each run.
        """
        model = Model(param=self.param, run_number=run)
        model.run()

        # Patient results
        patient_results = pd.DataFrame(model.results_list)
        patient_results["run"] = run
        patient_results["time_in_system"] = (
            patient_results["end_time"] - patient_results["arrival_time"]
        )
        # For each patient, if they haven't seen a doctor yet, calculate
        # their wait as current time minus arrival, else set as missing
        patient_results["unseen_wait_time"] = np.where(
            patient_results["time_with_doctor"].isna(),
            model.env.now - patient_results["arrival_time"], np.nan
        )

        # Run results
        run_results = {
            "run_number": run,
            "arrivals": len(patient_results),
            "mean_wait_time": patient_results["wait_time"].mean(),
            "mean_time_with_doctor": (
                patient_results["time_with_doctor"].mean()
            ),
            "mean_utilisation_tw": (
                sum(model.doctor.area_resource_busy) / (
                    self.param.number_of_doctors *
                    self.param.data_collection_period
                )
            ),
            "mean_queue_length": (
                sum(model.doctor.area_n_in_queue) /
                self.param.data_collection_period
            ),
            "mean_time_in_system": patient_results["time_in_system"].mean(),
            "mean_patients_in_system": (
                sum(model.area_n_in_system) /
                self.param.data_collection_period
            ),
            "unseen_count": patient_results["time_with_doctor"].isna().sum(),
            "unseen_wait_time": patient_results["unseen_wait_time"].mean()
        }

        return {
            "patient": patient_results,
            "run": run_results
        }

    def run_reps(self):
        """
        Execute a single model configuration for multiple runs.

        Returns
        -------
        dict
            Contains patient-level results, results from each run and
            overall results.
        """
        # Sequential execution#<<
        if self.param.cores == 1:#<<
            all_results = [self.run_single(run)
                           for run in range(self.param.number_of_runs)]
        # Parallel execution#<<
        else:#<<
            # Check number of cores is valid#<<
            valid_cores = [-1] + list(range(1, cpu_count()))#<<
            if self.param.cores not in valid_cores:#<<
                raise ValueError(#<<
                    f"Invalid cores: {self.param.cores}. Must be one of: " +#<<
                    f"{valid_cores}."#<<
                )#<<
            # Execute replications#<<
            all_results = Parallel(n_jobs=self.param.cores)(#<<
                delayed(self.run_single)(run)#<<
                for run in range(self.param.number_of_runs)#<<
            )#<<

        # Separate results from each run into appropriate lists
        patient_results_list = [result["patient"] for result in all_results]
        run_results_list = [result["run"] for result in all_results]

        # Convert lists into dataframes
        patient_results_df = pd.concat(
            patient_results_list, ignore_index=True
        )
        run_results_df = pd.DataFrame(run_results_list)

        # Calculate average results and uncertainty from across all runs
        uncertainty_metrics = {}
        run_col = run_results_df.columns

        # Loop through the run performance measure columns
        # Calculate mean, standard deviation and 95% confidence interval
        for col in run_col[~run_col.isin(["run_number", "scenario"])]:
            uncertainty_metrics[col] = dict(zip(
                ["mean", "std_dev", "lower_95_ci", "upper_95_ci"],
                summary_stats(run_results_df[col])
            ))
        # Convert to dataframe
        overall_results_df = pd.DataFrame(uncertainty_metrics)

        return {
            "patient": patient_results_df,
            "run": run_results_df,
            "overall": overall_results_df
        }
