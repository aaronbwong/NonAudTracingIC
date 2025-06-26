function [cluster_position, ccf_table] = site_position_lookup(mouse, clusters)
%% load channel map

if mouse == 27 % M27
    %channel_map_file_path = '';
else % M21, 22, 23, 24
    %channel_map_file_path = '';
end
load(channel_map_file_path, ...
    'chanMap','xcoords','ycoords','kcoords')

%% load probe track

if mouse == 21 || mouse == 22
    %probe_track_csv_path = '';
else
    %probe_track_csv_path = '';
end
ccf_table = readtable(probe_track_csv_path);

%% find minimum point as tip

[~,tip_idx] = max(ccf_table.ccf_dv);
[~,shaft_idx] = min(ccf_table.ccf_dv);

%% convert to bregma coordinate (for scaling)

ccf_scale_um = 1; % um; 1000 um = 1 mm
bregma_scale_um = 1; % um; 1000 um = 1 mm
ccf_bregma_tform = AW_ccf2bregma_IBL(ccf_scale_um,bregma_scale_um);

bregma_table = apply_ccf2bregma_tform(ccf_table,ccf_bregma_tform);

%% find vector from tip

tip_bregma = table2array(bregma_table(tip_idx,:));
shaft_bregma = table2array(bregma_table(shaft_idx,:));

probe_vector = shaft_bregma - tip_bregma;
probe_vector = probe_vector./ norm(probe_vector);

%% allocate electorde sites
% assumming tip is deepest electrode site in channel map
ycoords_norm = ycoords - min(ycoords);
electrode_bregma = tip_bregma + probe_vector .* ycoords_norm;
electrode_bregma_table = array2table(electrode_bregma,"VariableNames",bregma_table.Properties.VariableNames);
electrode_ccf_table = apply_bregma2ccf_tform(electrode_bregma_table,ccf_bregma_tform);
electrode_ccf_table.chan_id = chanMap;
electrode_ccf_table.xcoords = xcoords;
electrode_ccf_table.kcoords = kcoords;
% TODO: apply xcoords
%% read in cluster info
%cluster_info_path = '':
cluster_info_dir = dir([cluster_info_path '\*_InfoGoodUnits.mat']);
load([cluster_info_dir.folder '\' cluster_info_dir.name], 'clusterinfo');

%% find cluster location
for ii = 1:length(clusters)
    cluster_channel_0ind(ii) = clusterinfo.channel(clusterinfo.id==clusters(ii));
    cluster_channel(ii) = cluster_channel_0ind(ii) + 1;
    idx = electrode_ccf_table.chan_id == cluster_channel(ii);
    cluster_ccf_ap(ii) = electrode_ccf_table.ccf_ap(idx);
    cluster_ccf_dv(ii) = electrode_ccf_table.ccf_dv(idx);
    cluster_ccf_ml(ii) = electrode_ccf_table.ccf_ml(idx);
end

cluster_position = table(repmat(mouse, length(clusters), 1), clusters(:),cluster_channel(:),cluster_ccf_ap(:),cluster_ccf_dv(:),cluster_ccf_ml(:), ...
    'VariableNames',{'mouse_nr', 'cluster_nr','channel','ccf_ap','ccf_dv','ccf_ml'});

end