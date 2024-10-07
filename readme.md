# Tracing and analysis
This is the readme file accompanying the analysis pipeline for a anatomical tracing experiment.

## General pipeline
1. ```image-preparation```: Format and export images from proprietary file formats (e.g. .czi from Zeiss microscope) into general Tiffs format for aligning to reference atlas (AllenCCF) and/or cell counting.
2. ```alignment```: Align each image or series of image to the reference atlas. Apply and store appropriate transformation.
3. ```cell-count```: Mark cells or objects of interest on images. Either manually or via an algorithm. Input might be images of original or downsampled quality (to be determined).
4. ```summary```: combining data from previous two steps (```alignment``` and ```cell-count```).

## Dependency
- AP_histology requires "Curve Fitting Toolbox"
- AP_histology requires [ColorBrewer/BrewerMap](https://github.com/DrosteEffect/BrewerMap) by DrosteEffect
- DeepSlice


## Installation of DeepSlice
- Python 3.7 is needed (not later, e.g. 3.11 as of Nov 2023) 
- This can be done by installing miniconda or anaconda (search for installation file from archive)
- Then `pip install DeepSlice` should work.