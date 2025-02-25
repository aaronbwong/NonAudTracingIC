% Example pipeline for processing histology

%% 1) Load CCF and set paths for slide and slice images

addpath('submodules\npy-matlab\npy-matlab');
addpath('submodules\AP_histology');
addpath('submodules\AP_histology\allenCCF_repo_functions');
addpath(genpath('src\'));

% Set paths for histology images and directory to save slice/alignment

% -- Data specific ---
im_path = 'W:\AnalyzedData\Histology\2023-141-09279\FullSize8bitTIFFs\j3';
im_path = '\\borstlab-nas1\Aaron\EpiFluoData\2021_EpiFluoData\2017-628_AAVRetroICInj\2017-628';
slice_path = 'W:\AnalyzedData\Histology\2023-141-09279\downsampledImages\j3_old';
slice_path = 'W:\AnalyzedData\Histology\2017-628_test';
prefix = '2023-141-09279-j3';
prefix = '2017-628_test';
% --------------------

%%
% Load CCF atlas
% -- Compnuter specific ---
allen_atlas_path = 'data\AllenCCF';
allen_atlas_path = 'C:\Documents - Work\Software\Codes\Matlab\neuropixels_trajectory_explorer';
allen_atlas_path = 'W:\Documents - Work\Software\Codes\Matlab\neuropixels_trajectory_explorer';
% -------------------------
tv = readNPY([allen_atlas_path filesep 'template_volume_10um.npy']);
av = readNPY([allen_atlas_path filesep 'annotation_volume_10um_by_index.npy']);
st = AP_loadStructureTree([allen_atlas_path filesep 'structure_tree_safe_2017.csv']);


%% 2) Preprocess slide images to produce slice images

% Set white balance and resize slide images, extract slice images
% (Note: this resizes the images purely for file size reasons - the CCF can
% be aligned to histology no matter what the scaling. If pixel size is
% available in metadata then automatically scales to CCF resolution,
% otherwise user can specify the resize factor as a second argument)

% Set resize factor
% -- Data specific ---
% resize_factor = []; % (slides ome.tiff: auto-resize ~CCF size 10um/px)
% resize_factor = 0.340*2/10; % (slides tiff: resize factor)
resize_factor = 0.721/10; % (slides tiff: resize factor)
% --------------------

% Set slide or slice images
% slice_images = false; % (images are slides - extract individual slices)
slice_images = true; % (images are already individual slices)

% Preprocess images

% AP_process_histology(im_path,resize_factor,slice_images,slice_path);
AW_process_histology(im_path,resize_factor,slice_images,slice_path,prefix);

% (optional) Rotate, center, pad, flip slice images
% AP_rotate_histology(slice_path);
AW_reorderHistology(slice_path);
%% 3a) DeepSlice
% system('conda activate deepslice');
savepath = pwd;
codepath = [savepath,filesep,'src\alignment\run_deep_slice.py'];
cd(slice_path);
system(['python ','"',codepath,'"']);
cd(savepath);

%% 3) Align CCF to slices

% Find CCF slices corresponding to each histology slice
AP_grab_histology_ccf(tv,av,st,slice_path);
slice_plane_fn = [slice_path,filesep,'DeepSliceResults_normAngle_ordered_spacing_extrapolated.xml'];
AP_grab_histology_ccf(tv,av,st,slice_path,slice_plane_fn)

% Align CCF slices and histology slices
% (first: automatically, by outline)
AP_auto_align_histology_ccf(slice_path); %produces 2D affine transform between CCF image and slice
% (second: curate manually)
AP_manual_align_histology_ccf(tv,av,st,slice_path);


%% 4) Utilize aligned CCF

% Display aligned CCF over histology slices
AP_view_aligned_histology(st,slice_path);

% Display histology within 3D CCF
% AP_view_aligned_histology_volume(tv,av,st,slice_path,1);

% Extract results from ImageJ Cell Counter
% --- Data specific ---
cellcountpath = 'gen\cell-count\output\2023-141-09279\';
slice_path = 'W:\AnalyzedData\Histology\2023-141-09279\downsampledImages\j3_old';
cellcountpath = 'W:\AnalyzedData\Histology\2023-141-09279\CellCounterResults';
slice_path = 'Z:\Falk Bronnle\DATA\Brain 02888-22007\TIFFS 10x\Slices';
cellcountpath = 'Z:\Falk Bronnle\DATA\Brain 02888-22007\TIFFS 10x\Cellcount';
% ---------------------
[histology_points,slice_order] = AW_cellcounter2histology(slice_path,cellcountpath,resize_factor);

% Convert points in histology images to CCF coordinates
ccf_points = AP_histology2ccf(histology_points,slice_path);

% Display points in 3D with brain mesh outline
h_scatter = AW_view_celldistribution_volume(tv,slice_order);


% Concatenate points and round to nearest integer coordinate
ccf_points_cat = round(cell2mat(ccf_points));
% Get indicies from subscripts
ccf_points_idx = sub2ind(size(av),ccf_points_cat(:,1),ccf_points_cat(:,2),ccf_points_cat(:,3));
% Find annotated volume (AV) values at points
ccf_points_av = av(ccf_points_idx);
% Get areas from the structure tree (ST) at given AV values
ccf_points_areas = st(ccf_points_av,:).safe_name;












