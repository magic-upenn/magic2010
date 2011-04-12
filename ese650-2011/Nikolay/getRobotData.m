SetMagicPaths;
robotId = '8';
encMsgName = ['Robot' robotId '/Encoders'];              % Encoders
imuMsgName = ['Robot' robotId '/ImuFiltered'];           % IMU
lid0MsgName = ['Robot' robotId '/Lidar0'];               % Lidar0 (Horizontal)
ser0MsgName = ['Robot' robotId '/Servo0'];               % Servo0 (Horizontal)
lid1MsgName = ['Robot' robotId '/Lidar1'];               % Lidar1 (Vertical)
ser1MsgName = ['Robot' robotId '/Servo1'];               % Servo1 (Vertical)
hmapMsgName = ['Robot' robotId '/IncMapUpdateH'];         % Horizontal Map Update
vmapMsgName = ['Robot' robotId '/IncMapUpdateV'];         % Vertical Map Update
posMsgName = ['Robot' robotId '/Pose'];                  % Pose
patMsgName = ['Robot' robotId '/Planner_Path'];          % Path
ctrMsgName = ['Robot' robotId '/VelocityCmd'];           % Control commands

% Messages to receive
ipcAPIConnect('192.168.10.108');
ipcAPISubscribe(encMsgName);             
ipcAPISubscribe(imuMsgName);
ipcAPISubscribe(lid0MsgName);
ipcAPISubscribe(ser0MsgName);
ipcAPISubscribe(lid1MsgName);
ipcAPISubscribe(ser1MsgName);
ipcAPISubscribe(hmapMsgName);
ipcAPISubscribe(vmapMsgName);
ipcAPISubscribe(posMsgName);
ipcAPISubscribe(patMsgName);
ipcAPISubscribe(ctrMsgName);

Encoders = [];
Imu = [];
Lidar0 = [];
Servo0 = [];
Lidar1 = [];
Servo1 = [];
hMap = [];
vMap = [];
Pose = [];
Path = [];
Control = [];
while(1)
    msgs = ipcAPI('listenWait',10); %ipcAPIReceive(10);
    len = length(msgs);
    if len > 0
        disp('receiving...');
        for i=1:len
            switch(msgs(i).name)
                case encMsgName
                    Encoders = cat(1,Encoders,MagicEncoderCountsSerializer('deserialize',msgs(i).data));
                case imuMsgName
                    Imu = cat(1,Imu,MagicImuFilteredSerializer('deserialize',msgs(i).data));
                case lid0MsgName
                    Lidar0 = cat(1,Lidar0,MagicLidarScanSerializer('deserialize',msgs(i).data));
                case ser0MsgName
                    Servo0 = cat(1,Servo0,MagicServoStateSerializer('deserialize',msgs(i).data));
                case lid1MsgName
                    Lidar1 = cat(1,Lidar1,MagicLidarScanSerializer('deserialize',msgs(i).data));
                case ser1MsgName
                    Servo1 = cat(1,Servo1,MagicServoStateSerializer('deserialize',msgs(i).data));
                case hmapMsgName
                    fprintf('got hmap\n');
                    hMap = cat(1,hMap,deserialize(msgs(i).data));
                    plot(hMap(end).xs,hMap(end).ys,'k.'); drawnow;
                case vmapMsgName
                    vMap = cat(1,vMap,deserialize(msgs(i).data));
                case posMsgName
                    Pose = cat(1,Pose,MagicPoseSerializer('deserialize',msgs(i).data));
                case patMsgName
                    Path{end+1} = deserialize(msgs(i).data);
                case ctrMsgName
                    Control = cat(1,Control,MagicVelocityCmdSerializer('deserialize',msgs(i).data));
            end
        end
    end
end