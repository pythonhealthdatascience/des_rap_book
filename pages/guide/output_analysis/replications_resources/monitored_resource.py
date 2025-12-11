class MonitoredResource(simpy.Resource):
    """
    SimPy Resource subclass that tracks utilisation, queue length and mean
    number of patients in the system.

    Attributes
    ----------
    time_last_event : list
        Time of the most recent resource request or release event.
    area_resource_busy : list
        Cumulative time resources were busy, for computing utilisation.
    area_n_in_queue : list
        Cumulative time patients spent queueing for a resource, for
        computing average queue length.

    Notes
    -----
    Class adapted from Monks, Harper and Heather 2025.
    """

    def __init__(self, *args, **kwargs):
        """
        Initialise the MonitoredResource, resetting monitoring statistics.

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
        Reset monitoring attributes.
        """
        self.time_last_event = [self._env.now]
        self.area_resource_busy = [0.0]
        self.area_n_in_queue = [0.0]

    def request(self, *args, **kwargs):
        """
        Update time-weighted statistics before requesting a resource.

        Parameters
        ----------
        *args :
            Positional arguments to be passed to the parent class.
        **kwargs :
            Keyword arguments to be passed to the parent class.

        Returns
        -------
        simpy.events.Event
            Event for the resource request.
        """
        # Update time-weighted statistics
        self.update_time_weighted_stats()
        # Request a resource
        return super().request(*args, **kwargs)

    def release(self, *args, **kwargs):
        """
        Update time-weighted statistics before releasing a resource.

        Parameters
        ----------
        *args :
            Positional arguments to be passed to the parent class.
        **kwargs :
            Keyword arguments to be passed to the parent class.

        Returns
        -------
        simpy.events.Event
            Event for the resource release.
        """
        # Update time-weighted statistics
        self.update_time_weighted_stats()
        # Release a resource
        return super().release(*args, **kwargs)

    def update_time_weighted_stats(self):
        """
        Update the time-weighted statistics for resource usage.

        Notes
        -----
        - These sums can be referred to as "the area under the curve".
        - They are called "time-weighted" statistics as they account for how
          long certain events or states persist over time.
        """
        # Calculate time since last event
        time_since_last_event = self._env.now - self.time_last_event[-1]

        # Add record of current time
        self.time_last_event.append(self._env.now)

        # Add "area under curve" of resources in use
        # self.count is the number of resources in use
        self.area_resource_busy.append(self.count * time_since_last_event)

        # Add "area under curve" of people in queue
        # len(self.queue) is the number of requests queued
        self.area_n_in_queue.append(len(self.queue) * time_since_last_event)
