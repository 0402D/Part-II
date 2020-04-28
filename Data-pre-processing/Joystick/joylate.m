% this scritp: 
%   normalises the joystick numbers within trials 
%   reverse the joystick numbers in the 3-4 joystick blocks 
%   concatenate all blocks together 
%   allow plotting and saving of individual and multiple participants 
%   uses log2 to transform all joystick data 

% I gave participant 13's stimuli to participant 14
% I also gave participant 1's stimuli to participant 20 

% the paths of where the joystick data, latenesses and scripts are 
addpath('/Users/yijieyin/Downloads/CCC/projects/mine?/Data_Analysis/preprocessing'); 
addpath('/Users/yijieyin/Downloads/CCC/projects/mine?/Data/raw_Data/joystick');

% specify participant number 
partnum=input('Please insert the number of participant(s): ');
if ~ismember(partnum,1:21)
    partnum=input('Please insert the number of participant(s): ');
end

% collectivity 
clctv=input('Would you like to run collectively or individually, or both?\n (c/i/b): ','s');
while ~ismember(clctv,['c' 'i' 'b'])
    clctv=input('Would you like to run collectively or individually, or both?\n (c/i/b): ','s');
end

% specify plotting 
plotch=input('Would you like to see plots? (please insert y/n): ','s');
while ~ismember(plotch,['y' 'n'])
    plotch=input('Would you like to see plots? (please insert y/n): ','s');
end

% load all trials 
load('saloglo_input.mat');

% do I have to cd? 
% take all file names
cd '/Users/yijieyin/Downloads/CCC/projects/mine?/Data/raw_Data/joystick'
allfiles=dir('**/*.mat');
allfilenames={allfiles.name};

allpart=[];
logallpart=[];
allpart_sep=[];

% if the input contains many participants, allow processing at once 
% putting partnum before allfilenames reduces the biggest loop 
for j=1:length(partnum)
    % add latenesses to the trials 
    if partnum(j)==14
        lateness=trialcode_addition(saloglo_input,partnum(j)-1,[7 8 10 11]);
    elseif partnum(j)==21
        lateness=trialcode_addition(saloglo_input,1,[7 8 10 11]);
    else
        lateness=trialcode_addition(saloglo_input,partnum(j),[7 8 10 11]);
    end
    
    % loop through the files in joystick folder 
    for i=1:length(allfilenames)
        % compare between partnum and allfilenames; load the correct one 
        if partnum(j)==str2double(allfilenames{i}(3:4))
            load(allfilenames{i});
            % all variables have the same name, so need to load one at a
            % time
            
            % 228 (the max n of trials in a block)*4=912
            latejoy(j).joy=double.empty;
            latejoy(j).late=double.empty;
%             fiout=[];
            for blkn=[7:8,10:11]
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
                
                % put into field joy 
                % all blocks are concatenated 
                latejoy(j).joy=[latejoy(j).joy stdjoy];
                
                % put in latenesses 
                % all trialcodes in cells 
                if partnum(j)==14
                    latecell={lateness{13,blkn}.stim.trialcode};
                elseif partnum(j)==21
                    latecell={lateness{1,blkn}.stim.trialcode};
                else
                    latecell={lateness{partnum(j),blkn}.stim.trialcode};
                end
                
                lateinblock=double.empty;
                for k=1:length(latecell)
                    % take the third digit of every cell 
                    lateinblock(k)=str2double(latecell{k}(3));
                end
                latejoy(j).late=[latejoy(j).late lateinblock];
%                 fiou=[];
%                 fiou=[stdjoy;lateinblock];
%                 fiou=[blkn*ones(1,size(fiou,2));fiou];
%                 fiout=[fiout fiou];
            end

            finaljoy=[];
            % only take the standards 
            % column 1 is all the lateness numbers >0;
            % column 2 is all the joystick numbers with precision of 0.001
            for n=1:length(latejoy(j).late)
                if ~latejoy(j).late(n)==0
                    finaljoy=[finaljoy;latejoy(j).late(n) round(latejoy(j).joy(n),3)];
                end
            end

            single=[];
            single_sep=[];
            logsingle=[];
            % reduce the number of data points for earlier latenesses -
            % take numbers out randomly 
            late4row=find(finaljoy(:,1)==4);
            late4both=finaljoy(late4row,:);
            for ltns=1:3
                row=find(finaljoy(:,1)==ltns);
                row=row(randperm(length(row),length(late4row)));
                both=finaljoy(row,:);
                single=[single;both];
                single_sep=[single_sep,finaljoy(row,2)];
            end
            % latenesses & joypos for the single participant 
            single=[single;late4both];
            single_sep=[single_sep,finaljoy(late4row,2)];
            % log the second column after adding 1 so that my data's range
            % is [1,2], not [0,1](difficult to log) 
            % the end result would still range [0,1]! 
            logsingle=[single(:,1),round(log2(single(:,2)+1),3)];
            if ~(ismember('i',clctv))
                allpart=[allpart;single];
                logallpart=[logallpart;logsingle];
                allpart_sep=[allpart_sep;single_sep];
            end
            
            % convert to table so variables can have names 
            finaljoytable=array2table(single,'VariableNames',{'Lateness','JoystickPosition'});
            logjoytable=array2table(logsingle,'VariableNames',{'Lateness','LogJoystickPosition'});
            joytable_sep=array2table(single_sep,'VariableNames',{'Lateness1','Lateness2','Lateness3','Lateness4'});
            % save as csv file 
            if ismember('i',clctv)||ismember('b',clctv)
                writetable(finaljoytable,[['finaljoy' num2str(partnum(j))] '.csv'],'WriteRowNames',true);
                writetable(logjoytable,[['logjoy' num2str(partnum(j))] '.csv'],'WriteRowNames',true);
                writetable(joytable_sep,[['finaljoy_sep' num2str(partnum(j))] '.csv'],'WriteRowNames',true);
            end
            
            % plotting for the participant 
            % this should come after reducing data points 
            if plotch=='y'&&(ismember('i',clctv)||ismember('b',clctv))
                figure
                scatter(single(:,1),single(:,2));
                hold on;
                title(['Participant ' num2str(partnum(j))])
                xlabel('Latenesses')
                ylabel('Predictions')
                hold off;
            end
            
        end
    end
end

if length(partnum)==21
    alljoytable=array2table(allpart,'VariableNames',{'Lateness','JoystickPosition'});
    writetable(alljoytable,'finaljoyall.csv');
    logalljoytable=array2table(logallpart,'VariableNames',{'Lateness','LogJoystickPosition'});
    writetable(logalljoytable,'logjoyall.csv');
    alljoytable_sep=array2table(allpart_sep,'VariableNames',{'Lateness1','Lateness2','Lateness3','Lateness4'});
    writetable(alljoytable_sep,'joyall_sep.csv');
end

%% all participants data (as requested by the user) are plotted on the same graph 
if plotch=='y'
    
    if ~(ismember('i',clctv))
        % plot figure 
        figure
        scatter(allpart(:,1),allpart(:,2));
        hold on;
        title('All participants requested')
        xlabel('Latenesses')
        ylabel('Predictions')
        hold off;
    end
end


