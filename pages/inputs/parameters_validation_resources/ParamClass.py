# pylint: disable=missing-module-docstring, invalid-name, too-few-public-methods
class ParamClass:
    """
    Returns transfer_prob for validation example.
    """
    def __init__(self, transfer_prob=0.3):
        """
        Initialise ParamClass instance.

        Parameters
        ----------
        transfer_prob : float
            Transfer probability (0-1).
        """
        self.transfer_prob = transfer_prob
