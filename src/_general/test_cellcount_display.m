% List of CSV file paths
csvFilePaths = {
    'V:\Data\ProcessedData\Falk\Histology\20240725-02969-22535\Tiffs 10x\CellCount_ABBA_wRotation\02969-22535_tdTomato_ABBAConvert.csv',...
...%     'V:\Data\ProcessedData\Falk\Histology\20240725-02969-22534\10x TIFF\CellCount_ABBA_wRotation\02969-22534_tdTomato_ABBAConvert.csv',...
...%     'V:\Data\ProcessedData\Falk\Histology\20240626-02888-22007\TIFFS 10x\Cellcount_ABBAoutput_20250211\02888-22007_tdTomato_ABBAConvert.csv'
    'H:\ProcessedData\Falk\Histology\20240626-02888-22007\TIFFS 10x\Cellcount_ABBA_output3\02888-22007_tdTomato_ABBAConvert.csv',...
%     'H:\ProcessedData\Falk\Histology\20240626-02888-22007\TIFFS 10x\Cellcount_ABBAoutput_20250211\02888-22007_tdTomato_ABBAConvert.csv'
    % Add more file paths as needed
};
% DisplayNameList = {'22535','22534','22007'};
% DisplayNameList = {'22007-output3','22007-new'};
DisplayNameList = {'22535','22007'};
% Display the cell distribution volume
gui_fig = AW_view_celldistribution_volume(csvFilePaths,DisplayNameList);
% ColorList = turbo(length(csvFilePaths));
% for iCsv = 2:length(csvFilePaths)
%     % Add cell distribution volume to the image
%     gui_fig = AW_add_celldistribution_volume(gui_fig,csvFilePaths{iCsv},ColorList(iCsv,:));
% end
%%
% Load CCF atlas
% -- Compnuter specific ---
allen_atlas_path = 'W:\Documents - Work\Software\Codes\Matlab\AllenCCF';
% -------------------------
if ~exist("tv","var")
    tv = readNPY([allen_atlas_path filesep 'template_volume_10um.npy']);
end
if ~exist("av","var")
    av = readNPY([allen_atlas_path filesep 'annotation_volume_10um_by_index.npy']);
end
if ~exist("st","var")
    st = AP_loadStructureTree([allen_atlas_path filesep 'structure_tree_safe_2017.csv']);
end

%%
plot_structure = strcmp(st.acronym,'IC');
% Get all areas within and below the selected hierarchy level
    plot_structure_id = st.structure_id_path{plot_structure};
    plot_ccf_idx = find(cellfun(@(x) contains(x,plot_structure_id), ...
        st.structure_id_path));
    plot_structure_color = hex2dec(reshape(st.color_hex_triplet{plot_structure},2,[])')./255;
    structure_alpha = 0.2;

    atlas_downsample = 5; % (downsample atlas to make this faster)
    [ap_grid_ccf,dv_grid_ccf,ml_grid_ccf] = ...
        ndgrid(1:atlas_downsample:size(av,1), ...
        1:atlas_downsample:size(av,2), ...
        1:atlas_downsample:size(av,3));
    structure_3d = isosurface(ap_grid_ccf,ml_grid_ccf,dv_grid_ccf, ...
        ismember(av(1:atlas_downsample:end, ...
        1:atlas_downsample:end,1:atlas_downsample:end),plot_ccf_idx),0);
    patch(gca, ...
        'Vertices',structure_3d.vertices, ...
        'Faces',structure_3d.faces, ...
        'FaceColor',plot_structure_color,'EdgeColor','none','FaceAlpha',structure_alpha);
