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
    area_n_in_system : list of float
        List containing incremental area contributions used for
        time-weighted statistics of the number of patients in the system.
    time_last_n_in_system : float
        Simulation time at last update of the number-in-system statistic.
    n_in_system: int
        Current number of patients present in the system, including
        waiting and being served.
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
        self.doctor = MonitoredResource(
            self.env, capacity=self.param.number_of_doctors
        )

        # Create a random seed sequence based on the run number
        ss = np.random.SeedSequence(self.run_number)
        seeds = ss.spawn(2)

        # Set up attributes to store results
        self.patients = []
        self.results_list = []
        self.area_n_in_system = [0]
        self.time_last_n_in_system = self.env.now
        self.n_in_system = 0

        # Initialise distributions
        self.arrival_dist = Exponential(mean=self.param.interarrival_time,
                                        random_seed=seeds[0])
        self.consult_dist = Exponential(mean=self.param.consultation_time,
                                        random_seed=seeds[1])

    def update_n_in_system(self, inc):
        """
        Update the time-weighted statistics for number of patients in system.

        Parameters
        ----------
        inc : int
            Change in the number of patients (+1, 0, -1).
        """
        # Compute time since last event and calculate area under curve for that
        duration = self.env.now - self.time_last_n_in_system
        self.area_n_in_system.append(self.n_in_system * duration)
        # Update time and n in system
        self.time_last_n_in_system = self.env.now
        self.n_in_system += inc

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
                              period=period,
                              arrival_time=self.env.now)
            self.patients.append(patient)

            # Update the number in the system
            self.update_n_in_system(inc=1)

            # Print arrival time
            if self.param.verbose:
                print(f"{patient.period} Patient {patient.patient_id} " +
                      f"arrives at time: {patient.arrival_time:.3f}")

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
            patient.time_with_doctor = self.consult_dist.sample()
            yield self.env.timeout(patient.time_with_doctor)

            # Update number in system
            self.update_n_in_system(inc=-1)

            # Record end time
            patient.end_time = self.env.now
            if self.param.verbose:
                print(f"{patient.period} Patient {patient.patient_id} " +
                      f"leaves at: {patient.end_time:.3f}")

    def reset_results(self):
        """
        Reset results.
        """
        self.patients = []
        self.doctor.init_results()
        # For number in system, we reset area and time but not the count, as
        # it should include any remaining warm-up patients in the count
        self.area_n_in_system = [0]
        self.time_last_n_in_system = self.env.now

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

        # At simulation end, update time-weighted statistics by accounting
        # for the time from the last event up to the simulation finish.
        self.doctor.update_time_weighted_stats()

        # Run final calculation of number in system
        self.update_n_in_system(inc=0)

        # Create list of dictionaries containing each patient's attributes
        self.results_list = [x.__dict__ for x in self.patients]
