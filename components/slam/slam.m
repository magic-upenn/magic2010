function slam(addr,id)
clear all;

global SLAM;

if nargin < 1
  SLAM.addr = 'localhost';
else
  SLAM.addr = addr;
end

if nargin >1
  setenv('ROBOT_ID',sprintf('%d',id));
end

slamStart;

while(1)
  slamUpdate;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize slam process
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function slamStart
global SLAM OMAP POSE TRAJ

SetMagicPaths;
ipcInit(SLAM.addr);

SLAM.updateExplorationMap = 0;
SLAM.explorationUpdatePeriod = 5;
SLAM.plannerUpdatePeriod = 2;

SLAM.explorationUpdateTime = GetUnixTime();
SLAM.plannerUpdateTime = GetUnixTime();
poseInit();

SLAM.x            = POSE.xInit;
SLAM.y            = POSE.yInit;
SLAM.z            = POSE.zInit;
SLAM.yaw          = POSE.data.yaw;
SLAM.lidar0Cntr   = 0;
SLAM.lidar1Cntr   = 0;

SLAM.IncMapUpdateHMsgName = GetMsgName('IncMapUpdateH');
SLAM.IncMapUpdateVMsgName = GetMsgName('IncMapUpdateV');
ipcAPIDefine(SLAM.IncMapUpdateHMsgName);
ipcAPIDefine(SLAM.IncMapUpdateVMsgName);

SLAM.xOdom        = SLAM.x;
SLAM.yOdom        = SLAM.y;
SLAM.yawOdom      = SLAM.yaw;

TRAJ.cntr         = 0;
TRAJ.traj         = zeros(4,100000);
TRAJ.hTraj        = [];

%initialize the pose struct so that the maps are initialized around the initial pose
%in future, this should be the start UTM coordinate!!


SLAM.imuTimeout    = 0.2;
SLAM.lidar0Timeout = 0.2;
SLAM.lidar1Timeout = 0.2;
SLAM.servo1Timeout = 0.2;

SLAM.cMapIncFree = -5;
SLAM.cMapIncObs  = 10;
SLAM.maxCost     = 100;
SLAM.minCost     = -100;


initMapProps;
omapInit;
emapInit;
cmapInit;
dvmapInit;
dhmapInit;
lidar0Init;
lidar1Init;
servo1Init;
motorsInit;
DefineVisMsgs;
DefineSensorMessages;
DefinePlannerMessages;

%assign the message handlers
ipcReceiveSetFcn(GetMsgName('Pose'),        @ipcRecvPoseFcn);
ipcReceiveSetFcn(GetMsgName('Lidar0'),      @slamProcessLidar0);
ipcReceiveSetFcn(GetMsgName('Lidar1'),      @slamProcessLidar1_1);
ipcReceiveSetFcn(GetMsgName('Servo1'),      @slamProcessServo1);
ipcReceiveSetFcn(GetMsgName('Encoders'),    @slamProcessEncoders);
ipcReceiveSetFcn(GetMsgName('ImuFiltered'), @ipcRecvImuFcn);



%publish initial maps
PublishObstacleMap;
%PublishExplorationMap;

ScanMatch2D('setBoundaries',OMAP.xmin,OMAP.ymin,OMAP.xmax,OMAP.ymax);
ScanMatch2D('setResolution',OMAP.res);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Receive and handle ipc messages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function slamUpdate
ipcReceiveMessages;


