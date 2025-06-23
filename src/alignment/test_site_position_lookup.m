%% load channel map

load(channel_map_file_path, ...
    'chanMap','xcoords','ycoords','kcoords')


%% load probe track

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