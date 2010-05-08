function ipcRecvImuFcn(msg)

global IMU

if ~isempty(msg)
  IMU.data = MagicImuFilteredSerializer('deserialize',msg);
end