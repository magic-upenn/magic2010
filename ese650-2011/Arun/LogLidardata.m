clear all;
close all;
SetMagicPaths;
%lidar0MsgName = GetMsgName('Lidar0');

robotId = '5';
LidarMsgName = ['Robot' robotId '/Lidar0'];    
imuMsgName = ['Robot' robotId '/ImuFiltered']; % IMU
ServoMsgName = ['Robot' robotId '/Servo1']; 
ipcAPIConnect('localhost');
ipcAPISubscribe(LidarMsgName);
ipcAPISubscribe(ServoMsgName);
ipcAPISubscribe(imuMsgName);

Lidar ={}; 
Servo = {};
Imu = {};

timeout = 50;
tic;
ctf = 1;
cto = 1;
while(1)
      if(toc > timeout)
          break;
      end
      msgs = ipcAPIReceive(10);
      len = length(msgs);
      if len > 0
          disp('receiving...');
          for i=1:len
              switch(msgs(i).name)
                  case LidarMsgName
                     lidarScan =  MagicLidarScanSerializer('deserialize',msgs(i).data);
                      angles = linspace(lidarScan.startAngle, lidarScan.stopAngle, length(lidarScan.ranges));
                      polar(angles,lidarScan.ranges,'.');
                      Lidar{end+1} = lidarScan;
                      drawnow;
                      fprintf(1,'.');
                  case imuMsgName
                      Imu{end+1} = MagicImuFilteredSerializer('deserialize',msgs(i).data);
                  case ServoMsgName
                      Servo{end+1} = MagicServoStateSerializer('deserialize',msgs(i).data);
              end
          end
      end
end
b = datestr(clock());
savename = strcat('Lidardata_',b(1:11),'_',b(13:end),'.mat');
save(savename,'Lidar','Servo','Imu');
close all
clear all