import pytest
from simulation import Parameters, Runner


@pytest.mark.parametrize("param_name, initial_value, adjusted_value", [
    ("interarrival_time", 2, 15),
    ("data_collection_period", 2000, 500)
])
def test_arrivals_decrease(param_name, initial_value, adjusted_value):
    """
    Test that adjusting parameters reduces the number of arrivals as expected.
    """
    # Run model with initial value
    param = Parameters(**{param_name: initial_value})
    experiment = Runner(param)
    initial_arrivals = experiment.run_single(run=0)["run"]["arrivals"]

    # Run model with adjusted value
    param = Parameters(**{param_name: adjusted_value})
    experiment = Runner(param)
    adjusted_arrivals = experiment.run_single(run=0)["run"]["arrivals"]

    # Check that arrivals from adjusted model are less
    assert initial_arrivals > adjusted_arrivals, (
        f'Changing "{param_name}" from {initial_value} to {adjusted_value} ' +
        "did not decrease the number of arrivals as expected: observed " +
        f"{initial_arrivals} and {adjusted_arrivals} arrivals, respectively."
    )
