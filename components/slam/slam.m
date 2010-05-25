function slam()

clear all;

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

SLAM.x   = 0;
SLAM.y   = 0;
SLAM.z   = 0;
SLAM.yaw = 0/180*pi;


SLAM.lidarCntr = 0;

SLAM.xOdom   = SLAM.x;
SLAM.yOdom   = SLAM.y;
SLAM.yawOdom = SLAM.yaw;

TRAJ.cntr=0;
TRAJ.traj = zeros(4,100000);
TRAJ.hTraj = [];

%initialize the pose struct so that the maps are initialized around the initial pose
%in future, this should be the start UTM coordinate!!
POSE.x     = 0;
POSE.y     = 0;
POSE.z     = 0;
POSE.roll  = 0;
POSE.pitch = 0;
POSE.yaw   = 0/180*pi;

ipcInit;
omapInit;
emapInit;
encodersSubscribe;
lidar0Subscribe;
motorsInit;
poseInit;
DefineVisMsgs;
DefineSensorMessages;
DefinePlannerMessages;

%assign the message handlers
ipcReceiveSetFcn(GetMsgName('Pose'),        @ipcRecvPoseFcn);
ipcReceiveSetFcn(GetMsgName('Encoders'),    @ipcRecvEncodersFcn);
ipcReceiveSetFcn(GetMsgName('Lidar0'),      @slamProcessLidar);
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
% Lidar0 message handler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function slamProcessLidar(msg)
global SLAM LIDAR0 OMAP EMAP POSE IMU TRAJ

if ~isempty(msg)
  LIDAR0.scan = MagicLidarScanSerializer('deserialize',msg);
else
  return;
end

%wait for an initial imu message
if isempty(IMU)
  return
end
  
SLAM.lidarCntr = SLAM.lidarCntr+1;

%fprintf(1,'got lidar scan\n');
if (mod(SLAM.lidarCntr,200) == 0)
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

aCand = (-yawRange:yawRange)*dyaw+SLAM.yaw + IMU.data.wyaw*0.025;
xCand = (-xRange:xRange)*dx+SLAM.xOdom;
yCand = (-yRange:yRange)*dy+SLAM.yOdom;


%get a local 3D sampling of pose likelihood
hits = ScanMatch2D('match',OMAP.map.data,xsss,ysss,xCand,yCand,aCand);


[hmax imax] = max(hits(:));
[kmax mmax jmax] = ind2sub([nxs,nys,nyaw],imax);

if (SLAM.lidarCntr > 1)
  
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
  
  SLAM.yaw = aCand(jmax);
  SLAM.x   = xGrid(cimin);
  SLAM.y   = yGrid(cimin);
  
end

%update the map
T = (trans([SLAM.x SLAM.y SLAM.z])*rotz(SLAM.yaw))';
X = [xsss ysss zsss onez];
Y=X*T;  %reverse the order because of transpose


xss = Y(:,1);
yss = Y(:,2);

xis = ceil((xss - OMAP.xmin) * OMAP.invRes);
yis = ceil((yss - OMAP.ymin) * OMAP.invRes);

indGood = (xis > 1) & (yis > 1) & (xis < OMAP.map.sizex) & (yis < OMAP.map.sizey);
inds = sub2ind(size(OMAP.map.data),xis(indGood),yis(indGood));

inc=5;
if (SLAM.lidarCntr == 1)
  inc=100;
end

OMAP.map.data(inds)=OMAP.map.data(inds)+inc;

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
if (mod(SLAM.lidarCntr,300) == 0)
  PublishMapsToExplorationPlanner;
end


TRAJ.cntr = TRAJ.cntr+1;
TRAJ.traj(:,TRAJ.cntr) = [SLAM.x; SLAM.y; SLAM.yaw; hmax];

%draw the trajectory
%{
if (mod(SLAM.lidarCntr,40) == 0)
  if isempty(TRAJ.hTraj)
    TRAJ.hTraj =plot(TRAJ.traj(1,1:TRAJ.cntr-1),TRAJ.traj(2,1:TRAJ.cntr-1));
  else
    set(TRAJ.hTraj,'xdata',TRAJ.traj(1,1:TRAJ.cntr-1),'ydata',TRAJ.traj(2,1:TRAJ.cntr-1));
  end
    
  drawnow;
end
%}

