function slam()

clear all;

slamStart;

while(1)
  slamUpdate;
end


function slamStart
global SLAM OMAP POSE

SetMagicPaths;

SLAM.x   = 0;
SLAM.y   = 0;
SLAM.z   = 0;
SLAM.yaw = 0;
SLAM.lidarCntr = 0;


ipcInit;
omapInit;
emapInit;
encodersSubscribe;
lidar0Subscribe;
motorsInit;
DefineVisMsgs;



%publish initial maps
PublishObstacleMap;
%PublishExplorationMap;

ScanMatch2D('setBoundaries',OMAP.xmin,OMAP.ymin,OMAP.xmax,OMAP.ymax);
ScanMatch2D('setResolution',OMAP.res);


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
global SLAM LIDAR0 OMAP EMAP

SLAM.lidarCntr = SLAM.lidarCntr+1;
map = OMAP.map.data;

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

if (SLAM.lidarCntr == 1)
  SLAM.x=0;
  SLAM.y=0;
  SLAM.yaw=0;
end

T = (trans([SLAM.x SLAM.y SLAM.z])*rotz(SLAM.yaw))';
X = [xsss ysss zsss onez];
Y=X*T;  %reverse the order because of transpose


xss = Y(:,1);
yss = Y(:,2);

xis = ceil((xss - OMAP.xmin) * OMAP.invRes);
yis = ceil((yss - OMAP.ymin) * OMAP.invRes);

indGood = (xis > 1) & (yis > 1) & (xis < OMAP.map.sizex) & (yis < OMAP.map.sizey);
inds = sub2ind(size(map),xis(indGood),yis(indGood));

map(inds)= map(inds)+1;
OMAP.map.data = map;

if (mod(SLAM.lidarCntr,10) == 0)
  PublishObstacleMap;
end



function slamProcessEncoders
global ENCODERS

%fprintf(1,'got encoder packet\n');
counts = ENCODERS.counts;
ENCODERS.acounts = ENCODERS.acounts + [counts.fr;counts.fl;counts.rr;counts.rl];


dt = counts.t-ENCODERS.tLastReset;
if (dt > 0.1)
  ENCODERS.wheelVels = ENCODERS.acounts / dt * ENCODERS.metersPerTic;
  ENCODERS.acounts = ENCODERS.acounts*0;
  ENCODERS.tLastReset = counts.t;
end


