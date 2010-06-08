function slam(addr,id)
global SLAM SPREAD

if nargin < 1
  SLAM.addr = 'localhost';
else
  SLAM.addr = addr;
end

if nargin >1
  setenv('ROBOT_ID',sprintf('%d',id));
end

SPREAD.useSpread = 0;

slamStart;

while(1)
  slamUpdate;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize slam process
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function slamStart
global SLAM OMAP POSE SPREAD LIDAR0

SetMagicPaths;

%ipcAPIHandle = @ipcAPI;
ipcAPIHandle = @ipcWrapperAPI; %use threaded version

ipcInit(SLAM.addr,ipcAPIHandle);

if (SPREAD.useSpread)
  spreadInit;
end

SLAM.updateExplorationMap    = 0;
SLAM.explorationUpdatePeriod = 5;
SLAM.plannerUpdatePeriod     = 2;

SLAM.explorationUpdateTime   = GetUnixTime();
SLAM.plannerUpdateTime       = GetUnixTime();
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

SLAM.cMapIncFree = -5;
SLAM.cMapIncObs  = 10;
SLAM.maxCost     = 100;
SLAM.minCost     = -100;

%initialize maps
initMapProps;
omapInit;        %localization map
emapInit;        %exploration map ??
cmapInit;        %vertical lidar map
dvmapInit;       %vertical lidar delta map
dhmapInit;       %horizontal lidar delta map

%initialize data structures
imuInit;
lidar0Init;
lidar1Init;
servo1Init;
motorsInit;

%define messages
DefineSensorMessages;
DefinePlannerMessages;

if checkVis
  DefineVisMsgs;
end

%assign the message handlers
%arguments are (msgName, function handle, ipcAPI handle, queue length)
ipcReceiveSetFcn(GetMsgName('Lidar0'),      @slamProcessLidar0,   ipcAPIHandle,5);
ipcReceiveSetFcn(GetMsgName('Lidar1'),      @slamProcessLidar1_2, ipcAPIHandle,5);
ipcReceiveSetFcn(GetMsgName('Servo1'),      @slamProcessServo1,   ipcAPIHandle,5);
ipcReceiveSetFcn(GetMsgName('Encoders'),    @slamProcessEncoders, ipcAPIHandle,5);
ipcReceiveSetFcn(GetMsgName('ImuFiltered'), @ipcRecvImuFcn,       ipcAPIHandle,5);

%initialize scan matching function
ScanMatch2D('setBoundaries',OMAP.xmin,OMAP.ymin,OMAP.xmax,OMAP.ymax);
ScanMatch2D('setResolution',OMAP.res);
ScanMatch2D('setSensorOffsets',[LIDAR0.offsetx LIDAR0.offsety LIDAR0.offsetz]);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Receive and handle ipc messages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function slamUpdate
ipcReceiveMessages;

