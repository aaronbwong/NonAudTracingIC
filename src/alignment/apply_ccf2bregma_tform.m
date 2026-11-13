function [bregma_table] = apply_ccf2bregma_tform(ccf_table,ccf_bregma_tform,dimOrder)
%apply_ccf2bregma_tform 
    if nargin < 3; dimOrder = {'ap','ml','dv'}; end
%     ccf_scale_um = 1; % um; 1000 um = 1 mm
%     bregma_scale_um = 1; % um; 1000 um = 1 mm
%     ccf_bregma_tform = AW_ccf2bregma_IBL(ccf_scale_um,bregma_scale_um);
    matrix_input = ismatrix(ccf_table);
    if matrix_input
        T = table();
        T.ccf_ap = ccf_table(:,strcmpi(dimOrder,'ap'));
        T.ccf_ml = ccf_table(:,strcmpi(dimOrder,'ml'));
        T.ccf_dv = ccf_table(:,strcmpi(dimOrder,'dv'));
        ccf_table = T;
    end

    [bregma_ml,bregma_ap,bregma_dv] = ...
        transformPointsForward(ccf_bregma_tform,ccf_table.ccf_ml,ccf_table.ccf_ap,ccf_table.ccf_dv);
    bregma_table = table(bregma_ap,bregma_dv,bregma_ml);

    if matrix_input
        T = nan(size(bregma_table));
        T(:,strcmpi(dimOrder,'ap')) = bregma_table.bregma_ap;
        T(:,strcmpi(dimOrder,'ml')) = bregma_table.bregma_ml;
        T(:,strcmpi(dimOrder,'dv')) = bregma_table.bregma_dv;
        bregma_table = T;
    end
end