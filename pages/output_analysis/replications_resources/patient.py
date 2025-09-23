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
