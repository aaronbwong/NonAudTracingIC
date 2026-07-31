# Pipeline: Combine ABBA alignment and CellCounter data to fit a Probe Tract
## prerequisites
### Data
1. An ABBA state containing alignments with appropriately linked QuPath project file and image file(s)
2. A directory containing output XML files from ImageJ/FIJI's CellCounter plug-in.

### software
1. a python environment with [abba-python](https://github.com/BIOP/abba_python) installed. A couple of conda environmental files are provided:
    - [environment-abba11.yml](environment-abba11.yml): with a new abba-python version (0.11.0; newest as of writing) for newer alignments.
    - [environment-abba09.yml](environment-abba09.yml): with a legacy abba-python version (0.10.1.dev0) for alignment done in older versions (0.9.X)
2. (optinal for display) a python environment with [brainrender](https://github.com/brainglobe/brainrender) installed.
    - [environment-brainrender.yml](environment-brainrender.yml): for running brainrender

## Pipeline
1. Run src\summary\AW_ABBA_probetract2CCF.py. Output CSV files to a directory of choice. (use an environment with abba-python installed.)
2. Run src\summary\AW_fit_display_probetract.py. Selecting CSV files from the output directory above. (to display tract, use an environment with brainrender installed, e.g. [environment-brainrender.yml](environment-brainrender.yml))

