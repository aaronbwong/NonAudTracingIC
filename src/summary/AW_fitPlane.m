
% [filename, filepath] = uigetfile('*.csv', 'Select CSV file to load');
% Slice = readtable(fullfile(filepath, filename));
%%

[normal,plane_eq] = findPlaneNormal(Slice);
[horizontal_angle,vertical_angle] = calculateAngles(normal);
ML_target = 5700; 
DV_target = 4000; 
[AP_plane,ML_target,DV_target] = calculateXPlane(plane_eq,ML_target,DV_target);

fprintf('Vertical angle: %.2f degrees\n', vertical_angle);
fprintf('Horizontal angle: %.2f degrees\n', horizontal_angle);

%% Extract coordinates
pts = [Slice.ccf_ap, Slice.ccf_ml, Slice.ccf_dv];

% Color map for image location
max_image_x = max(Slice.image_x);
max_image_y = max(Slice.image_y);

markerColor = 0.25 + 0.75 .* ...
            [ [1].*Slice.image_x ./ max_image_x, ... % R
              zeros(height(Slice),1),... %G
              [1].*Slice.image_y ./ max_image_y]; % B


% Create 3D scatter plot
figure;
scatter3(pts(:,1), pts(:,2), pts(:,3), 10, markerColor, 'filled');
hold on;
ML_target = 5700;
DV_target = 4000;
% Plot normal vector as arrow from origin
fprintf('Point on plane at Y=%.0f, Z=%.0f: X=%.2f\n', ML_target, DV_target, AP_plane);
scatter3(AP_plane, ML_target, DV_target, 100, 'r', 'filled');
arrow_length = 2500; % Length of the normal vector arrow


quiver3(AP_plane, ML_target, DV_target, ...
        arrow_length*normal(1), ...
        arrow_length*normal(2), ...
        arrow_length*normal(3), 'r', 'LineWidth', 1);
plot3([0,13200],[ML_target,ML_target],[DV_target,DV_target],'-','LineWidth',1)
% % Plot the plane
% [X, Y] = meshgrid(linspace(min(pts(:,1)), max(pts(:,1)), 10), ...
%                    linspace(min(pts(:,2)), max(pts(:,2)), 10));
% Z = (-plane_eq(1)*X - plane_eq(2)*Y - plane_eq(4)) / plane_eq(3);
% surf(X, Y, Z, 'FaceAlpha', 0.3, 'FaceColor', 'cyan');


% Set labels and title
xlabel('ccf_ap');
ylabel('ccf_ml');
zlabel('ccf_dv');
title('3D Plane Fitting');
set(gca, 'ZDir', 'reverse');
legend('Data points', 'Normal vector');
grid on;
axis equal;

function [normal,plane_eq] = findPlaneNormal(tbl)
% Find the normal vector to a plane defined by points in a table
% The table must have columns: 'ccf_ap', 'ccf_ml', 'ccf_dv'
% 
% Outputs:
%   normal   - Normal vector to the plane
%   plane_eq - Plane equation coefficients [a, b, c, d] for ax + by + cz + d = 0

% Extract coordinates
pts = [tbl.ccf_ap, tbl.ccf_ml, tbl.ccf_dv];

% Compute the centroid
centroid = mean(pts, 1);

% Subtract centroid to center the points
pts_centered = pts - centroid;

% Singular Value Decomposition
[~, ~, V] = svd(pts_centered, 'econ');

% The normal vector is the last column of V
normal = V(:, end);
normal = sign(normal(1)) .* normal; % make sure its pointing towards posterior

% Plane equation: normal(1)*x + normal(2)*y + normal(3)*z + d = 0
% where d = -normal · centroid
d = -dot(normal, centroid);
plane_eq = [normal; d];


end

function [horizontal_angle,vertical_angle] = calculateAngles(normal)

% Calculate angles in horizontal and vertical directions
% Horizontal angle (in xy-plane, angle from x-axis)
horizontal_angle = -atan2(normal(2), normal(1)) * 180/pi; % in agreement with ABBA

% Vertical angle (angle from xy-plane)
vertical_angle = asin(normal(3)) * 180/pi;
end

function [AP_plane,ML_target,DV_target] = calculateXPlane(plane_eq,ML_target,DV_target)

% Find point on plane where Y = 5700 and Z = 4200
if nargin < 2; ML_target = 5700; end
if nargin < 2; DV_target = 4000; end
% From plane equation: ax + by + cz + d = 0, solve for X
AP_plane = (-plane_eq(2)*ML_target - plane_eq(3)*DV_target - plane_eq(4)) / plane_eq(1);

end