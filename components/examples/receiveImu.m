function receiveImu(host)
SetMagicPaths;

if (nargin < 1)
    host = 'localhost';
end

imuMsgName = GetMsgName('ImuFiltered');
imuRawMsgName = GetMsgName('ImuRaw');

ipcAPIConnect(host);
ipcAPISubscribe(imuMsgName);
ipcAPISubscribe(imuRawMsgName);

oldT = 0;

while(1)
  msgs = ipcAPI('listen',10);
  len = length(msgs);
  if len > 0
    for i=1:len
      switch msgs(i).name
        case imuMsgName
          imu = MagicImuFilteredSerializer('deserialize',msgs(i).data)
          PlotImu(deg([imu.roll imu.pitch imu.yaw imu.wroll imu.wpitch imu.wyaw]'), imu.t);
          dt = imu.t - oldT
          oldT = imu.t;
        case imuRawMsgName
          raw = MagicImuRawSerializer('deserialize',msgs(i).data)
          %PlotImu([raw.rawAx raw.rawAy raw.rawAz raw.rawWx raw.rawWy raw.rawWz]',raw.t);
      end
      
      %fprintf(1,'.');
    end
  end
end