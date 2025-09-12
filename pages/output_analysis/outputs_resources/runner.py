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
            "run_number": run
        }

        return {
            "patient": patient_results,
            "run": run_results
        }
