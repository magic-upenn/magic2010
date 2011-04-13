SetMagicPaths;
robotId = '5';
encMsgName = ['Robot' robotId '/Encoders'];              % Encoders
imuMsgName = ['Robot' robotId '/ImuFiltered'];           % IMU
GPSMsgName = ['Robot' robotId '/GPS'];               %GPS
OmniCamMsgName = ['Robot' robotId '/CamOmni'];               % Omni-directional Cam
FrontCamMsgName = ['Robot' robotId '/CamFront'];               %Front facing cam
% ser1MsgName = ['Robot' robotId '/Servo1'];               % Servo1 (Vertical)
% hmapMsgName = ['Robot' robotId '/IncMapUpdateH'];         % Horizontal Map Update
% vmapMsgName = ['Robot' robotId '/IncMapUpdateV'];         % Vertical Map Update
% posMsgName = ['Robot' robotId '/Pose'];                  % Pose
% patMsgName = ['Robot' robotId '/Planner_Path'];          % Path
% ctrMsgName = ['Robot' robotId '/VelocityCmd'];           % Control commands

% Messages to receive
ipcAPIConnect(strcat('192.168.10.10',robotId));
ipcAPISubscribe(encMsgName);             
ipcAPISubscribe(imuMsgName);
ipcAPISubscribe(GPSMsgName);
ipcAPISubscribe(OmniCamMsgName);
ipcAPISubscribe(FrontCamMsgName);
% ipcAPISubscribe(ser1MsgName);
% ipcAPISubscribe(hmapMsgName);
% ipcAPISubscribe(vmapMsgName);
% ipcAPISubscribe(posMsgName);
% ipcAPISubscribe(patMsgName);
% ipcAPISubscribe(ctrMsgName);

Encoders = {};
Imu = {};
GPS = {};
OmniCam = {};
FrontCam = {};
% Servo1 = [];
% hMap = [];
% vMap = [];
% Pose = [];
% Path = [];
% Control = [];
try
  while(1)
      msgs = ipcAPIReceive(10);
      len = length(msgs);
      if len > 0
          disp('receiving...');
          for i=1:len
              switch(msgs(i).name)
                  case encMsgName
                      Encoders{end+1} = MagicEncoderCountsSerializer('deserialize',msgs(i).data);
                  case imuMsgName
                      Imu{end+1} = MagicImuFilteredSerializer('deserialize',msgs(i).data);
                  case GPSMsgName
                      GPS{end+1} = MagicGpsASCIISerializer('deserialize',msgs(i).data);
                  case OmniCamMsgName
                      OmniCam{end+1} = deserialize(msgs(i).data);
                  case FrontCamMsgName
                      FrontCam{end+1} = deserialize(msgs(i).data);
  %                 case ser1MsgName
  %                     Servo1 = cat(1,Servo1,MagicServoStateSerializer('deserialize',msgs(i).data));
  %                 case hmapMsgName
  %                     hMap = cat(1,hMap,deserialize(msgs(i).data));
  %                 case vmapMsgName
  %                     vMap = cat(1,vMap,deserialize(msgs(i).data));
  %                 case posMsgName
  %                     Pose = cat(1,Pose,MagicPoseSerializer('deserialize',msgs(i).data));
  %                 case patMsgName
  %                     Path = cat(1,Path,deserialize(msgs(i).data));
  %                 case ctrMsgName
  %                     Control = cat(1,Control,MagicVelocityCmdSerializer('deserialize',msgs(i).data));
              end
          end
      end
  end
catch
    b = datestr(clock());
    savename = strcat('data_',b(1:11),'_',b(13:end),'.mat');
    save(savename,'Encoders','IMU','GPS','OmniCam','FrontCam');
end
