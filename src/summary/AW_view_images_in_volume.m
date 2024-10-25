function AW_view_images_in_volume(slice_path,value_thresh,max_alpha)
% AW_view_images_in_volume(slice_path)
%
% Plot histology warped onto CCF volume

if nargin < 3; max_alpha = 0.7; end
if nargin < 2; value_thresh = 40; end

slice_order_fn = [slice_path filesep 'slice_order.csv'];
slice_order = readtable(slice_order_fn,"FileType","text","ReadVariableNames",true,"NumHeaderLines",0);

n_im = size(slice_order,1);
out_fn = cellfun(@(fn) [slice_path,filesep, fn], ...
        slice_order.out_fn(:),'uni',false);

ccf_alignment_fn = [slice_path filesep 'atlas2histology_tform.mat'];
load(ccf_alignment_fn,"atlas2histology_tform");

quint_anchoring_fn =  [slice_path filesep 'Quint_anchoring.mat'];
load(quint_anchoring_fn,'plane2ccf_tform','image2ccf_tform');

%[ap_max,dv_max,ml_max] = size(tv);
ccf_scale = 10; % 10 um/voxel
ap_max = 13200/ccf_scale;
dv_max = 8000/ccf_scale;
ml_max = 11400/ccf_scale;

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
xlim([-10,ap_max+10])
ylim([-10,ml_max+10])
zlim([-10,dv_max+10])


for curr_slice = 1:n_im
    im_info = imfinfo(out_fn{curr_slice});
    imWidth = im_info.Width;
    imHeight = im_info.Height;

    frame_xy = [0,0;...
                 imWidth, 0 ;...
                 0, imHeight;...
                 imWidth, imHeight];

%     tform_img2plane = affine2d;
%     tform_img2plane.T = atlas2histology_tform{curr_slice};
%     tform_img2plane = invert(tform_img2plane);

    histo_img = imread(out_fn{curr_slice});
%     [frame_atlas_x,frame_atlas_y] = ...
%         transformPointsForward(tform_img2plane, ...
%         frame_xy(:,1), ...
%         frame_xy(:,2));
    
    [image_x,image_y] = meshgrid(1:imWidth,1:imHeight);

%     tform_plane2ccf = affine3d;
%     tform_plane2ccf.T = plane2ccf_tform{curr_slice};
% 
%     [frame_ap,frame_dv,frame_ml] = transformPointsForward(tform_plane2ccf,...
%         zeros(size(frame_xy,1),1),...
%         frame_atlas_y,...
%         frame_atlas_x);
%     plot3(frame_ap,frame_ml,frame_dv,'-o');
%     hold on;

    tform_img2ccf = affine3d;
    tform_img2ccf.T = image2ccf_tform{curr_slice};

%     [frame_ap,frame_dv,frame_ml] = transformPointsForward(tform_img2ccf,...
%         zeros(size(frame_xy,1),1),...
%         frame_xy(:,1),...
%         frame_xy(:,2));
%     plot3(frame_ap,frame_ml,frame_dv,'-d');
%     hold on;

    [image_ap, image_dv, image_ml] = transformPointsForward(tform_img2ccf,...
        zeros(size(image_x)),...
        image_x,...
        image_y);
    histology_surf(curr_slice) = surface( ...
        image_ap, ...
        image_ml, ...
        image_dv);
    histology_surf(curr_slice).FaceColor = 'texturemap';
    histology_surf(curr_slice).EdgeColor = 'none';
    histology_surf(curr_slice).CData = histo_img;

    slice_alpha = (mean(histo_img,3)>value_thresh)*max_alpha;
    histology_surf(curr_slice).FaceAlpha = 'texturemap';
    histology_surf(curr_slice).AlphaDataMapping = 'none';
    histology_surf(curr_slice).AlphaData = slice_alpha;

end


% Turn on rotation by default
h = rotate3d(axes_atlas);
h.Enable = 'on';

%     legend("Brain",'Interpreter','none');
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










