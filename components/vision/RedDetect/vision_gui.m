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

% Last Modified by GUIDE v2.5 12-Oct-2010 18:39:05

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
	setup_images(hObject);   
	updateGui;

function setup_images(gui)
	global GLOBALS IMAGES; 
	handles = guidata(gui);
	handles.ih_ind1 = imagesc(uint8(cat(3,255,0,0)),'Parent',handles.ind1); 
	handles.ih_ind2 = imagesc(uint8(cat(3,255,0,0)),'Parent',handles.ind2); 
	axis(handles.ind1,'off')
	axis(handles.ind2,'off')
	for t = 1:5
		history = GLOBALS.history(t); 
		fname = sprintf('hist_front%d',t); 
		oname = sprintf('hist_omni%d',t);
		ooiname = sprintf('hist_ooi%d',t); 
		handles.ih_hist_front(t) = imagesc(history.front{1},'Parent',handles.(fname));
		handles.ih_hist_omni(t)  = imagesc(history.omni{1},'Parent',handles.(oname));
		handles.ih_hist_ooi(t) = imagesc(history.ooi.front,'Parent',handles.(ooiname)); ;
		axis(handles.(fname),'off'); 
		axis(handles.(oname),'off'); 
		axis(handles.(ooiname),'off'); 
	end
		
	for box = 1:8
		image = IMAGES(GLOBALS.bids(box));
		cname = sprintf('cand%d',box);
		oname = sprintf('omni%d',box);
		ih_oname = ['ih_',oname];
		if box < 3
			fname = sprintf('front%d',box);
			ih_fname = ['ih_',fname]; 
			handles.(ih_fname) = imagesc(image.front,'Parent',handles.(fname)); 
			daspect(handles.(fname),[1 1 1]); 
			axis(handles.(fname),'off'); 
			set(handles.(ih_fname),'ButtonDownFcn',{@focus_ButtonDownFcn,[handles.(fname),box]});
		end
		handles.(ih_oname) = imagesc(image.omni,'Parent',handles.(oname)); 
		set(handles.(ih_oname),'ButtonDownFcn',{@omni_ButtonDownFcn,[handles.(oname),box]});
		axis(handles.(oname),'off')
	end
	guidata(gui, handles);


function updateGui(id)
	global GLOBALS IMAGES; 
	if nargin == 1
		for t = 5:-1:2
			GLOBALS.history(t).front(id) = GLOBALS.history(t-1).front(id); 
			GLOBALS.history(t).omni(id) = GLOBALS.history(t-1).omni(id); 
		end
		GLOBALS.history(1).front(id) = {IMAGES(id).front}; 
		GLOBALS.history(1).omni(id)  = {IMAGES(id).omni}; 
	end
	handles = guidata(GLOBALS.vision_gui);
	set(handles.(sprintf('ih_ind%d',GLOBALS.focus)),'CData',uint8(cat(3,0,255,0)));
	set(handles.(sprintf('ih_ind%d',mod(GLOBALS.focus,2)+1)),'CData',uint8(cat(3,0,0,255)));
	
	for t = 1:5
		history = GLOBALS.history(t); 
		set(handles.ih_hist_front(t),'CData',history.front{1});
		set(handles.ih_hist_omni(t),'CData',history.omni{1});
		set(handles.ih_hist_ooi(t),'CData',history.ooi(1).front);
	end

	for box = 1:8
		image = IMAGES(GLOBALS.bids(box));
		cname = sprintf('cand%d',box);
		oname = sprintf('omni%d',box);
		ih_oname = ['ih_',oname];
		if box < 3
			fname = sprintf('front%d',box);
			ih_fname = ['ih_',fname];
			draw_cands_on_image(handles.(ih_fname),handles.(fname),image.front_stats,image.front);
			if GLOBALS.bids(box) == GLOBALS.current_bb_id
				draw_box_on_axes(GLOBALS.current_bb,'c',handles.(fname)); 
			end
			draw_range(image.scanH,image.scanV,image.front,handles.(fname));  
			for sc = 1:3
				scname = sprintf('candf%d_%d',box,sc); 
				cand_h = imagesc(image.front_cands{sc},'Parent',handles.(scname)); 
				daspect(handles.(scname),[1 1 1]); 
				axis(handles.(scname),'off'); 
				bb = image.front_stats(sc,2:end);
				[dist,vsd,hsd] = get_dist_by_bb([],bb,[],[]); 
				text(1,10,sprintf('%.1fm',dist),'Parent',handles.(scname),'FontSize',16,'BackgroundColor','y'); 
				set(cand_h,'ButtonDownFcn',{@cand_ButtonDownFcn,[sc,box,GLOBALS.bids(box)]});
			end 
		end
		for sc = 1:3
			scname = sprintf('%s_%d',cname,sc); 
			imagesc(image.omni_cands{sc},'Parent',handles.(scname)); 
			daspect(handles.(scname),[1 1 1]); 
			axis(handles.(scname),'off'); 
		end 
		draw_cands_on_image(handles.(ih_oname),handles.(oname),image.omni_stats,image.omni);
		draw_center_line(handles.(oname),image.omni,image.front_angle,GLOBALS.req_angles(GLOBALS.bids(box))); 
		%Omni Focus
		text(30,20,sprintf('%d',GLOBALS.bids(box)),'Parent',handles.(oname),'FontSize',30,'BackgroundColor','c'); 
	end
	if ~isempty(GLOBALS.current_bb)
		bb = GLOBALS.current_bb; 
		image = IMAGES(GLOBALS.bids(GLOBALS.focus)); 
		[imgd,vsd,hsd] = get_dist_by_bb(image.front,bb,image.scanV,image.scanH); 
		auto = 0; 
		selected = get(handles.dist_source,'SelectedObject'); 
		selected = get(selected,'String'); 
		switch(selected)
		case 'IMG'
			GLOBALS.current_distance = imgd; 
		case 'HS'
			GLOBALS.current_distance = hsd; 
		case 'VS'
			GLOBALS.current_distance = vsd; 
		case 'AUTO'
			GLOBALS.current_distance = imgd; 
		end
		set(handles.dists_display,'String',sprintf('%.1f | %.1f | %.1f | *%.1f*',vsd,hsd,imgd,GLOBALS.current_distance));    	
	end
	if GLOBALS.focus == 1	
		set(handles.current_label,'String',strcat('<--',GLOBALS.current_label)); 
	else 
		set(handles.current_label,'String',strcat(GLOBALS.current_label,'-->')); 
	end
	drawnow
