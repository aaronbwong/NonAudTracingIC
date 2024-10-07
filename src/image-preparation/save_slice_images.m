function save_slice_images(im_fn, resize_factor, im_rgb, im_out_path,prefix,rotate90CW,flipHori)
    % im_fn
    % resize_factor
    % im_rgb: N x 1 cell array containing images

    n_img = length(im_rgb);
    out_fn_dir = cell(n_img,1);
    if (~exist('prefix','var') || isempty(prefix)); prefix = 'Brain'; end
    for curr_im = 1:length(im_rgb)
        curr_fn = [im_out_path, filesep, prefix, '_', num2str(curr_im,'s%03d'), '.jpg'];
        out_fn_dir{curr_im} = curr_fn;
        imwrite(im_rgb{curr_im},curr_fn,'jpg');
    end
    
    % Save a record of file correspondance
    slice_order_fn = [im_out_path filesep 'slice_order.csv'];
    
        % original path and name
        [im_path,ori_fn,ori_ext] = fileparts(im_fn);
        ori_filename = cellfun(@(fn,ext) [fn ext], ...
            ori_fn(:),ori_ext(:),'uni',false);
        im_path = im_path(:);
        % slice order
        order = (1:n_img)';

        % output name
        [~,out_fn,out_ext] = fileparts(out_fn_dir);
        out_fn = cellfun(@(fn,ext) [fn ext], ...
            out_fn(:),out_ext(:),'uni',false);

        % resize_factor
        if length(resize_factor) ~= n_img
            resize_factor = repmat(resize_factor, n_img,1);
        end
    csvtable = table(order,im_path,ori_filename,resize_factor,out_fn);
    if (exist('rotate90CW','var') && ~isempty(rotate90CW))
        csvtable.rotate90CW = rotate90CW;
    end
    if (exist('flipHori','var') && ~isempty(flipHori))
        csvtable.flipHori = flipHori;
    end
    writetable(csvtable,slice_order_fn);
end