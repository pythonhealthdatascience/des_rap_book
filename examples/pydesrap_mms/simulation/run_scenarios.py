"""
run_scenarios.

Acknowledgements
----------------
This code is adapted from Sammi Rosser and Dan Chalk (2024) HSMA - the
little book of DES (https://github.com/hsma-programme/hsma6_des_book)
(MIT Licence).
"""

import itertools
import pandas as pd

from .param import Param
from .runner import Runner


def run_scenarios(scenarios, param=None):
    """
    Execute a set of scenarios and return the results from each run.

    Parameters
    ----------
    scenarios : dict
        Dictionary where key is name of parameter and value is a list with
        different values to run in scenarios.
    param : Param, optional
        Instance of Param with parameters for the base case. Optional, defaults
        to use those as set in Param.

    Returns
    -------
    pandas.DataFrame
        DataFrame with results from each run of each scenario.

    Notes
    -----
    Function adapted from Rosser and Chalk 2024.
    """
    # Find every possible permutation of the scenarios
    all_scenarios_tuples = list(itertools.product(*scenarios.values()))
    # Convert back into dictionaries
    all_scenarios_dicts = [
        dict(zip(scenarios.keys(), p)) for p in all_scenarios_tuples
    ]
    # Preview some of the scenarios
    print(f"There are {len(all_scenarios_dicts)} scenarios. Running:")

    # Run the scenarios...
    results = []
    for index, scenario_to_run in enumerate(all_scenarios_dicts):
        print(scenario_to_run)

        # Create instance of parameter class, if not provided
        if param is None:
            param = Param()

        # Update parameter list with the scenario parameters
        param.scenario_name = index
        for key in scenario_to_run:
            setattr(param, key, scenario_to_run[key])

        # Perform replications and keep results from each run, adding the
        # scenario values to the results dataframe
        scenario_exp = Runner(param)
        scenario_exp.run_reps()
        for key in scenario_to_run:
            scenario_exp.run_results_df[key] = scenario_to_run[key]
        results.append(scenario_exp.run_results_df)
    return pd.concat(results)
