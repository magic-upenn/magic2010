function varargout = front_gui(varargin)
% FRONT_GUI M-file for front_gui.fig
%      FRONT_GUI, by itself, creates a new FRONT_GUI or raises the existing
%      singleton*.
%
%      H = FRONT_GUI returns the handle to a new FRONT_GUI or the handle to
%      the existing singleton*.
%
%      FRONT_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FRONT_GUI.M with the given input arguments.
%
%      FRONT_GUI('Property','Value',...) creates a new FRONT_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before front_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to front_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help front_gui

% Last Modified by GUIDE v2.5 22-Sep-2010 10:10:09

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @front_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @front_gui_OutputFcn, ...
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


% --- Executes just before front_gui is made visible.
function front_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to front_gui (see VARARGIN)

% Choose default command line output for front_gui
handles.output = hObject;

% Update handles structure

global FRONT, global OMNI
guidata(hObject, handles);

global FRONT_HANDLES;
FRONT_HANDLES = handles; 
all_stats = [];
if ~isempty(FRONT) 
for i = 1:9
	fname = sprintf('front%d',i)
	all_stats = [all_stats; [ones(size(FRONT(i).stats,1),1),FRONT(i).stats]];
	FRONT(i).stats = flipud(sortrows(FRONT(i).stats,2));  
	draw_cands_on_image(FRONT_HANDLES.(fname),FRONT(i).stats,FRONT(i).img); 
	if i == 9
		break
	end
	cname = sprintf('cand%d',i)
	draw_cand_on_axes(FRONT_HANDLES.(cname),FRONT(i).stats,i,FRONT(i).img); 
end
end
%vision_guis
for i =1:100000
	im = get_image(2);
	axes(handles.front_focus); 
	imagesc(im); 
	[red, stats] = find_red_candidates(im);
	size(stats);
	draw_cands_on_image(handles.front1,stats,im); 
	draw_cand_on_axes(handles.cand1,stats,1,im);  	 
	pause(1); 
end
% UIWAIT makes front_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = front_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in target_intensity.
function target_intensity_Callback(hObject, eventdata, handles)
% hObject    handle to target_intensity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in calibrate.
function calibrate_Callback(hObject, eventdata, handles)
% hObject    handle to calibrate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in manual_label.
function manual_label_Callback(hObject, eventdata, handles)
% hObject    handle to manual_label (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in confirm_OOI.
function confirm_OOI_Callback(hObject, eventdata, handles)
% hObject    handle to confirm_OOI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function target_intensity_focus_edit_Callback(hObject, eventdata, handles)
% hObject    handle to target_intensity_focus_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of target_intensity_focus_edit as text
%        str2double(get(hObject,'String')) returns contents of target_intensity_focus_edit as a double


% --- Executes during object creation, after setting all properties.
function target_intensity_focus_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to target_intensity_focus_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in calibrate_all.
function calibrate_all_Callback(hObject, eventdata, handles)
% hObject    handle to calibrate_all (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in autocalibrate_freq.
function autocalibrate_freq_Callback(hObject, eventdata, handles)
% hObject    handle to autocalibrate_freq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in target_intensity_all.
function target_intensity_all_Callback(hObject, eventdata, handles)
% hObject    handle to target_intensity_all (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function target_intensity_all_entry_Callback(hObject, eventdata, handles)
% hObject    handle to target_intensity_all_entry (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of target_intensity_all_entry as text
%        str2double(get(hObject,'String')) returns contents of target_intensity_all_entry as a double


% --- Executes during object creation, after setting all properties.
function target_intensity_all_entry_CreateFcn(hObject, eventdata, handles)
% hObject    handle to target_intensity_all_entry (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function autocalibrate_freq_entry_Callback(hObject, eventdata, handles)
% hObject    handle to autocalibrate_freq_entry (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of autocalibrate_freq_entry as text
%        str2double(get(hObject,'String')) returns contents of autocalibrate_freq_entry as a double


% --- Executes during object creation, after setting all properties.
function autocalibrate_freq_entry_CreateFcn(hObject, eventdata, handles)
% hObject    handle to autocalibrate_freq_entry (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in track_mode.
function track_mode_Callback(hObject, eventdata, handles)
% hObject    handle to track_mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in target_mode.
function target_mode_Callback(hObject, eventdata, handles)
% hObject    handle to target_mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
