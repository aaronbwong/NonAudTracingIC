function [ccf_points,slice_order] = AW_cellcounter2histology(slice_path,cellcountpath,resize_factor)
%
% slice_path: path to folder that contains 
%       1) downsampled images for alignment
%       2) slice_order.csv: relates high-res image to downsamp image
%       3) histology_ccf.mat: from AP_histology
%       4) atlas2histology_tform.mat: from AP_histology


% load slice_order data
slice_order_fn = [slice_path filesep 'slice_order.csv'];
slice_order = readtable(slice_order_fn,"FileType","text","ReadVariableNames",true,"NumHeaderLines",0);

% load cell counter data
cellcount_path_dir = dir([cellcountpath filesep '*.xml*']);
cellcount_fn = natsortfiles(cellfun(@(path,fn) [path filesep fn], ...
    {cellcount_path_dir.folder},{cellcount_path_dir.name},'uni',false));
n_cellcount = length(cellcount_fn);

    % preallocate cell arrays
markers = cell(n_cellcount,1);
im_fn = cell(n_cellcount,1);
    % loop through all cell counter files
for ii = 1:n_cellcount
    [im_fn{ii},markers{ii}] = readImageJCellCount(cellcount_fn{ii});
    nTypes = length(markers{ii});

    % apply resize factor
    for typeIdx = 1:nTypes     
        markers{ii}(typeIdx).MarkerXY_rz = resize_factor*markers{ii}(typeIdx).MarkerXY;
    end

    % collect metadata (names, type #)
    if ii == 1
        markerIdx = [markers{ii}.Type];
        markerNames = [markers{ii}.Name];
    else
        markerIdx = union([markers{ii}.Type],markerIdx,'stable');
        markerNames = union([markers{ii}.Name],markerNames,'stable');
    end

    % add cell_counter file name to slice_order table
    im_num = find(ismember(slice_order.ori_filename,im_fn{ii}));
    if ~isempty(im_num)
        [~,name,ext] = fileparts(cellcount_fn{ii});
        slice_order.cellcount_fn{im_num} = [name,ext];
    end
end

% allocate markers XY to table
nTypes = length(markerNames);
for ii = 1:n_cellcount
    for tt = 1:nTypes
        typeIdx = matches([markers{ii}.Name],markerNames(tt));
        slice_order.(markerNames(tt)){ii} = markers{ii}(typeIdx).MarkerXY_rz;
    end
end

% converting to CCF markers XY to table
for tt = 1:nTypes
    histology_points = slice_order.(markerNames(tt));
    ccf_points_temp = AP_histology2ccf(histology_points,slice_path);
    slice_order.(markerNames(tt)+"_ccf") = ccf_points_temp;
end

ccf_points = slice_order(:,endsWith(slice_order.Properties.VariableNames,'_ccf'));

end