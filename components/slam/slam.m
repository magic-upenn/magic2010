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
SLAM.explorationUpdateTime = GetUnixTime();
SLAM.plannerUpdateTime = GetUnixTime();
poseInit();

SLAM.x            = POSE.xInit;
SLAM.y            = POSE.yInit;
SLAM.z            = POSE.zInit;
SLAM.yaw          = POSE.data.yaw;
SLAM.lidar0Cntr   = 0;
SLAM.lidar1Cntr   = 0;

SLAM.MapIncUpdateMsgName = GetMsgName('MapIncUpdate');
ipcAPIDefine(SLAM.MapIncUpdateMsgName);

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


omapInit;
emapInit;
cmapInit;
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
function slamProcessLidar0(data,name)
global SLAM LIDAR0 OMAP EMAP POSE IMU TRAJ CMAP

if ~isempty(data)
  LIDAR0.scan = MagicLidarScanSerializer('deserialize',data);
else
  return;
end

%wait for an initial imu message
if isempty(IMU)
  return
end
  
SLAM.lidar0Cntr = SLAM.lidar0Cntr+1;

%fprintf(1,'got lidar scan\n');
if (mod(SLAM.lidar0Cntr,40) == 0)
  fprintf(1,'.');
  %toc,tic
end
  
ranges = double(LIDAR0.scan.ranges)'; %convert from float to double
indGood = ranges >0.25;

xs = ranges.*LIDAR0.cosines;
ys = ranges.*LIDAR0.sines;
zs = zeros(size(xs));
xsg=xs(indGood);
ysg=ys(indGood);
zsg=zs(indGood);
onesg=ones(size(xsg));

%apply the transformation given current roll and pitch
T = (roty(IMU.data.pitch)*rotx(IMU.data.roll))';
X = [xsg ysg zsg onesg];
Y=X*T;  %reverse the order because of transpose


%don't use the points that supposedly hit the ground (check!!)
indGood = Y(:,3) > -0.3;

%in sensor frame
xsss = Y(indGood,1);
ysss = Y(indGood,2);
zsss = Y(indGood,3);
onez = ones(size(xsss));

LIDAR0.xs = xsss;
LIDAR0.ys = ysss;


%number of poses in each dimension to try
nyaw= 5;
nxs = 5;
nys = 5;


yawRange = floor(nyaw/2);
xRange   = floor(nxs/2);
yRange   = floor(nys/2);

%resolution of the candidate poses
dyaw = 0.1/180.0*pi;
dx   = 0.01;
dy   = 0.01;

%create the candidate locations in each dimension
aCand = (-yawRange:yawRange)*dyaw+SLAM.yaw + IMU.data.wyaw*0.025;
xCand = (-xRange:xRange)*dx+SLAM.xOdom;
yCand = (-yRange:yRange)*dy+SLAM.yOdom;

offsetsx = LIDAR0.offsetx*cos(aCand) - LIDAR0.offsety*sin(aCand);
offsetsy = LIDAR0.offsetx*sin(aCand) + LIDAR0.offsety*cos(aCand);


%get a local 3D sampling of pose likelihood
hits = ScanMatch2D('match',OMAP.map.data,xsss,ysss, ...
              xCand+offsetsx,yCand+offsetsy,aCand);

%find maximum
[hmax imax] = max(hits(:));
[kmax mmax jmax] = ind2sub([nxs,nys,nyaw],imax);

if (SLAM.lidar0Cntr > 1)
  
  %extract the 2D slice of xy poses at the best angle
  hitsXY = hits(:,:,jmax);
  
  %create a grid of distance-based costs from each cell to odometry pose
  [yGrid xGrid] = meshgrid(yCand,xCand);
  xDiff = xGrid - SLAM.xOdom;
  yDiff = yGrid - SLAM.yOdom;
  distGrid = sqrt(xDiff.^2 + yDiff.^2);
  
  %combine the pose likelihoods with the distance from odometry prediction
  %TODO: play around with the weights!!
  costGrid = distGrid - hitsXY;
  
  %find the minimum and save the new pose
  [cmin cimin] = min(costGrid(:));
  
  %save the best pose
  SLAM.yaw = aCand(jmax);
  SLAM.x   = xGrid(cimin);
  SLAM.y   = yGrid(cimin);
  
end

%send out pose message
ipcAPIPublishVC(POSE.msgName,MagicPoseSerializer('serialize',POSE.data));

%update the map
T = (trans([SLAM.x SLAM.y SLAM.z])*rotz(SLAM.yaw)*trans([LIDAR0.offsetx LIDAR0.offsety LIDAR0.offsetz]))';
X = [xsss ysss zsss onez];
Y=X*T;  %reverse the order because of transpose


xss = Y(:,1);
yss = Y(:,2);

xis = ceil((xss - OMAP.xmin) * OMAP.invRes);
yis = ceil((yss - OMAP.ymin) * OMAP.invRes);

indGood = (xis > 1) & (yis > 1) & (xis < OMAP.map.sizex) & (yis < OMAP.map.sizey);
inds = sub2ind(size(OMAP.map.data),xis(indGood),yis(indGood));

