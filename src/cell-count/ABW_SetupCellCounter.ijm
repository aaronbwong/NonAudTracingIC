// setup for Cell Counter
print("\\Clear");
// 1) manually open an image

// 2) check if calibration is correct; if not apply a calibration
//		CZI export meta "ImageScaling->ImagePixelSize"
//		and "ImageScaling->ScalingComponent" 
	getPixelSize(unit, pixelWidth, pixelHeight);
	if (matches(unit,"pixels|inches")){calibrated = 0;}
	if (matches(unit,"microns|um|m|mm")){calibrated = 1;}
	ImagePixelSize = 3.45; //um; 
	Binning = 2;
	ScalingComponent = 10; // multiple of all magnifications; 
	//ImagePixelSize = 4.54; //um; 
	//Binning = 1;
	//ScalingComponent = 10 * 0.63; // multiple of all magnifications; 
	umPerPixel = ImagePixelSize / ScalingComponent * Binning;
	if(calibrated) {
		print("calibrated.");
	}else{
		print("uncalibrated");
		print("Setting pixel size to "+umPerPixel+" microns");
		setVoxelSize(umPerPixel, umPerPixel, 0, "micron");
		run("Save");
	}
	
// 3) Convert to Composite Image
	run("Make Composite");
	run("Brightness/Contrast...");
	run("Channels Tool...");
	getDimensions(width,height,nch,gridz,frames);
	for (i=1; i<=nch; i++) {
		Stack.setChannel(i);
		resetMinAndMax();
		run("Enhance Contrast", "saturated=0.005");
	}
	Stack.setChannel(1);

// 4) Run Cell Counter (please do it manually)
	// First image in series
	//	- "Plugin->Analyze->Cell Counter->Cell Counter"
	// Check Keep Original
	// Click Initialize
	// First image in series:
	//	- Remove and Rename Counter types
	// after counting:
	//	- Save Markers
	//	- Close Counter image
	//	- Select original image and click "File->Open Next" or Ctrl+Shift+O
	//	- Run this Macro again