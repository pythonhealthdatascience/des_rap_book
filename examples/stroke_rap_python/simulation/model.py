"""
Code for the simulation.
"""

import numpy as np
import simpy
from sim_tools.distributions import Exponential, Discrete, Lognormal


class Patient:
    """
    Represents a patient.

    Attributes
    ----------
    patient_id: int, float or str
        Unique patient identifier.
    patient_type: str
        Patient type ("stroke", "tia", "neuro" or "other").
    asu_arrival_time: float
        Arrival time at the acute stroke unit (ASU) in days.
    post_asu_destination: str
        Destination after the ASU ("rehab", "esd", "other").
    asu_los: float
        Length of stay on the ASU in days.
    rehab_arrival_time: float
        Arrival time at the rehabilitation unit in days.
    post_rehab_destination: str
        Destination after rehab ("esd", "other").
    rehab_los: float
        Length of stay on the rehabilitation unit in days.
    """
    def __init__(self, patient_id, patient_type):
        """
        Parameters
        ----------
        patient_id: int, float or str
            Unique patient identifier.
        patient_type: str
            Patient type ("stroke", "tia", "neuro" or "other").
        """
        self.patient_id = patient_id
        self.patient_type = patient_type
        self.asu_arrival_time = np.nan
        self.post_asu_destination = np.nan
        self.asu_los = np.nan
        self.rehab_arrival_time = np.nan
        self.post_rehab_destination = np.nan
        self.rehab_los = np.nan


