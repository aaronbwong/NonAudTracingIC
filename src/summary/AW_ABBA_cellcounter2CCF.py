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

# Suppress DecompressionBombWarning
warnings.simplefilter('ignore', Image.DecompressionBombWarning)

def find_cell_counter_file(cell_count_path, base_name, scene_number):
    # List all files in the directory
    files = os.listdir(cell_count_path)
    
    # Filter files that start with the given prefix
    prefix = 'CellCounter_' + base_name+'('+str(scene_number)+')'
    matching_files = [f for f in files if f.startswith(prefix) and f.endswith('.xml')]
    
    if len(matching_files) == 1:
        return matching_files[0]
    else:
        print(f"Error: Found {len(matching_files)} matching files for {prefix}*")
        return None

def get_image_size(image_path, image_filename):
    file_path = os.path.join(image_path, image_filename + '.tif')
    with Image.open(file_path) as img:
        return img.width, img.height

def process_data(cell_count_path, mp, rotation_data, output_path, atlas_pixel_size=10):
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

    # check file name/format
    pattern = r'(.*)\.czi - Scene #'
    image_name = str(mp.getSlices().get(0).getName())
    match = re.search(pattern, image_name)
    if match:
        filetype = 'czi'
        base_name = match.group(1)
    else:
        filetype = 'tif'
        

    # Loop through data files
    for idx in range(0, mp.getSlices().size()):
        # Get image name
        image_name = str(mp.getSlices().get(idx).getName())

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
        if filetype == 'czi':
            pattern = r'Scene #(\d+)'
            match = re.search(pattern, image_name)
            if match:
                scene_number = int(match.group(1))
                xml_name = find_cell_counter_file(cell_count_path, base_name, scene_number)
        else:
            xml_name = 'CellCounter_' + image_name[:-4] + '.xml'
            
        file_path = os.path.join(cell_count_path, xml_name)
        print(f"reading cell counter xml: {xml_name}")
        tree = ET.parse(file_path)
        root = tree.getroot()
        image_Filename = root.find('Image_Properties').find('Image_Filename').text
        marker_data = root.find('Marker_Data')

        # Check rotation and flipping
        image_base_name = os.path.splitext(image_Filename)[0]
        rotation_row = rotation_data[rotation_data['TIFF'] == image_base_name]
        rotated = rotation_row['Rotated'].iloc[0] == 'yes'
        flipped = rotation_row['Flipped'].iloc[0] == 'yes'
        print(f"Image {image_Filename} - Rotated: {rotated}, Flipped: {flipped}")

        # Loop through data
        for marker_type in marker_data.findall('Marker_Type'):
            marker_name = marker_type.find('Name').text
            markers = marker_type.findall('Marker')
            print(f"Marker name: {marker_name}, Number of markers: {len(markers)}")

            # Initialize the DataFrame if it doesn't exist
            if marker_name not in dataframes:
                dataframes[marker_name] = pd.DataFrame(columns=["mouse", "image_name", "image_Filename", "xml_name", "image_x", "image_y", "ccf_ap", "ccf_dv", "ccf_ml"])

            # Collect data
            data = []
            for marker in markers:
                x = int(marker.find('MarkerX').text)
                y = int(marker.find('MarkerY').text)
                if filetype == 'czi':
                    # Apply rotation and flipping if necessary
                    if flipped:
                        x =  rotation_row['Width'].iloc[0] - x + 1 # Flip x coordinate
                    if rotated:
                        x, y = y, rotation_row['Width'].iloc[0] - x + 1  # Rotate 90 degrees left based on image size (1-based)
                coordInImage[0] = x
                coordInImage[1] = y
                coordInImage[2] = 0
                transform_pix_to_atlas.inverse().apply(coordInImage, coordInCCF)
                data.append({
                    "mouse": mouse_name,
                    "image_name": image_name,
                    "image_Filename": image_Filename,
                    "xml_name": xml_name,
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

# Ask for the image rotation CSV file
rotation_file = filedialog.askopenfilename(
    title="Select rotation CSV file",
    filetypes=(("CSV files", "*.csv"), ("All files", "*.*"))
)

# Get the directory one level above the abba_file
project_dir = os.path.dirname(os.path.dirname(abba_file))

# Ask for the image path
image_path = filedialog.askdirectory(
    title="Select directory for image path",
    initialdir=project_dir
)

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
print(f"Rotation file: {rotation_file}")
print(f"Image path: {image_path}")
print(f"Cell count path: {cell_count_path}")
print(f"Output path: {output_path}")

# Read the CSV file and remove any trailing spaces from column names
rotation_data = pd.read_csv(rotation_file)
rotation_data.columns = rotation_data.columns.str.strip() # Remove any trailing spaces
print(f"Rotation data loaded: {rotation_data.shape[0]} rows")

# Initialize columns for width and height
rotation_data['Width'] = 0
rotation_data['Height'] = 0

for idx in range(rotation_data.shape[0]):
    image_Filename = rotation_data.iloc[idx]['TIFF']

    # Get image size
    width, height = get_image_size(image_path, image_Filename)
    rotation_data.at[idx, 'Width'] = width
    rotation_data.at[idx, 'Height'] = height
    # print(f"Image {image_Filename} - Width: {width}, Height: {height}")

# Save the updated rotation data to a new CSV file
updated_rotation_file = os.path.join(os.path.dirname(rotation_file), 'Updated_' + os.path.basename(rotation_file))
rotation_data.to_csv(updated_rotation_file, index=False)
print(f"Updated rotation data saved to {updated_rotation_file}")

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
process_data(cell_count_path, mp, rotation_data, output_path, atlas_pixel_size=10)

print("Closing abba session...")
abba.close()

print(f"Script {__file__} has completed.")