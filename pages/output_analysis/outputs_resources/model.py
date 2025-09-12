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
    results_list : list#<<
        List of dictionaries with the attributes of each patient.#<<
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
        self.results_list = []#<<

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
        # Patient requests access to a doctor (resource)
        with self.doctor.request() as req:
            yield req

            if self.param.verbose:
                print(f"{patient.period} Patient {patient.patient_id} starts " +
                      f"consultation at: {self.env.now:.3f}")

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
        # Create list of dictionaries containing each patient's attributes#<<
        self.results_list = [x.__dict__ for x in self.patients]#<<
