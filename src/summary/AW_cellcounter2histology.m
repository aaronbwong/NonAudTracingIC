function histology_points = AW_cellcounter2histology(slice_path,cellcountpath,resize_factor)
%
% slice_path: path to folder that contains 
%       1) downsampled images for alignment
%       2) slice_order.csv: relates high-res image to downsamp image
%       3) histology_ccf.mat: from AP_histology
%       4) atlas2histology_tform.mat: from AP_histology


% load cell counter data
cellcount_path_dir = dir([cellcountpath filesep '*.xml*']);
cellcount_fn = natsortfiles(cellfun(@(path,fn) [path filesep fn], ...
    {cellcount_path_dir.folder},{cellcount_path_dir.name},'uni',false));
n_cellcount = length(cellcount_fn);

hist_points = cell(n_cellcount,1);
im_fn = cell(n_cellcount,1);

for ii = 1:n_cellcount
    [im_fn{ii},hist_points{ii}] = readImageJCellCount(cellcount_fn{ii});
end

% load slice_order data
slice_order_fn = [slice_path filesep 'slice_order.csv'];
slice_order = readtable(slice_order_fn);

for ii = 1:n_cellcount 
    im_num = find(ismember(slice_order.ori_filename,im_fn{ii}));
%     resize_factor = slice_order.resize_factor(ii);
    if ~isempty(im_num)
        slice_order.histology_points{im_num} = resize_factor*hist_points{ii};
    end
end
histology_points = slice_order.histology_points;
end