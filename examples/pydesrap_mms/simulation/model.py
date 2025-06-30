"""
Model.

Acknowledgements
----------------
This code is adapted from Sammi Rosser and Dan Chalk (2024) HSMA - the
little book of DES (https://github.com/hsma-programme/hsma6_des_book)
(MIT Licence).
"""

import numpy as np
import simpy
from sim_tools.distributions import Exponential

from .monitoredresource import MonitoredResource
from .patient import Patient


# pylint: disable=too-many-instance-attributes
class Model:
    """
    Simulation model for a clinic.

    In this model, patients arrive at the clinic, wait for an available
    nurse, have a consultation with the nurse, and then leave.

    Attributes
    ----------
    param : Param
        Simulation parameters.
    run_number : int
        Run number for random seed generation.
    env : simpy.Environment
        The SimPy environment for the simulation.
    nurse : MonitoredResource
        Subclass of SimPy resource representing nurses (whilst monitoring
        the resource during the simulation run).
    patients : list
        List containing the generated patient objects.
    nurse_time_used : float
        Total time the nurse resources have been used in minutes.
    nurse_time_used_correction : float
        Correction for nurse time used with a warm-up period. Without
        correction, it will be underestimated, as patients who start their
        time with the nurse during the warm-up period and finish it during
        the data collection period will not be included in the recorded
        time.
    nurse_consult_count : int
        Count of patients seen by nurse, using to calculate running mean
        wait time.
    running_mean_nurse_wait : float
        Running mean wait time for nurse during simulation in minutes,
        calculated using Welford's Running Average.
    audit_list : list
        List to store metrics recorded at regular intervals.
    results_list : list
        List of dictionaries with the results for each patient (as defined
        by their patient object attributes).
    patient_inter_arrival_dist : Exponential
        Distribution for sampling patient inter-arrival times.
    nurse_consult_time_dist : Exponential
        Distribution for sampling nurse consultation times.

    Notes
    -----
    Class adapted from Rosser and Chalk 2024.
    """

    def __init__(self, param, run_number):
        """
        Initialise a new model.

        Parameters
        ----------
        param : Param
            Simulation parameters.
        run_number : int
            Run number for random seed generation.
        """
        # Set parameters and run number
        self.param = param
        self.run_number = run_number

        # Check validity of provided parameters
        self.valid_inputs()

        # Create simpy environment and resource
        self.env = simpy.Environment()
        self.nurse = MonitoredResource(
            self.env, capacity=self.param.number_of_nurses
        )

        # Initialise attributes to store results
        self.patients = []
        self.nurse_time_used = 0
        self.nurse_time_used_correction = 0
        self.nurse_consult_count = 0
        self.running_mean_nurse_wait = 0
        self.audit_list = []
        self.results_list = []

        # Generate seeds based on run_number as entropy (the "starter" seed)
        # The seeds produced will create independent streams
        ss = np.random.SeedSequence(entropy=self.run_number)
        seeds = ss.spawn(2)

        # Initialise distributions using those seeds
        self.patient_inter_arrival_dist = Exponential(
            mean=self.param.patient_inter, random_seed=seeds[0])
        self.nurse_consult_time_dist = Exponential(
            mean=self.param.mean_n_consult_time, random_seed=seeds[1])

        # Log model initialisation
        self.param.logger.log(sim_time=self.env.now, msg="Initialise model:\n")
        self.param.logger.log(vars(self))
        self.param.logger.log(sim_time=self.env.now, msg="Parameters:\n ")
        self.param.logger.log(vars(self.param))

    def valid_inputs(self):
        """
        Checks validity of provided parameters.
        """
        # Define validation rules for attributes
        # Doesn't include number_of_nurses as this is tested by simpy.Resource
        validation_rules = {
            "positive": [
                "patient_inter", "mean_n_consult_time", "number_of_runs",
                "audit_interval", "number_of_nurses"
            ],
            "non_negative": ["warm_up_period", "data_collection_period"]
        }
        # Iterate over the validation rules
        for rule, param_names in validation_rules.items():
            for param_name in param_names:
                # Get the value of the parameter by its name
                param_value = getattr(self.param, param_name)
                # Check if it meets the rules for that parameter
                if rule == "positive" and param_value <= 0:
                    raise ValueError(
                        f"Parameter '{param_name}' must be greater than 0.")
                if rule == "non_negative" and param_value < 0:
                    raise ValueError(
                        f"Parameter '{param_name}' must be greater than or " +
                        "equal to 0."
                    )

    def generate_patient_arrivals(self):
        """
        Generate patient arrivals.
        """
        while True:
            # Sample and pass time to arrival
            sampled_inter = self.patient_inter_arrival_dist.sample()
            yield self.env.timeout(sampled_inter)

            # Create new patient, with ID based on length of patient list + 1
            p = Patient(len(self.patients) + 1)
            p.arrival_time = self.env.now

            # Add the patient to the list.
            # The list stores a reference to the patient object, so any updates
            # to the patient attributes will be reflected in the list as well
            self.patients.append(p)

            # Log arrival time
            if p.arrival_time < self.param.warm_up_period:
                arrive_pre = "\U0001F538 WU"
            else:
                arrive_pre = "\U0001F539 DC"
            self.param.logger.log(
                sim_time=self.env.now,
                msg=(f"{arrive_pre} Patient {p.patient_id} arrives at: " +
                     f"{p.arrival_time:.3f}.")
            )

            # Start process of attending clinic
            self.env.process(self.attend_clinic(p))

    def attend_clinic(self, patient):
        """
        Simulates the patient's journey through the clinic.

        Parameters
        ----------
        patient : Patient
            Instance of the Patient() class representing a single patient.
        """
        # Start queueing and request nurse resource
        start_q_nurse = self.env.now
        with self.nurse.request() as req:
            yield req

            # Record time spent waiting
            patient.q_time_nurse = self.env.now - start_q_nurse

            # Update running mean of wait time for the nurse
            self.nurse_consult_count += 1
            self.running_mean_nurse_wait += (
                (patient.q_time_nurse - self.running_mean_nurse_wait) /
                self.nurse_consult_count
            )

            # Sample time spent with nurse
            patient.time_with_nurse = self.nurse_consult_time_dist.sample()

            # Log wait time and time spent with nurse
            if patient.arrival_time < self.param.warm_up_period:
                nurse_pre = "\U0001F536 WU"
            else:
                nurse_pre = "\U0001F537 DC"
            self.param.logger.log(
                sim_time=self.env.now,
                msg=(f"{nurse_pre} Patient {patient.patient_id} is seen by " +
                     f"nurse after {patient.q_time_nurse:.3f}. Consultation " +
                     f"length: {patient.time_with_nurse:.3f}.")
            )

            # Update the total nurse time used.
            # This is used to calculate utilisation. To avoid overestimation,
            # if the consultation would overrun the simulation, just record
            # time to end of the simulation.
            remaining_time = (
                self.param.warm_up_period +
                self.param.data_collection_period) - self.env.now
            self.nurse_time_used += min(
                patient.time_with_nurse, remaining_time)

            # If still in the warm-up period, find if the patient time with
            # nurse will go beyond end (if time_exceeding_warmup is positive) -
            # and, in which case, save that to nurse_time_used_correction
            # (ensuring to correct it if would exceed end of simulation).
            remaining_warmup = self.param.warm_up_period - self.env.now
            if remaining_warmup > 0:
                time_exceeding_warmup = (patient.time_with_nurse -
                                         remaining_warmup)
                if time_exceeding_warmup > 0:
                    self.nurse_time_used_correction += min(
                        time_exceeding_warmup,
                        self.param.data_collection_period)
                    # Logging message
                    self.param.logger.log(
                        sim_time=self.env.now,
                        msg=(f"\U0001F6E0 Patient {patient.patient_id} " +
                             "starts consultation with " +
                             f"{remaining_warmup:.3f} left of warm-up (which" +
                             f" is {self.param.warm_up_period:.3f}). " +
                             "As their consultation is for " +
                             f"{patient.time_with_nurse:.3f}, they will " +
                             f"exceed warmup by {time_exceeding_warmup:.3f}," +
                             "so we correct for this.")
                    )

            # Pass time spent with nurse
            yield self.env.timeout(patient.time_with_nurse)

    def interval_audit(self, interval):
        """
        Audit waiting times and resource utilisation at regular intervals.
        This is set-up to start when the warm-up period has ended.

        The running mean wait time is calculated using Welford's Running
        Average, which is a method that avoids the need to store previous wait
        times to compute the average. The running mean reflects the main wait
        time for all patients seen by nurse up to that point in the simulation.

        Parameters
        ----------
        interval : int
            Time between audits in minutes.
        """
        # Wait until warm-up period has passed
        yield self.env.timeout(self.param.warm_up_period)

        # Begin interval auditor
        while True:
            self.audit_list.append({
                "resource_name": "nurse",
                "simulation_time": self.env.now,
                "utilisation": self.nurse.count / self.nurse.capacity,
                "queue_length": len(self.nurse.queue),
                "running_mean_wait_time": self.running_mean_nurse_wait
            })

            # Trigger next audit after desired interval has passed
            yield self.env.timeout(interval)

    def init_results_variables(self):
        """
        Resets all results collection variables to their initial values.
        """
        self.patients = []
        self.nurse_time_used = 0
        self.audit_list = []
        self.nurse.init_results()

    def warm_up_complete(self):
        """
        If there is a warm-up period, then reset all results collection
        variables once warm-up period has passed.
        """
        if self.param.warm_up_period > 0:
            # Delay process until warm-up period has completed
            yield self.env.timeout(self.param.warm_up_period)

            # Reset results collection variables
            self.init_results_variables()

            # Correct nurse_time_used, adding the remaining time of patients
            # who were partway through their consultation during the warm-up
            # period (i.e. patients still in consultation as enter the
            # data collection period).
            self.nurse_time_used += self.nurse_time_used_correction

            # If there was a warm-up period, log that this time has passed so
            # can distinguish between patients before and after warm-up in logs
            self.param.logger.log(sim_time=self.env.now, msg="──────────")
            self.param.logger.log(
                sim_time=self.env.now, msg="Warm up complete."
            )
            self.param.logger.log(sim_time=self.env.now, msg="──────────")

    def run(self):
        """
        Runs the simulation for the specified duration.
        """
        # Calculate the total run length
        run_length = (self.param.warm_up_period +
                      self.param.data_collection_period)

        # Schedule process which will reset results when warm-up period ends
        # (or does nothing if there is no warm-up)
        self.env.process(self.warm_up_complete())

        # Schedule patient generator to run during simulation
        self.env.process(self.generate_patient_arrivals())

        # Schedule interval auditor to run during simulation
        self.env.process(
            self.interval_audit(interval=self.param.audit_interval))

        # Run the simulation
        self.env.run(until=run_length)

        # If the simulation ends while resources are still in use or requests
        # are still in the queue, the time between the last recorded event and
        # the simulation end will not have been accounted for. Hence, we call
        # update_time_weighted_stats() to run for last event --> end.
        self.nurse.update_time_weighted_stats()

        # Error handling - if there was no data collection period, the
        # simulation ends before it has a chance to reset the results,
        # so we do so manually
        if self.param.data_collection_period == 0:
            self.init_results_variables()

        # Convert list of patient objects into a list that just contains the
        # attributes of each of those patients as dictionaries
        self.results_list = [x.__dict__ for x in self.patients]
