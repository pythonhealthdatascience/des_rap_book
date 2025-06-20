"""
Param.
"""

from .simlogger import SimLogger


# pylint: disable=too-many-instance-attributes,too-few-public-methods

class Param:
    """
    Default parameters for simulation.

    Attributes
    ----------
    _initialising : bool
        Whether the object is currently initialising.
    patient_inter : float
        Mean inter-arrival time between patients in minutes.
    mean_n_consult_time : float
        Mean nurse consultation time in minutes.
    number_of_nurses : float
        Number of available nurses.
    warm_up_period : int
        Duration of the warm-up period in minutes.
    data_collection_period : int
        Duration of data collection period in minutes.
    number_of_runs : int
        The number of runs (i.e. replications).
    audit_interval : int
        How frequently to audit resource utilisation, in minutes.
    scenario_name : int|float|str
        Label for the scenario.
    cores : int
        Number of CPU cores to use for parallel execution. For all
        available cores, set to -1. For sequential execution, set to 1.
    logger : logging.Logger
        The logging instance used for logging messages.
    """
    # pylint: disable=too-many-arguments,too-many-positional-arguments
    def __init__(
        self,
        patient_inter=4,
        mean_n_consult_time=10,
        number_of_nurses=5,
        warm_up_period=1440*27,  # 27 days
        data_collection_period=1440*30,  # 30 days
        number_of_runs=31,
        audit_interval=120,  # Every 2 hours
        scenario_name=0,
        cores=-1,
        logger=SimLogger(log_to_console=False, log_to_file=False)
    ):
        """
        Initialise instance of parameters class.

        Parameters
        ----------
        patient_inter : float, optional
            Mean inter-arrival time between patients in minutes.
        mean_n_consult_time : float, optional
            Mean nurse consultation time in minutes.
        number_of_nurses : float, optional
            Number of available nurses.
        warm_up_period : int, optional
            Duration of the warm-up period in minutes.
        data_collection_period : int, optional
            Duration of data collection period in minutes.
        number_of_runs : int, optional
            The number of runs (i.e. replications).
        audit_interval : int, optional
            How frequently to audit resource utilisation, in minutes.
        scenario_name : int|float|str, optional
            Label for the scenario.
        cores : int, optional
            Number of CPU cores to use for parallel execution.
        logger : logging.Logger, optional
            The logging instance used for logging messages.
        """
        # Disable restriction on attribute modification during initialisation
        object.__setattr__(self, "_initialising", True)
        self.patient_inter = patient_inter
        self.mean_n_consult_time = mean_n_consult_time
        self.number_of_nurses = number_of_nurses
        self.warm_up_period = warm_up_period
        self.data_collection_period = data_collection_period
        self.number_of_runs = number_of_runs
        self.audit_interval = audit_interval
        self.scenario_name = scenario_name
        self.cores = cores
        self.logger = logger

        # Re-enable attribute checks after initialisation
        object.__setattr__(self, "_initialising", False)

    def __setattr__(self, name, value):
        """
        Prevent addition of new attributes.

        Parameters
        ----------
        name : str
            The name of the attribute to set.
        value : Any
            The value to assign to the attribute.

        Raises
        ------
        AttributeError
            If `name` is not an existing attribute and an attempt is made
            to add it to the instance.
        """
        # Skip the check if the object is still initialising
        # pylint: disable=maybe-no-member
        if hasattr(self, "_initialising") and self._initialising:
            super().__setattr__(name, value)
        else:
            # Check if attribute of that name is already present
            if name in self.__dict__:
                super().__setattr__(name, value)
            else:
                raise AttributeError(
                    f"Cannot add new attribute '{name}' - only possible to "
                    f"modify existing attributes: {self.__dict__.keys()}"
                )
