SetMagicPaths

angle = 0;
da    = 2;

servoMsgName = GetMsgName('Servo1Cmd');

ipcAPIConnect()
ipcAPIDefine(servoMsgName,MagicServoControllerCmdSerializer('getFormat'));

servoCmd.id           = 1;
servoCmd.mode         = 3;  %0: disabled; 1: feedback only: 2: point minAngle is the goal), 3: servo mode
servoCmd.minAngle     = -45;
servoCmd.maxAngle     = 20;
servoCmd.speed        = 15;
servoCmd.acceleration = 300;
ex_flag = 0;
% do it for first time
content = MagicServoControllerCmdSerializer('serialize',servoCmd);
ipcAPIPublishVC(servoMsgName,content);

while(1)
  c = getch();
  
  if ~isempty(c)
    switch c
      case 'f' % set it to point mode
        servoCmd.mode = 2;
        continue;
      case 'a' %increment the current angle
          if(servoCmd.mode == 2)
            angle=angle+da;
            fprintf(1,'setting angle %f\n',angle);
            servoCmd.minAngle = angle;
          else
              continue;
          end
      case 'd' %decrement the current angle
          if(servoCmd.mode == 2)
            angle=angle-da;
            fprintf(1,'setting angle %f\n',angle);
            servoCmd.minAngle = angle;
          else
            continue;
          end
      case 's' %stop controlservo
        servoCmd.id           = 1;
        servoCmd.mode         = 2;  %0: disabled; 1: feedback only: 2: point minAngle is the goal), 3: servo mode
        servoCmd.minAngle     = 0;
        servoCmd.maxAngle     = 0;
        servoCmd.speed        = 100;
        servoCmd.acceleration = 300;
        fprintf(1,'Stopping servo mode\n');
        ex_flag = 1;
        
      case 'g'
        servoCmd.id           = 1;
        servoCmd.mode         = 3;  %0: disabled; 1: feedback only: 2: point minAngle is the goal), 3: servo mode
        servoCmd.minAngle     = -45;
        servoCmd.maxAngle     = 20;
        servoCmd.speed        = 15;
        servoCmd.acceleration = 300;
    end
    content = MagicServoControllerCmdSerializer('serialize',servoCmd);
    ipcAPIPublishVC(servoMsgName,content);
    if(ex_flag == 1)
        break;
    end
  else
   
    pause(0.1);
  end
end