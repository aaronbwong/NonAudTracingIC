function h_scatter = AW_add_celldistribution_volume(gui_fig,cell_csv,Color)
% AW_add_celldistribution_volume(axes_atlas,cell_csv,Color)
%
% Plot histology warped onto CCF volume
%
% cell_csv: path to CSV file containing CCF coordinates of cells
%  should store as columns ccf_ap, ccf_dv, ccf_ml

if nargin < 3; Color = 'r'; end

% get gui_data
gui_data = guidata(gui_fig);

cells = readtable(cell_csv,'FileType','delimitedtext');

% Number of existing points
nScatters = length(gui_data.cells);

% Draw all datapoints
MrkrSz = 10;

hold on;
idx = nScatters + 1;
h_scatter = scatter3(gui_data.axes_atlas,...
                    cells.ccf_ap,... % AP
                    cells.ccf_ml,... % ML
                    cells.ccf_dv,... % DV
                    MrkrSz,Color,'filled','o');  
hold off;

% update gui_data
gui_data.cells{idx} = h_scatter;
guidata(gui_fig,gui_data);
end
