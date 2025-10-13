import pytest
from simulation import Parameters, Model


@pytest.mark.parametrize("param_name, message", [
    ("number_of_doctors", '"capacity" must be > 0.'),
    ("interarrival_time", "mean must be positive, got 0")
])
def test_zero_inputs(param_name, message):
    """
    Check that the model fails when inputs that are zero are used.

    Parameters
    ----------
    param_name : str
        Name of parameter to change in the parameter class.
    message : str
        Error message that expect to see.
    """
    # Create parameter class with value set to zero
    param = Parameters(**{param_name: 0})

    # Verify that initialising the model raises an error
    with pytest.raises(ValueError, match=message):
        Model(param=param, run_number=0)
