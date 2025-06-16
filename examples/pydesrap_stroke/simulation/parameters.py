"""
Stroke pathway simulation parameters.

It includes arrival rates, length of stay distributions, and routing
probabilities between different care settings.
"""

import time

from simulation.logging import SimLogger


class RestrictAttributesMeta(type):
    """
    Metaclass for attribute restriction.

    A metaclass modifies class construction. It intercepts instance creation
    via __call__, adding the _initialised flag after __init__ completes. This
    is later used by RestrictAttributes to enforce attribute restrictions.
    """
    def __call__(cls, *args, **kwargs):
        # Create instance using the standard method
        instance = super().__call__(*args, **kwargs)
        # Set the "_initialised" flag to True, marking end of initialisation
        instance.__dict__["_initialised"] = True
        return instance


class RestrictAttributes(metaclass=RestrictAttributesMeta):
    """
    Base class that prevents the addition of new attributes after
    initialisation.

    This class uses RestrictAttributesMeta as its metaclass to implement
    attribute restriction. It allows for safe initialisation of attributes
    during the __init__ method, but prevents the addition of new attributes
    afterwards.

    The restriction is enforced through the custom __setattr__ method, which
    checks if the attribute already exists before allowing assignment.
    """
    def __setattr__(self, name, value):
        """
        Prevent addition of new attributes.

        Parameters
        ----------
        name: str
            The name of the attribute to set.
        value: any
            The value to assign to the attribute.

        Raises
        ------
        AttributeError
            If `name` is not an existing attribute and an attempt is made
            to add it to the class instance.
        """
        # Check if the instance is initialised and the attribute doesn"t exist
        if hasattr(self, "_initialised") and not hasattr(self, name):
            # Get a list of existing attributes for the error message
            existing = ", ".join(self.__dict__.keys())
            raise AttributeError(
                f"Cannot add new attribute '{name}' - only possible to " +
                f"modify existing attributes: {existing}."
            )
        # If checks pass, set the attribute using the standard method
        object.__setattr__(self, name, value)


class ASUArrivals(RestrictAttributes):
    """
    Arrival rates for the acute stroke unit (ASU) by patient type.

    These are the average time intervals (in days) between new admissions.
    For example, a value of 1.2 means a new admission every 1.2 days.
    """
    def __init__(self, stroke=1.2, tia=9.3, neuro=3.6, other=3.2):
        """
        Parameters
        ----------
        stroke: float
            Stroke patient.
        tia: float
            Transient ischaemic attack (TIA) patient.
        neuro: float
            Complex neurological patient.
        other: float
            Other patient types (including medical outliers).
        """
        self.stroke = stroke
        self.tia = tia
        self.neuro = neuro
        self.other = other


class RehabArrivals(RestrictAttributes):
    """
    Arrival rates for the rehabiliation unit by patient type.

    These are the average time intervals (in days) between new admissions.
    For example, a value of 21.8 means a new admission every 21.8 days.
    """
    def __init__(self, stroke=21.8, neuro=31.7, other=28.6):
        """
        Parameters
        ----------
        stroke: float
            Stroke patient.
        neuro: float
            Complex neurological patient.
        other: float
            Other patient types.
        """
        self.stroke = stroke
        self.neuro = neuro
        self.other = other


class ASULOS(RestrictAttributes):
    """
    Mean and standard deviation (SD) of length of stay (LOS) in days in the
    acute stroke unit (ASU) by patient type.

    Attributes
    ----------
    stroke_noesd: dict
        Mean and SD of LOS for stroke patients without early support discharge.
    stroke_esd: dict
        Mean and SD of LOS for stroke patients with early support discharge.
    tia: dict
        Mean and SD of LOS for transient ischemic attack (TIA) patients.
    neuro: dict
        Mean and SD of LOS for complex neurological patients.
    other: dict
        Mean and SD of LOS for other patients.
    """
    def __init__(
        self,
        stroke_no_esd_mean=7.4, stroke_no_esd_sd=8.61,
        stroke_esd_mean=4.6, stroke_esd_sd=4.8,
        stroke_mortality_mean=7.0, stroke_mortality_sd=8.7,
        tia_mean=1.8, tia_sd=2.3,
        neuro_mean=4.0, neuro_sd=5.0,
        other_mean=3.8, other_sd=5.2
    ):
        """
        Parameters
        ----------
        stroke_no_esd_mean: float
            Mean LOS for stroke patients without early support discharge (ESD)
            services.
        stroke_no_esd_sd: float
            SD of LOS for stroke patients without ESD.
        stroke_esd_mean: float
            Mean LOS for stroke patients with ESD.
        stroke_esd_sd: float
            SD of LOS for stroke patients with ESD.
        stroke_mortality_mean: float
            Mean LOS for stroke patients who pass away.
        stroke_mortality_sd: float
            SD of LOS for stroke patients who pass away.
        tia_mean: float
            Mean LOS for TIA patients.
        tia_sd: float
            SD of LOS for TIA patients.
        neuro_mean: float
            Mean LOS for complex neurological patients.
        neuro_sd: float
            SD of LOS for complex neurological patients.
        other_mean: float
            Mean LOS for other patient types.
        other_sd: float
            SD of LOS for other patient types.
        """
        self.stroke_noesd = {
            "mean": stroke_no_esd_mean,
            "sd": stroke_no_esd_sd
        }
        self.stroke_esd = {
            "mean": stroke_esd_mean,
            "sd": stroke_esd_sd
        }
        self.stroke_mortality = {
            "mean": stroke_mortality_mean,
            "sd": stroke_mortality_sd
        }
        self.tia = {
            "mean": tia_mean,
            "sd": tia_sd
        }
        self.neuro = {
            "mean": neuro_mean,
            "sd": neuro_sd
        }
        self.other = {
            "mean": other_mean,
            "sd": other_sd
        }


