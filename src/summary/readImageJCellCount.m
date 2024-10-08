function [im_fn,Markers] = readImageJCellCount(filename)

    %% load XML
    
    S = readstruct(filename);
    % data structure
    % S -> ImageProperties
    %       ->
    %       ->
    % S.Marker_Data.Marker_Type: struct array of different marker types
    % S.Marker_Data.Marker_Type.Marker: 1xn struct array with fields:
    %    MarkerX
    %    MarkerY
    %    MarkerZ
    
    im_fn = S.Image_Properties.Image_Filename;
    
    Markers = struct;
    nTypes = length(S.Marker_Data.Marker_Type);
        for typeIdx = 1:nTypes 
            Markers(typeIdx).Type = S.Marker_Data.Marker_Type(typeIdx).Type;
            if isfield(S.Marker_Data.Marker_Type,'Name')
                Markers(typeIdx).Name = S.Marker_Data.Marker_Type(typeIdx).Name;
            else
                Markers(typeIdx).Name = "";
            end
            Markers(typeIdx).MarkerXY = readCellType(S,typeIdx);
        end
end

function MarkerXY = readCellType(S,typeIdx)
    if ~exist('typeIdx','var') || isempty(typeIdx);typeIdx = 1;end
    if isfield(S.Marker_Data.Marker_Type,'Marker') && ...
            ~all(ismissing(S.Marker_Data.Marker_Type(typeIdx).Marker))
        MarkerXY = [ [S.Marker_Data.Marker_Type(typeIdx).Marker.MarkerX]',...
                 [S.Marker_Data.Marker_Type(typeIdx).Marker.MarkerY]' ];
    else
        MarkerXY = NaN(0,2);
    end
end