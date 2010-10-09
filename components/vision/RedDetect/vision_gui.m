function varargout = vision_gui(varargin)
% VISION_GUI M-file for vision_gui.fig
%      VISION_GUI, by itself, creates a new VISION_GUI or raises the existing
%      singleton*.
%
%      H = VISION_GUI returns the handle to a new VISION_GUI or the handle to
%      the existing singleton*.
%
%      VISION_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in VISION_GUI.M with the given input arguments.
%
%      VISION_GUI('Property','Value',...) creates a new VISION_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before vision_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to vision_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help vision_gui

% Last Modified by GUIDE v2.5 08-Oct-2010 23:35:04

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @vision_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @vision_gui_OutputFcn, ...
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


% --- Executes just before vision_gui is made visible.
function vision_gui_OpeningFcn(hObject, eventdata, handles, varargin)
	handles.output = hObject;
	guidata(hObject, handles);
	setup_global_vars(hObject); 
	updateGui; 

function updateGui
	global GLOBALS IMAGES; 
	handles = guidata(GLOBALS.vision_gui);
	imagesc(uint8(cat(3,0,255,0)),'Parent',handles.(sprintf('ind%d',GLOBALS.focus))); 
	imagesc(uint8(cat(3,0,0,255)),'Parent',handles.(sprintf('ind%d',mod(GLOBALS.focus,2)+1)));  
	axis(handles.ind1,'off')
	axis(handles.ind2,'off')
	
	%Front Focus	
%	focus_h = draw_cands_on_image(handles.front1,image.front_stats,image.front); 
%	set(focus_h,'ButtonDownFcn',{@focus_ButtonDownFcn,handles.front1});
%	mid = round(size(image.front,2)/2);
%	step = size(image.front,1)/15; 
%	for txt = 1:15
%		text(mid,round(step*txt),sprintf('%.1f',image.scanV(txt)),'Parent',handles.front1,'FontSize',16); 
%	end	  
	
	%Omni Focus
	%omni_h = imagesc(image.omni,'Parent',handles.flat_focus); daspect(handles.flat_focus,[1 1 1]); 
	%set(omni_h,'ButtonDownFcn',{@omni_ButtonDownFcn,GLOBALS.focus,handles.flat_focus});
	%draw_center_line(handles.flat_focus,image.omni,image.front_angle,GLOBALS.req_angles(GLOBALS.focus)); 
	for box = 1:8
		image = IMAGES(GLOBALS.bids(box));
		cname = sprintf('cand%d',box);
		oname = sprintf('omni%d',box);
		if box < 3
			fname = sprintf('front%d',box);
			draw_cands_on_image(handles.(fname),image.front_stats,image.front); 
			axis(handles.(fname),'off')
			for sc = 1:3
				scname = sprintf('%s_%d',cname,sc); 
				imagesc(image.front_cands{sc},'Parent',handles.(scname)); 
				daspect(handles.(scname),[1 1 1]); 
				axis(handles.(scname),'off'); 
			end 
		else
			for sc = 1:3
				scname = sprintf('%s_%d',cname,sc); 
				imagesc(image.omni_cands{sc},'Parent',handles.(scname)); 
				daspect(handles.(scname),[1 1 1]); 
				axis(handles.(scname),'off'); 
			end 
		end
		img = draw_cands_on_image(handles.(oname),image.omni_stats,image.omni);
		text(30,20,sprintf('%d',GLOBALS.bids(box)),'Parent',handles.(oname),'FontSize',30,'BackgroundColor','c'); 
		axis(handles.(oname),'off')
	end
