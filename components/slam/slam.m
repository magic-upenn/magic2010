function slam(tUpdate)

clear all;

slamStart;

while(1)
  slamUpdate;
end


function slamStart
global SLAM MAPS POSE LIDAR0 ENCODERS
addpath ../common

SetMagicPaths;

LIDAR0.msgName = [GetRobotName '/Lidar0'];
LIDAR0.resd    = 0.25;
LIDAR0.res     = LIDAR0.resd/180*pi; 
LIDAR0.nRays   = 1081;
LIDAR0.angles  = ((0:LIDAR0.resd:(LIDAR0.nRays-1)*LIDAR0.resd)-135)'*pi/180;
LIDAR0.cosines = cos(LIDAR0.angles);
LIDAR0.sines   = sin(LIDAR0.angles);
LIDAR0.scan    = [];

ENCODERS.msgName = [GetRobotName '/Encoders'];
ENCODERS.counts  = [];

%obstacle map
MAPS.omap.res        = 0.05;
MAPS.omap.xmin       = -5;
MAPS.omap.ymin       = -5;
MAPS.omap.xmax       = 25;
MAPS.omap.ymax       = 25;
MAPS.omap.zmin       = 0;
MAPS.omap.zmax       = 5;

MAPS.omap.map.sizex  = (MAPS.omap.xmax - MAPS.omap.xmin) / MAPS.omap.res;
MAPS.omap.map.sizey  = (MAPS.omap.ymax - MAPS.omap.ymin) / MAPS.omap.res;
MAPS.omap.map.data   = zeros(MAPS.omap.map.sizex,MAPS.omap.map.sizey,'uint8');
MAPS.omap.msgName    = [GetRobotName '/omap2d_map2d'];


%exploration map
MAPS.emap            = MAPS.omap;
MAPS.emap.map.data   = 127*ones(MAPS.emap.map.sizex,MAPS.emap.map.sizey,'uint8');
MAPS.emap.msgName    = [GetRobotName '/emap2d_map2d'];


ipcAPIConnect;
DefineLidarMsgs;
DefineEncoderMsg;
DefineVisMsgs;
ipcAPISubscribe(LIDAR0.msgName);
ipcAPISubscribe(ENCODERS.msgName);



PublishObstacleMap;
PublishExplorationMap;

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
      ENCODERS.counts = MagicEncoderCountsSerializer('deserialize',msgs(mi).data);
      slamProcessEncoders;
  end
end




function slamProcessLidar
global LIDAR0 MAPS SLAM

fprintf(1,'got lidar scan\n');




function slamProcessEncoders
global ENCODERS MAPS SLAM

fprintf(1,'got encoder packet\n');

