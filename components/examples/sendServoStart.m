SetMagicPaths;

servoMsgName = GetMsgName('Servo1Cmd');

ipcAPIConnect()
ipcAPIDefine(servoMsgName,MagicServoControllerCmdSerializer('getFormat'));


servoCmd.id           = 1;
servoCmd.mode         = 3; %0 for point mode (minAngle is the goal), 1 for servo mode
servoCmd.minAngle     = -35;
servoCmd.maxAngle     = 35;
servoCmd.speed        = 70;
servoCmd.acceleration = 300;

content = MagicServoControllerCmdSerializer('serialize',servoCmd);
ipcAPIPublishVC(servoMsgName,content);
