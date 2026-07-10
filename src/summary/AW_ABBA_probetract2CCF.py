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


def resolve_slice_idx(slice_metadata, scene_number):
    matches = slice_metadata.loc[slice_metadata["scene_number"] == int(scene_number), :]
    if matches.empty:
        raise ValueError(f"Scene number {scene_number} was not found in the slice metadata table.")
    return int(matches.index[0])


def infer_scene_number(text):
    """Infer a slice/scene number from a string using common naming conventions."""
    if text is None:
        return None, None

    text = str(text)
    patterns = [
        r"(?i)(?:^|[^A-Za-z])(?:scene|s|tr|slice)\s*#?\s*(\d+)",
        r"(?i)_s(\d+)",
        r"(?i)\((\d+)\)",
        r"(?i)tr\s*(\d+)",
        r"(?i)slice\s*(\d+)",
        r"(?i)scene\s*#\s*(\d+)",
        r"(\d+)",
    ]

    for pattern in patterns:
        match = re.search(pattern, text)
        if match:
            return int(match.group(1)), pattern

    return None, None


def build_slice_metadata_table(mp):
    """Create a reusable table of slice metadata and infer a scene number from the image name."""
    records = []

    for idx in range(mp.getSlices().size()):
        image_name = str(mp.getSlices().get(idx).getName())
        scene_number, matched_pattern = infer_scene_number(image_name)
        if scene_number is None:
            scene_number = idx + 1
            matched_pattern = "slice_index_fallback"

        records.append({
            "slice_idx": idx,
            "image_name": image_name,
            "scene_number": scene_number,
            "matched_pattern": matched_pattern,
        })

    slice_metadata = pd.DataFrame(records).set_index("slice_idx")
    return slice_metadata


def build_xml_metadata_table(xml_dir):
    """Scan XML files in a directory and infer a scene number from the filename and embedded image name."""
    xml_files = sorted(Path(xml_dir).glob("*.xml"))
    records = []

    for xml_path in xml_files:
        image_filename = None
        try:
            tree = ET.parse(xml_path)
            root = tree.getroot()
            image_props = root.find("Image_Properties")
            if image_props is not None:
                image_node = image_props.find("Image_Filename")
                if image_node is not None and image_node.text:
                    image_filename = image_node.text
        except Exception as exc:
            print(f"Could not parse {xml_path.name}: {exc}")

        scene_number, matched_pattern = infer_scene_number(xml_path.name)
        if scene_number is None and image_filename is not None:
            scene_number, matched_pattern = infer_scene_number(image_filename)

        records.append({
            "xml_path": str(xml_path),
            "xml_name": xml_path.name,
            "image_filename": image_filename or "",
            "scene_number": scene_number,
            "matched_pattern": matched_pattern,
        })

    return pd.DataFrame(records)


def build_slice_xml_match_table(slice_metadata, xml_metadata):
    """Create a preview table of which XML files likely correspond to which slices."""
    rows = []
    for slice_idx, slice_row in slice_metadata.iterrows():
        slice_scene = slice_row["scene_number"]
        if xml_metadata.empty:
            rows.append({
                "slice_idx": int(slice_idx),
                "slice_scene_number": slice_scene,
                "slice_image_name": slice_row["image_name"],
                "xml_name": None,
                "xml_scene_number": None,
                "match_status": "unmatched",
                "xml_path": None,
            })
            continue

        matched_rows = xml_metadata.loc[xml_metadata["scene_number"] == slice_scene]
        if len(matched_rows) == 1:
            matched_row = matched_rows.iloc[0]
            match_status = "matched"
        elif len(matched_rows) > 1:
            matched_row = matched_rows.iloc[0]
            match_status = "ambiguous"
        else:
            matched_row = None
            match_status = "unmatched"

        rows.append({
            "slice_idx": int(slice_idx),
            "slice_scene_number": slice_scene,
            "slice_image_name": slice_row["image_name"],
            "xml_name": matched_row["xml_name"] if matched_row is not None else None,
            "xml_scene_number": matched_row["scene_number"] if matched_row is not None else None,
            "match_status": match_status,
            "xml_path": matched_row["xml_path"] if matched_row is not None else None,
        })

    return pd.DataFrame(rows)


