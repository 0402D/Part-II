
%% pp_rejectartifacts
% rejects bad trials and bad channels using a semiautomated algorithm

%%% input:
% prepdata ~ struct: preprocessing parameters
% filename ~ char: name of participant

% pbadchan ~ int: indicates what to do with the rejected channels
%%%% 1 - delete bad channels
%%%% 2 - interpolate bad channels
%%%% 3 - do nothing

% refmode ~ int: choice of reference
%%%% 1 - common average
%%%% 2 - laplacian average
%%%% 3 - linked mastoid
%%%% 4 - none

% prompt ~ boolean: indicates how to reject channels and trials
%%%% 1 - manual mode
%%%% 0 - automatic

% varsort ~ boolean:
%%%% 1 = display channel and trial variance
%%%  0 = off

% chanvarthresh ~ double: set channel variance threshold (default = 500)
% trialvarthresh ~ double: set trial variance threshold (default = 250)

function pp_rejectartifacts(prepdata, filename,pbadchan,refmode,prompt,varsort,chanvarthresh,trialvarthresh)

% define parameters 

% blocknumber 
blocknum = [2:5 7:8 10:16]; 

% set default threshold for
% channel variance
if ~exist('chanvarthresh','var') || isempty(chanvarthresh)
    chanvarthresh = 500; % usually 500 
end

% trial variance
if ~exist('trialvarthresh','var') || isempty(trialvarthresh)
    trialvarthresh = 250;
end

% determine whether a prompt is needed
if ~exist('prompt','var') || isempty(prompt)
    prompt = 1;
end

% display channel and trial variance
if ~exist('varsort','var') || isempty(varsort)
    varsort = 1;
end

% decide how to reference
if ~exist('refmode','var')
    refmode = [];
end

% load set
OUTEEG.setname = [filename, '.Epoched.set'];
OUTEEG.filename = [filename '.Epoched.set'];
OUTEEG.filepath = fullfile(prepdata.groupdir, '3 - Epoched');
OUTEEG = pop_loadset('filename', OUTEEG.filename, 'filepath', OUTEEG.filepath);

%select to start from a certain block
chooseblocks = input('Select blocks (y/n): ', 's');
while ~or(strcmp(chooseblocks, 'y'), strcmp(chooseblocks, 'n'))
    chooseblocks = input('Select blocks (y/n): ', 's');
end

% user can insert an array blocknumber from 1-16
if strcmp(chooseblocks, 'y')
    whichblocks = input('Insert blocknumbers from 1-16, e.g. [1,3:6]: ');
    while ~isempty(find(~ismember(whichblocks, blocknum), 1))
        whichblocks = input('Insert blocknumbers from 1-16, e.g. [1,3:6]: ');
    end
elseif strcmp(chooseblocks, 'n')
    whichblocks = blocknum;
end

% ARTIFACT REJECTION