inc=5;
if (SLAM.lidar0Cntr == 1)
  inc=100;
end

OMAP.map.data(inds)=OMAP.map.data(inds)+inc;

CMAP.map.data(inds)=CMAP.map.data(inds)+SLAM.cMapIncObs;
OMAP.delta.data(inds) = 1;

%send out map updates
if (mod(SLAM.lidar0Cntr,40) == 0)
  [xdi ydi] = find(OMAP.delta.data);
  
  MapUpdate.xs = single(xdi * CMAP.res + CMAP.xmin);
  MapUpdate.ys = single(ydi * CMAP.res + CMAP.ymin);
  MapUpdate.cs = CMAP.map.data(sub2ind(size(CMAP.map.data),xdi,ydi));
  content = serialize(MapUpdate);
  ipcAPIPublish(SLAM.MapIncUpdateMsgName,content);
  
  %reset the delta map
  OMAP.delta.data = zeros(size(OMAP.delta.data),'uint8');
end

if (SLAM.updateExplorationMap) 
    % Update the exploration map
    xl = ceil((SLAM.x-EMAP.xmin) * EMAP.invRes);
    yl = ceil((SLAM.y-EMAP.ymin) * EMAP.invRes);
    %tic
    [eix eiy] = getMapCellsFromRay(xl,yl,xis(indGood),yis(indGood));
    %toc
    %plot(eix,eiy,'r.'), hold on
    %plot(xis,yis,'b.'), drawnow, hold off
    cis = sub2ind(size(EMAP.map.data),eix,eiy);
    EMAP.map.data(cis) = 249;
    %imagesc(EMAP.map.data);
    %axis xy;
    %drawnow;
    %EMAP.map.data(cis) = EMAP.map.data(cis)+1;
    if (GetUnixTime()-SLAM.plannerUpdateTime > 2) %(mod(SLAM.lidar0Cntr,300) == 0)
      PublishMapsToMotionPlanner;
      fprintf('sent planner map\n');
      SLAM.plannerUpdateTime = GetUnixTime();
    end
    if (GetUnixTime()-SLAM.explorationUpdateTime > 10) %(mod(SLAM.lidar0Cntr,300) == 0)
      PublishMapsToExplorationPlanner;
      fprintf('sent exploration maps\n');
      SLAM.explorationUpdateTime = GetUnixTime();
    end
end

%send out robot trajectory to vis
if (mod(SLAM.lidar0Cntr,40) == 0)
  TRAJ.cntr = TRAJ.cntr+1;
  TRAJ.traj(:,TRAJ.cntr) = [SLAM.x; SLAM.y; SLAM.yaw; hmax];
  trajMsgName = [GetRobotName 'Traj' VisMarshall('getMsgSuffix','TrajPos3DColorDoubleRGBA')];
  txs = TRAJ.traj(1,1:TRAJ.cntr-1);
  tys = TRAJ.traj(2,1:TRAJ.cntr-1);
  tzs = 0.1*ones(size(txs));
  trs = ones(size(txs));
  tgs = zeros(size(txs));
  tbs = zeros(size(txs));
  tas = ones(size(txs));

  traj = [txs;tys;tzs;trs;tgs;tbs;tas]; 
  content = VisMarshall('marshall','TrajPos3DColorDoubleRGBA',traj);
  ipcAPIPublishVC(trajMsgName,content);
end

%decay the map around the vehicle
if (mod(SLAM.lidar0Cntr,20) == 0)
  xiCenter = ceil((SLAM.x - OMAP.xmin) * OMAP.invRes);
  yiCenter = ceil((SLAM.y - OMAP.ymin) * OMAP.invRes);

  windowSize = 30 *OMAP.invRes;
  ximin = ceil(xiCenter - windowSize/2);
  ximax = ximin + windowSize - 1;

  yimin = ceil(yiCenter - windowSize/2);
  yimax = yimin + windowSize - 1;
  
  
  if ximin < 1,ximin=1; end
  if ximax > OMAP.map.sizex; end
  if yimin < 1,yimin=1; end
  if yimax > OMAP.map.sizey; end

  %get a small map around current location and decay it
  localMap = OMAP.map.data(ximin:ximax,...
                           yimin:yimax);


  indd=localMap<50 & localMap > 0;
  localMap(indd) = localMap(indd)*0.95;
  localMap(localMap>100) = 100;
  
  %merge the small map back into the full map
  OMAP.map.data(ximin:ximax,yimin:yimax) = localMap;
end


%see if we need to increase the size of the map
[xi yi] = Pos2OmapInd(SLAM.x + [-30  30], SLAM.y + [-30 30]);

expandSize = 50;
xExpand = 0;
yExpand = 0;

if (xi(1) < 1), xExpand = -expandSize; end
if (yi(1) < 1), yExpand = -expandSize; end
if (xi(2) > OMAP.map.sizex), xExpand = expandSize; end
if (yi(2) > OMAP.map.sizey), yExpand = expandSize; end

