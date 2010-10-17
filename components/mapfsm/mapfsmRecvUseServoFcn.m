function mapfsmRecvUseServoFcn(data,name)
global USE_SERVO MP LOOK_ANGLE MPOSE

big_angle_thresh = 40*pi/180;

if ~isempty(data)
  new_servo_cmd = deserialize(data);

  if USE_SERVO ~= new_servo_cmd
    %if the command has changed
    USE_SERVO = new_servo_cmd

    if ~strcmp(currentState(MP.sm),'sLook') && ~strcmp(currentState(MP.sm),'sTrackHuman')
      %if we are not looking or tracking (because they control the servo already)
      if USE_SERVO
        %if we should servo then activate it
        servoCmd.id           = 1;
        servoCmd.mode         = 3;
        servoCmd.minAngle     = -40;
        servoCmd.maxAngle     = 40;
        servoCmd.speed        = 70;
        servoCmd.acceleration = 300;

        servoMsgName = GetMsgName('Servo1Cmd');
        content = MagicServoControllerCmdSerializer('serialize',servoCmd);
        ipcAPIPublishVC(servoMsgName,content);
      else 
        %if we should not servo then look at the last look angle we were given
        dHeading = modAngle(LOOK_ANGLE-MPOSE.heading);
        servoCmd.id           = 1;
        servoCmd.mode         = 2;
        servoCmd.minAngle     = max(min(dHeading,big_angle_thresh),-big_angle_thresh)*180/pi
        servoCmd.maxAngle     = 0;
        servoCmd.speed        = 70;
        servoCmd.acceleration = 300;

        servoMsgName = GetMsgName('Servo1Cmd');
        content = MagicServoControllerCmdSerializer('serialize',servoCmd);
        ipcAPIPublishVC(servoMsgName,content);
      end
    end
  end
end

