%% pp_mergeblocks
% concatenates blocks for each participant 

%%% input 
% prepdata ~ struct: preprocessing parameters
% filename ~ char: participant ID

function pp_mergeblocks(prepdata, filename)

% get filenames for each block 
filenames = dir(fullfile(prepdata.groupdir, '7 - Interpolated', [filename, '*.set']));
filefolder = {filenames.folder}; 
filefolder = filefolder{1}; 
filenames = {filenames.name}; 
filenames = natsortfiles(filenames);

% starts eeglab - we need an ALLEEG array
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

% puts the separate files for a participant in the ALLEEG array sorted
% chronologically 
for currfilename = filenames
    EEG = pop_loadset(currfilename, filefolder);
    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
end

% merges all files in ALLEEG
EEG = pop_mergeset(ALLEEG, 1:length(ALLEEG), 0); 

% remove baseline (100 ms before onset of 5th stimulus)
EEG = pop_rmbase(EEG, [500 600]);

% reference to average
EEG = pp_rereference(EEG, 1);  

% save set
saveset(EEG, prepdata, 'prep', filename, '8 - Preprocessed');  

end