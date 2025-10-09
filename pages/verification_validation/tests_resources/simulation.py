import numpy as np
import pandas as pd
import simpy
from sim_tools.distributions import Exponential
import pytest


class Parameters:
    """
    Parameter class.

    Attributes
    ----------
    interarrival_time : float
        Mean time between arrivals (minutes).
    consultation_time : float
        Mean length of doctor's consultation (minutes).
    number_of_doctors : int
        Number of doctors.
    warm_up_period : int
        Duration of the warm-up period (minutes).
    data_collection_period : int
        Duration of the data collection period (minutes).
    number_of_runs : int#<<
        The number of runs (i.e., replications).#<<
    verbose : bool
        Whether to print messages as simulation runs.
    """
    def __init__(
        self, interarrival_time=5, consultation_time=10,
        number_of_doctors=3, warm_up_period=30, data_collection_period=40,
        number_of_runs=5, verbose=False#<<
    ):
        """
        Initialise Parameters instance.

        Parameters
        ----------
        interarrival_time : float
            Time between arrivals (minutes).
        consultation_time : float
            Length of consultation (minutes).
        number_of_doctors : int
            Number of doctors.
        warm_up_period : int
            Duration of the warm-up period (minutes).
        data_collection_period : int
            Duration of the data collection period (minutes).
        number_of_runs : int#<<
            The number of runs (i.e., replications).#<<
        verbose : bool
            Whether to print messages as simulation runs.
        """
        self.interarrival_time = interarrival_time
        self.consultation_time = consultation_time
        self.number_of_doctors = number_of_doctors
        self.warm_up_period = warm_up_period
        self.data_collection_period = data_collection_period
        self.number_of_runs = number_of_runs#<<
        self.verbose = verbose


class Patient:
    """
    Represents a patient.

    Attributes
    ----------
    patient_id : int
        Unique patient identifier.
    period : str
        Arrival period (warm up or data collection) with emoji.
    wait_time : float
        Time spent waiting for the doctor (minutes).
    """
    def __init__(self, patient_id, period):
        """
        Initialises a new patient.

        Parameters
        ----------
        patient_id : int
            Unique patient identifier.
        period : str
            Arrival period (warm up or data collection) with emoji.
        """
        self.patient_id = patient_id
        self.period = period
        self.wait_time = np.nan


