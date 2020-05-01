%% pp_mergefiles
% if there are multiple EEG set files for one participant, this function
% will

%%% input:
% prepdata ~ struct: with preprocessing parameters
% filename ~ char: participant name

%%% output:
% EEG ~ struct: merged EEG data

function EEG = pp_mergefiles(prepdata, filename)

% gets the separate files for a participant from a folder
currentdir = fullfile(prepdata.groupdir, ...
    '0 - Raw separated', ...
    filename);
filenames = dir(fullfile(currentdir, '*.set'));
filefolder ={filenames.folder}; % gets the folder name
filefolder = filefolder{1};
filenames = {filenames.name}; % gets the filenames
filenames = sort(filenames); % sorts the filenames according to the date they were recorded

% starts eeglab - we need an ALLEEG array
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

% puts the separate files for a participant in the ALLEEG array sorted
% chronologically and deletes redundant event markers (such as BGIN etc.)
for filename = filenames
    EEG = pop_loadset(filename, filefolder);
    
    if ~isempty(EEG)
        if ~isempty(EEG.event)
            
            % exclude EEG sets which have been put there erroneously or which
            % only contain DIN markers due to some error
            if ~isempty(find(ismember(setdiff(prepdata.events, {'DIN1'}), {EEG.event.type}), 1))
                
                % rename DIN markers to reflect the actual tactile event
                EEG = rename_dinmarkers(EEG, prepdata);
                
                % rename DIN markers outputs an empty set if the DIN markers
                % and the tactile events do not correspond because this is
                % mostly due to a technical error during recording
                if ~isempty(EEG)
                    indices = find(ismember({EEG.event.type}, prepdata.events));
                    
                    EEG = pop_selectevent(EEG, 'event', indices, 'deleteevents', 'on');
                    
                    [ALLEEG EEG CURRENTSET] = eeg_store(ALLEEG, EEG);
                end
            end
        end
    end
end


% cycles through all ALLEEG sets in pairs, deselects duplicate trials from
% the first older set, merges it with the new second set, then stores the
% merged EEG in the position of the second set

for ceeg = 1:(length(ALLEEG)-1)
    % deselect events which are not experimental events (such as begin
    % markers) or events which had to be repeated due to a technical error
    EEG = deselecttrials(ALLEEG(ceeg), ALLEEG(ceeg+1));
    [ALLEEG EEG index] = eeg_store(ALLEEG, EEG, ceeg+1);
    
end

%% delete the first half of duplicate trials in blocks that are re-run 
allcrctidx=[];
% separate the blocks and cycle through them 
for blocknumber=1:16
    % get indices for this block 
    currentblock=find(strcmp(num2str(blocknumber),{EEG.event.mffkey_BNUM}));
    numberoftrials=EEG.event(currentblock(end)).mffkey_TNUM;
    blkcrctidx=currentblock(end-str2double(numberoftrials)+1:end);
    allcrctidx=[allcrctidx blkcrctidx];
end
EEG=pop_selectevent(EEG,'event',allcrctidx,'deleteevents','on');

% save new EEG file
EEG.filepath = fullfile(prepdata.groupdir, ...
    '1 - Raw');

if ~isdir(EEG.filepath)
    mkdir(EEG.filepath)
end
fname = strsplit(char(filename), '_20');
fname = fname{1};
EEG.filename = [fname ,'.Raw'];
if ~ischar(EEG.filename)
    EEG.filename = char(EEG.filename);
end
EEG.setname = [EEG.filename, '.set'];

checktrials(EEG); 
EEG = eeg_checkset(EEG);
pop_saveset(EEG, EEG.setname, EEG.filepath);

end

%% deselecttrials
% takes two EEG sets
% deselects trials in the older EEG set (since they have been sorted before, EEG_1 is older)
% merges the two EEG sets

%%% input
% prepdata ~ struct: preprocessing parameters
% EEG_1 ~ struct: older EEG set (where any duplicates will be deselected)
% EEG_2 ~ struct: newer EEG set

%%% output:
% EEG ~ struct: EEG set which is a merger of the two input EEG sets with
% duplicate trials in EEG_1 removed

function EEG = deselecttrials(EEG_1, EEG_2)

if isempty(EEG_1.event)
    EEG = EEG_2;
elseif isempty(EEG_2.event)
    EEG = EEG_1;
