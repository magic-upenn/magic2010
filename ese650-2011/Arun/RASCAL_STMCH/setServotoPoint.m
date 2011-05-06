function [] = setServotoPoint(val)

servoMsgName = GetMsgName('Servo1Cmd');
ipcAPIDefine(servoMsgName,MagicServoControllerCmdSerializer('getFormat'));

% Then do automatic scanning 
servoCmd.id           = 1;
servoCmd.mode         = 2;  %0: disabled; 1: feedback only: 2: point minAngle is the goal), 3: servo mode
servoCmd.minAngle     = val;
servoCmd.maxAngle     = 0;
servoCmd.speed        = 20;
servoCmd.acceleration = 300;

content = MagicServoControllerCmdSerializer('serialize',servoCmd);
ipcAPIPublishVC(servoMsgName,content);

end