for eegselect = whichblocks
    
    % loads EEG for each block
    EEG = saloglo_crps_getsets(OUTEEG, 'blocknumbers', eegselect);
       
    % semi-automatically rejects bad trial (see rejected trials:
    % find(EEG.reject.rejmanual))
    % automatically rejects bad channels
    % (these can be obtained with the command find([EEG.chanlocs.badchan])
    fprintf('\nMark bad trials manually ...\n');
    EEG = manurej(EEG, pbadchan, trialvarthresh); 
    
%     % Yijie pasted this here from below to delete the trials first before
%     % rejecting channels
%     fprintf('\nDelete previously marked trials ...\n');
%     EEG = dealwithartifacts(EEG, pbadchan, prompt);
    
    % automatically mark bad channels
    fprintf('\nAutomatic rejection ...\n');
    EEG = autorej(EEG, chanvarthresh, trialvarthresh); 
    
    % manually mark additional bad channels 
    fprintf('\nMark bad channels to delete manually...\n');
    EEG = manuallyrejectbadchannels(EEG); 
    
    % reject bad channels and delete bad trials (stored in
    % EEG.reject.rejmanual) and bad channels (stored in
    % EEG.chanlocs.badchan)
    fprintf('\nDelete previously marked channels ...\n');
    EEG = dealwithartifacts(EEG, pbadchan, prompt);
    
    % reference
    EEG = pp_rereference(EEG,refmode);
    
    
    % save EEG data
    saveset(EEG, prepdata, 'Badchannels', [filename, '_', num2str(eegselect)] , '4 - Bad channels detected'); 
    
end

end



%% autorej
% automatically rejects bad trials

%%% input
% EEG ~ struct: EEG data
% chanvarthresh ~ double: channel variance threshold
% trialvarthresh ~ double: trial variance threshold

function OUTEEG = autorej(EEG, chanvarthresh, trialvarthresh)

assignin('base','EEG',EEG);
uiwait(markartifacts(EEG,chanvarthresh,trialvarthresh));
OUTEEG = evalin('base','EEG');

end

%% manurej
% reject bad trials manually using preprocess_manageBadTrials 
% only returns trialnumbers manually marked as bad (doesn't delete anything, but deletes everything later with trials marked as bad in the combined channel and trial rejection algorithm)

%%% input
% EEG ~ struct: EEG data
% pbadchan ~ double: 1 ~ delete channels (before ICA), 2 - interpolate
% channels (after ICA)
% trialvarthresh ~ double array: cutoff for variance in trials for
% rejection

%%% output
% OUTEEG ~ struct: EEG data

function OUTEEG = manurej(EEG, pbadchan, trialvarthresh)
opts.reject = 1; opts.recon = 0;
opts.threshold = 1; opts.slope = 0;
[EEG, badtrials] = preprocess_manageBadTrials(EEG,opts, pbadchan, 'threshold', [-trialvarthresh trialvarthresh]);
EEG.reject.rejmanual(badtrials) = 1;

OUTEEG = EEG; 
end

%% manuallyrejectbadchannels
% a window showing all channels pops up and then the command window prompts
% you to insert the electrode labels (E-) of the channels to reject 

%%% input 
% EEG ~ struct: EEG data

%%% output 
% OUTEEG ~ struct: EEG data

function OUTEEG = manuallyrejectbadchannels(EEG)

% determine colour in EEG channel plot   
colors = cell(1, EEG.nbchan);
% marks interpolated channels as red
for channelidx = find([EEG.chanlocs.badchan])
    colors{channelidx} = 'r'; 
end
% leaves others blue
for channelidx = setdiff(1:EEG.nbchan, find([EEG.chanlocs.badchan]))
    colors{channelidx} = 'k'; 
end

assignin('base', 'EEG', EEG);
evalin('base','BadChanDetectionComplete=0;');

tmpcom = [ ...
    'BadChanDetectionComplete=1;' ...
    ] ;

% review channels 
eegplot(EEG.data(1:EEG.nbchan,:,:), 'srate', EEG.srate,...
    'title', 'Scroll component activities -- eegplot()', ...
    'limits', [EEG.xmin EEG.xmax]*1000, 'color', colors, ...
    'winlength', 10, ...
    'dispchans', EEG.nbchan, ...
    'eloc_file', EEG.chanlocs, 'command', tmpcom, ...
    'butlabel','Done');

%Wait until the user has finished reviewing.
reviewFinished=0;
while ~reviewFinished
    reviewFinished=evalin('base','BadChanDetectionComplete');
    %BadChannels =evalin('base','BadChannels');
    pause(0.01);
    
end

% remove dead channels %%% HASN'T BEEN DONE IN PART 1
chandata = reshape(EEG.data,EEG.nbchan,EEG.pnts*EEG.trials); %Get chan x tpts..
zerochannels = find(var(chandata,0,2) < 0.5); %Remove zero channels from spec..

if ~isempty(zerochannels)
    if ~isequal(size(zerochannels, 1), 1)
        zerochannels = zerochannels';
    end
    for bchan = zerochannels
        EEG.chanlocs(bchan).badchan = 1;
    end
end

% insert which channels are bad 
additionalbadchannels = input('Mark additional bad channels (E-)? (eg: [1, 2, 3]) ');
if ~isempty(additionalbadchannels)
    while ~isempty(find(~ismember(additionalbadchannels, 1:129),1))
        additionalbadchannels = input('Mark additional bad channels (E-)? (eg: [1, 2, 3]) ');
    end
    additionalbadchannels = arrayfun(@(x)['E', num2str(x)], additionalbadchannels, 'UniformOutput', 0);
    additionalbadchannels = find(ismember({EEG.chanlocs.labels}, additionalbadchannels));
    
    if ~isempty(additionalbadchannels)
        for badchannels = additionalbadchannels 
            EEG.chanlocs(badchannels).badchan =1;
        end
    end 
end

OUTEEG = EEG; 

end

%% dealwithartifacts
% deletes or interpolates bad channels 

%%% input
% EEG ~ struct: EEG data
% pbadchan ~ double: tells you what to do with the channels 
%%%% 1 : delete noisy channels
%%%% 2 : interpolate noisy channels
% prompt ~ boolean: indicates how to reject channels and trials

%%% output
% OUTEEG ~ struct: EEG data

function OUTEEG = dealwithartifacts(EEG, pbadchan, prompt)

% get bad channel indices
chanlocs = EEG.chanlocs;
if isfield(chanlocs, 'badchan')
    badchannels = find([chanlocs.badchan]);
else
    badchannels = [];
end

% get bad trial indices
btrials = EEG.reject.rejmanual; 
badtrials = find(btrials);

% decide whether to delete or interpolate bad channels
if prompt && (~exist('pbadchan','var') || isempty(pbadchan))
    pbadchanmodes = {'Delete','Interpolate','Do Nothing'};
    [pbadchan,ok] = listdlg('ListString',pbadchanmodes,'SelectionMode','single','Name','Bad Channels',...
        'PromptString','Process bad channels?');
    if ~ok
        return;
    end
end

% delete noisy channels
if pbadchan == 1
    
    if ~isempty(badchannels)
        % delete bad channels
        fprintf('\nDeleting bad channels previously marked ...\n');
        EEG = pop_select(EEG,'nochannel',badchannels);
    end
    
    if ~isempty(badtrials)
        % delete bad trials
        fprintf('\nDeleting bad trials previously marked...\n');
        EEG = pop_select(EEG, 'notrial', badtrials);
    end
    
    % or interpolate noisy channels
elseif pbadchan == 2
    fprintf('\nInterpolating bad channels...\n');
    EEG = eeg_interp(EEG,EEG.rejchan, 'spherical');
else
    fprintf('No channels or trials processed.\n');
end

OUTEEG = EEG;
OUTEEG.badtrials = btrials; 
OUTEEG.badchans = chanlocs; 

end