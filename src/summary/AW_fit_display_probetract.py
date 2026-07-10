
# Import functions from the new module
from utils.csv_utils import get_points_df_from_multiple_csv, ask_multiple_csv_files
import os
import csv
import numpy as np
from pathlib import Path
from tkinter import Tk, filedialog

scale_to_um = 1000

# Read points from CSV file ============
csv_files = ask_multiple_csv_files()

# Ask the user where to save the output CSV files
root = Tk()
root.withdraw()
output_dir = filedialog.askdirectory(title="Select output directory for fit CSV files")
root.destroy()
if not output_dir:
    print("No output directory selected. Using current working directory.")
    output_dir = Path.cwd()
else:
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

print(f"Fit output directory: {output_dir}")


# Ask whether a display is needed (y/n)
try:
    _resp = input("Display in brainrender? (y/n) [n]: ").strip().lower()
except Exception:
    _resp = 'n'
show_display = _resp in ('y', 'yes')
print(f"Display in brainrender: {show_display}")

if show_display:
    # import brainrender and related modules only if display is needed
    import brainrender
    from brainrender import Scene
    from brainrender.actors import Points,Line
    from brainglobe_space  import AnatomicalSpace
   
    # setup scene
    brainrender.settings.SHADER_STYLE = "plastic"
    scene = Scene(title="Labelled points")
    ic = scene.add_brain_region("IC", alpha=0.3)
    colors =["red","blue","green","purple","orange","pink"]
    i = 0  # Initialize color index

probe_track_tbl = get_points_df_from_multiple_csv(csv_files, scale_to_um)
type_name_list = probe_track_tbl['marker_name'].unique()
for i_type, type_name in enumerate(type_name_list):
    df = probe_track_tbl[probe_track_tbl['marker_name'] == type_name]
    probe_track = df[['ccf_ap', 'ccf_dv', 'ccf_ml']].to_numpy()
    if len(probe_track) == 0:
        print(f"No data found for marker '{type_name}'. Skipping...")
        continue
    cells_array = np.array(np.vstack(probe_track))  # Convert means to a NumPy array

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
    shallowest_point = np.min(projections)
    probe_length = 787.5

    # Generate end points in the regression line
    t = np.linspace(deepest_point-probe_length, deepest_point, num=2)  # Parameter for line generation
    probe_line_ends = mean_point + t[:, np.newaxis] * line_direction
    t = np.linspace(shallowest_point, deepest_point, num=2)  # Parameter for line generation
    regression_line_ends = mean_point + t[:, np.newaxis] * line_direction


    print(f"Mean point: {mean_point}")
    print(f"Line direction: {line_direction}")
    print(f"Regression line ends: {regression_line_ends}")
    # ========================================

    ## Store regression line points in a CSV file ==============
    # Create output filename by appending suffix to the input csv_file
    output_csv = output_dir / f"CoordCCF_{type_name}_fit.csv"

    # Save regression_line_ends to CSV
    with open(output_csv, mode='w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['ccf_ap', 'ccf_dv', 'ccf_ml'])
        for point in regression_line_ends:
            writer.writerow(point)
    print(f"Regression line ends saved to: {output_csv}")
    # ========================================

    # add display if needed
    if show_display:
        scene.add(Points(probe_track, name=type_name, colors=colors[i_type % len(colors)], radius=30, alpha=0.7))
        scene.add(Line(regression_line_ends, name=f"{type_name} Fitted line", linewidth=1.5, color="#555555"))
        scene.add(Line(probe_line_ends, name=f"{type_name} Fitted line", linewidth=5, color=colors[i_type % len(colors)]))
    # ========================================

if show_display:
    # Render the scene
    scene.render()