path = "C:/Documents - Work/Projects/NonAudTracingIC/Analysis/gen/alignment/input";
fn = "2023-141-09279_j3-Stitched-Scene-16_c1+2+3.tif";

channel = "red";
bg_radius1 = 100;
bg_radius2 = 100;
threshold = 25; // how to determine automatically?
minSize = 81; // pixels; how to determine automatically?
maxSize = 1024 // pixels; how to determine automatically?
run("Close All");

open(path+"/"+fn);
winName = getTitle();
print(winName);
selectWindow(winName);
run("Split Channels");
selectWindow(winName+" ("+channel+")");

run("Subtract Background...", "rolling="+bg_radius1);
run("Subtract Background...", "rolling="+bg_radius2);


run("3D Objects Counter", "threshold="+threshold+" slice=1 min.="+minSize+" max.="+maxSize+" exclude_objects_on_edges objects statistics");


saveAs("Results", path+"/ObjCounter_"+winName+" ("+channel+").csv");