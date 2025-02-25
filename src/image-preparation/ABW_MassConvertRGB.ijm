
   requires("1.33s"); 

   dir = getDirectory("Choose a Directory ");
   //setBatchMode(true);
   count = 0;
   countFiles(dir);
   print(count+ " files in directory");
   n = 0;
   processFiles(dir);
   //print(count+" files processed");
   
   function countFiles(dir) {
      list = getFileList(dir);
      for (i=0; i<list.length; i++) {
          if (endsWith(list[i], "/"))
              countFiles(""+dir+list[i]);
          else
              count++;
      }
  }

   function processFiles(dir) {
      //("montage", "16-bit black", 1, 1, 1);
      newImage("montage", "RGB black", 1, 1, 1);
      montage = getImageID();
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
		   run("RGB Color");
		   run("Save");
           close();
      }
  }
