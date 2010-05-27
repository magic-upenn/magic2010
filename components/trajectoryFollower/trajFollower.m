function trajFollower(tUpdate)

if nargin < 1,
  tUpdate = 0.001;
end

trajFollowerStart;

loop = 1;
while (loop),
  pause(tUpdate);
  trajFollowerUpdate;
end

trajFollowerStop;


function trajFollowerStart
clear all;
global TRAJ POSE
SetMagicPaths;

TRAJ.traj = [];
POSE.data = [];

%connect to ipc
ipcInit;
ipcReceiveSetFcn(GetMsgName('Pose'),        @ipcRecvPoseFcn);
ipcReceiveSetFcn(GetMsgName('Traj'),        @ipcRecvTrajFcn);

function ipcRecvTrajFcn(msg)
global TRAJ

fprintf(1,'got traj message\n');
TRAJ.traj = deserialize(msg);
TRAJ.itraj   = 1;

function ipcRecvPoseFcn(msg)

global POSE

if ~isempty(msg)
  POSE.data = MagicPoseSerializer('deserialize',msg);
end

trajFollowerFollow;

function trajFollowerUpdate
ipcReceiveMessages;


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

proximityThreshold = 0.05; %meters

while(di < proximityThreshold)
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
wgain = 1;  % need to tune this!!

vdes=V(1)*vgain;
wdes=V(2)*wgain;

vmax = 0.2;  %m/s
wmax = 0.3; %(30/180*pi);  %rad/s

kv=abs(vdes/vmax);
kw=abs(wdes/wmax);
k=max(kv,kw);
  
if k > 1
  vdes=vdes/k;
  wdes=wdes/k;
end

fprintf(1,'sending vels %f %f\n',vdes,wdes);

%send out velocity
SetVelocity(vdes,wdes);











