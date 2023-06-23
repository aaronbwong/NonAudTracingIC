function AW_reorderHistology(im_fn,im_rgb,im_out_path)
    
    n_slices = length(im_fn);
    nrows = floor(sqrt(n_slices));
    ncols = ceil( n_slices / nrows );

    curr_montage = montage(im_rgb,'Size',[nrows,Inf]);
    set(curr_montage,'ButtonDownFcn',@slice_click);
    h_fig = gcf; 
    set(h_fig,'KeyPressFcn',@keypress)
    C = curr_montage.CData;
    width = size(C,2);
    height = size(C,1);

    montage_data = struct;
    montage_data.h_fig = h_fig;
    montage_data.curr_montage = curr_montage;
    montage_data.n_slices = n_slices;
    montage_data.im_fn = im_fn;
    montage_data.im_rgb = im_rgb;
    montage_data.im_out_path = im_out_path;
    montage_data.nrows = nrows;
    montage_data.ncols = ncols;
    montage_data.width = width;
    montage_data.height = height;
    montage_data.panelWidth = width / ncols;
    montage_data.panelHeight = height / nrows;
    montage_data.CData_ori = C;
    montage_data.currSlice = 0;
    guidata(curr_montage, montage_data);

end


function slice_click(curr_montage,eventdata)
% On slice click, mark to extract

montage_data = guidata(curr_montage);


if eventdata.Button == 1
    x = eventdata.IntersectionPoint(1);
    y = eventdata.IntersectionPoint(2);
    row = ceil(y / (montage_data.height/montage_data.nrows));
    col = ceil(x / (montage_data.width/montage_data.ncols));
    slice_num = (row-1)*montage_data.ncols + col;
    if montage_data.currSlice == 0
        montage_data.currSlice = slice_num;
        guidata(montage_data.curr_montage, montage_data);
    else
        swap_slices(curr_montage,slice_num,montage_data.currSlice);
    end

end

end

function swap_slices(curr_montage,a,b)
montage_data = guidata(curr_montage);

[xRangeA,yRangeA] = img_range(curr_montage,a);
imgA = montage_data.curr_montage.CData(yRangeA,xRangeA,:);

[xRangeB,yRangeB] = img_range(curr_montage,b);
imgB = montage_data.curr_montage.CData(yRangeB,xRangeB,:);

montage_data.curr_montage.CData(yRangeB,xRangeB,:) = imgA;
montage_data.curr_montage.CData(yRangeA,xRangeA,:) = imgB; 

fn_A = montage_data.im_fn{a};
fn_B = montage_data.im_fn{b};
montage_data.im_fn{a} = fn_B;
montage_data.im_fn{b} = fn_A;

img_rgb_A = montage_data.im_rgb{a};
img_rgb_B = montage_data.im_rgb{b};
montage_data.im_rgb{a} = img_rgb_B;
montage_data.im_rgb{b} = img_rgb_A;

montage_data.currSlice = 0;

guidata(curr_montage,montage_data);
end

function [xrange,yrange] = img_range(montage_fig,a)
montage_data = guidata(montage_fig);
panelWidth = montage_data.panelWidth;
panelHeight = montage_data.panelHeight;
ncols = montage_data.ncols;
xrange = panelWidth * mod(a-1,  ncols)+(1:panelWidth);
yrange = panelHeight * floor((a-1)/ncols) + (1:panelHeight);

end


function keypress(montage_fig,eventdata)

montage_data = guidata(montage_fig);

im_out_path = montage_data.im_out_path;
im_rgb = montage_data.im_rgb;

switch eventdata.Key
    case 'escape'
            
    if ~exist(im_out_path,'dir')
        mkdir(im_out_path)
    end
    
    % Write all slice images to separate files
    
    disp('Saving slice images...');
    n_img = length(im_rgb);
    out_fn = cell(n_img,1);
    for curr_im = 1:length(im_rgb)
        curr_fn = [im_out_path filesep num2str(curr_im,'s%03d') '.tif'];
        out_fn{curr_im} = curr_fn;
        imwrite(im_rgb{curr_im},curr_fn,'tif');
    end
    disp('Done.');

    save_fn = [im_out_path filesep 'slice_order.csv'];
    [~,ori_fn,ori_ext] = fileparts(montage_data.im_fn);
    ori_filename = cellfun(@(fn,ext) [fn ext], ...
    ori_fn(:),ori_ext(:),'uni',false);
    order = (1:length(ori_filename))';
    csvtable = table(ori_filename,order,out_fn);
    writetable(csvtable,save_fn);

    close(montage_fig);
end
end

