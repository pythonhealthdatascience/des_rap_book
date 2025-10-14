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
