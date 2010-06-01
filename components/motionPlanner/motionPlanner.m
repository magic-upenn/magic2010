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

function ipcRecvGoalFcn(msg)
global GOAL

if ~isempty(msg)
  GOAL = deserialize(msg);
end

function ipcRecvPoseFcn(msg)
global POSE

%unpack the message
if ~isempty(msg)
  POSE.data = MagicPoseSerializer('deserialize',msg);
else
  return
end

%run the planner??


function ipcRecvOmapFcn(msg)
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

imagesc(map);
set(gca,'ydir','normal');
hold on, plot(traj(1,1:cntr), traj(2,1:cntr), 'g');
hold off;
drawnow;

