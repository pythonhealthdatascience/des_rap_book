class Patient:
    """
    Represents a patient.

    Attributes
    ----------
    patient_id : int
        Unique patient identifier.
    period : str
        Arrival period (warm up or data collection) with emoji.
    time_with_doctor : float#<<
        Time spent in consultation with a doctor (minutes).#<<
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
        self.time_with_doctor = np.nan#<<
