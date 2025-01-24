
print("Importing generic libraries...")
import os
import time
from pathlib import Path
from tkinter import Tk, filedialog
from tkinter.simpledialog import askstring

import xml.etree.ElementTree as ET
from jpype.types import JString, JArray, JDouble

print("Importing scientific libraries...")
import pandas as pd

print("Importing ABBA...")
from abba_python.abba import Abba
print("Libraries loaded.")


def process_data(cell_count_path, mp, output_path, atlas_pixel_size=10):
    # Initialize an empty dictionary to store DataFrames
    dataframes = {}

    # initiate the coord arrays
    DoubleArray = JArray(JDouble)

    coordInImage = DoubleArray(3)
    coordInCCF = DoubleArray(3)

    # Ensure the output path exists
    if not os.path.exists(output_path):
        os.makedirs(output_path)

    print(f"Processing {mp.getSlices().size()} slices...")
    print(f"-----------------------------------")

    # Loop through data files
    for idx in range(0, mp.getSlices().size()):
        # Get image name
        image_name = mp.getSlices().get(idx).getName()

        # Get mouse name
        if idx == 0:
            # Deduce the mouse name from the first 11 characters in image_name
            mouse_name = image_name[:11]
            # Create an input dialog for the user to confirm or adjust the mouse_name
            mouse_name = askstring("Mouse Name", "Confirm or adjust the mouse name:", initialvalue=mouse_name)

        print(f"Image file: {image_name}")
        # Get transformation
        transform_pix_to_atlas = mp.getSlices().get(idx).getSlicePixToCCFRealTransform()

        # Read in data
        xml_name = 'CellCounter_' + image_name[:-4] + '.xml'
        file_path = os.path.join(cell_count_path, xml_name)
        print(f"reading cell counter xml: {xml_name}")
        tree = ET.parse(file_path)
        root = tree.getroot()
        marker_data = root.find('Marker_Data')

        # Loop through data
        for marker_type in marker_data.findall('Marker_Type'):
            marker_name = marker_type.find('Name').text
            markers = marker_type.findall('Marker')
            print(f"Marker name: {marker_name}, Number of markers: {len(markers)}")

            # Initialize the DataFrame if it doesn't exist
            if marker_name not in dataframes:
                dataframes[marker_name] = pd.DataFrame(columns=["mouse", "image_name", "image_x", "image_y", "ccf_ap", "ccf_dv", "ccf_ml"])

            # Collect data
            data = []
            for marker in markers:
                x = int(marker.find('MarkerX').text)
                y = int(marker.find('MarkerY').text)
                # print(coordInImage)
                # print(coordInCCF)
                coordInImage[0] = x
                coordInImage[1] = y
                coordInImage[2] = 0
                #coordInCCF = [0, 0, 0]  # Initialize coordInCCF
                # print(x)
                # print(y)
                # print(coordInImage)
                # print(coordInCCF)
                transform_pix_to_atlas.inverse().apply(coordInImage, coordInCCF)
                data.append({
                    "mouse": mouse_name,
                    "image_name": image_name,
                    "image_x": x,
                    "image_y": y,
                    "ccf_ap": int(coordInCCF[0] * 1000 / atlas_pixel_size),
                    "ccf_dv": int(coordInCCF[1] * 1000 / atlas_pixel_size),
                    "ccf_ml": int(coordInCCF[2] * 1000 / atlas_pixel_size)
                })

            # Append data to the appropriate DataFrame
            dataframes[marker_name] = pd.concat([dataframes[marker_name], pd.DataFrame(data)], ignore_index=True)
        print(f"-----------------------------------")

    # Save each DataFrame to a CSV file
    for marker_name, df in dataframes.items():
        df.to_csv(os.path.join(output_path, f'{mouse_name}_{marker_name}_ABBAConvert.csv'), index=False)

    print("DataFrames saved to CSV files")


print("Asking for user input...")

# Initialize Tkinter root
root = Tk()
root.withdraw()  # Hide the root window

# Ask for the ABBA file
abba_file = filedialog.askopenfilename(
    title="Select ABBA state file",
    filetypes=(("ABBA state files", "*.abba"), ("All files", "*.*"))
)

# Get the directory one level above the abba_file
project_dir = os.path.dirname(os.path.dirname(abba_file))

# Ask for the directory for cell_count_path
cell_count_path = filedialog.askdirectory(
    title="Select directory for cell count path",
    initialdir=project_dir
)

# Ask for the directory for output_path
output_path = filedialog.askdirectory(
    title="Select directory for output path",
    initialdir=project_dir
)

print(f"ABBA file: {abba_file}")
print(f"Cell count path: {cell_count_path}")
print(f"Output path: {output_path}")

# Initialize ABBA
print("Initializing ABBA...")
print("You may have to click a window!")
abba = Abba('Adult Mouse Brain - Allen Brain Atlas V3p1') # You may have to click a window!

# Load the ABBA file
print("Loading ABBA file...")
abba.state_load(abba_file) # full absolute path needed
print("ABBA file loaded.")

print("Getting the Mouse Project data...")
mp = abba.mp

print("Processing data...")
process_data(cell_count_path, mp, output_path, atlas_pixel_size=10)

print("Closing abba session...")
abba.close()

print(f"Script {__file__} has completed.")