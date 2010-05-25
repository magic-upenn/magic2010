SetMagicPaths;

servoMsgName = GetMsgName('ImuFiltered');

ipcAPIConnect;
ipcAPISubscribe(servoMsgName);

oldT = 0;

while(1)
  msgs = ipcAPI('listen',10);
  len = length(msgs);
  if len > 0
    for i=1:len
      imu = MagicImuFilteredSerializer('deserialize',msgs(i).data)
      dt = imu.t - oldT
      oldT = imu.t;
      
      %fprintf(1,'.');
    end
  end
end