function RascalmapfsmRecvImuFcn(data,name)
global POSE

if ~isempty(data)
  Imu = MagicImuFilteredSerializer('deserialize',data);
  POSE.pitch = Imu.pitch;
  POSE.roll = Imu.roll;
end
