"""
Patient.

Acknowledgements
----------------
This code is adapted from Sammi Rosser and Dan Chalk (2024) HSMA - the
little book of DES (https://github.com/hsma-programme/hsma6_des_book)
(MIT Licence).
"""

import numpy as np


# pylint: disable=too-few-public-methods
class Patient:
    """
    Represents a patient.

    Attributes
    ----------
    patient_id : int|float|str
        Patient's unique identifier.
    arrival_time : float
        Arrival time for the patient in minutes.
    q_time_nurse : float
        Time the patient spent waiting for a nurse in minutes.
    time_with_nurse : float
        Time spent in consultation with a nurse in minutes.

    Notes
    -----
    Class adapted from Rosser and Chalk 2024.
    """

    def __init__(self, patient_id):
        """
        Initialises a new patient.

        Parameters
        ----------
        patient_id : int|float|str
            Patient's unique identifier.
        """
        self.patient_id = patient_id
        self.arrival_time = np.nan
        self.q_time_nurse = np.nan
        self.time_with_nurse = np.nan