## --- MAIN PROGRAM ---

# 1) Initialize ABBA and load the Mouse Project data
# Initialize ABBA
print("Initializing ABBA...")
# print("You may have to click a window!")
x_axis = 'LR' # 'LR' or 'RL'
abba = Abba('Adult Mouse Brain - Allen Brain Atlas V3p1',
            x_axis=x_axis) # You may have to click a window!

print(f"X_axis: {abba.x_axis}\nY_axis: {abba.y_axis}\nZ_axis: {abba.z_axis}\n")
print("ABBA initialized.")

# 2) Ask the user for the ABBA state file and load it
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

# Ask for the directory for output_path
output_dir = filedialog.askdirectory(
    title="Select directory for output path",
    initialdir=project_dir
)
output_folder = Path(os.path.join(output_dir, "output"))
output_folder.mkdir(exist_ok=True)

# Ask for the directory containing XML files
xml_dir = filedialog.askdirectory(
    title="Select directory containing XML files",
    initialdir=project_dir
)
if not xml_dir:
    print("No XML directory selected. Exiting...")
    exit()

slice_metadata = build_slice_metadata_table(mp)
print("Slice metadata table:")
print(slice_metadata[["image_name", "scene_number", "matched_pattern"]].to_string())
print(f"Number of slices: {len(slice_metadata)}")

xml_metadata = build_xml_metadata_table(xml_dir)
if xml_metadata.empty:
    print("No XML files were found in the selected directory. Exiting...")
    exit()

print("XML metadata table:")
print(xml_metadata[["xml_name", "image_filename", "scene_number", "matched_pattern"]].to_string(index=False))
print(f"Number of XML files: {len(xml_metadata)}")

match_table = build_slice_xml_match_table(slice_metadata, xml_metadata)
preview_rows = match_table.head(20)
print("XML-to-slice match preview:")
print(preview_rows[["slice_idx", "slice_scene_number", "slice_image_name", "xml_name", "xml_scene_number", "match_status"]].to_string(index=False))
if len(match_table) > len(preview_rows):
    print(f"... and {len(match_table) - len(preview_rows)} more rows")

# Prompt user for start and end slice numbers
root = Tk()
root.withdraw()
start_scene = askstring("Slice Range", f"Enter start scene number (1 to {mp.getSlices().size()}):")
end_scene = askstring("Slice Range", f"Enter end scene number (1 to {mp.getSlices().size()}):")
root.destroy()

try:
    start_slice = resolve_slice_idx(slice_metadata, start_scene)
    end_slice = resolve_slice_idx(slice_metadata, end_scene)
except (TypeError, ValueError):
    print("Invalid input for slice range. Exiting...")
    exit()

if start_slice > end_slice:
    (start_slice, end_slice) = (end_slice, start_slice)

if start_slice < 0 or end_slice >= mp.getSlices().size():
    print("Invalid slice range. Exiting...")
    exit()

for idx in range(start_slice, end_slice + 1):
    image_name = str(slice_metadata.loc[idx, "image_name"])
    print(f"Processing slice {idx}: {image_name}")

    match_row = match_table.loc[match_table["slice_idx"] == idx]
    if match_row.empty:
        print(f"No match information found for slice {idx}. Skipping...")
        continue

    match_info = match_row.iloc[0]
    if not match_info["xml_path"]:
        print(f"No matching XML file found for slice {idx}. Skipping...")
        continue

    xml_file_path = match_info["xml_path"]
    xml_filename = os.path.basename(xml_file_path)
    print(f"Using XML file: {xml_filename} (match status: {match_info['match_status']})")

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
    base_filename = Path(xml_filename).stem
    if base_filename.startswith("CellCounter_"):
        base_filename = base_filename[len("CellCounter_"):]
    output_file = output_folder / f"CoordCCF_{base_filename}.csv"
    transformed_df.to_csv(output_file, index=False)
    print(f"Transformed data saved to {output_file}")

print("All slices processed.")
abba.close()
print("Closing ABBA...")
print("Script finished.")