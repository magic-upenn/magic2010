function servoController(angle,servo)

servoMsgName = GetMsgName(servo);

ipcAPIDefine(servoMsgName,MagicServoControllerCmdSerializer('getFormat'));


servoCmd.id           = servo;
servoCmd.mode         = 0; %0 for point mode (minAngle is the goal), 1 for servo mode
servoCmd.minAngle     = angle;
servoCmd.maxAngle     =  10;
servoCmd.speed        = 100;
servoCmd.acceleration = 300;

content = MagicServoControllerCmdSerializer('serialize',servoCmd);
ipcAPIPublishVC(servoMsgName,content);