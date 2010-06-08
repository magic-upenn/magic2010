function motionPlanner()
SetMagicPaths;
clear all;

motionPlannerStart;

while(1)
  ipcReceiveMessages(10);
end



function motionPlannerStart
global MPLANNER GOAL POSE

GOAL = [];
POSE.data = [];

ipcInit;
ipcReceiveSetFcn(GetMsgName('Pose'),                @ipcRecvPoseFcn);
ipcReceiveSetFcn(GetMsgName('ObstacleMap2D_map2d'), @ipcRecvOmapFcn);
ipcReceiveSetFcn(GetMsgName('Goal'),                @ipcRecvGoalFcn);

MPLANNER.trajMsgName = GetMsgName('Traj');
ipcAPIDefine(MPLANNER.trajMsgName);

MPLANNER.initialized = 1;

function ipcRecvGoalFcn(msg,name)
global GOAL

if ~isempty(msg)
  GOAL = deserialize(msg);
end

fprintf(1,'got goal1\n');

function ipcRecvPoseFcn(msg,name)
global POSE

%unpack the message
if ~isempty(msg)
  POSE.data = MagicPoseSerializer('deserialize',msg);
else
  return
end

%run the planner??


function ipcRecvOmapFcn(msg,name)
global POSE OMAP GOAL MPLANNER

if ~isempty(msg)
  OMAP = VisMap2DSerializer('deserialize',msg);
end

if isempty(POSE.data)
  return;
end

if isempty(GOAL)
  return
end

starti = [ceil((POSE.data.x-OMAP.xmin)/OMAP.res);ceil((POSE.data.y-OMAP.ymin)/OMAP.res)];
endi = [ceil((GOAL.waypoints(1).x-OMAP.xmin)/OMAP.res);ceil((GOAL.waypoints(1).y-OMAP.ymin)/OMAP.res)];

map = double(OMAP.map.data')*100+1;
footPrint = ones(10,10);
map = conv2(map,footPrint,'same');

%{
[cost xiPrev yiPrev] = astar2D(map,starti,endi);

traj = zeros(2,10000);
traj(:,1) = endi;
cntr = 1;

while ( (traj(1,cntr) ~= starti(1)) || (traj(2,cntr) ~= starti(2)) )
  %flip the idexes for looking up the previous index in xiPrev and yiPrev
  %(y comes first, since these are in the same form as the map)
  traj(1,cntr+1) = xiPrev(traj(2,cntr),traj(1,cntr));
  traj(2,cntr+1) = yiPrev(traj(2,cntr),traj(1,cntr));
  cntr = cntr+1;
end

trajOut.size = cntr;
for ii=1:cntr
  trajOut.waypoints(ii).x = traj(1,cntr-ii+1)*OMAP.res + OMAP.xmin;
  trajOut.waypoints(ii).y = traj(2,cntr-ii+1)*OMAP.res + OMAP.ymin;
end
ipcAPIPublish(MPLANNER.trajMsgName,serialize(trajOut));
%}


costMap = double(OMAP.map.data)+1;
heuristicMap=dijkstra(costMap,endi,starti);
sizex = OMAP.map.sizex;
sizey = OMAP.map.sizey;
dplanner('initialize',costMap,heuristicMap,[1 sizex 1 1 sizey 1],'collisionProbTable6.dat');

actionTime=1;
dt=0.1;
robot=[starti(1) starti(2) POSE.data.yaw 0 0 endi(1) endi(2)];

[xs ys vs ws]=dplanner('compute',[],robot,actionTime,dt);

plot(xs,ys);
drawnow;

return;


imagesc(map);
set(gca,'ydir','normal');
hold on, plot(traj(1,1:cntr), traj(2,1:cntr), 'g');
hold off;
drawnow;

