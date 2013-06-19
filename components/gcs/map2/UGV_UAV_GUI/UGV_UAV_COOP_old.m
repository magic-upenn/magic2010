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
    global map1plot view1plot pose1plot ROBOT
    % hObject    handle to figure
    % handles    structure with handles and user data (see GUIDATA)

    %% Choose default command line output for UGV_UAV_COOP
    handles.output = hObject;

    %% Update handles structure
    guidata(hObject, handles);
    

	if ~isempty(varargin)
        cmd=varargin{1};
        if strcmp(cmd,'initialize')
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
            
            axes(handles.View1Axes);
            set(handles.View1Axes,'XLim',[-10 10], 'YLim', [-10 10]);
            %set(gca,'CLim',[-100 100]); 
            %set(gca,'CLimMode','manual');
            hold on;
            axis equal
            
            %mapplot
            
            ROBOT{8}.x0=0;
            ROBOT{8}.y0=0;
            ROBOT{8}.dx=[-50 50];
            ROBOT{8}.dy=[-50 50];
            ROBOT{8}.resolution=0.1;
            nx=round((ROBOT{8}.dx(end)-ROBOT{8}.dx(1))/ROBOT{8}.resolution);
            ny=round((ROBOT{8}.dy(end)-ROBOT{8}.dy(1))/ROBOT{8}.resolution);
            ROBOT{8}.cost=zeros(nx,ny,'int8');
            
            map1plot=imagesc(ROBOT{8}.x0+ROBOT{8}.dx,ROBOT{8}.y0+ROBOT{8}.dy,ROBOT{8}.cost,[-100 100]);
            colormap(MAGIC_COLORMAP);
            
            xFill=.3*[-1.0 2.5 -1.0 -1.0];
            yFill=.3*[-1.0 0 1.0 -1.0];
            pFill=[xFill; yFill; ones(size(xFill))];
            pose1plot=fill(pFill(1,:),pFill(2,:),'g');
            
        elseif strcmp(cmd,'update')
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
                        ROBOT{8}.pose=robotdat.update;
                        switch robotdat.id
                            case 8
                                x=robotdat.update.x;
                                y=robotdat.update.y;
                                z=robotdat.update.z;
                                yaw=robotdat.update.yaw;
                                plotBot(x,y,yaw,pose1plot,handles.View1Axes);
                            otherwise
                        end
                    case 'IncH'
                        inchdat=deserialize(msgs(i).data);
                        switch inchdat.id
                            case 8
                                xs=double(inchdat.update.xs);
                                ys=double(inchdat.update.ys);
                                cs=double(inchdat.update.cs);
                                xlim=ROBOT{8}.x0+ROBOT{8}.dx;
                                ylim=ROBOT{8}.y0+ROBOT{8}.dy;
                                incHUpdate(xs,ys,cs,xlim,ylim,map1plot,handles.View1Axes);
                            otherwise
                        end
                    case 'IncV'
                        incvdat=deserialize(msgs(i).data);
                        switch inchdat.id
                            case 8
                                xs=double(incvdat.update.xs);
                                ys=double(incvdat.update.ys);
                                cs=double(incvdat.update.cs);
                                xlim=ROBOT{8}.x0+ROBOT{8}.dx;
                                ylim=ROBOT{8}.y0+ROBOT{8}.dy;
                                incHUpdate(xs,ys,cs,xlim,ylim,map1plot,handles.View1Axes);
                            otherwise
                        end
                    case 'Global_Map'
                        globaldat=deserialize(msgs(i).data);
                    otherwise
                end
            end
        end
    end
end

function incHUpdate(xs,ys,cs,xlim,ylim,map1plot,ax)
    global ROBOT
    %% update horizontal lidar cost map\
    map_filter(ROBOT{8}.cost,xlim,ylim,[xs(:) ys(:) cs(:)]',0.3);
    
    if ROBOT{8}.pose.x~=ROBOT{8}.x0 || ROBOT{8}.pose.y~=ROBOT{8}.y0
        [nx,ny]=size(ROBOT{8}.cost);
        x1=[xlim(1):(xlim(end)-xlim(1))/(nx-1):xlim(end)];
        y1=[ylim(1):(ylim(end)-ylim(1))/(ny-1):ylim(end)];
        [xc,yc,sc]=find(ROBOT{8}.cost);
        pc=[x1(xc);y1(yc);double(sc)'];
        ROBOT{8}.x0=ROBOT{8}.pose.x;
        ROBOT{8}.y0=ROBOT{8}.pose.y;
        ROBOT{8}.cost=zeros(nx,ny,'int8');
        map_assign(ROBOT{8}.cost,ROBOT{8}.x0+ROBOT{8}.dx,ROBOT{8}.y0+ROBOT{8}.dy,pc);
    end
    rotangle=ROBOT{8}.pose.yaw*180/pi-90;
    cost=imrotate(ROBOT{8}.cost',rotangle,'crop');
    set(map1plot,'XData',xlim,'YData',ylim,'CData',cost);
end

function plotBot(x,y,yaw,pose1plot,ax)
    %global pose1plot
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
