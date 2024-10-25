ccf_slice_fn = [slice_path filesep 'histology_ccf.mat'];
load(ccf_slice_fn,"histology_ccf");
slice1 = histology_ccf(1);

point1_xyz = [slice1.plane_ap(1,1);...
              slice1.plane_ml(1,1);...
              slice1.plane_dv(1,1);];

pointYmax_xyz = [slice1.plane_ap(800,1);...
              slice1.plane_ml(800,1);...
              slice1.plane_dv(800,1);];

pointXmax_xyz = [slice1.plane_ap(1,1140);...
              slice1.plane_ml(1,1140);...
              slice1.plane_dv(1,1140);];

pointXYmax_xyz = [slice1.plane_ap(800,1140);...
              slice1.plane_ml(800,1140);...
              slice1.plane_dv(800,1140);];


% looks like ML & DV are not changing at all..
dAP_dx = (pointXmax_xyz(1) - point1_xyz(1)) / (1140-1);
dAP_dy = (pointYmax_xyz(1) - point1_xyz(1)) / (800-1);
AP_0 = point1_xyz(1) - dAP_dx - dAP_dy;

i = 800; j = 1140;
new_AP = AP_0 + j*dAP_dx + i*dAP_dy;

tform_plane2ccf = affine3d;
% [x y z 1] = [u v w 1] * T
% [AP DV LR 1] = [0 j i 1] * T
% where the i and j are the first and second index of the matrix 800 x
% 1140, correspond to the y and x of the image respectively.
%               AP  DV  LR  ~   
%               ^   ^   ^   ^   
%       0 -> [                 ]
%       i -> [                 ]
%       j -> [                 ]
%       1 -> [                 ]
%
tform_plane2ccf.T = [1,       0,  0,  0; ...
           dAP_dy,  1,  0,  0; ...
           dAP_dx,  0,  1,  0; ...
           AP_0,    0,  0,  1;]; 

transformPointsForward(tform_plane2ccf,0,1,x)