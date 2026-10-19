
import csv
import math

CSV_FILE = "SpendingTestingData.csv"

absolute_errors = []
squared_errors = []
predictions = []

with open(CSV_FILE, "r", newline="", encoding="utf-8-sig") as file:
    reader = csv.DictReader(file)

    for row in reader:
        days_elapsed = int(row["daysElapsed"])
        days_in_month = int(row["daysInMonth"])
        spending_so_far = float(row["spendingSoFar"])
        actual_total = float(row["actualMonthlyTotal"])

        # Estimate the final monthly total using the current daily rate.
        predicted_total = (
            spending_so_far / days_elapsed
        ) * days_in_month

        error = predicted_total - actual_total

        predictions.append(predicted_total)
        absolute_errors.append(abs(error))
        squared_errors.append(error ** 2)

if not absolute_errors:
    raise ValueError("The testing CSV contains no data rows.")

mae = sum(absolute_errors) / len(absolute_errors)
rmse = math.sqrt(sum(squared_errors) / len(squared_errors))
maximum_error = max(absolute_errors)

print("BASELINE EVALUATION")
print("-------------------")
print(f"Test examples: {len(absolute_errors)}")
print(f"MAE:           {mae:.2f}")
print(f"RMSE:          {rmse:.2f}")
print(f"Maximum Error: {maximum_error:.2f}")

