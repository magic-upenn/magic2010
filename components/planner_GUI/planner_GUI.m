function planner_GUI
setup_IPC();
while(1)
    ipcReceiveMessages(50);
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
GPFULL.data = [];
GPFULL.handle = -1;
GPTRAJ.data = [];
GPTRAJ.handle = -1;

figure(1);
hold on;

%connect to ipc on localhost
ipcInit;
ipcReceiveSetFcn(GetMsgName('Pose'),        @PoseHandler);
ipcAPISetMsgQueueLength(GetMsgName('Pose'), 1);

ipcReceiveSetFcn(GetMsgName('Trajectory'),  @TrajHandler);
ipcAPISetMsgQueueLength(GetMsgName('Trajectory'), 1);

ipcReceiveSetFcn('Global_Planner_Trajectory', @GPTRAJHandler);
ipcAPISetMsgQueueLength('Global_Planner_Trajectory', 1);

ipcReceiveSetFcn('Global_Planner_Full_Update', @GPFULLHandler);
ipcAPISetMsgQueueLength('Global_Planner_Full_Update', 1);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Message handler for a new trajectory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function TrajHandler(data,name)
global TRAJ

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
        temp(i,1) = TRAJ.traj.waypoints(i).x;
        temp(i,2) = TRAJ.traj.waypoints(i).y;
    end
    TRAJ.handle = plot(temp(:,1),temp(:,2), 'r-');
    drawnow;
end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Pose Handler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function PoseHandler(data,name)

global POSE
fprintf(1,'got pose message\n');
if ~isempty(data)
    POSE.data = MagicPoseSerializer('deserialize',data);
    
    if(POSE.handle ~= -1)
        delete(POSE.handle);
    end
    figure(1)
    hold on;
    POSE.handle = plot(POSE.data.x,POSE.data.y,'bx');
    temp = 20;
    axis([POSE.data.x-temp POSE.data.x+temp POSE.data.y-temp POSE.data.y+temp]);
    drawnow;
    
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% message handler for a new GPTRAJ
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function GPTRAJHandler(data,name)

global GPTRAJ

fprintf(1,'got GPTRAJ message\n');

if ~isempty(data)
    GPTRAJ.data = MagicGP_TRAJECTORYSerializer('deserialize',data);
    
    if(GPTRAJ.handle ~= -1)
        delete(GPTRAJ.handle);
    end
    figure(1)
    hold on;
    GPTRAJ.handle = plot(GPTRAJ.data.x,GPTRAJ.data.y,'g-');
    temp = 20;
    axis([POSE.data.x-temp POSE.data.x+temp POSE.data.y-temp POSE.data.y+temp]);
    drawnow;
    
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Map handler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function GPFULLHandler(data,name)

global GPFULL

fprintf(1,'got GPFULL message\n');

if ~isempty(data)
    GPFULL.data = MagicGP_FULL_UPDATESerializer('deserialize',data);
%     if(GPFULL.handle ~= -1)
%         delete(GPFULL.handle);
%     end
    figure(1)
    clf;
    GPFULL.handle = image(GPFULL.data);
    temp = 20;
    axis([POSE.data.x-temp POSE.data.x+temp POSE.data.y-temp POSE.data.y+temp]);
    drawnow;
    
end
end



