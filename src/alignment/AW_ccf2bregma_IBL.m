function ccf_bregma_tform = AW_ccf2bregma_IBL(ccf_scale_um,bregma_scale_um)
    
    %% Make transform matrix from CCF to bregma/mm coordinates

%     % scaling of 
%     ccf_scale_um = 1; % um; 1000 um = 1 mm
%     bregma_scale_um = 1000; % um; 1000 um = 1 mm

    % Set average stereotaxic bregma-lambda distance, set initial scale to 1
    bregma_lambda_distance_avg = 4.1; % Currently approximation
    


    % (translation values from our bregma estimate: AP/ML from Paxinos, DV from
    % rough MRI estimate)
    bregma_ccf = [5705,4800,550] ./ ccf_scale_um; % [ML,AP,DV]
    ccf_translation_tform = eye(4)+[zeros(3,4);-bregma_ccf,0];
    
    % (scaling "Toronto MRI transform", reflect AP/ML, convert 10um to 1mm)
    scale = [0.952,-1.031,0.885].*(ccf_scale_um/bregma_scale_um); % [ML,AP,DV]
    ccf_scale_tform = eye(4).*[scale,1]';
    
    % (rotation values from IBL estimate)
    ap_rotation = 5; % tilt the CCF 5 degrees nose-up
    ccf_rotation_tform = ...
        [1 0 0 0; ...
        0 cosd(ap_rotation) -sind(ap_rotation) 0; ...
        0 sind(ap_rotation) cosd(ap_rotation) 0; ...
        0 0 0 1];
    
    ccf_bregma_tform_matrix = ccf_translation_tform*ccf_scale_tform*ccf_rotation_tform;
    ccf_bregma_tform = affine3d(ccf_bregma_tform_matrix);

