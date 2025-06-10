import pandas as pd
import numpy as np
from tkinter import filedialog

def get_points_from_csv(file_path, scale_to_um=10,marker_name=None):
    """
    Reads points from a CSV file and returns them as a numpy array.
    Multiplies coordinates with atlas_pixel_size.
    XYZ = PIL
    """
    df = pd.read_csv(file_path)
    if marker_name is not None:
        # Filter the DataFrame based on the marker name
        df = df[df['marker_name'] == marker_name]
    points = df[['ccf_ap', 'ccf_dv', 'ccf_ml']].to_numpy()
    points *= scale_to_um
    return points

def get_points_from_multiple_csv(file_paths, scale_to_um=10,marker_name=None):
    """
    Reads points from multiple CSV files, concatenates them into a single numpy array,
    and multiplies coordinates with scale_to_mm.
    """
    all_points = []
    for file_path in file_paths:
        points = get_points_from_csv(file_path, scale_to_um=scale_to_um,marker_name=marker_name)
        all_points.append(points)
    return np.vstack(all_points)

def get_points_list_from_multiple_csv(file_paths, scale_to_um=10,marker_name=None):
    """
    Reads points from multiple CSV files, concatenates them into a single numpy array,
    and multiplies coordinates with scale_to_mm.
    """
    all_points = []
    for file_path in file_paths:
        points = get_points_from_csv(file_path, scale_to_um=scale_to_um,marker_name=marker_name)
        all_points.append(points)
    return all_points

def ask_csv_file():
    """
    Opens a file dialog to select a CSV file and returns the file path.
    """
    csv_file = filedialog.askopenfilename(
        title="Select CSV file with cell coordinates",
        filetypes=(("CSV files", "*.csv"), ("All files", "*.*"))
    )
    return csv_file

def ask_multiple_csv_files():
    """
    Opens a file dialog to select multiple CSV files and returns the file paths as a list.
    """
    csv_files = filedialog.askopenfilenames(
        title="Select CSV files with cell coordinates",
        filetypes=(("CSV files", "*.csv"), ("All files", "*.*"))
    )
    return list(csv_files)