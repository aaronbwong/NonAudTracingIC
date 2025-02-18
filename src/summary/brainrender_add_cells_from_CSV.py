import random
from pathlib import Path
from tkinter import filedialog

import numpy as np
import pandas as pd
from myterial import orange
from rich import print

import brainrender
from brainrender import Scene
from brainrender.actors import Points

print(f"[{orange}]Running example: {Path(__file__).name}")

atlas_pixel_size = 10

def get_points_from_csv(file_path, atlas_pixel_size):
    """
    Reads points from a CSV file and returns them as a numpy array.
    Multiplies coordinates with atlas_pixel_size.
    XYZ = PIL
    """
    df = pd.read_csv(file_path)
    points = df[['ccf_ap', 'ccf_dv', 'ccf_ml']].to_numpy()
    points *= atlas_pixel_size
    return points

def ask_csv_file():

    csv_file = filedialog.askopenfilename(
        title="Select CSV file with cell coordinates",
        filetypes=(("CSV files", "*.csv"), ("All files", "*.*"))
    )
    return csv_file

csv_file = ask_csv_file()

# Read points from CSV file
cells = get_points_from_csv(csv_file, atlas_pixel_size)

brainrender.settings.SHADER_STYLE = "plastic"

scene = Scene(title="Labelled cells")

# Add region to scene
ic = scene.add_brain_region("IC", alpha=0.15)

# Select IC cells
ic_cells = ic.mesh.inside_points(cells).vertices

# Add cells to scene
scene.add(Points(cells, name="All CELLS", colors="red",radius=30,alpha=0.3))
scene.add(Points(ic_cells, name="IC CELLS", colors="steelblue",radius=30,alpha=0.7))

# render
scene.content
scene.render()
