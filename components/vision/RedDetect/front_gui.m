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

% Last Modified by GUIDE v2.5 04-Oct-2010 18:36:34

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
	handles.output = hObject;
	guidata(hObject, handles);
	
	setup_global_fns; 
	global FRONT_GUI FRONT_UP CAND FOCUS
	FRONT_GUI = hObject; 
	FRONT_UP = @updateGui;
	FOCUS = 1;
	CAND = 1; 
	REQ_ANGLES = -ones(1,9); 
	updateGui; 

function updateGui 
	global FRONT_GUI CAND FOCUS IMAGES REQ_ANGLES
	handles = guidata(FRONT_GUI);
	image = IMAGES(FOCUS);
	draw_cands_on_image(handles.front_focus,image.front_stats,image.front); 
	omni_h = imagesc(image.omni,'Parent',handles.flat_focus); daspect(handles.flat_focus,[1 1 1]); 
	set(omni_h,'ButtonDownFcn',{@omni_ButtonDownFcn,FOCUS,handles.flat_focus});
	draw_center_line(handles.flat_focus,image.omni,image.front_angle,REQ_ANGLES(FOCUS)); 
	for i = 1:9
		image = IMAGES(i);
		oname = sprintf('front%d',i);
		cname = sprintf('cand%d',i);
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

%All buttons
function figure1_KeyPressFcn(hObject, eventdata, handles)
	chr = get(gcf,'CurrentCharacter'); 
	if chr == 13 
		chr = 'enter'; 
	elseif chr == 127
		chr = 'del'; 
	elseif chr == 28
		chr = 'left';
	elseif chr == 29
		chr = 'right'; 
	elseif chr == 30
		chr = 'up';
	elseif chr == 31
		chr = 'down';
	end
	button_handler(chr,'front'); 
%	num = str2num(char); 
%	if ~isempty(num)
%		if num == 0
%			switch_cand_Callback(hObject, eventdata, handles)
%		else 
%			FOCUS = num; 
%			updateGui;
%		end
%	end

function set_status(msg)
	global FRONT_GUI;
	h = guidata(FRONT_GUI);
	set(h.status_text,'String',msg)


function setup_global_fns
	global FRONT_FNS;
	FRONT_FNS.set_status		  = @set_status;  
	FRONT_FNS.switch_cand_Callback    = @switch_cand_Callback; 
	FRONT_FNS.lookat_Callback         = @lookat_Callback;
	FRONT_FNS.yellow_barrel_Callback  = @yellow_barrel_Callback;
	FRONT_FNS.car_Callback            = @car_Callback;
	FRONT_FNS.door_Callback           = @door_Callback;
	FRONT_FNS.red_barrel_Callback     = @red_barrel_Callback;
	FRONT_FNS.cancel_type_Callback    = @cancel_type_Callback;
	FRONT_FNS.confirm_type_Callback   = @confirm_type_Callback;
	FRONT_FNS.mobile_ooi_Callback     = @mobile_ooi_Callback;
	FRONT_FNS.lazer_up_Callback       = @lazer_up_Callback;
	FRONT_FNS.lazer_up_on_Callback    = @lazer_up_on_Callback;
	FRONT_FNS.lazer_down_Callback     = @lazer_down_Callback;
	FRONT_FNS.lazer_off_Callback      = @lazer_off_Callback;
	
function switch_cand_Callback(hObject, eventdata, handles)
	global IMAGES CAND;
	CAND = mod(CAND+1,3) + 1; 
	updateGui; 
	set_status('switch cands'); 
	
function lookat_Callback(hObject, eventdata, handles)
	set_status('lookat');
 	
function yellow_barrel_Callback(hObject, eventdata, handles)
	set_status('label yellow barrel'); 	

function car_Callback(hObject, eventdata, handles)
	set_status('label car'); 	

function door_Callback(hObject, eventdata, handles)
	set_status('label door'); 	

function red_barrel_Callback(hObject, eventdata, handles)
	set_status('label red barrel'); 	

function cancel_type_Callback(hObject, eventdata, handles)
	set_status('cancel label'); 	

function confirm_type_Callback(hObject, eventdata, handles)
	set_status('confirm label'); 	

function mobile_ooi_Callback(hObject, eventdata, handles)
	set_status('mobile ooi mode'); 	

function lazer_up_Callback(hObject, eventdata, handles)
	set_status('lazer up'); 	

function lazer_on_Callback(hObject, eventdata, handles)
	set_status('lazer on'); 	

function lazer_down_Callback(hObject, eventdata, handles)
	set_status('lazer down'); 	

function lazer_off_Callback(hObject, eventdata, handles)
	set_status('lazer off'); 	


