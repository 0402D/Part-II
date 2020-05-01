%% pp_interpolate
% interpolate missing channels for every participant 
% merge datasets of individual blocks for every participant 
% interpolate trialwise 

%%% input 
% prepdata ~ struct: contains preprocessing parameters
% filename ~ char: participant name 

function pp_interpolate(prepdata, filename)

% get blocks for current participant 
filepath = fullfile(prepdata.groupdir, '6 - ICA components removed');
filenames = dir(fullfile(filepath, [filename, '*.ICA.pruned.set']));
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
    findblocksinpartlist = arrayfun(@(x)['_', num2str(x)], insertblock, 'UniformOutput', 0);
    indices = arrayfun(@(x)contains(filenames{x}, findblocksinpartlist), 1:length(filenames), 'UniformOutput', 0);
    filenames = filenames(cell2mat(indices));
end

% un-comment the line below if participating participant 7
% EEG_other=pop_loadset('part07.Epoched.set','/Users/yijieyin/Downloads/CCC/projects/mine?/Data/preprocessed_Data/3 - Epoched');

% interpolate missing channels for every participant 
for currentparticipant = filenames 
    
    % load current block 
    EEG = pop_loadset('filename', char(currentparticipant), 'filepath', filepath);  
    
    % interpolate missing channels using old channel data obtained from
    % original file before the ICA, except for part07
    if ismember('07',filename)
        EEG = pop_interp(EEG,EEG_other.chanlocs,'spherical');
    else
        EEG = pop_interp(EEG, EEG.badchans, 'spherical');
    end
    
    % interpolate trialwise  
    opts.reject = 0; opts.recon = 1;
    opts.threshold = 1; opts.slope = 1;
    evts = EEG.event; 
    EEG.event = []; 
    EEG = preprocess_manageBadTrials(EEG,opts, 2);
    EEG.event = evts; 
    
    % save new set 
    saveset(EEG, prepdata, 'Interpolated', currentparticipant, '7 - Interpolated');  
     
end 

end 