function status = ipcInit

global IPC
if isempty(IPC)
  ipcAPIConnect;
  IPC.connected = 1;
  disp('IPC initialized');
end

status = 1;
