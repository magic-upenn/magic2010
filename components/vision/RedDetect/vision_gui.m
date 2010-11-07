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

% Last Modified by GUIDE v2.5 07-Nov-2010 07:25:39

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
	setup_imgs(hObject);   
	msg.cam = 2; 
	msg.otime = 0.5;
	msg.ftime = 0.5;
	send_cam_param_msg(1,msg)
	send_cam_param_msg(2,msg)
	msg.ftime = 2; 
	for i = 3:9
		send_cam_param_msg(i,msg)
	end

function setup_imgs(gui)
	global GLOBALS IMAGES; 
	handles = guidata(gui);
	handles.ih_ind1 = image(uint8(cat(3,255,0,0)),'Parent',handles.ind1); 
	set(handles.ih_ind1,'ButtonDownFcn',{@mouse_ButtonDownFcn,{'ind',handles.ind1,1}});
	set(handles.ih_ind1,'Interruptible','off');
	handles.ih_ind2 = image(uint8(cat(3,255,0,0)),'Parent',handles.ind2); 
	set(handles.ih_ind2,'ButtonDownFcn',{@mouse_ButtonDownFcn,{'ind',handles.ind2,2}});
	set(handles.ih_ind2,'Interruptible','off');
	axis(handles.ind1,'off')
	axis(handles.ind2,'off')
	for t = 1:5
		history = GLOBALS.history(t); 
		fname = sprintf('hist_front%d',t); 
		oname = sprintf('hist_omni%d',t);
		ooiname = sprintf('hist_ooi%d',t); 
		handles.ih_hist_front(t) = image(history.front{1},'Parent',handles.(fname));
		handles.ih_hist_omni(t)  = image(history.omni{1},'Parent',handles.(oname));
		handles.ih_hist_ooi(t) = image(history.ooi.front,'Parent',handles.(ooiname)); ;
		axis(handles.(fname),'off'); 
		axis(handles.(oname),'off'); 
		axis(handles.(ooiname),'off'); 
	end
		
	for box = 1:9
		img = IMAGES(GLOBALS.bids(box));
		cname = sprintf('cand%d',box);
		oname = sprintf('omni%d',box);
		ih_oname = ['ih_',oname];
		if box < 3
			fname = sprintf('front%d',box);
			ih_fname = ['ih_',fname]; 
			handles.(ih_fname) = image(img.front,'Parent',handles.(fname)); 
			daspect(handles.(fname),[1 1 1]); 
			axis(handles.(fname),'off'); 
			set(handles.(ih_fname),'ButtonDownFcn',{@mouse_ButtonDownFcn,{'front',handles.(fname),box}});
			set(handles.(ih_fname),'Interruptible','off');
		end
		handles.(ih_oname) = image(img.omni,'Parent',handles.(oname)); 
		set(handles.(ih_oname),'ButtonDownFcn',{@mouse_ButtonDownFcn,{'omni',handles.(oname),box}});
		set(handles.(ih_oname),'Interruptible','off');
	axis(handles.(oname),'off')
		end
		guidata(gui, handles);

function updateHistory(id)
	%Updates the history on message receipt from robot 
	global GLOBALS IMAGES; 
	if toc(GLOBALS.last_update_tics(id)) < 1
		return
	end
	GLOBALS.last_update_tics(id) = tic; 
	for t = 5:-1:2
	GLOBALS.history(t).front(id) = GLOBALS.history(t-1).front(id); 
	GLOBALS.history(t).omni(id) = GLOBALS.history(t-1).omni(id); 
	end
	GLOBALS.history(1).front(id) = {IMAGES(id).front}; 
	GLOBALS.history(1).omni(id)  = {IMAGES(id).omni};

function updateHistoryFocus
global GLOBALS IMAGES; 
handles = guidata(GLOBALS.vision_gui);
%Updates the history for the currently focused robot	
id = GLOBALS.bids(GLOBALS.focus);
for t = 1:5
history = GLOBALS.history(t); 
set(handles.ih_hist_front(t),'CData',history.front{id});
set(handles.ih_hist_omni(t),'CData',history.omni{id});
end
drawnow 

function updateBox(box)
	global GLOBALS IMAGES; 
	handles = guidata(GLOBALS.vision_gui);
	img = IMAGES(GLOBALS.bids(box));
	if box < 3
	updateFrontFocused(box); 	
	end
	updateOmni(box);

