function cc_struct = AW_ObjCount2CellCounter(obj_csv,im_fn)
    obj_table = readtable(obj_csv);
    cc_struct = struct;

    cc_struct.Image_Properties = struct;
    cc_struct.Image_Properties.Image_Filename = im_fn;
    cc_struct.Image_Properties.X_Calibration = 1;
    cc_struct.Image_Properties.Y_Calibration = 1;
    cc_struct.Image_Properties.Z_Calibration = 1;
    cc_struct.Image_Properties.Calibration_Unit = 'pixel';


    cc_struct.Marker_Data = struct;
    cc_struct.Marker_Data.Current_Type = 0;
    cc_struct.Marker_Data.Name = 'cell';
    cc_struct.Marker_Data.Marker_Type = struct;
    cc_struct.Marker_Data.Marker_Type.Type = 1;

    MarkerTbl = obj_table(:,{'X','Y','Z'});
    MarkerTbl.X = round(MarkerTbl.X);
    MarkerTbl.Y = round(MarkerTbl.Y);
    MarkerTbl.Z = round(MarkerTbl.Z+1);
    MarkerTbl.Properties.VariableNames = {'MarkerX','MarkerY','MarkerZ'};

    cc_struct.Marker_Data.Marker_Type.Marker = table2struct(MarkerTbl);

    writestruct(cc_struct,[obj_csv(1:end-3),'xml'],...
        'StructNodeName','CellCounter_Marker_File');
end