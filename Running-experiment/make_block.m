%%  make_block produces a block of oddball trials

% input: 
%%% blocktype: 0 (global standard=local standard), 1 (global standard=local
%%% deviant)
%%% deviance: 0 (no global deviance), 1 (global deviance) 
%%% laterality: 'left, 'right'
%%% deviance for global standard 

function [block]=make_block(blocktype, laterality, deviance, test)

% random number generator
rng shuffle

% trial number (without consecutive deviants) in main block
ntrials=192;

% how often 2,3 or 4 global standard precede a global deviant
nprop=ntrials/(3+4+5); 
% the latenesses have the same frequency - (1*3+1*4+...)
% nprop: how many of these cycles (3+4+5) there are in a block - the
% answer is 16

%% selecting standard and oddball sounds 
if strcmp(laterality,'left')
    locstd='LAX1'; 
    locdev='LAX2';
    devplus='LAY2';
elseif strcmp(laterality,'right')
    locstd='RAX1';
    locdev='RAX2'; 
    devplus='RAY2';
else
    print('error: no laterality')
end

%% assign blocktypes 
if blocktype==0
    % global eviant = local deviant
    glostd=struct('trialans',locstd,'trialname','glostd');
    glodev=struct('trialans',locdev,'trialname','glodev');
    glodev1=struct('trialans',devplus,'trialname','glodev'); 
    
elseif blocktype==1
    glostd=struct('trialans',locdev,'trialname','glostd');
    glodev=struct('trialans',locstd,'trialname','glodev');
    glodev1=struct('trialans',devplus,'trialname','glodev'); 
    
else 
    msg='Blocktypes must be either 0 (local standard = global deviant) or 1 (local standard = global standard)';
    error(msg); 

end
    
%% makes testblocks 

if test==1
    trials={[repmat(glostd,4,1);glodev];[repmat(glostd,4,1);glodev1]};
    trials=cell2mat(trials);
    % break in the middle to ask participant? 
elseif test==0
    %% construct chunks
        tp_base=cell(2,3);
        csc_base=cell(2,3);
        csc_base1=cell(2,3);
    if deviance==1
        for i=1:3
            tp_base(1,i)={[repmat(glostd,i+1,1);glodev]};
            tp_base(2,i)={[repmat(glostd,i+1,1);glodev1]};
            % 2 or 3 consecutive global deviants after 2/3/4 standards 
            csc_base(1,i)={[repmat(glostd,i+1,1);repmat(glodev,2,1)]};
            csc_base(2,i)={[repmat(glostd,i+1,1);repmat(glodev,3,1)]};
            % 2 or 3 consecutive global deviants after 2/3/4 standards 
            csc_base1(1,i)={[repmat(glostd,i+1,1);repmat(glodev1,2,1)]};
            csc_base1(2,i)={[repmat(glostd,i+1,1);repmat(glodev1,3,1)]};
        end
        testphase=[repmat([tp_base(1,:), tp_base(2,:)]',(nprop-2)./2,1);...
            csc_base(1,:)';csc_base(2,randi(3));... % 3 2-consecutive global deviant chunks + 1 3-consecutive global deivant chunks 
            csc_base1(1,:)';csc_base1(2,randi(3))]; % for glodev1 too 
        % 50 chunks in total: 6*(16-2)/2+4+4=50 - 50 first deviants; 
        % 60 deviants in total: 50+(3*1+1*2)*2=60 deviants; 
        % 208~212 trials in total: 2*(3+4+5)*(16-2)/2+(4+5+6)*2+(5/6/7)*2
        % without taking 3-consecutive deviants into account: 
        % in every block, 2*(16-2)/2+2=16 'consec_standards=4' trials; 
        % in 4 blocks, 16*4=64 trials in total 
    elseif deviance==0
        testphase=repmat({glostd},210,1);
    else 
        msg='Deviance should be either 0 or 1.';
        error(msg);
    end


    %% construct trials
    
    startphase=repmat(glostd,15,1);
    testphase=cell2mat(testphase(randperm(length(testphase))));
    % for deviance==0: 
    % length(testphase) = 50 
    % randperm(50) calls every one of the first colomn in a random order -
    % this suffles the lateness 
    % new testphase: ~210 trials; ~210 structs. 
    
    % jitter number of deviants in testphase 
    i=randi(3); % gives one number beween 1~3

    if i==1
        testphase=(testphase(1:length(testphase)-1));
        % 143 trials, the last deviant is subtracted 

    elseif i==2
        testphase=[glodev; testphase];

    elseif i==3
        j=randi(2);
        if j==1
            endp=testphase(length(testphase)); % get the last trial of testphase and put it as the first one - why??? 
            testphase=testphase(1:length(testphase)-1);
            testphase=[endp;testphase];
        end
    end
    
     % this way I still get the randomisation of number of trials when there
     % is no deviance 
    
    % stack trials
    trials=[startphase;testphase]; % 15+~210=223~227 trials 
end
%% make block

block=struct('blocktype',blocktype, 'laterality', laterality, 'stim', trials,'deviance',deviance);
% stim - stimulus 
end
