%% This processed Allen CCFv3 data can be downloaded from https://osf.io/fv7ed/
allen_atlas_path = fileparts(which('template_volume_10um.npy'));
av = readNPY([allen_atlas_path filesep 'annotation_volume_10um_by_index.npy']); % the number at each pixel labels the area, see note below
st = load_structure_tree([allen_atlas_path filesep 'structure_tree_safe_2017.csv']); % a table of what all the labels mean
%%
IC_structure_id = st.structure_id_path{strcmp(st.acronym,'IC')};
plot_ccf_idx = find(cellfun(@(x) contains(x,IC_structure_id), ...
    st.structure_id_path));
%% not downsampled
% dims: ap, dv, ml(lr)
IC_bool = ismember(av,plot_ccf_idx);
    % smoothing
IC_bool_smth = smooth3(IC_bool,'gaussian',15,2);

    % create mesh
IC_mesh_3d = isosurface(IC_bool,0.5);
IC_mesh_3d_smth = isosurface(IC_bool_smth,0.5);

    % scaling
ccf_scale_um = 10;
IC_mesh_3d.vertices = IC_mesh_3d.vertices * ccf_scale_um;
IC_mesh_3d_smth.vertices = IC_mesh_3d_smth.vertices * ccf_scale_um;
    % reorder axes
    % IPR -> PRI as XYZ (matlab display)
IC_mesh_3d.vertices = IC_mesh_3d.vertices(:,[2,3,1]);
IC_mesh_3d_smth.vertices = IC_mesh_3d_smth.vertices(:,[2,3,1]);
IC_mesh_3d.orientation = 'PRI';
IC_mesh_3d.dimensions = {'ccf_ap','ccf_ml','ccf_dv'};
IC_mesh_3d.unit = 'micron';

IC_mesh_3d_smth.orientation = 'PRI';
IC_mesh_3d_smth.dimensions = {'ccf_ap','ccf_ml','ccf_dv'};
IC_mesh_3d_smth.unit = 'micron';

%% save mesh
save(fullfile("gen","IC_mesh_3d.mat"),"IC_mesh_3d","IC_mesh_3d_smth");

%% Plot mesh
fig = figure;
plot_structure_color = [1,.6,.6];
structure_alpha = 0.5;
ax = axes('Parent',fig,'View',[-45,15]);
IC_patch = patch(ax,'Vertices',IC_mesh_3d_smth.vertices, ...
        'Faces',IC_mesh_3d_smth.faces, ...
        'FaceColor',plot_structure_color,'EdgeColor','none','FaceAlpha',structure_alpha);
axis(ax,'equal')
ax.ZDir='reverse';
xlabel(ax,'ccf_ap (um)','Interpreter','none')
ylabel(ax,'ccf_ml (um)','Interpreter','none')
zlabel(ax,'ccf_dv (um)','Interpreter','none')
% aesthetics ---
camproj('perspective')
material(IC_patch,'metal')
lgt = camlight('left');
camlight('headlight');

%%
%%
% dims: ap, dv, ml(lr)

structure_list = ["ICc","ICe","ICd"];
for ss = 1:length(structure_list)
    structure = structure_list(ss);
    structure_id = st.structure_id_path{strcmp(st.acronym,structure)};
    plot_ccf_idx = find(cellfun(@(x) contains(x,structure_id), ...
        st.structure_id_path));
    %% not downsampled
    IC_bool = ismember(av,plot_ccf_idx);
        % smoothing
    IC_bool_smth = smooth3(IC_bool,'gaussian',15,2);

        % kicked out weird stuff
        IC_bool(:,400:end,:) = 0;
        IC_bool_smth(:,400:end,:) = 0;
    
        % create mesh
    mesh_3d = isosurface(IC_bool,0.5);
    mesh_3d_smth = isosurface(IC_bool_smth,0.5);
    
        % scaling
    ccf_scale_um = 10;
    mesh_3d.vertices = mesh_3d.vertices * ccf_scale_um;
    mesh_3d_smth.vertices = mesh_3d_smth.vertices * ccf_scale_um;
        % reorder axes
        % IPR -> PRI as XYZ (matlab display)
    mesh_3d.vertices = mesh_3d.vertices(:,[2,3,1]);
    mesh_3d_smth.vertices = mesh_3d_smth.vertices(:,[2,3,1]);

    mesh_3d.orientation = 'PRI';
    mesh_3d.dimensions = {'ccf_ap','ccf_ml','ccf_dv'};
    mesh_3d.unit = 'micron';

    mesh_3d_smth.orientation = 'PRI';
    mesh_3d_smth.dimensions = {'ccf_ap','ccf_ml','ccf_dv'};
    mesh_3d_smth.unit = 'micron';
    
    %% save mesh
    save(fullfile("gen",structure+"_mesh_3d.mat"),"mesh_3d","mesh_3d_smth");
