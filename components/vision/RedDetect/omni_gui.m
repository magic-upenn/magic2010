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

% Last Modified by GUIDE v2.5 04-Oct-2010 13:30:42

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
guidata(hObject, handles);

global OMNI_GUI
global OMNI_UP
OMNI_GUI = hObject; 
OMNI_UP = @updateGui;

global CAND
CAND = 1; 
global REQ_ANGLES
REQ_ANGLES = -ones(1,9); 
updateGui; 


function updateGui
global OMNI_GUI
global CAND
global IMAGES
global REQ_ANGLES
handles = guidata(OMNI_GUI);
for i = 1:9
	image = IMAGES(i);
	oname = sprintf('omni%d',i);
	cname = sprintf('cand%d',i);
%	image.stats = flipud(sortrows(image.omni_stats,1));  
	omni_h  = draw_cands_on_image(handles.(oname),image.omni_stats,image.omni); 
	draw_center_line(handles.(oname),image.omni,image.front_angle,REQ_ANGLES(i)); 
	if(isempty(image.omni_cands))
		continue
	end
	cand_h = imagesc(image.omni_cands{CAND},'Parent',handles.(cname)); daspect(handles.(cname),[1 1 1]);  
	set(omni_h,'ButtonDownFcn',{@omni_ButtonDownFcn,i,handles.(oname)});
	set(cand_h,'ButtonDownFcn',{@cand_ButtonDownFcn,i,handles.(cname)});
	 
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


% --- Executes on button press in switch_cand.
function switch_cand_Callback(hObject, eventdata, handles)
% hObject    handle to switch_cand (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global IMAGES;
global CAND;
 
CAND = mod(CAND+1,3) + 1; 
updateGui; 
%for i = 1:9
%	image = IMAGES(i);
%	cname = sprintf('cand%d',i);
%	if(isempty(image.omni_cands))
%		continue
%	end
%	axes(handles.(cname)); imagesc(image.omni_cands{CAND}); daspect([1 1 1]);  
%end


% --- Executes on mouse press over axes background.
function cand_ButtonDownFcn(hObject, eventdata, id, axeh)
	global IMAGES;
	global CAND;
	global REQ_ANGLES;
	xpos = IMAGES(id).omni_stats(CAND,4:end);
	[id,CAND] 
	angle = pixel_to_angle(IMAGES(id).omni,mean(xpos));  
	REQ_ANGLES(id) = angle; 
	updateGui;   

function omni_ButtonDownFcn(hObject, eventdata, id, axeh)
	global IMAGES;
	global REQ_ANGLES;
	id
	cp = get(axeh,'CurrentPoint');
	x = cp(1,1);
	y = cp(1,2);  
	[x,y]
	angle = pixel_to_angle(IMAGES(id).omni,x) 
	REQ_ANGLES(id) = angle; 
	updateGui;   
% hObject    handle to omni1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