function updateOOIHistory(id,ser)
	global GLOBALS IMAGES;
	handles = guidata(GLOBALS.vision_gui);
	ooi.id = id; 
	ooi.ser = ser; 
	ooi.front = IMAGES(id).front; 
	[GLOBALS.history(2:5).ooi] = GLOBALS.history(1:4).ooi;
	GLOBALS.history(1).ooi = ooi; 
	for t = 1:5
		set(handles.ih_hist_ooi(t),'CData',GLOBALS.history(t).ooi.front);
		%image(GLOBALS.history(t).ooi.front)
	end
	try
		imwrite(ooi.front,sprintf('~/cands/robot_%d_ser_%d.png',id,ser));
	catch
		'Unable to write cand image!!!'
	end
	oois = [GLOBALS.history.ooi];
	ids = [oois.id];
	sers = [oois.ser];
	last_five = [ids;sers];
	current_ser = ser + 1; 
	try
		save('~/cands/last_five.mat','last_five'); 
		save('~/cands/current_ser.mat','current_ser'); 
	catch
		'Unable to save cand hist!!!'
	end


function updateOmni(box)
	global GLOBALS IMAGES; 
	handles = guidata(GLOBALS.vision_gui);
	img = IMAGES(GLOBALS.bids(box));
	cname = sprintf('cand%d',box);
	oname = sprintf('omni%d',box);
	delete(findobj(get(handles.(oname),'Children'),'Type','Text')); 
	ih_oname = ['ih_',oname];
	id = GLOBALS.bids(box); 
	for sc = 1:3
	scname = sprintf('%s_%d',cname,sc); 
	cand_h = image(img.omni_cands{sc},'Parent',handles.(scname)); 
	daspect(handles.(scname),[1 1 1]); 
	axis(handles.(scname),'off'); 
	set(cand_h,'ButtonDownFcn',{@mouse_ButtonDownFcn,{'omni_cand',handles.(scname),[box,sc]}});
	set(cand_h,'Interruptible','off');
	end 
	draw_cands_on_image(handles.(ih_oname),handles.(oname),img.omni_stats,img.omni);
	draw_center_line(handles.(oname),img.omni,img.front_angle,GLOBALS.req_angles(GLOBALS.bids(box))); 
	%Omni Focus
	colors = 'ck';
	speed_colors = 'ryg';
	oh = GLOBALS.heartbeat(id);
	nh = mod(GLOBALS.heartbeat(id),2) + 1;
	GLOBALS.heartbeat(id) = nh;
	text(231,95,'\_','Parent',handles.(oname),...
			'FontSize',21,'Color',colors(oh), ...
			'BackgroundColor',colors(nh));
	text(230,95,sprintf('%d',GLOBALS.bids(box)),'Parent',handles.(oname),...
			'FontSize',28,'Color',colors(oh)); %, ...
%			'BackgroundColor',colors(nh));
 
	text(10,20,'.','Parent',handles.(oname),...
			'FontSize',10,'Color','k',...
			'BackgroundColor',speed_colors(GLOBALS.speeds(id))); 


	function updateLabel
	global GLOBALS IMAGES; 
	handles = guidata(GLOBALS.vision_gui);
	if GLOBALS.focus == 1	
	set(handles.current_label,'String',strcat('<--',GLOBALS.current_label)); 
	else 
	set(handles.current_label,'String',strcat(GLOBALS.current_label,'-->')); 
	end

function updateFrontFocused(box)
	%Updates the display for one of the two focused robots 
	global GLOBALS IMAGES; 
	updateBB;
	if box == GLOBALS.focus
	updateHistoryFocus;
	end
	handles = guidata(GLOBALS.vision_gui);
	img = IMAGES(GLOBALS.bids(box));
	fname = sprintf('front%d',box);
	ih_fname = ['ih_',fname];
	set(handles.(sprintf('ih_ind%d',GLOBALS.focus)),'CData',uint8(cat(3,0,255,0)));
	set(handles.(sprintf('ih_ind%d',mod(GLOBALS.focus,2)+1)),'CData',uint8(cat(3,0,0,255)));
	draw_cands_on_image(handles.(ih_fname),handles.(fname),img.front_stats,img.front);
	delete(findobj(get(handles.(fname),'Children'),'Type','Text')); 
	if GLOBALS.bids(box) == GLOBALS.current_bb_id
	draw_box_on_axes(GLOBALS.current_bb,'c',handles.(fname)); 
	end
	draw_range(img.rangeH,img.rangeV,img.front,handles.(fname));  
	for sc = 1:3
	scname = sprintf('candf%d_%d',box,sc); 
	cand_h = image(img.front_cands{sc},'Parent',handles.(scname)); 
	daspect(handles.(scname),[1 1 1]); 
	axis(handles.(scname),'off'); 
	bb = img.front_stats(sc,2:end);
	[dist,vsd,hsd] = get_dist_by_bb([],bb,[],[]); 
	text(1,10,sprintf('%.1fm',dist),'Parent',handles.(scname),'FontSize',16,'BackgroundColor','y','HitTest','off'); 
	set(cand_h,'ButtonDownFcn',{@mouse_ButtonDownFcn,{'front_cand',handles.(scname),[box,sc]}});
	set(cand_h,'Interruptible','off');
	end 
	updateLabel; 


