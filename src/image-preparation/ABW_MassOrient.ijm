
   requires("1.33s"); 

   dir = getDirectory("Choose a Directory ");
   //setBatchMode(true);
   var count = 0; // defined as global variable
   var processCount = 0; // defined as global variable
   var processedCount = 0; // defined as global variable
   var Rotate = 0; // defined as global variable
   var FlipHori = 0; // defined as global variable
   
   countFiles(dir);
   print("Directory: "+dir);
   print(count+ " files in directory");
   n = 0;
   processFiles(dir);
   print(processcount+" files processed");
   
   function countFiles(dir) {
      list = getFileList(dir);
      for (i=0; i<list.length; i++) {
          if (endsWith(list[i], "/"))
              countFiles(""+dir+list[i]);
          else {
          	if(endsWith(path, ".tif")||endsWith(path, ".jpg")||endsWith(path, ".png")||endsWith(path, ".czi")){
            	count++;
          	}
          }
      }
  }

   function processFiles(dir) {
	  RotFlipDialog()
//	print("processFiles() scope:");
	print("  Rotate "+Rotate+" times.");
	print("  Flip "+FlipHori+" times horizontally.");
	list = getFileList(dir);
      for (i=0; i<list.length; i++) {
          if (endsWith(list[i], "/"))
             processFiles(""+dir+list[i]);
          else {
             showProgress(n++, count);
             path = dir+list[i];
             processFile(path);
          }
      }
  }

  function processFile(path) {
       if (endsWith(path, ".tif")||endsWith(path, ".jpg")||endsWith(path, ".png")||endsWith(path, ".czi")) {
           open(path);

        processCount++;
        print(processCount+"/"+count+" files.");
		//print("Rotate "+Rotate+" times.");
		for(i = 0; i < Rotate; i++) {
			run("Rotate 90 Degrees Right");
		}
		//print("Flip "+FlipHori+" times horizontally.");
		if (FlipHori) {
			run("Flip Horizontally");
		}
		if (endsWith(path, ".jpg")) { fileType = "Jpeg";}
		if (endsWith(path, ".png")) { fileType = "PNG";}
		if (endsWith(path, ".tif")) { fileType = "TIFF";}


		saveAs(fileType, path);
           close();
        processedCount++;
      }
  }
  
function RotFlipDialog() {

Dialog.create("Rotate/Flip")
Dialog.addNumber("Rotate N x right angles:",Rotate);
Dialog.addNumber("Flip Horizontally:",FlipHori);
Dialog.show();
Rotate = Dialog.getNumber();
FlipHori = Dialog.getNumber();
//print("Dialog scope:");
//print("Rotate "+Rotate+" times.");
//print("Flip "+FlipHori+" times horizontally.");

  }
