SetMagicPaths;

servoMsgName = GetMsgName('Servo1Cmd');

ipcAPIConnect()
ipcAPIDefine(servoMsgName,MagicServoControllerCmdSerializer('getFormat'));


servoCmd.id           = 1;
servoCmd.mode         = 3; %0: disabled; 1: feedback only: 2: point minAngle is the goal), 3: servo mode
servoCmd.minAngle     = -47;
servoCmd.maxAngle     = 47;
servoCmd.speed        = 70;
servoCmd.acceleration = 300;

content = MagicServoControllerCmdSerializer('serialize',servoCmd);
ipcAPIPublishVC(servoMsgName,content);
