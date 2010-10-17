SetMagicPaths;

servoMsgName = GetMsgName('Laser0Cmd');

ipcAPIConnect()
ipcAPIDefine(servoMsgName);

val = uint8(1);

ipcAPIPublish(servoMsgName,val);