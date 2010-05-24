SetMagicPaths;

servoMsgName = GetMsgName('Servo1Cmd');

ipcAPIConnect()
ipcAPIDefine(servoMsgName,MagicServoControllerCmdSerializer('getFormat'));


servoCmd.id           = 1;
servoCmd.mode         = 0;
servoCmd.minAngle     = -20;
servoCmd.maxAngle     = 20;
servoCmd.speed        = 100;
servoCmd.acceleration = 300;

content = MagicServoControllerCmdSerializer('serialize',servoCmd);
ipcAPIPublishVC(servoMsgName,content);
