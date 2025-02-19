from pathlib import Path

from myterial import orange
from rich import print

import brainrender
from brainrender import Scene
from brainrender.actors import Points

# Import functions from the new module
from utils.csv_utils import get_points_from_csv, ask_csv_file

print(f"[{orange}]Running example: {Path(__file__).name}")

atlas_pixel_size = 10

# Read points from CSV file
cells = get_points_from_csv(ask_csv_file(), atlas_pixel_size)

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
