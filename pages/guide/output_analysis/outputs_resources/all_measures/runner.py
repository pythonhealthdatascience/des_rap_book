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
        patient_results["time_in_system"] = (#<<
            patient_results["end_time"] - patient_results["arrival_time"]#<<
        )#<<
        # For each patient, if they haven't seen a doctor yet, calculate#<<
        # their wait as current time minus arrival, else set as missing#<<
        patient_results["unseen_wait_time"] = np.where(#<<
            patient_results["time_with_doctor"].isna(),#<<
            model.env.now - patient_results["arrival_time"], np.nan#<<
        )

        # Run results
        run_results = {
            "run_number": run,
            "arrivals": len(patient_results),#<<
            "mean_wait_time": patient_results["wait_time"].mean(),#<<
            "mean_time_with_doctor": (#<<
                patient_results["time_with_doctor"].mean()#<<
            ),#<<
            "mean_utilisation_tw": (#<<
                sum(model.doctor.area_resource_busy) / (#<<
                    self.param.number_of_doctors *#<<
                    self.param.data_collection_period#<<
                )#<<
            ),#<<
            "mean_queue_length": (#<<
                sum(model.doctor.area_n_in_queue) /#<<
                self.param.data_collection_period#<<
            ),#<<
            "mean_time_in_system": patient_results["time_in_system"].mean(),#<<
            "mean_patients_in_system": (#<<
                sum(model.area_n_in_system) /#<<
                self.param.data_collection_period#<<
            ),#<<
            "unseen_count": patient_results["time_with_doctor"].isna().sum(),#<<
            "unseen_wait_time": patient_results["unseen_wait_time"].mean()#<<
        }#<<

        return {
            "patient": patient_results,
            "run": run_results
        }
