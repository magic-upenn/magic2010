function ipcSendTest(name, x)

ipcInit;

msgName = GetMsgName(name);
ipcAPIDefine(msgName);

ipcAPIPublish(msgName, serialize(x));
