"""
Logs track events as the code runs - similar to print statements, but keeping a
more permanent record.
"""

import logging
import os
from pprint import pformat
import time

from rich.logging import RichHandler
from rich.console import Console


class SimLogger:
    """
    Provides log of events as the simulation runs.

    Attributes:
        log_to_console (boolean):
            Whether to print log messages to the console.
        log_to_file (boolean):
            Whether to save log to a file.
        file_path (str):
            Path to save log to file.
        sanitise (boolean):
            Whether to sanitise dictionaries to remove memory addresses in
            logs, default False.
        logger (logging.Logger):
            The logging instance used for logging messages.
    """
    def __init__(self, log_to_console=False, log_to_file=False,
                 file_path=("../outputs/logs/" +
                            f"{time.strftime("%Y-%m-%d_%H-%M-%S")}.log"),
                 sanitise=False):
        """
        Initialise the Logger class.

        Arguments:
            log_to_console (boolean):
                Whether to print log messages to the console.
            log_to_file (boolean):
                Whether to save log to a file.
            file_path (str):
                Path to save log to file. Note, if you use an existing .log
                file name, it will append to that log. Defaults to filename
                based on current date and time, and folder "../outputs/log/".
            sanitise (boolean):
                Whether to sanitise dictionaries to remove memory addresses
                in logs, default False.
        """
        self.log_to_console = log_to_console
        self.log_to_file = log_to_file
        self.file_path = file_path
        self.sanitise = sanitise
        self.logger = None

        # If saving to file, check path is valid
        if self.log_to_file:
            self._validate_log_path()

        # If logging enabled (either printing to console, file or both), then
        # create logger and configure settings
        if self.log_to_console or self.log_to_file:
            self.logger = logging.getLogger(__name__)
            self._configure_logging()

    def _validate_log_path(self):
        """
        Validate the log file path.

        Raises:
            ValueError: If log path is invalid.
        """
        # Check if directory exists
        directory = os.path.dirname(self.file_path)
        if directory and not os.path.exists(directory):
            raise ValueError(f"The directory '{directory}' for the log " +
                             "file does not exist.")

        # Check if the file ends with .log
        if not self.file_path.endswith(".log"):
            raise ValueError(f"The log file path '{self.file_path}' must " +
                             "end with '.log'.")

    def _configure_logging(self):
        """
        Configure the logger.
        """
        # Ensure any existing handlers are removed to avoid duplication
        for handler in self.logger.handlers[:]:
            self.logger.removeHandler(handler)

        # Configure RichHandler without INFO/ERROR labels, times or paths
        # to log message. Set up console with jupyter-specific behaviour
        # disabled to prevent large gaps between each log message on ipynb.
        console = Console()
        console.is_jupyter = False
        rich_handler = RichHandler(console=console, show_time=False,
                                   show_level=False, show_path=False)

        # Add handlers for saving messages to file and/or printing to console
        handlers = []
        if self.log_to_file:
            # In write mode, meaning will overwrite existing log of same name
            # (append mode "a" would add to the end of the log)
            handlers.append(logging.FileHandler(self.file_path, mode="w"))
        if self.log_to_console:
            handlers.append(rich_handler)

        # Add handlers directly to the logger
        for handler in handlers:
            self.logger.addHandler(handler)

        # Set logging level and format. If don't set level info, it would
        # only show log messages which are warning, error or critical.
        self.logger.setLevel(logging.INFO)
        formatter = logging.Formatter("%(message)s")
        for handler in handlers:
            handler.setFormatter(formatter)

    def sanitise_object(self, obj):
        """
        Sanitise object references to avoid memory addresses in logs.

        Arguments:
            obj (object):
                Object to sanitise

        Returns:
            str:
                Sanitised version of the object. If it"s an object,
                it returns the class name; otherwise, it returns the
                object itself.
        """
        # Only sanitise custom objects (not basic types like int, str, etc.)
        if isinstance(obj, object) and not isinstance(
            obj, (int, float, bool, str, list, dict, tuple, set)
        ):
            # Return the class name instead of the memory address
            return f"<{obj.__class__.__module__}.{obj.__class__.__name__}>"
        return obj

    def log(self, msg, sim_time=None):
        """
        Log a message if logging is enabled.

        Arguments:
            msg (str):
                Message to log.
            sim_time (float|None, optional):
                Current simulation time. If provided, prints before message.
        """
        # Sanitise (if enabled) and pretty format dictionaries
        if isinstance(msg, dict):
            if self.sanitise:
                msg = {key: self.sanitise_object(value)
                       for key, value in msg.items()}
            msg = pformat(msg, indent=4)

        if self.log_to_console or self.log_to_file:
            # Log message, with simulation time rounded to 3dp if given.
            if sim_time is not None:
                self.logger.info("%0.3f: %s", sim_time, msg)
            else:
                self.logger.info(msg)
