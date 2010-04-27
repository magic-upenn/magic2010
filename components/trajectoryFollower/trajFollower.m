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
addpath( [ getenv('VIS_DIR') '/ipc' ] )
addpath ../../matlab/Serialization/
addpath ../MotorController/


robotIdStr = getenv('ROBOT_ID');
if isempty(robotIdStr)
  error('robot id is not defined in an environment variable');
end

figure(1), clf(gcf);
hold on;
TRAJ.hTraj = plot(0,0,'b');
TRAJ.hNext = plot(0,0,'b*');
POSE.hPose = plot(0,0,'r*');
hold off;
drawnow;

TRAJ.traj = [];
POSE.pose = [];

%connect to ipc
TRAJ.ipcMsgName = ['Robot' robotIdStr '/Trajectory'];
POSE.ipcMsgName = ['Robot' robotIdStr '/Pose'];
ipcAPIConnect();
ipcAPISubscribe(TRAJ.ipcMsgName);
ipcAPISubscribe(POSE.ipcMsgName);



function trajFollowerUpdate
global TRAJ POSE
msgs = ipcAPIReceive(25);
len = length(msgs);
if len > 0
  for i=1:len
    msg = msgs(i);
    switch msg.name
      case TRAJ.ipcMsgName
        fprintf(1,'got traj message\n');
        TRAJ.traj    = MagicMotionTrajSerializer('deserialize',msg.data);
        TRAJ.itraj   = 1;
        
        if (TRAJ.traj.size == 0)
          fprintf(1,'traj is empty!!!\n');
        end
        
        trajLen=TRAJ.traj.size;
        xs = zeros(trajLen,1);
        ys = zeros(trajLen,1);
        for j=1:trajLen
            xs(j) = TRAJ.traj.waypoints(j).x;
            ys(j) = TRAJ.traj.waypoints(j).y;
        end
        
        set(TRAJ.hTraj,'xdata',xs,'ydata',ys');
        drawnow;
        
        
      
      case POSE.ipcMsgName
        fprintf(1,'got pose message\n');
        POSE.pose    = MagicPoseSerializer('deserialize',msg.data);
        
        set(POSE.hPose,'xdata',POSE.pose.x,'ydata',POSE.pose.y);
        drawnow;
          
      otherwise
        fprintf(1,'got unknown message type: %s \n',msg.name);
    end
  end
end

trajFollowerFollow;




function trajFollowerFollow
global TRAJ POSE

if isempty(TRAJ.traj) || isempty(POSE.pose) || TRAJ.traj.size < 1
  return
end

traj = TRAJ.traj;
pose = POSE.pose;

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

set(TRAJ.hNext,'xdata',xdes,'ydata',ydes);

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











