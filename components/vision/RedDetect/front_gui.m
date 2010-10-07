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

% Last Modified by GUIDE v2.5 05-Oct-2010 19:30:39

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
	setup_global_vars(hObject); 
	updateGui; 

function updateGui
	
	global GLOBALS IMAGES; 
	handles = guidata(GLOBALS.front_gui);
	image = IMAGES(GLOBALS.focus);
	focus_h = draw_cands_on_image(handles.front_focus,image.front_stats,image.front); 
	set(focus_h,'ButtonDownFcn',{@focus_ButtonDownFcn,handles.front_focus});
	omni_h = imagesc(image.omni,'Parent',handles.flat_focus); daspect(handles.flat_focus,[1 1 1]); 
	set(omni_h,'ButtonDownFcn',{@omni_ButtonDownFcn,GLOBALS.focus,handles.flat_focus});
	draw_center_line(handles.flat_focus,image.omni,image.front_angle,GLOBALS.req_angles(GLOBALS.focus)); 
	for i = 1:9
		image = IMAGES(i);
		oname = sprintf('front%d',i);
		cname = sprintf('cand%d',i);
		draw_cands_on_image(handles.(oname),image.front_stats,image.front); 
		if(isempty(image.front_cands))
			continue
		end
		imagesc(image.front_cands{GLOBALS.cand},'Parent',handles.(cname)); daspect(handles.(cname),[1 1 1]);  
		axis(handles.(cname),'off')
		axis(handles.(oname),'off')
	end
	if ~isempty(GLOBALS.current_bb) & numel(GLOBALS.current_bb) == 4
		bb = GLOBALS.current_bb;
		image = IMAGES(GLOBALS.focus);
		if ~isempty(image.front)
			imagesc(image.front(bb(1):bb(2),bb(3):bb(4),:),'Parent',handles.cand_focus);
		end
		daspect(handles.cand_focus,[1 1 1]);  
		axis(handles.cand_focus,'off')
		line([bb(3),bb(4)],[bb(1),bb(1)],'Color','c','LineWidth',2,'Parent',handles.front_focus);
		line([bb(3),bb(4)],[bb(2),bb(2)],'Color','c','LineWidth',2,'Parent',handles.front_focus);
		line([bb(3),bb(3)],[bb(1),bb(2)],'Color','c','LineWidth',2,'Parent',handles.front_focus);
		line([bb(4),bb(4)],[bb(1),bb(2)],'Color','c','LineWidth',2,'Parent',handles.front_focus);
		po = front_pixel_to_omni(IMAGES(1).omni,IMAGES(1).front,mean(bb(3:4))); 
		angle = pixel_to_angle(IMAGES(1).omni,po); 
		GLOBALS.req_angles(GLOBALS.focus) = angle; 
	end
	set(handles.current_label,'String',strcat('<--',GLOBALS.current_label)); 
	
	axis(handles.front_focus,'off')

% --- Outputs from this function are returned to the command line.
function varargout = front_gui_OutputFcn(hObject, eventdata, handles) 
	% varargout  cell array for returning output args (see VARARGOUT);
	% hObject    handle to figure
	% eventdata  reserved - to be defined in a future version of MATLAB
	% handles    structure with handles and user data (see GUIDATA)

	% Get default command line output from handles structure
	varargout{1} = handles.output;

function focus_ButtonDownFcn(hObject, eventdata, axeh)
	global IMAGES GLOBALS 
	cp = get(axeh,'CurrentPoint');
	x = cp(1,1);
	y = cp(1,2);  
	[x,y]
	if numel(GLOBALS.current_bb) == 2
		x1 = GLOBALS.current_bb(1); 
		y1 = GLOBALS.current_bb(2);
		if abs(x1-x) < 10 & abs(y1-y) < 10
			if ~isemtpy(IMAGES(GLOBALS.focus).front_stats)
				GLOBALS.current_bb = IMAGES(GLOBALS.focus).front_stats(GLOBALS.cand,2:end);
			end
			po = front_pixel_to_omni(IMAGES(1).omni,IMAGES(1).front,x); 
			angle = pixel_to_angle(IMAGES(1).omni,po); 
			GLOBALS.req_angles(GLOBALS.focus) = angle; 
			set_status('Focus request'); 
		else
			GLOBALS.current_bb = round([y1,y,x1,x]);  
		end
	elseif numel(GLOBALS.current_bb) == 4
		GLOBALS.current_bb = [x,y]; 
	end 
	updateGui; 

