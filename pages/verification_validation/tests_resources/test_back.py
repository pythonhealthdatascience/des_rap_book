from pathlib import Path

import pandas as pd
from simulation import Parameters, Runner


def test_reproduction():
    """
    Check that results from particular run of the model match those
    previously generated using the code.
    """
    # Define model parameters
    param = Parameters(
        interarrival_time=5,
        consultation_time=10,
        number_of_doctors=3,
        warm_up_period=30,
        data_collection_period=40,
        number_of_runs=5,
        verbose=False
    )

    # Run simulation
    runner = Runner(param=param)
    results = runner.run_reps()

    # Import expected results
    exp_patient = pd.read_csv(
        Path(__file__).parent.joinpath("python_patient.csv")
    )
    exp_run = pd.read_csv(
        Path(__file__).parent.joinpath("python_run.csv")
    )
    exp_overall = pd.read_csv(
        Path(__file__).parent.joinpath("python_overall.csv")
    )

    # Compare results
    pd.testing.assert_frame_equal(results["patient"], exp_patient)
    pd.testing.assert_frame_equal(results["run"], exp_run)
    pd.testing.assert_frame_equal(
        results["overall"].reset_index(drop=True), exp_overall
    )
