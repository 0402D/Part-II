%% make_blocksequence
% you are only supposed to run this function once. 
% makes block sequence for auditory local global oddball 
% input ~ int (npart number of participants) 
% output ~ matrix of cells 
% - saloglo_input is a matrix of cells in which each line represent a
% participant and it contains 1 testblocks and 16 blocks for the experiment


function [saloglo_input]=make_blocksequence(npart)

% number of blocks
nblocks=15;

% initialise matrices to collect data
saloglo_input=cell(npart, nblocks); % saloglo_input is a cell that has npart rows and nblocks columns 

% testblocks 
testblocks = repmat({make_block(0,'left',1,1)},npart,1);
% there must be a way to repeat testblocks? 

%% make chunks 
    chunkSize=4;
    % laterality * block type = 4 possibilities 
    
    blocktype=num2cell(repmat(0:1,1,chunkSize./2));
    blocklat=[repmat({'left'},1,2),repmat({'right'},1,2)]; 
    deviance=num2cell(ones(1,chunkSize));
    
    % stack block attributes 
    attrib=[blocktype;blocklat;deviance]; % attributes come in 4 columns. 
    
for partid=1:npart
    
    joyAttrib=attrib(:,randperm(length(attrib)));
    ctrlAttrib=[attrib(1:2,randi(length(attrib)));zeros(1,1)];
    
    % making 15 blocks for each participant:  
    fullattrib=[attrib(:,randperm(length(attrib))),...% 4 classic
        attrib(:,randi(length(attrib))),...% training for joystick
        joyAttrib(:,1:2),...% first 2 with joystick
        attrib(:,randi(length(attrib))),...% training for joystick
        joyAttrib(:,3:4),...% last 2 with joystick
        ctrlAttrib,...% 1 motor without deviance 
        attrib(:,randperm(length(attrib)))];% 4 classic 
    % this makes sure that there are both sides & both block types in the 4
    % chunks 
    % attrib=attrib(:,randperm(length(attrib))): randomises the sequences of 4s 
    
    % does a sequence have to start with a certain sequence? 
    
    %% make block sequence for one participant 
    
    % 15 blocks for each participant 
    p_inputdevc=cell(1,15); 
    for i=1:length(p_inputdevc)
        [curr_block]=make_block(cell2mat(fullattrib(1,i)),fullattrib(2,i),cell2mat(fullattrib(3,i)),0);
            % for block 5&8, interaction comes in from start_experiment -
            % pause it. 
        p_inputdevc(i)={curr_block};
    end
    saloglo_input(partid,:)=p_inputdevc(:);
    
end

saloglo_input=[testblocks, saloglo_input];

%% saves input to handbox in start folder
save(fullfile(cd,'saloglo_input'), 'saloglo_input');
save(fullfile(cd,'fullattrib'), 'fullattrib');

end 
