function varargout = UGV_UAV_COOP(varargin)
global MAGIC_COLORMAP
%% UGV_UAV_COOP MATLAB code for UGV_UAV_COOP.fig
%      UGV_UAV_COOP, by itself, creates a new UGV_UAV_COOP or raises the existing
%      singleton*.
%
%      H = UGV_UAV_COOP returns the handle to a new UGV_UAV_COOP or the handle to
%      the existing singleton*.
%
%      UGV_UAV_COOP('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in UGV_UAV_COOP.M with the given input arguments.
%
%      UGV_UAV_COOP('Property','Value',...) creates a new UGV_UAV_COOP or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before UGV_UAV_COOP_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to UGV_UAV_COOP_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help UGV_UAV_COOP

% Last Modified by GUIDE v2.5 12-Jun-2013 23:12:32

%% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @UGV_UAV_COOP_OpeningFcn, ...
                   'gui_OutputFcn',  @UGV_UAV_COOP_OutputFcn, ...
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


%% --- Executes just before UGV_UAV_COOP is made visible.
function UGV_UAV_COOP_OpeningFcn(hObject, eventdata, handles, varargin)
    global numAxes ROBOT
    % hObject    handle to figure
    % handles    structure with handles and user data (see GUIDATA)

    %% Choose default command line output for UGV_UAV_COOP
    handles.output = hObject;

    %% Update handles structure
    guidata(hObject, handles);

    %% Set MAGIC include directories
    SetMagicPaths;
    initColormap;
    more off;

    set(hObject,'toolbar','figure');

    %% Global planner data initialization and subscription
    ipcAPI('connect');
    fprintf('Connected to main IPC\n');

    %% Global and local map data initialization and subscription
    ipcAPI('subscribe','Global_Map');
    ipcAPI('set_msg_queue_length','Global_Map',1);
    fprintf('Subscribed to Global Map. Message queue length: 1\n');

    ipcAPI('subscribe','RPose');
    ipcAPI('set_msg_queue_length','RPose',30);
    fprintf('Subscribed to RPose. Message queue length: 30\n');

    ipcAPI('subscribe','IncH');
    ipcAPI('set_msg_queue_length','IncH',30);
    fprintf('Subscribed to IncH. Message queue length: 30\n');

    ipcAPI('subscribe','IncV');
    ipcAPI('set_msg_queue_length','IncV',30);
    fprintf('Subscribed to IncV. Message queue length: 30\n');

    fprintf('\nSubscriptions successful\n');

    %axes(handles.View1Axes);
    set(handles.View1Axes,'XLim',[-10 10], 'YLim', [-10 10]);
    %set(handles.View1Axes,'CLimMode','manual');
    %set(handles.View1Axes,'CLim',[-100 100]); 
    hold on;
    axis equal
            
    %axes(handles.View2Axes);
    set(handles.View2Axes,'XLim',[-10 10], 'YLim', [-10 10]);
    %set(handles.View2Axes,'CLimMode','manual');
    %set(handles.View2Axes,'CLim',[-100 100]); 
    hold on;
    axis equal
    
    %axes(handles.View3Axes);
    set(handles.View3Axes,'XLim',[-10 10], 'YLim', [-10 10]);
    %set(handles.View3Axes,'CLimMode','manual');
    %set(handles.View3Axes,'CLim',[-100 100]); 
    hold on;
    axis equal
    
    numAxes=3;
    ROBOT={};
    while(1)
        updatePlots(handles);
    end
end

function updatePlots(handles)
	global ROBOT numAxes
    
    %% receive map and pose updates
    robotdat=[];
    inchdat=[];
    incvdat=[];
    globaldat=[];

    msgs=ipcAPI('listenWait',100);
    nmsg=length(msgs);
    for i=1:nmsg
        drawnow;
        name=msgs(i).name;
        switch name
            case 'RPose'
                robotdat=deserialize(msgs(i).data);
                id=robotdat.id;
                if id>length(ROBOT)
                    initbot(id);
                else
                    if ~isfield(ROBOT{id},'x0')
                        initbot(id);
                    end
                end
                ROBOT{id}.pose=robotdat.update;
            case 'IncH'
                inchdat=deserialize(msgs(i).data);
                id=inchdat.id;
                if id>length(ROBOT)
                    initbot(id);
                else
                    if ~isfield(ROBOT{id},'x0')
                        initbot(id);
                    end
                end
                ROBOT{id}.inch.xsnew=inchdat.update.xs;
                ROBOT{id}.inch.ysnew=inchdat.update.ys;
                ROBOT{id}.inch.csnew=inchdat.update.cs;
            case 'IncV'
                incvdat=deserialize(msgs(i).data);
                id=incvdat.id;
                if id>length(ROBOT)
                    initbot(id);
                else
                    if ~isfield(ROBOT{id},'x0')
                        initbot(id);
                    end
                end
                ROBOT{id}.incv.xsnew=incvdat.update.xs;
                ROBOT{id}.incv.ysnew=incvdat.update.ys;
                ROBOT{id}.incv.csnew=incvdat.update.cs;
            %case 'Global_Map'
            %    globaldat=deserialize(msgs(i).data);
            otherwise
        end
    end
    
    %% update plots
    filledCells=~cellfun(@isempty,ROBOT);
    indeces=find(filledCells==1);
    if length(indeces)>numAxes
        iterations=numAxes;
    else
        iterations=length(indeces);
    end
    for i=1:iterations
        axesname=['View',num2str(i),'Axes'];
        id1=indeces(i);
        set(ROBOT{id1}.mapplot,'Parent',handles.(axesname));
        set(ROBOT{id1}.poseplot,'Parent',handles.(axesname));
        hold on
        xlim=ROBOT{id1}.x0+ROBOT{id1}.dx;
        ylim=ROBOT{id1}.y0+ROBOT{id1}.dy;
        plotBot(ROBOT{id1}.pose.x, ...
                ROBOT{id1}.pose.y, ...
                ROBOT{id1}.pose.yaw, ...
                ROBOT{id1}.poseplot);
        
        incUpdate(id1,double(ROBOT{id1}.inch.xsnew), ...
                    double(ROBOT{id1}.inch.ysnew), ...
                    double(ROBOT{id1}.inch.csnew), ...
                    xlim, ...
                    ylim, ...
                    ROBOT{id1}.mapplot);
        incUpdate(id1,double(ROBOT{id1}.incv.xsnew), ...
                    double(ROBOT{id1}.incv.ysnew), ...
                    double(ROBOT{id1}.incv.csnew), ...
                    xlim, ...
                    ylim, ...
                    ROBOT{id1}.mapplot);

    end
end

function initbot(id)
    global ROBOT
    
    ROBOT{id}.pose={};
    ROBOT{id}.x0=0;
    ROBOT{id}.y0=0;
    ROBOT{id}.dx=[-50 50];
    ROBOT{id}.dy=[-50 50];
    ROBOT{id}.resolution=0.1;
    nx=round((ROBOT{id}.dx(end)-ROBOT{id}.dx(1))/ROBOT{id}.resolution);
    ny=round((ROBOT{id}.dy(end)-ROBOT{id}.dy(1))/ROBOT{id}.resolution);
    ROBOT{id}.cost=zeros(nx,ny,'int8');
    xFill=.3*[-1.0 2.5 -1.0 -1.0];
    yFill=.3*[-1.0 0 1.0 -1.0];
    pFill=[xFill; yFill; ones(size(xFill))];
    ROBOT{id}.poseplot=fill(pFill(1,:),pFill(2,:),'b');
    ROBOT{id}.mapplot=imagesc(ROBOT{id}.x0+ROBOT{id}.dx, ...
                            ROBOT{id}.y0+ROBOT{id}.dy, ...
                            ROBOT{id}.cost, [-100 100]);
    colormap(MAGIC_COLORMAP);
    ROBOT{id}.inch.xsnew=[];
    ROBOT{id}.inch.ysnew=[];
    ROBOT{id}.inch.csnew=[];
    ROBOT{id}.incv.xsnew=[];
    ROBOT{id}.incv.ysnew=[];
    ROBOT{id}.incv.csnew=[];
end

function incUpdate(id,xs,ys,cs,xlim,ylim,map1plot)
    global ROBOT
    %% update lidar cost map
    map_filter(ROBOT{id}.cost,xlim,ylim,[xs(:) ys(:) cs(:)]',0.3);
    
    if ROBOT{id}.pose.x~=ROBOT{id}.x0 || ROBOT{id}.pose.y~=ROBOT{id}.y0
        [nx,ny]=size(ROBOT{id}.cost);
        x1=[xlim(1):(xlim(end)-xlim(1))/(nx-1):xlim(end)];
        y1=[ylim(1):(ylim(end)-ylim(1))/(ny-1):ylim(end)];
        [xc,yc,sc]=find(ROBOT{id}.cost);
        pc=[x1(xc);y1(yc);double(sc)'];
        ROBOT{id}.x0=ROBOT{id}.pose.x;
        ROBOT{id}.y0=ROBOT{id}.pose.y;
        ROBOT{id}.cost=zeros(nx,ny,'int8');
        map_assign(ROBOT{id}.cost,ROBOT{id}.x0+ROBOT{id}.dx,ROBOT{id}.y0+ROBOT{id}.dy,pc);
    end
    rotangle=ROBOT{8}.pose.yaw*180/pi-90;
    cost=imrotate(ROBOT{8}.cost',rotangle,'crop');
    set(map1plot,'XData',xlim,'YData',ylim,'CData',cost);
end

function plotBot(x,y,yaw,pose1plot)
    xFill=.3*[-1.0 2.5 -1.0 -1.0];
    yFill=.3*[-1.0 0 1.0 -1.0];
    yawrot=pi/2;
    trans=[cos(yawrot) -sin(yawrot) x;
            sin(yawrot) cos(yawrot) y;
            0 0 1];
    pFill=trans*[xFill; yFill; ones(size(xFill))];
    set(pose1plot,'XData',pFill(1,:),'YData',pFill(2,:));
end

%% --- Outputs from this function are returned to the command line.
function varargout = UGV_UAV_COOP_OutputFcn(hObject, eventdata, handles) 
    % varargout  cell array for returning output args (see VARARGOUT);
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Get default command line output from handles structure
    varargout{1} = handles.output;
end

%% --- Executes on selection change in UAVSelectMenu.
function UAVSelectMenu_Callback(hObject, eventdata, handles)
    % hObject    handle to UAVSelectMenu (see GCBO)
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: contents = cellstr(get(hObject,'String')) returns UAVSelectMenu contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from UAVSelectMenu
end

%% --- Executes during object creation, after setting all properties.
function UAVSelectMenu_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to UAVSelectMenu (see GCBO)
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

%% --- Executes on button press in UAVGoToPtButton.
function UAVGoToPtButton_Callback(hObject, eventdata, handles)
    % hObject    handle to UAVGoToPtButton (see GCBO)
    % handles    structure with handles and user data (see GUIDATA)
end

%% --- Executes on button press in UAVSelectPathButton.
function UAVSelectPathButton_Callback(hObject, eventdata, handles)
    % hObject    handle to UAVSelectPathButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
end

%% --- Executes on button press in UAVStopButton.
function UAVStopButton_Callback(hObject, eventdata, handles)
    % hObject    handle to UAVStopButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
end

%% --- Executes on button press in UAVFollowButton.
function UAVFollowButton_Callback(hObject, eventdata, handles)
    % hObject    handle to UAVFollowButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
end

%% --- Executes on selection change in UGVSelectMenu.
function UGVSelectMenu_Callback(hObject, eventdata, handles)
    % hObject    handle to UGVSelectMenu (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: contents = cellstr(get(hObject,'String')) returns UGVSelectMenu contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from UGVSelectMenu
end

%% --- Executes during object creation, after setting all properties.
function UGVSelectMenu_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to UGVSelectMenu (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

%% --- Executes on button press in UGVGoToPtButton.
function UGVGoToPtButton_Callback(hObject, eventdata, handles)
    % hObject    handle to UGVGoToPtButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    [xp, yp]=ginput(1);
    msgName=['Robot',num2str(id),'/Goal_Point'];
    if ~isempty(xp)
        PATH=[xp(1) yp(1)];
        try
            msgName
            xp
            yp
            %ipcAPI('publish',msgName,serialize(PATH));
        catch
        end
    end
end

%% --- Executes on button press in UGVSelectPathButton.
function UGVSelectPathButton_Callback(hObject, eventdata, handles)
    % hObject    handle to UGVSelectPathButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
end

%% --- Executes on button press in UGVStopButton.
function UGVStopButton_Callback(hObject, eventdata, handles)
    % hObject    handle to UGVStopButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
end

%% --- Executes on button press in View3Toggle.
function View3Toggle_Callback(hObject, eventdata, handles)
    % hObject    handle to View3Toggle (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hint: get(hObject,'Value') returns toggle state of View3Toggle
end

%% --- Executes on button press in View2Toggle.
function View2Toggle_Callback(hObject, eventdata, handles)
    % hObject    handle to View2Toggle (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hint: get(hObject,'Value') returns toggle state of View2Toggle
end

%% --- Executes on button press in View1Toggle.
function View1Toggle_Callback(hObject, eventdata, handles)
    % hObject    handle to View1Toggle (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hint: get(hObject,'Value') returns toggle state of View1Toggle
end

%% --- Executes on selection change in MainViewMenu.
function MainViewMenu_Callback(hObject, eventdata, handles)
    % hObject    handle to MainViewMenu (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: contents = cellstr(get(hObject,'String')) returns MainViewMenu contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from MainViewMenu
end

%% --- Executes during object creation, after setting all properties.
function MainViewMenu_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to MainViewMenu (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end
end
