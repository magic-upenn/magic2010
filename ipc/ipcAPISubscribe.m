function result = ipcAPISubscribe(msg_name)
global IPC

result = 0;
if isempty(IPC) || ~isfield(IPC,'connected') || ~IPC.connected
  disp('not connected to ipc');
  return;
end

result = IPC.handle('subscribe', msg_name);