% --- Outputs from this function are returned to the command line.
function varargout = vision_gui_OutputFcn(hObject, eventdata, handles) 
	varargout{1} = handles.output;

function focus_ButtonDownFcn(hObject, eventdata, data)
	global IMAGES GLOBALS 
	axeh = data(1);
	focus = data(2); 
	id = GLOBALS.bids(focus);  
	GLOBALS.focus = focus;  
	cp = get(axeh,'CurrentPoint');
	x = cp(1,1);
	y = cp(1,2);  
	if isempty(GLOBALS.last_click) | GLOBALS.current_bb_id ~= id
		GLOBALS.last_click = [x,y];
		GLOBALS.current_bb = [];  
	else
		xp = GLOBALS.last_click(1); 
		yp = GLOBALS.last_click(2); 
		if abs(xp-x) < 10 & abs(yp-y) < 10
			GLOBALS.current_bb = [];
		else
			GLOBALS.current_bb = round([yp,y,xp,x]);
		end
	GLOBALS.last_click = [];   
	end
	GLOBALS.current_bb_id = id; 
	updateGui; 

function cand_ButtonDownFcn(hObject, eventdata, data)
	global IMAGES GLOBALS 
	cand = data(1);
	focus = data(2);  
	id = data(3); 
	GLOBALS.focus = focus;  
	GLOBALS.current_bb_id = id; 
	GLOBALS.current_bb = IMAGES(id).front_stats(cand,2:end);
	updateGui;   
	GLOBALS.focus = focus;  

function omni_ButtonDownFcn(hObject, eventdata, data)
	global IMAGES GLOBALS;
	axeh = data(1);
	box = data(2);  
	id = GLOBALS.bids(box);  
	if box < 3
		GLOBALS.focus = box; 
	else
		set_focus(id); 
	end
	cp = get(axeh,'CurrentPoint');
	x = cp(1,1);
	y = cp(1,2);  
	[x,y]
	theta = pixel_to_angle(IMAGES(id).omni,x) 
	lookat(id,theta,0,'look'); 

