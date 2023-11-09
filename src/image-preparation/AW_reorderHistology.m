function AW_reorderHistology(im_out_path)
    % rotate90CW and flipHori specify orientations
    % we keep the following convention: 
    %   - first rotate rotate90CW times 90 degrees clockwise
    %   - then flip horizontally if flipHori == 1

    slice_order_fn = [im_out_path filesep 'slice_order.csv'];
    if exist(slice_order_fn,"file")
        slice_order = readtable(slice_order_fn);
    else
        disp('Downsample images first!')
        return
    end

    n_im = size(slice_order,1);
    h = waitbar(0,'Loading images...');

    im_fn = cellfun(@(path,fn) [path,filesep, fn], ...
            slice_order.im_path(:),slice_order.ori_filename(:),'uni',false);
    out_fn = cellfun(@(fn) [im_out_path,filesep, fn], ...
            slice_order.out_fn(:),'uni',false);
    resize_factor = slice_order.resize_factor;
    im_rgb = cell(n_im,1);
    prefix = regexp(slice_order.out_fn{1},'(.*)_s[0-9]{2,3}.jpg$','tokens');
    prefix = prefix{1}{1};
    if(ismember('flipHori',slice_order.Properties.VariableNames))
        flipHori = slice_order.flipHori;
    else
        flipHori = zeros(n_im,1);
    end
    if(ismember('rotate90CW',slice_order.Properties.VariableNames))
        rotate90CW = slice_order.rotate90CW;
    else
        rotate90CW = zeros(n_im,1);
    end
    for curr_im = 1:n_im
        im_rgb{curr_im} = imread(out_fn{curr_im});
        waitbar(curr_im/n_im,h,['Loading images (' num2str(curr_im) '/' num2str(n_im) ')...']);
    end
    close(h);

    nrows = floor(sqrt(n_im));
    ncols = ceil( n_im / nrows );

    h_fig = figure;
    curr_montage = montage(im_rgb,'Size',[nrows,Inf]);
    set(curr_montage,'ButtonDownFcn',@slice_click);
%     h_fig = gcf; 
    set(h_fig,'KeyPressFcn',@keypress)

    C = curr_montage.CData;
    width = size(C,2);
    height = size(C,1);

    montage_data = struct;
    montage_data.h_fig = h_fig;
    montage_data.curr_montage = curr_montage;
    montage_data.n_slices = n_im;
    montage_data.im_fn = im_fn;
    montage_data.im_rgb = im_rgb;
    montage_data.im_out_path = im_out_path;
    montage_data.prefix = prefix;
    montage_data.flipHori = flipHori;
    montage_data.rotate90CW = rotate90CW;
    montage_data.resize_factor = resize_factor;
    montage_data.nrows = nrows;
    montage_data.ncols = ncols;
    montage_data.width = width;
    montage_data.height = height;
    montage_data.panelWidth = width / ncols;
    montage_data.panelHeight = height / nrows;
    montage_data.CData_ori = C;
    montage_data.currSlice = 0;
    guidata(curr_montage, montage_data);
    updateTitle(curr_montage);
end


function slice_click(curr_montage,eventdata)
% On slice click, mark to extract

montage_data = guidata(curr_montage);


if eventdata.Button == 1 % left click
    x = eventdata.IntersectionPoint(1);
    y = eventdata.IntersectionPoint(2);
    row = ceil(y / (montage_data.height/montage_data.nrows));
    col = ceil(x / (montage_data.width/montage_data.ncols));
    slice_num = (row-1)*montage_data.ncols + col;

    montage_data.currSlice = slice_num;
    guidata(montage_data.curr_montage, montage_data);

    updateTitle(curr_montage);
end


if eventdata.Button == 3 % right click
    x = eventdata.IntersectionPoint(1);
    y = eventdata.IntersectionPoint(2);
    row = ceil(y / (montage_data.height/montage_data.nrows));
    col = ceil(x / (montage_data.width/montage_data.ncols));
    slice_num = (row-1)*montage_data.ncols + col;

    if montage_data.currSlice ~= 0
        swap_slices(curr_montage,slice_num,montage_data.currSlice);
    end
    updateTitle(curr_montage)
end