function omni_ButtonDownFcn(hObject, eventdata, id, axeh)
	global IMAGES GLOBALS;
	cp = get(axeh,'CurrentPoint');
	x = cp(1,1);
	y = cp(1,2);  
	[x,y]
	angle = pixel_to_angle(IMAGES(id).omni,x) 
	GLOBALS.req_angles(id) = angle; 
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
	global GLOBALS;
	h = guidata(GLOBALS.front_gui);
	set(h.status_text,'String',msg)


function setup_global_vars(front_gui)
	global GLOBALS IMAGES;
	GLOBALS.front_gui = front_gui; 
	GLOBALS.focus = 1; 
	GLOBALS.cand = 1; 
	GLOBALS.req_angles = -ones(1,9);
	GLOBALS.current_bb = [1,1,1,1]; 
	GLOBALS.current_label = '?'; 
	GLOBALS.current_ser = 1; 
	front_fns.updateGui		  = @updateGui;  
	front_fns.set_status		  = @set_status;  
	front_fns.switch_cand_Callback    = @switch_cand_Callback; 
	front_fns.lookat_Callback         = @lookat_Callback;
	front_fns.yellow_barrel_Callback  = @yellow_barrel_Callback;
	front_fns.car_Callback            = @car_Callback;
	front_fns.door_Callback           = @door_Callback;
	front_fns.red_barrel_Callback     = @red_barrel_Callback;
	front_fns.cancel_type_Callback    = @cancel_type_Callback;
	front_fns.confirm_type_Callback   = @confirm_type_Callback;
	front_fns.mobile_ooi_Callback     = @mobile_ooi_Callback;
	front_fns.lazer_up_Callback       = @lazer_up_Callback;
	front_fns.lazer_on_Callback       = @lazer_on_Callback;
	front_fns.lazer_down_Callback     = @lazer_down_Callback;
	front_fns.lazer_off_Callback      = @lazer_off_Callback;
	GLOBALS.front_fns = front_fns; 
	
function switch_cand_Callback(hObject, eventdata, handles)
	global GLOBALS IMAGES;
	GLOBALS.cand = mod(GLOBALS.cand+1,3) + 1; 
	set_status('switch cands'); 
	GLOBALS.current_bb = IMAGES(GLOBALS.focus).front_stats(GLOBALS.cand,2:end); 
	GLOBALS.current_label = 'red'; 
	updateGui; 
	
function lookat_Callback(hObject, eventdata, handles)
	set_status('lookat');
	global ROBOTS, GLOBALS; 
	id = GLOBALS.focus; 
	msg.phi = 0; 
	msg.theta = GLOBALS.req_angles(id);
	msg.type = 'look';  
	ROBOTS(id).ipcAPI('publish',sprintf('Robot%d/Look_Msg',id),serialize(msg));

function yellow_barrel_Callback(hObject, eventdata, handles)
	global GLOBALS; 
	GLOBALS.current_label = 'yellow'; 
	set_status('label yellow barrel'); 	
	updateGui;  

function car_Callback(hObject, eventdata, handles)
	global GLOBALS; 
	GLOBALS.current_label = 'car';
	set_status('label car'); 	
	updateGui;  

function door_Callback(hObject, eventdata, handles)
	global GLOBALS; 
	GLOBALS.current_label = 'door'; 
	set_status('label door'); 	
	updateGui;  

function red_barrel_Callback(hObject, eventdata, handles)
	global GLOBALS; 
	GLOBALS.current_label = 'red'; 
	set_status('label red barrel'); 	
	updateGui;  

function cancel_type_Callback(hObject, eventdata, handles)
	global GLOBALS; 
	GLOBALS.current_label = '?'; 
	set_status('cancel label'); 	
	updateGui;  

function confirm_type_Callback(hObject, eventdata, handles)
	global GLOBALS VISION_IPC 
	set_status('confirm label'); 	
	VISION_IPC('define','OOI_Msg'); 
	msg.id=GLOBALS.focus;  
	msg.ser= GLOBALS.current_ser; 
	msg.type= 1
	msg.x= 5
	msg.y= 0
	VISION_IPC('publish','OOI_Msg',serialize(msg)); 
	GLOBALS.current_ser = GLOBALS.current_ser + 1;  

function mobile_ooi_Callback(hObject, eventdata, handles)
	global GLOBALS; 
	GLOBALS.current_label = 'mobile'; 
	set_status('mobile ooi mode'); 	
	updateGui;  

function lazer_up_Callback(hObject, eventdata, handles)
	set_status('lazer up'); 	

function lazer_on_Callback(hObject, eventdata, handles)
	set_status('lazer on'); 	

function lazer_down_Callback(hObject, eventdata, handles)
	set_status('lazer down'); 	

function lazer_off_Callback(hObject, eventdata, handles)
	set_status('lazer off'); 	


