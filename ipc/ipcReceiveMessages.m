function nmsg = ipcReceiveMessages(dt)

global IPC

nmsg = 0;
if isempty(IPC) || ~isfield(IPC,'connected') || ~IPC.connected
  disp('not connected to ipc');
  return;
end

if nargin <1
    dt=10;
end

tStart = clock;
msgs = IPC.handle('listenWait',dt);

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


dtActual = etime(clock,tStart);

if (dtActual < dt/1000)
  pause(dt/1000-dtActual)
end

