% netip='10.10.10.42'; % Net Station IP address. (NS 5!)
% NetStation('Connect', netip, 55513);

% Prompt netstation to connect to port 
eeghost; % loads NETSTATIONPORT and NETSTATIONHOST
NetStation('Connect', netip, NETSTATIONPORT);
netip=NETSTATIONHOST; % Net Station IP address. (NS 5!)

disp('Connected');

NetStation('Synchronize');

NetStation('StartRecording');

% The following events show up in the log in real time, but they get saved
% with the same time stamps, all well after the recording ends.
NetStation('EVENT','0.1S',GetSecs,0.1);
pause(1);
NetStation('EVENT','0.4S',GetSecs,0.4);
pause(5);

% Set test_simultaneous to true to debug events with the same time stamp.
test_simultaneous = false;
if (test_simultaneous)
    
    % Two events with the same time stamp:
    t=GetSecs;
    NetStation('EVENT','SIM1',t,0.1);
    NetStation('EVENT','SIM2',t,0.1);
    % Only one gets saved. (Usually the 1st one sent, but not always.)
    
    pause(5);
    
    % Two events with overlapping durations:
    t=GetSecs;
    NetStation('EVENT','OVL1',t,0.5);
    NetStation('EVENT','OVL2',t+0.2,0.5);
    % Both events get saved.
    
end

NetStation('StopRecording');
disp('Stopped');

pause(1);

NetStation('Disconnect');