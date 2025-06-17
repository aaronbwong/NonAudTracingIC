
# Import functions from the new module
from utils.csv_utils import get_points_from_csv, ask_csv_file
import numpy as np

import brainrender
from brainrender import Scene
from brainrender.actors import Points,Line

scale_to_um = 1000

# Read points from CSV file ============
csv_files = ask_csv_file()
probe_track = get_points_from_csv(csv_files, scale_to_um,marker_name="Type 1")
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

# Generate points along the regression line
t = np.linspace(deepest_point-probe_length, deepest_point, num=100)  # Parameter for line generation
regression_line_points = mean_point + t[:, np.newaxis] * line_direction

print(f"Mean point: {mean_point}")
print(f"Line direction: {line_direction}")
# Print the regression line points
print(f"Regression line points: {regression_line_points}")
# ========================================


## Rendering in brainrender ==============
brainrender.settings.SHADER_STYLE = "plastic"

scene = Scene(title="Labelled points")
# Add region to scene
ic = scene.add_brain_region("IC", alpha=0.3)

# ipts = scene.root.mesh.inside_points(regression_line_points).coordinates

scene.add(Points(regression_line_points, name="Probe", colors="black"))
# scene.add(Line(regression_line_points, name="Probe", linewidth=10, color="black"))
scene.add(Points(probe_track, name="Track", colors="red"))

scene.content
scene.render()
# ========================================