if eventdata.Button == 2 % middle click
    x = eventdata.IntersectionPoint(1);
    y = eventdata.IntersectionPoint(2);
    row = ceil(y / (montage_data.height/montage_data.nrows));
    col = ceil(x / (montage_data.width/montage_data.ncols));
    slice_num = (row-1)*montage_data.ncols + col;
    
%     rotate_slice(curr_montage,slice_num)
    flip_slice(curr_montage,slice_num)
end

end

function keypress(montage_fig,eventdata)

montage_data = guidata(montage_fig);

im_out_path = montage_data.im_out_path;
im_rgb = montage_data.im_rgb;
im_fn = montage_data.im_fn;
resize_factor = montage_data.resize_factor;
prefix = montage_data.prefix;
flipHori = montage_data.flipHori;
rotate90CW = montage_data.rotate90CW;
switch eventdata.Key
    case 'escape'
        if ~exist(im_out_path,'dir')
            mkdir(im_out_path)
        end
        
        % Write all slice images to separate files
        
        disp('Saving slice images...');
        save_slice_images(im_fn, resize_factor, im_rgb, im_out_path,prefix,rotate90CW,flipHori);
        disp('Done.');
        close(montage_fig);
    case {'rightarrow','f','F'}
        slice_num = montage_data.currSlice;
        if (slice_num > 0); flip_slice(montage_fig,slice_num); end
    case {'pagedown','r','R'}
        slice_num = montage_data.currSlice;
        if (slice_num > 0); rotate_slice(montage_fig,slice_num); end
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



function rotate_slice(curr_montage,a)
montage_data = guidata(curr_montage);
nRot = 3;

% rotate data
im_rbg_A = montage_data.im_rgb{a};
im_rbg_A = rot90(im_rbg_A,nRot);
montage_data.im_rgb{a} = im_rbg_A;

% rotate image in montage
[xRangeA,yRangeA] = img_range(curr_montage,a);
imgA = montage_data.curr_montage.CData(yRangeA,xRangeA,:);

xMin = min(xRangeA);
width = max(xRangeA) - xMin;
yMin = min(yRangeA);
height = max(yRangeA)- yMin;

minDim = min(width,height);
xRangeB = xMin:(xMin+minDim-1);
yRangeB = yMin:(yMin+minDim-1);

imgA = rot90(imgA,nRot);
montage_data.curr_montage.CData(yRangeB,xRangeB,:) = imgA(1:minDim,1:minDim,:);

% keep record of rotation (with flipping taken into account)
if (montage_data.flipHori(a))
    montage_data.rotate90CW(a) = montage_data.rotate90CW(a)-1 ;
else
    montage_data.rotate90CW(a) = montage_data.rotate90CW(a)+1 ;
end
montage_data.rotate90CW(a) = mod(montage_data.rotate90CW(a),4);

guidata(curr_montage,montage_data);

end

function flip_slice(curr_montage,a)
montage_data = guidata(curr_montage);
flipDim = 2; % 2: left-right

% flip data
im_rbg_A = montage_data.im_rgb{a};
im_rbg_A = flip(im_rbg_A,flipDim);
montage_data.im_rgb{a} = im_rbg_A;

% flip image in montage
[xRangeA,yRangeA] = img_range(curr_montage,a);
imgA = montage_data.curr_montage.CData(yRangeA,xRangeA,:);

% xMin = min(xRangeA);
% width = max(xRangeA) - xMin;
% yMin = min(yRangeA);
% height = max(yRangeA)- yMin;
% 
% minDim = min(width,height);
% xRangeB = xMin:(xMin+minDim-1);
% yRangeB = yMin:(yMin+minDim-1);

imgA = flip(imgA,flipDim);
montage_data.curr_montage.CData(yRangeA,xRangeA,:) = imgA;

% keep record of flipping (rotation already taken into account)
montage_data.flipHori(a) = 1-montage_data.flipHori(a);

guidata(curr_montage,montage_data);

end

function updateTitle(curr_montage)
montage_data = guidata(curr_montage);

titleStr = 'Left click: select slice';
if montage_data.currSlice > 0
   titleStr = [titleStr, '(',num2str(montage_data.currSlice),')']; 
end
titleStr = [titleStr,...
            '. Right click: swap with slice. ',...
            'Middle click/RightArrow: flip slice. ',...
            'Esc: Save and exit.'];

title(montage_data.curr_montage.Parent,titleStr);
end