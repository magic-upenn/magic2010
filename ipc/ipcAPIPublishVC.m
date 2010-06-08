function result = ipcAPIPublishVC(msg_name,msg)
global IPC

result =0;
if isempty(IPC) || ~isfield(IPC,'connected') || ~IPC.connected
  disp('not connected to ipc');
  return;
end

result = IPC.handle('publishVC',msg_name,msg);
