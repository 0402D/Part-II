function varargout = markartifacts(varargin)
% markartifacts MATLAB code for markartifacts.fig
%      markartifacts, by itself, creates a new markartifacts or raises the existing
%      singleton*.
%
%      H = markartifacts returns the handle to a new markartifacts or the handle to
%      the existing singleton*.
%
%      markartifacts('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in markartifacts.M with the given input arguments.
%
%      markartifacts('Property','Value',...) creates a new markartifacts or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before markartifacts_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to markartifacts_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help markartifacts

% Last Modified by GUIDE v2.5 02-Feb-2012 11:23:44

if ismac || isunix
    guisuffix = '_mac';
elseif ispc
    guisuffix = '_win';
end

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       [mfilename guisuffix], ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @markartifacts_OpeningFcn, ...
    'gui_OutputFcn',  @markartifacts_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before markartifacts is made visible.
function markartifacts_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to markartifacts (see VARARGIN)

% Choose default command line output for markartifacts
handles.output = hObject;

if length(varargin) == 0 || length(varargin) > 3
    error('Usage: EEG = markartifacts(EEG, [chanvarthresh, trialvarthresh]);');
elseif length(varargin) == 1
    handles.chanvarthresh = 500;
    handles.trialvarthresh = 250;
elseif length(varargin) == 2
    handles.chanvarthresh = varargin{2};
    handles.trialvarthresh = 500;
elseif length(varargin) == 3
    handles.chanvarthresh = varargin{2};
    handles.trialvarthresh = varargin{3};
end
EEG = varargin{1};
assignin('base','EEG',EEG);

set(handles.chanEdit,'String',num2str(handles.chanvarthresh));
set(handles.trialEdit,'String',num2str(handles.trialvarthresh));

drawchan(handles);
drawtrial(handles);

set(handles.mainFig,'Name', [get(handles.mainFig,'Name') ': ' EEG.setname]);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes markartifacts wait for user response (see UIRESUME)
% uiwait(handles.mainFig);


% --- Outputs from this function are returned to the command line.
function varargout = markartifacts_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = hObject;
varargout{2} = handles;

% --- Executes on button press in acceptBtn.
function acceptBtn_Callback(hObject, eventdata, handles)
% hObject    handle to acceptBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

CloseMenuItem_Callback(hObject, eventdata, handles);

% --------------------------------------------------------------------
function FileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to FileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function OpenMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to OpenMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function PrintMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to PrintMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
printdlg(handles.mainFig)

% --------------------------------------------------------------------
function CloseMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to CloseMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

EEG = evalin('base','EEG');

badchannels = cell2mat({EEG.chanlocs.badchan});
fprintf('\n%d (%d%%) channels marked as bad: ', sum(badchannels),round(sum(badchannels)*100/length(badchannels)));
badchannels = find(badchannels);
for ch=1:length(badchannels)-1
    fprintf('''%s'',',EEG.chanlocs(badchannels(ch)).labels);
end
if ~isempty(badchannels)
    fprintf('''%s''',EEG.chanlocs(badchannels(end)).labels);
end
fprintf('\n');

fprintf('%d (%d%%) trials marked as bad.\n\n', sum(EEG.reject.rejmanual),round(sum(EEG.reject.rejmanual)*100/length(EEG.reject.rejmanual)));

delete(handles.mainFig);

% --- Executes during object creation, after setting all properties.
function chanEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to chanEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function trialEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to trialEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on chanEdit and none of its controls.
function chanEdit_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to chanEdit (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

if strcmp(eventdata.Key,'return')
    set(handles.chanText,'String','Updating...');
    pause(0.1);
    handles.chanvarthresh = str2double(get(hObject,'String'));
    drawchan(handles);
    drawtrial(handles);
end


% --- Executes on key press with focus on trialEdit and none of its controls.
function trialEdit_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to trialEdit (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

if strcmp(eventdata.Key,'return')
    set(handles.trialText,'String','Updating...');
    pause(0.1);
    handles.trialvarthresh = str2double(get(hObject,'String'));
    drawtrial(handles);
end

%% Function to update channel variance plot
function drawchan(handles)

EEG = evalin('base','EEG');

data = EEG.data;
data = reshape(data,size(EEG.data,1),size(data,2)*size(data,3));

chanvar = var(data,0,2);
zerochan = find(chanvar < 0.5);
chanvar = chanvar - median(chanvar);

badchannels = [find(chanvar > handles.chanvarthresh); zerochan];

for ch = 1:length(EEG.chanlocs)
    if sum(ch == badchannels) == 1
        EEG.chanlocs(ch).badchan = 1;
    else
        EEG.chanlocs(ch).badchan = 0;
    end
end

chanText = sprintf('%d of %d (%d%%) bad: ', ...
    length(badchannels),EEG.nbchan,round((length(badchannels)/EEG.nbchan)*100));

for ch=1:length(badchannels)
    chanText = sprintf('%s%s ',chanText,EEG.chanlocs(badchannels(ch)).labels);
end
set(handles.chanText,'String',chanText);

bar(handles.chanAxes,chanvar);
chanlabels = {EEG.chanlocs.labels};
set(handles.chanAxes,'XLim',[1 EEG.nbchan],'YLim',[0 handles.chanvarthresh*2],...
    'XTick',1:3:EEG.nbchan,'XTickLabel',chanlabels(1:3:end));
xlabel(handles.chanAxes,'Channels'); ylabel(handles.chanAxes,'Variance');
line([1 EEG.nbchan],[handles.chanvarthresh handles.chanvarthresh],...
    'LineStyle','--','LineWidth',2,'Parent',handles.chanAxes);

assignin('base','EEG',EEG);


%% Function to update trial variance plot
function drawtrial(handles)

EEG = evalin('base','EEG');

badchannels = find(cell2mat({EEG.chanlocs.badchan}));

data = EEG.data(setdiff(1:EEG.nbchan,badchannels),:,:);
data = reshape(data,size(data,1)*size(data,2),size(data,3));

trialvar = var(data);
trialvar = trialvar - median(trialvar);

EEG.reject.rejmanual = false(1,EEG.trials);
EEG.reject.rejmanualE = false(EEG.nbchan,EEG.trials);
EEG.reject.rejmanual(trialvar > handles.trialvarthresh) = true;

set(handles.trialText,'String',sprintf('%d of %d (%d%%) bad', ...
    sum(EEG.reject.rejmanual),EEG.trials,round((sum(EEG.reject.rejmanual)/EEG.trials)*100)));

bar(handles.trialAxes,trialvar);
set(handles.trialAxes,'XLim',[1 EEG.trials],'YLim',[0 handles.trialvarthresh*2]);
xlabel(handles.trialAxes,'Trials'); ylabel(handles.trialAxes,'Variance');
line([1 EEG.trials],[handles.trialvarthresh handles.trialvarthresh],...
    'LineStyle','--','LineWidth',2,'Parent',handles.trialAxes);

assignin('base','EEG',EEG);

% --- Executes during object creation, after setting all properties.
function mainFig_CreateFcn(hObject, eventdata, handles)
% hObject    handle to mainFig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function chanAxes_CreateFcn(hObject, eventdata, handles)
% hObject    handle to chanAxes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate chanAxes


% --- Executes during object creation, after setting all properties.
function trialAxes_CreateFcn(hObject, eventdata, handles)
% hObject    handle to trialAxes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate trialAxes



function chanEdit_Callback(hObject, eventdata, handles)
% hObject    handle to chanEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of chanEdit as text
%        str2double(get(hObject,'String')) returns contents of chanEdit as a double



function trialEdit_Callback(hObject, eventdata, handles)
% hObject    handle to trialEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of trialEdit as text
%        str2double(get(hObject,'String')) returns contents of trialEdit as a double
