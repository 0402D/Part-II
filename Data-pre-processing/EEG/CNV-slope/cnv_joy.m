% this script attempts to: 
% for joystick: 
%   normalise the data; 
% for cnv: 
%   get slope for each trial;
% then get the same trials from the same blocks for both joystick and cnv,
% together with latenesses; 
% then reduce the number of trials of smaller latenesses 

% list of variables: 
% joy_normed=zeros(21,16,228); - normalised joystick value for all
% participants, 16 blocks and 228 trials; 
% cnvs=zeros(21,91,16,228);
% lateness=zeros(21,16,228); - all participants, all blocks and all trials;
% equalnlate=zeros(21,4,16,17); - trial indices for 21 participants, 4
% latenesses, 16 blocks and 17 trials (max) per block; 
% cnv3D: like cnv, but without the electrodes 
% electrodes: 21*3 - 3 electrodes per participant 

% I gave participant 13's stimuli to participant 14
% I also gave participant 1's stimuli to participant 20 

clear all

% load paths for Yijie 
addpath(genpath('/Users/yijieyin/Downloads/CCC/projects/mine?/Data_Analysis/scripts'));
allproj_dir;
addpath(genpath(fullfile(cdir.saloglo_crps,'Data_Analysis','misc')));
saloglo_crps_loadpaths;
addpath(fullfile(cdir.packages, 'eeglab2019_0'));

subjectlist = dir(fullfile(projectinfo.EEGprepdata, '*.set')); subjectlist = {subjectlist.name};

% specify participant number 
partnum=input('Please insert the number of participant(s): ');
if ~ismember(partnum,1:21)
    partnum=input('Please insert the number of participant(s): ');
end

% do I have to cd? 
% take all file names
cd '/Users/yijieyin/Downloads/CCC/projects/mine?/Data/raw_Data/joystick'
allfiles=dir('**/*.mat');
allfilenames={allfiles.name};

% NOTICE THAT THERE ARE 0s AT THE END NOT FILLED BY DATA
% cnvs=zeros(max participant,electrodes,n of blocks,n of trials)
cnvs=zeros(21,91,16,228);
lateness=zeros(21,16,228);
joy_normed=zeros(21,16,228);

for j=partnum
    
    %% joystick: 
    % loop through the files in joystick folder 
    for i=1:length(allfilenames)
        % compare between partnum and allfilenames; load the correct one 
        if j==str2double(allfilenames{i}(3:4))
            load(allfilenames{i});
            % all variables have the same name, so need to load one at a
            % time 
            for blkn=[7:8,10:12]
                % getting rid of the 0 values at the end of pos
                anum=max(find(pos(blkn,221:end)));
                pos_new=pos(blkn,1:220);
                for l=1:anum
                    pos_new=[pos_new pos(blkn,220+l)];
                end
                                
                % standardise joystick numbers 
                blkmin=min(pos_new);
                blkmax=max(pos_new);
                
                stdjoy=(pos_new-blkmin)./(blkmax-blkmin);

                % reverse joystick numbers for block 10&11
                if ismember(blkn,[10 11])
                    stdjoy=1-stdjoy;
                end
                joy_normed(j,blkn,1:length(stdjoy))=stdjoy;
            end
        end
    end
    %% for CNV: 
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    
    EEG = pop_loadset('filename', subjectlist{j}, 'filepath', projectinfo.EEGprepdata);
    
    % sort channels, baseline correct and reference to the average
    EEG = eegprep(EEG);
    
    % THIS ASSUMES THAT ALL DATASETS HAVE SAME NUMBER OF ELECTRODES
    chanlocs = EEG.chanlocs;
    
    % select only the first 600 ms in the data set (i.e., the trial duration)
    EEG=pop_select(EEG, 'time', [0 0.6]);
    
    % get CNV slope values per channel per trial per block per subject 
    % for each channel 
    % get lateness values per trial per block per participant 
    disp('Gettng CNV slopes and latenesses...');
    for chan=1:size(EEG.data,1)
        % for each trial 
        for epoch=1:size(EEG.data,3)
            % trialnum, blocknum, cnvs and lateness all correspond; 
            trialnum=str2double(EEG.event(epoch).mffkey_TNUM);
            blocknum=str2double(EEG.event(epoch).mffkey_BNUM);
            suminfo=polyfit(EEG.times,EEG.data(chan,:,epoch),1);
            % as 
            cnvs(j,chan,blocknum,trialnum)=suminfo(1);
            lateness(j,blocknum,trialnum)=str2double(EEG.event(epoch).trialcodes(3));
        end
    end
