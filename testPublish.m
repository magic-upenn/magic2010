SetMagicPaths

pubMsgName=GetMsgName('PubState')
ipcAPIConnect()
ipcAPIDefine(pubMsgName);
ipcAPISetMsgQueueLength(pubMsgName,10);

while(1)
    a.dat=rand
    data=serialize(a);
    ipcAPIPublish(pubMsgName,data);
    pause(0.01);
end