%All buttons
function figure1_KeyPressFcn(hObject, eventdata, handles)
	chr = get(gcf,'CurrentCharacter'); 
	if strcmp(chr,'')
		'Empty char'
		return
	end 
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
	global GLOBALS IMAGES
	GLOBALS.vision_gui = vision_gui; 
	GLOBALS.focus = 1;  
	GLOBALS.req_angles = -ones(1,9);
	GLOBALS.current_bb = []; 
	GLOBALS.current_bb_id = []; 
	GLOBALS.current_label = '?'; 
	GLOBALS.current_ser = 1;
	GLOBALS.current_distance = 0;
	GLOBALS.last_look = []; 
	GLOBALS.last_click = []; 
	GLOBALS.bids = [1 2 3 4 5 6 7 8 9];  
	GLOBALS.track_mode = false; 
	vision_fns.updateGui		   = @updateGui;  
	vision_fns.set_status		   = @set_status;  
	vision_fns.lookat_Callback         = @lookat_Callback;
	vision_fns.car_Callback            = @car_Callback;
	vision_fns.door_Callback           = @door_Callback;
	vision_fns.renounce_ooi_Callback   = @renounce_ooi_Callback;
	vision_fns.cand_Callback	  =  @cand_ButtonDownFcn;
	vision_fns.announce_ooi_Callback   = @announce_ooi_Callback;
	vision_fns.track_Callback   	   = @track_Callback;
	vision_fns.lookat_Callback   	   = @lookat_Callback;
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
	vision_fns.set_focus	           = @set_focus; 
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
	    IMAGES(id).type = 'vision'; 
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
	for t = 1:5
		history(t).front = {IMAGES.front};  
		history(t).omni = {IMAGES.omni};  
		history(t).ooi.front = null_front;
		history(t).ooi.id = 0; 
	end 
	GLOBALS.null_cand = null_cand; 
	GLOBALS.history = history; 
%------------------------------------------------------------------------------------------

function set_focus(new_fr)
	global GLOBALS;
	new_fr_old_box = find(GLOBALS.bids == new_fr);  
	old_fr = GLOBALS.bids(GLOBALS.focus);  
	GLOBALS.bids(GLOBALS.focus) = new_fr; 
	GLOBALS.bids(new_fr_old_box) = old_fr; 
	GLOBALS.bids(3:8) = sort(GLOBALS.bids(3:8));  
	GLOBALS.vision_fns.set_status(sprintf('Gave focus to: %d',new_fr)); 
	
	 

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
	send_ooi_done_msg(GLOBALS.current_ser-1,'cancel')

function announce_ooi_Callback(hObject, eventdata, handles)
	global GLOBALS IMAGES;  
	set_status('announced label'); 	
	id = GLOBALS.bids(GLOBALS.focus); 
	x = IMAGES(id).pose.x; 
	y = IMAGES(id).pose.y;
	yaw = IMAGES(id).pose.yaw;
	servo_yaw = IMAGES(id).front_angle; ;
	distance = GLOBALS.current_distance;   
	x = x + distance * cos(yaw + servo_yaw);  
	y = y + distance * sin(yaw + servo_yaw);  
	send_ooi_msg(id,GLOBALS.current_ser,x,y,GLOBALS.current_label)
	GLOBALS.current_ser = GLOBALS.current_ser + 1;  
	send_look_msg(id,0,0,'done');

function lazer_up_Callback(hObject, eventdata, handles)
	global GLOBALS; 
	set_status('lazer up'); 	
	id = GLOBALS.bids(GLOBALS.focus); 
	send_lazer_msg(id,'up'); 

function lazer_down_Callback(hObject, eventdata, handles)
	global GLOBALS; 
	set_status('lazer down'); 	
	id = GLOBALS.bids(GLOBALS.focus); 
	send_lazer_msg(id,'down'); 

function lazer_on_Callback(hObject, eventdata, handles)
	global GLOBALS; 
	set_status('lazer on'); 	
	id = GLOBALS.bids(GLOBALS.focus); 
	send_lazer_msg(id,'on'); 

function lazer_off_Callback(hObject, eventdata, handles)
	global GLOBALS; 
	set_status('lazer off'); 	
	id = GLOBALS.bids(GLOBALS.focus); 
	send_lazer_msg(id,'off'); 

function nudge_right_Callback(hObject, eventdata, handles)
	global GLOBALS;
	set_status('nudge right'); 	
	msg = GLOBALS.last_look;  
	if isempty(msg)
		return; 
	end
	msg.theta = mod(msg.theta - pi/180,2*pi); 
	id = GLOBALS.bids(GLOBALS.focus); 
	send_look_msg(id,msg.theta,msg.phi,msg.type);  