end

% makes the folder and save the normalised joystick for the
% participant 
if ~isfolder('rawData')
    mkdir('rawData');
end
cd '/Users/yijieyin/Downloads/CCC/projects/mine?/Data/raw_Data/joystick/rawData'
save('joy_normed', 'joy_normed');
save('cnvs','cnvs');
save('lateness','lateness');

%% extract the same number of standards across blocks, latenesses and participants 
% NOTICE THAT THERE ARE 0s AT THE END NOT FILLED BY DATA
disp("Extracting trials from multiple latenesses...");
equalnlate=zeros(21,4,16,17);

for parti=partnum
    for bloc=1:size(lateness,2)
        late4=find(lateness(parti,bloc,:)==4);
        late3=find(lateness(parti,bloc,:)==3);
        late2=find(lateness(parti,bloc,:)==2);
        late1=find(lateness(parti,bloc,:)==1);
        % equate the number of data points 
        % these are indices of trials 
        late3_red=late3(randperm(length(late3),length(late4)));
        late2_red=late2(randperm(length(late2),length(late4)));
        late1_red=late1(randperm(length(late1),length(late4)));
        for latei=1:4
            if latei==1
                equalnlate(parti,1,bloc,1:length(late4))=late1_red;
            elseif latei==2
                equalnlate(parti,2,bloc,1:length(late4))=late2_red;
            elseif latei==3
                equalnlate(parti,3,bloc,1:length(late4))=late3_red;
            elseif latei==4
                equalnlate(parti,4,bloc,1:length(late4))=late4;
            end
            
        end
    end
end

save('equalnlate','equalnlate');

%% decide which electrodes to keep (3) 
% electrodes that show the most variance among different lateness
% conditions 
% extract specific electrodes for each participant 
snr=[];
disp("Deciding which electrodes to keep...");
for parti=partnum
    for electrode=1:size(cnvs,2)
        noise=[];
        signal=[];
        average=[];
        for late=1:4
            cnvdata=[];
            % only use blocks with data 
            [row,col]=find(squeeze(cnvs(parti,electrode,:,:)));
            blocktosearch=unique(row)';
            for blockn=blocktosearch
                % get rid of the 0s at the end 
                trialn=squeeze(equalnlate(parti,late,blockn,:))';
                trialn=trialn(find(trialn));
                % get the trials of cnv data from the current block 
                newcnvdata=squeeze(cnvs(parti,electrode,blockn,trialn));
                newcnvdata=newcnvdata';
                % concatenate between blocks 
                cnvdata=[cnvdata,newcnvdata];
            end
            % calculate the mean and variance of cnv data for this lateness
            average(late)=mean(cnvdata);
            noise(electrode,late)=var(cnvdata);
        end
        % takes the max variance across latenesses 
        noise1(electrode)=max(noise(electrode,:));
        signal(electrode)=var(average);
        snr(parti,electrode)=signal(electrode)./noise1(electrode);
    end
    sorted=sort(snr,2,'descend');
    % find the 3 electrodes with the biggest SNR 
    elec1=find(snr(parti,:)==sorted(parti,1));
    elec2=find(snr(parti,:)==sorted(parti,2));
    elec3=find(snr(parti,:)==sorted(parti,3));
    electrodes(parti,:)=[elec1 elec2 elec3];
    % get cnv data of only the electrodes selected 
    cnv3D(parti,:,:,:)=cnvs(parti,electrodes(parti,:),:,:);
end
cnv3D=mean(cnv3D,2);
% get rid of the electrode dimension, so that the new dimension is:
% part*block*trial
% THIS ONLY WORKS WHEN MULTIPLE PARTICIPANTS ARE THE INPUT 
cnv3D=squeeze(cnv3D);

save('cnv3D','cnv3D');
save('electrodes','electrodes');

%% putting it all together 
% list of variables: 
% joy_normed=zeros(21,16,228); - normalised joystick value for all
% participants, 16 blocks and 228 trials; 
% cnvs=zeros(21,91,16,228);
% lateness=zeros(21,16,228); - all participants, all blocks and all trials;
% equalnlate=zeros(21,4,16,17); - trial indices for 21 participants, 4
% latenesses, 16 blocks and 17 trials (max) per block; 
% cnv3D: like cnv, but without the electrodes 
% electrodes: 21*3 - 3 electrodes per participant 

% 3 columns: lateness, joystick, cnv 
% for every participant, and for all 

allinallc1=[];
allinallc2=[];
allinallj=[];
for partic=partnum
    partinallc1=[];
    partinallc2=[];
    partinallj=[];
