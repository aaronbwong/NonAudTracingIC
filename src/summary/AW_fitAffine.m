
[filename, filepath] = uigetfile('*.csv', 'Select CSV file to load');
Slice = readtable(fullfile(filepath, filename));
load('.\gen\brain_10_mesh_3d.mat',"mesh_3d_smth");

% Extract coordinates
numPoints = height(Slice);
imagePoints = [Slice.image_x, Slice.image_y, ones(numPoints,1)];
worldPoints = [Slice.ccf_ap, Slice.ccf_ml, Slice.ccf_dv];

% Fit affine transformation (2D to 3D) using least squares
% Create design matrix for affine transformation: [x y 1] * A = [X Y Z]
A =  imagePoints \ worldPoints;

% Apply affine transformation
transformedPoints = imagePoints * A;
Slice.ccf_ap_affine = transformedPoints(:, 1);
Slice.ccf_ml_affine = transformedPoints(:, 2);
Slice.ccf_dv_affine = transformedPoints(:, 3);


% Select points within mesh
% tri = triangulation(mesh_3d_smth.faces, mesh_3d_smth.vertices);
tri = delaunayTriangulation(mesh_3d_smth.vertices);
in = ~isnan(pointLocation(tri, worldPoints));
imagePoints_in = imagePoints(in, :);
worldPoints_in = worldPoints(in, :);

% Fit second affine transformation with points inside mesh
A2 = imagePoints_in \ worldPoints_in;
transformedPoints2 = imagePoints * A2;



% Create 3D scatter plot
figure('Position', [100, 100, 1200, 500]);

% Transformed points with arrows
hold on;
scatter3(worldPoints(:, 1), worldPoints(:, 2), worldPoints(:, 3), 50, 'b', 'filled', 'DisplayName', 'Original');
scatter3(transformedPoints(:, 1), transformedPoints(:, 2), transformedPoints(:, 3), 50, 'r', 'filled', 'DisplayName', 'Transformed');
scatter3(transformedPoints2(:, 1), transformedPoints2(:, 2), transformedPoints2(:, 3), 50, 'g', 'filled', 'DisplayName', 'Transformed');
% 
% Draw arrows connecting corresponding points
% for i = 1:numPoints
%     quiver3(worldPoints(i, 1), worldPoints(i, 2), worldPoints(i, 3), ...
%             transformedPoints(i, 1) - worldPoints(i, 1), ...
%             transformedPoints(i, 2) - worldPoints(i, 2), ...
%             transformedPoints(i, 3) - worldPoints(i, 3), ...
%             0, 'k', 'AutoScale', 'off', 'LineWidth', 1);
% end

xlabel('CCF AP'); ylabel('CCF ML'); zlabel('CCF DV');
title('Original vs Transformed Points');
legend;
grid on;
hold off;