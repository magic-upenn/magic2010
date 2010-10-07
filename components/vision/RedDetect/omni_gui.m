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

% Last Modified by GUIDE v2.5 07-Oct-2010 14:03:16

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

function omni_gui_OpeningFcn(hObject, eventdata, handles, varargin)
	handles.output = hObject;
	guidata(hObject, handles);
	setup_global_vars(hObject); 
	updateGui; 

function updateGui
	global GLOBALS IMAGES; 
	handles = guidata(GLOBALS.omni_gui);
	for i = 1:9
		image = IMAGES(i);
		oname = sprintf('omni%d',i);
		cname = sprintf('cand%d',i);
		omni_h  = draw_cands_on_image(handles.(oname),image.omni_stats,image.omni); 
		draw_center_line(handles.(oname),image.omni,image.front_angle,GLOBALS.req_angles(i)); 
		cand_h = imagesc(image.omni_cands{GLOBALS.cand},'Parent',handles.(cname)); 
		daspect(handles.(cname),[1 1 1]);  
		set(omni_h,'ButtonDownFcn',{@omni_ButtonDownFcn,i,handles.(oname)});
		set(cand_h,'ButtonDownFcn',{@cand_ButtonDownFcn,i,handles.(cname)});
		axis(handles.(cname),'off')
		axis(handles.(oname),'off')
	end

function setup_global_vars(omni_gui)
	global GLOBALS IMAGES;
	GLOBALS.omni_gui = omni_gui; 
	omni_fns.updateGui = @updateGui; 
	GLOBALS.omni_fns = omni_fns;
 
function varargout = omni_gui_OutputFcn(hObject, eventdata, handles) 
	varargout{1} = handles.output;


function switch_cand_Callback(hObject, eventdata, handles)
	button_handler('0','front'); 

function cand_ButtonDownFcn(hObject, eventdata, id, axeh)
	global IMAGES GLOBALS;
	xpos = IMAGES(id).omni_stats(GLOBALS.cand,4:5);
	theta = pixel_to_angle(IMAGES(id).omni,mean(xpos));  
	GLOBALS.front_fns.lookat(id,theta); 
	updateGui;   

function omni_ButtonDownFcn(hObject, eventdata, id, axeh)
	global GLOBALS IMAGES;
	cp = get(axeh,'CurrentPoint');
	x = cp(1,1);
	y = cp(1,2);  
	theta = pixel_to_angle(IMAGES(id).omni,x) 
	GLOBALS.front_fns.lookat(id,theta); 
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
	button_handler(chr,'omni'); 
