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

% Last Modified by GUIDE v2.5 07-Oct-2010 11:07:30

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

	%Front Focus	
	focus_h = draw_cands_on_image(handles.front_focus,image.front_stats,image.front); 
	set(focus_h,'ButtonDownFcn',{@focus_ButtonDownFcn,handles.front_focus});
	
	%Omni Focus	
	omni_h = imagesc(image.omni,'Parent',handles.flat_focus); daspect(handles.flat_focus,[1 1 1]); 
	set(omni_h,'ButtonDownFcn',{@omni_ButtonDownFcn,GLOBALS.focus,handles.flat_focus});
	draw_center_line(handles.flat_focus,image.omni,image.front_angle,GLOBALS.req_angles(GLOBALS.focus)); 
	
	for i = 1:9
		image = IMAGES(i);
		oname = sprintf('front%d',i);
		cname = sprintf('cand%d',i);
		draw_cands_on_image(handles.(oname),image.front_stats,image.front); 
		imagesc(image.front_cands{GLOBALS.cand},'Parent',handles.(cname)); 
		daspect(handles.(cname),[1 1 1]);  
		axis(handles.(cname),'off')
		axis(handles.(oname),'off')
	end

	bb = GLOBALS.current_bb;
	image = IMAGES(GLOBALS.focus);
	imagesc(image.front(bb(1):bb(2),bb(3):bb(4),:),'Parent',handles.cand_focus);
	daspect(handles.cand_focus,[1 1 1]);  
	axis(handles.cand_focus,'off')
	line([bb(3),bb(4)],[bb(1),bb(1)],'Color','c','LineWidth',2,'Parent',handles.front_focus);
	line([bb(3),bb(4)],[bb(2),bb(2)],'Color','c','LineWidth',2,'Parent',handles.front_focus);
	line([bb(3),bb(3)],[bb(1),bb(2)],'Color','c','LineWidth',2,'Parent',handles.front_focus);
	line([bb(4),bb(4)],[bb(1),bb(2)],'Color','c','LineWidth',2,'Parent',handles.front_focus);
%	po = front_pixel_to_omni(IMAGES(1).omni,IMAGES(1).front,mean(bb(3:4))); 
%	angle = pixel_to_angle(IMAGES(1).omni,po); 
%	GLOBALS.req_angles(GLOBALS.focus) = angle; 
	
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
	if numel(GLOBALS.current_bb) == 6
		x1 = GLOBALS.current_bb(5); 
		y1 = GLOBALS.current_bb(6);
		if abs(x1-x) < 10 & abs(y1-y) < 10
			id = GLOBALS.focus; 
			GLOBALS.current_bb = IMAGES(id).front_stats(GLOBALS.cand,2:end);
			po = front_pixel_to_omni(IMAGES(id).omni,IMAGES(id).front,x); 
			angle = pixel_to_angle(IMAGES(id).omni,po);
			lookat(GLOBALS.focus, angle);  
		else
			GLOBALS.current_bb = round([y1,y,x1,x]);  
		end
		GLOBALS.current_bb = [GLOBALS.current_bb,[1 1 1 1]]; 
	elseif numel(GLOBALS.current_bb) == 8
		GLOBALS.current_bb(5:6) = round([x,y]);
		GLOBALS.current_bb(7:8) = [];
	end
	updateGui; 

function omni_ButtonDownFcn(hObject, eventdata, id, axeh)
	global IMAGES GLOBALS;
	cp = get(axeh,'CurrentPoint');
	x = cp(1,1);
	y = cp(1,2);  
	[x,y]
	angle = pixel_to_angle(IMAGES(id).omni,x) 
	lookat(id,angle); 

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
	GLOBALS.current_bb = [1,1,1,1,1,1,1,1]; 
	GLOBALS.current_label = '?'; 
	GLOBALS.current_ser = 1; 
	front_fns.updateGui		  = @updateGui;  
	front_fns.set_status		  = @set_status;  
	front_fns.switch_cand_Callback    = @switch_cand_Callback; 
	front_fns.lookat_Callback         = @lookat_Callback;
	front_fns.car_Callback            = @car_Callback;
	front_fns.door_Callback           = @door_Callback;
	front_fns.cancel_type_Callback    = @cancel_type_Callback;
	front_fns.confirm_type_Callback   = @confirm_type_Callback;
	front_fns.mobile_ooi_Callback     = @mobile_ooi_Callback;
	front_fns.lazer_up_Callback       = @lazer_up_Callback;
	front_fns.lazer_on_Callback       = @lazer_on_Callback;
	front_fns.lazer_down_Callback     = @lazer_down_Callback;
	front_fns.lazer_off_Callback      = @lazer_off_Callback;
	front_fns.red_ooi_Callback        = @red_ooi_Callback;       
	front_fns.yellow_ooi_Callback     = @yellow_ooi_Callback;
	front_fns.still_mobile_Callback   = @still_mobile_Callback;
	front_fns.nudge_right_Callback    = @nudge_right_Callback;
	front_fns.nudge_left_Callback     = @nudge_left_Callback; 
	front_fns.lookat	          = @lookat; 

	GLOBALS.front_fns = front_fns; 
	null_front = null_image(320,240); 	
	null_omni  = null_image(775,155);
	null_cand  = null_image(150,150);
	null_cands = {}; 
	null_stats = ones(3,5); 
	null_stats(:,1) = 0; 
	for cand = 1:3
		null_cands{cand} = null_cand;  
	end  	
	for id=1:9
	    IMAGES(id).id = id;
	    IMAGES(id).t = [];
	    IMAGES(id).omni = null_omni;
	    IMAGES(id).front = null_front;
	    IMAGES(id).front_angle = [];
	    IMAGES(id).omni_cands = null_cands;
	    IMAGES(id).front_cands = null_cands;
	    IMAGES(id).omni_stats = null_stats;
	    IMAGES(id).front_stats = null_stats;
	end
	GLOBALS.null_cand = null_cand; 
	
