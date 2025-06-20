"""
OnlineStatistics.

Acknowledgements
----------------
This code is adapted from Tom Monks (2021) sim-tools: fundamental tools to
support the simulation process in python
(https://github.com/TomMonks/sim-tools) (MIT Licence).
"""

import numpy as np
from scipy.stats import t


class OnlineStatistics:
    """
    Computes running sample mean and variance (using Welford's algorithm),
    which then allows computation of confidence intervals (CIs).

    The statistics are referred to as "online" as they are computed via updates
    to its value, rather than storing lots of data and repeatedly taking the
    mean after new values have been added.

    Attributes
    ----------
    n : int
        Number of data points processed.
    x_i : float
        Most recent data point.
    mean : float
        Running mean.
    _sq : float
        Sum of squared differences from the mean.
    alpha : float
        Significance level for confidence interval calculations.
    observer : list
        Object to notify on updates.

    Notes
    -----
    Class adapted from Monks 2021.
    """

    def __init__(self, data=None, alpha=0.05, observer=None):
        """
        Initialises the OnlineStatistics instance.

        Parameters
        ----------
        data : np.ndarray, optional
            Array containing an initial data sample.
        alpha : float, optional
            Significance level for confidence interval calculations.
        observer : object, optional
            Observer to notify on updates.
        """
        self.n = 0
        self.x_i = None
        self.mean = None
        self._sq = None
        self.alpha = alpha
        self.observer = observer

        # If an array of initial values are supplied, then run update()
        if data is not None:
            if isinstance(data, np.ndarray):
                for x in data:
                    self.update(x)
            # Raise an error if in different format - else will invisibly
            # proceed and won't notice it hasn't done this
            else:
                raise ValueError(
                    f"data must be np.ndarray but is type {type(data)}")

    def update(self, x):
        """
        Running update of mean and variance implemented using Welford's
        algorithm (1962).

        See Knuth. D `The Art of Computer Programming` Vol 2. 2nd ed. Page 216.

        Parameters
        ----------
        x : float
            A new data point.
        """
        self.n += 1
        self.x_i = x
        if self.n == 1:
            self.mean = x
            self._sq = 0
        else:
            updated_mean = self.mean + ((x - self.mean) / self.n)
            self._sq += (x - self.mean) * (x - updated_mean)
            self.mean = updated_mean

        # Run the observer update() method
        if self.observer is not None:
            self.observer.update(self)

    @property
    def variance(self):
        """
        Computes and returns the variance of the data points.

        Returns
        -------
        float
            Sample variance.
        """
        # Sum of squares of differences from the current mean divided by n - 1
        return self._sq / (self.n - 1)

    @property
    def std(self):
        """
        Computes and returns the standard deviation, or NaN if not enough data.

        Returns
        -------
        float
            Standard deviation.
        """
        if self.n > 2:
            return np.sqrt(self.variance)
        return np.nan

    @property
    def std_error(self):
        """
        Computes and returns the standard error of the mean.

        Returns
        -------
        float
            Standard error.
        """
        return self.std / np.sqrt(self.n)

    @property
    def half_width(self):
        """
        Computes and returns the half-width of the confidence interval.

        Returns
        -------
        float
            Confidence interval half-width.
        """
        dof = self.n - 1
        t_value = t.ppf(1 - (self.alpha / 2), dof)
        return t_value * self.std_error

    @property
    def lci(self):
        """
        Computes and returns the lower confidence interval bound, or NaN if
        not enough data.

        Returns
        -------
        float
            Lower confidence interval bound.
        """
        if self.n > 2:
            return self.mean - self.half_width
        return np.nan

    @property
    def uci(self):
        """
        Computes and returns the upper confidence interval bound, or NaN if
        not enough data.

        Returns
        -------
        float
            Upper confidence interval bound.
        """
        if self.n > 2:
            return self.mean + self.half_width
        return np.nan

    @property
    def deviation(self):
        """
        Computes and returns the precision of the confidence interval
        expressed as the percentage deviation of the half width from the mean.

        Returns
        -------
        float
            Relative deviation of the confidence interval half width.
        """
        if self.n > 2:
            return self.half_width / self.mean
        return np.nan
