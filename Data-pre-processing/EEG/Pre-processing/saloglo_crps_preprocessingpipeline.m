%% preprocessing pipeline for auditory local-global oddball
dbstop if error;

% loads path with directories for raw data and preprocessing
addpath(genpath('/Users/yijieyin/Downloads/CCC/projects/mine?/Data_Analysis/scripts'));
allproj_dir;
addpath(genpath('/Users/yijieyin/Downloads/CCC/projects/mine?/Data_Analysis/misc'));
saloglo_crps_loadpaths;

% set working directory if necessary
if ~isequal(cd, projectinfo.eeglabprep_analysis)
    cd(projectinfo.eeglabprep_analysis);
end

% add toolboxes
addpath(fullfile(cdir.packages, 'eeglab2019_0'));

% addpath(fullfile(cdir.packages, 'eeglab14', '/plugins/MFFimport2.2/mffimport')); 
addpath(genpath(fullfile(cdir.packages, 'manage_badTrials-master')));
eeglab;

prepdata.exclpart = [];

% Set sampling frequency in Hz
prepdata.samplingfrequency = 250;

% Exclude the following channels from ALL pre-processing stages and
% analyses i.e. the 2 outer rings
prepdata.excludechannels = [1,8,14,17,21,25,32,38,43,44,48,49,56,63,64,68,69,73,74,81,82,88,89,94,95,99,107,113,114,119,120,121,125,126,127,128];

% Filter the data between following frequencies:
prepdata.highpass = 0.5;
prepdata.lowpass = 30;

% apply a notch filter (to remove 50 Hz line noise)?
prepdata.applynotchfilter = 'no'; % or 'no'
prepdata.notchfilterfreq = 50; % Hz

% baseline correction
prepdata.blcorr = [500 600]; % saloglo start of presentation of 5. stimulus at 600ms

% Set event names for epoching
% L ~ left hand stimulation
% R ~ right hand stimulation
% A ~ auditory stimulation
% S ~ somatosensory stimulation
% 0 ~ blocktype local standard = global standard, local deviant = global deviant
% 1 ~ blocktype local standard = global deviant, local deviant = global standard

prepdata.events = [
    {'LD01'     } % left, deviant, blocktype 1, global standard; 
    {'LD02'     }
    {'LD11'     } 
    {'LD12'     } 
    {'LN01'     }
    {'LN02'     }
    {'LN11'     }
    {'LN12'     }
    {'RD01'     }
    {'RD02'     }
    {'RD11'     }
    {'RD12'     }
    {'RN01'     }
    {'RN02'     }
    {'RN11'     }
    {'RN12'     }];

prepdata.startepoch = -0.2; % Start of epoch / trial in seconds. 0 means that the start of the epoch is stimulus onset
prepdata.endepoch = 1; % End of epoch in seconds

% Specify non-EEG channels (heart and such) if present
prepdata.nonEEGchannels = [];

%% iterate along all recordings and perform pre-processing steps

% generates a list of filenames for the participants or a subset thereof
everyone=input('Preprocess all participants? (y/n): ', 's');
while ~(or(strcmp(everyone, 'y'), strcmp(everyone, 'n')))
    everyone=input('Preprocess all participants? (y/n): ', 's');
end
if strcmp(everyone, 'y')
    allfiles  = saloglo_crps_generate_participantnames(projectinfo, prepdata, 0);
elseif strcmp(everyone, 'n')
    allfiles  = saloglo_crps_generate_participantnames(projectinfo, prepdata, 1);
end

% allows to start from a particular preprocessing steps, or run multiple but not all steps
step=input('Perform only selected preprocessing steps? (y/n): ', 's');
while ~(or(strcmp(step, 'y'), strcmp(step, 'n')))
    step=input('Perform only selected preprocessing steps? (y/n): ', 's');
end

if strcmp(step, 'y')
    disp('Indicate which preprocessing step to perform: ');
    disp('1 - Import');
    disp('2 - Merge');
    disp('3 - Filter');
    disp('4 - Epoch');
    disp('5 - Semi-automatically reject bad trials and channels');
    disp('6 - Run ICA');
    disp('7 - Reject bad ICA components');
    disp('8 - Interpolate deleted/bad channels');
    disp('9 - Merge blocks');
    whichstep = input('Step (e.g. [1,5]: ');
    while find(~(ismember(whichstep, 1:9)), 1)
        whichstep = input('Step: ');
    end
    
elseif strcmp(step, 'n')
    whichstep = 1:9; % run all steps
end

