function [im_fn,MarkerXY] = readImageJCellCount(filename,typeIdx)

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
if ~exist('typeIdx','var') || isempty(typeIdx);typeIdx = 1;end

im_fn = S.Image_Properties.Image_Filename;
MarkerXY = [ [S.Marker_Data.Marker_Type(typeIdx).Marker.MarkerX]',...
             [S.Marker_Data.Marker_Type(typeIdx).Marker.MarkerY]' ];
