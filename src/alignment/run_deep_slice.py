from DeepSlice import DSModel     
import os

species = 'mouse' #available species are 'mouse' and 'rat'

Model = DSModel(species)

#folderpath = '../../gen/alignment/temp/'
imagepath = './' # the same folder you're in
outputpath = '../DeepSliceResults/' # the same folder you're in
ResName = 'DeepSliceResults'
#here you run the model on your folder
#try with and without ensemble to find the model which best works for you
#if you have section numbers included in the filename as _sXXX specify this :)
print(imagepath)
if not os.path.exists(outputpath):
    os.mkdir(outputpath)
Model.predict(imagepath, ensemble=True, section_numbers=True)    
Model.save_predictions(outputpath + ResName +'_raw')                                                                                                             


#If you would like to normalise the angles (you should)
Model.propagate_angles()    
Model.save_predictions(outputpath + ResName +'_normAngle')           
#To reorder your sections according to the section numbers 
Model.enforce_index_order()    
Model.save_predictions(outputpath + ResName +'_normAngle_ordered')           
#alternatively if you know the precise spacing (ie; 1, 2, 4, indicates that section 3 has been left out of the series) Then you can use      
#Furthermore if you know the exact section thickness in microns this can be included instead of None        
Model.enforce_index_spacing(section_thickness = None)
#now we save which will produce a json file which can be placed in the same directory as your images and then opened with QuickNII. 
Model.save_predictions(outputpath + ResName +'_normAngle_ordered_spacing')   