%% pp_runICA
% runs Independent Component Analysis (ICA) on EEG data

%%% input
% prepdata ~ struct: preprocessing parameters
% filename ~ char: participant name
% icatype ~ char: indicates which ICA algorithm to run
% pcacheck ~ boolean: checks whether a principal component analysis

%%% output
% EEG ~ struct: EEG data with independent components

function EEG = pp_runICA(prepdata, filename,icatype,pcacheck)

% check for ICA type
if ~exist('icatype','var') || isempty(icatype)
    icatype = 'runica';
end

% is PCA needed?
if (strcmp(icatype,'runica') || strcmp(icatype,'binica') || strcmp(icatype,'mybinica')) && ...
        (~exist('pcacheck','var') || isempty(pcacheck))
    pcacheck = true;
end

% load EEG data
allfilepath = fullfile(prepdata.groupdir, '4 - Bad channels detected');
filenames = dir(fullfile(allfilepath, [filename, '*.set']));
filenames = {filenames.name};

% decide whether to start from a specific block 
selectblock = input('Select block? (y/n) ', 's');
while ~(or(strcmp(selectblock, 'y'), strcmp(selectblock, 'n')))
    selectblock = input('Select block? (y/n) ', 's');
end

% select blocks from participant list
if strcmp(selectblock, 'y')
    insertblock = input('Insert blocknumber from 1:16 (e.g., [1, 3, 5:7]: ');
    while ~isempty(find(~ismember(insertblock, 1:16), 1))
        insertblock = input('Insert blocknumber from 1:16: ');
    end
    findblocksinpartlist = arrayfun(@(x)['_', num2str(x),'.'], insertblock, 'UniformOutput', 0);
    indices = arrayfun(@(x)contains(filenames{x}, findblocksinpartlist), 1:length(filenames), 'UniformOutput', 0);
    indices = logical(cell2mat(indices)); 
    filenames = filenames(indices);
end

for filename = filenames
    
    EEG.filename = char(filename);
    EEG = pop_loadset('filename', EEG.filename, 'filepath', allfilepath);
    evts = EEG.event; 
    
    % determine whether to run ICA or first PCA
    if strcmp(icatype,'runica') || strcmp(icatype,'binica') || strcmp(icatype,'mybinica')
        if pcacheck
            kfactor = 60;
            pcadim = round(sqrt(EEG.pnts*EEG.trials/kfactor));
            if EEG.nbchan > pcadim
                fprintf('Too many channels for stable ICA. Data will be reduced to %d dimensions using PCA.\n',pcadim);
                icaopts = {'extended' 1 'pca' pcadim};
            else
                icaopts = {'extended' 1};
            end
        else
            icaopts = {'extended' 1};
        end
    else
        icaopts = {};
    end
    
    % run 'runica' algorithm except if binica is chosen
    if strcmp(icatype,'mybinica')
        EEG = mybinica(EEG);
    else
        EEG = pop_runica(EEG, 'icatype',icatype,'dataset',1,'chanind',1:EEG.nbchan,'options',icaopts);
    end
    
    % Save data
    EEG.event = evts; 
    saveset(EEG, prepdata, 'ICA', filename, '5 - ICA'); 

end

end
