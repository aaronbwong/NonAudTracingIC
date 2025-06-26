%% ANALYSIS

mice = [21 22 23 24 27]; % all mice numbers

% cell array units per mouse
good_clusters_all = {
    [290 312 321 346];      % M21
    [ ];                    % M22
    [284 292];              % M23
    [376 408 470 476 522];  % M24
    [118 189]               % M27
    };

good_cluster_table = table();
ccf_table = table();


for i = 1:length(mice)
    good_clusters = good_clusters_all{i};
    if isempty(good_clusters); continue; end

    [tcluster_position, tccf_table] = site_position_lookup(mice(i), good_clusters);

    % add info and combine tables
    tccf_table = [table([mice(i); mice(i)], 'VariableNames', {'mouse_nr'}), tccf_table];
    ccf_table = [ccf_table; tccf_table];
    good_cluster_table = [good_cluster_table; tcluster_position];

end

%% PLOTTING
% display cluster location

colors = lines(length(mice));

for i = 1:length(mice)
    mouse_id = mice(i);
    idx = good_cluster_table.mouse_nr == mouse_id;

    % Plot each mouse's points in a different color
    scatter3(good_cluster_table.ccf_ap(idx), ...
             good_cluster_table.ccf_ml(idx), ...
             good_cluster_table.ccf_dv(idx), ...
             50, colors(i,:), 'filled');

    % TO DO: fit line in probe track

    % Add cluster number labels
    for j = find(idx)'
        text(good_cluster_table.ccf_ap(j), ...
             good_cluster_table.ccf_ml(j), ...
             good_cluster_table.ccf_dv(j), ...
             num2str(good_cluster_table.cluster_nr(j)), 'FontSize', 14);
    end

    hold on
end

% Final touches
ax = gca;
ax.ZDir = 'reverse';
axis(ax, 'equal')
legend(ax, cellstr(string(mice)));

%% plot line

%% Add IC mask

plot_structure_color = [.5,.5,.5];
structure_alpha = 0.3;
ylim([-Inf,5700])
IC_patch = patch(ax,'Vertices',IC_mesh_3d_smth.vertices, ...
    'Faces',IC_mesh_3d_smth.faces, ...
    'FaceColor',plot_structure_color,'EdgeColor','none','FaceAlpha',structure_alpha);

%% save figure

%% aesthetics ---
camproj('perspective')
material(IC_patch,'metal')
lgt = camlight('left');
lgt2 = camlight('headlight');