class Model:
    """
    Simulation model.

    Attributes
    ----------
    param : Parameters
        Simulation parameters.
    run_number : int
        Run number for random seed generation.
    env : simpy.Environment
        The SimPy environment for the simulation.
    doctor : simpy.Resource
        SimPy resource representing doctors.
    patients : list
        List of Patient objects.
    results_list : list
        List of dictionaries with the attributes of each patient.
    arrival_dist : Exponential
        Distribution used to generate random patient inter-arrival times.
    consult_dist : Exponential
        Distribution used to generate length of a doctor's consultation.
    """
    def __init__(self, param, run_number):
        """
        Create a new Model instance.

        Parameters
        ----------
        param : Parameters
            Simulation parameters.
        run_number : int
            Run number for random seed generation.
        """
        self.param = param
        self.run_number = run_number

        # Create SimPy environment
        self.env = simpy.Environment()

        # Create resource
        self.doctor = simpy.Resource(
            self.env, capacity=self.param.number_of_doctors
        )

        # Create a random seed sequence based on the run number
        ss = np.random.SeedSequence(self.run_number)
        seeds = ss.spawn(2)

        # Set up attributes to store results
        self.patients = []
        self.results_list = []

        # Initialise distributions
        self.arrival_dist = Exponential(mean=self.param.interarrival_time,
                                        random_seed=seeds[0])
        self.consult_dist = Exponential(mean=self.param.consultation_time,
                                        random_seed=seeds[1])

    def generate_arrivals(self):
        """
        Process that generates patient arrivals.
        """
        while True:
            # Sample and pass time to next arrival
            sampled_iat = self.arrival_dist.sample()
            yield self.env.timeout(sampled_iat)

            # Check whether arrived during warm-up or data collection
            if self.env.now < self.param.warm_up_period:
                period = "\U0001F538 WU"
            else:
                period = "\U0001F539 DC"

            # Create a new patient
            patient = Patient(patient_id=len(self.patients)+1,
                              period=period)
            self.patients.append(patient)

            # Print arrival time
            if self.param.verbose:
                print(f"{patient.period} Patient {patient.patient_id} " +
                      f"arrives at time: {self.env.now:.3f}")

            # Start process of consultation
            self.env.process(self.consultation(patient))

    def consultation(self, patient):
        """
        Process that simulates a consultation.

        Parameters
        ----------
        patient :
            Instance of the Patient() class representing a single patient.
        """
        start_wait = self.env.now
        # Patient requests access to a doctor (resource)
        with self.doctor.request() as req:
            yield req

            # Record how long patient waited before consultation
            patient.wait_time = self.env.now - start_wait

            if self.param.verbose:
                print(f"{patient.period} Patient {patient.patient_id} " +
                      f"starts consultation at: {self.env.now:.3f}")

            # Sample consultation duration and pass time spent with doctor
            time_with_doctor = self.consult_dist.sample()
            yield self.env.timeout(time_with_doctor)

    def reset_results(self):
        """
        Reset results.
        """
        self.patients = []

    def warmup(self):
        """
        Reset result collection after the warm-up period.
        """
        if self.param.warm_up_period > 0:
            # Delay process until warm-up period has completed
            yield self.env.timeout(self.param.warm_up_period)
            # Reset results variables
            self.reset_results()
            if self.param.verbose:
                print(f"Warm up period ended at time: {self.env.now}")

    def run(self):
        """
        Run the simulation.
        """
        # Schedule arrival generator and warm-up
        self.env.process(self.generate_arrivals())
        self.env.process(self.warmup())

        # Run the simulation
        self.env.run(until=(self.param.warm_up_period +
                            self.param.data_collection_period))

        # Create list of dictionaries containing each patient's attributes
        self.results_list = [x.__dict__ for x in self.patients]


def summary_stats(data):
    """
    Calculate mean, standard deviation and 95% confidence interval (CI).

    Parameters
    ----------
    data : pd.Series
        Data to use in calculation.

    Returns
    -------
    tuple
        (mean, standard deviation, CI lower, CI upper).
    """
    # Remove any NaN from the series
    data = data.dropna()

    # Find number of observations
    count = len(data)

    # If there are no observations, then set all to NaN
    if count == 0:
        mean, std_dev, ci_lower, ci_upper = np.nan, np.nan, np.nan, np.nan
    # If there is only one or two observations, can do mean but not others
    elif count < 3:
        mean = data.mean()
        std_dev, ci_lower, ci_upper = np.nan, np.nan, np.nan
    # With more than one observation, can calculate all...
    else:
        mean = data.mean()
        std_dev = data.std()
        # Special case for CI if variance is 0
        if np.var(data) == 0:
            ci_lower, ci_upper = mean, mean
        else:
            # Calculation of CI uses t-distribution, which is suitable for
            # smaller sample sizes (n<30)
            ci_lower, ci_upper = st.t.interval(
                confidence=0.95,
                df=count-1,
                loc=mean,
                scale=st.sem(data))
    return mean, std_dev, ci_lower, ci_upper


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

    def run_reps(self): #<<
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
        for col in run_col[~run_col.isin(["run_number", "scenario"])]: #<<
            uncertainty_metrics[col] = dict(zip(#<<
                ["mean", "std_dev", "lower_95_ci", "upper_95_ci"], #<<
                summary_stats(run_results_df[col])#<<
            ))
        # Convert to dataframe#<<
        overall_results_df = pd.DataFrame(uncertainty_metrics)#<<

        return {#<<
            "patient": patient_results_df, #<<
            "run": run_results_df, #<<
            "overall": overall_results_df#<<
        }#<<