function updateBB
	global GLOBALS IMAGES; 
	handles = guidata(GLOBALS.vision_gui);
	if ~isempty(GLOBALS.current_bb)
		bb = GLOBALS.current_bb; 
		img = IMAGES(GLOBALS.bids(GLOBALS.focus)); 
		[imgd,vsd,hsd] = get_dist_by_bb(img.front,bb,img.rangeV,img.rangeH); 
		auto = 0; 
		selected = get(handles.dist_source,'SelectedObject'); 
		selected = get(selected,'String'); 
	mand = str2num(get(handles.manual_dist,'String'));
	switch(selected)
	case 'I'
		GLOBALS.current_distance = imgd; 
	case 'H'
		GLOBALS.current_distance = hsd; 
	case 'V'
		GLOBALS.current_distance = vsd; 
	case '>'
		GLOBALS.current_distance = mand; 
	end
	set(handles.dists_display,'String',sprintf('%.1f | %.1f | %.1f | %.1f | *%.1f*',vsd,hsd,imgd,mand,GLOBALS.current_distance));    		end


function updateGui(id)
	global GLOBALS IMAGES; 
	updateHistory(id); 
	handles = guidata(GLOBALS.vision_gui);
	box = find(GLOBALS.bids == id); 
	updateBox(box)

function updateWithPackets(imPackets)
	global IMAGES GLOBALS;
	[imPackets,ids] = filter_packets(imPackets); 
	for i = 1:numel(imPackets)
		imPacket = imPackets{i};
		IMAGES(imPacket.id).t = imPacket.t; 
		IMAGES(imPacket.id).pose = imPacket.pose;
		IMAGES(imPacket.id).front_angle = imPacket.front_angle; 
		if strcmp(imPacket.type,'FrontVision')
 			front = djpeg(imPacket.front);
			IMAGES(imPacket.id).front = front; 
			for im = 1:3
				IMAGES(imPacket.id).front_cands{im} = draw_cand_zoom(imPacket.front_stats,im,front); 
			end 
			IMAGES(imPacket.id).front_stats = imPacket.front_stats; 
			IMAGES(imPacket.id).rangeH = single(imPacket.rangeH) / 10.0; 
			IMAGES(imPacket.id).rangeV = single(imPacket.rangeV) / 10.0;
			if isempty(imPacket.rangeV)
				IMAGES(imPacket.id).rangeV = zeros([1,60]); 
			end
			%Hokuyu: step = 1081, step = 0.0044, fov = 270
			if isempty(imPacket.rangeH)
				IMAGES(imPacket.id).rangeH = zeros([1,60]); 
			end
			IMAGES(imPacket.id).front_params = imPacket.params; 
		end
		if strcmp(imPacket.type,'OmniVision')
			omni = djpeg(imPacket.omni);
			IMAGES(imPacket.id).omni = omni; 
			for im = 1:3
				IMAGES(imPacket.id).omni_cands{im}  = draw_cand_zoom(imPacket.omni_stats,im,omni);
			end 
				IMAGES(imPacket.id).omni_stats = imPacket.omni_stats; 
				IMAGES(imPacket.id).omni_params = imPacket.params; 
		end
		updateSettingsWithPacket(imPacket.id,imPacket.type,imPacket.params); 	
	end
	for i = 1:numel(ids)
		id = ids(i); 
		GLOBALS.vision_fns.updateGui(id);  
	end
	drawnow; 
	% --- Outputs from this function are returned to the command line.
function varargout = vision_gui_OutputFcn(hObject, eventdata, handles) 
	varargout{1} = handles.output;