function switch_cand_Callback(hObject, eventdata, handles)
	global GLOBALS IMAGES;
	GLOBALS.cand = mod(GLOBALS.cand+1,3) + 1; 
	set_status('switch cands'); 
	GLOBALS.current_bb = IMAGES(GLOBALS.focus).front_stats(GLOBALS.cand,2:end); 
	GLOBALS.current_label = 'red'; 
	updateGui; 
	
function lookat_Callback(hObject, eventdata, handles)
	global GLOBALS IMAGES; 
	id = GLOBALS.focus; 
	x = mean(IMAGES(id).front_stats(GLOBALS.focus,4:5));
	po = front_pixel_to_omni(IMAGES(id).omni,IMAGES(id).front,x); 
	angle = pixel_to_angle(IMAGES(id).omni,po);
	lookat(id,angle); 
	 

function yellow_ooi_Callback(hObject, eventdata, handles)
	set_label('YellowBarrel'); 

function car_Callback(hObject, eventdata, handles)
	set_label('Car'); 

function door_Callback(hObject, eventdata, handles)
	set_label('Doorway'); 

function red_ooi_Callback(hObject, eventdata, handles)
	set_label('RedBarrel'); 

function mobile_ooi_Callback(hObject, eventdata, handles)
	set_label('MovingPOI'); 

function still_mobile_Callback(hObject, eventdata, handles)
	set_label('StationaryPOI'); 

function cancel_type_Callback(hObject, eventdata, handles)
	global GLOBALS; 
	send_ooi_done_msg(GLOBALS.current_ser-1,'canceled')
	set_status('cancel label'); 	

function confirm_type_Callback(hObject, eventdata, handles)
	global GLOBALS;  
	set_status('confirm label'); 	
	x = 5; 
	y = 0; 
	send_ooi_msg(GLOBALS.focus,GLOBALS.current_ser,x,y,GLOBALS.current_label)
	GLOBALS.current_ser = GLOBALS.current_ser + 1;  

function lazer_up_Callback(hObject, eventdata, handles)
	global GLOBALS; 
	set_status('lazer up'); 	
	send_lazer_msg(GLOBALS.focus,'up'); 

function lazer_down_Callback(hObject, eventdata, handles)
	global GLOBALS; 
	set_status('lazer down'); 	
	send_lazer_msg(GLOBALS.focus,'down'); 

function lazer_on_Callback(hObject, eventdata, handles)
	global GLOBALS; 
	set_status('lazer on'); 	
	send_lazer_msg(GLOBALS.focus,'on'); 

function lazer_off_Callback(hObject, eventdata, handles)
	global GLOBALS; 
	set_status('lazer off'); 	
	send_lazer_msg(GLOBALS.focus,'off'); 

function nudge_right_Callback(hObject, eventdata, handles)
	global GLOBALS; 
	set_status('nudge_right'); 	
	send_nudge_msg(GLOBALS.focus,'right'); 

function nudge_left_Callback(hObject, eventdata, handles)
	global GLOBALS; 
	set_status('nudge_left'); 	
	send_nudge_msg(GLOBALS.focus,'left'); 


function lookat(id,theta)
	global GLOBALS; 
	GLOBALS.req_angles(id) = theta; 
	set_status('lookat');
	updateGui; 

function set_label(label)
	global GLOBALS; 
	GLOBALS.current_label = label; 
	set_status(strcat('label:',label)); 	
	updateGui;  

function send_nudge_msg(id,status)
	name = sprintf('robot%d/Nudge_Msg',id); 
	msg.status = status; %Left/Right
	send_message_to_gcs(name,msg); 

function send_ooi_msg(id,ser,x,y,type)
	name = 'OOI_Msg'; 
	msg.ser = ser;
	msg.x = x; %in UTM coordinates (m)
	msg.y = y; %in UTM coordinates (m)
	msg.type = type;
	msg.id = id;
	send_message_to_gcs(name,msg); 

function send_ooi_done_msg(ser,status)
	name = 'OOI_Done_Msg'
	msg.status = status; %complete, canceled
	msg.ser = ser; 
	send_message_to_gcs(name,msg); 

function send_lazer_msg(id,status)
	name = sprintf('robot%d/Laser_Msg',id); 
	msg.status = status; %on, off, up, down
	send_message_to_gcs(name,msg); 

function send_look_msg(id,theta,phi,type);
	name = sprintf('robot%d/Look_Msg',id); 
	msg.theta = theta;  
	msg.phi = phi; 
	msg.type = type; %'look', 'track', 'done'
	send_message_to_gcs(name,msg); 

function send_message_to_gcs(name,msg);
	'NOT SENDING MESSAGES TODAY!!!'
	msg 
	return
	global VISION_IPC 
	VISION_IPC('define',name); 
	VISION_IPC('publish',name,serialize(msg)); 
