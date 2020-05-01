%% pp_notchfilter
% filters line noise 

%%% input 
% EEG ~ struct: EEG data 
% freq ~ double: freqency to notch filter (default is 50 Hz)

function EEG = pp_notchfilter(EEG, freq)
    if ~exist('freq','var') || isempty(freq)
        freq = 50;
    end
    
    fprintf('Notch Filtering.\n');
    EEG = pop_eegfiltnew(EEG,freq-2,freq+2,[],1);
    EEG = pop_eegfiltnew(EEG,(freq*2)-2,(freq*2)+2,[],1);
end