function mouse_ButtonDownFcn(hObject, eventdata, data)
	global GLOBALS 
	type = data{1} 
	axeh = data{2}
	nums = data{3}
	cp = get(axeh,'CurrentPoint');
	x = cp(1,1);
	y = cp(1,2); 
	dclick = sum(abs([x,y] - GLOBALS.last_click)) < 50  & toc(GLOBALS.last_click_time) < 5 & GLOBALS.last_click_box == axeh; 
	switch type
	case 'ind'
		ind_down(axeh,x,y,dclick,nums)
	case 'omni'
		omni_down(axeh,x,y,dclick,nums)
	case 'omni_cand'
		omni_cand_down(axeh,x,y,dclick,nums(1),nums(2),'lookat')
	case 'front' 
		front_down(axeh,x,y,dclick,nums)
	case 'front_cand' 
		front_cand_down(axeh,x,y,dclick,nums(1),nums(2))
	otherwise
		assert(false)
	end
	GLOBALS.last_click = [x,y]; 
	GLOBALS.last_click_box = axeh; 	
	GLOBALS.last_click_time = tic; 	
	if dclick
		GLOBALS.last_click_time = GLOBALS.clock; 
	end 

function ind_down(axeh,x,y,dclick,nums)
	focus = nums;
	global IMAGES GLOBALS 
	GLOBALS.focus = focus; 
	updateFrontFocused(focus);


function front_down(axeh,x,y,dclick,box)
	global IMAGES GLOBALS 
	focus = box; 
	id = GLOBALS.bids(focus);  
	image = IMAGES(id);
	focus 
	GLOBALS.focus = focus; 
	if dclick
		bb = image.front_stats(1:end-3,2:end); 
		if isempty(bb)
			return
		end
		mean_y = mean(bb(:,1:2),2); 
		mean_x = mean(bb(:,3:4),2);
		dists = sqrt((mean_y - y).^2 + (mean_x - x).^2);
		[minv,mini] = min(dists);
		GLOBALS.current_bb = bb(mini,:); 
	elseif isempty(GLOBALS.current_bb) | GLOBALS.current_bb_id ~= id
		set_status('Box point')
		GLOBALS.current_bb = round([0,y,0,x]);
	else
		set_status('Box point')
		xp = GLOBALS.current_bb(4);    
		yp = GLOBALS.current_bb(2);   
		GLOBALS.current_bb = round([yp,y,xp,x]);
	end
	GLOBALS.current_bb_id = id; 
	updateFrontFocused(focus);

function omni_cand_down(axeh,x,y,dclick,box,cand,type)
	global IMAGES GLOBALS 
	id = GLOBALS.bids(box);  
	bb = IMAGES(id).omni_stats(cand,2:end);
	set_focus(id); 
	x = mean(bb(3:4)); 
	y = mean(bb(1:2)); 
	servo_yaw = IMAGES(id).front_angle; 
	[theta] = pixel_to_angle(IMAGES(id).omni,x); 
	lookat(id,theta,0,type);
	if box < 3 
		focus = box;
		GLOBALS.focus = focus;   
		updateFrontFocused(focus); 
	end

function front_cand_down(axeh,x,y,dclick,box,cand)
	global IMAGES GLOBALS 
	focus = box;  
	id = GLOBALS.bids(focus);  
	if dclick
		x = mean(GLOBALS.current_bb(3:4)); 
		y = mean(GLOBALS.current_bb(1:2)); 
		servo_yaw = IMAGES(id).front_angle; 
		[theta,phi] = front_pixel_to_angle(IMAGES(id).front,x,y); 
		theta = servo_yaw + theta; 
		lookat(id,theta,phi,'look'); 
		return; 
	end	
	GLOBALS.focus = focus;  
	GLOBALS.current_bb_id = id; 
	GLOBALS.current_bb = IMAGES(id).front_stats(cand,2:end);
	GLOBALS.focus = focus;
	x = mean(GLOBALS.current_bb(3:4)); 
	y = mean(GLOBALS.current_bb(1:2)); 
	updateFrontFocused(focus); 

function omni_down(axeh,x,y,dclick,box)
	global IMAGES GLOBALS;
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
	set(h.status_text,'String',sprintf('%s @ %.1f',msg,toc(GLOBALS.clock)))

function restoreOOIHistory()
	global GLOBALS
	try
		load('~/cands/current_ser.mat'); 
		GLOBALS.current_ser = current_ser; 
	catch 
		GLOBALS.current_ser = 1;
	end
	try	
		load('~/cands/last_five.mat')
		last_five
		size(last_five,2)
		for i = 1:size(last_five,2);
			ooi.id  = last_five(1,i);  
			ooi.ser = last_five(2,i); 
			ooi.front = imread(sprintf('cands/robot_%d_ser_%d.png',ooi.id,ooi.ser));
			GLOBALS.history(i).ooi = ooi;
		end 
	catch
	end

