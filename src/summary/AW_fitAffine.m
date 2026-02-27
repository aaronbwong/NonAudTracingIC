
% [filename, filepath] = uigetfile('*.csv', 'Select CSV file to load');
% Slice = readtable(fullfile(filepath, filename));
if ~exist("mesh_3d_smth","var")
    load('.\gen\brain_10_mesh_3d.mat',"mesh_3d_smth");
end
%%
% Extract coordinates
numPoints = height(Slice);
imagePoints = [Slice.image_x, Slice.image_y, ones(numPoints,1)];
worldPoints = [Slice.ccf_ap, Slice.ccf_ml, Slice.ccf_dv];

% Fit affine transformation (2D to 3D) using least squares
% Create design matrix for affine transformation: [x y 1] * A = [X Y Z]
A =  imagePoints \ worldPoints;

% Apply affine transformation
transformedPoints = imagePoints * A;


% Select points within mesh % DOES NOT WORK WELL
    % % tri = triangulation(mesh_3d_smth.faces, mesh_3d_smth.vertices);
    % tri = delaunayTriangulation(mesh_3d_smth.vertices);
    % in = ~isnan(pointLocation(tri, worldPoints));
in = checkPointsInBrain(av,worldPoints);
imagePoints_in = imagePoints(in, :);
worldPoints_in = worldPoints(in, :);


% Fit second affine transformation with points inside mesh
A2 = imagePoints_in \ worldPoints_in;
transformedPoints2 = imagePoints * A2;
Slice.ccf_ap_affine = transformedPoints2(:, 1);
Slice.ccf_ml_affine = transformedPoints2(:, 2);
Slice.ccf_dv_affine = transformedPoints2(:, 3);


%%
% Create 3D scatter plot
figure('Position', [100, 100, 1200, 500]);

% Transformed points with arrows
hold on;
scatter3(worldPoints(~in, 1), worldPoints(~in, 2), worldPoints(~in, 3), 20, 'b', 'filled', 'DisplayName', 'Original (out)');
scatter3(worldPoints(in, 1), worldPoints(in, 2), worldPoints(in, 3), 50, 'k', 'filled', 'DisplayName', 'Original (in)');
patch(gca,'Vertices',mesh_3d_smth.vertices,'Faces',mesh_3d_smth.faces,'FaceColor',[.5,.5,.5],'EdgeColor','none','FaceAlpha',0.4)
% scatter3(transformedPoints(:, 1), transformedPoints(:, 2), transformedPoints(:, 3), 50, 'r', 'filled', 'DisplayName', 'Transformed');
% scatter3(transformedPoints2(:, 1), transformedPoints2(:, 2), transformedPoints2(:, 3), 50, 'g', 'filled', 'DisplayName', 'Transformed');
axis equal
set(gca,'ZDir','reverse')
% 
%%
figure('Position', [100, 100, 1200, 800]);
imageDeformation = worldPoints - transformedPoints2;
quiver3(transformedPoints2(:,1),transformedPoints2(:,2),transformedPoints2(:,3),...
imageDeformation(:,1),imageDeformation(:,2),imageDeformation(:,3),'LineWidth',2)
patch(gca,'Vertices',mesh_3d_smth.vertices,'Faces',mesh_3d_smth.faces,'FaceColor',[.5,.5,.5],'EdgeColor','none','FaceAlpha',0.4)
axis equal
set(gca,'ZDir','reverse')
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

function in = checkPointsInBrain(av,points)
    % av: atlas volume 10um, in ap, dv, ml
    % points: 3D coordinates in um, in ap, ml, dv
    scaling = 10;

    % numPoints = size(points,1);
    points = round(points ./ scaling);
    max_ap =size(av,1);
    max_dv =size(av,2);
    max_ml =size(av,3);
    points(:,1) = max(1,points(:,1)); points(:,1) = min(max_ap,points(:,1));
    points(:,2) = max(1,points(:,2)); points(:,2) = min(max_ml,points(:,2));
    points(:,3) = max(1,points(:,3)); points(:,3) = min(max_dv,points(:,3));
    % in = false(numPoints,1);
    idx = sub2ind(size(av),points(:,1),points(:,3),points(:,2));
    in = av(idx) > 1;
end