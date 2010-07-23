function servoControllerTest(angle,servo)

if strcmp(servo,'ServoH')
	servo = 1;
end

id = 2;
setenv('ROBOT_ID',sprintf('%d',id));
addr = sprintf('192.168.10.10%d',id);
ipcInit(addr);
servoMsgName = GetMsgName('Servo1Cmd');

ipcAPIDefine(servoMsgName,MagicServoControllerCmdSerializer('getFormat'));


servoCmd.id           = servo;
servoCmd.mode         = 0; %0 for point mode (minAngle is the goal), 1 for servo mode
servoCmd.minAngle     = angle;
servoCmd.maxAngle     =  35;
servoCmd.speed        = 100;
servoCmd.acceleration = 300;

content = MagicServoControllerCmdSerializer('serialize',servoCmd);

ipcAPIPublishVC(servoMsgName,content);

end