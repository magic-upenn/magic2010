SetMagicPaths;
estopMsgName = GetMsgName('EstopState');

ipcAPIConnect;
ipcAPISubscribe(estopMsgName);


while(1)
  msgs = ipcAPIReceive(10);
  len = length(msgs);
  if len > 0
    for i=1:len
      estate =  MagicEstopStateSerializer('deserialize',msgs(i).data)
    end
  end
end