else
    
    % event codes from the first EEG set (with trials to remove)
    % set1_codes = {EEG_1.event(:).mffkeys};
    set1_codes = {EEG_1.event(:).codes};
    % event codes from the second EEG set
    % set2_codes = {EEG_2.event(:).mffkeys};
    set2_codes = {EEG_2.event(:).codes};
    % initialse collecting indices highlighting duplicates in EEG set 1
    removetrials_idcs = zeros(1,length(set1_codes));
    
    % compares every event code in the old set to eventcodes in the new set. if
    % they are the same the index of the eventcode will be stored
    for oldcode=1:length(set1_codes)
        
        for newcode=1:length(set2_codes)
            
            if ~or(isempty(set1_codes{oldcode}), isempty(set2_codes{newcode}))
                codes1=set1_codes{oldcode};
                codes2=set2_codes{newcode};
                % if isequal(set1_codes{oldcode}, set2_codes{newcode})
                if isempty(find(cellfun(@isequal, codes1(1:5,:), codes2(1:5,:)) ==0, 1))
                    
                    removetrials_idcs(oldcode) = 1;
                    
                end
            end
            
        end
    end
    
    % indices of duplicate trials in EEG_1
    duplicatetrials = find(removetrials_idcs);
    
    % deselects duplicate trials in the older EEG set
    if ~isempty(duplicatetrials)
        disp(['Removing ', num2str(duplicatetrials)]);
        indices = setdiff(1:length({EEG_1.event.type}), duplicatetrials);
        EEG_1 = pop_selectevent(EEG_1, 'event', indices, 'deleteevents', 'on');
    else
        disp('No duplicates');
    end
    % merges the old and the new EEG set
    EEG = pop_mergeset(EEG_1, EEG_2);
end


end

%% rename_dinmarkers
% renames DIN1 markers to reflect that it represents the corresponding preceding somatosensory event

%%% input
% EEG ~ struct: EEG dataset
% prepdata ~ struct: preprocessing parameters

%%% output
% OUTEEG ~ struct: EEG dataset where DIN markers have the name of the
% preceding somatosensory event

function OUTEEG = rename_dinmarkers(EEG, prepdata)

% get the event indices for the DIN markers
din_indices = find(ismember({EEG.event.type}, {'DIN1'}));

if isempty(din_indices)
    OUTEEG = EEG;
else
    
    % check whether every somatosensory event in fact shows up before the DIN marker
    % if not, output an empty EEG set
    soma_idx = cell2mat(cellfun(@(x)contains(x, 'S'), prepdata.events, 'UniformOutput', 0));
    somaevt_indices = find(ismember({EEG.event.type}, prepdata.events(soma_idx)));
    shouldbe_somaevt_indices = din_indices-1;
    
    if ~isequal(somaevt_indices, shouldbe_somaevt_indices)
        EEG = [];
    end
    
    soma_eventnames = {EEG.event(somaevt_indices).type};
    
    % check whether there are more DIN markers than events or the other way
    % round
    if ~isequal(length(din_indices), length(somaevt_indices))
        error('There are unequal numbers of DIN markers and corresponding events')
    end
    
    % are all events tactile
    if find(cell2mat(cellfun(@(x)~contains(x, 'S'), soma_eventnames, 'UniformOutput', 0)))
        error('Not all events are tactile')
    end
    
    % rename DIN markers
    for ctypeidx = 1:length(din_indices)
        
        % keep begin time of din marker
        oldbegin = EEG.event(din_indices(ctypeidx)).begintime;
        % keep latency of din marker
        oldlatency = EEG.event(din_indices(ctypeidx)).latency;
        
        % the din marker receives the complete event information from the
        % corresponding somatosensory event
        EEG.event(din_indices(ctypeidx)) = EEG.event(somaevt_indices(ctypeidx));
        % the din marker keeps the old begin and latency
        EEG.event(din_indices(ctypeidx)).begintime = oldbegin;
        EEG.event(din_indices(ctypeidx)).latency = oldlatency;
        
    end
    
    % delete the inaccurate somatosensory events
    OUTEEG = pop_selectevent(EEG, 'event', setdiff(1:size(EEG.event, 2), somaevt_indices), 'deleteevents', 'on');
    
end
end


%% checktrials

% checks whether all blocks are in the EEG set file 

%%% input
% INEEG ~ struct: EEG data

%%% output
% OUTEEG ~ struct: EEG data

function checktrials(EEG)

blocknumbers = unique(cell2mat(cellfun(@(x)str2double(x), {EEG.event.mffkey_BNUM}, 'UniformOutput', 0))); 
blocknumbers = blocknumbers(~isnan(blocknumbers)); 

allblocks_idx = logical(cell2mat(arrayfun(@(x)ismember(x, blocknumbers), 2:16, 'UniformOutput', 0)));
if ~isempty(find(~allblocks_idx, 1))
    error('Some blocks are missing - check whether this is due to a recording error or bug in the code'); 
end 

end 