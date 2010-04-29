function slam(tUpdate)

clear all;

slamStart;

while(1)
  slamUpdate;
end


function slamStart
global SLAM MAPS POSE LIDAR0 ENCODERS MOTORS

SetMagicPaths;

SLAM.x   = 0;
SLAM.y   = 0;
SLAM.z   = 0;
SLAM.yaw = 0;
SLAM.lidarCntr = 1;

%obstacle map
MAPS.omap.res        = 0.05;
MAPS.omap.invRes     = 1/MAPS.omap.res;
MAPS.omap.xmin       = -25;
MAPS.omap.ymin       = -25;
MAPS.omap.xmax       = 25;
MAPS.omap.ymax       = 25;
MAPS.omap.zmin       = 0;
MAPS.omap.zmax       = 5;

MAPS.omap.map.sizex  = (MAPS.omap.xmax - MAPS.omap.xmin) / MAPS.omap.res;
MAPS.omap.map.sizey  = (MAPS.omap.ymax - MAPS.omap.ymin) / MAPS.omap.res;
MAPS.omap.map.data   = zeros(MAPS.omap.map.sizex,MAPS.omap.map.sizey,'uint8');
MAPS.omap.msgName    = [GetRobotName '/ObstacleMap2D_map2d'];


%exploration map
MAPS.emap            = MAPS.omap;
MAPS.emap.map.data   = 127*ones(MAPS.emap.map.sizex,MAPS.emap.map.sizey,'uint8');
MAPS.emap.msgName    = [GetRobotName '/ExplorationMap2D_map2d'];


ipcInit;
encodersSubscribe;
lidar0Subscribe;
motorsInit;
DefineVisMsgs;



%publish initial maps
PublishObstacleMap;
%PublishExplorationMap;

ScanMatch2D('setBoundaries',MAPS.omap.xmin,MAPS.omap.ymin,MAPS.omap.xmax,MAPS.omap.ymax);
ScanMatch2D('setResolution',MAPS.omap.res);


POSE.x     = 0;
POSE.y     = 0;
POSE.z     = 0;
POSE.roll  = 0;
POSE.pitch = 0;
POSE.yaw   = 0/180*pi; %1.5


function slamUpdate
global LIDAR0 ENCODERS
msgs = ipcAPI('listen',25);
nmsgs = length(msgs);

for mi=1:nmsgs
  switch msgs(mi).name
    case LIDAR0.msgName
      LIDAR0.scan = MagicLidarScanSerializer('deserialize',msgs(mi).data);
      slamProcessLidar;
    case ENCODERS.msgName
      ENCODERS.counts  = MagicEncoderCountsSerializer('deserialize',msgs(mi).data);
      
      if isempty(ENCODERS.tLastReset)
        ENCODERS.tLastReset = ENCODERS.counts.t;
      end
      
      slamProcessEncoders;
  end
end




function slamProcessLidar
global SLAM LIDAR0 MAPS

SLAM.lidarCntr = SLAM.lidarCntr+1;
map = MAPS.omap.map.data;

%fprintf(1,'got lidar scan\n');
fprintf(1,'.');

ranges = double(LIDAR0.scan.ranges)'; %convert from float to double
indGood = ranges >0.25;

xs = ranges.*LIDAR0.cosines;
ys = ranges.*LIDAR0.sines;
zs = zeros(size(xs));

xsss=xs(indGood);
ysss=ys(indGood);
zsss=zs(indGood);
onez=ones(size(xsss));


nyaw= 21;
nxs = 11;
nys = 11;

dyaw = 0.25/180.0*pi;
dx   = 0.02;
dy   = 0.02;

aCand = (-10:10)*dyaw+SLAM.yaw; %+ (-cshift(cimax))*a_res;
xCand = (-5:5)*dx+SLAM.x;
yCand = (-5:5)*dy+SLAM.y;

hits = ScanMatch2D('match',map,xsss,ysss,xCand,yCand,aCand);


[hmax imax] = max(hits(:));
[kmax mmax jmax] = ind2sub([nxs,nys,nyaw],imax);

SLAM.yaw = aCand(jmax);
SLAM.x   = xCand(kmax);
SLAM.y   = yCand(mmax);

T = (trans([SLAM.x SLAM.y SLAM.z])*rotz(SLAM.yaw))';
X = [xsss ysss zsss onez];
Y=X*T;  %reverse the order because of transpose


xss = Y(:,1);
yss = Y(:,2);

xis = ceil((xss - MAPS.omap.xmin) * MAPS.omap.invRes);
yis = ceil((yss - MAPS.omap.ymin) * MAPS.omap.invRes);

indGood = (xis > 1) & (yis > 1) & (xis < MAPS.omap.map.sizex) & (yis < MAPS.omap.map.sizey);
inds = sub2ind(size(map),xis(indGood),yis(indGood));

map(inds)= map(inds)+1;
MAPS.omap.map.data = map;

if (mod(SLAM.lidarCntr,10) == 0)
  PublishObstacleMap;
end



function slamProcessEncoders
global ENCODERS MAPS SLAM MOTORS

%fprintf(1,'got encoder packet\n');
counts = ENCODERS.counts;
ENCODERS.acounts = ENCODERS.acounts + [counts.fr;counts.fl;counts.rr;counts.rl];


dt = counts.t-ENCODERS.tLastReset;
if (dt > 0.1)
  ENCODERS.wheelVels = ENCODERS.acounts / dt * ENCODERS.metersPerTic;
  ENCODERS.acounts = ENCODERS.acounts*0;
  ENCODERS.tLastReset = counts.t;
end


