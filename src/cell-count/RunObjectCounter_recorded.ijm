open("C:/Documents - Work/Projects/NonAudTracingIC/Analysis/gen/alignment/input/2023-141-09279_j3-Stitched-Scene-16_c1+2+3.tif");
selectWindow("2023-141-09279_j3-Stitched-Scene-16_c1+2+3.tif");
run("Split Channels");
selectWindow("2023-141-09279_j3-Stitched-Scene-16_c1+2+3.tif (blue)");
selectWindow("2023-141-09279_j3-Stitched-Scene-16_c1+2+3.tif (red)");
run("Subtract Background...", "rolling=100");
//run("Brightness/Contrast...");
run("Enhance Contrast", "saturated=0.35");
resetMinAndMax();
run("3D Objects Counter", "threshold=25 slice=1 min.=80 max.=2000 exclude_objects_on_edges objects statistics");
selectWindow("2023-141-09279_j3-Stitched-Scene-16_c1+2+3.tif (red)");
selectWindow("Objects map of 2023-141-09279_j3-Stitched-Scene-16_c1+2+3.tif (red)");
run("Help on Menu Item");
run("3D Objects Counter");
saveAs("Results", "C:/Documents - Work/Projects/NonAudTracingIC/Analysis/gen/alignment/input/Statistics for 2023-141-09279_j3-Stitched-Scene-16_c1+2+3.csv");
run("Analyze Particles...", "size=80 pixel circularity=0.30-1.00 show=Overlay display clear summarize");
selectWindow("2023-141-09279_j3-Stitched-Scene-16_c1+2+3.tif (red)");
run("Console");
selectWindow("Objects map of 2023-141-09279_j3-Stitched-Scene-16_c1+2+3.tif (red)");
selectWindow("2023-141-09279_j3-Stitched-Scene-16_c1+2+3.tif (red)");
run("Analyze Particles...", "size=80-Infinity pixel circularity=0.30-1.00 show=Overlay display clear summarize");
setAutoThreshold("Default dark no-reset");
//run("Threshold...");
setThreshold(25, 255, "raw");
//setThreshold(25, 255);
setOption("BlackBackground", true);
run("Convert to Mask");
run("Analyze Particles...", "size=80-Infinity pixel circularity=0.30-1.00 show=Overlay display clear summarize");
run("Close");
run("Analyze Particles...", "size=80-Infinity pixel circularity=0.30-1.00 show=Overlay display exclude clear summarize overlay add");
