# Image preparation

---
pipelines under considerations

- Quint (https://quint-workflow.readthedocs.io/en/latest/QuickNII.html)
- brain-mapping (https://sites.google.com/view/brain-mapping/home/code)
- AP_histology (https://github.com/petersaj/AP_histology)
	+ contains script to adjust contrast and rotate images (no documentation of the adjustment)
	+ The adjusted images are used for both alignment to atlas and analysis (e.g. probe track)
---
## Route 1
The goal of this pipeline is to yield individual TIF files, each containing a single slice. 

- The TIF files should contain metadata about pixel size. 
- Individual channels should be separable, e.g. pure red, green, blue in an RGB image or magenta/green (2-channel) in an RGB image, or multi-channel TIF image. 
- To save space, the color scales are adjusted to 8-bit. 
- There should be documentation about the adjustment
- There should be documentation about orientation and sequence of the slices, for instance when flipping or reordering was necessary for all/some slices.

These images should be good for:
1. Alignment to atlas
2. other downstream analysis (e.g. cell/structure count)

So that the same can be related to each other

### pipeline 1a
input: Tile-scan image from Zeiss slidescanner (.czi file)
- Zen: "Stitching" Stitch image if not already done (new/updated .czi file)
- Zen: Adjust intensity scale 
- Zen: Adjust color to pure red/green/blue
- Zen: "SplitScene (Write files)" (new series of .czi files)
- Zen: Batch "Image Export" of the series of .czi files (new series of .tif files)
	+ Select "Use Input Folder as Output Folder"
	+ Naming... -> Format: {%N}