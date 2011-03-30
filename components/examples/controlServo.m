SetMagicPaths

angle = 0;
da    = 2;

servoMsgName = GetMsgName('Servo1Cmd');

ipcAPIConnect()
ipcAPIDefine(servoMsgName,MagicServoControllerCmdSerializer('getFormat'));


servoCmd.id           = 1;
servoCmd.mode         = 2; %0 for point mode (minAngle is the goal), 1 for servo mode
servoCmd.minAngle     = 0;
servoCmd.maxAngle     = 0;
servoCmd.speed        = 100;
servoCmd.acceleration = 300;

while(1)
  c = getch();
  
  if ~isempty(c)
    switch c
      case 'a'
        angle=angle+da;
      case 'd'
        angle=angle-da;
    end
    
    fprintf(1,'setting angle %f\n',angle);
    servoCmd.minAngle = angle;
    content = MagicServoControllerCmdSerializer('serialize',servoCmd);
    ipcAPIPublishVC(servoMsgName,content);
  else
   
    pause(0.1);
  end
end