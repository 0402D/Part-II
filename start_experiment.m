%% start_experiment_wcount
% presents a local-global paradigm in the auditory modality 
% no input, but loads saloglo_input.mat. 
% Output contains joystick position in trials. 

% saloglo_input.mat contains structs specifying blocktype, laterality & the
% existence of deviance; 

% ISI: 150 ms (50 ms stimulus on, 100 ms stimulus off) - inter-stimulus
% interval: length of a trial = 150*5-100=650ms 
% ITI: randomly one of 800:50:1000 ms - inter-trial interval 

function start_experiment()
%% SET UP EXPERIMENT
% tidy up
clear; % this frees up workspace 

global hd

dbstop if error;

% adding all folders is wrong because sometimes different functions with the same name exist in
% different folders 

projectfolder = '/Users/yijieyin/Downloads/CCC'; 
% joystickfolder = '/Users/yijieyin/Downloads/CCC/projects/Stani/sg04'; 
% joystickfolder2 = '/Users/yijieyin/Downloads/CCC/projects/Stani/joystick'; 
% addpath(genpath(joystickfolder)); 
% addpath(genpath(joystickfolder2)); 
% if the line below doesn't work, un-comment the lines above

addpath(genpath(fullfile(projectfolder,'projects','mine?')));
% this adds the functions for stimulus presentation, NetStation & joystick 
addpath(genpath(fullfile(projectfolder, 'Matlab_Packages', 'Psychtoolbox'))); 
% this adds Psychtoolbox 

% specify path for stimuli
cpath='/Users/yijieyin/Downloads/CCC/projects/saloglo - Stimulus Presentation/Stimuli/';

%% setup audioplayer

% initialise  psychtoolbox sound
if ~isfield(hd,'pahandle')
    hd.f_sample = 44100;
    fprintf('Initialising audio.\n');
    
    InitializePsychSound(1)
    
    if PsychPortAudio('GetOpenDeviceCount') == 1
        PsychPortAudio('Close',0);
    end
    
    hd.pahandle = PsychPortAudio('Open',[],[],[],hd.f_sample,2);
end

%%  Connect to net station
% specify host and port
eeghost; % loads NETSTATIONHOST and NETSTATIONPORT
NetStation('Connect', NETSTATIONHOST, NETSTATIONPORT);

% catch errors
if  exist('NETSTATIONHOST','var') && ~isempty(NETSTATIONHOST) && ...
        exist('NETSTATIONPORT','var') && NETSTATIONPORT ~= 0
    fprintf('Connecting to Net Station.\n');
    [nsstatus, nserror] = NetStation('Connect',NETSTATIONHOST,NETSTATIONPORT);
    if nsstatus ~= 0
        error('Could not connect to NetStation host %s:%d.\n%s\n', ...
            NETSTATIONHOST, NETSTATIONPORT, nserror);
    end
else error('Error occurred for connecting to NetStation');
end

% Synchronise with Netstation
disp('Connected');
NetStation('Synchronize');
disp('Start recording...');
NetStation('StartRecording');


%% load stimuli

% load stimulus input
load('saloglo_input');

% load audiofiles
%%% for stimuli
LAX1=audioread([cpath,'LAX1.wav']);
LAX2=audioread([cpath,'LAX2.wav']);
LAY2=audioread([cpath,'LAY2.wav']); % different sound, different ear; 
RAX1=audioread([cpath,'RAX1.wav']);
RAX2=audioread([cpath,'RAX2.wav']);
RAY2=audioread([cpath,'RAY2.wav']);

%% stimulus parameters

% time between consecutive stimulations
hd.stimoff = 0.100;

% stimulus duration
hd.stimon = 0.050;

% distribution for intertrial interval
ITI=800:50:1000;

%% Insert participant details

% insert participant number
part_id = input('Participant number: ', 's');
npart=length(saloglo_input(:,1));
while ~(ismember(str2double(part_id), 1:npart))
    part_id = input('Participant number: ', 's');
end

% insert participant initials
part_in = input('Participant initials: ', 's');

%% Start netstation

% NetStation: send begin marker
NetStation('Event','BGIN', GetSecs, 0.001);

%% allow to start with specified block
interrupt=input('Insert y to specify a block to start with. Otherwise insert n: ', 's');
while ~(or(interrupt=='y', interrupt=='n'))
    interrupt=input('Insert y to specify a block to start with. Otherwise insert n: ', 's');
end

if interrupt=='y'
    startblock=input(['Block 0: testblock;',...
        '\nBlock 1-4: global-local;',...
        '\nBlock 5&8: joystick training;',...
        '\nBlock 6-7 & 9-10: joystick global-local',...
        '\nBlock 11:no deviants',...
        '\nBlock 12-15:global-local',...
        '\nInsert number of startblock from 0-15: '], 's');
    while ~(ismember(str2double(startblock), 0:15))
        startblock=input('Insert number of startblock from 0-15: ', 's');
    end
    startblock=str2double(startblock)+1; % this includes the testblock; [1,16]
elseif interrupt=='n'
    startblock=1;
else
    error('No startblock input. Restart experiment');
end

%% RUN EXPERIMENT

