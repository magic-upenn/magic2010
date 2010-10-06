function lidar0Init
global LIDAR0

if isempty(LIDAR0) || ~isfield(LIDAR0,'initialized') || (LIDAR0.initialized ~= 1)
  LIDAR0.msgName = [GetRobotName '/Lidar0'];
  LIDAR0.resd    = 0.25;
  LIDAR0.res     = LIDAR0.resd/180*pi; 
  LIDAR0.nRays   = 1081;
  LIDAR0.angles  = ((0:LIDAR0.resd:(LIDAR0.nRays-1)*LIDAR0.resd)-135)'*pi/180;
  LIDAR0.cosines = cos(LIDAR0.angles);
  LIDAR0.sines   = sin(LIDAR0.angles);
  LIDAR0.scan    = [];
  LIDAR0.offsetx = 0.137;
  LIDAR0.offsety = 0;
  LIDAR0.offsetz = 0.54;  %from the body origin (not floor)
  LIDAR0.timeout = 0.1;
  LIDAR0.lastTime = []; 
  
  LIDAR0.mask    = ones(size(LIDAR0.angles));
  LIDAR0.mask(10:40)    = 0;
  LIDAR0.mask(80:120)   = 0;
  LIDAR0.mask(970:1010) = 0;
  LIDAR0.mask(1050:end) = 0;
  
  ipcInit;
  ipcAPIDefine(LIDAR0.msgName,MagicLidarScanSerializer('getFormat'));
  
  LIDAR0.initialized = 1;
  disp('Lidar0 initialized');
end
