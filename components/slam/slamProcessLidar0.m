%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Lidar0 message handler (horizontal lidar)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function slamProcessLidar0(data,name)
global SLAM LIDAR0 OMAP EMAP POSE IMU CMAP DHMAP MAPS DVMAP SPREAD ENCODERS TRACK GPS

runTrackObs = 1;

if ~isempty(data)
  LIDAR0.scan = MagicLidarScanSerializer('deserialize',data);
else
  return;
end

%wait for an initial imu message
if isempty(IMU.data)
  disp('waiting for initial imu message');
  return
end

%wait for initial encoders message
if isempty(ENCODERS.counts)
    disp('waiting for initial encoder message..');
    return;
end

SLAM.lidar0Cntr = SLAM.lidar0Cntr+1;
if isempty(LIDAR0.lastTime)
  LIDAR0.lastTime = LIDAR0.scan.startTime;
end

dt = LIDAR0.scan.startTime - LIDAR0.lastTime;

%fprintf(1,'got lidar scan\n');
if (mod(SLAM.lidar0Cntr,40) == 0)
  fprintf(1,'.');
  %toc,tic
end
  
ranges = double(LIDAR0.scan.ranges)'; %convert from float to double
%dranges = [0; diff(ranges)];
indGood = ranges >0.25 & LIDAR0.mask; % & (abs(dranges) <0.1);

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

%if encoders are zero, don't move
%if(SLAM.odomChanged > 0)
if (1)
  SLAM.odomChanged = 0;
  
  %figure out how much to search over the yaw space based on the 
  %instantaneous angular velocity from imu
 
  slamScanMatchPass1;
  
  slamScanMatchPass2;
 
else
  %fprintf(1,'not moving\n');
end
  
POSE.data.x     = SLAM.x;
POSE.data.y     = SLAM.y;
POSE.data.z     = SLAM.z;
POSE.data.roll  = IMU.data.roll;
POSE.data.pitch = IMU.data.pitch;
POSE.data.yaw   = SLAM.yaw;
POSE.t          = GetUnixTime();
SLAM.xOdom      = SLAM.x;
SLAM.yOdom      = SLAM.y;
SLAM.yawOdom    = SLAM.yaw;

%send out pose message
if mod(SLAM.lidar0Cntr,4) == 0
  ipcAPIPublishVC(POSE.msgName,MagicPoseSerializer('serialize',POSE.data));
end
  
%publish pose message going out to outside world
if mod(SLAM.lidar0Cntr,10) == 0
    POSE.data.gps = GPS;
  
    ipcAPIPublishVC(POSE.extMsgName,MagicPoseSerializer('serialize',POSE.data));

    if (SPREAD.useSpread)
      spreadSendUnreliable('Pose', serialize(POSE.data));
    end
    
    if (SLAM.useUdpExternal)
        packet = POSE.data;
        packet.type = 'Pose';
        packet.id = GetRobotId();
        raw = serialize(packet);
        zraw = zlibCompress(raw);
        UdpSendAPI('send',zraw);
    end
end


T = (trans([SLAM.x SLAM.y SLAM.z])*rotz(SLAM.yaw)*trans([LIDAR0.offsetx LIDAR0.offsety LIDAR0.offsetz]));

if runTrackObs
  %track obstacles
  obsTracks = trackObstacles(ranges,LIDAR0.angles,T);
  %obsTracks = trackObstaclesOld(ranges,LIDAR0.angles,T);

  if mod(SLAM.lidar0Cntr,10) == 0
    ipcAPIPublish(TRACK.msgName,serialize(obsTracks));
  end
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

  if (SPREAD.useSpread)
    spreadSendUnreliable('MapUpdateH', serialize(MapUpdateH));
  end
  
  if (SLAM.useUdpExternal)
    packet = MapUpdateH;
    packet.type = 'MapUpdateH';
    packet.id   = GetRobotId();
    raw =serialize(packet);
    zraw = zlibCompress(raw);
    UdpSendAPI('send',zraw);
  end


  [xdi ydi] = find(DVMAP.map.data);
  MapUpdateV.xs = single(xdi * MAPS.res + OMAP.xmin);
  MapUpdateV.ys = single(ydi * MAPS.res + OMAP.ymin);
  MapUpdateV.cs = CMAP.map.data(sub2ind(size(CMAP.map.data),xdi,ydi));
  ipcAPIPublish(SLAM.IncMapUpdateVMsgName,serialize(MapUpdateV));

  if (SPREAD.useSpread)
    spreadSendUnreliable('MapUpdateV', serialize(MapUpdateV));
  end
  
  if (SLAM.useUdpExternal)
    packet = MapUpdateV;
    packet.type = 'MapUpdateV';
    packet.id   = GetRobotId();
    raw = serialize(packet);
    zraw = zlibCompress(raw);
    UdpSendAPI('send',zraw);
  end
  
  %reset the delta map
  DHMAP.map.data = zeros(size(DHMAP.map.data),'uint8');
  DVMAP.map.data = zeros(size(DVMAP.map.data),'uint8');
end

%{
if (GetUnixTime()-SLAM.plannerUpdateTime > SLAM.plannerUpdatePeriod)
  oldPublishMapsToMotionPlanner;
  fprintf('sent planner map\n');
  SLAM.plannerUpdateTime = GetUnixTime();
end
%}


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

LIDAR0.lastTime = LIDAR0.scan.startTime;
