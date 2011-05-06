function groundStation(robotId, ip)
global MAP GOAL

%initRobotParam();
MsgNames = initMessagingGC(robotId,ip);
%mapMsgName = ['Robot' robotId '/CMap'];
goalMsgName = ['Robot' robotId '/Goal_Point'];
ipcAPIDefine(goalMsgName);
ipcAPIsubscribe(goalMsgName);
res = 0.05;
xdev = 15;
ydev = 15;

init_map(res,xdev,ydev);

%NikolayGui('gui_OpeningFcn',goalMsgName);

point = meters2cells_cont([0,0],[MAP.xmin,MAP.ymin],MAP.res);
%h = dispMap([]);
figure;
h = imagesc(MAP.map);
colormap gray
hold on
pl = plot(point(1),point(2),'b*');
pth = plot(0,0,'r.');
gl = plot(0,0,'g*');
set(h,'ButtonDownFcn',@sendGoal,'UserData',goalMsgName);


while(1)

    %fprintf('.');
    msgs = ipcAPIReceive(10);
    len = length(msgs);
    %fprintf('got %d messages\n',len);
    if len > 0
        %disp('receiving...');
        for i=1:len
            switch(msgs(i).name)
                
                case MsgNames.cmap
                    CMap = deserialize(msgs(i).data);
                    set(h,'Cdata',CMap.MAP.map);
                    set(pl,'Xdata',CMap.orx,'Ydata',CMap.ory);
                    disp('Received LIDAR map'); 
                case MsgNames.path
                    Path = deserialize(msgs(i).data);
                    set(pth,'Xdata',Path.x,'Ydata',Path.y);
                    disp('Received path');
                case MsgNames.pose
                    Pose = deserialize(msgs(i).data);
                    set(pl,'Xdata',Pose.x,'Ydata',Pose.y);
                case goalMsgName
                    Goal = deserialize(msgs(i).data);
                    set(gl,'Xdata',Goal(1),'Ydata',Goal(2));
                    
                %{
                case MsgNames.imu
                    
                    Imu = MagicImuFilteredSerializer('deserialize',msgs(i).data);
                    
                case MsgNames.lid0
                    Lidar0 = MagicLidarScanSerializer('deserialize',msgs(i).data);
                case MsgNames.lid1
                    Lidar1 = MagicLidarScanSerializer('deserialize',msgs(i).data);
                case MsgNames.ser1
                    Servo1 = MagicServoStateSerializer('deserialize',msgs(i).data);
                %}
                %case MsgNames.hmap
                %    hMap = deserialize(msgs(i).data);
                %    updateMap(hMap);
                %case MsgNames.vmap
                %    vMap = deserialize(msgs(i).data);
                %    updateMap(vMap);
                %case MsgNames.pose
                %    Pose = MagicPoseSerializer('deserialize',msgs(i).data);
                %    %h.pose = plot(axesH,Pose.x,Pose.y,'k*','MarkerSize',5);
                %    cpose = meters2cells_cont([Pose.x,Pose.y],[MAP.xmin,MAP.ymin],MAP.res);
                %    h.pose = drawPose(h.pose,cpose(1),cpose(2),Pose.yaw,10);
                %case MsgNames.path
                %    %disp('Got Path');
                %    Path = deserialize(msgs(i).data);
                %    h.path = drawPathN(h.path,Path);
                %case MsgNames.ctrl
                %    Control = MagicVelocityCmdSerializer('deserialize',msgs(i).data);
            end
        end
    end
    
    % display
    %h = dispMap(h);
    drawnow;
    
end

end

function sendGoal(src,varargin)
global MAP GOAL
[x,y] = ginput(1);

%GOAL = cells2meters([x,y],[MAP.xmin,MAP.ymin],MAP.res);
x = round(x);
y = round(y);
GOAL(1) = x;
GOAL(2) = y;

choice = questdlg('Would you like to specify a goal orientation?',...
    'Choose Orientation',...
'Yes, please!','No, thank you!','No, thank you!');

switch choice
    case 'Yes, please!'
        prompt = {'Enter final yaw in degrees'};
        dlg_title = 'Choose Orientation';
        num_lines = 1;
        def = {'0'};
        answer = inputdlg(prompt,dlg_title,num_lines,def);
        
        [val,status] = str2num(answer{1});
        
        if status
            GOAL(3) = val*pi/180;
            
            fprintf('Setting GOAL at [%d,%d,%f]\n',x,y,val);
        end
    case 'No, thank you!'
        fprintf('Setting GOAL at [%d,%d]\n',x,y);
end

content = serialize(GOAL);
goalMsgName = get(src,'UserData');
ipcAPIPublish(goalMsgName,content);
end
