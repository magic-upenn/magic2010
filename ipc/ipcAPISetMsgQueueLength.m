function result = ipcAPISetMsgQueueLength(msg_name,length)
global IPC

result = 0;
if isempty(IPC) || ~isfield(IPC,'connected') || ~IPC.connected
  disp('not connected to ipc');
  return;
end


result = IPC.handle('set_msg_queue_length',msg_name,length);