end

%%

fig = figure;
plot_structure_color = [1,.6,.6];
structure_alpha = 0.5;
ax = axes('Parent',fig,'View',[-45,15]);
ICe = load(fullfile("gen","ICe_mesh_3d.mat"),"mesh_3d_smth");
ICe_patch = patch(ax,'Vertices',ICe.mesh_3d_smth.vertices, ...
        'Faces',ICe.mesh_3d_smth.faces, ...
        'FaceColor',plot_structure_color,'EdgeColor','none','FaceAlpha',structure_alpha);

plot_structure_color = [0,0,.6];
ICc = load(fullfile("gen","ICc_mesh_3d.mat"),"mesh_3d_smth");
ICc_patch = patch(ax,'Vertices',ICc.mesh_3d_smth.vertices, ...
        'Faces',ICc.mesh_3d_smth.faces, ...
        'FaceColor',plot_structure_color,'EdgeColor','none','FaceAlpha',structure_alpha);


plot_structure_color = [0,.6,0];
ICd = load(fullfile("gen","ICd_mesh_3d.mat"),"mesh_3d_smth");
ICd_patch = patch(ax,'Vertices',ICd.mesh_3d_smth.vertices, ...
        'Faces',ICd.mesh_3d_smth.faces, ...
        'FaceColor',plot_structure_color,'EdgeColor','none','FaceAlpha',structure_alpha);

axis(ax,'equal')
ax.ZDir='reverse';
xlabel(ax,'ccf_ap (um)','Interpreter','none')
ylabel(ax,'ccf_ml (um)','Interpreter','none')
zlabel(ax,'ccf_dv (um)','Interpreter','none')

%% Brain
tic
downsample_factor = 2;
fprintf('Downsampling factor: %d\n',downsample_factor)
brain_bool = av(downsample_factor:downsample_factor:end,...
                downsample_factor:downsample_factor:end,...
                downsample_factor:downsample_factor:end) > 1;
% brain_bool_smth = smooth3(brain_bool,'gaussian',15,2);

fprintf('Creating mesh using isosurface...\n')
mesh_3d = isosurface(brain_bool,0.5);
% mesh_3d_smth = isosurface(brain_bool_smth,0.5);

    % scaling
ccf_scale_um = 10;
scale_factor = downsample_factor* ccf_scale_um;
fprintf('Scaling vertices in mesh by %d...\n',scale_factor)
mesh_3d.vertices = mesh_3d.vertices * scale_factor;
% mesh_3d_smth.vertices = mesh_3d_smth.vertices * scale_factor;

    % orientation
fprintf('Re-ordering dimensions to AP, ML, DV...\n')
mesh_3d.vertices = mesh_3d.vertices(:,[2,3,1]);
toc

%% checking
fig = figure;
plot_structure_color = [.5,.5,.5];
structure_alpha = 0.2;
ax = axes('Parent',fig,'View',[-45,15]);
brain = patch(ax,'Vertices',mesh_3d.vertices, ...
        'Faces',mesh_3d.faces, ...
        'FaceColor',plot_structure_color,'EdgeColor','none','FaceAlpha',structure_alpha);

% --- formatting ---
axis(ax,'equal')
ax.ZDir='reverse';
xlabel(ax,'ccf_ap (um)','Interpreter','none')
ylabel(ax,'ccf_ml (um)','Interpreter','none')
zlabel(ax,'ccf_dv (um)','Interpreter','none')
% ------------------
%% saving
structure = 'brain';
save(fullfile("gen",structure+"_mesh_3d.mat"),"mesh_3d");

%% Mid-brain
structure_id = st.structure_id_path{strcmp(st.acronym,'MB')};
plot_ccf_idx = find(cellfun(@(x) contains(x,structure_id), ...
    st.structure_id_path));
