function imuInit
global IMU

if isempty(IMU) || ~isfield(IMU,'initialized') || (IMU.initialized ~= 1)
  IMU.msgName = [GetRobotName '/ImuFiltered'];
  IMU.data    = [];
  
  ipcInit;
  ipcAPIDefine(IMU.msgName,MagicImuFilteredSerializer('getFormat'));
  
  IMU.initialized = 1;
  %IMU.initDelta   = []; %time between first imu packettimestamp and unix time at the moment of reception
  IMU.tLastArrival       = []; %time of arrival of last packet
  IMU.timeout = 0.1;
  disp('Imu initialized');
end