function setup_global_vars(vision_gui)
	global GLOBALS IMAGES
	GLOBALS.vision_gui = vision_gui; 
	GLOBALS.focus = 1;  
	GLOBALS.req_angles = -ones(1,9);
	GLOBALS.current_bb = []; 
	GLOBALS.current_bb_id = []; 
	GLOBALS.current_label = '?'; 
	GLOBALS.current_distance = 0;
	GLOBALS.clock = tic; 
	GLOBALS.last_look = {};
	GLOBALS.phis = zeros(1,9); 	  
	GLOBALS.last_click = [0,0]; 
	GLOBALS.last_click_box = 0; 
	GLOBALS.last_click_time = tic; 
	GLOBALS.bids = [1 2 3 4 5 6 7 8 9];  
	GLOBALS.track_mode = false; 
	GLOBALS.heartbeat = ones(1,9); 
     	GLOBALS.startAngle = -2.356194496154785;
      	GLOBALS.stopAngle = 2.356194496154785;
      	GLOBALS.angleStep = 0.004363323096186;
	GLOBALS.scan_angles = GLOBALS.startAngle:GLOBALS.angleStep:GLOBALS.stopAngle; 
	GLOBALS.tweekH = .2; 
	GLOBALS.tweekV = .15;
	GLOBALS.speeds = ones(1,9); 
	GLOBALS.last_update_tics = [tic,tic,tic,tic,tic,tic,tic,tic,tic];  
	vision_fns.front_cand_down	   = @front_cand_down;  
	vision_fns.omni_cand_down	   = @omni_cand_down;  
	vision_fns.updateGui		   = @updateGui;  
	vision_fns.updateFrontFocused	   = @updateFrontFocused;  
	vision_fns.center_bb_Callback 	   = @center_bb_Callback;  
	vision_fns.updateBox		   = @updateBox;  
	vision_fns.set_status		   = @set_status;  
	vision_fns.lookat_Callback         = @lookat_Callback;
	vision_fns.car_Callback            = @car_Callback;
	vision_fns.door_Callback           = @door_Callback;
	vision_fns.stop_Callback	  =  @stop_Callback
	vision_fns.announce_ooi_Callback   = @announce_ooi_Callback;
	vision_fns.face_Callback   	   = @face_Callback;
	vision_fns.suggest_Callback   	   = @Suggest_Callback;
	vision_fns.track_Callback   	   = @track_Callback;
	vision_fns.lookat_Callback   	   = @lookat_Callback;
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
	GLOBALS.updateWithPackets 	   = @updateWithPackets; 
	GLOBALS.vision_fns = vision_fns;
	null_front = null_image(320,240); 	
	null_omni  = null_image(500,100);
	null_cand  = null_image(150,150);
	GLOBALS.null_omni = null_omni; 
	GLOBALS.null_cand = null_cand; 
	null_cands = {}; 
	null_pose.x = 0;  
	null_pose.y = 0;  
	null_pose.yaw = 0;  
	null_stats = ones(3,5); 
	null_stats(:,1) = 0;
	null_params = get_ctrl_values(-1); 
	GLOBALS.default_params = null_params; 
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
		IMAGES(id).rangeV = zeros(1,60);
		IMAGES(id).rangeH = zeros(1,60);
		IMAGES(id).omni_cands = null_cands;
		IMAGES(id).front_cands = null_cands;
		IMAGES(id).omni_stats = null_stats;
		IMAGES(id).front_stats = null_stats;
		IMAGES(id).pose = null_pose;
		IMAGES(id).omni_params = null_params;
		IMAGES(id).front_params = null_params;
	end
	for t = 1:5
		history(t).front = {IMAGES.front};  
		history(t).omni = {IMAGES.omni};  
		history(t).ooi.front = null_front;
		history(t).ooi.id = 0; 
		history(t).ooi.ser = 0; 
	end 
	GLOBALS.null_cand = null_cand; 
	GLOBALS.history = history; 
	restoreOOIHistory(); 
%------------------------------------------------------------------------------------------

