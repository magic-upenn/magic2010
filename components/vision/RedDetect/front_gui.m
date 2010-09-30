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

% Last Modified by GUIDE v2.5 27-Sep-2010 12:42:53

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

guidata(hObject, handles);

global FRONT_GUI
global FRONT_UP
FRONT_GUI = hObject; 
FRONT_UP = @updateGui;

global CAND
global FOCUS
FOCUS = 1;
CAND = 1; 
updateGui; 

function updateGui 
global FRONT_GUI
global CAND
global FOCUS
global IMAGES
handles = guidata(FRONT_GUI);
image = IMAGES(FOCUS);
draw_cands_on_image(handles.front_focus,image.front_stats,image.front); 
imagesc(image.omni,'Parent',handles.flat_focus); daspect(handles.flat_focus,[1 1 1]); 
for i = 1:9
	image = IMAGES(i);
	oname = sprintf('front%d',i);
	cname = sprintf('cand%d',i);
%	image.stats = flipud(sortrows(image.front_stats,1));  
	draw_cands_on_image(handles.(oname),image.front_stats,image.front); 
	if(isempty(image.front_cands))
		continue
	end
	imagesc(image.front_cands{CAND},'Parent',handles.(cname)); daspect(handles.(cname),[1 1 1]);  
end


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


% --- Executes on button press in switch_cand.
function switch_cand_Callback(hObject, eventdata, handles)
% hObject    handle to switch_cand (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global IMAGES;
global CAND;

CAND = mod(CAND+1,3) + 1; 
for i = 1:9
	image = IMAGES(i);
	cname = sprintf('cand%d',i);
	if(isempty(image.front_cands))
		continue
	end
	axes(handles.(cname)); imagesc(image.front_cands{CAND}); daspect([1 1 1]);  
end


