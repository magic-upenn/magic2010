function result = ipcAPIDisconnect
global IPC

result = 0;
if isempty(IPC) || ~isfield(IPC,'connected') || ~IPC.connected
  return
end

result = IPC.handle('disconnect');
IPC.connected = 0;