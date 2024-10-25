function AW_APHistology2Quint(slice_path)
% slice_path: path to folder that contains 
%       1) downsampled images for alignment
%       2) slice_order.csv: relates high-res image to downsamp image
%       3) histology_ccf.mat: from AP_histology
%       4) atlas2histology_tform.mat: from AP_histology

% load slice_order data
slice_order_fn = [slice_path filesep 'slice_order.csv'];
slice_order = readtable(slice_order_fn,"FileType","text","ReadVariableNames",true,"NumHeaderLines",0);

% genereate corners
n_im = size(slice_order,1);
out_fn = cellfun(@(fn) [slice_path,filesep, fn], ...
        slice_order.out_fn(:),'uni',false);

histology_points = cell(n_im,1);
for img = 1:n_im
    im_info = imfinfo(out_fn{img});
    imWidth = im_info.Width;
    imHeight = im_info.Height;
    histology_points{img} = [0,0;...
                             imWidth, 0 ;...
                             0, imHeight;...
                             imWidth, imHeight];
end


%
% Load corresponding CCF slices
ccf_slice_fn = [slice_path filesep 'histology_ccf.mat'];
load(ccf_slice_fn,"histology_ccf");

% Load histology/CCF alignment
ccf_alignment_fn = [slice_path filesep 'atlas2histology_tform.mat'];
load(ccf_alignment_fn,"atlas2histology_tform");
nonemptyslices = find(~cellfun(@isempty,histology_points));

ccf_scale = 10;     %(10um/voxel)
quint_scale = 25;   %(25um/voxel)
quint_anchoring_25um = cell(n_im,1);
quint_anchoring_um = cell(n_im,1);
image2ccf_tform= cell(n_im,1);
plane2ccf_tform= cell(n_im,1);

fig = figure;
ax1 = subplot(2,2,1);
ax2 = subplot(2,2,2);
ax3 = subplot(2,2,3);
Colors = [0,0,0; 1,0,0;0,1,0;0,0,1];

for curr_slice = nonemptyslices(:)'
    
    % Transform histology to atlas slice
    tform_img2plane = affine2d;
    tform_img2plane.T = atlas2histology_tform{curr_slice};
    % (transform is CCF -> histology, invert for other direction)
    tform_img2plane = invert(tform_img2plane);

%     scatter(ax1,histology_points{img}(:,1),...
%              histology_points{img}(:,2),...
%              25,Colors)
%     xlabel(ax1,'image x');ylabel(ax1,'image y')
%     set(ax1,'YDir','reverse')
    
    % Transform to plane stored in histology_ccf
    [histology_points_atlas_x,histology_points_atlas_y] = ...
        transformPointsForward(tform_img2plane, ...
        histology_points{curr_slice}(:,1), ...
        histology_points{curr_slice}(:,2));
    
%     scatter(ax2,histology_points_atlas_x,...
%              histology_points_atlas_y,...
%              25,Colors)
%     xlabel(ax2,'atlas x');ylabel(ax2,'atlas y')
%     set(ax2,'YDir','reverse')
    

    % Transform to 3D CCF coordinate
    tform_plane2ccf = affine3d;
    plane2ccf_tform{curr_slice}=histo2tform(histology_ccf(curr_slice).plane_ap);
    tform_plane2ccf.T = plane2ccf_tform{curr_slice};

    [histology_points_ccf_ap,histology_points_ccf_dv,histology_points_ccf_ml] = ...
        transformPointsForward(tform_plane2ccf, ...
        zeros(size(histology_points_atlas_x)),...
        histology_points_atlas_y,...
        histology_points_atlas_x);

%     scatter(ax3,histology_points_ccf_ml,...
%              histology_points_ccf_dv,...
%              25,Colors)
%     xlabel(ax3,'ml');ylabel(ax3,'dv')
%     set(ax3,'YDir','reverse')

    ccf_points{curr_slice} = [histology_points_ccf_ap,histology_points_ccf_dv,histology_points_ccf_ml];
    %
    [x,y,z] = ccf2Quint(histology_points_ccf_ap,...
                        histology_points_ccf_dv,...
                        histology_points_ccf_ml,...
                        ccf_scale, ...
                        quint_scale);

    ox = x(1);
    oy = y(1);
    oz = z(1);
    ux = x(2) - x(1);
    uy = y(2) - y(1);
    uz = z(2) - z(1);
    vx = x(3) - x(1);
    vy = y(3) - y(1);
    vz = z(3) - z(1);

    quint_anchoring_25um{curr_slice} = [ox,oy,oz, ux,uy,uz, vx, vy, vz];
    quint_anchoring_um{curr_slice} = 25*quint_anchoring_25um{curr_slice};

    img2plane_tform_3d = eye(4);
    img2plane_tform_3d(2:4,2:4) = tform_img2plane.T*[0,1,0;1,0,0;0,0,1];
    image2ccf_tform{curr_slice} = img2plane_tform_3d*tform_plane2ccf.T;
end
quint_anchoring_fn =  [slice_path filesep 'Quint_anchoring.mat'];
save(quint_anchoring_fn,'quint_anchoring_25um','ccf_scale','quint_scale','image2ccf_tform','plane2ccf_tform');

end

function plane2ccf_tform = histo2tform(plane_ap)
    dAP_dx = (plane_ap(1,1140) - plane_ap(1,1)) / (1140-1);
    dAP_dy = (plane_ap(800,1) - plane_ap(1,1)) / (800-1);
    AP_0 = plane_ap(1,1) - dAP_dx - dAP_dy;
% [x y z 1] = [u v w 1] * T
% [AP DV LR 1] = [0 i j 1] * T
% where the i and j are the first and second index of the matrix 800 x
% 1140, correspond to the y and x of the image respectively.
%               AP  DV  LR  ~   
%               ^   ^   ^   ^   
%       0 -> [                 ]
%    (y)i -> [                 ]
%    (x)j -> [                 ]
%       1 -> [                 ]    
    plane2ccf_tform = [1,       0,  0,  0; ...
                       dAP_dy,  1,  0,  0; ...
                       dAP_dx,  0,  1,  0; ...
                       AP_0,    0,  0,  1;]; 
end

function [x,y,z] = ccf2Quint(AP,DV,ML,ccf_scale,quint_scale)
    % AP, DV, ML in voxel index (10um/voxel)
    % ccf_scale = 10;     %(10um/voxel)
    % quint_scale = 25;   %(25um/voxel)
    Quint2ccf_M = [0,           0,              quint_scale,        0;...
                   -quint_scale,0,              0,                  0;...
                   0,           -quint_scale,   0,                  0;...
                   13200-quint_scale,8000-quint_scale,0,            1]; % voxel atlas (RAS axis orientation) to allen coordinate (PIR axis orientation)
    tform = affine3d;
    tform.T = Quint2ccf_M;
    [x,y,z] = transformPointsInverse(tform,AP*ccf_scale,DV*ccf_scale,ML*ccf_scale);

end