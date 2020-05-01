%% pp_filtering 
% filters data 

%%% input: 
% prepdata ~ struct: contains info about preprocessing parameters 
% filename ~ char: name of participant 

function pp_filtering(prepdata, filename)

% load file

EEG.filename = [filename, '.Raw.set']; 
EEG.filepath = fullfile(fullfile(prepdata.groupdir, '1 - Raw')); 
EEG = pop_loadset('filename', EEG.filename, ... 
    'filepath', EEG.filepath);


% Filters according to predefined frequency range
fprintf('Low-pass filtering below %dHz...\n', prepdata.lowpass);
EEG = pop_eegfiltnew(EEG, 0, prepdata.lowpass);
fprintf('High-pass filtering above %dHz...\n', prepdata.highpass);
EEG = pop_eegfiltnew(EEG, prepdata.highpass, 0);

% Applies notch filter to remove line noise
if strcmp(prepdata.applynotchfilter, 'yes')
    EEG = pp_notchfilter(EEG, prepdata.applynotchfilter);
end

% Saves the filtered data
saveset(EEG, prepdata, 'Filtered', filename, '2 - Filtered'); 

end