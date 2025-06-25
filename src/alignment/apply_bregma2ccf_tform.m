function [ccf_table] = apply_bregma2ccf_tform(bregma_table,ccf_bregma_tform)
%apply_ccf2bregma_tform 
%     ccf_scale_um = 1; % um; 1000 um = 1 mm
%     bregma_scale_um = 1; % um; 1000 um = 1 mm
%     ccf_bregma_tform = AW_ccf2bregma_IBL(ccf_scale_um,bregma_scale_um);
    [ccf_ml,ccf_ap,ccf_dv] = ...
        transformPointsInverse(ccf_bregma_tform,bregma_table.bregma_ml,bregma_table.bregma_ap,bregma_table.bregma_dv);
    ccf_table = table(ccf_ap,ccf_dv,ccf_ml);
end