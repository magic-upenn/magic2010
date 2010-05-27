function lidar1Init
global LIDAR1

if isempty(LIDAR1) || (LIDAR1.initialized ~= 1)
  LIDAR0.msgName = [GetRobotName '/Lidar1'];
  LIDAR1.resd    = 0.25;
  LIDAR1.res     = LIDAR1.resd/180*pi; 
  LIDAR1.nRays   = 1081;
  LIDAR1.angles  = ((0:LIDAR1.resd:(LIDAR1.nRays-1)*LIDAR1.resd)-135)'*pi/180;
  LIDAR1.cosines = cos(LIDAR1.angles);
  LIDAR1.sines   = sin(LIDAR1.angles);
  LIDAR1.scan    = [];
  
  ipcInit;
  ipcAPIDefine(LIDAR1.msgName,MagicLidarScanSerializer('getFormat'));
  
  LIDAR1.initialized = 1;
  disp('Lidar0 initialized');
end
