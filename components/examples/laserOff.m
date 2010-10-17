SetMagicPaths;

servoMsgName = GetMsgName('Laser0Cmd');

ipcAPIConnect()
ipcAPIDefine(servoMsgName);

val = uint8(0);

ipcAPIPublish(servoMsgName,val);
