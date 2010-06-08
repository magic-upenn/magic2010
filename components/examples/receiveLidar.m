SetMagicPaths;
lidar0MsgName = GetMsgName('Lidar0');

ipcAPIConnect;
ipcAPISubscribe(lidar0MsgName);

tic
while(1)
  msgs = ipcAPIReceive(10);
  len = length(msgs);
  if len > 0
    for i=1:len
      toc
      tic
      lidarScan =  MagicLidarScanSerializer('deserialize',msgs(i).data);
      plot(lidarScan.ranges);
      drawnow;
      %fprintf(1,'.');
    end
  end
end