SetMagicPaths;
%lidar0MsgName = GetMsgName('Lidar0');

ipcAPIConnect('localhost');
ipcAPISubscribe('Robot2/Lidar0');

tic
while(1)
  msgs = ipcAPIReceive(10);
  len = length(msgs);
  if len > 0
    for i=1:len
      msg = msgs(i)
      lidarScan =  MagicLidarScanSerializer('deserialize',msgs(i).data)
      plot(lidarScan.ranges,'.');
      drawnow;
      fprintf(1,'.');
    end
  end
end