function nudge_left_Callback(hObject, eventdata, handles)
	global GLOBALS;
	set_status('nudge left'); 	
	msg = GLOBALS.last_look;  
	if isempty(msg)
		return; 
	end
	msg.theta = mod(msg.theta + pi/180,2*pi); 
	id = GLOBALS.bids(GLOBALS.focus); 
	send_look_msg(id,msg.theta,msg.phi,msg.type);  

function neutralized_Callback(hObject, eventdata, handles)
	global GLOBALS;
	set_status('neutralized target'); 	
	send_ooi_done_msg(GLOBALS.current_ser-1,'complete'); 

function explore_Callback(hObject, eventdata, handles)
	global GLOBALS;
	set_status('return to exploring'); 	
	id = GLOBALS.bids(GLOBALS.focus); 
	send_look_msg(id,0,0,'done');

%------------------------------------------------------------------------------------------

function lookat(id,theta,phi,type)
	global GLOBALS IMAGES; 
	GLOBALS.req_angles(id) = theta;
	if isempty(IMAGES(id).pose)
		abs_angle = 0; 
	else 
		abs_angle = IMAGES(id).pose.yaw;   
	end
	set_status(type);
	updateGui; 
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
	msg.status = status; %complete, cancel
	msg.ser = ser; 
	send_message_to_gcs(name,msg); 

function send_lazer_msg(id,status)
	name = sprintf('Robot%d/Laser_Msg',id); 
	msg.status = status; %on, off, up, down
	send_message_to_gcs(name,msg); 
	msg

function send_look_msg(id,theta,phi,type);
	global GLOBALS ROBOTS; 
	name = sprintf('Robot%d/Look_Msg',id); 
	msg.theta = theta;  
	msg.phi = phi; 
	msg.type = type; %'look', 'track', 'done'
	msg.distance = GLOBALS.current_distance; 
	GLOBALS.last_look = msg;
	global NOSEND
	if ~isempty(NOSEND)
		'NOT SENDING MESSAGES TODAY!!!'
		msg 
		return
	end
	msg
	ROBOTS(id).ipcAPI('define',name);  
	ROBOTS(id).ipcAPI('publish',name,serialize(msg));  
	
function send_message_to_gcs(name,msg);
	global NOSEND
	if ~isempty(NOSEND)
		'NOT SENDING MESSAGES TODAY!!!'
		msg 
		return
	end
	name
	msg
	global VISION_IPC 
	VISION_IPC('define',name); 
	VISION_IPC('publish',name,serialize(msg)); 


function track_Callback(hObject, eventdata, handles)
	global GLOBALS IMAGES;  
	if isempty(GLOBALS.current_bb)
		return
	end
	id = GLOBALS.bids(GLOBALS.focus); 
	x = mean(GLOBALS.current_bb(3:4)); 
	y = mean(GLOBALS.current_bb(1:2)); 
	servo_yaw = IMAGES(id).front_angle; 
	[theta,phi] = front_pixel_to_angle(IMAGES(id).front,x,y); 
	theta = servo_yaw + theta; 
	lookat(id,theta,phi,'track'); 

function lookat_Callback(hObject, eventdata, handles)
	global GLOBALS IMAGES;  
	if isempty(GLOBALS.current_bb)
		return
	end
	id = GLOBALS.bids(GLOBALS.focus); 
	x = mean(GLOBALS.current_bb(3:4)); 
	y = mean(GLOBALS.current_bb(1:2)); 
	servo_yaw = IMAGES(id).front_angle; 
	[theta,phi] = front_pixel_to_angle(IMAGES(id).front,x,y); 
	theta = servo_yaw + theta; 
	lookat(id,theta,phi,'look'); 


function stop_Callback(hObject, eventdata, handles)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
function slider1_Callback(hObject, eventdata, handles)
function slider1_CreateFcn(hObject, eventdata, handles)
function slider2_Callback(hObject, eventdata, handles)
function slider2_CreateFcn(hObject, eventdata, handles)
function slider3_Callback(hObject, eventdata, handles)
function slider3_CreateFcn(hObject, eventdata, handles)
function slider4_Callback(hObject, eventdata, handles)
function slider4_CreateFcn(hObject, eventdata, handles)
function slider5_Callback(hObject, eventdata, handles)
function slider5_CreateFcn(hObject, eventdata, handles)
function slider6_Callback(hObject, eventdata, handles)
function slider6_CreateFcn(hObject, eventdata, handles)