class RehabLOS(RestrictAttributes):
    """
    Mean and standard deviation (SD) of length of stay (LOS) in days in the
    rehabilitation unit by patient type.

    Attributes
    ----------
    stroke_noesd: dict
        Mean and SD of LOS for stroke patients without early support discharge.
    stroke_esd: dict
        Mean and SD of LOS for stroke patients with early support discharge.
    tia: dict
        Mean and SD of LOS for transient ischemic attack (TIA) patients.
    neuro: dict
        Mean and SD of LOS for complex neurological patients.
    other: dict
        Mean and SD of LOS for other patients.
    """
    def __init__(
        self,
        stroke_no_esd_mean=28.4, stroke_no_esd_sd=27.2,
        stroke_esd_mean=30.3, stroke_esd_sd=23.1,
        tia_mean=18.7, tia_sd=23.5,
        neuro_mean=27.6, neuro_sd=28.4,
        other_mean=16.1, other_sd=14.1
    ):
        """
        Parameters
        ----------
        stroke_no_esd_mean: float
            Mean LOS for stroke patients without early support discharge (ESD)
            services.
        stroke_no_esd_sd: float
            SD of LOS for stroke patients without ESD.
        stroke_esd_mean: float
            Mean LOS for stroke patients with ESD.
        stroke_esd_sd: float
            SD of LOS for stroke patients with ESD.
        tia_mean: float
            Mean LOS for TIA patients.
        tia_sd: float
            SD of LOS for TIA patients.
        neuro_mean: float
            Mean LOS for complex neurological patients.
        neuro_sd: float
            SD of LOS for complex neurological patients.
        other_mean: float
            Mean LOS for other patient types.
        other_sd: float
            SD of LOS for other patient types.
        """
        self.stroke_noesd = {
            "mean": stroke_no_esd_mean,
            "sd": stroke_no_esd_sd
        }
        self.stroke_esd = {
            "mean": stroke_esd_mean,
            "sd": stroke_esd_sd
        }
        self.tia = {
            "mean": tia_mean,
            "sd": tia_sd
        }
        self.neuro = {
            "mean": neuro_mean,
            "sd": neuro_sd
        }
        self.other = {
            "mean": other_mean,
            "sd": other_sd
        }


class ASURouting(RestrictAttributes):
    """
    Probabilities of each patient type being transferred from the acute
    stroke unit (ASU) to other destinations.

    Attributes
    ----------
    stroke: dict
        Routing probabilities for stroke patients.
    tia: dict
        Routing probabilities for transient ischemic attack (TIA) patients.
    neuro: dict
        Routing probabilities for complex neurological patients.
    other: dict
        Routing probabilities for other patients.
    """
    def __init__(
        self,
        # Stroke patients
        stroke_rehab=0.24, stroke_esd=0.13, stroke_other=0.63,
        # TIA patients
        tia_rehab=0.01, tia_esd=0.01, tia_other=0.98,
        # Complex neurological patients
        neuro_rehab=0.11, neuro_esd=0.05, neuro_other=0.84,
        # Other patients
        other_rehab=0.05, other_esd=0.10, other_other=0.85
    ):
        """
        Parameters
        ----------
        stroke_rehab: float
            Stroke patient to rehabilitation unit.
        stroke_esd: float
            Stroke patient to early support discharge (ESD) services.
        stroke_other: float
            Stroke patient to other destinations (e.g., own home, care
            home, mortality).
        tia_rehab: float
            TIA patient to rehabilitation unit.
        tia_esd: float
            TIA patient to ESD.
        tia_other: float
            TIA patient to other destinations.
        neuro_rehab: float
            Complex neurological patient to rehabilitation unit.
        neuro_esd: float
            Complex neurological patient to ESD.
        neuro_other: float
            Complex neurological patient to other destinations.
        other_rehab: float
            Other patient type to rehabilitation unit.
        other_esd: float
            Other patient type to ESD.
        other_other: float
            Other patient type to other destinations.
        """
        self.stroke = {
            "rehab": stroke_rehab,
            "esd": stroke_esd,
            "other": stroke_other
        }
        self.tia = {
            "rehab": tia_rehab,
            "esd": tia_esd,
            "other": tia_other
        }
        self.neuro = {
            "rehab": neuro_rehab,
            "esd": neuro_esd,
            "other": neuro_other
        }
        self.other = {
            "rehab": other_rehab,
            "esd": other_esd,
            "other": other_other
        }