function set_focus(new_fr)
	global GLOBALS;
	handles = guidata(GLOBALS.vision_gui); 
	new_fr_old_box = find(GLOBALS.bids == new_fr);  
	old_fr = GLOBALS.bids(GLOBALS.focus);  
	GLOBALS.bids(GLOBALS.focus) = new_fr; 
	GLOBALS.bids(new_fr_old_box) = old_fr; 
	delete(findobj(get(handles.(sprintf('omni%d',new_fr_old_box)),'Children'),'Type','Text')); 
	delete(findobj(get(handles.(sprintf('omni%d',new_fr_old_box)),'Children'),'Type','Rectangle')); 
	delete(findobj(get(handles.(sprintf('omni%d',new_fr_old_box)),'Children'),'Type','Line'));
	set(handles.(sprintf('ih_omni%d',new_fr_old_box)),'CData',GLOBALS.null_omni);
	GLOBALS.bids(3:8) = sort(GLOBALS.bids(3:8));  
	GLOBALS.vision_fns.set_status(sprintf('Gave focus to: %d',new_fr)); 
	GLOBALS.vision_fns.updateBox(GLOBALS.focus); 
	%old_fr is in front focus, and is going fast	
	%If new_fr was not in front focus, it needs to speed up, and the old_fr needs to slow down
	msg.id = new_fr; 
	if new_fr_old_box > 2
		'Slowing old, speeding new'
		msg.cam = 2; 
		msg.otime = 0.5;
		msg.ftime = 0.5;
		send_cam_param_msg(new_fr,msg)
		msg.ftime = 2;
		send_cam_param_msg(old_fr,msg)
	end
	%If new_fr was in front focus, nobody changes speed
	

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
	handles = guidata(GLOBALS.vision_gui);
	if strcmp(GLOBALS.current_label,'?')
		'Label not set'
		return
	end
	set_status('announced label'); 	
	id = GLOBALS.bids(GLOBALS.focus); 
	x = IMAGES(id).pose.x; 
	y = IMAGES(id).pose.y;
	yaw = IMAGES(id).pose.yaw;
	servo_yaw = IMAGES(id).front_angle; ;
	distance = GLOBALS.current_distance;   
	x = x + distance * cos(yaw + servo_yaw);  
	y = y + distance * sin(yaw + servo_yaw);  
	if strcmp(GLOBALS.current_label,'StationaryPOI') || strcmp(GLOBALS.current_label,'MovingPOI') || strcmp(GLOBALS.current_label,'RedBarrel') 
		updateOOIHistory(id,GLOBALS.current_ser);
	end
	shirt = -1; 
	if strcmp(GLOBALS.current_label,'StationaryPOI') || strcmp(GLOBALS.current_label,'MovingPOI') 
		shirt = str2num(get(handles.shirt,'String')); 
		if isempty(shirt)
			shirt = 0; 
		end
	end 
	send_ooi_msg(id,GLOBALS.current_ser,shirt,x,y,GLOBALS.current_label)
	GLOBALS.current_ser = GLOBALS.current_ser + 1;  

function lazer_up_Callback(hObject, eventdata, handles)
	global GLOBALS; 
	set_status('lazer up'); 	
	id = GLOBALS.bids(GLOBALS.focus); 
	try
		msg = GLOBALS.last_look{GLOBALS.focus};  
	catch
		return; 
	end
	msg.phi = msg.phi + pi/180;
	if msg.phi > pi/2
		msg.phi = msg.phi-pi/2;
	end 
	if msg.phi < -pi/2
		msg.phi = msg.phi+pi/2;
	end 
	send_look_msg(id,msg.theta,msg.phi,'look');  

function lazer_down_Callback(hObject, eventdata, handles)
	global GLOBALS; 
	set_status('lazer down'); 	
	id = GLOBALS.bids(GLOBALS.focus); 
	try
		msg = GLOBALS.last_look{GLOBALS.focus};  
	catch
		return; 
	end
	msg.phi = msg.phi - pi/180;
	if msg.phi > pi/2
		msg.phi = msg.phi-pi/2;
	end 
	if msg.phi < -pi/2
		msg.phi = msg.phi+pi/2;
	end 
	send_look_msg(id,msg.theta,msg.phi,'look');  

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
	try
		msg = GLOBALS.last_look{GLOBALS.focus};  
	catch
		return; 
	end
	msg.theta = mod(msg.theta - pi/180,2*pi); 
	id = GLOBALS.bids(GLOBALS.focus); 
	send_look_msg(id,msg.theta,msg.phi,msg.type);  

function nudge_left_Callback(hObject, eventdata, handles)
	global GLOBALS;
	set_status('nudge left'); 	
	try
		msg = GLOBALS.last_look{GLOBALS.focus};  
	catch
		return; 
	end
	msg.theta = mod(msg.theta + pi/181,2*pi); 
	id = GLOBALS.bids(GLOBALS.focus); 
	send_look_msg(id,msg.theta,msg.phi,msg.type);  

function neutralized_Callback(hObject, eventdata, handles)
	global GLOBALS;
	hid = eventdata; 
	ser = GLOBALS.history(hid).ooi.ser
	set_status('neutralized target'); 	
	send_ooi_done_msg(ser,'complete'); 

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
	updateOmni(find(GLOBALS.bids == id)); ; 
	[theta,abs_angle,theta+abs_angle,mod(theta-abs_angle,2*pi)] 
	send_look_msg(id,mod(theta+abs_angle,2*pi),phi,type); 

