SetMagicPaths;

xbeeMsgName = GetMsgName('XbeeForward');

ipcAPIConnect()
ipcAPIDefine(xbeeMsgName);


data.t = GetUnixTime();
ipcAPIPublishVC(xbeeMsgName,serialize(data));
