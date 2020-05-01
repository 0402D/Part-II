%% saveset
% saves EEG datasets

%%% input
% EEG ~ struct: dataset to save 
% abbrev ~ char: particle for preprocessing step (e.g., 'Epoched')
% filename ~ char: name of participant 
% folder ~ char: name of subfolder to store stuff in ('3 - Epoched')s

% saveset(EEG, 'Epoched', 'saloglo_crps_controls_part05', '3 - Epoched')

function OUTEEG = saveset(EEG, prepdata, abbrev, filename, folder)

if contains(filename, '.')
    filename = strtok(filename, '.'); 
end 

if ~ischar(filename)
    filename = char(filename); 
end 

EEG.filename = strjoin({filename, abbrev}, '.');
EEG.setname = [EEG.filename, '.set']; 
EEG.filepath = fullfile(prepdata.groupdir, folder);

fprintf('Saving %s%s.\n', EEG.filepath, EEG.filename);

if ~isfolder(EEG.filepath)
    mkdir(EEG.filepath);
end

pop_saveset(EEG, 'filename', EEG.setname, 'filepath', EEG.filepath);

OUTEEG = EEG; 
end 


