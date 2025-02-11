% List of CSV file paths
csvFilePaths = {
    'V:\Data\ProcessedData\Falk\Histology\20240725-02969-22535\Tiffs 10x\CellCount_ABBAoutput\02969-22535_tdTomato_ABBAConvert.csv',...
    'V:\Data\ProcessedData\Falk\Histology\20240725-02969-22534\10x TIFF\Cellcount_ABBAoutput\02969-22534_tdTomato_ABBAConvert.csv',...
    'V:\Data\ProcessedData\Falk\Histology\20240626-02888-22007\TIFFS 10x\Cellcount_ABBAoutput\02888-22007_tdTomato_ABBAConvert.csv'
    % Add more file paths as needed
};
DisplayNameList = {'22535','22534','22007'};

% Display the cell distribution volume
gui_fig = AW_view_celldistribution_volume(csvFilePaths,DisplayNameList);
% ColorList = turbo(length(csvFilePaths));
% for iCsv = 2:length(csvFilePaths)
%     % Add cell distribution volume to the image
%     gui_fig = AW_add_celldistribution_volume(gui_fig,csvFilePaths{iCsv},ColorList(iCsv,:));
% end