%     fiou=[];
    for latei=1:size(equalnlate,2)
        [roww,colu]=find(squeeze(equalnlate(partic,latei,:,:)));
        partinalc1=[];
        partinalc2=[];
        partinalj=[];
        % this excludes the training and testing blocks 
        for blocknu=unique(roww)'
            % get rid of the 0s at the end 
            index=squeeze(equalnlate(partic,latei,blocknu,:))';
            index=index(find(index));
            % this excludes the motor block 12, but the motor block data
            % are still in the previous variables 
            if blocknu<6||blocknu>12
                partina=[];
                partina(2,:)=squeeze(cnv3D(partic,blocknu,index))';
                partina(1,:)=ones(1,size(partina,2))*latei;
                if blocknu<6
                    partinalc1=[partinalc1,partina];
                else 
                    partinalc2=[partinalc2,partina];
                end
            elseif blocknu>6 && blocknu<12
                partina=[];
%                 fio=[];
                partina(2,:)=squeeze(joy_normed(partic,blocknu,index))';
%                 fio=[blocknu*ones(1,length(partina(2,:)));index;...
%                     squeeze(joy_normed(partic,blocknu,index))';...
%                     ones(1,size(partina,2))*latei];
%                 fiou=[fiou fio];
                partina(3,:)=squeeze(cnv3D(partic,blocknu,index))';
                partina(1,:)=ones(1,size(partina,2))*latei;
                partinalj=[partinalj,partina];
            end
        end
        partinallc1=[partinallc1,partinalc1];
        partinallc2=[partinallc2,partinalc2];
        partinallj=[partinallj,partinalj];
    end
    % concatenate for all participants 
    allinallc1=[allinallc1,partinallc1];
    allinallc2=[allinallc2,partinallc2];
    allinallj=[allinallj,partinallj];
    
    % turn partinalls into tables 
    partinallc1=array2table(partinallc1','VariableNames',{'Lateness','CNVSlope'});
    partinallc2=array2table(partinallc2','VariableNames',{'Lateness','CNVSlope'});
    partinallj=array2table(partinallj','VariableNames',{'Lateness','Joystick','CNVSlope'});
    
    save(strjoin({'partinallc1',num2str(partic)},'_'),'partinallc1');
    save(strjoin({'partinallc2',num2str(partic)},'_'),'partinallc2');
    save(strjoin({'partinallj',num2str(partic)},'_'),'partinallj');
    
    writetable(partinallc1,[['partinallc1' num2str(partic)] '.csv'],'WriteRowNames',true);
    writetable(partinallc2,[['partinallc2' num2str(partic)] '.csv'],'WriteRowNames',true);
    writetable(partinallj,[['partinallj' num2str(partic)] '.csv'],'WriteRowNames',true);
end

% put all lateness & cnv together without joystick
late_cnv=[allinallc1,allinallj([1 3],:),allinallc2];

allinallc1=array2table(allinallc1','VariableNames',{'Lateness','CNVSlope'});
allinallc2=array2table(allinallc2','VariableNames',{'Lateness','CNVSlope'});
allinallj=array2table(allinallj','VariableNames',{'Lateness','Joystick','CNVSlope'});
late_cnv=array2table(late_cnv','VariableNames',{'Lateness','CNVSlope'});

save('allinallc1','allinallc1');
save('allinallc2','allinallc2');
save('allinallj','allinallj');
save('late_cnv','late_cnv');

writetable(allinallc1,'allinallc1.csv','WriteRowNames',true);
writetable(allinallc2,'allinallc2.csv','WriteRowNames',true);
writetable(allinallj,'allinallj.csv','WriteRowNames',true);
writetable(late_cnv,'late_cnv.csv','WriteRowNames',true);


%% eegprep
% sorts channels, references EEG data to the average, and performs a
% baseline correction with respect to a timewindow of 200ms before the
% onset of the first stimulus

%%% input
% EEG ~ struct: contains input EEG data

%%% output
% OUTEEG ~ struct: contains output EEG data which is baselined,
% rereferenced and sorted

function OUTEEG = eegprep(EEG)

% sort channels
EEG = sortchan(EEG);

% rereference and remove reference electrode
disp('Rereference to average...');
EEG = rereference(EEG,1); %rereferenced to average
EEG.icachansind = 1:EEG.nbchan;
EEG = pop_select(EEG, 'nochannel', {'Cz'});

% baseline correction
disp('Baseline-correction to 200ms before onset of first stimulus');
bcwin = [-200 0];
OUTEEG = pop_rmbase(EEG,bcwin);

end



