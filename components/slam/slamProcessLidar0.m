%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Lidar0 message handler (horizontal lidar)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function slamProcessLidar0(data,name)
global SLAM LIDAR0 OMAP EMAP POSE IMU TRAJ CMAP DHMAP MAPS DVMAP

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

if mod(SLAM.lidar0Cntr,10) == 0
    ipcAPIPublishVC(POSE.extMsgName,MagicPoseSerializer('serialize',POSE.data));
end

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
DHMAP.map.data(inds) = 1;

%send out map updates
if (mod(SLAM.lidar0Cntr,40) == 0)
  [xdi ydi] = find(DHMAP.map.data);
  MapUpdateH.xs = single(xdi * MAPS.res + OMAP.xmin);
  MapUpdateH.ys = single(ydi * MAPS.res + OMAP.ymin);
  MapUpdateH.cs = OMAP.map.data(sub2ind(size(OMAP.map.data),xdi,ydi));
  ipcAPIPublish(SLAM.IncMapUpdateHMsgName,serialize(MapUpdateH));
  
  [xdi ydi] = find(DVMAP.map.data);
  MapUpdateV.xs = single(xdi * MAPS.res + OMAP.xmin);
  MapUpdateV.ys = single(ydi * MAPS.res + OMAP.ymin);
  MapUpdateV.cs = CMAP.map.data(sub2ind(size(CMAP.map.data),xdi,ydi));
  ipcAPIPublish(SLAM.IncMapUpdateVMsgName,serialize(MapUpdateV));
  
  %reset the delta map
  DHMAP.map.data = zeros(size(DHMAP.map.data),'uint8');
  DVMAP.map.data = zeros(size(DVMAP.map.data),'uint8');
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
    if (GetUnixTime()-SLAM.plannerUpdateTime > SLAM.plannerUpdatePeriod) %(mod(SLAM.lidar0Cntr,300) == 0)
      PublishMapsToMotionPlanner;
      fprintf('sent planner map\n');
      SLAM.plannerUpdateTime = GetUnixTime();
    else
      %send pose
      position_update.timestamp = GetUnixTime();
      position_update.x = SLAM.x;
      position_update.y = SLAM.y;
      position_update.theta = SLAM.yaw;
      ipcAPIPublishVC('Lattice Planner Position Update',MagicGP_POSITION_UPDATESerializer('serialize',position_update));
    end
    if (GetUnixTime()-SLAM.explorationUpdateTime > SLAM.explorationUpdatePeriod) %(mod(SLAM.lidar0Cntr,300) == 0)
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


%see if we need to shift the map
shiftAmount = 10; %meters
xShift = 0;
yShift = 0;

if (SLAM.x - OMAP.xmin < MAPS.edgeProx), xShift = -shiftAmount; end
if (SLAM.y - OMAP.ymin < MAPS.edgeProx), yShift = -shiftAmount; end
if (OMAP.xmax - SLAM.x < MAPS.edgeProx), xShift = shiftAmount; end
if (OMAP.ymax - SLAM.y < MAPS.edgeProx), yShift = shiftAmount; end


if (xShift ~= 0 || yShift ~= 0)
    OMAP  = mapResize(OMAP,xShift,yShift);
    CMAP  = mapResize(CMAP,xShift,yShift);
    DHMAP = mapResize(DHMAP,xShift,yShift);
    DVMAP = mapResize(DVMAP,xShift,yShift);
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


function [xi yi] = Pos2OmapInd(x,y)
global OMAP

xi = ceil((x - OMAP.xmin) * OMAP.invRes);
yi = ceil((y - OMAP.ymin) * OMAP.invRes);
