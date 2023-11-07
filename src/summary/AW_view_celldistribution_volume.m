function h_scatter = AW_view_celldistribution_volume(tv,ccf_points_cat)
% AP_view_celldistribution_volume(tv,ccf_points_cat)
%
% Plot histology warped onto CCF volume


% Create figure
gui_fig = figure;

% Set up 3D plot for volume viewing
axes_atlas = axes;
[~, brain_outline] = plotBrainGrid([],axes_atlas);
% X-Y-Z axes in the order [AP/ML/DV] (processed CCF)
set(axes_atlas,'ZDir','reverse');
hold(axes_atlas,'on');
axis vis3d equal off manual
view([-30,25]);
caxis([0 300]);
[ap_max,dv_max,ml_max] = size(tv);
xlim([-10,ap_max+10])
ylim([-10,ml_max+10])
zlim([-10,dv_max+10])


% Turn on rotation by default
h = rotate3d(axes_atlas);
h.Enable = 'on';

% Draw all datapoints
% ccf_points_cat is in native CCF order [AP/DV/ML] 
h_scatter = scatter3(axes_atlas,ccf_points_cat(:,1),... % AP
                    ccf_points_cat(:,3),... % ML
                    ccf_points_cat(:,2),... % DV
                    5,'red','filled','o');  



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