%	bb = GLOBALS.current_bb;
%	image = IMAGES(GLOBALS.focus);
% 	Something is wrong with bb!!!!
%	imagesc(image.front(bb(1):bb(2),bb(3):bb(4),:),'Parent',handles.cand5_focus);
%	daspect(handles.cand5_focus,[1 1 1]);  
%	axis(handles.cand5_focus,'off')
	%line([bb(3),bb(4)],[bb(1),bb(1)],'Color','c','LineWidth',2,'Parent',handles.front1);
	%line([bb(3),bb(4)],[bb(2),bb(2)],'Color','c','LineWidth',2,'Parent',handles.front1);
	%line([bb(3),bb(3)],[bb(1),bb(2)],'Color','c','LineWidth',2,'Parent',handles.front1);
	%line([bb(4),bb(4)],[bb(1),bb(2)],'Color','c','LineWidth',2,'Parent',handles.front1);
	
%	set(handles.current_label,'String',strcat('<--',GLOBALS.current_label)); 
	
%	axis(handles.front1,'off')

% --- Outputs from this function are returned to the command line.
function varargout = vision_gui_OutputFcn(hObject, eventdata, handles) 
	varargout{1} = handles.output;

function focus_ButtonDownFcn(hObject, eventdata, axeh)
	global IMAGES GLOBALS 
	cp = get(axeh,'CurrentPoint');
	x = cp(1,1);
	y = cp(1,2);  
	[x,y]
	GLOBALS.current_bb
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
		GLOBALS.current_bb = [GLOBALS.current_bb]; 
	elseif mod(numel(GLOBALS.current_bb),4) == 0
		GLOBALS.current_bb = [GLOBALS.current_bb,round([x,y])];
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
	button_handler(chr,'vision'); 

function set_status(msg)
	global GLOBALS;
	h = guidata(GLOBALS.vision_gui);
	set(h.status_text,'String',msg)


function setup_global_vars(vision_gui)
	global GLOBALS IMAGES;
	GLOBALS.vision_gui = vision_gui; 
	GLOBALS.focus = 1;  
	GLOBALS.req_angles = -ones(1,9);
	GLOBALS.current_bb = [1,1,1,1]; 
	GLOBALS.current_label = '?'; 
	GLOBALS.current_ser = 1;
	GLOBALS.last_look = []; 
	GLOBALS.last_click = [1,1]; 
	GLOBALS.bids = [1 2 3 4 5 6 7 8 9];  
	vision_fns.updateGui		   = @updateGui;  
	vision_fns.set_status		   = @set_status;  
	vision_fns.lookat_Callback         = @lookat_Callback;
	vision_fns.car_Callback            = @car_Callback;
	vision_fns.door_Callback           = @door_Callback;
	vision_fns.renounce_ooi_Callback   = @renounce_ooi_Callback;
	vision_fns.announce_ooi_Callback   = @announce_ooi_Callback;
	vision_fns.neutralized_Callback    = @neutralized_Callback;
	vision_fns.explore_Callback        = @explore_Callback;
	vision_fns.mobile_ooi_Callback     = @mobile_ooi_Callback;
	vision_fns.lazer_up_Callback       = @lazer_up_Callback;
	vision_fns.lazer_on_Callback       = @lazer_on_Callback;
	vision_fns.lazer_down_Callback     = @lazer_down_Callback;
	vision_fns.lazer_off_Callback      = @lazer_off_Callback;
	vision_fns.red_ooi_Callback        = @red_ooi_Callback;       
	vision_fns.yellow_ooi_Callback     = @yellow_ooi_Callback;
	vision_fns.still_mobile_Callback   = @still_mobile_Callback;
	vision_fns.nudge_right_Callback    = @nudge_right_Callback;
	vision_fns.nudge_left_Callback     = @nudge_left_Callback; 
	vision_fns.lookat	           = @lookat; 
	GLOBALS.vision_fns = vision_fns; 
	null_front = null_image(320,240); 	
	null_omni  = null_image(775,155);
	null_cand  = null_image(150,150);
	null_cands = {}; 
	null_pose.x = 0;  
	null_pose.y = 0;  
	null_pose.yaw = 0;  
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
	    IMAGES(id).scanH = [];
	    IMAGES(id).scanV = zeros(15,1); ;
	    IMAGES(id).omni_cands = null_cands;
	    IMAGES(id).front_cands = null_cands;
	    IMAGES(id).omni_stats = null_stats;
	    IMAGES(id).front_stats = null_stats;
	    IMAGES(id).pose = null_pose;
	end
	GLOBALS.null_cand = null_cand; 

