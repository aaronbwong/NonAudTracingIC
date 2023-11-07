path = "W:/RawData/EpiFluoData/2023-141/2023-141-09280/";
filename = "2023-141_09280_j3(1)";
fileExt = ".czi";
//open(path+filename+fileExt+"  color_mode=Composite open_files quiet view=Hyperstack stack_order=XYCZT use_virtual_stack");
run("Bio-Formats Importer","open="+path+filename+fileExt+
	"  color_mode=Composite open_files quiet view=Hyperstack stack_order=XYCZT use_virtual_stack");

getDimensions(width,height,nch,gridz,frames);
getVoxelSize(dx, dy, dz, unit);

for (i=1; i<=nch; i++) {
	Stack.setChannel(i);
	resetMinAndMax();
	run("Enhance Contrast", "saturated=0.01");
}

setOption("ScaleConversions", true);
run("8-bit");
