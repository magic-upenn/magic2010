SetMagicPaths;

servoMsgName = GetMsgName('Servo1Cmd');

ipcAPIConnect()
ipcAPIDefine(servoMsgName,MagicServoControllerCmdSerializer('getFormat'));


%servo with laser has id =2
%target angle is minAngle
%mode does not matter
%speed setting is used -- 100 is ok
%acceleration is not used
servoCmd.id           = 2;
servoCmd.mode         = 0;
servoCmd.minAngle     = 0;
servoCmd.maxAngle     = 0;
servoCmd.speed        = 100;
servoCmd.acceleration = 300;

content = MagicServoControllerCmdSerializer('serialize',servoCmd);
ipcAPIPublishVC(servoMsgName,content);