downsample_factor = 2;
tic
fprintf('Downsampling factor: %d\n',downsample_factor)
MB_bool = ismember(av(downsample_factor:downsample_factor:end,...
                downsample_factor:downsample_factor:end,...
                downsample_factor:downsample_factor:end)...
                ,plot_ccf_idx);
fprintf('Smoothing...\n')
MB_bool_smth = smooth3(MB_bool,'gaussian',15,2/downsample_factor);

fprintf('Creating mesh using isosurface...\n')
mesh_3d = isosurface(MB_bool,0.5);
mesh_3d_smth = isosurface(MB_bool_smth,0.5);

    % scaling
ccf_scale_um = 10;
scale_factor = downsample_factor* ccf_scale_um;
fprintf('Scaling vertices in mesh by %d...\n',scale_factor)
mesh_3d.vertices = mesh_3d.vertices * scale_factor;
mesh_3d_smth.vertices = mesh_3d_smth.vertices * scale_factor;


    % orientation
fprintf('Re-ordering dimensions to AP, ML, DV...\n')
mesh_3d.vertices = mesh_3d.vertices(:,[2,3,1]);
mesh_3d_smth.vertices = mesh_3d_smth.vertices(:,[2,3,1]);
toc
%% checking
fig = figure;
plot_structure_color = [.5,.5,.5];
structure_alpha = 0.2;
ax = axes('Parent',fig,'View',[-45,15]);

h_patch = patch(ax,'Vertices',mesh_3d.vertices, ...
        'Faces',mesh_3d.faces, ...
        'FaceColor',plot_structure_color,'EdgeColor','none','FaceAlpha',structure_alpha);
if exist("mesh_3d_smth","var")
    plot_structure_color = [.0,.5,.5];
    h_patch_smth = patch(ax,'Vertices',mesh_3d_smth.vertices, ...
            'Faces',mesh_3d_smth.faces, ...
            'FaceColor',plot_structure_color,'EdgeColor','none','FaceAlpha',structure_alpha);
end
% --- formatting ---
axis(ax,'equal')
ax.ZDir='reverse';
xlabel(ax,'ccf_ap (um)','Interpreter','none')
ylabel(ax,'ccf_ml (um)','Interpreter','none')
zlabel(ax,'ccf_dv (um)','Interpreter','none')
% ------------------
%% saving
structure = 'MB';
save(fullfile("gen",structure+"_mesh_3d.mat"),"mesh_3d");

%% ----- local functions -----
function structureTreeTable = load_structure_tree(fn)

if nargin<1
    p = mfilename('fullpath');
    fn = fullfile(fileparts(fileparts(p)), 'structure_tree_safe_2017.csv');
end

[~, fnBase] = fileparts(fn);
if ~isempty(strfind(fnBase, '2017'))
    mode = '2017';
else
    mode = 'old';
end

fid = fopen(fn, 'r');

if strcmp(mode, 'old')
    titles = textscan(fid, '%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s', 1, 'delimiter', ',');
    titles = cellfun(@(x)x{1}, titles, 'uni', false);
    titles{1} = 'index'; % this is blank in the file

    data = textscan(fid, '%d%s%d%s%d%s%d%d%d%d%d%s%s%d%d%s%d%s%s%d%d', 'delimiter', ',');

elseif strcmp(mode, '2017')
    titles = textscan(fid, repmat('%s', 1, 21), 1, 'delimiter', ',');
    titles = cellfun(@(x)x{1}, titles, 'uni', false);

    data = textscan(fid, ['%d%d%s%s'... % 'id'    'atlas_id'    'name'    'acronym'
        '%s%d%d%d'... % 'st_level'    'ontology_id'    'hemisphere_id'    'weight'
        '%d%d%d%d'... % 'parent_structure_id'    'depth'    'graph_id'     'graph_order'
        '%s%s%d%s'... % 'structure_id_path'    'color_hex_triplet' neuro_name_structure_id neuro_name_structure_id_path
        '%s%d%d%d'... % 'failed'    'sphinx_id' structure_name_facet failed_facet
        '%s'], 'delimiter', ','); % safe_name

    titles = ['index' titles];
    data = [[0:numel(data{1})-1]' data];

end


structureTreeTable = table(data{:}, 'VariableNames', titles);

fclose(fid);

end