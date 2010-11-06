function ret = sLook(event, varargin);

global MPOSE LOOK_ANGLE USE_SERVO BODY_FACE TILT_ANGLE
persistent DATA

timeout = 5.0;
ret = [];

small_angle_thresh = 10*pi/180;
big_angle_thresh = 40*pi/180;
max_tilt = 10*pi/180;
servoMsgName = GetMsgName('Servo1Cmd');

switch event
 case 'entry'
  disp('sLook');

  DATA.state = 0;
  DATA.new_state = 1;

 case 'exit'
  if USE_SERVO
    servoCmd.id           = 1;
    servoCmd.mode         = 3;
    servoCmd.minAngle     = -40;
    servoCmd.maxAngle     = 40;
    servoCmd.speed        = 70;
    servoCmd.acceleration = 300;

    content = MagicServoControllerCmdSerializer('serialize',servoCmd);
    ipcAPIPublishVC(servoMsgName,content);
  end

 case 'update'
   LOOK_ANGLE*180/pi
   MPOSE.heading*180/pi

   dHeading = modAngle(LOOK_ANGLE-MPOSE.heading);
   dHeading*180/pi

   servoMsgName = GetMsgName('Servo1Cmd');
   servoCmd.id           = 1;
   servoCmd.mode         = 2; %0 for point mode (minAngle is the goal), 1 for servo mode
   if BODY_FACE
     servoCmd.minAngle   = 0;
   else
     servoCmd.minAngle   = max(min(dHeading,big_angle_thresh),-big_angle_thresh)*180/pi
   end
   servoCmd.maxAngle     = 0;
   servoCmd.speed        = 70;
   servoCmd.acceleration = 300;
   content = MagicServoControllerCmdSerializer('serialize',servoCmd);
   ipcAPIPublishVC(servoMsgName,content);


   %Tilt servo
   servoMsgName = GetMsgName('Servo1Cmd');
   servoCmd.id           = 2;
   servoCmd.mode         = 0;
   servoCmd.minAngle     = max(min(TILT_ANGLE, max_tilt), -max_tilt);
   servoCmd.maxAngle     = 0;
   servoCmd.speed        = 100;
   servoCmd.acceleration = 300;
   content = MagicServoControllerCmdSerializer('serialize',servoCmd);
   ipcAPIPublishVC(servoMsgName,content);


   if abs(dHeading) > big_angle_thresh || (abs(dHeading) > small_angle_thresh && BODY_FACE)
     if dHeading > 0
       if(DATA.state ~= 1)
         DATA.new_state = 1
       end
       DATA.state = 1;
     else
       if(DATA.state ~= 2)
         DATA.new_state = 1
       end
       DATA.state = 2;
     end
   elseif abs(dHeading) < small_angle_thresh
     DATA.state = 0;
     DATA.new_state = 1;
     SetVelocity(0,0);
   end


   if DATA.state == 1
     if DATA.new_state
       DATA.new_state = 0;
       sSpinLeft('entry');
     end
     sSpinLeft('update');
   elseif DATA.state == 2
     if DATA.new_state
       DATA.new_state = 0;
       sSpinRight('entry');
     end
     sSpinRight('update');
   end

end
