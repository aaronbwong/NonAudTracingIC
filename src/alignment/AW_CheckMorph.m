%% Load Allen CCFv3
allen_atlas_path = fileparts(which('template_volume_10um.npy'));
if ~exist("av","var")
    av = readNPY([allen_atlas_path filesep 'annotation_volume_10um_by_index.npy']); % the number at each pixel labels the area, see note below
end
if  ~exist("tv","var")
    tv = readNPY([allen_atlas_path filesep 'template_volume_10um.npy']);
end
% dimensions: ap, dv, ml
%% Load Slice Grid CSV
if exist("filepath","var")
    [filename, filepath] = uigetfile('*.csv', 'Select CSV file to load',[filepath,'\']);
else
    [filename, filepath] = uigetfile('*.csv', 'Select CSV file to load');
end
Slice = readtable(fullfile(filepath, filename));
AW_fitPlane
AW_fitAffine
% Slice = readtable(fullfile(filepath, filename));
%% 

% reorient vector 
atlas_vector = [normal(1),normal(2),normal(3)];  % ap, ml, dv
atlas_point = 0.1 * [AP_plane; ML_target; DV_target]; % um -> 10um
point_spacing = 1;

%
[atlas_slice,atlas_coords] = ap_histology.grab_atlas_slice(av,tv,atlas_vector,atlas_point,point_spacing);

figure('Position',[200,100,600,900])
subplot(2,1,1)
imagesc(atlas_slice.tv);colormap("gray")
subplot(2,1,2)
imagesc(atlas_slice.av);colormap("gray")

% Overlay Image Grid

max_image_x = max(Slice.image_x);
max_image_y = max(Slice.image_y);

markerColor = 0.25 + 0.75 .* ...
            [ [1].*Slice.image_x ./ max_image_x, ... % R
              zeros(height(Slice),1),... %G
              [1].*Slice.image_y ./ max_image_y]; % B

subplot(2,1,1)
hold on;
scatter(0.1*Slice.ccf_ml,0.1*Slice.ccf_dv,10,markerColor,'+') % um -> 10um
hold off;

subplot(2,1,2)
hold on;
scatter(0.1*Slice.ccf_ml,0.1*Slice.ccf_dv,10,markerColor,'+') % um -> 10um
hold off;

%% Load image
if exist("image_filepath","var")
    [image_filename, image_filepath] = uigetfile('*.tif', 'Select Tiff file to load',[image_filepath,'\']);
else
    [image_filename, image_filepath] = uigetfile('*.tif', 'Select Tiff file to load');
end
img = imread(fullfile(image_filepath,image_filename));
img = img*10;
%%
markerColor = lines(numPoints);
markerColor = markerColor(randperm(numPoints),:);
% Group points by image_x
[unique_x, ~, x_idx] = unique(Slice.image_x);
% Group points by image_y
[unique_y, ~, y_idx] = unique(Slice.image_y);

figure('Position',[200,100,1200,900]);
subplot(2,2,1)
imagesc(atlas_slice.tv);colormap("gray")
hold on;
% scatter(0.1*Slice.ccf_ml,0.1*Slice.ccf_dv,10,markerColor,'+') % um -> 10um
for i = 1:length(unique_x)
    mask = x_idx == i;
    plot(0.1*Slice.ccf_ml(mask), 0.1*Slice.ccf_dv(mask), 'color', "white", 'LineWidth', 1);
end
for i = 1:length(unique_y)
    mask = y_idx == i;
    plot(0.1*Slice.ccf_ml(mask), 0.1*Slice.ccf_dv(mask), 'color', "white", 'LineWidth', 1);
end
hold off;

subplot(2,2,2)
imagesc(img);
hold on;
% scatter(Slice.image_y,Slice.image_x,10,markerColor,'+') % um -> 10um
for i = 1:length(unique_x)
    mask = x_idx == i;
    plot(Slice.image_y(mask), Slice.image_x(mask), 'color', "white", 'LineWidth', 1);
end
for i = 1:length(unique_y)
    mask = y_idx == i;
    plot(Slice.image_y(mask), Slice.image_x(mask), 'color', "white", 'LineWidth', 1);
end
hold off;

subplot(2,2,3)
imagesc(atlas_slice.tv);colormap("gray")
hold on;
% scatter(0.1*Slice.ccf_ml_affine,0.1*Slice.ccf_dv_affine,10,markerColor,'+') % um -> 10um
for i = 1:length(unique_x)
    mask = x_idx == i;
    plot(0.1*Slice.ccf_ml_affine(mask), 0.1*Slice.ccf_dv_affine(mask), 'color', "white", 'LineWidth', 1);
end
for i = 1:length(unique_y)
    mask = y_idx == i;
    plot(0.1*Slice.ccf_ml_affine(mask), 0.1*Slice.ccf_dv_affine(mask), 'color', "white", 'LineWidth', 1);
end
hold off;

subplot(2,2,4)
imagesc(img);
hold on;
% scatter(Slice.image_y,Slice.image_x,10,markerColor,'+') % um -> 10um
for i = 1:length(unique_x)
    mask = x_idx == i;
    plot(Slice.image_y(mask), Slice.image_x(mask), 'color', "white", 'LineWidth', 1);
end
for i = 1:length(unique_y)
    mask = y_idx == i;
    plot(Slice.image_y(mask), Slice.image_x(mask), 'color', "white", 'LineWidth', 1);
end
hold off;
subplot(2,2,3)
hold on;

hold off;

% %% add affine approximation
% hold on;
% scatter(0.1*Slice.ccf_ml_affine,0.1*Slice.ccf_dv_affine,10,"yellow",'+') % um -> 10um
% hold off;