%% pp_epoching
% epochs trials
% removes baseline 200 ms before trial onset
% corrects for 20ms time difference between eventmarker and actual sound
% removes 15 standard trials as habituation phase in each block before the actual oddball
% starts

%%% input:
% prepdata ~ struct: information about preprocessing parameters
% filename ~ char: name of participant
% icamode ~ boolean: indicates whether to keep independent components if
% ICA has already been performed

%%% output:
% EEG ~ struct: the epoched EEG set

function EEG = pp_epoching(prepdata, filename,icamode)

% has ICA been performed? if yes keep independent components
if ~exist('icamode','var') || isempty(icamode)
    icamode = true;
end
keepica = true;

copyartifacts = true;

% selects the events used for epoching from the prepdata struct

% loads filtered EEG dataset
% load file
EEG = pop_loadset('filename', [filename, '.Filtered.set'], ...
    'filepath', fullfile(prepdata.groupdir, '2 - Filtered'));

% renames the events in the filtered EEG dataset if necessary to be able to
% select the first stimulus in a trial sequence

fprintf('Epoching and baselining.\n');

% select events
EEG = pop_epoch(EEG,{},[prepdata.startepoch prepdata.endepoch]);
EEG = pop_select(EEG, 'notrial', ismember({EEG.epoch.eventtype}, ...
    setdiff({EEG.epoch.eventtype}, prepdata.events)));

% baselining 200 ms before trial onset
EEG = pop_rmbase(EEG, [-200 0]);
EEG = eeg_checkset(EEG);

% if ischar(filename)
%
%     if icamode == true && keepica == true && exist([EEG.filepath EEG.filename],'file') == 2
%         oldEEG = pop_loadset('filepath',EEG.filepath,'filename',EEG.filename,'loadmode','info');
%         if isfield(oldEEG,'icaweights') && ~isempty(oldEEG.icaweights)
%             fprintf('Loading existing ICA info from %s%s.\n',EEG.filepath,EEG.filename);
%             EEG.icaact = oldEEG.icaact;
%             EEG.icawinv = oldEEG.icawinv;
%             EEG.icasphere = oldEEG.icasphere;
%             EEG.icaweights = oldEEG.icaweights;
%             EEG.icachansind = oldEEG.icachansind;
%             EEG.reject.gcompreject = oldEEG.reject.gcompreject;
%         end
%     end
%
%     if copyartifacts == true && exist([EEG.filepath EEG.filename],'file') == 2
%         oldEEG = pop_loadset('filepath',EEG.filepath,'filename',EEG.filename,'loadmode','info');
%         EEG.rejchan = oldEEG.rejchan;
%         EEG.rejepoch = oldEEG.rejepoch;
%         for c = 1:length(EEG.chanlocs)
%             EEG.chanlocs(c).badchan = 0;
%         end
%         fprintf('Found %d bad channels and %d bad trials in existing file.\n', length(EEG.rejchan), length(EEG.rejepoch));
%
%         if ~isempty(EEG.rejchan)
%             EEG = pop_select(EEG,'nochannel',{EEG.rejchan.labels});
%         end
%
%         if ~isempty(EEG.rejepoch)
%             EEG = pop_select(EEG, 'notrial', EEG.rejepoch);
%         end
% %         EEG = eeg_interp(EEG, EEG.rejchan);
% %         EEG = rereference(EEG,3);
%     end
%

% removes test trials and trials 1-15
EEG = pop_select(EEG, 'trial', find(~ismember(str2double({EEG.event.mffkey_TNUM}), 1:15)));

% remove testblocks
blocknumbers = unique(cell2mat(cellfun(@(x)str2double(x), {EEG.event.mffkey_BNUM}, 'UniformOutput', 0)));
blocknumbers = blocknumbers(~isnan(blocknumbers));
otherstuffinthere = find(~ismember(blocknumbers, 2:16), 1);
blockstoinclude = [2:5 7:8 10:16];
if ~isempty(otherstuffinthere)
    disp('Probably you did not exclude the testblocks');
end

EEG = saloglo_crps_getsets(EEG, 'blocknumbers', blockstoinclude);

%% add trialcode to the blocks included 
load('saloglo_input.mat');
% add trial codes only to participants and blocks used 
if str2double(EEG.subject(5:6))==14
    saloglo_input=trialcode_addition(saloglo_input,str2double(EEG.subject(5:6))-1,blockstoinclude);
elseif str2double(EEG.subject(5:6))==21
    saloglo_input=trialcode_addition(saloglo_input,1,blockstoinclude);
else
    saloglo_input=trialcode_addition(saloglo_input,str2double(EEG.subject(5:6)),blockstoinclude);
end

trialcodes=strings(0);
% add trial codes for every block 
for blknm=blockstoinclude
    if str2double(EEG.subject(5:6))==14
        trialcodes=[trialcodes saloglo_input{str2double(EEG.subject(5:6))-1,blknm}.stim(16:end).trialcode];
    elseif str2double(EEG.subject(5:6))==21
        trialcodes=[trialcodes saloglo_input{1,blknm}.stim(16:end).trialcode];
    else
        trialcodes=[trialcodes saloglo_input{str2double(EEG.subject(5:6)),blknm}.stim(16:end).trialcode];
    end
end
if length(trialcodes)>length(EEG.event)
    error('Too many trialcodes.')
end
trialcodes=cellstr(trialcodes);
% assign trialcodes to the field of trialcodes in EEG.event
[EEG.event.trialcodes]=trialcodes{:};

% save EEG .set in new directory
saveset(EEG, prepdata, 'Epoched', filename, '3 - Epoched');

end