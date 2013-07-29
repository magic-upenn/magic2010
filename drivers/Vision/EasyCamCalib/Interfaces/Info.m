function varargout = Info(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Info_OpeningFcn, ...
                   'gui_OutputFcn',  @Info_OutputFcn, ...
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


% --- Executes just before Info is made visible.
function Info_OpeningFcn(hObject, eventdata, handles, varargin)
setappdata(0,'PROCEED',0);

if getappdata(0,'ISARTHROSCOPIC')
    set(handles.imagetype,'String', 'Arthroscope');
else
    set(handles.imagetype,'String', 'Point Grey');
end
if getappdata(0,'REFINEMENT');
    set(handles.refinement,'String', 'ON');
else
    set(handles.refinement,'String', 'OFF');
end
if getappdata(0,'CHANGEORIGINS');
    set(handles.autoorigin,'String', 'ON');
else
    set(handles.autoorigin,'String', 'OFF');
end
gs=getappdata(0,'GRIDSIZE');
set(handles.gridsize,'String', sprintf('%.1fx%.1f',gs,gs));
res=getappdata(0,'RESOLUTION');
set(handles.imagesize,'String', sprintf('%dx%d',res(2),res(1)));
set(handles.imagenumber,'String', getappdata(0,'NUMBEROFIMAGES'));
% Choose default command line output for Info
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = Info_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;


% --- Executes on button press in proceed.
function proceed_Callback(hObject, eventdata, handles)
setappdata(0,'PROCEED',1);
delete(handles.figure1);


% --- Executes on button press in cancel.
function cancel_Callback(hObject, eventdata, handles)
delete(handles.figure1);


function edit1_Callback(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