function set_label(label)
	global GLOBALS; 
	GLOBALS.current_label = label; 
	set_status(strcat('label:',label)); 	
	updateLabel;  

function send_ooi_msg(id,ser,shirt,x,y,type)
	name = 'OOI_Msg'; 
	msg.ser = ser;
	msg.shirtNumber = shirt; 
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
	name = 'Lazer_Msg';
	msg.status = status;  
	send_message_to_robot(id,name,msg); 

function send_look_msg(id,theta,phi,type);
	global GLOBALS; 
	name = 'Look_Msg'; 
	msg.theta = theta;  
	msg.phi = phi; 
	msg.type = type; %'look', 'track', 'done'
	msg.distance = GLOBALS.current_distance; 
	GLOBALS.last_look{GLOBALS.focus} = msg;
	set_status(type)
	send_message_to_robot(id,name,msg); 

function send_message_to_robot(id,name,msg);
	global ROBOTS NOSEND
	name = sprintf('Robot%d/%s',id,name); 
	msg 
	if ~isempty(NOSEND)
		'NOT SENDING MESSAGES TODAY!!!'
		return
	end
	if ~ROBOTS(id).connected
		sprintf('ROBOT %d NOT CONNECTED!',id)
		return
	end
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
		set_status('No BB to track')
		return
	end
	set_status('Track BB'); 
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
		set_status('No BB to lookat')
		return
	end
	set_status('Lookat BB'); 
	id = GLOBALS.bids(GLOBALS.focus); 
	x = mean(GLOBALS.current_bb(3:4)); 
	y = mean(GLOBALS.current_bb(1:2)); 
	servo_yaw = IMAGES(id).front_angle; 
	[theta,phi] = front_pixel_to_angle(IMAGES(id).front,x,y); 
	theta = servo_yaw + theta; 
	lookat(id,theta,phi,'look'); 

function face_Callback(hObject, eventdata, handles)
	global GLOBALS IMAGES;  
	if isempty(GLOBALS.current_bb)
		set_status('No BB to face')
		return
	end
	set_status('Face BB'); 
	id = GLOBALS.bids(GLOBALS.focus); 
	x = mean(GLOBALS.current_bb(3:4)); 
	y = mean(GLOBALS.current_bb(1:2)); 
	servo_yaw = IMAGES(id).front_angle; 
	[theta,phi] = front_pixel_to_angle(IMAGES(id).front,x,y); 
	theta = servo_yaw + theta; 
	lookat(id,theta,phi,'face'); 

function stop_Callback(hObject, eventdata, handles)
	global GLOBALS; 
	id = GLOBALS.bids(GLOBALS.focus); 
	name = 'StateEvent';
	msg = 'stop'; 
	set_status('Sending stop')
	send_message_to_robot(id,name,msg); 

% --- Executes on button press in Suggest.
function Suggest_Callback(hObject, eventdata, handles)
	global GLOBALS IMAGES;  
	set_status('suggested label'); 	
	id = GLOBALS.bids(GLOBALS.focus); 
	x = IMAGES(id).pose.x; 
	y = IMAGES(id).pose.y;
	yaw = IMAGES(id).pose.yaw;
	servo_yaw = IMAGES(id).front_angle; ;
	distance = GLOBALS.current_distance;   
	x = x + distance * cos(yaw + servo_yaw);  
	y = y + distance * sin(yaw + servo_yaw);  
	send_ooi_msg(id,GLOBALS.current_ser,-1,x,y,'CandOOI'); 

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
function retval = updateSettings(sliders,values)
	global GLOBALS IMAGES;  
	handles = guidata(GLOBALS.vision_gui);
	if isempty(sliders)
		sliders = {'exp','sat','gn','foc','con','brt'}; 
	end
	for i = 1:numel(sliders)
		slider = sliders{i};
		if nargin == 1
			val = round(get(handles.([slider,'slider']),'Value')); 
			set(handles.([slider,'reqval']),'String',num2str(val)); 
			retval = val; 
		else 
			val = values(i); 
			set(handles.([slider,'slider']),'Value',val);
			retval = [];  
		end
		set(handles.([slider,'val']),'String',num2str(val)); 
	end

function long = pname_short_to_long(short)
	switch (short)
	case 'exp'
		long = 'exposure_absolute';
	case 'sat'
		long = 'saturation';
	case 'gn'
		long = 'gain';
	case 'foc'
		long = 'focus'; 
	case 'con'
		long = 'contrast'; 
	case 'brt'; 
		long = 'brightness';
	end

