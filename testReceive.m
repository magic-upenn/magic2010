SetMagicPaths;

pubMsgName=GetMsgName('PubState')
ipcAPIConnect;
ipcAPISubscribe(pubMsgName);

while(1)
    msgs = ipcAPIReceive(10);
    len=length(msgs);
    if len>0
        for i=1:len
            dat=deserialize(msgs(i).data);
			dat.dat
        end
    end
end
