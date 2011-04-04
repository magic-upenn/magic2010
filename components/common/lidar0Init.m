function lidar0Init
global LIDAR0

if isempty(LIDAR0) || ~isfield(LIDAR0,'initialized') || (LIDAR0.initialized ~= 1)
  LIDAR0.msgName = [GetRobotName '/Lidar0'];
  LIDAR0.scan    = [];
  LIDAR0.timeout = 0.1;
  LIDAR0.lastTime = []; 
  
  ipcInit;
  ipcAPIDefine(LIDAR0.msgName,MagicLidarScanSerializer('getFormat'));
  
  LIDAR0.initialized = 1;
  disp('Lidar0 initialized');
end