function short = pname_long_to_short(long)
	switch (long)
	case 'exposure_absolute'
		short = 'exp';
	case 'saturation' 
		short =  'sat';
	case 'gain'
		short =  'gn';
	case 'focus' 
		short =  'foc';
	case 'contrast' 
		short =  'con';
	case 'brightness'
		short =  'brt'; 
	end

function updateSettingsWithPacket(id,type,p)
	global GLOBALS;
	if p.ftime == 0.5
		GLOBALS.speeds(id) = 3; 
	else 
		GLOBALS.speeds(id) = 2;
	end 
	handles = guidata(GLOBALS.vision_gui);
	seltype = get(get(handles.camera_type,'SelectedObject'),'String');
	selcam  = get(get(handles.camera,'SelectedObject'),'String');
	switch(selcam)
	case	'L'
		box = 1; 
	case  	'R'
		box = 2;
	otherwise
		box = 1; 
	end

	if id ~= GLOBALS.bids(box)
		return
	end
	
	switch(type)
	case 'OmniVision'
		type = 'OM'; 
	case 'FrontVision'
		type = 'FR'; 
	end

	if strcmp(type,seltype) | strcmp(seltype,'ALL')
		values = [p.exposure_absolute, p.saturation, p.gain, p.focus, p.contrast, p.brightness]; 
		updateSettings([],values); 
	end

function send_cam_param_msg(id,msg)
	name = 'CamParams'
	send_message_to_robot(id,name,msg);

function slider_Callback(hObject, eventdata, handles)
	global GLOBALS ROBOTS IMAGES; 
	short = eventdata; 
	val = updateSettings({short}); 
	seltype = get(get(handles.camera_type,'SelectedObject'),'String');
	selcam  = get(get(handles.camera,'SelectedObject'),'String');
	switch(selcam)
	case	'L'
		boxes = [1]; 
	case  	'R'
		boxes = [2];
	case  	'L/R'
		boxes = [1 2];
	otherwise
		boxes = [1 2 3 4 5 6 7 8 9]; 
	end

	send_om = false; 
	send_fr = false; 
	switch(seltype)
	case 'OM'
		send_om = true;  
	case 'FR'
		send_fr = true; 
	otherwise
		send_om = true;  
		send_fr = true; 
	end
	for box = boxes
		id = GLOBALS.bids(box);
		if ~ROBOTS(id).connected 
			continue
		end
		if send_om
			IMAGES(id).omni_params.(pname_short_to_long(short)) = val; 
			params = IMAGES(id).omni_params; 
			send_cam_param_msg(id,params);
		end
		if send_fr
			IMAGES(id).front_params.(pname_short_to_long(short)) = val; 
			params = IMAGES(id).front_params; 
			send_cam_param_msg(id,params);
		end
	end

	

function slider_CreateFcn(hObject, eventdata, handles)

function reset_params_Callback(hObject, eventdata, handles)
	global GLOBALS
	handles = guidata(GLOBALS.vision_gui);
	p = GLOBALS.default_params; 
	values = [p.exposure_absolute, p.saturation, p.gain, p.focus, p.contrast,p.brightness]
	updateSettings([],values); 
	slider_Callback([], 'exp', handles);
	slider_Callback([], 'sat', handles);
	slider_Callback([], 'gn',  handles);
	slider_Callback([], 'foc', handles);
	slider_Callback([], 'con', handles);
	slider_Callback([], 'brt', handles);

function omni1_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to omni1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function shirt_Callback(hObject, eventdata, handles)
function shirt_CreateFcn(hObject, eventdata, handles)



function man_dist_Callback(hObject, eventdata, handles)
% hObject    handle to man_dist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of man_dist as text
%        str2double(get(hObject,'String')) returns contents of man_dist as a double


% --- Executes during object creation, after setting all properties.
function man_dist_CreateFcn(hObject, eventdata, handles)
% hObject    handle to man_dist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function manual_dist_Callback(hObject, eventdata, handles)
% hObject    handle to manual_dist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of manual_dist as text
%        str2double(get(hObject,'String')) returns contents of manual_dist as a double


% --- Executes during object creation, after setting all properties.
function manual_dist_CreateFcn(hObject, eventdata, handles)
% hObject    handle to manual_dist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in center_bb.
function center_bb_Callback(hObject, eventdata, handles)
	global GLOBALS 
	GLOBALS.current_bb 
	GLOBALS.current_bb = round([110,130,150,180]);
	GLOBALS.current_bb_id = GLOBALS.focus; 
	updateFrontFocused(GLOBALS.focus);

