addpath( [ getenv('VIS_DIR') '/ipc' ] )

ipcAPIConnect;
ipcAPISubscribe('Robot0/Lidar0');


while(1)
  msgs = ipcAPIReceive(10);
  len = length(msgs);
  if len > 0
    for i=1:len
      lidarScan =  MagicLidarScanSerializer('deserialize',msgs(i).data);
      plot(lidarScan.ranges);
      drawnow;
      %fprintf(1,'.');
    end
  end
end