class RehabRouting(RestrictAttributes):
    """
    Probabilities of each patient type being transferred from the rehabiliation
    unit to other destinations.

    Attributes
    ----------
    stroke: dict
        Routing probabilities for stroke patients.
    tia: dict
        Routing probabilities for transient ischemic attack (TIA) patients.
    neuro: dict
        Routing probabilities for complex neurological patients.
    other: dict
        Routing probabilities for other patients.
    """
    def __init__(
        self,
        # Stroke patients
        stroke_esd=0.40, stroke_other=0.60,
        # TIA patients
        tia_esd=0, tia_other=1,
        # Complex neurological patients
        neuro_esd=0.09, neuro_other=0.91,
        # Other patients
        other_esd=0.13, other_other=0.88
    ):
        """
        Parameters
        ----------
        stroke_esd: float
            Stroke patient to early support discharge (ESD) services.
        stroke_other: float
            Stroke patient to other destinations (e.g., own home, care home,
            mortality).
        tia_esd: float
            TIA patient to ESD.
        tia_other: float
            TIA patient to other destinations.
        neuro_esd: float
            Complex neurological patient to ESD.
        neuro_other: float
            Complex neurological patient to other destinations.
        other_esd: float
            Other patient type to ESD.
        other_other: float
            Other patient type to other destinations.
        """
        self.stroke = {
            "esd": stroke_esd,
            "other": stroke_other
        }
        self.tia = {
            "esd": tia_esd,
            "other": tia_other
        }
        self.neuro = {
            "esd": neuro_esd,
            "other": neuro_other
        }
        self.other = {
            "esd": other_esd,
            "other": other_other
        }


