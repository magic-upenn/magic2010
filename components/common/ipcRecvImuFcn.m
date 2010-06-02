function ipcRecvImuFcn(data,name)

global IMU

if ~isempty(data)
  IMU.data = MagicImuFilteredSerializer('deserialize',data);
end