% set up 
    posx=zeros(14,227);
    posy=zeros(14,227);
    pos=zeros(14,227);

% cycle though input matrix for each block
for blocknumber=startblock:size(saloglo_input,2) % [1,16]
    while true 
    % picks current block 
    curr_block=saloglo_input{str2double(part_id),blocknumber};
    
    % run oddball sample
    if blocknumber==1
        blktxt='TESTBLOCK';
    else
        blktxt=['Block ',num2str(blocknumber-1)];% [1,15]
    end
    
    fprintf(['The experiment will start with ',blktxt]);
    
    disp('Press any key to start:\n');
    
    % waits for button press to continue with experiment
    k=waitforbuttonpress;
    if k==1
        disp('Start...');
    end
    
    % Synchronise Netstation before each block
    NetStation('Synchronize');
    
    % cycle through trials
    for  currtrial_idx=1:length(curr_block.stim)
        % assign audiofiles to numeric input
        switch getfield(curr_block.stim, {currtrial_idx}, 'trialans')
            case 'LAX1'
                audiofile=LAX1;
            case 'LAX2'
                audiofile=LAX2;
            case 'LAY2'
                audiofile=LAY2;
            case 'RAX1'
                audiofile=RAX1;
            case 'RAX2'
                audiofile=RAX2;
            case 'RAY2'
                audiofile=RAY2;
            otherwise
                error('trialtype does not exist');
        end
        
        % load sound pattern corresponding to trial into buffer
        PsychPortAudio('FillBuffer',hd.pahandle, audiofile');
        
        % EEG event
        % keycodes:
        % BMOD: stimulation modality (either auditory or somatosensory)
        % BLAT: laterality of standard stimulus (left or right)
        % BNUM: blocknumber
        % BTYP: blocktype (global standard=local deviant, global standard=global deviant)
        % TNUM: trialnumber (one from 1-270)
        % TTYP: trialtype (local standard or local deviant)
        % SNUM: stimulusnumber, number of stimulus within a trial (i.e. one of 1-5)
        % FNUM: fingernumber (indicates which finger, one of 1-10, was
        % stimulated)

        trigger=eventnameconv(curr_block.blocktype,curr_block.laterality,...
            curr_block.deviance,getfield(curr_block.stim, {currtrial_idx}, 'trialname'));
        
        NetStation('Event',trigger,GetSecs,0.001,'BLAT',curr_block.laterality,'BNUM',blocknumber,'BTYP',...
            curr_block.blocktype,'TNUM', currtrial_idx, 'TTYP', getfield(curr_block.stim, {currtrial_idx}, 'trialname'));
        
        % decrease volume
        PsychPortAudio('Volume', hd.pahandle, 0.5);

        % play sound corresponding to trial
        PsychPortAudio('Start',hd.pahandle,1,0,1);
        
        %% joystick acquisition 
        % this only happens at the end of the 4th sound of each trial 
        % 150ms*4=600ms
        % waits until after the 100ms after the 4th sound: 
        WaitSecs(0.6);

        if ismember(blocknumber,6:12)
            h=joystick;
            posx(blocknumber,currtrial_idx)=h(1); % do I want posx and posy to be cells? 
            posy(blocknumber,currtrial_idx)=h(2);
            % below should have the value between 0 and root 2
            pos(blocknumber,currtrial_idx)=((posx(blocknumber,currtrial_idx)).^2+(posy(blocknumber,currtrial_idx)).^2).^0.5;
            disp(h);
        end

        % wait until the stimulus is played 
        WaitSecs(0.050); 
        
        % print number of current block and trial to catch errors
        if isequal(blocknumber, 1)
            fprintf('Testblock 1, trialnumber: %d \n', currtrial_idx);
        else 
            fprintf('Blocknumber: %d, trialnumber: %d \n', ...
                    blocknumber-1, currtrial_idx);
        end
        
        % add stops at the training blocks (number 6&9; input number: 5&8)
        if blocknumber==6 || blocknumber==9
            if ismember(currtrial_idx,20:7:90) % 10 training opportunities 
                ctn=input('Continue training (c) or move on (m)?');
                while ~(or(ctn=='c',ctn=='m'))
                    ctn=input('Continue training (c) or move on (m)?');
                end
                if ctn=='m'
                    break
                end
            end
        end
        
        % wait for intertrial interval
        WaitSecs(ITI(randi(length(ITI)))/1000);
    end

save([part_in 'joypos.mat'],'pos');

% Wrap up 
    rrunblk=input('Insert r to re-run this block, otherwise insert n: ','s');
    while ~(or(rrunblk=='r',rrunblk=='n'))
        rrunblk=input('Insert r to re-run this block, otherwise insert n: ','s');
    end
    if rrunblk=='n'
        break 
    end
    
    % prompt experimenter to continue with next block
    if blocknumber<length(saloglo_input)
        % prompt experimenter to press any key to continue
        fprintf('Pause and press any key to continue: \n');
        k=waitforbuttonpress;
        if k==1
            disp('continue...');
        end
    else
        disp('END OF EXPERIMENT');
    end
    end
    
end

% Shut down Netstation
NetStation('Disconnect');
NetStation('StopRecording');

end

