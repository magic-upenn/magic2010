function nmsg = ipcReceiveMessages(dt)

global IPC

if nargin <1
    dt=10;
end

msgs = ipcAPI('listenWait',dt);
nmsg = length(msgs);

for mi=1:nmsg
  name = msgs(mi).name;
  name(name=='/')='_';
  if isfield(IPC.handler,name),
    %try
      IPC.handler.(name)(msgs(mi).data,msgs(mi).name);
    %catch
    %  disp(sprintf('Error in ipc %s handler: %s', name, lasterror.message));
    %end
  end
end