if (xExpand ~=0 || yExpand ~=0)
  %expand the map
  omapExpand(xExpand,yExpand);
  
  %update the boundaries
  ScanMatch2D('setBoundaries',OMAP.xmin,OMAP.ymin,OMAP.xmax,OMAP.ymax);
end
  

POSE.data.x     = SLAM.x;
POSE.data.y     = SLAM.y;
POSE.data.z     = SLAM.z;
POSE.data.roll  = IMU.data.roll;
POSE.data.pitch = IMU.data.pitch;
POSE.data.yaw   = SLAM.yaw;
SLAM.t          = GetUnixTime();

%publish the full obstacle map (to vis)
if (mod(SLAM.lidar0Cntr,200) == 0)
  %PublishObstacleMap;
end


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
global SLAM LIDAR1 SERVO1 OMAP CMAP EMAP POSE IMU

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
indGood = ranges >0.05;
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

%in sensor frame
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

dzs = [diff(zss(indGood)) 0];
%plot(dzs);
%drawnow;

%indsBad = abs(dzs) > 0.05;
indsBad = zss(indGood) > 0.05;
firstBad = find(indsBad,1);

%czs = ones(size(dzs)) * SLAM.cMapIncFree;
czs = zeros(size(dzs));
czs(1:firstBad-1) = SLAM.cMapIncFree;
czs(indsBad) = SLAM.cMapIncObs;

CMAP.map.data(inds)=CMAP.map.data(inds)+czs;
tooLarge = CMAP.map.data(inds) > SLAM.maxCost;
tooSmall = CMAP.map.data(inds) < SLAM.minCost;
CMAP.map.data(inds(tooLarge)) = SLAM.maxCost;
CMAP.map.data(inds(tooSmall)) = SLAM.minCost;
OMAP.delta.data(inds) = 1;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Encoder message handler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function slamProcessEncoders(data,name)
global ENCODERS SLAM IMU

if isempty(IMU)
    return
end

if ~isempty(data)
  ENCODERS.counts  = MagicEncoderCountsSerializer('deserialize',data);
  ENCODERS.cntr    = ENCODERS.cntr + 1;
  
  if isempty(ENCODERS.tLastReset)
    ENCODERS.tLastReset = ENCODERS.counts.t;
    ENCODERS.tLast = ENCODERS.counts.t;
    return;
  end
  
  counts = ENCODERS.counts;
  ENCODERS.acounts = ENCODERS.acounts + [counts.fr;counts.fl;counts.rr;counts.rl];

  %dt for velocity calculation
  dtv = counts.t-ENCODERS.tLastReset;
  if (dtv > 0.1)
    ENCODERS.wheelVels = ENCODERS.acounts / dtv * ENCODERS.metersPerTic;
    ENCODERS.acounts = ENCODERS.acounts*0;
    ENCODERS.tLastReset = counts.t;
  end
  
  
  %get the mean travelled distance for left and right sides
  rc = mean([ENCODERS.counts.rr ENCODERS.counts.fr]) * ENCODERS.metersPerTic;
  lc = mean([ENCODERS.counts.rl ENCODERS.counts.fl]) * ENCODERS.metersPerTic;
  
  %rc = ENCODERS.counts.rr * ENCODERS.metersPerTic;
  %lc = ENCODERS.counts.rl * ENCODERS.metersPerTic;
  
  
  vdt = mean([rc,lc]);
  
  %the fudge factor scales the angular change due to slippage
  %TODO: this will also affect vdt!!
  wdt = (rc - lc)/(2*ENCODERS.robotRadius*ENCODERS.robotRadiusFudge);
  %dt = counts.t - ENCODERS.tLast;
  
  xPrev   = SLAM.x;
  yPrev   = SLAM.y;
  yawPrev = SLAM.yaw;
  
  %calculate the change in position
  if (abs(wdt) > 0.001)
    dx   = -vdt/wdt*sin(yawPrev) + vdt/wdt*sin(yawPrev+wdt);
    dy   =  vdt/wdt*cos(yawPrev) - vdt/wdt*cos(yawPrev+wdt);
    dyaw =  wdt;
  else
    dx   =  vdt*cos(yawPrev);
    dy   =  vdt*sin(yawPrev);
    dyaw =  wdt;
  end
  
  
  %this does not seem to do anything...
  %the idea is to project the displacement onto the 2D plane, given pitch
  %and roll
  dTrans       = rotz(SLAM.yaw)*roty(IMU.data.pitch)*rotx(IMU.data.roll)*rotz(SLAM.yaw)'*[dx;dy;0;1]; 
  
  SLAM.xOdom   = xPrev   + dTrans(1);
  SLAM.yOdom   = yPrev   + dTrans(2);
  SLAM.yawOdom = yawPrev + dyaw;
  
end



function [xi yi] = Pos2OmapInd(x,y)
global OMAP

xi = ceil((x - OMAP.xmin) * OMAP.invRes);
yi = ceil((y - OMAP.ymin) * OMAP.invRes);



