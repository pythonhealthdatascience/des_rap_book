# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# %% [python]
# pylint: disable=missing-function-docstring,missing-class-docstring
# pylint: disable=wrong-import-position
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# %% [python]
def estimate_wait_time(queue_length, avg_service_time):
    return queue_length * avg_service_time


# There are 4 patients ahead, average service time is 15 minutes
print(estimate_wait_time(queue_length=4, avg_service_time=15))
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# %% [python]
class Patient:
    def __init__(self, patient_id, arrival_time):
        self.patient_id = patient_id
        self.arrival_time = arrival_time
        self.status = "waiting"

    def admit(self):
        self.status = "admitted"

    def discharge(self):
        self.status = "discharged"


alice = Patient(patient_id=1, arrival_time=3)
print(alice.status)
# -
# -
# %% [python]
alice.admit()
print(alice.status)
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# %% [python]
class EmergencyPatient(Patient):
    def __init__(self, patient_id, arrival_time, severity):
        super().__init__(patient_id, arrival_time)
        self.severity = severity

    def triage(self):
        if self.severity > 7:
            return "High priority"
        return "Standard priority"


ben = EmergencyPatient(patient_id=2, arrival_time=5, severity=9)
print(ben.status)
# -
# -
# %% [python]
print(ben.triage())
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# %% [python]
import numpy as np
import pandas as pd

# Set seed for reproducibility
np.random.seed(123)

# Input data
patient_arrivals = [1, 3, 4, 10, 12]  # in minutes
service_times = [5, 7, 3, 4, 6]       # in minutes
arrival_ids = list(range(1, len(patient_arrivals) + 1))

# Initialize tracking variables
start_times = [0] * len(patient_arrivals)
end_times = [0] * len(patient_arrivals)
waiting_times = [0] * len(patient_arrivals)

# Simulate service
for i, arrival in enumerate(patient_arrivals):
    if i == 0:
        start_times[i] = arrival
    else:
        # Next patient starts when they arrive or when previous is done
        start_times[i] = max(arrival, end_times[i - 1])

    end_times[i] = start_times[i] + service_times[i]
    waiting_times[i] = start_times[i] - arrival

# Combine into a DataFrame
results = pd.DataFrame({
    'id': arrival_ids,
    'arrival': patient_arrivals,
    'start': start_times,
    'end': end_times,
    'waiting': waiting_times
})

print(results)
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
# -
