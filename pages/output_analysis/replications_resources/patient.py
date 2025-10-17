class Patient:
    """
    Represents a patient.

    Attributes
    ----------
    patient_id : int
        Unique patient identifier.
    period : str
        Arrival period (warm up or data collection) with emoji.
    arrival_time : float
        Time patient entered the system (minutes).
    wait_time : float
        Time spent waiting for the doctor (minutes).
    time_with_doctor : float
        Time spent in consultation with a doctor (minutes).
    end_time : float
        Time that patient leaves (minutes), or NaN if remain in system.
    """
    def __init__(self, patient_id, period, arrival_time):
        """
        Initialises a new patient.

        Parameters
        ----------
        patient_id : int
            Unique patient identifier.
        period : str
            Arrival period (warm up or data collection) with emoji.
        arrival_time : float
            Time patient entered the system (minutes).
        """
        self.patient_id = patient_id
        self.period = period
        self.arrival_time = arrival_time
        self.wait_time = np.nan
        self.time_with_doctor = np.nan
        self.end_time = np.nan
