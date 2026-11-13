function probe_tracts_tbl = analyze_probetracts_insertion(brain,probe_tracts_tbl)
    % ANALYZE_PROBETRACTS_INSERTION 
    % brain: struct containing brain mesh data in ccf coordinates
    % probe_tracts_tbl: table containing information about probe tracts
    %                   it should contain 
    %       - ccf_ap, ccf_ml, ccf_dv, each is a vector
    %               defining points along the tracts ap,ml,dv positions 
    %               in ccf coordinates (um)
    %       - tip_depth_rec: [optional field] how deep the penetration was
    %       as monitored during the recording. Used to estimate actual
    %       position of the probe based on trajectory and location of brain
    %       surface
    %               

    ccf_scale_um = 1; %um; data scaled in um
    bregma_scale_um = 1; %um; data scaled in um
    ccf_bregma_tform = AW_ccf2bregma_IBL(ccf_scale_um,bregma_scale_um);

    vert0 = brain.mesh_3d.vertices(brain.mesh_3d.faces(:,1),:);
    vert1 = brain.mesh_3d.vertices(brain.mesh_3d.faces(:,2),:);
    vert2 = brain.mesh_3d.vertices(brain.mesh_3d.faces(:,3),:);
    for i_tract = 1:height(probe_tracts_tbl)
        probe_tract = [probe_tracts_tbl.ccf_ap{i_tract},...
                       probe_tracts_tbl.ccf_ml{i_tract},...
                       probe_tracts_tbl.ccf_dv{i_tract}];
        probe_tract = sortrows(probe_tract,3,'descend'); % largest dv (deepest) first
        probe_tract_bregma = apply_ccf2bregma_tform(probe_tract,ccf_bregma_tform,{'ap','ml','dv'});
        
        orig = probe_tract(1,:);
        orig_bregma = probe_tract_bregma(1,:);
        
        direction = [diff(probe_tract)];
        tract_length = norm(direction);
        direction = direction ./ tract_length;
        
        direction_bregma = [diff(probe_tract_bregma)];
        tract_length_bregma = norm(direction_bregma);
        direction_bregma = direction_bregma ./ tract_length_bregma;
        
        [intersect, ~, ~, ~, xcoor] = TriangleRayIntersection(orig,direction,vert0,vert1,vert2,'lineType','ray');
        
        insertion_points = xcoor(intersect,:);
        insertion_points_bregma = apply_ccf2bregma_tform(insertion_points,ccf_bregma_tform,{'ap','ml','dv'});
        
        % depth
        if size(insertion_points,1) > 0
            [~,idx] = min(insertion_points(:,3));
            most_dorsal_point = insertion_points(idx,:);
            most_dorsal_point_bregma = insertion_points_bregma(idx,:);
            tip_depth = norm(probe_tract(1,:) - most_dorsal_point);
            tip_depth_bregma = norm(probe_tract_bregma(1,:) - most_dorsal_point_bregma);
        else
            most_dorsal_point = [];
            tip_depth = nan;
            tip_depth_bregma = nan;
        end
    
        probe_tracts_tbl.tip_depth_ccf(i_tract) = tip_depth;
        probe_tracts_tbl.tip_depth_bregma(i_tract) = tip_depth_bregma;
        probe_tracts_tbl.insertion_point_ccf{i_tract} = insertion_points;
        probe_tracts_tbl.insertion_point_bregma{i_tract} = insertion_points_bregma;

        % re-estimate probe tip location by penetration depth
        if contains('tip_depth_rec',probe_tracts_tbl.Properties.VariableNames) ...
            && ~isempty(most_dorsal_point)
            ccf_tip_calc = most_dorsal_point + direction * probe_tracts_tbl.tip_depth_rec(i_tract);
            probe_tracts_tbl.ccf_ap_calc{i_tract} = [most_dorsal_point(:,1); ccf_tip_calc(:,1)];
            probe_tracts_tbl.ccf_ml_calc{i_tract} = [most_dorsal_point(:,2); ccf_tip_calc(:,2)];
            probe_tracts_tbl.ccf_dv_calc{i_tract} = [most_dorsal_point(:,3); ccf_tip_calc(:,3)];
        end
       
    end
end