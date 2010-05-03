clear all;

SetMagicPaths;

hBeatMsgName = [GetRobotName '/HeartBeat'];

ipcAPIConnect();
ipcAPISubscribe(hBeatMsgName);


while(1)
  msgs = ipcAPI('listenWait',5);
  len = length(msgs);
  
  for mi=1:len
    switch (msgs(i).name)
      case hBeatMsgName
        hbeat = MagicHeartBeatSerializer('deserialize',msgs(i));
        fprintf(1,'received heartbeat from %s for message %s\n', ...
          hbeat.sender,hbeat.msgName);
      otherwise
        error('unknown message name');
    end
  end
end