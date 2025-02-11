function gui_fig = AW_view_celldistribution_volume(csvFilePaths,DisplayNameList)
% AP_view_celldistribution_volume(tv,ccf_points_cat)
%
% Plot histology warped onto CCF volume

% cell_csv: path to CSV file containing CCF coordinates of cells
%  should store as columns ccf_ap, ccf_dv, ccf_ml

ap_max = 1320;
dv_max = 800;
ml_max = 1140;

% Create figure
gui_fig = figure;

% Set up 3D plot for volume viewing
axes_atlas = axes;
[~, brain_outline] = plotBrainGrid([],axes_atlas);
brain_outline.DisplayName = 'Brain';
% X-Y-Z axes in the order [AP/ML/DV] (processed CCF)
set(axes_atlas,'ZDir','reverse');
hold(axes_atlas,'on');
axis vis3d equal on manual
view([-30,25]);
caxis([0 300]);
xlim([-10,ap_max+10]);xlabel('Anterior-Posterior (10 um)')
ylim([-10,ml_max+10]);ylabel('Right-Left (10 um)')
zlim([-10,dv_max+10]);zlabel('Dorsal-Ventral (10 um)')
axes_atlas.Color = 'none';


% Turn on rotation by default
h = rotate3d(axes_atlas);
h.Enable = 'on';

% Draw all datapoints
% ccf_points_cat is in native CCF order [AP/DV/ML] 
Colors = [ 1,0,0;...
          0,1,0;...
          0,0.5,1;...
          1,0,1;];

gui_data.axes_atlas = axes_atlas;
gui_data.cells = {};
guidata(gui_fig,gui_data);

if ~iscell(csvFilePaths); csvFilePaths = {csvFilePaths};end
ColorList = jet(length(csvFilePaths)+1);
if ~exist("DisplayNameList","var");DisplayNameList = num2cell(1:length(csvFilePaths));end
for iCsv = 1:length(csvFilePaths)
    % Add cell distribution volume to the image
    gui_fig = AW_add_celldistribution_volume(gui_fig,csvFilePaths{iCsv},ColorList(iCsv,:),DisplayNameList{iCsv});
end

legend;
end


% % Attempt plotting as 3D surface
% 
% keyboard
% 
% thresh_volume = false(size(tv));
% 
% for curr_slice = 1:length(gui_data.slice_im)
%     
%     % Get thresholded image
%     curr_slice_im = gui_data.atlas_aligned_histology{curr_slice}(:,:,channel);
%     slice_alpha = curr_slice_im;
%     slice_alpha(slice_alpha < 100) = 0;
%     
%     slice_thresh = curr_slice_im > 200;
%     
%     slice_thresh_ap = round(gui_data.histology_ccf(curr_slice).plane_ap(slice_thresh));
%     slice_thresh_dv = round(gui_data.histology_ccf(curr_slice).plane_dv(slice_thresh));
%     slice_thresh_ml = round(gui_data.histology_ccf(curr_slice).plane_ml(slice_thresh));
%     
%     thresh_idx = sub2ind(size(tv),slice_thresh_ap,slice_thresh_dv,slice_thresh_ml);
%     thresh_volume(thresh_idx) = true;
%     
% end
% 
% thresh_volume_dilate = imdilate(thresh_volume,strel('sphere',5));
% 
% sphere_size = (4/3)*pi*5^3;
% a = bwareaopen(thresh_volume_dilate,round(sphere_size*20));
% b = imdilate(a,strel('sphere',5));
% c = imresize3(+b,1/10,'nearest');
% 
% ap = linspace(1,size(tv,1),size(c,1));
% dv = linspace(1,size(tv,2),size(c,2));
% ml = linspace(1,size(tv,3),size(c,3));
% 
% figure;
% plotBrainGrid([],gca); hold on;
% isosurface(ap,ml,dv,permute(c,[3,1,2]));
% camlight;










