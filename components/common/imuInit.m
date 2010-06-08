function imuInit
global IMU

if isempty(IMU) || ~isfield(IMU,'initialized') || (IMU.initialized ~= 1)
  IMU.msgName = [GetRobotName '/ImuFiltered'];
  IMU.data    = [];
  
  ipcInit;
  ipcAPIDefine(IMU.msgName,MagicImuFilteredSerializer('getFormat'));
  
  IMU.initialized = 1;
  disp('Imu initialized');
end