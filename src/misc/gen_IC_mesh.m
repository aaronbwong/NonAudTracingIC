%% This processed Allen CCFv3 data can be downloaded from https://osf.io/fv7ed/
allen_atlas_path = fileparts(which('template_volume_10um.npy'));
av = readNPY([allen_atlas_path filesep 'annotation_volume_10um_by_index.npy']); % the number at each pixel labels the area, see note below
st = load_structure_tree([allen_atlas_path filesep 'structure_tree_safe_2017.csv']); % a table of what all the labels mean
%%
IC_structure_id = st.structure_id_path{strcmp(st.acronym,'IC')};
plot_ccf_idx = find(cellfun(@(x) contains(x,IC_structure_id), ...
    st.structure_id_path));
%% not downsampled

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