for fileidx = 1 : length(allfiles)
    
    % find preprocessing directory for the current participant (either
    % patient or controls)
    prepdata.groupdir = projectinfo.EEGpreprocessed;
    
    % 1. import data
    % 2. remove channels on cheek and foreheads
    if ismember(1, whichstep)
        pp_importdata(projectinfo, prepdata, char(allfiles{fileidx}));
    end
    
    % 3. merge separate files 
    if ismember(2, whichstep)
        pp_mergefiles(prepdata, char(allfiles(fileidx)))
    end
    
    % 4. Filter 
    if ismember(3, whichstep)
        pp_filtering(prepdata, char(allfiles(fileidx)));
    end
    
    % 5. Epoch data
    if ismember(4, whichstep)
        pp_epoching(prepdata, char(allfiles(fileidx)));
    end
    
    % 6. Detect bad channels
    % 7. Rereference to average
    if ismember(5, whichstep)
        pp_rejectartifacts(prepdata, char(allfiles(fileidx)),1,1, 1, 1, 650,250)
    end
    
    % 8. Run ICA
    if ismember(6, whichstep)
        pp_runICA(prepdata, char(allfiles(fileidx)));
    end
    
    % Install VisEd Plugin
    % 9. Reject components
    if ismember(7, whichstep)
        pp_rejectcomp(prepdata, char(allfiles(fileidx)));
    end
     
    % 10. Mark channels as bad and interpolate
    % 11. interpolate
    if ismember(8, whichstep)
        pp_interpolate(prepdata, char(allfiles(fileidx)))
    end
    
    % 12. Remove baseline
    % 13. reference to average    
    if ismember(9, whichstep)
        pp_mergeblocks(prepdata, char(allfiles(fileidx)))
    end
   
end


%% findgroupdir
% determines whether a datasets is from patients or controls

%%% input:
% prepdata ~ struct: specifications for preprocessing
% filename ~ char: participant ID (e.g., saloglo_crps_patient_part01)

%%% output:
% prepdatadir ~ char: preprocessing directory for either patients or
% controls

function prepdatadir = findgroupdir(prepdata, filename)
% find out whether to store the data in the patient or the controls
% directory
if contains(filename, 'patient')
    prepdatadir = prepdata.EEGpreprocessed_patients;
elseif contains(filename, 'control')
    prepdatadir = prepdata.EEGpreprocessed_controls;
end
end


%% saloglo_crps_generate_participantnames

% generates participant names of the format 'saloglo_crps_[patients or controls]_partxx' where x is the
% number of the participant

%%% input:
% projectinfo ~ struct: contains project directories
% prepdata ~ struct: contains parameters for preprocessing
% select ~ boolean: if true you can select which participants to include
% whichgroup ~ string: select whether to preprocess patients or controls

%%% output:
% partid ~ cell array: participantnames of the format
% 'saloglo_crps_partxx' where x is the participant number starting from '01'

function partid = saloglo_crps_generate_participantnames(projectinfo, prepdata, select)

% load directory which includes a struct projectinfo with the excluded participants
partnames=dir(projectinfo.rawEEGdata_storage);
partid = {partnames.name};

% list only folders which contain participant data
whichisfolder = [partnames.isdir] & ...
    cell2mat(cellfun(@(x)contains(x, 'part'), ...
    partid, 'UniformOutput', 0));
partid = partid(whichisfolder);

% exclude participants
participants = setdiff(partid, makepartname(prepdata.exclpart));

if select
    whichpart = input('Insert participant number (e.g., [1:5, 22]): ');
    while ~isa(whichpart, 'double')
        disp('Number needs to be a double');
        whichpart = input('Insert participant number (e.g., [1:5, 22]): ');
    end
    selectedparticipants = makepartname(whichpart);
    while ~ismember(selectedparticipants, ...
            participants)
        disp('Only select included datasets');
        whichpart = input('Insert participant number (e.g., [1:5, 22]): ');
        selectedparticipants = makepartname(whichpart);
    end
    participants = selectedparticipants;
end

% list only included participants
whichisfolder = cell2mat(cellfun(@(x)contains(x, participants), ...
    partid, 'UniformOutput', 0));
partid = partid(whichisfolder);

end

%% makepartname

%%% input
% numbers ~ double array: participant numbers (e.g., [1,3])

%%% output 
% participantnames ~ cell array: participant names ([{'
%   {'saloglo_crps_controls_part06'}
%     {'saloglo_crps_controls_part07'}
%     {'saloglo_crps_controls_part10'}]
    
function participantnames = makepartname(numbers)

participantnames = cellfun(@(x)['part', char(x)], ... 
    make0xnumberformat(numbers), 'UniformOutput', 0); 

end 

%% make0xnumberformat
% lets one-digit numbers start with 0

%%% input:
% numbers ~ double : double array

%%% output:
% idx ~ cell array: contains the input numbers (as cellstr) where numbers
% from 0:9 start with 0 (i.e., '00', '01', '02'...)
function idx = make0xnumberformat(numbers)

numbers = sort(numbers);
start = numbers(numbers<10);
tail = numbers(numbers>=10);
idx = cellstr([num2str(start.','0%d'); ...
    num2str(tail.', '%d')]);

end