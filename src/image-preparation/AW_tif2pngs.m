function AW_tif2pngs(im_out_path,format,prefix)

    slice_order_fn = [im_out_path filesep 'slice_order.csv'];
    if exist(slice_order_fn,"file")
        slice_order = readtable(slice_order_fn);
    else
        disp('Downsample images first!')
        return
    end

    n_im = size(slice_order,1);
    h = waitbar(0,'Converting images...');

    in_fn = cellfun(@(fn) [im_out_path,filesep, fn], ...
            slice_order.out_fn(:),'uni',false);
    out_fn = cellfun(@(fn) [im_out_path,filesep, prefix, '_', fn(1:end-3), format], ...
            slice_order.out_fn(:),'uni',false);
    for curr_im = 1:n_im
        im_rgb = imread(in_fn{curr_im});
        curr_fn = out_fn{curr_im};
        imwrite(im_rgb,curr_fn,format);
        waitbar(curr_im/n_im,h,['Converting images (' num2str(curr_im) '/' num2str(n_im) ')...']);
    end
    close(h);