class Param(RestrictAttributes):
    """
    Default parameters for simulation.
    """
    def __init__(
        self,
        asu_arrivals=ASUArrivals(),
        rehab_arrivals=RehabArrivals(),
        asu_los=ASULOS(),
        rehab_los=RehabLOS(),
        asu_routing=ASURouting(),
        rehab_routing=RehabRouting(),
        warm_up_period=365*3,  # 3 years
        data_collection_period=365*5,  # 5 years
        number_of_runs=150,
        audit_interval=1,
        cores=1,
        log_to_console=False,
        log_to_file=False,
        log_file_path=("../outputs/logs/" +
                       f"{time.strftime("%Y-%m-%d_%H-%M-%S")}.log")
    ):
        """
        Initialise a parameter set for the simulation.

        Parameters
        ----------
        asu_arrivals: ASUArrivals
            Arrival rates to the acute stroke unit (ASU) in days.
        rehab_arrivals: RehabArrivals
            Arrival rates to the rehabilitation unit in days.
        asu_los: ASULOS
            Length of stay (LOS) distributions for patients in the ASU in days.
        rehab_los: RehabLOS
            LOS distributions for patients in the rehabilitation unit in days.
        asu_routing: ASURouting
            Transfer probabilities from the ASU to other destinations.
        rehab_routing: RehabRouting
            Transfer probabilities from the rehabilitation unit to other
            destinations.
        warm_up_period: int
            Length of the warm-up period.
        data_collection_period: int
            Length of the data collection period.
        number_of_runs: int
            The number of runs (i.e. replications), defining how many times to
            re-run the simulation (with different random numbers).
        audit_interval: float
            Frequency of simulation audits in days.
        cores: int
            Number of CPU cores to use for parallel execution. Set to desired
            number, or to -1 to use all available cores. For sequential
            execution, set to 1.
        log_to_console: boolean
            Whether to print log messages to the console.
        log_to_file: boolean
            Whether to save log to a file.
        log_file_path: str
            Path to save log to file. Note, if you use an existing .log
            file name, it will append to that log.
        """
        # Set parameters
        self.asu_arrivals = asu_arrivals
        self.rehab_arrivals = rehab_arrivals
        self.asu_los = asu_los
        self.rehab_los = rehab_los
        self.asu_routing = asu_routing
        self.rehab_routing = rehab_routing
        self.warm_up_period = warm_up_period
        self.data_collection_period = data_collection_period
        self.number_of_runs = number_of_runs
        self.audit_interval = audit_interval
        self.cores = cores

        # Set up logger
        self.logger = SimLogger(log_to_console=log_to_console,
                                log_to_file=log_to_file,
                                file_path=log_file_path)

    def check_param_validity(self):
        """
        Check the validity of the provided parameters.

        Validates all simulation parameters to ensure they meet requirements:
        - Warm-up period and data collection period must be >= 0
        - Number of runs and audit interval must be > 0
        - Arrival rates must be >= 0
        - Length of stay parameters must be >= 0
        - Routing probabilities must sum to 1 and be between 0 and 1

        Raises
        ------
        ValueError
            If any parameter fails validation with a descriptive error message.
        """
        # Validate parameters that must be >= 0
        for param in ["warm_up_period", "data_collection_period"]:
            self.validate_param(
                param, lambda x: x >= 0,
                "must be greater than or equal to 0")

        # Validate parameters that must be > 0
        for param in ["number_of_runs", "audit_interval"]:
            self.validate_param(
                param, lambda x: x > 0,
                "must be greater than 0")

        # Validate arrival parameters
        for param in ["asu_arrivals", "rehab_arrivals"]:
            self.validate_nested_param(
                param, lambda x: x >= 0,
                "must be greater than 0")

        # Validate length of stay parameters
        for param in ["asu_los", "rehab_los"]:
            self.validate_nested_param(
                param, lambda x: x >= 0,
                "must be greater than 0", nested=True)

        # Validate routing parameters
        for param in ["asu_routing", "rehab_routing"]:
            self.validate_routing(param)

    def validate_param(self, param_name, condition, error_msg):
        """
        Validate a single parameter against a condition.

        Parameters
        ----------
        param_name: str
            Name of the parameter being validated.
        condition: callable
            A function that returns True if the value is valid.
        error_msg: str
            Error message to display if validation fails.

        Raises
        ------
        ValueError:
            If the parameter fails the validation condition.
        """
        value = getattr(self, param_name)
        if not condition(value):
            raise ValueError(
                f"Parameter '{param_name}' {error_msg}, but is: {value}")

    def validate_nested_param(
        self, obj_name, condition, error_msg, nested=False
    ):
        """
        Validate parameters within a nested object structure.

        Parameters
        ----------
        obj_name: str
            Name of the object containing parameters.
        condition: callable
            A function that returns True if the value is valid.
        error_msg: str
            Error message to display if validation fails.
        nested: bool, optional
            If True, validates parameters in a doubly-nested structure. If
            False, validates parameters in a singly-nested structure.

        Raises
        ------
        ValueError:
            If any nested parameter fails the validation condition.
        """
        obj = getattr(self, obj_name)
        for key, value in vars(obj).items():
            if key == "_initialised":
                continue
            if nested:
                for sub_key, sub_value in value.items():
                    if not condition(sub_value):
                        raise ValueError(
                            f"Parameter '{sub_key}' for '{key}' in " +
                            f"'{obj_name}' {error_msg}, but is: {sub_value}")
            else:
                if not condition(value):
                    raise ValueError(
                        f"Parameter '{key}' from '{obj_name}' {error_msg}, " +
                        f"but is: {value}")

    def validate_routing(self, obj_name):
        """
        Validate routing probability parameters.

        Performs two validations:
        1. Checks that all probabilities for each routing option sum to 1.
        2. Checks that individual probabilities are between 0 and 1 inclusive.

        Parameters
        ----------
        obj_name: str
            Name of the routing object.

        Raises
        ------
        ValueError:
            If the probabilities don't sum to 1, or if any probability is
            outside [0,1].
        """
        obj = getattr(self, obj_name)
        for key, value in vars(obj).items():
            if key == "_initialised":
                continue

            # Check that probabilities sum to 1
            # Note: In the article, rehab other is 88% and 13%, so have
            # allowed deviation of 1%
            total_prob = sum(value.values())
            if total_prob < 0.99 or total_prob > 1.01:
                raise ValueError(
                    f"Routing probabilities for '{key}' in '{obj_name}' " +
                    f"should sum to apx. 1 but sum to: {total_prob}")

            # Check that probabilities are between 0 and 1
            for sub_key, sub_value in value.items():
                if sub_value < 0 or sub_value > 1:
                    raise ValueError(
                        f"Parameter '{sub_key}' for '{key}' in '{obj_name}'" +
                        f"must be between 0 and 1, but is: {sub_value}")
