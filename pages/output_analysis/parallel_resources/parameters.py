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
    number_of_runs : int
        The number of runs (i.e., replications).
    cores : int#<<
        Number of CPU cores to use for parallel execution. For all#<<
        available cores, set to -1. For sequential execution, set to 1.#<<
    verbose : bool
        Whether to print messages as simulation runs.
    """
    def __init__(
        self, interarrival_time=5, consultation_time=10, number_of_doctors=3,
        warm_up_period=30, data_collection_period=40,
        number_of_runs=18, cores=1, verbose=False#<<
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
        number_of_runs : int
            The number of runs (i.e., replications).
        cores : int#<<
            Number of CPU cores to use for parallel execution. For all#<<
            available cores, set to -1. For sequential execution, set to 1.#<<
        verbose : bool
            Whether to print messages as simulation runs.
        """
        self.interarrival_time = interarrival_time
        self.consultation_time = consultation_time
        self.number_of_doctors = number_of_doctors
        self.warm_up_period = warm_up_period
        self.data_collection_period = data_collection_period
        self.number_of_runs = number_of_runs
        self.cores = cores#<<
        self.verbose = verbose
