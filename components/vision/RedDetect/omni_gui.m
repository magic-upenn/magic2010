function varargout = omni_gui(varargin)
% OMNI_GUI M-file for omni_gui.fig
%      OMNI_GUI, by itself, creates a new OMNI_GUI or raises the existing
%      singleton*.
%
%      H = OMNI_GUI returns the handle to a new OMNI_GUI or the handle to
%      the existing singleton*.
%
%      OMNI_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in OMNI_GUI.M with the given input arguments.
%
%      OMNI_GUI('Property','Value',...) creates a new OMNI_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before omni_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to omni_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help omni_gui

% Last Modified by GUIDE v2.5 22-Sep-2010 09:25:16

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @omni_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @omni_gui_OutputFcn, ...
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


% --- Executes just before omni_gui is made visible.
function omni_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to omni_gui (see VARARGIN)

% Choose default command line output for omni_gui
handles.output = hObject;

% Update handles structure
global OMNI; 
guidata(hObject, handles);

all_stats = []; 
for i = 1:9
	oname = sprintf('omni%d',i)
	all_stats = [all_stats; [ones(size(OMNI(i).stats,1),1),OMNI(i).stats]];
	OMNI(i).stats = flipud(sortrows(OMNI(i).stats,2));  
	draw_cands_on_image(handles.(oname),OMNI(i).stats,OMNI(i).img); 
	cname = sprintf('cand%d',i)
	draw_cand_on_axes(handles.(cname),OMNI(i).stats,i,OMNI(i).img); 
end

%all_stats = flipud(sortrows(all_stats,3));  
%for i = 1:8
%	cname = sprintf('cand%d',i)
%	draw_cand_on_axes(handles.(cname),all_stats(i,2:end),i,OMNI(all_stats(i,1)).img); 
%end

% UIWAIT makes omni_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);a 


% --- Outputs from this function are returned to the command line.
function varargout = omni_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in calibrate_all.
function calibrate_all_Callback(hObject, eventdata, handles)
% hObject    handle to calibrate_all (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


