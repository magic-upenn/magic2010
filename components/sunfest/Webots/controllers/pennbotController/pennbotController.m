function pennbotController

  clear all;
  
  addpath('/usr/local/webots/lib/matlab')
  addpath(genpath('/home/kuprel/magic2010'))

  TIME_STEP   = 64;
  robotWidth  = 0.42545;
  wheelRadius = 0.0825;
  robotID     = 1;
  velCmdSufx  = 'VelocityCmd';
  
  setenv('ROBOT_ID',num2str(robotID));
  velMsg = GetMsgName(velCmdSufx);

  ipcAPIConnect('localhost');
  ipcAPISubscribe(velMsg);
  
  gyroMsg  = GetMsgName('gyroWebots');
  lidarMsg = GetMsgName('lidarWebots');
  encMsg   = GetMsgName('encoderWebots');
  
  ipcAPIDefine(gyroMsg);
  ipcAPIDefine(lidarMsg);
  ipcAPIDefine(encMsg);

  frontRightWheel = wb_robot_get_device('front right wheel');
  frontLeftWheel  = wb_robot_get_device('front left wheel');
  backRightWheel  = wb_robot_get_device('back right wheel');
  backLeftWheel   = wb_robot_get_device('back left wheel');
  servoH          = wb_robot_get_device('servoH');
  servoV          = wb_robot_get_device('servoV');
  lidar           = wb_robot_get_device('lidar');
  gyro            = wb_robot_get_device('gyro');

  wb_robot_keyboard_enable(TIME_STEP);
  wb_camera_enable(lidar, TIME_STEP);
  wb_gyro_enable(gyro, TIME_STEP);  

  wb_servo_set_velocity(frontRightWheel, 0);
  wb_servo_set_velocity(backRightWheel,  0);
  wb_servo_set_velocity(frontLeftWheel,  0);
  wb_servo_set_velocity(backLeftWheel,   0);

  wb_servo_set_position(frontRightWheel, -Inf);
  wb_servo_set_position(backRightWheel,  -Inf);
  wb_servo_set_position(frontLeftWheel,  -Inf);
  wb_servo_set_position(backLeftWheel,   -Inf);

  numRanges = wb_camera_get_width(lidar);
  fov = wb_camera_get_fov(lidar);
  theta = linspace(0,fov,numRanges) - pi/4;

  plotHandle = polar(0,5,'or');
  
  encoderData = [0 0];

  while wb_robot_step(TIME_STEP) ~= -1

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Receive Velocity Command &
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    messages = ipcAPIReceive;
    if length(messages)
      cmd = MagicVelocityCmdSerializer('deserialize',messages(end).data);
      leftSpeed  = cmd.v - cmd.w*robotWidth/2;
      rightSpeed = cmd.v + cmd.w*robotWidth/2;
      wLeft  =  leftSpeed/wheelRadius;
      wRight = rightSpeed/wheelRadius;
      encoderData = round(rad2deg([wLeft wRight])*1e-3*TIME_STEP/2);
      wb_servo_set_velocity(frontRightWheel, wRight);
      wb_servo_set_velocity(backRightWheel,  wRight);
      wb_servo_set_velocity(frontLeftWheel,  wLeft);
      wb_servo_set_velocity(backLeftWheel,   wLeft);
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    gyroData = wb_gyro_get_values(gyro);
    
    lidarData = wb_camera_get_range_image(lidar);
    lidarData = fliplr(lidarData);
    [lidarX lidarY] = pol2cart(theta,lidarData);
    set(plotHandle,'xdata',lidarX,'ydata',lidarY);
    
    drawnow;
    
    publishIPCMsgs(gyroData,lidarData,encoderData,gyroMsg,lidarMsg,encMsg);

  end
  
end

function publishIPCMsgs(gyroData,lidarData,encoderData,gyroMsg,lidarMsg,encMsg)
  
  g.wroll  = gyroData(1);
  g.wyaw   = gyroData(2);
  g.wpitch = gyroData(3);
  g.t = now;
   
  e.fl = encoderData(1);
  e.fr = encoderData(2);
  e.rl = e.fl;
  e.rr = e.fr;
  e.t = now;
  
  l.startAngle = deg2rad(-135);
  l.stopAngle = -l.startAngle;
  l.angleStep = deg2rad(.25);
  l.ranges = single(lidarData);
  l.id = 0;
  l.intensities = uint16(ones(1,length(lidarData)));
  l.startTime = now;
  l.stopTime = now;
  
  encSerial = MagicEncoderCountsSerializer('serialize',e);
  gyroSerial = MagicImuFilteredSerializer('serialize',g);
  lidarSerial = MagicLidarScanSerializer('serialize',l);
  
  ipcAPIPublish(encMsg,encSerial);
  ipcAPIPublish(gyroMsg,gyroSerial);
  ipcAPIPublish(lidarMsg,lidarSerial);
  
end
