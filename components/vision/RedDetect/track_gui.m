function varargout = track_gui(varargin)
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @track_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @track_gui_OutputFcn, ...
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

function track_gui_OpeningFcn(hObject, eventdata, handles, varargin)
	handles.output = hObject;
	guidata(hObject, handles);
	setup_global_vars(hObject); 	
	updateGui; 

function updateGui
	global GLOBALS IMAGES; 
	handles = guidata(GLOBALS.track_gui);
	image1 = IMAGES(GLOBALS.track_focus(1).id);
	image2 = IMAGES(GLOBALS.track_focus(2).id);
	front_left_h = draw_cands_on_image(handles.front_left,image1.front_stats,image1.front); 
	front_right_h = draw_cands_on_image(handles.front_right,image2.front_stats,image2.front); 
	set(front_left_h ,'ButtonDownFcn',{@front_ButtonDownFcn,handles.front_left,1});
	set(front_right_h,'ButtonDownFcn',{@front_ButtonDownFcn,handles.front_right,2});
	colors = circshift(uint8([[0,0,255];[0,255,0]]),GLOBALS.track_toggle); 
	imagesc(permute(colors(1,:),[3 1 2]),'Parent',handles.ind_left); 
	imagesc(permute(colors(2,:),[3 1 2]),'Parent',handles.ind_right); 
	text(1,1,sprintf('%d',GLOBALS.track_focus(1).id),'FontSize',20,'Parent',handles.ind_left); 
	text(1,1,sprintf('%d',GLOBALS.track_focus(2).id),'FontSize',20,'Parent',handles.ind_right); 
	
	omni_left_h  = draw_cands_on_image(handles.flat_left,image1.omni_stats,image1.omni); 
	omni_right_h = draw_cands_on_image(handles.flat_right,image2.omni_stats,image2.omni); 

	focus = GLOBALS.track_focus; 
	for cand = 1:3
		crname = sprintf('cand_right%d',cand);
		clname = sprintf('cand_left%d',cand);
		cand1_h = imagesc(image1.front_cands{cand},'Parent',handles.(clname)); 
		daspect(handles.(clname),[1 1 1]);  
		axis(handles.(clname),'off')
		cand2_h = imagesc(image2.front_cands{cand},'Parent',handles.(crname)); 
		daspect(handles.(crname),[1 1 1]);  
		axis(handles.(crname),'off'); 
		bb = image1.front_stats(focus(1).cand,2:end); 
		line([bb(3),bb(4)],[bb(1),bb(1)],'Color','c','LineWidth',2,'Parent',handles.front_left);
		line([bb(3),bb(4)],[bb(2),bb(2)],'Color','c','LineWidth',2,'Parent',handles.front_left);
		line([bb(3),bb(3)],[bb(1),bb(2)],'Color','c','LineWidth',2,'Parent',handles.front_left);
		line([bb(4),bb(4)],[bb(1),bb(2)],'Color','c','LineWidth',2,'Parent',handles.front_left);
		bb = image2.front_stats(focus(2).cand,2:end); 
		line([bb(3),bb(4)],[bb(1),bb(1)],'Color','c','LineWidth',2,'Parent',handles.front_right);
		line([bb(3),bb(4)],[bb(2),bb(2)],'Color','c','LineWidth',2,'Parent',handles.front_right);
		line([bb(3),bb(3)],[bb(1),bb(2)],'Color','c','LineWidth',2,'Parent',handles.front_right);
		line([bb(4),bb(4)],[bb(1),bb(2)],'Color','c','LineWidth',2,'Parent',handles.front_right);
		set(cand1_h,'ButtonDownFcn',{@cand_ButtonDownFcn,handles.(clname),[1,cand]});
		set(cand2_h,'ButtonDownFcn',{@cand_ButtonDownFcn,handles.(crname),[2,cand]});
	end	

	axis(handles.ind_left,'off'); 	
	axis(handles.ind_right,'off'); 	
	axis(handles.flat_left,'off'); 	
	axis(handles.flat_right,'off'); 	
	axis(handles.front_left,'off'); 	
	axis(handles.front_right,'off'); 	
		
function cand_ButtonDownFcn(hObject, eventdata, axeh, focus)
	global IMAGES GLOBALS 
	GLOBALS.track_focus(focus(1)).cand = focus(2); 
	updateGui; 	

function front_ButtonDownFcn(hObject, eventdata, axeh, focus)
	global IMAGES GLOBALS 
	cp = get(axeh,'CurrentPoint');
	x = cp(1,1);
	y = cp(1,2); 
	last_xy = GLOBALS.track_focus(focus).last_xy;
	id = GLOBALS.track_focus(focus).id;
	if abs(last_xy(1)-x) < 10 & abs(last_xy(2)-y) < 10
		po = front_pixel_to_omni(IMAGES(id).omni,IMAGES(id).front,x); 
		angle = pixel_to_angle(IMAGES(id).omni,po);
		GLOBALS.front_fns.lookat(GLOBALS.focus, angle,'track');  
	end
	GLOBALS.track_focus(focus).last_xy = [x,y];


function setup_global_vars(track_gui)
	global GLOBALS IMAGES;  
	handles = guidata(track_gui);
	GLOBALS.track_gui = track_gui; 
	GLOBALS.track_focus(1).id = 1;  
	GLOBALS.track_focus(2).id = 2;  
	GLOBALS.track_focus(1).last_xy = [0 0];   
	GLOBALS.track_focus(2).last_xy = [0 0];  
	GLOBALS.track_focus(1).cand = 1;  
	GLOBALS.track_focus(2).cand = 1;  
	GLOBALS.track_toggle = 1;  
	track_fns.updateGui		= @updateGui;  
	track_fns.toggle_control 	= @toggle_control_Callback; 
	track_fns.set_robot		= @set_robot; 
	track_fns.set_cand 		= @cand_ButtonDownFcn; 
	GLOBALS.track_fns = track_fns; 

function varargout = track_gui_OutputFcn(hObject, eventdata, handles) 
	varargout{1} = handles.output;

function toggle_control_Callback(hObject, eventdata, handles)
	global GLOBALS; 
	GLOBALS.track_toggle = mod(GLOBALS.track_toggle,2) + 1;
	GLOBALS.track_toggle
	updateGui; 

function robot1_Callback(hObject, eventdata, handles)
	set_robot(1); 
function robot2_Callback(hObject, eventdata, handles)
	set_robot(2); 
function robot3_Callback(hObject, eventdata, handles)
	set_robot(3); 
function robot4_Callback(hObject, eventdata, handles)
	set_robot(4); 
function robot5_Callback(hObject, eventdata, handles)
	set_robot(5); 
function robot6_Callback(hObject, eventdata, handles)
	set_robot(6); 
function robot7_Callback(hObject, eventdata, handles)
	set_robot(7); 
function robot8_Callback(hObject, eventdata, handles)
	set_robot(8); 
function robot9_Callback(hObject, eventdata, handles)
	set_robot(9); 
function set_robot(robot)
	global GLOBALS; 
	GLOBALS.track_focus(GLOBALS.track_toggle).id = robot;  
	updateGui; 	

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
	button_handler(chr,'track'); 

function lookat_Callback(hObject, eventdata, handles)
	button_handler('up','track'); 

