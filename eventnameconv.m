% converts block lateralities, blocktypes, deviance and trialtype
% to a 4-letter abbreviation for netstation 

function [eventn]=eventnameconv(blocktype,blocklat,deviance,ctans)
    
if(strcmp(blocklat, 'left'))
    bl='L';
elseif(strcmp(blocklat, 'right'))
    bl='R';
end

switch deviance 
    case 1
        devi='D';
    case 0
        devi='N';
end

if blocktype==0
    if strcmp(ctans,'glostd')
        blckt='01';
    elseif strcmp(ctans,'glodev')
        blckt='02';
    else 
        error('Wrong trialname.')
    end
elseif blocktype==1
    if strcmp(ctans,'glostd')
        blckt='11';
    elseif strcmp(ctans,'glodev')
        blckt='12';
    else 
        error('Wrong trialname.')
    end
else
    error('Wrong blocktype.')
end

eventn=[bl, devi, blckt];
