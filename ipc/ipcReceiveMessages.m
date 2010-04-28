function nmsg = ipcReceiveMessages

global IPC

msgs = ipcAPI('listenClear',1);  %listen until no messages for 1ms
nmsg = length(msgs);

for mi=1:nmsg
  name = msgs(mi).name;
  if isfield(IPC.handler,name),
    try
      IPC.handler.(name)(msgs(mi).data);
    catch
      disp(sprintf('Error in ipc %s handler: %s', name, lasterror.message));
    end
  end
end
