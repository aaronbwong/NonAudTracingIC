// location of files
im_path = "W:/Documents - Work/Projects/NonAudTracingIC/Analysis/gen/cell-count/input";
fn = "2023-141-09279_j3d9-10-Scene-01_c1+2+3.tif";
out_path = "W:/Documents - Work/Projects/NonAudTracingIC/Analysis/gen/cell-count/output";
print(getInfo("macro.filepath"));

// parameters
channel = "red";
bg_radius1 = 100;
bg_radius2 = 100;
threshold = 25; // how to determine automatically?
minSize = 81; // pixels; how to determine automatically?
maxSize = 1024 // pixels; how to determine automatically?
run("Close All");


// open and prepare image for analysis
open(im_path+"/"+fn);
winName = getTitle();
print(winName);
selectWindow(winName);

// Set Scale
run("Set Scale...", "distance=1	 known=1 unit=pixel");
print("Set scale to 1 pixel.");

// Select correct channel
run("Split Channels");
targetWin = winName+" ("+channel+")";
selectWindow(targetWin);
close("\\Others")
print("Analyzing "+channel+" channel.");

// Subtract Background
print("Subtracting background (1/2) with radius of "+bg_radius1+"...");
run("Subtract Background...", "rolling="+bg_radius1);
print("Subtracting background (2/2) with radius of "+bg_radius2+"...");
run("Subtract Background...", "rolling="+bg_radius2);

// Set Threshold, set measurements
setThreshold(threshold,255)
print("Set threshold to "+threshold);
run("Set Measurements...", "area mean min centroid center shape redirect=None decimal=3");

// Actual analysis of particles
print("Analyzing particles...");
run("Analyze Particles...", "size="+minSize+"-"+maxSize+" circularity=0.0-1.00 display clear");

// Save Results 
saveAs("Results", out_path+"/PartCounter_"+targetWin+".csv");
print("Results saved at "+out_path);