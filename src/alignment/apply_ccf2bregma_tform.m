function [bregma_table] = apply_ccf2bregma_tform(ccf_table,ccf_bregma_tform)
%apply_ccf2bregma_tform 
%     ccf_scale_um = 1; % um; 1000 um = 1 mm
%     bregma_scale_um = 1; % um; 1000 um = 1 mm
%     ccf_bregma_tform = AW_ccf2bregma_IBL(ccf_scale_um,bregma_scale_um);
    [bregma_ml,bregma_ap,bregma_dv] = ...
        transformPointsForward(ccf_bregma_tform,ccf_table.ccf_ml,ccf_table.ccf_ap,ccf_table.ccf_dv);
    bregma_table = table(bregma_ap,bregma_dv,bregma_ml);
end