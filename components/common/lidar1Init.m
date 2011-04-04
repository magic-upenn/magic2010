function lidar1Init
global LIDAR1

if isempty(LIDAR1) || ~isfield(LIDAR1,'initialized') ||(LIDAR1.initialized ~= 1)
  LIDAR1.msgName  = [GetRobotName '/Lidar1'];
  LIDAR1.scan     = [];
  LIDAR1.timeout  = 0.1;
  LIDAR1.lastTime = []; 
  
  ipcInit;
  ipcAPIDefine(LIDAR1.msgName,MagicLidarScanSerializer('getFormat'));
  
  LIDAR1.initialized = 1;
  disp('Lidar0 initialized');
end
