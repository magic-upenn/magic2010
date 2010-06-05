function slam(addr,id)
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
ipcReceiveSetFcn(GetMsgName('Lidar1'),      @slamProcessLidar1);
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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Lidar0 message handler (horizontal lidar)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check imu status
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ret = CheckImu()
global IMU SLAM

if isempty(IMU), ret=0; return, end
if ~isfield(IMU,'data'), ret=0; return, end
if ~isfield(IMU.data,'t'), ret=0; return, end

%{
if (IMU.data.t - GetUnixTime() > SLAM.imuTimeout)
  ret=0;
  return;
end
%}
ret=1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check lidar0 status
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ret = CheckLidar0()
global LIDAR0 SLAM

if isempty(LIDAR0), ret=0; return, end
if ~isfield(LIDAR0,'scan'), ret=0; return, end
if ~isfield(LIDAR0.scan,'startTime'), ret=0; return, end
%{
if (LIDAR0.scan.startTime - GetUnixTime() > SLAM.lidar0Timeout)
  ret=0;
  return;
end
%}
ret=1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check lidar1 status
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ret = CheckLidar1()
global LIDAR1 SLAM

if isempty(LIDAR1), ret=0; return, end
if ~isfield(LIDAR1,'scan'), ret=0; return, end
if ~isfield(LIDAR1.scan,'startTime'), ret=0; return, end
%{
if (LIDAR1.scan.startTime - GetUnixTime() > SLAM.lidar1Timeout)
  ret=0;
  return;
end
%}
ret=1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check servo1 status
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ret = CheckServo1()
global SERVO1 SLAM

if isempty(SERVO1), ret=0; return, end
if ~isfield(SERVO1,'data'), ret=0; return, end
if ~isfield(SERVO1.data,'t'), ret=0; return, end

%{
if (SERVO1.data.t - GetUnixTime() > SLAM.servo1Timeout)
  ret=0;
  return;
end
%}

ret=1;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Servo1 message handler 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function slamProcessServo1(data,name)
global SERVO1

SERVO1.data = MagicServoStateSerializer('deserialize',data);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Lidar1 message handler (vertical lidar)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function slamProcessLidar1(data,name)
global SLAM LIDAR1 SERVO1 OMAP CMAP EMAP POSE IMU DVMAP

if ~isempty(data)
  LIDAR1.scan = MagicLidarScanSerializer('deserialize',data);
else
  return;
end

%make sure we have fresh data
if (CheckImu() ~= 1), return; end
if (CheckServo1() ~= 1), return; end
servoAngle = SERVO1.data.position + 3/180*pi;
Tservo1 = trans([SERVO1.offsetx SERVO1.offsety SERVO1.offsetz])*rotz(servoAngle);
Tlidar1 = trans([LIDAR1.offsetx LIDAR1.offsety LIDAR1.offsetz]) * ...
          rotx(pi/2);
Timu = roty(IMU.data.pitch)*rotx(IMU.data.roll);
Tpos = trans([SLAM.x SLAM.y SLAM.z])*rotz(SLAM.yaw);

T = (Tpos*Timu*Tservo1*Tlidar1);
        
nStart = 250; %throw out points that pick up our own body
ranges = double(LIDAR1.scan.ranges); %convert from float to double
indGood = ranges >0.25;
indGood(1:nStart-1) = 0;

rangesGood = ranges(indGood);

xs = rangesGood.*LIDAR1.cosines(indGood);
ys = rangesGood.*LIDAR1.sines(indGood);
zs = zeros(size(xs));

xsg=xs;
ysg=ys;
zsg=zs;
onesg=ones(size(xsg));

%apply the transformation given current roll and pitch

X = [xsg; ysg; zsg; onesg];
Y=T*X;

%in body
xss = Y(1,:);
yss = Y(2,:);
zss = Y(3,:);
onez = ones(size(xss));

LIDAR1.xs = xss;
LIDAR1.ys = yss;

%publishVisPointCloud('lidar1map',xss,yss,zss);

xis = ceil((xss - OMAP.xmin) * OMAP.invRes);
yis = ceil((yss - OMAP.ymin) * OMAP.invRes);

