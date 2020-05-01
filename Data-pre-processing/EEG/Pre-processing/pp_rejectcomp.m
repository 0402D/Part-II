%% pp_rejectcomps
% reject independent components with noise

%%% input
% prepdata ~ struct: preprocessing parameters
% filename ~ char: participant name
% varargin contains parameters for independent component rejection
% specified in param
function pp_rejectcomp(prepdata, filename,varargin)

% check for parameters of component rejection
param = finputcheck(varargin, { ...
    'reject' , 'string' , {'on','off'}, 'on'; ...
    'skip' , 'string' , {'on','off'}, 'off'; ...
    'sortorder', 'integer', [], []; ...
    'prompt' , 'string' , {'on','off'}, 'on'; ...
    });

% load EEG data list for blocks for selected participant 
allfilename = [filename, '*.ICA.set'];
allfilepath = fullfile(prepdata.groupdir, '5 - ICA');
filenames = dir(fullfile(allfilepath, allfilename));
filenames = {filenames.name};

% decide whether to start from a specific block 
selectblock = input('Select block? (y/n) ', 's');
while ~(or(strcmp(selectblock, 'y'), strcmp(selectblock, 'n')))
    selectblock = input('Select block? (y/n) ', 's');
end

% select blocks from participant list
if strcmp(selectblock, 'y')
    insertblock = input('Insert blocknumber from 1:16 (e.g., [1, 3, 5:7]: ');
    while ~isempty(find(~ismember(insertblock, 1:16), 1))
        insertblock = input('Insert blocknumber from 1:16: ');
    end
    findblocksinpartlist = arrayfun(@(x)['_', num2str(x),'.'], insertblock, 'UniformOutput', 0);
    indices = find(arrayfun(@(x) contains(filenames{x}, findblocksinpartlist), 1:length(filenames)));
    filenames = filenames(indices);
%     Maria's codes below 
%     indices = arrayfun(@(x) contains(filenames{x}, findblocksinpartlist), 1:length(filenames), 'UniformOutput', 0);
%     filenames = filenames(cell2mat(indices));
end

for filename = filenames
    
    % load EEG set
    EEG.setname = filename;
    EEG.filename = filename; 
    EEG = pop_loadset('filename', EEG.filename, 'filepath', allfilepath);
    evts = EEG.event; 

    
    disp(['Processing ' EEG.filename]); 
    
    if strcmp(param.skip,'off')
        if isempty(EEG.icaweights)
            EEG = computeic(EEG);
            if ~isfield(EEG.reject,'gcompreject') || isempty(EEG.reject.gcompreject)
                EEG.reject.gcompreject = zeros(1,size(EEG.icaweights,1));
            end
            EEG.saved = 'no';
            pop_saveset(EEG, 'savemode', 'resave');
        end
        
        evalin('base','eeglab');
        assignin('base','EEG',EEG);
        evalin('base','[ALLEEG EEG index] = eeg_store(ALLEEG,EEG,0);');
        
        if strcmp(param.reject,'on')
            
            if isempty(param.sortorder)
                param.sortorder = 1:size(EEG.icaweights,1);
            end
            
            EEG = VisEd(EEG,2,['[' num2str(param.sortorder) ']'],{});
            comptimefig = gcf;
            set(comptimefig,'Name',char(filename));
            g = get(comptimefig, 'UserData');
            badchan_old = cell2mat({g.eloc_file.badchan});
            
            for comp = 1:35:length(param.sortorder);
                if strcmp(param.prompt,'on')
                    choice = questdlg(sprintf('Plot component maps %d-%d?',comp,min(comp+34,length(param.sortorder))),...
                        mfilename,'Yes','No','Yes');
                    if ~strcmp(choice,'Yes')
                        break;
                    end
                elseif comp > 35
                    break;
                end
                pop_selectcomps(EEG, param.sortorder(comp:min(comp+34,length(param.sortorder))));
                uiwait;
                EEG = evalin('base','EEG');
                
                if ishandle(comptimefig)
                    g = get(comptimefig, 'UserData');
                    badchan_new = cell2mat({g.eloc_file.badchan});
                    
                    for c = 1:length(badchan_old)
                        if badchan_old(c) == 0 && (badchan_new(c) == 1 || EEG.reject.gcompreject(param.sortorder(c)) == 1)
                            g.eloc_file(c).badchan = 1;
                        elseif badchan_old(c) == 1 && (badchan_new(c) == 0 || EEG.reject.gcompreject(param.sortorder(c)) == 0)
                            g.eloc_file(c).badchan = 0;
                        end
                    end
                    set(comptimefig, 'UserData', g);
                    eegplot('drawp',0,[],comptimefig);
                end
            end
            
            if ishandle(comptimefig)
                uiwait(comptimefig);
            end
            
            EEG = evalin('base','EEG');
            
            EEG.saved = 'no';
            
            if strcmp(param.prompt,'on')
                choice = questdlg(sprintf('Overwrite %s?',EEG.filename),...
                    mfilename,'Yes','No','Yes');
                
                if ~strcmp(choice,'Yes')
                    return;
                end
            end
            
            fprintf('Resaving to %s%s.\n',EEG.filepath,EEG.filename);
            pop_saveset(EEG, 'savemode', 'resave');
        end
        
        rejectics = find(EEG.reject.gcompreject);
        fprintf('\n%d ICs marked for rejection: ', length(rejectics));
        
        fprintf('comp%d, ',rejectics(1:end));
        fprintf('\n');
        
        if strcmp(param.prompt,'on')
            choice = questdlg(sprintf('Reject marked ICs and overwrite %s?',EEG.filename),...
                mfilename,'Yes','No','Yes');
            
            if ~strcmp(choice,'Yes')
                return;
            end
        end
        
        % reject components
        if ~isempty(rejectics)
            fprintf('Rejecting marked ICs\n');
            EEG = pop_subcomp( EEG, rejectics, 0);
            EEG = eeg_checkset(EEG);
        end
    end
    
    % save new EEG set with rejected components
    % Save data
    saveset(EEG, prepdata, 'ICA.pruned', filename, '6 - ICA components removed'); 

    % save rejected independent components
    save(fullfile(EEG.filepath, [EEG.filename, '_rejectics.mat']), 'rejectics');
    
    fprintf('\n');
    
    evalin('base','eeglab');
    assignin('base','EEG',EEG);
    evalin('base','[ALLEEG EEG index] = eeg_store(ALLEEG,EEG,0);');
    evalin('base','eeglab redraw');
end
end