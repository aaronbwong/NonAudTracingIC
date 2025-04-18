from pathlib import Path

from myterial import orange
from rich import print

import brainrender
from brainrender import Scene
from brainrender.actors import Points,Line

# Import functions from the new module
from utils.csv_utils import get_points_list_from_multiple_csv, get_points_from_multiple_csv, ask_multiple_csv_files
import numpy as np

print(f"[{orange}]Running example: {Path(__file__).name}")

scale_to_um = 1000

# Read points from CSV file
csv_files = ask_multiple_csv_files()
IC_outline = get_points_list_from_multiple_csv(csv_files, scale_to_um,marker_name="IC")
probe_track = get_points_list_from_multiple_csv(csv_files, scale_to_um,marker_name="Type 1")

brainrender.settings.SHADER_STYLE = "plastic"

scene = Scene(title="Labelled points")

# Add region to scene
ic = scene.add_brain_region("IC", alpha=0.15)
# Add region to scene
mb = scene.add_brain_region("MB", alpha=0.10, color="blue")

# print(type(probe_track))
# Fit a regression line to the cells' x, y, z coordinates using the eigenvector method
cells_array = np.array(np.vstack(probe_track))  # Convert cells to a NumPy array

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

# Generate points along the regression line
t = np.linspace(-1000, 1000, num=500)  # Parameter for line generation
regression_line_points = mean_point + t[:, np.newaxis] * line_direction
line = Line(regression_line_points, name="Fitted line", linewidth=3, color="black")

# You can add this as a line to the scene for visualization
scene.add(line)

colors =["red","blue","green","orange","purple","pink"]
# Add cells to scene
for i, points in enumerate(probe_track):
    # Add each set of points as a separate actor
    scene.add(Points(points, name=f"Probe track {i}", colors=colors[i], radius=30, alpha=0.7))
# scene.add(Points(probe_track, name="Probe track", colors="red",radius=30,alpha=0.3))
for i, points in enumerate(IC_outline):
    scene.add(Points(points, name="IC outline", colors=colors[i],radius=30,alpha=0.3))
# scene.add(Points(ic_cells, name="IC CELLS", colors="steelblue",radius=30,alpha=0.7))

# render
# scene.content
scene.add_label(ic, "IC")
scene.add_label(line, "probe track")
scene.render()
