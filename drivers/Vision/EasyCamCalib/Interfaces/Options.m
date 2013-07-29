function varargout = Options(varargin)

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Options_OpeningFcn, ...
                   'gui_OutputFcn',  @Options_OutputFcn, ...
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


% --- Executes just before Options is made visible.
function Options_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;

%Get some variables from the main GUI
handles.PROJECTPATH = getappdata(0,'PROJECTPATH');
handles.defaultOptionsPath = getappdata(0,'DEFAULTOPTIONSPATH');

%Load the current options, or the default option from a file.
curroptpath=sprintf('%stemp/currentOptions.mat',handles.PROJECTPATH);
if(exist(curroptpath,'file'))
    fprintf('Loading current options: %s \n', curroptpath);
    temp=load(curroptpath);
else %No need to check if the default file exists, if we get eher the main gui has created the file
    fprintf('Loading default options: %s \n', handles.defaultOptionsPath);
    temp=load(handles.defaultOptionsPath);
end
if(~isfield(temp,'optionsGUI'))
    disp('Bad options file, please edit the options again...');
    return;
end

%Initialize options
handles.ISARTHROSCOPIC = 1;
handles.REFINEMENT = 1;
handles.CHANGEORIGINS = 0;
handles.GRIDSIZE = [];
handles.DISCARDFAIL = 1;
handles.ABORTONIMAGEFAILURE = 1;
handles.OPENEDOPTIONS = 1;

%Retrieve the options
if isfield(temp.optionsGUI,'ISARTHROSCOPIC')
    handles.ISARTHROSCOPIC = temp.optionsGUI.ISARTHROSCOPIC;
    if handles.ISARTHROSCOPIC
        set(handles.source,'SelectedObject',handles.source_arthro)
    else
        set(handles.source,'SelectedObject',handles.source_ptg)
    end
end
if isfield(temp.optionsGUI,'REFINEMENT')
    handles.REFINEMENT = temp.optionsGUI.REFINEMENT;
    set(handles.autorefine,'Value',handles.REFINEMENT)
end
if isfield(temp.optionsGUI,'CHANGEORIGINS')
    handles.CHANGEORIGINS = temp.optionsGUI.CHANGEORIGINS;
    set(handles.autoorigin,'Value',handles.CHANGEORIGINS)
end
if isfield(temp.optionsGUI,'DISCARDFAIL')
    handles.DISCARDFAIL = temp.optionsGUI.DISCARDFAIL;
    set(handles.discard,'Value',handles.DISCARDFAIL)
end
if isfield(temp.optionsGUI,'ABORTONIMAGEFAILURE')
    handles.ABORTONIMAGEFAILURE = temp.optionsGUI.ABORTONIMAGEFAILURE;
    set(handles.abort,'Value',handles.ABORTONIMAGEFAILURE)
end
if isfield(temp.optionsGUI,'GRIDSIZE')
    handles.GRIDSIZE = temp.optionsGUI.GRIDSIZE;
    set(handles.gridsize,'string',handles.GRIDSIZE)
end

% Update handles structure
guidata(hObject, handles);


function updateCheckBoxes(handles)
set(handles.autoorigin,'enable','on');


function varargout = Options_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

function abort_Callback(hObject, eventdata, handles)
if (get(hObject,'Value') == get(hObject,'Max'))
    handles.ABORTONIMAGEFAILURE = 1;
else
    handles.ABORTONIMAGEFAILURE = 0;
end
guidata(hObject, handles);

function autoorigin_Callback(hObject, eventdata, handles)
if (get(hObject,'Value') == get(hObject,'Max'))
    handles.CHANGEORIGINS = 1;
else
    handles.CHANGEORIGINS = 0;
end
guidata(hObject, handles);

function autorefine_Callback(hObject, eventdata, handles)
if (get(hObject,'Value') == get(hObject,'Max'))
    handles.REFINEMENT = 1;
else
    handles.REFINEMENT = 0;
end
guidata(hObject, handles);


function source_arthro_Callback(hObject, eventdata, handles)

function source_ptg_Callback(hObject, eventdata, handles)

function source_ButtonDownFcn(hObject, eventdata, handles)

function source_SelectionChangeFcn(hObject, eventdata, handles)
switch get(hObject,'Tag')   % Get Tag of selected object
    case 'source_arthro'
        handles.ISARTHROSCOPIC = 1;
    case 'source_ptg'
        handles.ISARTHROSCOPIC = 0;
    otherwise
        disp('UNKNOWN')
end
guidata(hObject, handles);


function saveandquit_Callback(hObject, eventdata, handles)
%Apply the selected options
setappdata(0,'OPENEDOPTIONS',handles.OPENEDOPTIONS);
setappdata(0,'ISARTHROSCOPIC',handles.ISARTHROSCOPIC);
setappdata(0,'REFINEMENT',handles.REFINEMENT);
setappdata(0,'CHANGEORIGINS',handles.CHANGEORIGINS);
setappdata(0,'DISCARDFAIL',handles.DISCARDFAIL);
setappdata(0,'ABORTONIMAGEFAILURE',handles.ABORTONIMAGEFAILURE);
if isnan(str2double(get(handles.gridsize,'string')))
    errordlg('You must enter a numeric value on Grid Size','Bad Input','modal')
    return
else
    handles.GRIDSIZE = str2num(get(handles.gridsize,'string'));
    setappdata(0,'GRIDSIZE',handles.GRIDSIZE);   
end
%Save the current options in a file
optionsGUI=handles;
save(sprintf('%stemp/currentOptions.mat',handles.PROJECTPATH),'optionsGUI')
fprintf('Options saved under: %stemp/currentOptions.mat \n',handles.PROJECTPATH);
delete(handles.figure1);

% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function saveandquit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to saveandquit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


function discard_Callback(hObject, eventdata, handles)
if (get(hObject,'Value') == get(hObject,'Max'))
    handles.DISCARDFAIL = 1;
else
    handles.DISCARDFAIL = 0;
end
guidata(hObject, handles);



function gridsize_Callback(hObject, eventdata, handles)
% hObject    handle to gridsize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of gridsize as text
%        str2double(get(hObject,'String')) returns contents of gridsize as a double


% --- Executes during object creation, after setting all properties.
function gridsize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to gridsize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
