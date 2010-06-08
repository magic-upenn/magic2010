function planner_GUI
setup_IPC();
while(1)
    ipcReceiveMessages(100);
    pause(.1);
end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize trajectory follower process
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setup_IPC
clear all;
global TRAJ POSE GPFULL GPTRAJ
SetMagicPaths;

TRAJ.traj = [];
TRAJ.handle = -1;
POSE.data = [];
POSE.handle = -1;
POSE.handle2 = -1;
GPFULL.data = [];
GPFULL.data.sent_cost_x = -1;
GPFULL.data.sent_cost_y = -1;
GPFULL.handle = -1;
GPFULL.data.UTM_x = 0;
GPFULL.data.UTM_y = 0;
GPFULL.res = 0.05;
GPFULL.robotsize = .355;
GPFULL.temp = 5/GPFULL.res;
GPTRAJ.data = [];
GPTRAJ.handle = -1;

figure(1);
hold on;

%connect to ipc on localhost
ipcInit('localhost');
ipcReceiveSetFcn('Global_Planner_Position_Update',        @PoseHandler);
ipcAPISetMsgQueueLength(GetMsgName('Global_Planner_Position_Update'), 1);

%ipcReceiveSetFcn(GetMsgName('Trajectory'),  @TrajHandler);
%ipcAPISetMsgQueueLength(GetMsgName('Trajectory'), 1);

ipcReceiveSetFcn('Global_Planner_Trajectory', @GPTRAJHandler);
ipcAPISetMsgQueueLength('Global_Planner_Trajectory', 1);

ipcReceiveSetFcn('Global_Planner_Full_Update', @GPFULLHandler);
ipcAPISetMsgQueueLength('Global_Planner_Full_Update', 1);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Message handler for a new trajectory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function TrajHandler(data,name)
global TRAJ GPFULL

fprintf(1,'got traj message\n');
TRAJ.traj = MagicMotionTrajSerializer('deserialize',data);
TRAJ.itraj   = 1;   %reset the current waypoint
if (TRAJ.traj.size > 0)
    if (TRAJ.handle ~= -1)
        delete(TRAJ.handle);
    end
    figure(1)
    hold on;
    temp = zeros(TRAJ.traj.size,2);
    for i=1:size(temp,1)
        temp(i,1) = (TRAJ.traj.waypoints(i).x-GPFULL.data.UTM_x)/GPFULL.res;
        temp(i,2) = (TRAJ.traj.waypoints(i).y-GPFULL.data.UTM_y)/GPFULL.res;
    end
    TRAJ.handle = plot(temp(:,2),temp(:,1), 'r-');
    drawnow;
end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Pose Handler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function PoseHandler(data,name)
global POSE GPFULL
t=1:100;
pts = (GPFULL.robotsize/GPFULL.res)*[sin(2*t*pi/100); cos(2*t*pi/100)]';


%fprintf(1,'got pose message\n');
if ~isempty(data)
    POSE.data = MagicGP_POSITION_UPDATESerializer('deserialize',data);
    POSE.data.yaw = POSE.data.theta;
    
    if(POSE.handle ~= -1)
        delete(POSE.handle);
        delete(POSE.handle2);
    end
    temp = (POSE.data.x-GPFULL.data.UTM_x)/GPFULL.res;
    POSE.data.x = (POSE.data.y-GPFULL.data.UTM_y)/GPFULL.res;
    POSE.data.y = temp;
    figure(1)
    hold on;
    %POSE.handle = plot(POSE.data.x,POSE.data.y,'bx');
    POSE.handle = patch(pts(:,1)+POSE.data.x, pts(:,2)+POSE.data.y, [1 0 0]);
    POSE.handle2 = plot([POSE.data.x POSE.data.x+(GPFULL.robotsize/GPFULL.res)*sin(POSE.data.yaw)], [POSE.data.y POSE.data.y+(GPFULL.robotsize/GPFULL.res)*cos(POSE.data.yaw)], 'LineWidth', 5);
    temp = GPFULL.temp;
    axis([POSE.data.x-temp POSE.data.x+temp POSE.data.y-temp POSE.data.y+temp]);
    drawnow;
    
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% message handler for a new GPTRAJ
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function GPTRAJHandler(data,name)

global GPTRAJ GPFULL POSE

fprintf(1,'got GPTRAJ message\n');

if ~isempty(data)
    GPTRAJ.data = MagicGP_TRAJECTORYSerializer('deserialize',data);
    if(GPTRAJ.data.num_traj_pts > 0)
        if(GPTRAJ.handle ~= -1)
            delete(GPTRAJ.handle);
        end
        figure(1)
        hold on;
        size(GPTRAJ.data.traj_array)
        GPTRAJ.data.traj_array = reshape(GPTRAJ.data.traj_array, 6, [])';
        %(GPTRAJ.data.traj_array(1:10,1)-GPFULL.data.UTM_x)/GPFULL.res
        %(GPTRAJ.data.traj_array(1:10,2)-GPFULL.data.UTM_y)/GPFULL.res
        GPTRAJ.handle = plot((GPTRAJ.data.traj_array(:,2)-GPFULL.data.UTM_x)/GPFULL.res,(GPTRAJ.data.traj_array(:,1)-GPFULL.data.UTM_y)/GPFULL.res,'g-');
        %temp(1,1:2)
        temp = GPFULL.temp;
        if(~isempty(POSE.data))
          axis([POSE.data.x-temp POSE.data.x+temp POSE.data.y-temp POSE.data.y+temp]);
        end
        drawnow;
    end
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Map handler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function GPFULLHandler(data,name)

global GPFULL POSE TRAJ GPTRAJ

fprintf(1,'got GPFULL message\n');
old_size_x = GPFULL.data.sent_cost_x;
old_size_y = GPFULL.data.sent_cost_y;

if ~isempty(data)
    GPFULL.data = MagicGP_FULL_UPDATESerializer('deserialize',data);
%     if(GPFULL.handle ~= -1)
%         delete(GPFULL.handle);
%     end
    figure(1)
    %{
    clf;
    POSE.handle = -1;
    TRAJ.handle = -1;
    GPTRAJ.handle = -1;
    %}
    costmap = reshape(GPFULL.data.cost_map,GPFULL.data.sent_cost_x,GPFULL.data.sent_cost_y);
    costmap = 250-costmap;
    covermap = reshape(GPFULL.data.coverage_map, GPFULL.data.sent_cover_x, GPFULL.data.sent_cover_y);
    covermap = (249-covermap)/2;
    map = costmap - covermap;
    %map = fliplr(map);
    if(old_size_x ~= GPFULL.data.sent_cost_x || old_size_y ~= GPFULL.data.sent_cost_y)
      GPFULL.handle = imagesc(map);
    else
      set(GPFULL.handle,'CData',map);
    end
    axis xy equal;
    set(gca,'Xdir','reverse');
    colormap gray;
    temp = GPFULL.temp;
    if(~isempty(POSE.data))
      axis([POSE.data.x-temp POSE.data.x+temp POSE.data.y-temp POSE.data.y+temp]);
    end
    drawnow;
    
end
end



