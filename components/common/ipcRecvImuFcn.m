function ipcRecvImuFcn(data,name)

global IMU

if ~isempty(data)
  IMU.data = MagicImuFilteredSerializer('deserialize',data);
end

IMU.cntr = IMU.cntr + 1;
tnow = GetUnixTime();

if (mod(IMU.cntr,100) == 0)
  dt = tnow - IMU.rateTime;
  fprintf('imu rate = %f\n',100/dt);
  IMU.rateTime = tnow;
end

dtImu = tnow - IMU.tLastArrival;
IMU.tLastArrival = tnow;