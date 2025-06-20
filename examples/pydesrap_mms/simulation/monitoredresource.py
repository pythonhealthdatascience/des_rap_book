"""
MonitoredResource.

Acknowledgements
----------------
The MonitoredResource class is based on Tom Monks, Alison Harper and Amy
Heather (2025) An introduction to Discrete-Event Simulation (DES) using Free
and Open Source Software
(https://github.com/pythonhealthdatascience/intro-open-sim/tree/main)
(MIT Licence). They based it on the method described in Law. Simulation
Modeling and Analysis 4th Ed. Pages 14 - 17.
"""

from simpy import Resource


class MonitoredResource(Resource):
    """
    Subclass of simpy.Resource used to monitor resource usage during the run.

    Calculates resource utilisation and the queue length during the model run.

    Attributes
    ----------
    time_last_event : list
        Time of last resource request or release.
    area_n_in_queue : list
        Time that patients have spent queueing for the resource
        (i.e. sum of the times each patient spent waiting). Used to
        calculate the average queue length.
    area_resource_busy : list
        Time that resources have been in use during the simulation
        (i.e. sum of the times each individual resource was busy). Used
        to calculated utilisation.

    Notes
    -----
    Class adapted from Monks, Harper and Heather 2025.
    """

    def __init__(self, *args, **kwargs):
        """
        Initialises a MonitoredResource - which involves initialising a SimPy
        resource and resetting monitoring attributes.

        Parameters
        ----------
        *args :
            Positional arguments to be passed to the parent class.
        **kwargs :
            Keyword arguments to be passed to the parent class.
        """
        # Initialise a SimPy Resource
        super().__init__(*args, **kwargs)
        # Run the init_results() method
        self.init_results()

    def init_results(self):
        """
        Resets monitoring attributes to initial values.
        """
        self.time_last_event = [self._env.now]
        self.area_n_in_queue = [0.0]
        self.area_resource_busy = [0.0]

    def request(self, *args, **kwargs):
        """
        Requests a resource, but updates time-weighted statistics BEFORE
        making the request.

        Parameters
        ----------
        *args :
            Positional arguments to be passed to the parent class.
        **kwargs :
            Keyword arguments to be passed to the parent class.

        Returns
        -------
        simpy.events.Event
            Event representing the request.
        """
        # Update time-weighted statistics
        self.update_time_weighted_stats()
        # Request a resource
        return super().request(*args, **kwargs)

    def release(self, *args, **kwargs):
        """
        Releases a resource, but updates time-weighted statistics BEFORE
        releasing it.

        Parameters
        ----------
        *args :
            Positional arguments to be passed to the parent class.
        **kwargs :
            Keyword arguments to be passed to the parent class.

        Returns
        -------
        simpy.events.Event
            Event representing the request.
        """
        # Update time-weighted statistics
        self.update_time_weighted_stats()
        # Release a resource
        return super().release(*args, **kwargs)

    def update_time_weighted_stats(self):
        """
        Update the time-weighted statistics for resource usage.

        Between every request or release of the resource, it calculates the
        relevant statistics - e.g.:
        - Total queue time (number of requests in queue * time)
        - Total resource use (number of resources in use * time)

        These are summed to return the totals from across the whole simulation.

        Notes
        -----
        - These sums can be referred to as "the area under the curve".
        - They are called "time-weighted" statistics as they account for how
          long certain events or states (such as resource use or queue length)
          persist over time.
        """
        # Calculate time since last event
        time_since_last_event = self._env.now - self.time_last_event[-1]

        # Add record of current time
        self.time_last_event.append(self._env.now)

        # Add "area under curve" of people in queue
        # len(self.queue) is the number of requests queued
        self.area_n_in_queue.append(len(self.queue) * time_since_last_event)

        # Add "area under curve" of resources in use
        # self.count is the number of resources in use
        self.area_resource_busy.append(self.count * time_since_last_event)
