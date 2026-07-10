# Pipeline: Combine ABBA alignment and CellCounter data to fit a Probe Tract
## prerequisites
### Data
1. An ABBA state containing alignments with appropriately linked QuPath project file and image file(s)
2. A directory containing output XML files from ImageJ/FIJI's CellCounter plug-in.

### software
1. a python environment with [abba-python](https://github.com/BIOP/abba_python) installed
2. (optinal for display) a python environment with [brainrender](https://github.com/brainglobe/brainrender) installed.

## Pipeline
1. Run src\summary\AW_ABBA_probetract2CCF.py. Output CSV files to a directory of choice.
2. Run src\summary\AW_fit_display_probetract.py. Selecting CSV files from the output directory above.