class Model:
    """
    Simulation model.

    Attributes
    ----------
    param: Param
        Run parameters.
    run_number: int
        Replication / run number.
    audit_interval: float
        Frequency of simulation audits in days.
    env: simpy.Environment
        Simulation environment.
    patients: list
        Stores the Patient objects.
    asu_occupancy: int
        Number of patients currently in the acute stroke unit (ASU).
    rehab_occupancy: int
        Number of patients currently in the rehabilitation unit.
    audit_list: list
        List to store metrics recorded at regular intervals.
    seed_generator: iterator
        An iterator that yields independent random seeds when iterated over.
    arrival_dist: dictionary
        The arrival sampling distributions by unit and patient type.
    routing_dist: dictionary
        The routing sampling distributions by unit and patient type.
    los_dist: dictionary
        The length of stay (LOS) sampling distributions by unit and patient
        type.
    """
    def __init__(self, param, run_number):
        """
        Parameters
        ----------
        param: Param
            Run parameters.
        run_number: int
            Replication / run number.
        """
        # Check parameter validity
        param.check_param_validity()

        # Set parameters
        self.param = param
        self.run_number = run_number
        self.audit_interval = self.param.audit_interval

        # Create SimPy environment
        self.env = simpy.Environment()

        # Create attributes to store results
        # The patients list will store a reference to the patient objects, so
        # any updates to the patient attributes after they are saved to the
        # list, will be reflected in the list as well
        self.patients = []
        self.asu_occupancy = 0
        self.rehab_occupancy = 0
        self.audit_list = []

        # Create seeds, spawning enough for all the sampling distributions
        ss = np.random.SeedSequence(entropy=self.run_number)
        self.seed_generator = iter(ss.spawn(30))

        # Create arrival sampling distributions
        self.arrival_dist = self.create_distributions(
            asu_param=self.param.asu_arrivals,
            rehab_param=self.param.rehab_arrivals,
            distribution_type="exponential")

        # Create routing sampling distributions
        self.routing_dist = self.create_distributions(
            asu_param=self.param.asu_routing,
            rehab_param=self.param.rehab_routing,
            distribution_type="discrete")

        # Create length of stay (LOS) sampling distributions
        self.los_dist = self.create_distributions(
            asu_param=self.param.asu_los,
            rehab_param=self.param.rehab_los,
            distribution_type="lognormal")

    def create_distributions(self, asu_param, rehab_param, distribution_type):
        """
        Create a nested dictionary with two items: "asu" and "rehab". Each
        then contains a set of distributions by patient type.

        Parameters
        ----------
        asu_param: Class
            Acute stroke unit (ASU) parameters.
        rehab_param: Class
            Rehabilitation unit parameters.
        distribution_type: str
            Name of the distribution to use ("exponential", "discrete",
            "lognormal").

        Returns
        -------
        distributions: dictionary
            Dictionary with "asu" and "rehab", which each then contains a
            dictionary of sampling distributions by patient type.
        """
        # Create dictionary to store distributions
        distributions = {}

        # Loop through each unit
        for unit, unit_param in [("asu", asu_param), ("rehab", rehab_param)]:

            # Make sub-dictionary to store that unit's distributions
            distributions[unit] = {}

            # Get a list of the patients in that unit (ignore other attributes)
            patient_types = [attr for attr in dir(unit_param) if attr in
                             ["stroke", "stroke_esd", "stroke_noesd",
                              "stroke_mortality", "tia", "neuro", "other"]]

            # For each patient type...
            for patient_type in patient_types:

                # Get the entry for that patient
                patient_param = getattr(unit_param, patient_type)

                # Create distributions of specified type
                if distribution_type == "exponential":
                    distributions[unit][patient_type] = Exponential(
                        mean=patient_param,
                        random_seed=next(self.seed_generator)
                    )
                elif distribution_type == "discrete":
                    distributions[unit][patient_type] = Discrete(
                        values=list(patient_param.keys()),
                        freq=list(patient_param.values()),
                        random_seed=next(self.seed_generator)
                    )
                elif distribution_type == "lognormal":
                    distributions[unit][patient_type] = Lognormal(
                        mean=patient_param["mean"],
                        stdev=patient_param["sd"],
                        random_seed=next(self.seed_generator)
                    )
        return distributions

    def patient_generator(self, patient_type, unit):
        """
        Generic patient generator for any patient type and unit.

        Parameters
        ----------
        patient_type: str
            Type of patient ("stroke", "tia", "neuro", "other").
        unit: str
            The unit the patient is arriving at ("asu", "rehab").
        """
        while True:
            # Sample and pass time to arrival
            sampled_iat = self.arrival_dist[unit][patient_type].sample()
            yield self.env.timeout(sampled_iat)

            # Create a new patient and add to the patients list
            patient = Patient(patient_id=len(self.patients)+1,
                              patient_type=patient_type)
            self.patients.append(patient)

            # Record the arrival time, and then start the process for
            # the acute stroke unit or rehab unit
            if unit == "asu":
                patient.asu_arrival_time = self.env.now
                self.env.process(self.acute_stroke_unit(patient))
            elif unit == "rehab":
                patient.rehab_arrival_time = self.env.now
                self.env.process(self.rehab_unit(patient))

    def acute_stroke_unit(self, patient):
        """
        Represents patient stay in the acute stroke unit (ASU) - samples their
        (1) destination after the ASU, and (2) length of stay (LOS) on the ASU.

        Parameters
        ----------
        patient: Patient
            Patient.
        """
        # Add to occupancy count
        self.asu_occupancy += 1

        # Log the arrival time
        self.param.logger.log(
            sim_time=patient.asu_arrival_time,
            msg=(f"Patient {patient.patient_id} ({patient.patient_type}) " +
                 "arrive at ASU."))

        # Sample destination after ASU (we do this immediately on arrival
        # in the ASU, as the destination influences the length of stay)
        patient.post_asu_destination = (
            self.routing_dist["asu"][patient.patient_type].sample())

        # Log the post-ASU destination
        self.param.logger.log(
            sim_time=self.env.now,
            msg=(f"Patient {patient.patient_id} ({patient.patient_type}) " +
                 f"post-ASU: {patient.post_asu_destination}"))

        # If it is a stroke patient, find out if they are going to the ESD
        # (stroke_esd) or not (stroke_noesd) or if they pass away
        # (stroke_mortality). For other patients, just same as patient_type.
        if patient.patient_type == "stroke":
            if patient.post_asu_destination == "esd":
                routing_type = "stroke_esd"
            elif patient.post_asu_destination == "rehab":
                routing_type = "stroke_noesd"
            elif patient.post_asu_destination == "other":
                routing_type = "stroke_mortality"
            else:
                raise ValueError("Stroke post-asu destination '" +
                                 f"{patient.post_asu_destination}' invalid")
        else:
            routing_type = patient.patient_type

        # Sample LOS on the ASU, log it and pass time
        patient.asu_los = self.los_dist["asu"][routing_type].sample()
        self.param.logger.log(
            sim_time=self.env.now,
            msg=(f"Patient {patient.patient_id} ({patient.patient_type}) " +
                 f"LOS on ASU: {patient.asu_los:.3f}"))
        yield self.env.timeout(patient.asu_los)

        # If patient is going to rehab next, record arrival time and start that
        # process
        if patient.post_asu_destination == "rehab":
            patient.rehab_arrival_time = self.env.now
            self.env.process(self.rehab_unit(patient))

        # Remove from occupancy count
        self.asu_occupancy -= 1

    def rehab_unit(self, patient):
        """
        Represents patient stay on the rehabilitation unit - samples their
        (1) destination after rehab, and (2) length of stay (LOS) on the unit.
        """
        # Add to occupancy count
        self.rehab_occupancy += 1

        # Log the arrival time
        self.param.logger.log(
            sim_time=patient.rehab_arrival_time,
            msg=(f"Patient {patient.patient_id} ({patient.patient_type}) " +
                 "arrive at rehab."))

        # Sample destination after rehab
        patient.post_rehab_destination = (
            self.routing_dist["rehab"][patient.patient_type].sample())

        # Log the post-rehab destination
        self.param.logger.log(
            sim_time=self.env.now,
            msg=(f"Patient {patient.patient_id} ({patient.patient_type}) " +
                 f"post-rehab: {patient.post_rehab_destination}"))

        # If it is a stroke patient,find out if they are going to the ESD
        # (stroke_esd) or not (stroke_noesd) - else, just same as patient_type
        if patient.patient_type == "stroke":
            if patient.post_rehab_destination == "esd":
                routing_type = "stroke_esd"
            else:
                routing_type = "stroke_noesd"
        else:
            routing_type = patient.patient_type

        # Sample LOS on the rehab unit, log it and pass time
        patient.rehab_los = self.los_dist["rehab"][routing_type].sample()
        self.param.logger.log(
            sim_time=self.env.now,
            msg=(f"Patient {patient.patient_id} ({patient.patient_type}) " +
                 f"LOS on rehab unit: {patient.rehab_los:.3f}"))
        yield self.env.timeout(patient.rehab_los)

        # Remove from occupancy count
        self.rehab_occupancy -= 1

    def interval_audit(self, interval):
        """
        Audit occupancy at regular intervals.

        Parameters
        ----------
        interval: float
            Time between audits in days.
        """
        while True:
            # Record current status of the simulation
            self.audit_list.append({
                "time": self.env.now,
                "asu_occupancy": self.asu_occupancy,
                "rehab_occupancy": self.rehab_occupancy
            })
            # Trigger next audit after desired interval has passed
            yield self.env.timeout(interval)

    def reset_results(self):
        """
        Resets results collection variables to their initial values. Used by
        warm_up(), and for correction to results in run().
        """
        self.patients = []
        self.audit_list = []

    def warm_up(self):
        """
        If there is a warm-up period, then reset all results collection
        variables once warm-up period has passed.
        """
        if self.param.warm_up_period > 0:
            # Delay process until warm-up period has completed
            yield self.env.timeout(self.param.warm_up_period)
            # Reset results variables
            self.reset_results()
            # Log that warm-up period has ended
            if self.param.warm_up_period > 0:
                self.param.logger.log(sim_time=self.env.now,
                                      msg='─' * 10)
                self.param.logger.log(sim_time=self.env.now,
                                      msg='Warm up complete.')
                self.param.logger.log(sim_time=self.env.now,
                                      msg='─' * 10)

    def run(self):
        """
        Run the simulation.
        """
        # Add model initialisation details to the log
        self.param.logger.log(sim_time=self.env.now, msg="Initialise model:\n")
        self.param.logger.log(vars(self))
        self.param.logger.log(msg="Parameters:\n ")
        self.param.logger.log(vars(self.param))
        self.param.logger.log(msg="Logger:\n ")
        self.param.logger.log(vars(self.param.logger))
        self.param.logger.log(msg="ASU arrivals:\n ")
        self.param.logger.log(vars(self.param.asu_arrivals))
        self.param.logger.log(msg="ASU LOS:\n ")
        self.param.logger.log(vars(self.param.asu_los))
        self.param.logger.log(msg="ASU routing:\n ")
        self.param.logger.log(vars(self.param.asu_routing))
        self.param.logger.log(msg="Rehab arrivals:\n ")
        self.param.logger.log(vars(self.param.rehab_arrivals))
        self.param.logger.log(msg="Rehab LOS:\n ")
        self.param.logger.log(vars(self.param.rehab_los))
        self.param.logger.log(msg="Rehab routing:\n ")
        self.param.logger.log(vars(self.param.rehab_routing))

        # Calculate the total run length
        run_length = (self.param.warm_up_period +
                      self.param.data_collection_period)

        # Schedule patient generators to run during the simulation
        # For each unit...
        for unit, patient_types in self.arrival_dist.items():
            # For each patient...
            for patient_type, _ in patient_types.items():
                self.env.process(
                    self.patient_generator(
                        patient_type=patient_type,
                        unit=unit
                    )
                )

        # Schedule the interval auditor to run during the simulation
        self.env.process(
            self.interval_audit(interval=self.param.audit_interval))

        # Schedule process which will reset results when warm-up period ends
        self.env.process(self.warm_up())

        # Run the simulation
        self.env.run(until=run_length)

        # Error handling - if there was no data collection period, the
        # simulation ends before it has a chance to reset the results,
        # so we do so manually
        if self.param.data_collection_period == 0:
            self.reset_results()