%send out robot trajectory to vis
if (mod(SLAM.lidarCntr,100) == 0)
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
if (mod(SLAM.lidarCntr,20) == 0)
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


  localMap = OMAP.map.data(ximin:ximax,...
                           yimin:yimax);


  indd=localMap<50 & localMap > 0;
  localMap(indd) = localMap(indd)*0.95;
  localMap(localMap>100) = 100;
  
  OMAP.map.data(ximin:ximax,yimin:yimax) = localMap;
end


%see if we need to increase the size of the map
[xi yi] = PositionToIndeces(SLAM.x + [-30  30], SLAM.y + [-30 30]);

expandSize = 50;
xExpand = 0;
yExpand = 0;

if (xi(1) < 1), xExpand = -expandSize; end
if (yi(1) < 1), yExpand = -expandSize; end
if (xi(2) > OMAP.map.sizex), xExpand = expandSize; end
if (yi(2) > OMAP.map.sizey), yExpand = expandSize; end

if (xExpand ~=0 || yExpand ~=0)
  omapExpand(xExpand,yExpand);
  ScanMatch2D('setBoundaries',OMAP.xmin,OMAP.ymin,OMAP.xmax,OMAP.ymax);
end
  

POSE.x     = SLAM.x;
POSE.y     = SLAM.y;
POSE.z     = SLAM.z;
POSE.roll  = IMU.data.roll;
POSE.pitch = IMU.data.pitch;
POSE.yaw   = SLAM.yaw;

%{
if (mod(SLAM.lidarCntr,200) == 0)
  PublishObstacleMap;
end
%}

ipcAPIPublishVC(POSE.msgName,MagicPoseSerializer('serialize',POSE));




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Encoder message handler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function slamProcessEncoders(msg)
global ENCODERS SLAM IMU

if ~isempty(msg)
  ENCODERS.counts  = MagicEncoderCountsSerializer('deserialize',msg);
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
  
  
  rc = mean([ENCODERS.counts.rr ENCODERS.counts.fr]) * ENCODERS.metersPerTic;
  lc = mean([ENCODERS.counts.rl ENCODERS.counts.fl]) * ENCODERS.metersPerTic;
  
  %rc = ENCODERS.counts.rr * ENCODERS.metersPerTic;
  %lc = ENCODERS.counts.rl * ENCODERS.metersPerTic;
  
  
  vdt = mean([rc,lc]);
  wdt = (rc - lc)/2/ENCODERS.robotRadius/2;
  %dt = counts.t - ENCODERS.tLast;
  
  SLAM.xOdom = SLAM.x;
  SLAM.yOdom = SLAM.y;
  SLAM.yawOdom = SLAM.yaw;
  
  xPrev = SLAM.x;
  yPrev = SLAM.y;
  
  %update the state variables
  if (abs(wdt) > 0.001)
    SLAM.xOdom = SLAM.xOdom - vdt/wdt*sin(SLAM.yawOdom) + vdt/wdt*sin(SLAM.yawOdom+wdt);
    SLAM.yOdom = SLAM.yOdom + vdt/wdt*cos(SLAM.yawOdom) - vdt/wdt*cos(SLAM.yawOdom+wdt);
    SLAM.yawOdom = SLAM.yawOdom + wdt;
  else
    SLAM.xOdom   = SLAM.xOdom + vdt*cos(SLAM.yawOdom);
    SLAM.yOdom   = SLAM.yOdom + vdt*sin(SLAM.yawOdom);
    SLAM.yawOdom = SLAM.yawOdom + wdt;
  end
  
  
  %this does not seem to do anything...
  %the idea is to project the displacement onto the 2D plane, given pitch
  %and roll
  dx = SLAM.xOdom - xPrev;
  dy = SLAM.yOdom - yPrev;
  dTrans = rotz(SLAM.yaw)*roty(IMU.data.pitch)*rotx(IMU.data.roll)*rotz(SLAM.yaw)'*[dx;dy;0;1];
  
  SLAM.xOdom = xPrev + dTrans(1);
  SLAM.yOdom = yPrev + dTrans(2);
  
end



function [xi yi] = PositionToIndeces(x,y)
global OMAP

xi = ceil((x - OMAP.xmin) * OMAP.invRes);
yi = ceil((y - OMAP.ymin) * OMAP.invRes);



