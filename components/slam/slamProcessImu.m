function slamProcessImu(data,name)

global IMU IMU_TS

if ~isempty(data)
  IMU.data = MagicImuFilteredSerializer('deserialize',data);
end

if isempty(IMU_TS)
    IMU_TS.ts  = zeros(1,1000);
    IMU_TS.dts = zeros(1,1000);
    IMU_TS.cntr = 1;
end

IMU.cntr = IMU.cntr + 1;
tnow = GetUnixTime();

if (IMU_TS.cntr > 1)
  ti   = IMU.data.t;
  dtt= tnow-ti;
  IMU_TS.ts(IMU_TS.cntr) = ti;
  IMU_TS.dts(IMU_TS.cntr) = dtt; %ti-IMU_TS.ts(IMU_TS.cntr-1);%dtt;
end
IMU_TS.cntr = IMU_TS.cntr + 1;

if (mod(IMU.cntr,100) == 0)
  dt = tnow - IMU.rateTime;
  fprintf('imu rate = %f\n',100/dt);
  IMU.rateTime = tnow;
end

dtImu = tnow - IMU.tLastArrival;
IMU.tLastArrival = tnow;