SetMagicPaths;

incMapMsgName ='Robot3/IncMapUpdateH';

ipcAPIConnect('192.168.10.103');
ipcAPISubscribe(incMapMsgName);


while(1)
  msgs = ipcAPIReceive(10);
  len = length(msgs);
  if len > 0
    for i=1:len
      inc = deserialize(msgs(i).data);
      xs = double(inc.xs);
      ys = double(inc.ys);
      plot(xs,ys,'.'); drawnow;
    end
  end
end
