
# Import functions from the new module
from utils.csv_utils import get_points_from_csv, ask_csv_file
import os
import csv
import numpy as np

scale_to_um = 1000

# Read points from CSV file ============
csv_file = ask_csv_file()
probe_track = get_points_from_csv(csv_file, scale_to_um,marker_name="Type 1")
cells_array = np.array(np.vstack(probe_track))  # Convert means to a NumPy array
# ========================================

## Fit a regression line to the cells' x, y, z coordinates using the eigenvector method
# Compute the mean of the points
mean_point = np.mean(cells_array, axis=0)

# Center the points by subtracting the mean
centered_points = cells_array - mean_point

# Compute the covariance matrix
cov_matrix = np.cov(centered_points, rowvar=False)

# Compute the eigenvalues and eigenvectors
eigenvalues, eigenvectors = np.linalg.eig(cov_matrix)

# The eigenvector corresponding to the largest eigenvalue is the direction of the line
line_direction = eigenvectors[:, np.argmax(eigenvalues)]
# Ensure the second value of line_direction is positive
if line_direction[1] < 0:
    line_direction = -line_direction

# Project all points onto the line direction
projections = np.dot(centered_points, line_direction)

deepest_point = np.max(projections)
probe_length = 787.5

# Generate end points in the regression line
t = np.linspace(deepest_point-probe_length, deepest_point, num=2)  # Parameter for line generation
regression_line_ends = mean_point + t[:, np.newaxis] * line_direction


print(f"Mean point: {mean_point}")
print(f"Line direction: {line_direction}")
print(f"Regression line ends: {regression_line_ends}")
# ========================================

## Store regression line points in a CSV file ==============
# Create output filename by appending suffix to the input csv_file
base, ext = os.path.splitext(csv_file)
output_csv = f"{base}_fit{ext}"

# Save regression_line_ends to CSV
with open(output_csv, mode='w', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(['ccf_ap', 'ccf_dv', 'ccf_ml'])
    for point in regression_line_ends:
        writer.writerow(point)
print(f"Regression line ends saved to: {output_csv}")
# ========================================

