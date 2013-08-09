%{
GUI Handles
              msgHandle:
             uitoolbar1:
                  text1:
           UAVCtrlPanel:
           UGVCtrlPanel:
         View3CtrlPanel:
         View2CtrlPanel:
         View1CtrlPanel:
      MainViewCtrlPanel:
             View3Panel:
             View2Panel:
             View1Panel:
          MainViewPanel:
          uitoggletool5:
          uitoggletool4:
          uitoggletool3:
          uitoggletool1:
          uitoggletool2:
        UAVFollowButton:
          UAVStopButton:
    UAVSelectPathButton:
        UAVGoToPtButton:
          UAVSelectMenu:
        UGV_Select_List:
       UGV_GoToPtButton:
          UGVStopButton:
    UGVSelectPathButton:
            View3Toggle:
            View2Toggle:
            View1Toggle:
           MainViewMenu:
              View3Axes:
              View2Axes:
              View1Axes:
           MainViewAxes:
                 output:
%}





function varargout = UGV_UAV_COOP_2(varargin)
global MAGIC_COLORMAP
%% UGV_UAV_COOP_2 MATLAB code for UGV_UAV_COOP_2.fig
%      UGV_UAV_COOP_2, by itself, creates a new UGV_UAV_COOP_2 or raises the existing
%      singleton*.
%
%      H = UGV_UAV_COOP_2 returns the handle to a new UGV_UAV_COOP_2 or the handle to
%      the existing singleton*.
%
%      UGV_UAV_COOP_2('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in UGV_UAV_COOP_2.M with the given input arguments.
%
%      UGV_UAV_COOP_2('Property','Value',...) creates a new UGV_UAV_COOP_2 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before UGV_UAV_COOP_2_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to UGV_UAV_COOP_2_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help UGV_UAV_COOP_2

% Last Modified by GUIDE v2.5 24-Jun-2013 11:33:13

%% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @UGV_UAV_COOP_2_OpeningFcn, ...
                   'gui_OutputFcn',  @UGV_UAV_COOP_2_OutputFcn, ...
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% MAIN PLOTTING AND MAP UPDATE PROCESSING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% --- Executes just before UGV_UAV_COOP_2 is made visible.
function UGV_UAV_COOP_2_OpeningFcn(hObject, eventdata, handles, varargin)
    global numAxes ROBOT connections globaldat
    % hObject    handle to figure
    % handles    structure with handles and user data (see GUIDATA)

    %% Choose default command line output for UGV_UAV_COOP_2
    handles.output = hObject;

    %% Update handles structure
    guidata(hObject, handles);

    %% Set MAGIC include directories
    SetMagicPaths;
    initColormap;
    more off;

    set(hObject,'toolbar','figure');
    %% Global planner data initialization and subscription
    connections.main=ipcAPI('connect');
    fprintf('Connected to main IPC\n\n');
    
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
    fprintf('Subscribed to IncV. Message queue length: 30\n\n');

    
    %% Robot 1 connect
    connections.r1=ipcWrapperAPI1('connect','192.168.10.101',1);
    fprintf('Connected to Robot 1 messages\n\n');
    
    ipcWrapperAPI1('subscribe','Robot1/Planner_Path');
    ipcWrapperAPI1('set_msg_queue_length','Robot1/Planner_Path',1);
    fprintf('Subscribed to Robot1 path planner. Message queue length: 1\n');
    
    ipcWrapperAPI1('subscribe','Robot1/FSM_Status');
    ipcWrapperAPI1('set_msg_queue_length','Robot1/FSM_Status',1);
    fprintf('Subscribed to Robot1 FSM status. Message queue length: 1\n');
    
    ipcWrapperAPI1('define','Robot1/Goal_Point');
    ipcWrapperAPI1('define','Robot1/Path');
    ipcWrapperAPI1('define','Robot1/StateEvent');
%{
    %% Robot 2 connect
    connections.r2=ipcWrapperAPI2('connect','192.168.10.102',2);
    fprintf('Connected to Robot 2 messages\n\n');
    
    ipcWrapperAPI2('subscribe','Robot2/Planner_Path');
    ipcWrapperAPI2('set_msg_queue_length','Robot2/Planner_Path',1);
    fprintf('Subscribed to Robot2 path planner. Message queue length: 1\n');
    
    ipcWrapperAPI2('subscribe','Robot2/FSM_Status');
    ipcWrapperAPI2('set_msg_queue_length','Robot2/FSM_Status',1);
    fprintf('Subscribed to Robot2 FSM status. Message queue length: 1\n');
    
    ipcWrapperAPI2('define','Robot2/Goal_Point');
    ipcWrapperAPI2('define','Robot2/Path');
    ipcWrapperAPI2('define','Robot2/StateEvent');
  %}  
    %% Quad 1 Connect
    ipcAPI('subscribe','Quad1/AprilInfo');
    ipcAPI('set_msg_queue_length','Quad1/AprilInfo',1);
    fprintf('Connected to AprilInfo. Message queue length: 1\n');
    
    %% confirmation printf
    fprintf('\nSubscriptions successful! Starting GUI...\n');
    
    %% Initialize axes
    axes(handles.View1Axes);
    set(handles.View1Axes,'CLimMode','manual');
    set(handles.View1Axes,'CLim',[-100 100]); 
    hold on;
    axis equal
            
    axes(handles.View2Axes);
    set(handles.View2Axes,'CLimMode','manual');
    set(handles.View2Axes,'CLim',[-100 100]); 
    hold on;
    axis equal
    
    axes(handles.View3Axes);
    set(handles.View3Axes,'CLimMode','manual');
    set(handles.View3Axes,'CLim',[-100 100]); 
    hold on;
    axis equal
    
    axes(handles.MainViewAxes);
    set(handles.MainViewAxes,'CLimMode','manual');
    set(handles.MainViewAxes,'CLim',[-100 100]);
    hold on;
    axis equal
    
    globaldat.xlim=[-200 200];
    globaldat.ylim=[-200 200];
    globaldat.map=int8(zeros(400/.1,400/.1));
    globaldat.resolution=0.1    
    globaldat.mapplot=imagesc(globaldat.xlim, ...
                            globaldat.ylim, ...
                            globaldat.map, [-100 100]);

    numAxes=3;
    ROBOT={};
    while(1)
        updatePlots(handles)
        updateFSM(handles)
    end

function updateFSM(handles)
global ROBOT numAxes connections
for j=1:3%length(connections)
    fieldname=['r' num2str(j)];
    if isfield(connections,fieldname)
        handlename=str2func(['ipcWrapperAPI' num2str(j)]);
        msgs=handlename('listen',10);
        nmsgs=length(msgs);
        for i=1:nmsgs
            name=msgs(i).name;
            switch name
                case 'Robot1/FSM_Status'
                    fprintf('robot 1 fsm status received\n')
                    data=deserialize(msgs(i).data);
                    ROBOT{1}.fsmstatus=data.status;
                case 'Robot1/Planner_Path'
                    fprintf('robot 1 path received\n')
                    data=deserialize(msgs(i).data);
                    ROBOT{1}.path=data;
                case 'Robot2/FSM_Status'
                    fprintf('robot 2 fsm status received\n')
                    data=deserialize(msgs(i).data);
                    ROBOT{2}.fsmstatus=data.status;
                case 'Robot2/Planner_Path'
                    fprintf('robot 2 path received\n')
                    data=deserialize(msgs(i).data);
                    ROBOT{2}.path=data;
                case 'Robot3/FSM_Status'
                    fprintf('robot 3 fsm status received\n')
                    data=deserialize(msgs(i).data);
                    ROBOT{3}.fsmstatus=data.status;
                case 'Robot3/Planner_Path'
                    fprintf('robot 3 path received\n')
                    data=deserialize(msgs(i).data);
                    ROBOT{3}.path=data;
                otherwise
            end
        end
    end
end

function initbot(id)
    global ROBOT MAGIC_COLORMAP
    
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
    ROBOT{id}.poseplot=fill(pFill(1,:),pFill(2,:),'g');
    ROBOT{id}.mapplot=imagesc(ROBOT{id}.x0+ROBOT{id}.dx, ...
                            ROBOT{id}.y0+ROBOT{id}.dy, ...
                            ROBOT{id}.cost, [-100 100]);
    ROBOT{id}.pathplot=plot(0,0,'r');
    colormap(MAGIC_COLORMAP);
    
    %initialize incremental horizontal fields
    ROBOT{id}.inch.xsnew=[];
    ROBOT{id}.inch.ysnew=[];
    ROBOT{id}.inch.csnew=[];
    
    %initialize incremental vertical fields
    ROBOT{id}.incv.xsnew=[];
    ROBOT{id}.incv.ysnew=[];
    ROBOT{id}.incv.csnew=[];

    ROBOT{id}.wpplot=plot(0,0,'gs','MarkerSize',10);
    ROBOT{id}.wp=[0 0];
    ROBOT{id}.path=[];


function updatePlots(handles)
	global ROBOT numAxes globaldat constraints
    
    %% receive map and pose updates
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
            case 'Quad1/AprilInfo'
                aprildata=msgs(i).data;
                id=aprildata(1);
                t=double(typecast(aprildata(2:9),'double'))
                rest=aprildata(10:end);
                pos1=typecast(rest(1:8*3),'double');
                ypr=typecast(rest(8*3+1:8*6),'double');
                dist=typecast(rest(8*6+1:8*7),'double');
            %case 'Global_Map'
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
        xlim=ROBOT{id1}.x0+ROBOT{id1}.dx;
        ylim=ROBOT{id1}.y0+ROBOT{id1}.dy;
        set(handles.(axesname), ...
            'XLim',xlim/2.9+ROBOT{id1}.pose.x, ...
            'YLim',ylim/5+ROBOT{id1}.pose.y);
        set(ROBOT{id1}.mapplot,'Parent',handles.(axesname));
        set(ROBOT{id1}.poseplot,'Parent',handles.(axesname));
        set(ROBOT{id1}.wpplot,'Parent',handles.(axesname));
        set(ROBOT{id1}.pathplot,'Parent',handles.(axesname));
        
        hold on
        plotBot(ROBOT{id1}.pose.x, ...
                ROBOT{id1}.pose.y, ...
                ROBOT{id1}.pose.yaw, ...
                ROBOT{id1}.poseplot);
        plotWayPoint(id1);
        plotPath(id1);
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
        drawnow;
    end
    
    set(globaldat.mapplot,'Parent',handles.MainViewAxes);
    updateGlobal;
    drawnow;
        
function updateGlobal
    global ROBOT globaldat
    
    filledCells=~cellfun(@isempty,ROBOT);
    indeces=find(filledCells==1);
    
    [nx,ny]=size(ROBOT{indeces(1)}.cost);
    xlim=ROBOT{indeces(1)}.x0+ROBOT{indeces(1)}.dx;
    ylim=ROBOT{indeces(1)}.y0+ROBOT{indeces(1)}.dy;
    
    x1=[xlim(1):(xlim(end)-xlim(1))/(nx-1):xlim(end)];
    y1=[ylim(1):(ylim(end)-ylim(1))/(ny-1):ylim(end)];
    [xc,yc,sc]=find(ROBOT{indeces(1)}.cost);
    vec=[x1(xc);y1(yc)];
    rotation=[cos(pi/4) -sin(pi/4); sin(pi/4) cos(pi/4)]*vec;
    pc=[rotation(1,:);rotation(2,:);double(sc)'];
    
    map_assign(globaldat.map,globaldat.xlim,globaldat.ylim,pc);
    set(globaldat.mapplot,'XData',globaldat.xlim,'YData',globaldat.ylim,'CData',globaldat.map')
    
    

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
    rotangle=ROBOT{id}.pose.yaw*180/pi-90;
    cost=ROBOT{id}.cost';
    set(map1plot,'XData',xlim,'YData',ylim,'CData',cost);


function plotBot(x,y,yaw,pose1plot)
    xFill=.3*[-1.0 2.5 -1.0 -1.0];
    yFill=.3*[-1.0 0 1.0 -1.0];
    yawrot=yaw;
    trans=[cos(yawrot) -sin(yawrot) x;
            sin(yawrot) cos(yawrot) y;
            0 0 1];
    pFill=trans*[xFill; yFill; ones(size(xFill))];
    set(pose1plot,'XData',pFill(1,:),'YData',pFill(2,:));

function plotWayPoint(id)
    global ROBOT
    yaw=0;
    x0=ROBOT{id}.pose.x;
    y0=ROBOT{id}.pose.y;
    rotation=[cos(yaw) -sin(yaw);
                sin(yaw) cos(yaw)];
    position=rotation*(ROBOT{id}.wp');
    set(ROBOT{id}.wpplot,'XData',position(1),'YData',position(2))
    
function plotPath(id)
    global ROBOT
    if ~isempty(ROBOT{id}.path)
        yaw=0;%-ROBOT{id}.pose.yaw+pi/2;
        rotation=[cos(yaw) -sin(yaw);
                sin(yaw) cos(yaw)];
        path=rotation*ROBOT{id}.path(:,1:2)';
        set(ROBOT{id}.pathplot,'XData',path(1,:),'YData',path(2,:));
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CALLBACK FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
% --- Executes on button press in testbutton.
function testbutton_Callback(hObject, eventdata, handles)
% hObject    handle to testbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
fprintf('i can get here fine\n')
%}

% --- Executes on button press in UGV_GoToPtButton.
function UGV_GoToPtButton_Callback(hObject, eventdata, handles)
% hObject    handle to UGV_GoToPtButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global ROBOT numAxes
[xp,yp]=ginput(1);
filledCells=~cellfun(@isempty,ROBOT);
indeces=find(filledCells==1);
idx=[];
id=[];
for i=1:length(indeces)
    id=indeces(i);
    pl=ROBOT{id}.wpplot;
    children=get(gca,'Children');
    idx=find(children==pl);
    if ~isempty(idx)
        parsedid=id;
    end
end

if ~isempty(parsedid)
    yaw=0;%ROBOT{id}.pose.yaw;
    rotation=[cos(yaw) -sin(yaw);
            sin(yaw) cos(yaw)];
    turnvec=rotation*[xp;yp];
    x0=ROBOT{parsedid}.pose.x;
    y0=ROBOT{parsedid}.pose.y;
    ROBOT{parsedid}.wp=[turnvec(1) turnvec(2)];
    PATH=[turnvec(1) turnvec(2)];
    msgName=['Robot',num2str(parsedid),'/Goal_Point'];
    try
        handlename=str2func(['ipcWrapperAPI' num2str(parsedid)]);
        handlename('publish',msgName,serialize(PATH));
    catch
    end
else
    fprintf('Invalid coordinates. Choose proper map.\n')
end


%% --- Executes on button press in UAVSelectPathButton.
function UAVSelectPathButton_Callback(hObject, eventdata, handles)
    % hObject    handle to UAVSelectPathButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    
%% --- Executes on selection change in UAVSelectMenu.
function UAVSelectMenu_Callback(hObject, eventdata, handles)
    % hObject    handle to UAVSelectMenu (see GCBO)
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: contents = cellstr(get(hObject,'String')) returns UAVSelectMenu contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from UAVSelectMenu

    
%% --- Executes on button press in UAVStopButton.
function UAVStopButton_Callback(hObject, eventdata, handles)
    % hObject    handle to UAVStopButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)


%% --- Executes on button press in UAVFollowButton.
function UAVFollowButton_Callback(hObject, eventdata, handles)
    % hObject    handle to UAVFollowButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)


%% --- Executes on selection change in UGVSelectMenu.
function UGVSelectMenu_Callback(hObject, eventdata, handles)
    % hObject    handle to UGVSelectMenu (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: contents = cellstr(get(hObject,'String')) returns UGVSelectMenu contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from UGVSelectMenu


%% --- Executes on button press in UGVSelectPathButton.
function UGVSelectPathButton_Callback(hObject, eventdata, handles)
    % hObject    handle to UGVSelectPathButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
global ROBOT
    [xp,yp]=ginput;
    filledCells=~cellfun(@isempty,ROBOT);
    indeces=find(filledCells==1);
    idx=[];
    id=[];
    for i=1:length(indeces)
        id=indeces(i);
        pl=ROBOT{id}.wpplot;
        children=get(gca,'Children')
        idx=find(children==pl);
    end
    %{
    if ~isempty(idx)
        PATH=[ROBOT{id}.pose.x ROBOT{id}.pose.y; xp yp];
        ROBOT{id}.wp=[PATH(:,1) PATH(:,2)];
        msgName=['Robot',num2str(id),'/Path'];
        try
            ipcWrapperAPI3('publish',msgName,serialize(PATH));
        catch
        end
        
    else
        fprintf('Invalid path. Choose points in proper map.\n')
    end
%}

%% --- Executes on button press in UGVStopButton.
function UGVStopButton_Callback(hObject, eventdata, handles)
    % hObject    handle to UGVStopButton (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
global ROBOT numAxes

filledCells=~cellfun(@isempty,ROBOT);
indeces=find(filledCells==1);

for i=1:length(indeces)
    id=indeces(i);
    
    %if ~isempty(parsedid)
    msgName=['Robot',num2str(id),'/StateEvent'];
    state='stop';
    try
        handlename=str2func(['ipcWrapperAPI' num2str(id)]);
        handlename('publish',msgName,serialize(state));
        %ipcWrapperAPI3('publish',msgName,serialize(state));
    catch
    end
end

%% --- Executes on button press in View3Toggle.
function View3Toggle_Callback(hObject, eventdata, handles)
    % hObject    handle to View3Toggle (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hint: get(hObject,'Value') returns toggle state of View3Toggle


%% --- Executes on button press in View2Toggle.
function View2Toggle_Callback(hObject, eventdata, handles)
    % hObject    handle to View2Toggle (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hint: get(hObject,'Value') returns toggle state of View2Toggle


%% --- Executes on button press in View1Toggle.
function View1Toggle_Callback(hObject, eventdata, handles)
    % hObject    handle to View1Toggle (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hint: get(hObject,'Value') returns toggle state of View1Toggle


%% --- Executes on selection change in MainViewMenu.
function MainViewMenu_Callback(hObject, eventdata, handles)
    % hObject    handle to MainViewMenu (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: contents = cellstr(get(hObject,'String')) returns MainViewMenu contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from MainViewMenu


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CREATE FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% --- Executes during object creation, after setting all properties.
function UAVSelectMenu_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to UAVSelectMenu (see GCBO)
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

% 
% %% --- Executes on button press in UAVGoToPtButton.
% function UAVGoToPtButton_Callback(hObject, eventdata, handles)
%     % hObject    handle to UAVGoToPtButton (see GCBO)
%     % handles    structure with handles and user data (see GUIDATA)
% 

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
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% OUTPUT FUNCTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% --- Outputs from this function are returned to the command line.
function varargout = UGV_UAV_COOP_2_OutputFcn(hObject, eventdata, handles) 
    % varargout  cell array for returning output args (see VARARGOUT);
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Get default command line output from handles structure
    varargout{1} = handles.output;


% --- Executes on selection change in UGV_Select_List.
function UGV_Select_List_Callback(hObject, eventdata, handles)
% hObject    handle to UGV_Select_List (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns UGV_Select_List contents as cell array
%        contents{get(hObject,'Value')} returns selected item from UGV_Select_List


% --- Executes during object creation, after setting all properties.
function UGV_Select_List_CreateFcn(hObject, eventdata, handles)
% hObject    handle to UGV_Select_List (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