zmax = 0.8;

indGood = (xis > 1) & (yis > 1) & (xis < OMAP.map.sizex) & (yis < OMAP.map.sizey) & (zss<zmax);
inds = sub2ind(size(OMAP.map.data),xis(indGood),yis(indGood));

cellChange = diff(inds);
newCellLogic = cellChange ~=0;
cellChangeInds  = [1 find(newCellLogic)];

nCells = length(cellChangeInds);
nCounts = zeros(1,length(inds));

xsGood = xss(indGood);
ysGood = yss(indGood);
zsGood = zss(indGood);
rsGood = rangesGood(indGood);


indsBadLogic = logical(zeros(size(inds)));

zMinPrev = 0;
zMaxPrev = 0;
xPrev = 0;
yPrev = 0;

angles = zeros(1,nCells-1);

inc=1;
for ii=1:nCells-inc
    zsc = zsGood(cellChangeInds(ii):cellChangeInds(ii+inc));
    nCounts(cellChangeInds(ii):cellChangeInds(ii+inc)) = cellChangeInds(ii+inc)-cellChangeInds(ii);
    minCurr = min(zsc);
    maxCurr = max(zsc);
    minMax = abs(maxCurr - minCurr);
    
    if (minMax > 0.06)
        indsBadLogic(cellChangeInds(ii):cellChangeInds(ii+inc)) = 1;
    end
    
    
    xCurr  = xsGood(cellChangeInds(ii));
    yCurr  = ysGood(cellChangeInds(ii));
    rCurr  = rsGood(cellChangeInds(ii));
    
    if (ii>1)
        z1 = abs(maxCurr-zMinPrev);
        z2 = abs(zMaxPrev-minCurr);
        vert = max([z1,z2]);
        dist = norm([xCurr-xPrev; yCurr-yPrev]);
        angle = atan2(vert,dist);
        dr = abs(rCurr-rPrev);
        
        %angles(ii) = vert; %angle/pi*180;
        
        if ((dr > 0.07) && (abs(angle) > 20/180*pi))
            indsBadLogic(cellChangeInds(ii):cellChangeInds(ii+inc)) = 1;
        end
    end
    
    zMinPrev = minCurr;
    zMaxPrev = maxCurr;
    xPrev    = xCurr;
    yPrev    = yCurr;
    rPrev    = rCurr;
end

%plot(angles); drawnow;

indsBad = inds(indsBadLogic);
%indsBad = inds(indsBadLogic);

%CMAP.map.data(indsBad) = CMAP.map.data(indsBad) + SLAM.cMapIncObs;
firstBad = find(indsBadLogic,1);

indsGoodLogicInds = 1:firstBad-1;
indsGood = inds(indsGoodLogicInds);

%dzs = [diff(zss) 0];
%indsBad = abs(dzs) > 0.05;
%indsBad = zss(indGood) > 0.05;
CMAP.map.data(indsBad) = CMAP.map.data(indsBad) + nCounts(indsBadLogic).*SLAM.cMapIncObs;
CMAP.map.data(indsGood) = CMAP.map.data(indsGood) + nCounts(indsGoodLogicInds)*SLAM.cMapIncFree;

%czs = ones(size(dzs)) * SLAM.cMapIncFree;
%czs = zeros(size(dzs));
%czs(1:firstBad-1) = SLAM.cMapIncFree;
%CMAP.map.data(inds)=CMAP.map.data(inds)+czs;

%czs(indsBad) = SLAM.cMapIncObs;

%CMAP.map.data(inds)=CMAP.map.data(inds)+czs;

%make sure that the costs stay bounded
tooLarge = CMAP.map.data(inds) > SLAM.maxCost;
tooSmall = CMAP.map.data(inds) < SLAM.minCost;
CMAP.map.data(inds(tooLarge)) = SLAM.maxCost;
CMAP.map.data(inds(tooSmall)) = SLAM.minCost;

%mark the cells as modified
DVMAP.map.data(indsBad)  = 1;
DVMAP.map.data(indsGood) = 1;







