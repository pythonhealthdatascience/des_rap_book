"""
summary_stats.
"""

import numpy as np
import scipy.stats as st


def summary_stats(data):
    """
    Calculate mean, standard deviation and 95% confidence interval (CI).

    Parameters
    ----------
    data : pd.Series
        Data to use in calculation.

    Returns
    -------
    tuple
        (mean, standard deviation, CI lower, CI upper).
    """
    # Remove any NaN from the series
    data = data.dropna()

    # Find number of observations
    count = len(data)

    # If there are no observations, then set all to NaN
    if count == 0:
        mean, std_dev, ci_lower, ci_upper = np.nan, np.nan, np.nan, np.nan
    # If there is only one or two observations, can do mean but not others
    elif count < 3:
        mean = data.mean()
        std_dev, ci_lower, ci_upper = np.nan, np.nan, np.nan
    # With more than one observation, can calculate all...
    else:
        mean = data.mean()
        std_dev = data.std()
        # Special case for CI if variance is 0
        if np.var(data) == 0:
            ci_lower, ci_upper = mean, mean
        else:
            # Calculation of CI uses t-distribution, which is suitable for
            # smaller sample sizes (n<30)
            ci_lower, ci_upper = st.t.interval(
                confidence=0.95,
                df=count-1,
                loc=mean,
                scale=st.sem(data))
    return mean, std_dev, ci_lower, ci_upper
