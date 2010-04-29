function lidar0Init
global LIDAR0

if isempty(LIDAR0) || (LIDAR0.initialized ~= 1)
  LIDAR0.msgName = [GetRobotName '/Lidar0'];
  LIDAR0.resd    = 0.25;
  LIDAR0.res     = LIDAR0.resd/180*pi; 
  LIDAR0.nRays   = 1081;
  LIDAR0.angles  = ((0:LIDAR0.resd:(LIDAR0.nRays-1)*LIDAR0.resd)-135)'*pi/180;
  LIDAR0.cosines = cos(LIDAR0.angles);
  LIDAR0.sines   = sin(LIDAR0.angles);
  LIDAR0.scan    = [];
  
  ipcInit;
  ipcAPIDefine(LIDAR0.msgName,MagicLidarScanSerializer('getFormat'));
  
  LIDAR0.initialized = 1;
  disp('Lidar0 initialized');
end