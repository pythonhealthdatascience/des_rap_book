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

        # Run results
        run_results = {
            "run_number": run,
            "arrivals": len(patient_results),
            "mean_wait_time": patient_results["wait_time"].mean()
        }

        return {
            "patient": patient_results,
            "run": run_results
        }

    def run_reps(self):#<<
        """#<<
        Execute a single model configuration for multiple runs.#<<
        """#<<
        # Run replications#<<
        all_results = [self.run_single(run)#<<
                       for run in range(self.param.number_of_runs)]#<<

        # Separate results from each run into appropriate lists#<<
        patient_results_list = [result["patient"] for result in all_results]#<<
        run_results_list = [result["run"] for result in all_results]#<<

        # Convert lists into dataframes#<<
        patient_results_df = pd.concat(#<<
            patient_results_list, ignore_index=True#<<
        )#<<
        run_results_df = pd.DataFrame(run_results_list)#<<

        # Calculate average results and uncertainty from across all runs#<<
        uncertainty_metrics = {}#<<
        run_col = run_results_df.columns#<<

        # Loop through the run performance measure columns#<<
        # Calculate mean, standard deviation and 95% confidence interval#<<
        for col in run_col[~run_col.isin(["run_number", "scenario"])]:#<<
            uncertainty_metrics[col] = dict(zip(#<<
                ["mean", "std_dev", "lower_95_ci", "upper_95_ci"],#<<
                summary_stats(run_results_df[col])#<<
            ))
        # Convert to dataframe#<<
        overall_results_df = pd.DataFrame(uncertainty_metrics)#<<

        return {#<<
            "patient": patient_results_df,#<<
            "run": run_results_df,#<<
            "overall": overall_results_df#<<
        }#<<
