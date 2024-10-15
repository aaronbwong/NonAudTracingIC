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

# Notes on Coordinate Systems 
There are a number of (standard) ways to represent a 3D volume in a data file or coordinate system. The convention varies across disciplines and different datasets. Two important pieces of information are:
1. how the 3 dimensions are ordered ("Voxel-Order"), and
2. which direction is defined as positive ("Orientation").

Additionally, some coordinate system uses a reference point not at the corner of the volume as origin (0,0,0), e.g. relative to Bregma.

## Terminology
*This section is based on: [Orientation and Voxel-Order Terminology](http://www.grahamwideman.com/gw/brain/orientation/orientterms.htm)*
*Some additional resources at [NiBabel](https://nipy.org/nibabel/neuro_radio_conventions.html) and [3D Slicer](https://www.slicer.org/wiki/Coordinate_systems).
Basic directional:
- **L**eft and **R**ight
- **S**uperior and **I**nferior
- **A**nterior and **P**osterior

A specification of RAS for example, illustrates that left-right is the first dimension, anterior-posterior is the second, and superior-inferior is the thrid. The R means that **R**ight is the positive direction. The same goes for A and S, which indicate that **A**nterior and **S**uperior are the positive directions of their respective axes.

Left-hand and right-handed orientations refers to how the 3 ordered positive direction are related to each other. One can check it with the thumb-index-middle fingers of each hand.

## Specification of relevant dataset/systems

### The [QUINT workflow](https://quint-workflow.readthedocs.io/en/latest/)
- RAS 
- origin: corner

### Matlab 3D display
- XYZ with right-hand orientation.

### Native Allen CCFv3
- PIR
- origin: corner

### Cortex-lab processed Allen CCFv3