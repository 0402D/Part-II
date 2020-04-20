function dry_run()%% SET UP EXPERIMENT
% tidy up
clear;

global hd

dbstop if error;

% add all folders in current working directory (which is where the
% functions are)
projectfolder = '/Users/yijieyin/Downloads/CCC'; 
addpath(genpath(fullfile(projectfolder,'projects','mine?')));
addpath(genpath(fullfile(projectfolder, 'Matlab_Packages', 'Psychtoolbox'))); 

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

% distribution for inter-trial interval
ITI=800:50:1000;

%% Insert participant details

% insert participant number
part_id = input('Participant number: ', 's');
npart=length(saloglo_input(:,1));
while ~(ismember(str2double(part_id), 1:npart))
    part_id = input('Participant number: ', 's');
end

% % insert participant initials
% part_in = input('Participant initials: ', 's');

%% allow to start with specified block
interrupt=input('Insert y to specify a block to start with. Otherwise insert n: ', 's');
while ~(or(interrupt=='y', interrupt=='n'))
    interrupt=input('Insert y to specify a block to start with. Otherwise insert n: ', 's');
end

if interrupt=='y'
    startblock=input(['Block 1-4: global-local;',...
        '\nBlock 5&8: joystick training;',...
        '\nBlock 6-7 & 9-10: joystick global-local',...
        '\nBlock 11:no deviants',...
        '\nBlock 12-15:global-local',...
        '\nInsert number of startblock from 1-15: '], 's');
    while ~(ismember(str2double(startblock), 1:15))
        startblock=input('Insert number of startblock from 1-15: ', 's');
    end
    startblock=str2double(startblock)+1; 
elseif interrupt=='n'
    startblock=1;
else
    error('No startblock input. Restart experiment');
end

%% RUN EXPERIMENT
% cycle though input matrix for each block
for blocknumber=startblock:size(saloglo_input,2)
    while true 
    % picks current block
    curr_block=saloglo_input{str2double(part_id),blocknumber};
    
    % run oddball sample
    if blocknumber==1
        blktxt='TESTBLOCK';
    else
        blktxt=['block ',num2str(blocknumber-1)];
    end
    
    fprintf(['The experiment will start with ',blktxt,', \n','Press any key to start:\n']);
    
    % waits for button press to continue with experiment
    k=waitforbuttonpress;
    if k==1
        disp('Start...');
    end
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

        % decrease volume
        PsychPortAudio('Volume', hd.pahandle, 0.5);

        % play sound corresponding to trial
        PsychPortAudio('Start',hd.pahandle,1,0,1);
        % wait until the stimulus is played 
        WaitSecs(0.650); 
        % print number of current block and trial to catch errors
        if isequal(blocknumber, 1)
            fprintf('Testblock 1, trialnumber: %d \n', currtrial_idx);
        else 
            fprintf('Blocknumber: %d, trialnumber: %d \n', ...
                    blocknumber-1, currtrial_idx);
        end
        % wait for intertrial interval
        WaitSecs(ITI(randi(length(ITI)))/1000);
    end
    
    rrunblk=input('Insert r to re-run this block, otherwise insert n: ','s');
    while ~(or(rrunblk=='r',rrunblk=='n'))
        rrunblk=input('Insert r to re-run this block, otherwise insert n: ','s');
    end
    if rrunblk=='n'
        break 
    end
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
disp('end of experiment')
end