%------------------------------------------------------------------------------------------
	
function switch_cand5_Callback(hObject, eventdata, handles)
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

function renounce_ooi_Callback(hObject, eventdata, handles)
	global GLOBALS; 
	set_status('renounced label'); 	
	send_ooi_done_msg(GLOBALS.current_ser-1,'canceled')

function announce_ooi_Callback(hObject, eventdata, handles)
	global GLOBALS IMAGES;  
	set_status('announced label'); 	
	x = IMAGES(GLOBALS.focus).pose.x; 
	y = IMAGES(GLOBALS.focus).pose.y;
	yaw = IMAGES(GLOBALS.focus).pose.yaw;
	servo_yaw = IMAGES(GLOBALS.focus).front_angle; ;
	distance = mean(IMAGES(GLOBALS.focus).scanV(7:9));  
	x = x + distance * cos(yaw + servo_yaw);  
	y = y + distance * sin(yaw + servo_yaw);  
	send_ooi_msg(GLOBALS.focus,GLOBALS.current_ser,x,y,GLOBALS.current_label)
	GLOBALS.current_ser = GLOBALS.current_ser + 1;  
	send_look_msg(GLOBALS.focus,0,0,'done');

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
	set_status('nudge right'); 	
	msg = GLOBALS.last_look;  
	if isempty(msg)
		return; 
	end
	msg.theta = mod(msg.theta - pi/180,2*pi); 
	send_look_msg(GLOBALS.focus,msg.theta,msg.phi,msg.type);  

function nudge_left_Callback(hObject, eventdata, handles)
	global GLOBALS;
	set_status('nudge left'); 	
	msg = GLOBALS.last_look;  
	if isempty(msg)
		return; 
	end
	msg.theta = mod(msg.theta + pi/180,2*pi); 
	send_look_msg(GLOBALS.focus,msg.theta,msg.phi,msg.type);  

function neutralized_Callback(hObject, eventdata, handles)
	set_status('neutralized target'); 	

function explore_Callback(hObject, eventdata, handles)
	set_status('return to exploring'); 	

%------------------------------------------------------------------------------------------

function lookat(id,theta,type)
	if nargin < 3
		type = 'look';
	end
	global GLOBALS IMAGES; 
	GLOBALS.req_angles(id) = theta;
	if isempty(IMAGES(id).pose)
		abs_angle = 0; 
	else 
		abs_angle = IMAGES(id).pose.yaw;   
	end
	set_status('lookat');
	updateGui; 
	phi = 0; 
	[theta,abs_angle,theta+abs_angle,mod(theta-abs_angle,2*pi)] 
	send_look_msg(id,mod(theta+abs_angle,2*pi),phi,type); 

function set_label(label)
	global GLOBALS; 
	GLOBALS.current_label = label; 
	set_status(strcat('label:',label)); 	
	updateGui;  

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
	global GLOBALS ROBOTS; 
	name = sprintf('robot%d/Look_Msg',id); 
	msg.theta = theta;  
	msg.phi = phi; 
	msg.type = type; %'look', 'track', 'done'
	GLOBALS.last_look = msg;
	ROBOTS(id).ipcAPI('define',name);  
	ROBOTS(id).ipcAPI('publish',name,serialize(msg));  
	
function send_message_to_gcs(name,msg);
	'NOT SENDING MESSAGES TODAY!!!'
	msg 
	return
	global VISION_IPC 
	VISION_IPC('define',name); 
	VISION_IPC('publish',name,serialize(msg)); 




