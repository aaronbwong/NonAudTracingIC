print("Importing generic libraries...")
import os
import time
from pathlib import Path
from tkinter import Tk, filedialog
from tkinter.simpledialog import askstring
import re

import xml.etree.ElementTree as ET
from jpype.types import JString, JArray, JDouble

print("Importing scientific libraries...")
import pandas as pd

print("Importing ABBA...")
from abba_python.abba import Abba
print("Libraries loaded.")

from PIL import Image
import warnings
import numpy as np

# def process_single_slice(mp,idx,xml_path):

def get_slice_transform(mp, idx):
    # Get the transformation matrix for the slice
    transform_pix_to_atlas = mp.getSlices().get(idx).getSlicePixToCCFRealTransform()
    return transform_pix_to_atlas

def transform_coordinates(image_xy, transform_pix_to_atlas):
    # Transform the coordinates from image space to atlas space
    # image_xy is a tuple (x, y)

    # initiate the coord arrays
    DoubleArray = JArray(JDouble)
    coordInImage = DoubleArray(3)
    coordInCCF = DoubleArray(3)
    coordInImage[0] = image_xy[0]
    coordInImage[1] = image_xy[1]
    coordInImage[2] = 0
    transform_pix_to_atlas.inverse().apply(coordInImage, coordInCCF)
    return coordInCCF

def load_marker_xml(xml_path): # Load the XML file and parse it
    tree = ET.parse(xml_path)
    root = tree.getroot()
    image_Filename = root.find('Image_Properties').find('Image_Filename').text
    marker_xml = root.find('Marker_Data')
    marker_data = {}
    for marker_type in marker_xml.findall('Marker_Type'):
        marker_name = marker_type.find('Name').text
        markers = marker_type.findall('Marker')
        data = []
        for marker in markers:
            x = int(marker.find('MarkerX').text)
            y = int(marker.find('MarkerY').text)
            data.append({
                    "image_x": x,
                    "image_y": y
                })
        if len(data) > 0:
            marker_data[marker_name] = data
    return marker_data, image_Filename

def transform_marker_data(marker_data, transform_pix_to_atlas):
    transformed_data = {}
    for marker_name, data in marker_data.items():
        transformed_data[marker_name] = []
        for marker in data:
            image_xy = (marker["image_x"], marker["image_y"])
            coordInCCF = transform_coordinates(image_xy, transform_pix_to_atlas)
            transformed_data[marker_name].append({
                "image_x": image_xy[0],
                "image_y": image_xy[1],
                "ccf_ap": float(coordInCCF[0]),
                "ccf_dv": float(coordInCCF[1]),
                "ccf_ml": float(coordInCCF[2])
            })
    return transformed_data


# Initialize ABBA
print("Initializing ABBA...")
# print("You may have to click a window!")
x_axis = 'RL' # 'LR' or 'RL'
abba = Abba('Adult Mouse Brain - Allen Brain Atlas V3p1',
            x_axis=x_axis) # You may have to click a window!

print(f"X_axis: {abba.x_axis}\nY_axis: {abba.y_axis}\nZ_axis: {abba.z_axis}\n")
print("ABBA initialized.")

# Initialize Tkinter root
root = Tk()
root.withdraw()  # Hide the root window

# Ask for the ABBA file
abba_file = filedialog.askopenfilename(
    title="Select ABBA state file",
    filetypes=(("ABBA state files", "*.abba"), ("All files", "*.*"))
)
root.destroy()
if not abba_file:
    print("No ABBA file selected. Exiting...")
    exit()

# Load the ABBA file
print("Loading ABBA file...")
abba.state_load(abba_file) # full absolute path needed
print("ABBA file loaded.")

print("Getting the Mouse Project data...")
mp = abba.mp

print("Number of slices: ", mp.getSlices().size())

# Get the directory one level above the abba_file
project_dir = os.path.dirname(os.path.dirname(abba_file))
output_folder = Path(os.path.join(project_dir,"output"))
output_folder.mkdir(exist_ok=True)

scene_number_array = np.full(mp.getSlices().size(), np.nan)
for idx in range(0, mp.getSlices().size()):
    # Get image name
    image_name = str(mp.getSlices().get(idx).getName())
    filetype = 'czi'
    # Read in data
    if filetype == 'czi':
        pattern = r'Scene #(\d+)'
        match = re.search(pattern, image_name)
        if match:
            scene_number = int(match.group(1))              
            scene_number_array[idx] = scene_number

print("Scene numbers for slices:")
print(scene_number_array)
print(f"Number of scenes: {len(scene_number_array)}")

# Prompt user for start and end slice numbers
root = Tk()
root.withdraw()
start_scene = askstring("Slice Range", f"Enter start scene number (1 to {mp.getSlices().size()}):")
end_scene = askstring("Slice Range", f"Enter end scene number (1 to {mp.getSlices().size()}):")
root.destroy()

try:
    start_slice = int(np.where(scene_number_array == int(start_scene))[0][0])
    end_slice = int(np.where(scene_number_array == int(end_scene))[0][0])
except (TypeError, ValueError):
    print("Invalid input for slice range. Exiting...")
    exit()

if start_slice > end_slice:
    (start_slice, end_slice) = (end_slice, start_slice)

if start_slice < 0 or end_slice >= mp.getSlices().size():
    print("Invalid slice range. Exiting...")
    exit()

for idx in range(start_slice, end_slice+1):
    # # Find the index in scene_number_array where scene_number_array[idx] == scene_number
    # idx = int(np.where(scene_number_array == scene_number)[0][0])
    
    # Get the image name for the current slice
    image_name = mp.getSlices().get(idx).getName()
    print(f"Processing slice {idx}: {image_name}")

    # Ask for an XML file using the file open dialog
    root = Tk()
    root.withdraw()  # Hide the root window
    xml_file_path = filedialog.askopenfilename(
        title=f"Select XML file for slice {idx} ({image_name})",
        filetypes=[("XML files", "*.xml")]
    )
    root.destroy()

    # If no file is selected, continue to the next slice
    if not xml_file_path:
        print(f"No file selected for slice {idx}. Skipping...")
        continue
    xml_filename = os.path.basename(xml_file_path)

    # Load marker data from the XML file
    marker_data, image_Filename = load_marker_xml(xml_file_path)
    print(f"marker_data number of marker types: {len(marker_data)}")

    # Get the transformation matrix for the slice
    transform_pix_to_atlas = get_slice_transform(mp, idx)

    # Perform the transformation
    transformed_data = transform_marker_data(marker_data, transform_pix_to_atlas)
    print(f"transformed_data number of marker types: {len(transformed_data)}")

    # Convert the transformed data to a DataFrame
    transformed_df = pd.DataFrame([
        {
            "marker_name": marker_name,
            "image_name": image_name,
            "image_Filename": image_Filename,
            "xml_name": xml_filename,
            **marker
        }
        for marker_name, markers in transformed_data.items()
        for marker in markers
    ])
    print(transformed_df)

    # Save the resulting DataFrame to the output folder
    if xml_filename.startswith("CellCounter_"):
        base_filename = xml_filename[len("CellCounter_"):-4]
    output_file = output_folder / f"CoordCCF_{base_filename}.csv"
    transformed_df.to_csv(output_file, index=False)
    print(f"Transformed data saved to {output_file}")
print("All slices processed.")
abba.close()
print("Closing ABBA...")
print("Script finished.")
exit()