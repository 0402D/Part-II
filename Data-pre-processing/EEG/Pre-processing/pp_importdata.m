
%% pp_importdata
% convert .mff files to .set files, resamples from 500Hz to 250Hz, and 
% removes electrodes on neck, forehead and cheeks which primarily record
% movement artifacts

%%% input: 
% projectinfo ~ struct: directories
% prepdata ~ struct: specifications for preprocessing 
% basename ~ char: participant ID (e.g., saloglo_crps_patient_part01)

function pp_importdata(projectinfo, prepdata, basename)

% get channel locations 
chanlocfile = 'GSN-HydroCel-129.sfp';

% list all mff files for current participant
mffdir=projectinfo.rawEEGdata_storage; 

filenames = dir(fullfile(mffdir, basename, [basename, '*.mff'])); 
filenames = {filenames.name};

% throw error if there are no mff files 
if isempty(filenames)
    error('No files found to import!\n');
end

% list of corrupt files 
corruptfiles = {'part07_20200205_014004.mff'}; 

% delete corrupt files 
filenames(find(ismember(filenames, corruptfiles),1)) = [];

for filename = filenames
    % convert the mff file to set file 
    disp(['Importing ', char(filename)]);
    EEG = pop_mffimport(fullfile(mffdir, basename, char(filename)), 'code');
    EEG = saloglo_crps_makecodes(EEG, prepdata); 
    EEG = eeg_checkset(EEG);
    
    % down-sample
    EEG = pop_resample(EEG, prepdata.samplingfrequency);
    
    % exclude channels on the cheeks and in the neck 
    if ~isempty(prepdata.excludechannels)
        fprintf('Removing excluded channels.\n');
        EEG = pop_select(EEG, 'nochannel', prepdata.excludechannels);
    end 
    
    % remove all pns channels except for ECG 
    pnssetwithoutECG = [{'Body.Position'}, {'Resp.Effort.Chest'}, {'Resp.Effort.Abd'}, {'EMG'}, {'Resp.Temp'}, {'Resp.Pressure'}]; 
    deselectchannels_indices = logical(cell2mat(cellfun(@(x)ismember(x, pnssetwithoutECG), {EEG.chanlocs.labels}, 'UniformOutput', 0))); 
    EEG = pop_select(EEG, 'nochannel', find(deselectchannels_indices));
    
    % make a participant name 
    participantname = strsplit(char(filename), '_20'); 
    participantname = char(participantname{1}); 
    
    % find preprocessing directory depending on whether you're    
    % save the set files for any participant in the folder for Raw files 
    EEG.subject = participantname;
    EEG.filename = strsplit(char(filename), '.'); 
    EEG.filename= char(EEG.filename{1});
    EEG.setname = [EEG.filename, '.set']; 
    
    EEG.filepath = fullfile(prepdata.groupdir, '0 - Raw separated', EEG.subject);
    if ~isfolder(EEG.filepath)
        mkdir(EEG.filepath);
    end
    
    pop_saveset(EEG, 'filename', EEG.setname, 'filepath', EEG.filepath);    
    
end