SetMagicPaths;

servoMsgName = GetMsgName('Servo1Cmd');

ipcAPIConnect()
ipcAPIDefine(servoMsgName,MagicServoControllerCmdSerializer('getFormat'));


servoCmd.id           = 1;
servoCmd.mode         = 0; %0 for point mode (minAngle is the goal), 1 for servo mode
servoCmd.minAngle     = -40;
servoCmd.maxAngle     = 40;
servoCmd.speed        = 100;
servoCmd.acceleration = 300;

content = MagicServoControllerCmdSerializer('serialize',servoCmd);
ipcAPIPublishVC(servoMsgName,content);
