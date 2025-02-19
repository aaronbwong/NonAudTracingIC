import pandas as pd
from tkinter import filedialog

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
    """
    Opens a file dialog to select a CSV file and returns the file path.
    """
    csv_file = filedialog.askopenfilename(
        title="Select CSV file with cell coordinates",
        filetypes=(("CSV files", "*.csv"), ("All files", "*.*"))
    )
    return csv_file
