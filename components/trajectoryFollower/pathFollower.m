
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Simple trajectory follower
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function trajFollower(tUpdate)
tic
if nargin < 1,
  tUpdate = 0.05;
end

trajFollowerStart;

loop = 1;
while (loop),
  %pause(tUpdate);
  trajFollowerUpdate;
end

trajFollowerStop;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize trajectory follower process
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function trajFollowerStart
clear all;
global TRAJ POSE
SetMagicPaths;

TRAJ.traj = [];
TRAJ.handle = -1;
POSE.data = [];
POSE.handle = -1;
figure(1);
hold on;

%connect to ipc on localhost
ipcInit;
ipcReceiveSetFcn(GetMsgName('Pose'),        @ipcRecvPoseFcn);
ipcReceiveSetFcn(GetMsgName('Trajectory'),  @ipcRecvTrajFcn);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Message handler for a new trajectory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ipcRecvTrajFcn(data,name)
global TRAJ

fprintf(1,'got traj message\n');
TRAJ.traj = MagicMotionTrajSerializer('deserialize',data);
TRAJ.itraj   = 1;   %reset the current waypoint
%{
if(TRAJ.traj.size > 0)
  if(TRAJ.handle ~= -1)
      delete(TRAJ.handle);
  end
  figure(1)
  hold on;
  temp = zeros(TRAJ.traj.size,2);
  for i=1:size(temp,1)
      temp(i,1) = TRAJ.traj.waypoints(i).x;
      temp(i,2) = TRAJ.traj.waypoints(i).y;
  end
  TRAJ.handle = plot(temp(:,1),temp(:,2));
  drawnow;
end
%}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Receive and handle ipc messages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function trajFollowerUpdate
ipcReceiveMessages(50);

function ipcRecvPoseFcn(data,name)

global POSE

if ~isempty(data)
  POSE.data = MagicPoseSerializer('deserialize',data);
  %{
  if(POSE.handle ~= -1)
    delete(POSE.handle);
  end
  figure(1)
  hold on;
  POSE.handle = plot(POSE.data.x,POSE.data.y,'bx');
  temp = 20;
  axis([POSE.data.x-temp POSE.data.x+temp POSE.data.y-temp POSE.data.y+temp]);
  drawnow;
  %}
end
dt = toc;
tic
if (dt>0.1)
    fprintf(1,'large delay!!!!!!\n');
end
trajFollowerFollow;




function trajFollowerFollow
global TRAJ POSE

if isempty(TRAJ.traj) || isempty(POSE.data) || TRAJ.traj.size < 1
  return
end

traj = TRAJ.traj;
pose = POSE.data;

%find the closest point
minDist = inf;
minInd  = TRAJ.itraj;


%first find the closest point 
for pp=minInd:traj.size
  dist = norm([traj.waypoints(pp).x-pose.x, traj.waypoints(pp).y-pose.y]);

  if (dist < minDist)
    minDist = dist;
    minInd=pp;
  else
      break
  end
end

TRAJ.itraj = minInd;
fprintf(1,'traj index %d\n',TRAJ.itraj);



%now throw out points that are too close
%calculate distance to the next path point
di = norm([traj.waypoints(TRAJ.itraj).x-pose.x, traj.waypoints(TRAJ.itraj).y-pose.y]);

proximityThreshold = 0.11; %meters

while(di < proximityThreshold && TRAJ.itraj < TRAJ.traj.size)
  TRAJ.itraj = TRAJ.itraj +1;
  di = norm([traj.waypoints(TRAJ.itraj).x-pose.x, traj.waypoints(TRAJ.itraj).y-pose.y]);
end

xdes = traj.waypoints(TRAJ.itraj).x;
ydes = traj.waypoints(TRAJ.itraj).y;

%set(TRAJ.hNext,'xdata',xdes,'ydata',ydes);

L=0.1;
V = [cos(pose.yaw) sin(pose.yaw); -sin(pose.yaw)/L cos(pose.yaw)/L] * ...
    [xdes-pose.x; ydes-pose.y];

vgain = 10;
wgain = 3;  % need to tune this!!

vdes=V(1)*vgain;
wdes=V(2)*wgain;

vmax = 0.4;  %m/s
wmax = 0.5; %(30/180*pi);  %rad/s

kv=abs(vdes/vmax);
kw=abs(wdes/wmax);
k=max(kv,kw);
  
if k > 1
  vdes=vdes/k;
  wdes=wdes/k;
end

if minDist < 0.1
    vdes = 0;
    wdes = 0;
end

fprintf(1,'sending vels %f %f\n',vdes,wdes);

%send out velocity
SetVelocity(vdes,wdes);











