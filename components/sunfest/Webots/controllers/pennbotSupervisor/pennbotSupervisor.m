clear all;
TIME_STEP = 64;

pennbot    = wb_supervisor_node_get_from_def('PENNBOT');
yawServo   = wb_supervisor_node_get_from_def('YAW_SERVO');
pitchServo = wb_supervisor_node_get_from_def('PITCH_SERVO');

positionField = wb_supervisor_node_get_field(pennbot,'translation');
rotationField = wb_supervisor_node_get_field(pennbot,'rotation');
laserYawField = wb_supervisor_node_get_field(yawServo,'rotation');
laserPitchField = wb_supervisor_node_get_field(pitchServo,'rotation');

x=1; y=2; z=3; t=4;

laserOffset = [0.1 0.7 0];
targetGlob = [8 2 -3 1]';

addpath(genpath('/home/kuprel/magic2010'))

  robotID     = 1;
  
  setenv('ROBOT_ID',num2str(robotID));

  ipcAPIConnect('localhost');
  
  gyroMsgWebots  = GetMsgName('gyroWebots');
  lidarMsgWebots = GetMsgName('lidarWebots');
  encMsgWebots   = GetMsgName('encoderWebots');
  gyroMsg        = GetMsgName('ImuFiltered');
  lidarMsg       = GetMsgName('Lidar0');
  encMsg         = GetMsgName('Encoders');
  
  ipcAPISubscribe(gyroMsgWebots);
  ipcAPISubscribe(encMsgWebots);
  ipcAPISubscribe(lidarMsgWebots);

while wb_robot_step(TIME_STEP) ~= -1

  pos = wb_supervisor_field_get_sf_vec3f(positionField);
  rot = wb_supervisor_field_get_sf_rotation(rotationField);
  
  glob2rob = makehgtform('translate',[pos(x) pos(y) pos(z)],'axisrotate',[rot(x) rot(y) rot(z)],rot(t),'translate',laserOffset)^-1;
  targetRob = glob2rob*targetGlob;
  
  xt = targetRob(x); yt = targetRob(y); zt = targetRob(z);
  thetaH = asin(-zt/(xt^2+zt^2)^0.5);
  thetaV = asin(yt/(xt^2+zt^2+yt^2)^0.5);
    
  %wb_supervisor_field_set_sf_rotation(laserYawField,[0 1 0 thetaH]);
  %wb_supervisor_field_set_sf_rotation(laserPitchField,[0 0 1 thetaV]);

  msgs = ipcAPIReceive;
  for i=1:length(msgs)
    if strcmp(msgs(i).name,gyroMsgWebots)
      gyroData = MagicImuFilteredSerializer('deserialize',msgs(i).data);
      T = makehgtform('axisrotate',[rot(x) rot(y) rot(z)],rot(t));
      gyroData.yaw = atan2(-T(3,1),T(1,1));
      gyroData.pitch = asin(T(2,1));
      gyroData.roll = atan2(-T(2,3),T(2,2));
      gyroSerial = MagicImuFilteredSerializer('serialize',gyroData);
      ipcAPIPublish(gyroMsg,gyroSerial);
    elseif strcmp(msgs(i).name,encMsgWebots)
      ipcAPIPublish(encMsg,msgs(i).data);
    elseif strcmp(msgs(i).name,lidarMsgWebots)
      ipcAPIPublish(lidarMsg,msgs(i).data);
    end
  end

end
