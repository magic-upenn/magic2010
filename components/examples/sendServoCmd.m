SetMagicPaths;

servoMsgName = GetMsgName('Servo1Cmd');

ipcAPIConnect()
ipcAPIDefine(servoMsgName,MagicServoControllerCmdSerializer('getFormat'));


servoCmd.id           = 4;
servoCmd.mode         = 0;
servoCmd.minAngle     = -30;
servoCmd.maxAngle     = 40;
servoCmd.speed        = 100;
servoCmd.acceleration = 300;

content = MagicServoControllerCmdSerializer('serialize',servoCmd);
ipcAPIPublishVC(servoMsgName,content);